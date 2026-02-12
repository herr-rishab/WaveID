import 'package:cloud_firestore/cloud_firestore.dart';

class Drive {
  const Drive({
    required this.id,
    required this.title,
    required this.company,
    required this.date,
    required this.venue,
    required this.status,
    required this.createdBy,
    this.notes = '',
    this.spcIds = const <String>[],
  });

  final String id;
  final String title;
  final String company;
  final DateTime date;
  final String venue;
  final String status;
  final String createdBy;
  final String notes;
  final List<String> spcIds;

  Drive copyWith({
    String? id,
    String? title,
    String? company,
    DateTime? date,
    String? venue,
    String? status,
    String? createdBy,
    String? notes,
    List<String>? spcIds,
  }) {
    return Drive(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      spcIds: spcIds ?? this.spcIds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'company': company,
      'date': Timestamp.fromDate(date),
      'venue': venue,
      'status': status,
      'createdBy': createdBy,
      'notes': notes,
      'spcIds': spcIds,
    };
  }

  factory Drive.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Drive ${doc.id} has no data');
    }
    return Drive.fromMap(doc.id, data);
  }

  factory Drive.fromMap(String id, Map<String, dynamic> data) {
    final Timestamp? timestamp = data['date'] as Timestamp?;
    return Drive(
      id: id,
      title: (data['title'] ?? '') as String,
      company: (data['company'] ?? '') as String,
      date: (timestamp?.toDate()) ?? DateTime.now(),
      venue: (data['venue'] ?? '') as String,
      status: (data['status'] ?? 'draft') as String,
      createdBy: (data['createdBy'] ?? '') as String,
      notes: (data['notes'] ?? '') as String,
      spcIds: List<String>.from(data['spcIds'] ?? const <String>[]),
    );
  }
}
