import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum PromptImageSource { camera, gallery }

class ImagePickerFailure implements Exception {
  const ImagePickerFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImagePickerService {
  static const double _maxDimension = 2560;
  static const int _imageQuality = 90;

  final ImagePicker _picker = ImagePicker();

  bool get supportsCamera =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<List<String>> pickImages(PromptImageSource source) async {
    try {
      if (source == PromptImageSource.camera) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: _maxDimension,
          maxHeight: _maxDimension,
          imageQuality: _imageQuality,
        );
        return photo == null ? const <String>[] : <String>[photo.path];
      }
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _imageQuality,
      );
      return files.map((XFile file) => file.path).toList(growable: false);
    } on PlatformException catch (error) {
      throw ImagePickerFailure(_messageFor(error.code));
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'camera_access_denied':
        return 'Camera access is off. Enable it in your device settings to take a photo.';
      case 'photo_access_denied':
        return 'Photo access is off. Enable it in your device settings to add images.';
      case 'no_available_camera':
        return 'No camera is available on this device.';
      default:
        return 'Could not open the image picker. Please try again.';
    }
  }
}
