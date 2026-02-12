import 'package:cloud_firestore/cloud_firestore.dart';

class DriveStudent {
  const DriveStudent({
    required this.id,
    required this.driveId,
    required this.studentId,
    required this.active,
  });

  final String id;
  final String driveId;
  final String studentId;
  final bool active;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'driveId': driveId,
      'studentId': studentId,
      'active': active,
      'updatedAt': Timestamp.now(),
    };
  }

  factory DriveStudent.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Drive student ${doc.id} has no data');
    }
    return DriveStudent.fromMap(doc.id, data);
  }

  factory DriveStudent.fromMap(String id, Map<String, dynamic> data) {
    return DriveStudent(
      id: id,
      driveId: (data['driveId'] ?? '') as String,
      studentId: (data['studentId'] ?? '') as String,
      active: (data['active'] ?? false) as bool,
    );
  }
}
