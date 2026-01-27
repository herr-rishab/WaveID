import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/audio_listener_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  AudioListenerService? _listener;
  StreamSubscription<DetectionResult>? _resultsSub;

  bool _listening = false;
  bool _quietMode = false;
  String _status = 'Not listening';
  String _lastToken = '--';
  bool _present = false;

  final ValueNotifier<double> _noiseLevel = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _confidenceLevel = ValueNotifier<double>(0.0);

  @override
  void dispose() {
    _stopListening(updateState: false);
    _noiseLevel.dispose();
    _confidenceLevel.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Microphone permission denied';
        _present = false;
      });
      return;
    }

    await _resetListener();
    await _listener?.start();

    if (!mounted) {
      return;
    }
    setState(() {
      _listening = true;
      _status = 'Listening...';
      _present = false;
    });
  }

  Future<void> _stopListening({bool updateState = true}) async {
    await _resultsSub?.cancel();
    _resultsSub = null;
    await _listener?.dispose();
    _listener = null;
    if (mounted && updateState) {
      setState(() {
        _listening = false;
        _status = 'Stopped';
      });
    }
  }

  Future<void> _resetListener() async {
    await _resultsSub?.cancel();
    await _listener?.dispose();

    _listener = AudioListenerService(
      symbolDurationMs: _quietMode ? 70 : 40,
    );

    _listener?.noiseLevel.addListener(() {
      _noiseLevel.value = _listener?.noiseLevel.value ?? 0.0;
    });
    _listener?.lastConfidence.addListener(() {
      _confidenceLevel.value = _listener?.lastConfidence.value ?? 0.0;
    });

    _resultsSub = _listener?.results.listen(
      _handleDetection,
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _status = 'Listening error: $error';
        });
      },
    );
  }

  void _handleDetection(DetectionResult result) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lastToken = result.token;
      _present = result.isValid;
      _status = result.isValid ? 'PRESENT' : 'Not detected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _listening ? Icons.mic : Icons.mic_none,
                color: _listening ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _listening ? 'Listening' : 'Idle',
                style: TextStyle(
                  color: _listening ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _listening ? Colors.blueGrey : Colors.grey,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                _present ? 'Result: PRESENT' : 'Result: NOT PRESENT',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _present ? Colors.green : Colors.orange,
                    ),
              ),
              const SizedBox(width: 8),
              if (_present) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Text('Last detected token: $_lastToken'),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: _confidenceLevel,
            builder: (BuildContext context, double value, Widget? child) {
              return Text('Confidence: ${value.toStringAsFixed(2)}');
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<double>(
            valueListenable: _noiseLevel,
            builder: (BuildContext context, double value, Widget? child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Noise meter: ${value.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: _listening ? null : _startListening,
                  child: const Text('Start Listening'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _listening ? _stopListening : null,
                  child: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Quiet mode'),
            subtitle: const Text('Match longer teacher symbols'),
            value: _quietMode,
            onChanged: (bool value) async {
              setState(() {
                _quietMode = value;
              });
              if (_listening) {
                await _startListening();
              }
            },
          ),
        ],
      ),
    );
  }
}
