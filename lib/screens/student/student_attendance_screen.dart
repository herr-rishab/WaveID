import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/drive.dart';
import '../../models/drive_student.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_view.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();
    if (user.studentId == null || user.studentId!.isEmpty) {
      return const Center(child: Text('Student ID missing. Contact admin.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('My Drives', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<DriveStudent>>(
              stream: service.watchStudentDrives(user.studentId!),
              builder: (BuildContext context, AsyncSnapshot<List<DriveStudent>> assignmentSnap) {
                if (!assignmentSnap.hasData) {
                  return const LoadingView(message: 'Loading assignments...');
                }
                final List<DriveStudent> assignments = assignmentSnap.data ?? <DriveStudent>[];
                final Set<String> driveIds = assignments.map((item) => item.driveId).toSet();

                return StreamBuilder<List<Drive>>(
                  stream: service.watchDrives(),
                  builder: (BuildContext context, AsyncSnapshot<List<Drive>> driveSnap) {
                    if (!driveSnap.hasData) {
                      return const LoadingView(message: 'Loading drives...');
                    }
                    final List<Drive> drives = driveSnap.data
                            ?.where((drive) => driveIds.contains(drive.id))
                            .toList() ??
                        <Drive>[];

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('attendance')
                          .where('studentId', isEqualTo: user.studentId)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> attendanceSnap) {
                        final Set<String> presentDriveIds = attendanceSnap.data?.docs
                                .map((doc) => doc.data()['driveId']?.toString() ?? '')
                                .where((id) => id.isNotEmpty)
                                .toSet() ??
                            <String>{};

                        if (drives.isEmpty) {
                          return const Center(child: Text('No drives assigned yet.'));
                        }

                        return ListView.separated(
                          itemCount: drives.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final drive = drives[index];
                            final bool present = presentDriveIds.contains(drive.id);
                            return Card(
                              child: ListTile(
                                title: Text(drive.title),
                                subtitle: Text(
                                  '${drive.company} • ${DateFormat('dd MMM yyyy').format(drive.date)}',
                                ),
                                trailing: Chip(
                                  label: Text(present ? 'PRESENT' : 'NOT MARKED'),
                                  backgroundColor: present ? Colors.green.shade100 : null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
