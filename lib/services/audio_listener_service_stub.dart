import 'dart:async';

import 'package:flutter/foundation.dart';

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
  });

  final int sampleRate;
  final int symbolDurationMs;
  final double freq0;
  final double freq1;

  final ValueNotifier<double> noiseLevel = ValueNotifier<double>(0.0);
  final ValueNotifier<double> lastConfidence = ValueNotifier<double>(0.0);

  Stream<DetectionResult> get results => const Stream<DetectionResult>.empty();

  Future<void> start() {
    return Future<void>.error(
      UnsupportedError('Microphone streaming is not supported on this platform.'),
    );
  }

  Future<void> stop() async {}

  Future<void> dispose() async {
    noiseLevel.dispose();
    lastConfidence.dispose();
  }
}
