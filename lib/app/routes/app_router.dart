import 'package:flutter/material.dart';

import '../../features/image_viewer/screens/image_viewer_screen.dart';
import '../../features/prompt_editor/screens/prompt_editor_screen.dart';
import '../../features/prompts/screens/prompt_details_screen.dart';
import '../../models/prompt.dart';
import '../../shared/widgets/app_snack_bar.dart';

class AppRouter {
  const AppRouter._();

  static Future<bool> openPromptEditor(BuildContext context, {Prompt? prompt}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => PromptEditorScreen(prompt: prompt),
      ),
    );
    return saved ?? false;
  }

  static Future<void> createPrompt(BuildContext context) async {
    final bool saved = await openPromptEditor(context);
    if (saved && context.mounted) {
      showAppSnackBar(context, 'Prompt saved');
    }
  }

  /// Opens the prompt's details screen. If the user tapped a group chip
  /// inside it, returns that group's id so the caller can apply it as a
  /// filter (e.g. on the home list); otherwise returns null.
  static Future<String?> openPromptDetails(BuildContext context, Prompt prompt) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) => PromptDetailsScreen(prompt: prompt),
      ),
    );
  }

  static Future<void> openImageViewer(
    BuildContext context, {
    required List<String> imageFileNames,
    int initialIndex = 0,
  }) {
    if (imageFileNames.isEmpty) {
      return Future<void>.value();
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ImageViewerScreen(
          imageFileNames: imageFileNames,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
