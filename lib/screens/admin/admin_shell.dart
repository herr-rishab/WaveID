import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../profile/profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_drives_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_spc_screen.dart';
import 'admin_students_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user});

  final AppUser user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<_AdminDestination> destinations = <_AdminDestination>[
      _AdminDestination(
        'Dashboard',
        Icons.dashboard,
        AdminDashboardScreen(user: widget.user),
      ),
      _AdminDestination(
        'Drives',
        Icons.event_available,
        AdminDrivesScreen(user: widget.user),
      ),
      _AdminDestination('Students', Icons.school, const AdminStudentsScreen()),
      _AdminDestination('SPCs', Icons.campaign, const AdminSpcScreen()),
      _AdminDestination(
        'Reports',
        Icons.insert_chart,
        const AdminReportsScreen(),
      ),
      _AdminDestination(
        'Profile',
        Icons.person,
        ProfileScreen(user: widget.user),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 960;
        final Widget content = destinations[_index].screen;

        return Scaffold(
          body: GradientBackground(
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  if (wide)
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (int value) =>
                          setState(() => _index = value),
                      backgroundColor: Colors.transparent,
                      extended: true,
                      labelType: NavigationRailLabelType.none,
                      destinations: destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: Icon(destination.icon),
                              label: Text(destination.label),
                            ),
                          )
                          .toList(),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 14, 18, 18),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppTheme.pine.withValues(alpha: 0.10),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppTheme.ink.withValues(alpha: 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: content,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          drawer: wide
              ? null
              : Drawer(
                  child: ListView(
                    children: <Widget>[
                      const SizedBox(height: 16),
                      for (int i = 0; i < destinations.length; i++)
                        ListTile(
                          leading: Icon(destinations[i].icon),
                          title: Text(destinations[i].label),
                          selected: i == _index,
                          onTap: () {
                            setState(() => _index = i);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
          appBar: wide ? null : AppBar(title: Text(destinations[_index].label)),
        );
      },
    );
  }
}

class _AdminDestination {
  const _AdminDestination(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}
