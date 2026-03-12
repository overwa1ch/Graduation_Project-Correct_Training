import 'package:flutter/material.dart';

import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/home_page.dart';
import 'package:aiwa_app/ui/pages/task_calendar_page.dart';
import 'package:aiwa_app/ui/pages/library_page.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';

/// Persistent tab shell.
///
/// Wraps the four main tabs in an [IndexedStack] so that each page's state
/// (scroll position, loaded data, animation controllers) is preserved across
/// tab switches — no [initState] re-run, no data reload on every tap.
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key, this.initialIndex = 0});

  /// Which tab is shown first (0=Home, 1=Plan, 2=Library, 3=Settings).
  final int initialIndex;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  late int _currentIndex;

  // Pages are created once and kept alive for the lifetime of MainTabShell.
  static const _pages = <Widget>[
    HomePage(),
    TaskCalendarPage(),
    LibraryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // IndexedStack keeps all pages alive; only the active one is visible.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i != _currentIndex) setState(() => _currentIndex = i);
        },
      ),
    );
  }
}
