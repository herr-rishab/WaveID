import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class DriveStudentImportDialog extends StatefulWidget {
  const DriveStudentImportDialog({super.key, required this.driveId});

  final String driveId;

  @override
  State<DriveStudentImportDialog> createState() => _DriveStudentImportDialogState();
}

class _DriveStudentImportDialogState extends State<DriveStudentImportDialog> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _service = FirestoreService();
  String? _error;
  bool _saving = false;
  bool _deactivateOthers = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseStudentIds(String raw, List<String> invalid) {
    final Set<String> ids = <String>{};
    try {
      final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(raw);
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].isEmpty) {
          continue;
        }
        final String value = rows[i][0].toString().trim();
        if (value.isEmpty) {
          continue;
        }
        if (i == 0 && value.toLowerCase().contains('student')) {
          continue;
        }
        if (value.contains('/')) {
          invalid.add(value);
          continue;
        }
        ids.add(value);
      }
    } catch (_) {
      final parts = raw.split(RegExp(r'[\n,;\t]+'));
      for (final part in parts) {
        final String value = part.trim();
        if (value.isEmpty) {
          continue;
        }
        if (value.contains('/')) {
          invalid.add(value);
          continue;
        }
        ids.add(value);
      }
    }
    return ids.toList();
  }

  Future<void> _import() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final String raw = _controller.text.trim();
      if (raw.isEmpty) {
        setState(() {
          _error = 'Paste student IDs to import.';
        });
        return;
      }
      final List<String> invalid = <String>[];
      final List<String> studentIds = _parseStudentIds(raw, invalid);
      if (studentIds.isEmpty) {
        setState(() {
          _error = 'No valid student IDs found.';
        });
        return;
      }
      if (invalid.isNotEmpty) {
        setState(() {
          _error = 'Skipped ${invalid.length} invalid IDs (contains /).';
        });
      }
      await _service.bulkSetDriveStudents(
        driveId: widget.driveId,
        studentIds: studentIds,
        active: true,
        deactivateOthers: _deactivateOthers,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _error = 'Unable to import students. ${error.toString()}';
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
      title: const Text('Bulk assign students'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Paste student IDs (CSV or one per line). Example header: studentId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'studentId\nstudentId\nstudentId',
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _deactivateOthers,
              onChanged: _saving
                  ? null
                  : (bool? value) {
                      setState(() {
                        _deactivateOthers = value ?? false;
                      });
                    },
              title: const Text('Deactivate students not in this list'),
              subtitle: const Text('Use carefully for full refresh imports.'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
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
