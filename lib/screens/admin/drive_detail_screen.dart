import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_session.dart';
import '../../models/drive.dart';
import '../../models/drive_student.dart';
import '../../models/student_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/metric_card.dart';
import 'drive_student_import_dialog.dart';

class DriveDetailScreen extends StatelessWidget {
  const DriveDetailScreen({super.key, required this.driveId});

  final String driveId;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return StreamBuilder<Drive?>(
      stream: service.watchDrive(driveId),
      builder: (BuildContext context, AsyncSnapshot<Drive?> snapshot) {
        final Drive? drive = snapshot.data;
        if (drive == null) {
          return const Scaffold(body: LoadingView(message: 'Loading drive...'));
        }
        return Scaffold(
          appBar: AppBar(title: Text(drive.title)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  _SectionCard(
                    title: 'Overview',
                    child: _DriveOverviewSection(drive: drive),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Eligible students',
                    actions: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (BuildContext context) =>
                                DriveStudentImportDialog(driveId: drive.id),
                          );
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Bulk assign'),
                      ),
                    ],
                    child: _DriveStudentsSection(driveId: drive.id),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'SPC assignments',
                    child: _DriveSpcSection(drive: drive),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Sessions',
                    child: _DriveSessionsSection(drive: drive),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Attendance',
                    child: _DriveAttendanceSection(driveId: drive.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DriveOverviewSection extends StatelessWidget {
  const _DriveOverviewSection({required this.drive});

  final Drive drive;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(drive.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${drive.company} • ${drive.venue}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Chip(label: Text(drive.status.toUpperCase())),
            OutlinedButton.icon(
              onPressed: drive.status == 'live'
                  ? null
                  : () => service.updateDriveStatus(
                      driveId: drive.id,
                      status: 'live',
                    ),
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Mark live'),
            ),
            OutlinedButton.icon(
              onPressed: drive.status == 'closed'
                  ? null
                  : () => service.closeDrive(driveId: drive.id),
              icon: const Icon(Icons.stop_circle),
              label: const Text('Close drive'),
            ),
            TextButton(
              onPressed: drive.status == 'draft'
                  ? null
                  : () => service.updateDriveStatus(
                      driveId: drive.id,
                      status: 'draft',
                    ),
              child: const Text('Set draft'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _OverviewInfoTile(
              label: 'Date',
              value: DateFormat('dd MMM yyyy').format(drive.date),
              icon: Icons.calendar_month,
            ),
            _OverviewInfoTile(
              label: 'Venue',
              value: drive.venue,
              icon: Icons.location_on_outlined,
            ),
            _OverviewInfoTile(
              label: 'Company',
              value: drive.company,
              icon: Icons.business,
            ),
            StreamBuilder<List<DriveStudent>>(
              stream: service.watchDriveStudents(drive.id),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<DriveStudent>> snapshot,
                  ) {
                    final int eligible =
                        snapshot.data?.where((item) => item.active).length ?? 0;
                    return _OverviewInfoTile(
                      label: 'Eligible',
                      value: '$eligible students',
                      icon: Icons.how_to_reg,
                    );
                  },
            ),
            _OverviewInfoTile(
              label: 'Assigned SPCs',
              value: drive.spcIds.length.toString(),
              icon: Icons.campaign_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _OverviewNote(
          note: drive.notes.isEmpty
              ? 'No notes added for this drive.'
              : drive.notes,
        ),
      ],
    );
  }
}

class _OverviewInfoTile extends StatelessWidget {
  const _OverviewInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _OverviewNote extends StatelessWidget {
  const _OverviewNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(note, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DriveStudentsSection extends StatefulWidget {
  const _DriveStudentsSection({required this.driveId});

  final String driveId;

  @override
  State<_DriveStudentsSection> createState() => _DriveStudentsSectionState();
}

class _DriveStudentsSectionState extends State<_DriveStudentsSection> {
  final FirestoreService _service = FirestoreService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final double listHeight = _sectionListHeight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search students',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (String value) {
            setState(() {
              _query = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: listHeight,
          child: StreamBuilder<List<StudentProfile>>(
            stream: _service.watchStudents(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<StudentProfile>> studentSnap,
                ) {
                  if (studentSnap.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load students. ${studentSnap.error}',
                      ),
                    );
                  }
                  if (!studentSnap.hasData) {
                    return const LoadingView();
                  }
                  final List<StudentProfile> students =
                      studentSnap.data ?? <StudentProfile>[];
                  return StreamBuilder<List<DriveStudent>>(
                    stream: _service.watchDriveStudents(widget.driveId),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<DriveStudent>> driveSnap,
                        ) {
                          if (driveSnap.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load eligibility. ${driveSnap.error}',
                              ),
                            );
                          }
                          if (!driveSnap.hasData) {
                            return const LoadingView(
                              message: 'Loading eligibility...',
                            );
                          }
                          final assignments =
                              driveSnap.data ?? <DriveStudent>[];
                          final Set<String> activeIds = assignments
                              .where((item) => item.active)
                              .map((item) => item.studentId)
                              .toSet();

                          final filtered = students.where((student) {
                            if (_query.isEmpty) {
                              return true;
                            }
                            return student.name.toLowerCase().contains(
                                  _query,
                                ) ||
                                student.studentId.toLowerCase().contains(
                                  _query,
                                ) ||
                                student.department.toLowerCase().contains(
                                  _query,
                                );
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text('No students match your search.'),
                            );
                          }

                          return Card(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final student = filtered[index];
                                final bool active = activeIds.contains(
                                  student.studentId,
                                );
                                return CheckboxListTile(
                                  value: active,
                                  onChanged: (bool? value) {
                                    _service.setDriveStudent(
                                      driveId: widget.driveId,
                                      studentId: student.studentId,
                                      active: value ?? false,
                                    );
                                  },
                                  title: Text(student.name),
                                  subtitle: Text(
                                    '${student.studentId} • ${student.department} ${student.year}${student.section}',
                                  ),
                                );
                              },
                            ),
                          );
                        },
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _DriveSpcSection extends StatefulWidget {
  const _DriveSpcSection({required this.drive});

  final Drive drive;

  @override
  State<_DriveSpcSection> createState() => _DriveSpcSectionState();
}

class _DriveSpcSectionState extends State<_DriveSpcSection> {
  final FirestoreService _service = FirestoreService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _userService.watchUsersByRole('spc'),
      builder: (BuildContext context, AsyncSnapshot<List<AppUser>> snapshot) {
        if (snapshot.hasError) {
          return Text('Failed to load SPCs. ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const LoadingView();
        }
        final spcs = snapshot.data ?? <AppUser>[];
        if (spcs.isEmpty) {
          return const Text('No SPC accounts found.');
        }

        final Set<String> selected = widget.drive.spcIds.toSet();
        final double listHeight = _sectionListHeight(
          context,
          factor: 0.3,
          min: 220,
          max: 360,
        );

        return SizedBox(
          height: listHeight,
          child: Card(
            child: ListView.separated(
              itemCount: spcs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final spc = spcs[index];
                final bool active = selected.contains(spc.uid);
                return CheckboxListTile(
                  value: active,
                  onChanged: (bool? value) async {
                    final Set<String> updated = Set<String>.from(selected);
                    if (value == true) {
                      updated.add(spc.uid);
                    } else {
                      updated.remove(spc.uid);
                    }
                    await _service.updateDriveSpcAssignments(
                      driveId: widget.drive.id,
                      spcIds: updated.toList(),
                      previousSpcIds: widget.drive.spcIds,
                    );
                  },
                  title: Text(spc.name),
                  subtitle: Text(spc.uid),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DriveSessionsSection extends StatelessWidget {
  const _DriveSessionsSection({required this.drive});

  final Drive drive;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    final double listHeight = _sectionListHeight(
      context,
      factor: 0.4,
      min: 280,
      max: 520,
    );
    return StreamBuilder<List<AttendanceSession>>(
      stream: service.watchSessionsForDrive(drive.id),
      builder: (BuildContext context, AsyncSnapshot<List<AttendanceSession>> snapshot) {
        if (snapshot.hasError) {
          return Text('Failed to load sessions. ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const LoadingView(message: 'Loading sessions...');
        }
        final sessions = snapshot.data ?? <AttendanceSession>[];
        if (sessions.isEmpty) {
          return const Text('No sessions yet.');
        }
        return SizedBox(
          height: listHeight,
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final session = sessions[index];
              return Card(
                child: ExpansionTile(
                  title: Text(
                    'Session ${DateFormat('dd MMM, hh:mm a').format(session.startTime)}',
                  ),
                  subtitle: Text(session.status.toUpperCase()),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Started by: ${session.startedBy}'),
                          if (session.endTime != null)
                            Text(
                              'Ended: ${DateFormat('dd MMM, hh:mm a').format(session.endTime!)}',
                            ),
                          const SizedBox(height: 12),
                          if (session.isActive)
                            Row(
                              children: <Widget>[
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      service.endSession(session.id),
                                  icon: const Icon(Icons.stop_circle),
                                  label: const Text('End session'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showManualMark(context, session),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Manual mark'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          _SessionAttendanceList(sessionId: session.id),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showManualMark(
    BuildContext context,
    AttendanceSession session,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Manual mark present'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              hintText: 'Enter student ID',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String studentId = controller.text.trim();
                if (studentId.isEmpty) {
                  return;
                }
                await FirestoreService().markAttendanceManual(
                  sessionId: session.id,
                  driveId: session.driveId,
                  studentId: studentId,
                  deviceId: 'admin',
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Mark present'),
            ),
          ],
        );
      },
    );
  }
}

class _SessionAttendanceList extends StatelessWidget {
  const _SessionAttendanceList({required this.sessionId});

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
            final records = snapshot.data ?? <AttendanceRecord>[];
            if (records.isEmpty) {
              return const Text('No attendance marked yet.');
            }
            return StreamBuilder<List<StudentProfile>>(
              stream: service.watchStudents(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<StudentProfile>> studentSnap,
                  ) {
                    if (studentSnap.hasError) {
                      return Text(
                        'Failed to load students. ${studentSnap.error}',
                      );
                    }
                    final Map<String, StudentProfile> studentMap = {
                      for (final student
                          in studentSnap.data ?? <StudentProfile>[])
                        student.studentId: student,
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Present count: ${records.length}'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
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
                                dense: true,
                                title: Text('$name • ${record.studentId}'),
                                subtitle: Text(
                                  DateFormat('hh:mm a').format(record.markedAt),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
            );
          },
    );
  }
}

class _DriveAttendanceSection extends StatefulWidget {
  const _DriveAttendanceSection({required this.driveId});

  final String driveId;

  @override
  State<_DriveAttendanceSection> createState() =>
      _DriveAttendanceSectionState();
}

class _DriveAttendanceSectionState extends State<_DriveAttendanceSection> {
  String _query = '';
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    final double listHeight = _sectionListHeight(
      context,
      factor: 0.4,
      min: 260,
      max: 520,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search by name, ID, department',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (String value) {
            setState(() {
              _query = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 0, label: Text('Present')),
            ButtonSegment<int>(value: 1, label: Text('Absent')),
            ButtonSegment<int>(value: 2, label: Text('All eligible')),
          ],
          selected: <int>{_segment},
          onSelectionChanged: (Set<int> selection) {
            setState(() {
              _segment = selection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<StudentProfile>>(
          stream: service.watchStudents(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<StudentProfile>> studentSnap,
              ) {
                if (studentSnap.hasError) {
                  return Text('Failed to load students. ${studentSnap.error}');
                }
                if (!studentSnap.hasData) {
                  return const LoadingView(message: 'Loading students...');
                }
                final List<StudentProfile> students =
                    studentSnap.data ?? <StudentProfile>[];
                final Map<String, StudentProfile> studentMap = {
                  for (final student in students) student.studentId: student,
                };
                return StreamBuilder<List<DriveStudent>>(
                  stream: service.watchDriveStudents(widget.driveId),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<DriveStudent>> driveSnap,
                      ) {
                        if (driveSnap.hasError) {
                          return Text(
                            'Failed to load eligibility. ${driveSnap.error}',
                          );
                        }
                        if (!driveSnap.hasData) {
                          return const LoadingView(
                            message: 'Loading eligibility...',
                          );
                        }
                        final List<DriveStudent> assignments =
                            driveSnap.data ?? <DriveStudent>[];
                        final Set<String> eligibleIds = assignments
                            .where((item) => item.active)
                            .map((item) => item.studentId)
                            .toSet();
                        return StreamBuilder<List<AttendanceRecord>>(
                          stream: service.watchAttendanceForDrive(
                            widget.driveId,
                          ),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<List<AttendanceRecord>>
                                attendanceSnap,
                              ) {
                                if (attendanceSnap.hasError) {
                                  return Text(
                                    'Failed to load attendance. ${attendanceSnap.error}',
                                  );
                                }
                                if (!attendanceSnap.hasData) {
                                  return const LoadingView(
                                    message: 'Loading attendance...',
                                  );
                                }
                                final Set<String> presentIds =
                                    attendanceSnap.data
                                        ?.map((record) => record.studentId)
                                        .toSet() ??
                                    <String>{};
                                final Set<String> presentEligible = presentIds
                                    .intersection(eligibleIds);
                                final Set<String> absentIds = eligibleIds
                                    .difference(presentEligible);

                                final int totalStudents = students.length;
                                final int totalEligible = eligibleIds.length;
                                final int totalPresent = presentEligible.length;
                                final int totalAbsent = absentIds.length;

                                final List<_StudentRow> presentRows =
                                    _buildRows(
                                      presentEligible,
                                      studentMap,
                                      _query,
                                    );
                                final List<_StudentRow> absentRows = _buildRows(
                                  absentIds,
                                  studentMap,
                                  _query,
                                );
                                final List<_StudentRow> allRows = _buildRows(
                                  eligibleIds,
                                  studentMap,
                                  _query,
                                );

                                final List<_StudentRow> rows = _segment == 0
                                    ? presentRows
                                    : _segment == 1
                                    ? absentRows
                                    : allRows;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 240,
                                          child: MetricCard(
                                            label: 'Total Students',
                                            value: totalStudents.toString(),
                                            icon: Icons.school,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: MetricCard(
                                            label: 'Eligible',
                                            value: totalEligible.toString(),
                                            icon: Icons.how_to_reg,
                                            accent: Colors.indigo,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: MetricCard(
                                            label: 'Present',
                                            value: totalPresent.toString(),
                                            icon: Icons.check_circle,
                                            accent: Colors.green,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 240,
                                          child: MetricCard(
                                            label: 'Absent',
                                            value: totalAbsent.toString(),
                                            icon: Icons.remove_circle,
                                            accent: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _segment == 0
                                          ? 'Present students'
                                          : _segment == 1
                                          ? 'Absent students'
                                          : 'All eligible students',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: listHeight,
                                      child: Card(
                                        child: rows.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'No students match your filters.',
                                                ),
                                              )
                                            : ListView.separated(
                                                itemCount: rows.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final _StudentRow row =
                                                          rows[index];
                                                      return ListTile(
                                                        title: Text(row.name),
                                                        subtitle: Text(
                                                          row.subtitle,
                                                        ),
                                                        trailing: Text(
                                                          row.studentId,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                        ),
                                                      );
                                                    },
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                        );
                      },
                );
              },
        ),
      ],
    );
  }

  List<_StudentRow> _buildRows(
    Set<String> ids,
    Map<String, StudentProfile> studentMap,
    String query,
  ) {
    final List<String> sortedIds = ids.toList()
      ..sort((a, b) {
        final String nameA = studentMap[a]?.name.toLowerCase() ?? '';
        final String nameB = studentMap[b]?.name.toLowerCase() ?? '';
        if (nameA.isEmpty && nameB.isEmpty) {
          return a.compareTo(b);
        }
        if (nameA.isEmpty) {
          return 1;
        }
        if (nameB.isEmpty) {
          return -1;
        }
        final int nameCompare = nameA.compareTo(nameB);
        return nameCompare != 0 ? nameCompare : a.compareTo(b);
      });

    final List<_StudentRow> rows = <_StudentRow>[];
    for (final String studentId in sortedIds) {
      final StudentProfile? student = studentMap[studentId];
      final String name = (student?.name ?? '').isNotEmpty
          ? student!.name
          : 'Unknown student';
      final String dept = student?.department ?? '';
      final String year = student?.year ?? '';
      final String section = student?.section ?? '';
      final String group = [
        dept,
        '$year$section',
      ].where((value) => value.trim().isNotEmpty).join(' ');
      final String subtitle = group.isEmpty ? studentId : '$studentId • $group';

      if (query.isNotEmpty) {
        final String haystack = [
          studentId,
          name,
          dept,
          year,
          section,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          continue;
        }
      }

      rows.add(
        _StudentRow(studentId: studentId, name: name, subtitle: subtitle),
      );
    }
    return rows;
  }
}

class _StudentRow {
  const _StudentRow({
    required this.studentId,
    required this.name,
    required this.subtitle,
  });

  final String studentId;
  final String name;
  final String subtitle;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: title,
      actions: actions,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

double _sectionListHeight(
  BuildContext context, {
  double min = 260,
  double max = 420,
  double factor = 0.35,
}) {
  return (MediaQuery.of(context).size.height * factor)
      .clamp(min, max)
      .toDouble();
}
