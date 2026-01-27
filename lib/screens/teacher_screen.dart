import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_encoder.dart';
import '../services/audio_player_service.dart';
import '../services/token_service.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final AudioEncoder _encoder = AudioEncoder();
  final AudioPlayerService _player = AudioPlayerService();
  Timer? _timer;
  StreamSubscription<void>? _playerSub;

  String _token = '';
  int _window = 0;
  bool _autoBroadcast = false;
  bool _quietMode = false;
  bool _melodyOverlay = true;
  double _volume = 0.2;
  bool _broadcasting = false;
  int _lastBroadcastWindow = -1;

  @override
  void initState() {
    super.initState();
    final int window = TokenService.currentWindow();
    _window = window;
    _token = TokenService.tokenForWindow(window);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _playerSub = _player.onComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasting = false;
      });
    });
  }

  void _tick() {
    final int window = TokenService.currentWindow();
    if (window != _window) {
      setState(() {
        _window = window;
        _token = TokenService.tokenForWindow(window);
      });
      if (_autoBroadcast) {
        _playToken();
      }
    }
  }

  Future<void> _playToken() async {
    if (_broadcasting) {
      return;
    }
    setState(() {
      _broadcasting = true;
    });
    final int symbolMs = _quietMode ? 70 : 40;
    final int gapMs = _quietMode ? 200 : 150;
    final wav = _encoder.encodeTokenToWav(
      _token,
      symbolDurationMs: symbolMs,
      gapMs: gapMs,
      repeatCount: 2,
      amplitude: _melodyOverlay ? 0.30 : 0.35,
      melodyOverlay: _melodyOverlay,
      melodyGain: _melodyOverlay ? 0.18 : 0.0,
      melodyNoteMs: _quietMode ? 220 : 180,
    );
    await _player.playWav(wav, volume: _volume);
    _lastBroadcastWindow = _window;
  }

  void _toggleAuto(bool value) {
    setState(() {
      _autoBroadcast = value;
    });
    if (value) {
      _playToken();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Current token',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _token,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text('Window: $_window'),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(
                _broadcasting ? Icons.graphic_eq : Icons.graphic_eq_outlined,
                color: _broadcasting ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _broadcasting ? 'Broadcasting' : 'Idle',
                style: TextStyle(
                  color: _broadcasting ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _playToken,
            child: const Text('Play Token Now'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Auto Broadcast'),
            subtitle: const Text('Play once per 30-second window'),
            value: _autoBroadcast,
            onChanged: _toggleAuto,
          ),
          SwitchListTile(
            title: const Text('Quiet mode'),
            subtitle: const Text('Longer symbols for stability'),
            value: _quietMode,
            onChanged: (bool value) {
              setState(() {
                _quietMode = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Melody overlay'),
            subtitle: const Text('Blend a soft arpeggio'),
            value: _melodyOverlay,
            onChanged: (bool value) {
              setState(() {
                _melodyOverlay = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Text('Volume: ${( _volume * 100).round()}'),
          Slider(
            value: _volume,
            onChanged: (double value) {
              setState(() {
                _volume = value;
              });
            },
            min: 0.0,
            max: 1.0,
            divisions: 100,
          ),
          const SizedBox(height: 12),
          Text(
            "Debug: last broadcast window ${_lastBroadcastWindow == -1 ? 'none' : _lastBroadcastWindow}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
