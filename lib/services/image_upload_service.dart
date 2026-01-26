import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Maximum image dimensions (width and height)
  static const int maxImageSize = 800;

  /// Maximum file size in bytes (500KB)
  static const int maxFileSizeBytes = 500 * 1024;

  /// Picks an image from the device gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxImageSize.toDouble(),
        maxHeight: maxImageSize.toDouble(),
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Picks an image from the device camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxImageSize.toDouble(),
        maxHeight: maxImageSize.toDouble(),
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Compresses an image to meet size requirements
  /// Returns the compressed image file
  Future<File> compressImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if dimensions exceed maximum
      img.Image resizedImage = image;
      if (image.width > maxImageSize || image.height > maxImageSize) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxImageSize : null,
          height: image.height > image.width ? maxImageSize : null,
        );
      }

      // Compress with quality adjustment to meet file size requirement
      int quality = 85;
      List<int> compressedBytes;

      do {
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);

        // If still too large and quality can be reduced, reduce quality
        if (compressedBytes.length > maxFileSizeBytes && quality > 10) {
          quality -= 10;
        } else {
          break;
        }
      } while (compressedBytes.length > maxFileSizeBytes && quality > 10);

      // Write compressed image to a temporary file
      final tempDir = imageFile.parent;
      final compressedFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Validates if an image file meets the requirements
  Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        return false;
      }

      // Check image format (JPG or PNG)
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return false;
      }

      // Check dimensions
      if (image.width > maxImageSize || image.height > maxImageSize) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Uploads an image to Firebase Storage and returns the download URL
  /// Automatically compresses the image if it exceeds size limits
  Future<String> uploadProductImage({
    required String productId,
    required File imageFile,
  }) async {
    try {
      // Check authentication before upload
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception(
          'Authentication required: Please log in to upload images',
        );
      }

      // Get fresh authentication token to ensure it's valid
      try {
        await currentUser.getIdToken(true);
      } catch (e) {
        throw Exception(
          'Authentication token expired: Please log in again. Error: $e',
        );
      }

      // Validate and compress image if needed
      File fileToUpload = imageFile;
      final isValid = await validateImage(imageFile);

      if (!isValid) {
        // Compress the image to meet requirements
        fileToUpload = await compressImage(imageFile);
      }

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('products/$productId/image.jpg');

      final uploadTask = await storageRef.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Clean up temporary compressed file if it was created
      if (fileToUpload.path != imageFile.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Deletes a product image from Firebase Storage
  Future<void> deleteProductImage(String productId) async {
    try {
      final storageRef = _storage.ref().child('products/$productId/image.jpg');
      await storageRef.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Failed to delete image: $e');
      }
    }
  }

  /// Gets the file size of an image in bytes
  Future<int> getImageSize(File imageFile) async {
    return await imageFile.length();
  }

  /// Formats file size for display (e.g., "245 KB")
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
