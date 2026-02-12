import 'package:flutter/material.dart';

import 'app/auth_gate.dart';
import 'app/admin_gate.dart';
import 'theme/app_theme.dart';

class WaveIdApp extends StatelessWidget {
  const WaveIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveID',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/admin') {
          return MaterialPageRoute<Widget>(
            builder: (BuildContext context) => const AdminGate(),
            settings: settings,
          );
        }
        return MaterialPageRoute<Widget>(
          builder: (BuildContext context) => const AuthGate(),
          settings: settings,
        );
      },
    );
  }
}
