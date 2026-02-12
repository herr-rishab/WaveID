import 'package:flutter/material.dart';

import '../../models/student_profile.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/loading_view.dart';
import 'admin_account_dialog.dart';
import 'student_form_dialog.dart';
import 'student_import_dialog.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final FirestoreService _service = FirestoreService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AdminPanel(
              title: 'Students',
              subtitle:
                  'Profiles control eligibility; accounts are for app login.',
              actions: <Widget>[
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const StudentImportDialog(),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Bulk import CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const AdminAccountDialog(role: 'student'),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create student account'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) =>
                          const StudentFormDialog(),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: const Text('Add student profile'),
                ),
              ],
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            AdminPanel(
              child: TextField(
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<StudentProfile>>(
                stream: _service.watchStudents(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<StudentProfile>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const LoadingView(
                          message: 'Loading students...',
                        );
                      }
                      final List<StudentProfile> students =
                          snapshot.data ?? <StudentProfile>[];
                      final List<StudentProfile> filtered = students.where((
                        student,
                      ) {
                        if (_query.isEmpty) {
                          return true;
                        }
                        return student.name.toLowerCase().contains(_query) ||
                            student.studentId.toLowerCase().contains(_query) ||
                            student.department.toLowerCase().contains(_query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No students found.'));
                      }

                      return AdminPanel(
                        subtitle: '${filtered.length} students',
                        expandChild: true,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final student = filtered[index];
                            return Card(
                              child: ListTile(
                                title: Text(student.name),
                                subtitle: Text(
                                  '${student.studentId} • ${student.department} ${student.year}${student.section}',
                                ),
                                trailing: Text(student.email),
                                onTap: () async {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        StudentFormDialog(student: student),
                                  );
                                },
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
