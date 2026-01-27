import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  File? _tempFile;

  Stream<void> get onComplete => _player.onPlayerComplete;

  Future<void> playWav(Uint8List wavBytes, {double volume = 0.2}) async {
    await _player.stop();
    _tempFile ??= await _createTempFile();
    await _tempFile!.writeAsBytes(wavBytes, flush: true);
    await _player.setVolume(volume);
    await _player.play(DeviceFileSource(_tempFile!.path));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
    if (_tempFile != null && await _tempFile!.exists()) {
      await _tempFile!.delete();
    }
  }

  Future<File> _createTempFile() async {
    final Directory dir = await getTemporaryDirectory();
    final String path = '${dir.path}/present_sir_token.wav';
    return File(path);
  }
}
