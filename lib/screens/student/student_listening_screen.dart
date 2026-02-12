import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/app_user.dart';
import '../../models/attendance_session.dart';
import '../../services/attendance_service.dart';
import '../../services/audio_listener_service.dart';
import '../../services/firestore_service.dart';
import '../../services/token_engine.dart';
import '../../widgets/loading_view.dart';

class StudentListeningScreen extends StatefulWidget {
  const StudentListeningScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<StudentListeningScreen> createState() => _StudentListeningScreenState();
}

class _StudentListeningScreenState extends State<StudentListeningScreen> {
  AudioListenerService? _listener;
  StreamSubscription<DetectionResult>? _sub;
  bool _listening = false;
  bool _processing = false;
  String _status = 'Tap start to listen.';
  String _message = '';

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (widget.user.studentId == null || widget.user.studentId!.isEmpty) {
      setState(() {
        _status = 'Student ID missing.';
        _message = 'Ask admin to link your account.';
      });
      return;
    }

    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() {
        _status = 'Microphone permission denied.';
      });
      return;
    }

    await _listener?.dispose();
    _listener = AudioListenerService();
    _sub = _listener?.results.listen(
      _handleDetection,
      onError: (Object error) {
        setState(() {
          _status = 'Listening error.';
          _message = error.toString();
        });
      },
    );
    try {
      await _listener?.start();
      setState(() {
        _listening = true;
        _status = 'Listening...';
        _message = 'Stay near the SPC audio.';
      });
    } catch (error) {
      setState(() {
        _status = 'Microphone unavailable.';
        _message = error.toString();
      });
    }
  }

  Future<void> _stopListening() async {
    await _sub?.cancel();
    _sub = null;
    await _listener?.dispose();
    _listener = null;
    if (mounted) {
      setState(() {
        _listening = false;
      });
    }
  }

  Future<void> _handleDetection(DetectionResult result) async {
    if (_processing) {
      return;
    }
    setState(() {
      _processing = true;
      _status = 'Token detected';
      _message = 'Verifying attendance...';
    });

    final List<AttendanceSession> sessions = await FirestoreService()
        .fetchActiveSessionsForStudent(widget.user.studentId ?? '');

    if (sessions.isEmpty) {
      setState(() {
        _processing = false;
        _status = 'No active session';
        _message = 'No active drive session found for your profile.';
      });
      return;
    }

    final AttendanceSession? session = _pickSession(sessions, result.token);
    if (session == null) {
      setState(() {
        _processing = false;
        _status = 'Token mismatch';
        _message =
            'Detected token is not for your assigned drives. Stay near the SPC audio and try again.';
      });
      return;
    }

    final MarkAttendanceResult response = await AttendanceService()
        .markAttendance(
          sessionId: session.id,
          driveId: session.driveId,
          studentId: widget.user.studentId!,
          token: result.token,
          deviceId: widget.user.uid,
        );

    setState(() {
      _processing = false;
      _status = response.isSuccess
          ? 'Attendance Marked Present'
          : 'Attendance Failed';
      _message = response.message;
    });
  }

  AttendanceSession? _pickSession(
    List<AttendanceSession> sessions,
    String token,
  ) {
    final List<AttendanceSession> matches = sessions.where((
      AttendanceSession session,
    ) {
      final TokenEngine engine = TokenEngine(
        windowSeconds: session.tokenWindowSeconds,
      );
      return engine.isTokenValid(token, session.sessionSeed);
    }).toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_status, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Center(
                  child: _processing
                      ? const LoadingView(message: 'Verifying token...')
                      : Icon(
                          _listening ? Icons.hearing : Icons.hearing_disabled,
                          size: 96,
                          color: _listening ? Colors.green : Colors.grey,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
