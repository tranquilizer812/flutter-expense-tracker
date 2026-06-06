import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
const int maxCompressedImageSizeBytes = 2 * 1024 * 1024; // 2MB target

class ImageHandlingException implements Exception {
  final String message;
  final dynamic originalError;

  ImageHandlingException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'ImageHandlingException: $message';
}

class ImageHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera
  /// Returns the file path or null if user cancelled
  /// Throws [ImageHandlingException] if image picking fails
  static Future<String?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      final file = File(pickedFile.path);
      
      // Check file size and compress if needed
      final fileSize = await file.length();
      if (fileSize > maxImageSizeBytes) {
        throw ImageHandlingException(
          message: 'Image too large for this device (max ${maxImageSizeBytes ~/ (1024 * 1024)}MB)',
        );
      }

      // Attempt to compress if larger than target
      if (fileSize > maxCompressedImageSizeBytes) {
        return await _compressImage(file);
      }

      return file.path;
    } catch (e) {
      if (e is ImageHandlingException) {
        rethrow;
      }
      throw ImageHandlingException(
        message: 'Could not access camera: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Pick an image from gallery
  /// Returns the file path or null if user cancelled
  /// Throws [ImageHandlingException] if image picking fails
  static Future<String?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      final file = File(pickedFile.path);
      
      // Check file size and compress if needed
      final fileSize = await file.length();
      if (fileSize > maxImageSizeBytes) {
        throw ImageHandlingException(
          message: 'Image too large for this device (max ${maxImageSizeBytes ~/ (1024 * 1024)}MB)',
        );
      }

      // Attempt to compress if larger than target
      if (fileSize > maxCompressedImageSizeBytes) {
        return await _compressImage(file);
      }

      return file.path;
    } catch (e) {
      if (e is ImageHandlingException) {
        rethrow;
      }
      throw ImageHandlingException(
        message: 'Could not access gallery: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Compress an image file
  /// Returns the path to the compressed image file
  static Future<String> _compressImage(File imageFile) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw ImageHandlingException(
          message: 'Could not decode image',
        );
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        resized = img.copyResize(
          image,
          width: 1920,
          height: 1080,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress with quality
      var quality = 85;
      Uint8List compressed = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );

      // If still too large, reduce quality
      while (compressed.length > maxCompressedImageSizeBytes && quality > 50) {
        quality -= 5;
        compressed = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
      }

      // Save to app documents
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(
        directory.path,
        'expense_receipts',
        'receipt_$timestamp.jpg',
      );

      await Directory(p.dirname(outputPath)).create(recursive: true);
      await File(outputPath).writeAsBytes(compressed);

      return outputPath;
    } catch (e) {
      if (e is ImageHandlingException) {
        rethrow;
      }
      throw ImageHandlingException(
        message: 'Failed to compress image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Check if an image file exists and is readable
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete an image file
  /// Throws [ImageHandlingException] if deletion fails
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ImageHandlingException(
        message: 'Failed to delete image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get file size in bytes
  static Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw ImageHandlingException(
        message: 'Failed to get image size: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
