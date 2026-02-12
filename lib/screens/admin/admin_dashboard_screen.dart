import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/drive.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/metric_card.dart';
import 'admin_account_dialog.dart';
import 'drive_form_dialog.dart';
import 'student_import_dialog.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: <Widget>[
          AdminPanel(
            title: 'Welcome back, ${user.name}',
            subtitle:
                'Operational snapshot for placement drives and attendance.',
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          AdminPanel(
            title: 'Quick actions',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          DriveFormDialog(createdBy: user.uid),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Drive'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const StudentImportDialog(),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Students'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const AdminAccountDialog(role: 'student'),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create Student Account'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const AdminAccountDialog(role: 'spc'),
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('Create SPC Account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<Drive>>(
            stream: service.watchDrives(),
            builder: (BuildContext context, AsyncSnapshot<List<Drive>> snapshot) {
              if (!snapshot.hasData) {
                return const LoadingView();
              }
              final List<Drive> drives = snapshot.data ?? <Drive>[];
              final int liveCount = drives
                  .where((drive) => drive.status == 'live')
                  .length;
              final List<Drive> upcoming =
                  drives.where((drive) => !drive.date.isBefore(today)).toList()
                    ..sort((a, b) => a.date.compareTo(b.date));
              final Map<String, Drive> driveMap = <String, Drive>{
                for (final drive in drives) drive.id: drive,
              };
              final int upcomingCount = upcoming.length > 5
                  ? 5
                  : upcoming.length;
              final List<Drive> recentDrives = drives.length > 8
                  ? drives.sublist(0, 8)
                  : drives;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .snapshots(),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                          studentSnap,
                        ) {
                          final int studentCount =
                              studentSnap.data?.docs.length ?? 0;
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream: FirebaseFirestore.instance
                                .collection('sessions')
                                .where('status', isEqualTo: 'active')
                                .snapshots(),
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >
                                  sessionSnap,
                                ) {
                                  final int activeSessions =
                                      sessionSnap.data?.docs.length ?? 0;
                                  return AdminPanel(
                                    title: 'Metrics',
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 260,
                                          child: MetricCard(
                                            label: 'Total Drives',
                                            value: drives.length.toString(),
                                            icon: Icons.event_note,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 260,
                                          child: MetricCard(
                                            label: 'Live Drives',
                                            value: liveCount.toString(),
                                            icon: Icons.wifi_tethering,
                                            accent: Colors.orange,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 260,
                                          child: MetricCard(
                                            label: 'Active Sessions',
                                            value: activeSessions.toString(),
                                            icon: Icons.campaign,
                                            accent: Colors.green,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 260,
                                          child: MetricCard(
                                            label: 'Students',
                                            value: studentCount.toString(),
                                            icon: Icons.school,
                                            accent: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          );
                        },
                  ),
                  const SizedBox(height: 24),
                  AdminPanel(
                    title: 'Upcoming drives',
                    child: upcoming.isEmpty
                        ? const Text('No upcoming drives scheduled.')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: upcomingCount,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final drive = upcoming[index];
                              return Card(
                                child: ListTile(
                                  title: Text(drive.title),
                                  subtitle: Text(
                                    '${drive.company} • ${DateFormat('dd MMM').format(drive.date)}',
                                  ),
                                  trailing: Chip(
                                    label: Text(drive.status.toUpperCase()),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  _RecentAttendanceSection(driveMap: driveMap),
                  const SizedBox(height: 24),
                  AdminPanel(
                    title: 'Recent drives',
                    child: drives.isEmpty
                        ? const Text('No drives yet. Create your first drive.')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentDrives.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final drive = recentDrives[index];
                              return Card(
                                child: ListTile(
                                  title: Text(drive.title),
                                  subtitle: Text(
                                    '${drive.company} • ${drive.venue}',
                                  ),
                                  trailing: Chip(
                                    label: Text(drive.status.toUpperCase()),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentAttendanceSection extends StatelessWidget {
  const _RecentAttendanceSection({required this.driveMap});

  final Map<String, Drive> driveMap;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPanel(
          title: 'Recent attendance',
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: service.watchRecentAttendance(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<AttendanceRecord>> snapshot,
                ) {
                  if (!snapshot.hasData) {
                    return const LoadingView(message: 'Loading attendance...');
                  }
                  final records = snapshot.data ?? <AttendanceRecord>[];
                  if (records.isEmpty) {
                    return const Text('No attendance marked yet.');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final record = records[index];
                      final String driveTitle =
                          driveMap[record.driveId]?.title ?? record.driveId;
                      return ListTile(
                        dense: true,
                        title: Text(record.studentId),
                        subtitle: Text(
                          '$driveTitle • ${DateFormat('dd MMM, hh:mm a').format(record.markedAt)}',
                        ),
                        trailing: Text(
                          record.deviceId,
                          style: Theme.of(context).textTheme.bodySmall,
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
