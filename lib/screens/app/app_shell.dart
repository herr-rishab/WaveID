import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../widgets/gradient_background.dart';
import '../profile/profile_screen.dart';
import '../spc/spc_home_screen.dart';
import '../spc/spc_drive_list_screen.dart';
import '../student/student_home_screen.dart';
import '../student/student_attendance_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user});

  final AppUser user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.user.isStudent;
    final List<Widget> pages = isStudent
        ? <Widget>[
            StudentHomeScreen(user: widget.user),
            StudentAttendanceScreen(user: widget.user),
            ProfileScreen(user: widget.user),
          ]
        : <Widget>[
            SpcHomeScreen(user: widget.user),
            SpcDriveListScreen(user: widget.user),
            ProfileScreen(user: widget.user),
          ];

    final List<BottomNavigationBarItem> items = isStudent
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'My Drives'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Session'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Drives'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ];

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: IndexedStack(index: _index, children: pages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        items: items,
        onTap: (int value) => setState(() => _index = value),
      ),
    );
  }
}
