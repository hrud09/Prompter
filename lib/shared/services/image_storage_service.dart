import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageException implements Exception {
  const ImageStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImageStorageService {
  static const String _directoryName = 'prompt_images';
  static const Set<String> _allowedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
    '.heif',
  };

  final Uuid _uuid = const Uuid();

  Future<String>? _preparing;
  String? _rootPath;

  Future<void> initialize() async {
    try {
      _rootPath = await (_preparing ??= _prepareDirectory());
    } catch (_) {
      _preparing = null;
      rethrow;
    }
  }

  String absolutePathFor(String fileName) {
    final String? root = _rootPath;
    if (root == null) {
      throw const ImageStorageException('Image storage has not been initialized.');
    }
    return p.join(root, fileName);
  }

  File fileFor(String fileName) => File(absolutePathFor(fileName));

  File? tryFileFor(String fileName) {
    if (fileName.isEmpty || _rootPath == null) {
      return null;
    }
    return fileFor(fileName);
  }

  Future<String> importImage(String sourcePath) async {
    await initialize();
    final File source = File(sourcePath);
    if (!await source.exists()) {
      throw const ImageStorageException('That image is no longer available.');
    }
    final String fileName = '${_uuid.v4()}${_normalizedExtension(sourcePath)}';
    try {
      await source.copy(absolutePathFor(fileName));
    } on FileSystemException {
      throw const ImageStorageException('Could not save the image to this device.');
    }
    return fileName;
  }

  Future<List<String>> importImages(Iterable<String> sourcePaths) async {
    final List<String> imported = <String>[];
    try {
      for (final String sourcePath in sourcePaths) {
        imported.add(await importImage(sourcePath));
      }
    } catch (_) {
      await deleteImages(imported);
      rethrow;
    }
    return imported;
  }

  Future<void> deleteImages(Iterable<String> fileNames) async {
    for (final String fileName in fileNames) {
      await deleteImage(fileName);
    }
  }

  Future<void> deleteImage(String fileName) async {
    if (fileName.isEmpty || _rootPath == null) {
      return;
    }
    try {
      final File file = fileFor(fileName);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      return;
    }
  }

  Future<String> _prepareDirectory() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory images = Directory(p.join(documents.path, _directoryName));
    if (!await images.exists()) {
      await images.create(recursive: true);
    }
    return images.path;
  }

  String _normalizedExtension(String sourcePath) {
    final String extension = p.extension(sourcePath).toLowerCase();
    return _allowedExtensions.contains(extension) ? extension : '.jpg';
  }
}
