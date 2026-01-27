import 'package:flutter/material.dart';

import 'student_screen.dart';
import 'teacher_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound-Only Check-in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Choose a mode to broadcast or listen for attendance tokens.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ModeButton(
              label: 'Teacher',
              subtitle: 'Play the rotating token',
              icon: Icons.campaign,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const TeacherScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ModeButton(
              label: 'Student',
              subtitle: 'Listen and check in',
              icon: Icons.hearing,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(
                    builder: (BuildContext context) => const StudentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
