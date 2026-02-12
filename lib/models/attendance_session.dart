import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.driveId,
    required this.startedBy,
    required this.startTime,
    required this.status,
    required this.sessionSeed,
    required this.tokenWindowSeconds,
    required this.tokenExpirySeconds,
    this.endTime,
  });

  final String id;
  final String driveId;
  final String startedBy;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int sessionSeed;
  final int tokenWindowSeconds;
  final int tokenExpirySeconds;

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'driveId': driveId,
      'startedBy': startedBy,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime == null ? null : Timestamp.fromDate(endTime!),
      'status': status,
      'sessionSeed': sessionSeed,
      'tokenWindowSeconds': tokenWindowSeconds,
      'tokenExpirySeconds': tokenExpirySeconds,
    };
  }

  factory AttendanceSession.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Session ${doc.id} has no data');
    }
    return AttendanceSession.fromMap(doc.id, data);
  }

  factory AttendanceSession.fromMap(String id, Map<String, dynamic> data) {
    final Timestamp? start = data['startTime'] as Timestamp?;
    final Timestamp? end = data['endTime'] as Timestamp?;
    return AttendanceSession(
      id: id,
      driveId: (data['driveId'] ?? '') as String,
      startedBy: (data['startedBy'] ?? '') as String,
      startTime: (start?.toDate()) ?? DateTime.now(),
      endTime: end?.toDate(),
      status: (data['status'] ?? 'active') as String,
      sessionSeed: (data['sessionSeed'] ?? 0) as int,
      tokenWindowSeconds: (data['tokenWindowSeconds'] ?? 15) as int,
      tokenExpirySeconds: (data['tokenExpirySeconds'] ?? 20) as int,
    );
  }
}
