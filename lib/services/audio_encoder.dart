import 'dart:math';
import 'dart:typed_data';

class AudioEncoder {
  static const int sampleRate = 16000;
  static const double freq0 = 523.0;
  static const double freq1 = 659.0;

  Uint8List encodeTokenToWav(
    String token, {
    int symbolDurationMs = 40,
    int repeatCount = 2,
    int gapMs = 150,
    double amplitude = 0.35,
    bool melodyOverlay = true,
    double melodyGain = 0.12,
    int melodyNoteMs = 180,
  }) {
    final List<int> bits = <int>[
      ..._preambleBits(),
      ..._tokenToBcdBits(token),
    ];

    final int symbolSamples =
        (AudioEncoder.sampleRate * (symbolDurationMs / 1000.0)).round();
    final int gapSamples =
        (AudioEncoder.sampleRate * (gapMs / 1000.0)).round();
    final int fadeSamples = _fadeSamples(symbolSamples, symbolDurationMs);

    final List<int> pcm = <int>[];
    for (int repeat = 0; repeat < repeatCount; repeat++) {
      for (final int bit in bits) {
        final double freq = bit == 0 ? AudioEncoder.freq0 : AudioEncoder.freq1;
        pcm.addAll(_toneSamples(freq, symbolSamples, amplitude, fadeSamples));
      }
      if (repeat < repeatCount - 1) {
        pcm.addAll(List<int>.filled(gapSamples, 0));
      }
    }

    if (melodyOverlay) {
      _mixMelodyOverlay(pcm, melodyNoteMs, melodyGain);
    }

    return _wrapAsWav(pcm, AudioEncoder.sampleRate);
  }

  List<int> _preambleBits() => const <int>[1, 0, 1, 0, 1, 0, 1, 0];

  List<int> _tokenToBcdBits(String token) {
    final String normalized = token.padLeft(4, '0').substring(0, 4);
    final List<int> bits = <int>[];
    for (int i = 0; i < normalized.length; i++) {
      final int digit = int.tryParse(normalized[i]) ?? 0;
      for (int shift = 3; shift >= 0; shift--) {
        bits.add((digit >> shift) & 1);
      }
    }
    return bits;
  }

  int _fadeSamples(int symbolSamples, int symbolDurationMs) {
    final int fadeFromMs = (AudioEncoder.sampleRate * 0.012).round();
    final int maxFade = symbolSamples ~/ 2;
    return max(4, min(fadeFromMs, maxFade));
  }

  List<int> _toneSamples(
    double frequency,
    int samples,
    double amplitude,
    int fadeSamples,
  ) {
    final List<int> data = List<int>.filled(samples, 0);
    final double increment = (2 * pi * frequency) / AudioEncoder.sampleRate;
    final double secondaryFrequency = frequency / 2.0;
    final double secondaryIncrement =
        (2 * pi * secondaryFrequency) / AudioEncoder.sampleRate;
    const double secondaryGain = 0.18;
    double phase = 0;
    double secondaryPhase = 0;
    for (int i = 0; i < samples; i++) {
      final double envelope = _raisedCosineEnvelope(i, samples, fadeSamples);
      final double primary = sin(phase);
      final double secondary = sin(secondaryPhase) * secondaryGain;
      final double value = (primary + secondary) * amplitude * envelope;
      data[i] = (value * 32767).round().clamp(-32768, 32767);
      phase += increment;
      secondaryPhase += secondaryIncrement;
    }
    return data;
  }

  void _mixMelodyOverlay(List<int> pcm, int noteMs, double gain) {
    if (pcm.isEmpty || gain <= 0) {
      return;
    }
    final List<double> melody = <double>[
      261.63,
      329.63,
      392.00,
      440.00,
      392.00,
      329.63,
    ];
    final int noteSamples =
        (AudioEncoder.sampleRate * (noteMs / 1000.0)).round();
    final int fadeSamples = max(4, (AudioEncoder.sampleRate * 0.02).round());
    double phase = 0.0;

    for (int i = 0; i < pcm.length; i++) {
      final int noteIndex = (i ~/ noteSamples) % melody.length;
      final int noteOffset = i % noteSamples;
      final double freq = melody[noteIndex];
      final double increment = (2 * pi * freq) / AudioEncoder.sampleRate;
      phase += increment;

      final double envelope = _raisedCosineEnvelope(
        noteOffset,
        noteSamples,
        min(fadeSamples, noteSamples ~/ 2),
      );
      final int overlay = (sin(phase) * gain * envelope * 32767)
          .round()
          .clamp(-32768, 32767);
      pcm[i] = (pcm[i] + overlay).clamp(-32768, 32767);
    }
  }

  double _raisedCosineEnvelope(int index, int samples, int fadeSamples) {
    if (fadeSamples <= 1) {
      return 1.0;
    }
    if (index < fadeSamples) {
      return 0.5 - 0.5 * cos(pi * index / fadeSamples);
    }
    if (index >= samples - fadeSamples) {
      return 0.5 - 0.5 * cos(pi * (samples - index) / fadeSamples);
    }
    return 1.0;
  }

  Uint8List _wrapAsWav(List<int> pcmSamples, int sampleRate) {
    const int bitsPerSample = 16;
    const int channels = 1;
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final int blockAlign = channels * (bitsPerSample ~/ 8);
    final int dataSize = pcmSamples.length * 2;
    final int fileSize = 36 + dataSize;

    final ByteData header = ByteData(44 + dataSize);
    _writeString(header, 0, 'RIFF');
    header.setUint32(4, fileSize, Endian.little);
    _writeString(header, 8, 'WAVE');
    _writeString(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    _writeString(header, 36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      header.setInt16(44 + i * 2, pcmSamples[i], Endian.little);
    }

    return header.buffer.asUint8List();
  }

  void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
