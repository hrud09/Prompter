import 'package:flutter/material.dart';

import '../../../app/routes/app_router.dart';
import '../../prompts/screens/home_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<Widget> _sections = <Widget>[
    HomeScreen(),
    SettingsScreen(),
  ];

  int _currentIndex = 0;

  void _selectSection(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _createPrompt() async {
    _selectSection(0);
    await AppRouter.createPrompt(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _sections),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onSelect: _selectSection,
        onCreate: _createPrompt,
      ),
    );
  }
}
