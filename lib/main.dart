import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/prompt_repository.dart';
import 'features/prompts/controllers/prompts_controller.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'shared/services/image_picker_service.dart';
import 'shared/services/image_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final ImageStorageService imageStorage = ImageStorageService();
  try {
    await imageStorage.initialize();
  } on Object {
    debugPrint('Image storage could not be prepared.');
  }

  final PromptRepository repository = PromptRepository(
    database: AppDatabase(),
    imageStorage: imageStorage,
  );

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<ImageStorageService>.value(value: imageStorage),
        Provider<ImagePickerService>(
          create: (BuildContext context) => ImagePickerService(),
        ),
        Provider<PromptRepository>.value(value: repository),
        ChangeNotifierProvider<ThemeController>(
          create: (BuildContext context) => ThemeController(preferences),
        ),
        ChangeNotifierProvider<PromptsController>(
          create: (BuildContext context) => PromptsController(repository)..load(),
        ),
      ],
      child: const PromptLibraryApp(),
    ),
  );
}
