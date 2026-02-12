import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.year,
    required this.section,
  });

  final String studentId;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String year;
  final String section;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'year': year,
      'section': section,
      'updatedAt': Timestamp.now(),
    };
  }

  factory StudentProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Student ${doc.id} has no data');
    }
    return StudentProfile.fromMap(data);
  }

  factory StudentProfile.fromMap(Map<String, dynamic> data) {
    return StudentProfile(
      studentId: (data['studentId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      department: (data['department'] ?? '') as String,
      year: (data['year'] ?? '') as String,
      section: (data['section'] ?? '') as String,
    );
  }
}
