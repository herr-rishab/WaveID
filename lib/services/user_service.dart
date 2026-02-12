import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return AppUser.fromMap(uid, data);
    });
  }

  Future<void> createOrUpdateUser(AppUser user) {
    return _firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<List<AppUser>> watchUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createAdminUser({
    required String uid,
    required String name,
    required String adminCode,
  }) {
    return _firestore.collection('users').doc(uid).set(<String, dynamic>{
      'role': 'admin',
      'name': name,
      'assignedDrives': <String>[],
      'adminCode': adminCode,
    }, SetOptions(merge: true));
  }
}
