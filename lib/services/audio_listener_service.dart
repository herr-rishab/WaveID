import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:mic_stream/mic_stream.dart';

import 'token_service.dart';

class DetectionResult {
  DetectionResult({
    required this.token,
    required this.confidence,
    required this.isValid,
  });

  final String token;
  final double confidence;
  final bool isValid;
}

class AudioListenerService {
  AudioListenerService({
    this.sampleRate = 16000,
    this.symbolDurationMs = 40,
    this.freq0 = 523.0,
    this.freq1 = 659.0,
  }) {
    _symbolSamples =
        (sampleRate * (symbolDurationMs / 1000.0)).round();
  }

  final int sampleRate;
  final int symbolDurationMs;
  final double freq0;
  final double freq1;

  late int _symbolSamples;
  bool _listening = false;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<DetectionResult> _resultsController =
      StreamController<DetectionResult>.broadcast();
  final List<int> _sampleBuffer = <int>[];
  final List<int> _preambleBuffer = <int>[];
  final List<int> _payloadBuffer = <int>[];
  String _lastToken = '';
  DateTime? _lastDetection;
  bool _synced = false;

  final ValueNotifier<double> noiseLevel = ValueNotifier<double>(0.0);
  final ValueNotifier<double> lastConfidence = ValueNotifier<double>(0.0);

  Stream<DetectionResult> get results => _resultsController.stream;

  bool get isListening => _listening;

  Future<void> start() async {
    if (_listening) {
      return;
    }
    final Stream<Uint8List>? stream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: sampleRate,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );
    if (stream == null) {
      throw StateError('Microphone stream unavailable.');
    }
    _listening = true;
    _subscription = stream.listen(_handleAudioData, onError: (Object error) {
      _resultsController.addError(error);
    });
  }

  Future<void> stop() async {
    if (!_listening) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    _sampleBuffer.clear();
    _preambleBuffer.clear();
    _payloadBuffer.clear();
    _synced = false;
    _listening = false;
  }

  Future<void> dispose() async {
    await stop();
    await _resultsController.close();
    noiseLevel.dispose();
    lastConfidence.dispose();
  }

  void _handleAudioData(List<int> data) {
    final Uint8List bytes = Uint8List.fromList(data);
    final ByteData byteData = ByteData.view(bytes.buffer);
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      _sampleBuffer.add(byteData.getInt16(i, Endian.little));
    }

    while (_sampleBuffer.length >= _symbolSamples) {
      final List<int> windowSamples =
          _sampleBuffer.sublist(0, _symbolSamples);
      _sampleBuffer.removeRange(0, _symbolSamples);
      _processWindow(windowSamples);
    }
  }

  void _processWindow(List<int> samples) {
    final double p0 = _goertzel(samples, freq0);
    final double p1 = _goertzel(samples, freq1);
    final double denom = p0 + p1;
    final double confidence = denom > 0 ? (p1 - p0).abs() / denom : 0.0;
    lastConfidence.value = confidence;

    final double rms = _rmsLevel(samples);
    noiseLevel.value = rms;

    final int bit = p1 > p0 ? 1 : 0;
    _consumeBit(bit, confidence);
  }

  void _consumeBit(int bit, double confidence) {
    if (!_synced) {
      _preambleBuffer.add(bit);
      if (_preambleBuffer.length > 8) {
        _preambleBuffer.removeAt(0);
      }
      if (_preambleBuffer.length == 8 && _isPreamble(_preambleBuffer)) {
        _synced = true;
        _payloadBuffer.clear();
      }
      return;
    }

    _payloadBuffer.add(bit);
    if (_payloadBuffer.length < 16) {
      return;
    }

    final String token = _decodeBcd(_payloadBuffer);
    _payloadBuffer.clear();
    _synced = false;

    if (token.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    if (token == _lastToken &&
        _lastDetection != null &&
        now.difference(_lastDetection!).inSeconds < 2) {
      return;
    }
    _lastToken = token;
    _lastDetection = now;

    _resultsController.add(
      DetectionResult(
        token: token,
        confidence: confidence,
        isValid: TokenService.isValidToken(token, now),
      ),
    );
  }

  bool _isPreamble(List<int> bits) {
    const List<int> pattern = <int>[1, 0, 1, 0, 1, 0, 1, 0];
    for (int i = 0; i < pattern.length; i++) {
      if (bits[i] != pattern[i]) {
        return false;
      }
    }
    return true;
  }

  String _decodeBcd(List<int> bits) {
    if (bits.length < 16) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    for (int digitIndex = 0; digitIndex < 4; digitIndex++) {
      int value = 0;
      for (int bitIndex = 0; bitIndex < 4; bitIndex++) {
        value = (value << 1) | bits[digitIndex * 4 + bitIndex];
      }
      if (value > 9) {
        return '';
      }
      buffer.write(value.toString());
    }
    return buffer.toString();
  }

  double _goertzel(List<int> samples, double frequency) {
    final double omega = 2 * pi * frequency / sampleRate;
    final double coeff = 2 * cos(omega);
    double sPrev = 0.0;
    double sPrev2 = 0.0;
    for (final int sample in samples) {
      final double s = sample + coeff * sPrev - sPrev2;
      sPrev2 = sPrev;
      sPrev = s;
    }
    return sPrev2 * sPrev2 + sPrev * sPrev - coeff * sPrev * sPrev2;
  }

  double _rmsLevel(List<int> samples) {
    double sum = 0.0;
    for (final int sample in samples) {
      final double value = sample / 32768.0;
      sum += value * value;
    }
    return sqrt(sum / samples.length).clamp(0.0, 1.0);
  }
}
