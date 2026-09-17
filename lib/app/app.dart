import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/settings/controllers/theme_controller.dart';
import '../features/shell/screens/app_shell.dart';
import 'app_info.dart';
import 'theme/app_theme.dart';

class PromptLibraryApp extends StatelessWidget {
  const PromptLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = context.watch<ThemeController>().themeMode;
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
