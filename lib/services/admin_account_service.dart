import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AdminAccountService {
  AdminAccountService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<CreateAccountResult> createUserAccount({
    required String role,
    required String email,
    required String password,
    required String name,
    String? studentId,
    Map<String, dynamic>? studentProfile,
  }) async {
    FirebaseApp? secondaryApp;
    User? createdUser;

    try {
      final User? adminUser = _auth.currentUser;
      if (adminUser == null) {
        return const CreateAccountResult(
          status: 'unauthenticated',
          message: 'Sign in as admin to create accounts.',
        );
      }

      final adminDoc = await _firestore.collection('users').doc(adminUser.uid).get();
      final String adminRole = adminDoc.data()?['role']?.toString() ?? '';
      if (adminRole != 'admin') {
        return const CreateAccountResult(
          status: 'permission-denied',
          message: 'Admin access required.',
        );
      }

      final String cleanRole = role.trim();
      final String cleanEmail = email.trim();
      final String cleanName = name.trim();
      final String cleanPassword = password.trim();
      final String cleanStudentId = studentId?.trim() ?? '';

      if (cleanRole.isEmpty || cleanEmail.isEmpty || cleanName.isEmpty || cleanPassword.isEmpty) {
        return const CreateAccountResult(
          status: 'invalid-argument',
          message: 'Missing role, email, name or password.',
        );
      }
      if (cleanRole != 'student' && cleanRole != 'spc') {
        return const CreateAccountResult(
          status: 'invalid-argument',
          message: 'Role must be student or spc.',
        );
      }
      if (cleanPassword.length < 6) {
        return const CreateAccountResult(
          status: 'invalid-argument',
          message: 'Password must be at least 6 characters.',
        );
      }
      if (cleanRole == 'student') {
        if (cleanStudentId.isEmpty) {
          return const CreateAccountResult(
            status: 'invalid-argument',
            message: 'Student ID is required.',
          );
        }
        if (cleanStudentId.contains('/')) {
          return const CreateAccountResult(
            status: 'invalid-argument',
            message: 'Student ID cannot include /.',
          );
        }
      }

      final String appName = 'adminAccountCreator_${DateTime.now().microsecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      try {
        final UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        createdUser = credential.user;
      } on FirebaseAuthException catch (error) {
        return CreateAccountResult(
          status: error.code,
          message: _mapAuthError(error),
        );
      }

      if (createdUser == null) {
        return const CreateAccountResult(
          status: 'error',
          message: 'Unable to create auth user.',
        );
      }

      try {
        await _firestore.collection('users').doc(createdUser.uid).set(
          <String, dynamic>{
            'role': cleanRole,
            'name': cleanName,
            'studentId': cleanRole == 'student' ? cleanStudentId : null,
            'assignedDrives': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (cleanRole == 'student') {
          final String profileName = studentProfile?['name']?.toString().trim() ?? '';
          final String profileEmail = studentProfile?['email']?.toString().trim() ?? '';
          final Map<String, dynamic> profile = <String, dynamic>{
            'studentId': cleanStudentId,
            'name': profileName.isNotEmpty ? profileName : cleanName,
            'email': profileEmail.isNotEmpty ? profileEmail : cleanEmail,
            'phone': studentProfile?['phone']?.toString().trim() ?? '',
            'department': studentProfile?['department']?.toString().trim() ?? '',
            'year': studentProfile?['year']?.toString().trim() ?? '',
            'section': studentProfile?['section']?.toString().trim() ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('students').doc(cleanStudentId).set(profile, SetOptions(merge: true));
        }
      } on FirebaseException catch (error) {
        await createdUser.delete().catchError((_) {});
        return CreateAccountResult(
          status: error.code,
          message: error.message ?? 'Unable to save user profile.',
        );
      }

      return CreateAccountResult(
        status: 'ok',
        message: '${cleanRole.toUpperCase()} account created.',
      );
    } catch (error) {
      if (createdUser != null) {
        await createdUser.delete().catchError((_) {});
      }
      return CreateAccountResult(
        status: 'error',
        message: 'Unable to create account. ${error.toString()}',
      );
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete().catchError((_) {});
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return error.message ?? 'Unable to create auth user.';
    }
  }
}

class CreateAccountResult {
  const CreateAccountResult({required this.status, required this.message});

  final String status;
  final String message;

  bool get isSuccess => status == 'ok' || status == 'success';
}
