import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';

Future<PromptImageSource?> showImageSourceSheet(
  BuildContext context, {
  required String title,
  required bool allowCamera,
}) {
  return showModalBottomSheet<PromptImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);
      return SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Signature Nakama-style warm amber header
              Container(
                color: AppColors.sunnyAmber,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 18, AppSpacing.md, 18),
                child: Row(
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E1400),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    BouncingWrapper(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF1E1400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: <Widget>[
                    if (allowCamera)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: BouncingWrapper(
                          onTap: () => Navigator.of(sheetContext)
                              .pop(PromptImageSource.camera),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.field),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.electricBlue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: AppColors.electricBlue,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Take Photo',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onTap: () => Navigator.of(sheetContext)
                                  .pop(PromptImageSource.camera),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: BouncingWrapper(
                        onTap: () => Navigator.of(sheetContext)
                            .pop(PromptImageSource.gallery),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.field),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.royalIndigo.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: AppColors.royalIndigo,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Choose from Gallery',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onTap: () => Navigator.of(sheetContext)
                                .pop(PromptImageSource.gallery),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.close_rounded),
                      title: const Text('Cancel'),
                      onTap: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
