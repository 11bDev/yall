import 'media_attachment.dart';

/// Represents the data for a post including text content and media attachments
class PostData {
  final String content;
  final List<MediaAttachment> mediaAttachments;
  final DateTime createdAt;

  PostData({
    required this.content,
    List<MediaAttachment>? mediaAttachments,
    DateTime? createdAt,
  }) : mediaAttachments = mediaAttachments ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Create a text-only post
  factory PostData.textOnly(String content) {
    return PostData(content: content);
  }

  /// Create a post with media
  factory PostData.withMedia(String content, List<MediaAttachment> media) {
    return PostData(content: content, mediaAttachments: media);
  }

  /// Check if this post has media attachments
  bool get hasMedia => mediaAttachments.isNotEmpty;

  /// Check if this post has images
  bool get hasImages => mediaAttachments.any((media) => media.isImage);

  /// Check if this post has videos
  bool get hasVideos => mediaAttachments.any((media) => media.isVideo);

  /// Get only image attachments
  List<MediaAttachment> get imageAttachments =>
      mediaAttachments.where((media) => media.isImage).toList();

  /// Get only video attachments
  List<MediaAttachment> get videoAttachments =>
      mediaAttachments.where((media) => media.isVideo).toList();

  /// Get total size of all media attachments
  int get totalMediaSize =>
      mediaAttachments.fold(0, (sum, media) => sum + media.sizeBytes);

  /// Get formatted total media size
  String get formattedTotalMediaSize {
    final totalBytes = totalMediaSize;
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Create a copy with updated content
  PostData copyWith({
    String? content,
    List<MediaAttachment>? mediaAttachments,
  }) {
    return PostData(
      content: content ?? this.content,
      mediaAttachments: mediaAttachments ?? this.mediaAttachments,
      createdAt: createdAt,
    );
  }

  /// Add a media attachment
  PostData addMedia(MediaAttachment media) {
    final newMedia = List<MediaAttachment>.from(mediaAttachments);
    newMedia.add(media);
    return copyWith(mediaAttachments: newMedia);
  }

  /// Remove a media attachment
  PostData removeMedia(String mediaId) {
    final newMedia = mediaAttachments.where((media) => media.id != mediaId).toList();
    return copyWith(mediaAttachments: newMedia);
  }

  /// Update media attachment description
  PostData updateMediaDescription(String mediaId, String? description) {
    final newMedia = mediaAttachments.map((media) {
      if (media.id == mediaId) {
        return media.copyWith(description: description);
      }
      return media;
    }).toList();
    return copyWith(mediaAttachments: newMedia);
  }

  /// Check if the post is valid (has content or media)
  bool get isValid => content.trim().isNotEmpty || hasMedia;

  /// Get a summary of the post
  String getSummary() {
    final parts = <String>[];
    
    if (content.trim().isNotEmpty) {
      final truncatedContent = content.length > 50 
          ? '${content.substring(0, 50)}...' 
          : content;
      parts.add('"$truncatedContent"');
    }
    
    if (hasMedia) {
      final imageCount = imageAttachments.length;
      final videoCount = videoAttachments.length;
      
      final mediaParts = <String>[];
      if (imageCount > 0) {
        mediaParts.add('$imageCount image${imageCount == 1 ? '' : 's'}');
      }
      if (videoCount > 0) {
        mediaParts.add('$videoCount video${videoCount == 1 ? '' : 's'}');
      }
      
      parts.add('with ${mediaParts.join(' and ')}');
    }
    
    return parts.join(' ');
  }

  @override
  String toString() {
    return 'PostData(content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, '
        'mediaCount: ${mediaAttachments.length}, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostData &&
        other.content == content &&
        _listEquals(other.mediaAttachments, mediaAttachments) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      content,
      Object.hashAll(mediaAttachments),
      createdAt,
    );
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}