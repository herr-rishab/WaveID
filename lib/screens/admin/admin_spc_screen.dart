import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';
import 'admin_account_dialog.dart';

class AdminSpcScreen extends StatelessWidget {
  const AdminSpcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService service = UserService();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AdminPanel(
              title: 'SPC Assignments',
              subtitle: 'Create SPC accounts and track assigned drives.',
              actions: <Widget>[
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const AdminAccountDialog(role: 'spc'),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create SPC account'),
                ),
              ],
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: service.watchUsersByRole('spc'),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<AppUser>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const LoadingView(message: 'Loading SPCs...');
                      }
                      final List<AppUser> spcs = snapshot.data ?? <AppUser>[];
                      if (spcs.isEmpty) {
                        return const Center(
                          child: Text('No SPC accounts found.'),
                        );
                      }
                      return AdminPanel(
                        subtitle: '${spcs.length} SPC accounts',
                        expandChild: true,
                        child: ListView.separated(
                          itemCount: spcs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final spc = spcs[index];
                            final String driveList = spc.assignedDrives.isEmpty
                                ? 'No assigned drives'
                                : spc.assignedDrives.join(', ');
                            return Card(
                              child: ListTile(
                                title: Text(spc.name),
                                subtitle: Text(driveList),
                                trailing: Text(
                                  spc.uid,
                                  style: Theme.of(context).textTheme.bodySmall,
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
