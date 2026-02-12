class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    this.studentId,
    this.assignedDrives = const <String>[],
  });

  final String uid;
  final String role;
  final String name;
  final String? studentId;
  final List<String> assignedDrives;

  bool get isAdmin => role == 'admin';
  bool get isSpc => role == 'spc';
  bool get isStudent => role == 'student';

  AppUser copyWith({
    String? uid,
    String? role,
    String? name,
    String? studentId,
    List<String>? assignedDrives,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      assignedDrives: assignedDrives ?? this.assignedDrives,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'role': role,
      'name': name,
      'studentId': studentId,
      'assignedDrives': assignedDrives,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      role: (data['role'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      studentId: data['studentId'] as String?,
      assignedDrives: List<String>.from(data['assignedDrives'] ?? const <String>[]),
    );
  }
}
