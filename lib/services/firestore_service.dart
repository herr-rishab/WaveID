import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/drive.dart';
import '../models/drive_student.dart';
import '../models/student_profile.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drives => _firestore.collection('drives');
  CollectionReference<Map<String, dynamic>> get _students => _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get _driveStudents => _firestore.collection('drive_students');
  CollectionReference<Map<String, dynamic>> get _sessions => _firestore.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _attendance => _firestore.collection('attendance');

  Future<void> _commitBatchedWrites(List<void Function(WriteBatch)> operations) async {
    const int maxOps = 450;
    for (int i = 0; i < operations.length; i += maxOps) {
      final WriteBatch batch = _firestore.batch();
      final int end = min(i + maxOps, operations.length);
      for (int j = i; j < end; j++) {
        operations[j](batch);
      }
      await batch.commit();
    }
  }

  Stream<List<Drive>> watchDrives() {
    return _drives.orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Drive.fromSnapshot).toList(),
        );
  }

  Stream<Drive?> watchDrive(String driveId) {
    return _drives.doc(driveId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return Drive.fromMap(doc.id, data);
    });
  }

  Future<String> createDrive(Drive drive) async {
    final doc = _drives.doc();
    await doc.set(drive.copyWith(id: doc.id).toMap());
    return doc.id;
  }

  Future<void> updateDrive(Drive drive) {
    return _drives.doc(drive.id).set(drive.toMap(), SetOptions(merge: true));
  }

  Future<void> updateDriveStatus({required String driveId, required String status}) {
    return _drives.doc(driveId).set(<String, dynamic>{'status': status}, SetOptions(merge: true));
  }

  Future<void> closeDrive({required String driveId}) async {
    final snapshot = await _sessions
        .where('driveId', isEqualTo: driveId)
        .where('status', isEqualTo: 'active')
        .get();
    final WriteBatch batch = _firestore.batch();
    batch.set(_drives.doc(driveId), <String, dynamic>{'status': 'closed'}, SetOptions(merge: true));
    if (snapshot.docs.isNotEmpty) {
      final Timestamp now = Timestamp.fromDate(DateTime.now());
      for (final doc in snapshot.docs) {
        batch.set(
          doc.reference,
          <String, dynamic>{
            'status': 'ended',
            'endTime': now,
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
  }

  Stream<List<StudentProfile>> watchStudents() {
    return _students.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(StudentProfile.fromSnapshot).toList(),
        );
  }

  Future<void> upsertStudent(StudentProfile student) {
    return _students.doc(student.studentId).set(student.toMap(), SetOptions(merge: true));
  }

  Future<void> bulkUpsertStudents(List<StudentProfile> students) async {
    final List<void Function(WriteBatch)> ops = <void Function(WriteBatch)>[];
    for (final student in students) {
      final doc = _students.doc(student.studentId);
      ops.add((WriteBatch batch) => batch.set(doc, student.toMap(), SetOptions(merge: true)));
    }
    await _commitBatchedWrites(ops);
  }

  Future<void> bulkSetDriveStudents({
    required String driveId,
    required List<String> studentIds,
    bool active = true,
    bool deactivateOthers = false,
  }) async {
    final Set<String> uniqueIds = studentIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final List<void Function(WriteBatch)> ops = <void Function(WriteBatch)>[];

    for (final studentId in uniqueIds) {
      final String docId = '${driveId}_$studentId';
      final doc = _driveStudents.doc(docId);
      ops.add(
        (WriteBatch batch) => batch.set(
          doc,
          DriveStudent(
            id: docId,
            driveId: driveId,
            studentId: studentId,
            active: active,
          ).toMap(),
          SetOptions(merge: true),
        ),
      );
    }

    if (deactivateOthers) {
      final List<DriveStudent> existing = await fetchDriveStudents(driveId);
      for (final assignment in existing) {
        if (!uniqueIds.contains(assignment.studentId) && assignment.active) {
          final doc = _driveStudents.doc(assignment.id);
          ops.add(
            (WriteBatch batch) => batch.set(
              doc,
              <String, dynamic>{'active': false, 'updatedAt': Timestamp.now()},
              SetOptions(merge: true),
            ),
          );
        }
      }
    }

    await _commitBatchedWrites(ops);
  }

  Stream<List<DriveStudent>> watchDriveStudents(String driveId) {
    return _driveStudents
        .where('driveId', isEqualTo: driveId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DriveStudent.fromSnapshot).toList());
  }

  Future<List<DriveStudent>> fetchDriveStudents(String driveId) async {
    final snapshot = await _driveStudents.where('driveId', isEqualTo: driveId).get();
    return snapshot.docs.map(DriveStudent.fromSnapshot).toList();
  }

  Stream<List<DriveStudent>> watchStudentDrives(String studentId) {
    return _driveStudents
        .where('studentId', isEqualTo: studentId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(DriveStudent.fromSnapshot).toList());
  }

  Future<void> setDriveStudent({required String driveId, required String studentId, required bool active}) {
    final docId = '${driveId}_$studentId';
    final doc = _driveStudents.doc(docId);
    return doc.set(
      DriveStudent(id: docId, driveId: driveId, studentId: studentId, active: active).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> updateDriveSpcAssignments({
    required String driveId,
    required List<String> spcIds,
    required List<String> previousSpcIds,
  }) async {
    final batch = _firestore.batch();
    batch.set(_drives.doc(driveId), <String, dynamic>{'spcIds': spcIds}, SetOptions(merge: true));

    final Set<String> newSet = spcIds.toSet();
    final Set<String> prevSet = previousSpcIds.toSet();

    for (final spcId in newSet.difference(prevSet)) {
      final userRef = _firestore.collection('users').doc(spcId);
      batch.set(
        userRef,
        <String, dynamic>{'assignedDrives': FieldValue.arrayUnion(<String>[driveId])},
        SetOptions(merge: true),
      );
    }

    for (final spcId in prevSet.difference(newSet)) {
      final userRef = _firestore.collection('users').doc(spcId);
      batch.set(
        userRef,
        <String, dynamic>{'assignedDrives': FieldValue.arrayRemove(<String>[driveId])},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Stream<List<AttendanceSession>> watchSessionsForDrive(String driveId) {
    return _sessions
        .where('driveId', isEqualTo: driveId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AttendanceSession.fromSnapshot).toList());
  }

  Stream<AttendanceSession?> watchActiveSessionForDrive(String driveId) {
    return _sessions
        .where('driveId', isEqualTo: driveId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : AttendanceSession.fromSnapshot(snapshot.docs.first));
  }

  Future<List<AttendanceSession>> fetchActiveSessionsForStudent(String studentId) async {
    final assignments = await _driveStudents
        .where('studentId', isEqualTo: studentId)
        .where('active', isEqualTo: true)
        .get();
    final List<String> driveIds = assignments.docs
        .map((doc) => (doc.data()['driveId'] ?? '') as String)
        .where((id) => id.isNotEmpty)
        .toList();
    if (driveIds.isEmpty) {
      return <AttendanceSession>[];
    }
    final List<String> limited = driveIds.length > 10 ? driveIds.sublist(0, 10) : driveIds;
    final sessions = await _sessions
        .where('driveId', whereIn: limited)
        .where('status', isEqualTo: 'active')
        .get();
    return sessions.docs.map(AttendanceSession.fromSnapshot).toList();
  }

  Future<String> createSession({
    required String driveId,
    required String startedBy,
    int windowSeconds = 15,
    int expirySeconds = 20,
  }) async {
    final doc = _sessions.doc();
    final session = AttendanceSession(
      id: doc.id,
      driveId: driveId,
      startedBy: startedBy,
      startTime: DateTime.now(),
      status: 'active',
      sessionSeed: Random().nextInt(10000),
      tokenWindowSeconds: windowSeconds,
      tokenExpirySeconds: expirySeconds,
    );
    await doc.set(session.toMap());
    await _drives.doc(driveId).set(<String, dynamic>{'status': 'live'}, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> endSession(String sessionId) {
    return _sessions.doc(sessionId).set(
      <String, dynamic>{
        'status': 'ended',
        'endTime': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<AttendanceRecord>> watchAttendanceForSession(String sessionId) {
    return _attendance
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AttendanceRecord.fromSnapshot).toList());
  }

  Stream<List<AttendanceRecord>> watchAttendanceForDrive(String driveId) {
    return _attendance
        .where('driveId', isEqualTo: driveId)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AttendanceRecord.fromSnapshot).toList());
  }

  Stream<List<AttendanceRecord>> watchRecentAttendance({int limit = 8}) {
    return _attendance
        .orderBy('markedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AttendanceRecord.fromSnapshot).toList());
  }

  Future<List<AttendanceRecord>> fetchAttendanceForDrive(String driveId) async {
    final snapshot = await _attendance
        .where('driveId', isEqualTo: driveId)
        .orderBy('markedAt', descending: true)
        .get();
    return snapshot.docs.map(AttendanceRecord.fromSnapshot).toList();
  }

  Future<void> markAttendanceManual({
    required String sessionId,
    required String driveId,
    required String studentId,
    required String deviceId,
  }) {
    final doc = _attendance.doc();
    final record = AttendanceRecord(
      id: doc.id,
      sessionId: sessionId,
      driveId: driveId,
      studentId: studentId,
      markedAt: DateTime.now(),
      deviceId: deviceId,
    );
    return doc.set(record.toMap());
  }
}
