import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.driveId,
    required this.studentId,
    required this.markedAt,
    required this.deviceId,
  });

  final String id;
  final String sessionId;
  final String driveId;
  final String studentId;
  final DateTime markedAt;
  final String deviceId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'driveId': driveId,
      'studentId': studentId,
      'markedAt': Timestamp.fromDate(markedAt),
      'deviceId': deviceId,
    };
  }

  factory AttendanceRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Attendance ${doc.id} has no data');
    }
    return AttendanceRecord.fromMap(doc.id, data);
  }

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> data) {
    final Timestamp? marked = data['markedAt'] as Timestamp?;
    return AttendanceRecord(
      id: id,
      sessionId: (data['sessionId'] ?? '') as String,
      driveId: (data['driveId'] ?? '') as String,
      studentId: (data['studentId'] ?? '') as String,
      markedAt: (marked?.toDate()) ?? DateTime.now(),
      deviceId: (data['deviceId'] ?? '') as String,
    );
  }
}
