import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../models/media_attachment.dart';

/// Service for handling image operations like picking, resizing, and validation
class ImageService {
  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Maximum image dimensions
  static const int maxImageWidth = 2048;
  static const int maxImageHeight = 2048;

  /// Supported image formats
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Supported video formats
  static const List<String> supportedVideoExtensions = ['mp4', 'mov', 'avi'];

  /// Pick images from the file system
  Future<List<MediaAttachment>> pickImages({
    bool allowMultiple = true,
    int? maxFiles,
  }) async {
    try {
      // Try different file picker approaches for better Linux compatibility
      FilePickerResult? result;

      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: supportedImageExtensions,
          allowMultiple: allowMultiple,
          withData: false,
        );
      } catch (e) {
        // If custom type fails, try with image type
        print('Custom file picker failed, trying image type: $e');
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: allowMultiple,
            withData: false,
          );
        } catch (e2) {
          // If that also fails, try any file type
          print('Image file picker failed, trying any type: $e2');
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: allowMultiple,
            withData: false,
          );
        }
      }

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final attachments = <MediaAttachment>[];
      final filesToProcess = maxFiles != null
          ? result.files.take(maxFiles).toList()
          : result.files;

      for (final platformFile in filesToProcess) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);

        // Check if it's actually an image file by extension
        final extension = path.extension(file.path).toLowerCase().substring(1);
        if (!supportedImageExtensions.contains(extension)) {
          print('Skipping non-image file: ${file.path}');
          continue;
        }

        // Validate file
        final validation = await validateImageFile(file);
        if (!validation.isValid) {
          print(
            'File validation failed for ${file.path}: ${validation.errorMessage}',
          );
          continue; // Skip invalid files instead of throwing
        }

        // Create media attachment
        final attachment = MediaAttachment.fromFile(file);
        attachments.add(attachment);
      }

      return attachments;
    } catch (e) {
      if (e is ImageServiceException) {
        rethrow;
      }

      // Provide more helpful error messages
      String errorMessage = 'Failed to pick images';
      if (e.toString().contains('zenity')) {
        errorMessage =
            'File picker not available. Please install zenity: sudo apt install zenity';
      } else if (e.toString().contains('No such file')) {
        errorMessage =
            'File picker utility not found. Please install required system packages.';
      } else {
        errorMessage = 'Failed to pick images: ${e.toString()}';
      }

      throw ImageServiceException(errorMessage);
    }
  }

  /// Pick videos from the file system
  Future<List<MediaAttachment>> pickVideos({
    bool allowMultiple = true,
    int? maxFiles,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedVideoExtensions,
        allowMultiple: allowMultiple,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final attachments = <MediaAttachment>[];
      final filesToProcess = maxFiles != null
          ? result.files.take(maxFiles).toList()
          : result.files;

      for (final platformFile in filesToProcess) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);

        // Validate file
        final validation = await validateVideoFile(file);
        if (!validation.isValid) {
          throw ImageServiceException(validation.errorMessage!);
        }

        // Create media attachment
        final attachment = MediaAttachment.fromFile(file);
        attachments.add(attachment);
      }

      return attachments;
    } catch (e) {
      if (e is ImageServiceException) {
        rethrow;
      }
      throw ImageServiceException('Failed to pick videos: ${e.toString()}');
    }
  }

  /// Pick any supported media files
  Future<List<MediaAttachment>> pickMedia({
    bool allowMultiple = true,
    int? maxFiles,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...supportedImageExtensions,
          ...supportedVideoExtensions,
        ],
        allowMultiple: allowMultiple,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final attachments = <MediaAttachment>[];
      final filesToProcess = maxFiles != null
          ? result.files.take(maxFiles).toList()
          : result.files;

      for (final platformFile in filesToProcess) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        final extension = path.extension(file.path).toLowerCase().substring(1);

        // Validate file based on type
        FileValidationResult validation;
        if (supportedImageExtensions.contains(extension)) {
          validation = await validateImageFile(file);
        } else if (supportedVideoExtensions.contains(extension)) {
          validation = await validateVideoFile(file);
        } else {
          validation = FileValidationResult(
            isValid: false,
            errorMessage: 'Unsupported file format: $extension',
          );
        }

        if (!validation.isValid) {
          throw ImageServiceException(validation.errorMessage!);
        }

        // Create media attachment
        final attachment = MediaAttachment.fromFile(file);
        attachments.add(attachment);
      }

      return attachments;
    } catch (e) {
      if (e is ImageServiceException) {
        rethrow;
      }
      throw ImageServiceException('Failed to pick media: ${e.toString()}');
    }
  }

  /// Validate an image file
  Future<FileValidationResult> validateImageFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'File does not exist',
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return FileValidationResult(
          isValid: false,
          errorMessage:
              'File size exceeds ${(maxFileSize / (1024 * 1024)).toStringAsFixed(1)}MB limit',
        );
      }

      // Check file extension
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!supportedImageExtensions.contains(extension)) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Unsupported image format: $extension',
        );
      }

      // Try to decode the image to validate it's a valid image file
      try {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          return FileValidationResult(
            isValid: false,
            errorMessage: 'Invalid or corrupted image file',
          );
        }
      } catch (e) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Failed to process image: ${e.toString()}',
        );
      }

      return FileValidationResult(isValid: true);
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'File validation failed: ${e.toString()}',
      );
    }
  }

  /// Validate a video file
  Future<FileValidationResult> validateVideoFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'File does not exist',
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return FileValidationResult(
          isValid: false,
          errorMessage:
              'File size exceeds ${(maxFileSize / (1024 * 1024)).toStringAsFixed(1)}MB limit',
        );
      }

      // Check file extension
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!supportedVideoExtensions.contains(extension)) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Unsupported video format: $extension',
        );
      }

      return FileValidationResult(isValid: true);
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'File validation failed: ${e.toString()}',
      );
    }
  }

  /// Resize an image if it exceeds maximum dimensions
  Future<Uint8List> resizeImageIfNeeded(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw ImageServiceException('Failed to decode image');
      }

      // Check if resizing is needed
      if (image.width <= maxImageWidth && image.height <= maxImageHeight) {
        return imageBytes; // No resizing needed
      }

      // Calculate new dimensions maintaining aspect ratio
      double aspectRatio = image.width / image.height;
      int newWidth, newHeight;

      if (image.width > image.height) {
        newWidth = maxImageWidth;
        newHeight = (maxImageWidth / aspectRatio).round();
      } else {
        newHeight = maxImageHeight;
        newWidth = (maxImageHeight * aspectRatio).round();
      }

      // Resize the image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode back to bytes (JPEG for better compression)
      final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
      return Uint8List.fromList(resizedBytes);
    } catch (e) {
      throw ImageServiceException('Failed to resize image: ${e.toString()}');
    }
  }

  /// Get image dimensions
  Future<ImageDimensions?> getImageDimensions(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      return ImageDimensions(width: image.width, height: image.height);
    } catch (e) {
      return null;
    }
  }

  /// Generate a thumbnail for an image
  Future<Uint8List> generateThumbnail(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw ImageServiceException('Failed to decode image for thumbnail');
      }

      // Calculate thumbnail dimensions maintaining aspect ratio
      double aspectRatio = image.width / image.height;
      int thumbWidth, thumbHeight;

      if (image.width > image.height) {
        thumbWidth = maxWidth;
        thumbHeight = (maxWidth / aspectRatio).round();
      } else {
        thumbHeight = maxHeight;
        thumbWidth = (maxHeight * aspectRatio).round();
      }

      // Create thumbnail
      final thumbnail = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with lower quality for smaller size
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
      return Uint8List.fromList(thumbnailBytes);
    } catch (e) {
      throw ImageServiceException(
        'Failed to generate thumbnail: ${e.toString()}',
      );
    }
  }

  /// Compress an image to fit within a specific file size limit
  /// Uses progressive quality reduction and resizing if needed
  Future<Uint8List> compressImageToSize(
    Uint8List imageBytes, 
    int maxSizeBytes,
  ) async {
    try {
      // If already within size limit, return as-is
      if (imageBytes.length <= maxSizeBytes) {
        return imageBytes;
      }

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw ImageServiceException('Failed to decode image for compression');
      }

      // Start with high quality and progressively reduce
      for (int quality = 90; quality >= 30; quality -= 10) {
        final compressedBytes = img.encodeJpg(image, quality: quality);
        final compressedData = Uint8List.fromList(compressedBytes);
        
        if (compressedData.length <= maxSizeBytes) {
          return compressedData;
        }
      }

      // If quality reduction isn't enough, try resizing
      var currentImage = image;
      double scaleFactor = 0.9;
      
      while (scaleFactor > 0.3) {
        final newWidth = (currentImage.width * scaleFactor).round();
        final newHeight = (currentImage.height * scaleFactor).round();
        
        final resizedImage = img.copyResize(
          currentImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
        
        // Try different quality levels for the resized image
        for (int quality = 85; quality >= 30; quality -= 15) {
          final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
          final compressedData = Uint8List.fromList(compressedBytes);
          
          if (compressedData.length <= maxSizeBytes) {
            return compressedData;
          }
        }
        
        scaleFactor -= 0.1;
      }

      // If we still can't fit it, return the smallest version we can make
      final minResized = img.copyResize(
        image,
        width: (image.width * 0.3).round(),
        height: (image.height * 0.3).round(),
        interpolation: img.Interpolation.linear,
      );
      
      final finalBytes = img.encodeJpg(minResized, quality: 30);
      return Uint8List.fromList(finalBytes);
      
    } catch (e) {
      throw ImageServiceException('Failed to compress image: ${e.toString()}');
    }
  }
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  FileValidationResult({required this.isValid, this.errorMessage});
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  double get aspectRatio => width / height;

  @override
  String toString() => '${width}x$height';
}

/// Exception thrown by ImageService
class ImageServiceException implements Exception {
  final String message;
  final dynamic originalError;

  ImageServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'ImageServiceException: $message';
}
