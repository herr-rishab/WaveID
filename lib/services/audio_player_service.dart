import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<void> get onComplete => _player.onPlayerComplete;

  Future<void> playWav(Uint8List wavBytes, {double volume = 0.2}) async {
    await _player.stop();
    await _player.setVolume(volume);
    await _player.play(BytesSource(wavBytes));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
