import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/image_storage_service.dart';

class LocalImageView extends StatelessWidget {
  const LocalImageView({
    super.key,
    required this.fileName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.decodeWidth,
  });

  final String fileName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final File? file = context.read<ImageStorageService>().tryFileFor(fileName);
    if (file == null) {
      return _MissingImagePlaceholder(width: width, height: height);
    }
    final double? targetWidth = decodeWidth;
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      cacheWidth: targetWidth == null
          ? null
          : (targetWidth * MediaQuery.devicePixelRatioOf(context)).round(),
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        return _MissingImagePlaceholder(width: width, height: height);
      },
    );
  }
}

class _MissingImagePlaceholder extends StatelessWidget {
  const _MissingImagePlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Image unavailable',
      child: Container(
        width: width,
        height: height,
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}
