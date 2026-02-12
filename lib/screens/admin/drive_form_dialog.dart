import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drive.dart';
import '../../services/firestore_service.dart';

class DriveFormDialog extends StatefulWidget {
  const DriveFormDialog({super.key, required this.createdBy, this.drive});

  final String createdBy;
  final Drive? drive;

  @override
  State<DriveFormDialog> createState() => _DriveFormDialogState();
}

class _DriveFormDialogState extends State<DriveFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _service = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _venueController;
  late TextEditingController _notesController;
  late DateTime _date;
  String _status = 'draft';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Drive? drive = widget.drive;
    _titleController = TextEditingController(text: drive?.title ?? '');
    _companyController = TextEditingController(text: drive?.company ?? '');
    _venueController = TextEditingController(text: drive?.venue ?? '');
    _notesController = TextEditingController(text: drive?.notes ?? '');
    _date = drive?.date ?? DateTime.now();
    _status = drive?.status ?? 'draft';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (selected != null) {
      setState(() {
        _date = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
    });
    final Drive? existing = widget.drive;
    final Drive drive = Drive(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      company: _companyController.text.trim(),
      date: _date,
      venue: _venueController.text.trim(),
      status: _status,
      createdBy: existing?.createdBy ?? widget.createdBy,
      notes: _notesController.text.trim(),
      spcIds: existing?.spcIds ?? const <String>[],
    );
    if (existing == null) {
      await _service.createDrive(drive);
    } else {
      await _service.updateDrive(drive);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.drive == null ? 'Create Drive' : 'Edit Drive'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Drive Title'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue / Room'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Date: ${DateFormat('dd MMM yyyy').format(_date)}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'live', child: Text('Live')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const Text('Saving...') : const Text('Save'),
        ),
      ],
    );
  }
}
