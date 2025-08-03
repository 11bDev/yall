import 'dart:io';
import 'dart:typed_data';

/// Represents a media attachment (image, video, etc.) for a post
class MediaAttachment {
  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final File? file;
  final Uint8List? bytes;
  final String? description; // Alt text for accessibility
  final MediaType type;

  MediaAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.file,
    this.bytes,
    this.description,
    required this.type,
  }) : assert(file != null || bytes != null, 'Either file or bytes must be provided');

  /// Create from a file
  factory MediaAttachment.fromFile(File file, {String? description}) {
    final fileName = file.path.split('/').last;
    final mimeType = _getMimeTypeFromExtension(fileName);
    final type = _getMediaTypeFromMimeType(mimeType);
    
    return MediaAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: file.lengthSync(),
      file: file,
      description: description,
      type: type,
    );
  }

  /// Create from bytes
  factory MediaAttachment.fromBytes(
    Uint8List bytes,
    String fileName, {
    String? description,
  }) {
    final mimeType = _getMimeTypeFromExtension(fileName);
    final type = _getMediaTypeFromMimeType(mimeType);
    
    return MediaAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      bytes: bytes,
      description: description,
      type: type,
    );
  }

  /// Get file bytes (either from file or bytes property)
  Future<Uint8List> getBytes() async {
    if (bytes != null) {
      return bytes!;
    } else if (file != null) {
      return await file!.readAsBytes();
    } else {
      throw StateError('No file or bytes available');
    }
  }

  /// Check if this is an image
  bool get isImage => type == MediaType.image;

  /// Check if this is a video
  bool get isVideo => type == MediaType.video;

  /// Get file size in a human-readable format
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Create a copy with updated description
  MediaAttachment copyWith({String? description}) {
    return MediaAttachment(
      id: id,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      file: file,
      bytes: bytes,
      description: description ?? this.description,
      type: type,
    );
  }

  /// Get MIME type from file extension
  static String _getMimeTypeFromExtension(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get media type from MIME type
  static MediaType _getMediaTypeFromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return MediaType.image;
    } else if (mimeType.startsWith('video/')) {
      return MediaType.video;
    } else {
      return MediaType.unknown;
    }
  }

  @override
  String toString() {
    return 'MediaAttachment(id: $id, fileName: $fileName, type: $type, size: $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaAttachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of media that can be attached
enum MediaType {
  image,
  video,
  unknown,
}

/// Extension methods for MediaType
extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Image';
      case MediaType.video:
        return 'Video';
      case MediaType.unknown:
        return 'Unknown';
    }
  }

  List<String> get allowedExtensions {
    switch (this) {
      case MediaType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case MediaType.video:
        return ['mp4', 'mov', 'avi'];
      case MediaType.unknown:
        return [];
    }
  }
}