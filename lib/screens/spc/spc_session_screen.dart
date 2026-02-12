import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/attendance_record.dart';
import '../../models/attendance_session.dart';
import '../../models/drive.dart';
import '../../models/student_profile.dart';
import '../../services/audio_encoder.dart';
import '../../services/audio_player_service.dart';
import '../../services/firestore_service.dart';
import '../../services/token_engine.dart';
import '../../widgets/loading_view.dart';

class SpcSessionScreen extends StatefulWidget {
  const SpcSessionScreen({
    super.key,
    required this.drive,
    required this.sessionId,
  });

  final Drive drive;
  final String sessionId;

  @override
  State<SpcSessionScreen> createState() => _SpcSessionScreenState();
}

class _SpcSessionScreenState extends State<SpcSessionScreen> {
  final AudioEncoder _encoder = AudioEncoder();
  final AudioPlayerService _player = AudioPlayerService();
  Timer? _timer;
  StreamSubscription<void>? _onCompleteSub;
  bool _continuousAudio = true;
  bool _quietMode = false;
  double _volume = 0.7;
  bool _broadcasting = false;
  String _token = '----';
  AttendanceSession? _session;

  @override
  void initState() {
    super.initState();
    _onCompleteSub = _player.onComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _broadcasting = false;
      });
      final AttendanceSession? session = _session;
      if (_continuousAudio && session != null) {
        _playToken(session);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _onCompleteSub?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _tick() {
    final AttendanceSession? session = _session;
    if (session != null) {
      final TokenEngine engine = TokenEngine(
        windowSeconds: session.tokenWindowSeconds,
      );
      final String token = engine.currentToken(session.sessionSeed);
      if (token != _token && mounted) {
        setState(() {
          _token = token;
        });
      }
      if (_continuousAudio && !_broadcasting) {
        _playToken(session);
      }
    }
  }

  Future<void> _playToken(AttendanceSession session) async {
    if (_broadcasting || !_continuousAudio) {
      return;
    }
    final TokenEngine engine = TokenEngine(
      windowSeconds: session.tokenWindowSeconds,
    );
    final String token = engine.currentToken(session.sessionSeed);
    setState(() {
      _broadcasting = true;
      _token = token;
    });
    final int symbolMs = _quietMode ? 70 : 40;
    final int gapMs = _quietMode ? 200 : 150;
    final wav = _encoder.encodeTokenToWav(
      token,
      symbolDurationMs: symbolMs,
      gapMs: gapMs,
      repeatCount: 2,
      amplitude: 0.32,
      melodyOverlay: true,
      melodyGain: 0.18,
      melodyNoteMs: _quietMode ? 220 : 180,
    );
    try {
      await _player.playWav(wav, volume: _volume);
    } catch (_) {
      if (mounted) {
        setState(() {
          _broadcasting = false;
          _continuousAudio = false;
        });
      }
    }
  }

  Future<void> _playOneShot(AttendanceSession session) async {
    if (_broadcasting) {
      return;
    }
    final bool wasContinuous = _continuousAudio;
    setState(() {
      _continuousAudio = false;
    });
    await _playToken(session);
    if (mounted) {
      setState(() {
        _continuousAudio = wasContinuous;
      });
    }
  }

  Future<void> _stopAudio() async {
    setState(() {
      _continuousAudio = false;
      _broadcasting = false;
    });
    await _player.stop();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('SPC Session')),
      body: StreamBuilder<AttendanceSession?>(
        stream: service.watchActiveSessionForDrive(widget.drive.id),
        builder:
            (BuildContext context, AsyncSnapshot<AttendanceSession?> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Failed to load session. ${snapshot.error}'),
                );
              }
              final AttendanceSession? session = snapshot.data;
              if (session == null) {
                return const Center(
                  child: Text('Session ended or unavailable.'),
                );
              }
              _session = session;
              final TokenEngine engine = TokenEngine(
                windowSeconds: session.tokenWindowSeconds,
              );
              _token = engine.currentToken(session.sessionSeed);

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.drive.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.drive.venue),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Current token',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _token,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 12),
                            Text('Rotate every ${session.tokenWindowSeconds}s'),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _continuousAudio
                                        ? null
                                        : () {
                                            setState(() {
                                              _continuousAudio = true;
                                            });
                                            _playToken(session);
                                          },
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text('Start Continuous Audio'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _continuousAudio
                                        ? _stopAudio
                                        : null,
                                    icon: const Icon(Icons.stop_circle),
                                    label: const Text('Stop Audio'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _broadcasting
                                    ? null
                                    : () => _playOneShot(session),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play One Time'),
                              ),
                            ),
                            SwitchListTile(
                              value: _quietMode,
                              onChanged: (bool value) =>
                                  setState(() => _quietMode = value),
                              title: const Text('Quiet mode'),
                              subtitle: const Text(
                                'Longer symbols for noisy rooms.',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Volume: ${(_volume * 100).round()}% (keep above 70%)',
                            ),
                            Slider(
                              value: _volume,
                              onChanged: (double value) =>
                                  setState(() => _volume = value),
                              min: 0.4,
                              max: 1.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => service.endSession(session.id),
                          icon: const Icon(Icons.stop_circle),
                          label: const Text('End session'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _continuousAudio
                              ? (_broadcasting
                                    ? 'Audio broadcasting...'
                                    : 'Preparing audio...')
                              : 'Audio stopped',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _SpcAttendanceList(sessionId: session.id)),
                  ],
                ),
              );
            },
      ),
    );
  }
}

class _SpcAttendanceList extends StatelessWidget {
  const _SpcAttendanceList({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return StreamBuilder<List<AttendanceRecord>>(
      stream: service.watchAttendanceForSession(sessionId),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<AttendanceRecord>> snapshot,
          ) {
            if (snapshot.hasError) {
              return Text('Failed to load attendance. ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const LoadingView(message: 'Loading attendance...');
            }
            final List<AttendanceRecord> records =
                snapshot.data ?? <AttendanceRecord>[];
            return StreamBuilder<List<StudentProfile>>(
              stream: service.watchStudents(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<StudentProfile>> studentSnap,
                  ) {
                    final Map<String, StudentProfile> studentMap = {
                      for (final student
                          in studentSnap.data ?? <StudentProfile>[])
                        student.studentId: student,
                    };
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Present count: ${records.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Realtime marked students',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: records.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final record = records[index];
                                  final name =
                                      studentMap[record.studentId]?.name ??
                                      'Unknown student';
                                  return ListTile(
                                    title: Text('$name • ${record.studentId}'),
                                    subtitle: Text(
                                      'Marked at ${record.markedAt.hour.toString().padLeft(2, '0')}:${record.markedAt.minute.toString().padLeft(2, '0')}',
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }
}
