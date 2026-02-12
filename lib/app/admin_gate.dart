import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/access_pending_screen.dart';
import '../screens/auth/admin_auth_screen.dart';
import '../screens/auth/not_admin_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_view.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final UserService userService = UserService();

    Widget wrapSelectable(Widget child) => kIsWeb ? SelectionArea(child: child) : child;

    return wrapSelectable(
      StreamBuilder<User?>(
        stream: authService.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: LoadingView(message: 'Loading session...'));
          }
          final User? firebaseUser = snapshot.data;
          if (firebaseUser == null) {
            return const AdminAuthScreen();
          }
          return StreamBuilder<AppUser?>(
            stream: userService.watchUser(firebaseUser.uid),
            builder: (BuildContext context, AsyncSnapshot<AppUser?> userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: LoadingView(message: 'Loading profile...'));
              }
              final AppUser? user = userSnap.data;
              if (user == null || user.role.isEmpty) {
                return AccessPendingScreen(email: firebaseUser.email ?? '');
              }
              if (user.isAdmin) {
                return AdminShell(user: user);
              }
              return NotAdminScreen(email: firebaseUser.email ?? '');
            },
          );
        },
      ),
    );
  }
}
