import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/drive.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_view.dart';

class SpcDriveListScreen extends StatelessWidget {
  const SpcDriveListScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final FirestoreService service = FirestoreService();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('My Drives', style: Theme.of(context).textTheme.headlineSmall),
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
                  return const Center(child: Text('No assigned drives.'));
                }
                return ListView.separated(
                  itemCount: drives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final drive = drives[index];
                    return Card(
                      child: ListTile(
                        title: Text(drive.title),
                        subtitle: Text('${drive.company} • ${DateFormat('dd MMM').format(drive.date)}'),
                        trailing: Chip(label: Text(drive.status.toUpperCase())),
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
