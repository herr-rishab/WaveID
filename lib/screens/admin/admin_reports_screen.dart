import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/drive.dart';
import '../../models/drive_student.dart';
import '../../services/export_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AdminPanel(
              title: 'Reports & Export',
              subtitle:
                  'Download drive-wise attendance CSV with summary stats.',
              child: SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Drive>>(
                stream: service.watchDrives(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Drive>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const LoadingView(message: 'Loading reports...');
                      }
                      final List<Drive> drives = snapshot.data ?? <Drive>[];
                      if (drives.isEmpty) {
                        return const Center(
                          child: Text('No drives to export yet.'),
                        );
                      }
                      return AdminPanel(
                        subtitle:
                            '${drives.length} drives available for export',
                        expandChild: true,
                        child: ListView.separated(
                          itemCount: drives.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final Drive drive = drives[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            drive.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _exportDrive(service, drive),
                                          icon: const Icon(Icons.download),
                                          label: const Text('Export CSV'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${drive.company} • ${DateFormat('dd MMM yyyy').format(drive.date)}',
                                    ),
                                    const SizedBox(height: 12),
                                    _DriveReportStats(driveId: drive.id),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDrive(FirestoreService service, Drive drive) async {
    final List<AttendanceRecord> attendance = await service
        .fetchAttendanceForDrive(drive.id);
    final List<DriveStudent> eligible = await service.fetchDriveStudents(
      drive.id,
    );

    final List<List<dynamic>> rows = <List<dynamic>>[
      <dynamic>['studentId', 'markedAt'],
      ...attendance.map(
        (record) => <dynamic>[
          record.studentId,
          record.markedAt.toIso8601String(),
        ],
      ),
    ];

    rows.add(<dynamic>[]);
    rows.add(<dynamic>['Summary']);
    rows.add(<dynamic>[
      'Eligible',
      eligible.where((item) => item.active).length,
    ]);
    rows.add(<dynamic>['Present', attendance.length]);

    final String csv = const ListToCsvConverter().convert(rows);
    final String filename = 'drive_${drive.id}_attendance.csv';
    await downloadCsv(filename: filename, csv: csv);
  }
}

class _DriveReportStats extends StatelessWidget {
  const _DriveReportStats({required this.driveId});

  final String driveId;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return StreamBuilder<List<DriveStudent>>(
      stream: service.watchDriveStudents(driveId),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<DriveStudent>> studentSnap,
          ) {
            if (studentSnap.hasError) {
              return Text('Failed to load eligibility. ${studentSnap.error}');
            }
            return StreamBuilder<List<AttendanceRecord>>(
              stream: service.watchAttendanceForDrive(driveId),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<AttendanceRecord>> attendanceSnap,
                  ) {
                    if (attendanceSnap.hasError) {
                      return Text(
                        'Failed to load attendance. ${attendanceSnap.error}',
                      );
                    }
                    final int eligible =
                        studentSnap.data?.where((item) => item.active).length ??
                        0;
                    final int present = attendanceSnap.data?.length ?? 0;
                    return Text('Present $present / $eligible students');
                  },
            );
          },
    );
  }
}
