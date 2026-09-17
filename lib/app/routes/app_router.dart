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

  static Future<void> openPromptDetails(BuildContext context, Prompt prompt) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
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
