import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../../models/student_profile.dart';
import '../../services/firestore_service.dart';

class StudentImportDialog extends StatefulWidget {
  const StudentImportDialog({super.key});

  @override
  State<StudentImportDialog> createState() => _StudentImportDialogState();
}

class _StudentImportDialogState extends State<StudentImportDialog> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _service = FirestoreService();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final String raw = _controller.text.trim();
      final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(raw);
      final bool hasHeader = rows.isNotEmpty &&
          rows.first.isNotEmpty &&
          rows.first.first.toString().toLowerCase().contains('student');
      final int startIndex = hasHeader ? 1 : 0;
      if (rows.length <= startIndex) {
        setState(() {
          _error = 'CSV must include at least one student row.';
        });
        return;
      }
      final List<StudentProfile> students = <StudentProfile>[];
      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 7) {
          continue;
        }
        students.add(
          StudentProfile(
            studentId: row[0].toString().trim(),
            name: row[1].toString().trim(),
            email: row[2].toString().trim(),
            phone: row[3].toString().trim(),
            department: row[4].toString().trim(),
            year: row[5].toString().trim(),
            section: row[6].toString().trim(),
          ),
        );
      }
      if (students.isEmpty) {
        setState(() {
          _error = 'No valid student rows found.';
        });
        return;
      }
      await _service.bulkUpsertStudents(students);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (error) {
      setState(() {
        _error = error.message ?? 'Unable to import. Check Firestore rules.';
      });
    } catch (error) {
      setState(() {
        _error = 'Invalid CSV format. Make sure it is comma-separated.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk import students'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Paste CSV with columns: studentId,name,email,phone,department,year,section (header optional).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'studentId,name,email,phone,department,year,section',
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _import,
          child: _saving ? const Text('Importing...') : const Text('Import'),
        ),
      ],
    );
  }
}
