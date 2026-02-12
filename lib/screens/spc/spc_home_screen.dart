import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/attendance_session.dart';
import '../../models/drive.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_view.dart';
import 'spc_session_screen.dart';

class SpcHomeScreen extends StatelessWidget {
  const SpcHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('SPC Mode', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Welcome ${user.name}. Start attendance for your assigned drives.'),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Drive>>(
              stream: service.watchDrives(),
              builder: (BuildContext context, AsyncSnapshot<List<Drive>> snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingView(message: 'Loading drives...');
                }
                final List<Drive> drives = snapshot.data
                        ?.where((drive) => user.assignedDrives.contains(drive.id))
                        .toList() ??
                    <Drive>[];

                if (drives.isEmpty) {
                  return const Center(child: Text('No assigned drives. Contact admin.'));
                }

                return ListView.separated(
                  itemCount: drives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final Drive drive = drives[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(drive.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('${drive.company} • ${DateFormat('dd MMM yyyy').format(drive.date)}'),
                            const SizedBox(height: 8),
                            StreamBuilder<AttendanceSession?>(
                              stream: service.watchActiveSessionForDrive(drive.id),
                              builder: (BuildContext context,
                                  AsyncSnapshot<AttendanceSession?> sessionSnap) {
                                if (sessionSnap.hasError) {
                                  return Text('Session error: ${sessionSnap.error}');
                                }
                                final AttendanceSession? session = sessionSnap.data;
                                final bool hasActive = session != null && session.isActive;
                                return LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    final bool narrow = constraints.maxWidth < 520;
                                    final List<Widget> chips = <Widget>[
                                      Chip(label: Text(drive.status.toUpperCase())),
                                      if (hasActive) const Chip(label: Text('ACTIVE SESSION')),
                                    ];
                                    final Widget actionButton = ElevatedButton(
                                      onPressed: () async {
                                        final String sessionId = session == null
                                            ? await service.createSession(
                                                driveId: drive.id,
                                                startedBy: user.uid,
                                              )
                                            : session.id;
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<Widget>(
                                              builder: (BuildContext context) => SpcSessionScreen(
                                                drive: drive,
                                                sessionId: sessionId,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(hasActive ? 'Open session' : 'Start session'),
                                    );

                                    if (narrow) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 8,
                                            children: chips,
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(width: double.infinity, child: actionButton),
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: <Widget>[
                                        ...chips
                                            .map(
                                              (chip) => Padding(
                                                padding: const EdgeInsets.only(right: 12),
                                                child: chip,
                                              ),
                                            )
                                            .toList(),
                                        const Spacer(),
                                        actionButton,
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
