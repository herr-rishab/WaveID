import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/drive.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';
import 'drive_detail_screen.dart';
import 'drive_form_dialog.dart';

class AdminDrivesScreen extends StatelessWidget {
  const AdminDrivesScreen({super.key, required this.user});

  final AppUser user;

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
            AdminPanel(
              title: 'Drives',
              subtitle: 'Manage drive details, status, and eligibility.',
              actions: <Widget>[
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          DriveFormDialog(createdBy: user.uid),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Drive'),
                ),
              ],
              child: const SizedBox.shrink(),
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
                        return const LoadingView(message: 'Loading drives...');
                      }
                      final drives = snapshot.data ?? <Drive>[];
                      if (drives.isEmpty) {
                        return const Center(
                          child: Text('No drives created yet.'),
                        );
                      }
                      return AdminPanel(
                        subtitle: '${drives.length} drives',
                        expandChild: true,
                        child: ListView.separated(
                          itemCount: drives.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final drive = drives[index];
                            return Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<Widget>(
                                      builder: (BuildContext context) =>
                                          DriveDetailScreen(driveId: drive.id),
                                    ),
                                  );
                                },
                                title: Text(drive.title),
                                subtitle: Text(
                                  '${drive.company} • ${DateFormat('dd MMM yyyy').format(drive.date)} • ${drive.venue}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: <Widget>[
                                    Chip(
                                      label: Text(drive.status.toUpperCase()),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit drive',
                                      onPressed: () async {
                                        await showDialog<void>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              DriveFormDialog(
                                                createdBy: user.uid,
                                                drive: drive,
                                              ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Drive actions',
                                      onSelected: (String value) {
                                        if (value == 'live') {
                                          service.updateDriveStatus(
                                            driveId: drive.id,
                                            status: 'live',
                                          );
                                        } else if (value == 'closed') {
                                          service.closeDrive(driveId: drive.id);
                                        } else if (value == 'draft') {
                                          service.updateDriveStatus(
                                            driveId: drive.id,
                                            status: 'draft',
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'live',
                                              child: Text('Mark live'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'closed',
                                              child: Text('Close drive'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'draft',
                                              child: Text('Set draft'),
                                            ),
                                          ],
                                    ),
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
}
