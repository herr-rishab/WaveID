import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_session.dart';
import 'token_engine.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<MarkAttendanceResult> markAttendance({
    required String sessionId,
    required String studentId,
    required String token,
    required String deviceId,
    String? driveId,
  }) async {
    try {
      final String cleanStudentId = studentId.trim();
      final String cleanToken = token.trim();
      if (cleanStudentId.isEmpty || cleanToken.isEmpty) {
        return const MarkAttendanceResult(
          status: 'invalid-argument',
          message: 'Missing student ID or token.',
        );
      }

      AttendanceSession? session;
      DocumentSnapshot<Map<String, dynamic>>? sessionSnap;

      if (sessionId.trim().isNotEmpty) {
        sessionSnap = await _firestore.collection('sessions').doc(sessionId.trim()).get();
      }

      if (sessionSnap == null || !sessionSnap.exists) {
        final String? cleanDriveId = driveId?.trim().isNotEmpty == true ? driveId!.trim() : null;
        if (cleanDriveId != null) {
          final QuerySnapshot<Map<String, dynamic>> fallback = await _firestore
              .collection('sessions')
              .where('driveId', isEqualTo: cleanDriveId)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
          if (fallback.docs.isNotEmpty) {
            sessionSnap = fallback.docs.first;
          }
        }
      }

      if (sessionSnap == null || !sessionSnap.exists) {
        return const MarkAttendanceResult(
          status: 'not-found',
          message: 'Session not found.',
        );
      }

      session = AttendanceSession.fromMap(sessionSnap.id, sessionSnap.data() ?? <String, dynamic>{});
      if (!session.isActive) {
        return const MarkAttendanceResult(
          status: 'ended',
          message: 'Session has ended.',
        );
      }

      final TokenEngine engine = TokenEngine(windowSeconds: session.tokenWindowSeconds);
      final bool valid = engine.isTokenValid(cleanToken, session.sessionSeed);
      if (!valid) {
        return const MarkAttendanceResult(
          status: 'token_expired',
          message: 'Token expired, try again.',
        );
      }

      final String resolvedDriveId = session.driveId.isNotEmpty ? session.driveId : (driveId ?? '');
      if (resolvedDriveId.isEmpty) {
        return const MarkAttendanceResult(
          status: 'not-found',
          message: 'Drive not found for session.',
        );
      }

      final String eligibilityId = '${resolvedDriveId}_$cleanStudentId';
      final eligibilitySnap =
          await _firestore.collection('drive_students').doc(eligibilityId).get();
      if (!eligibilitySnap.exists || eligibilitySnap.data()?['active'] != true) {
        return const MarkAttendanceResult(
          status: 'ineligible',
          message: 'You are not eligible for this drive.',
        );
      }

      final existing = await _firestore
          .collection('attendance')
          .where('sessionId', isEqualTo: session.id)
          .where('studentId', isEqualTo: cleanStudentId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return const MarkAttendanceResult(
          status: 'already',
          message: 'Attendance already marked.',
        );
      }

      await _firestore.collection('attendance').add(<String, dynamic>{
        'sessionId': session.id,
        'driveId': resolvedDriveId,
        'studentId': cleanStudentId,
        // Firestore rules require a concrete timestamp on create.
        // `FieldValue.serverTimestamp()` is a sentinel and fails `is timestamp`.
        'markedAt': Timestamp.now(),
        'deviceId': deviceId.trim().isEmpty ? 'unknown' : deviceId.trim(),
      });

      return const MarkAttendanceResult(
        status: 'ok',
        message: 'Attendance marked present.',
      );
    } on FirebaseException catch (e) {
      // Surface the real failure mode (e.g. permission-denied) instead of a generic "network error".
      final String code = (e.code).trim().isEmpty ? 'firebase-error' : e.code.trim();
      final String msg = (e.message ?? '').trim();
      return MarkAttendanceResult(
        status: code,
        message: msg.isEmpty ? code : msg,
      );
    } catch (e) {
      return MarkAttendanceResult(
        status: 'error',
        message: e.toString(),
      );
    }
  }
}

class MarkAttendanceResult {
  const MarkAttendanceResult({required this.status, required this.message});

  final String status;
  final String message;

  bool get isSuccess => status == 'ok' || status == 'success';
}
