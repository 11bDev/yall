/// Enum representing the supported social media platforms
enum PlatformType {
  mastodon('mastodon', 'Mastodon', 500),
  bluesky('bluesky', 'Bluesky', 300),
  nostr('nostr', 'Nostr', 800), // 800 character limit for Nostr
  microblog('microblog', 'Micro.blog', 280); // 280 character limit for Micro.blog

  const PlatformType(this.id, this.displayName, this.characterLimit);

  /// Unique identifier for the platform
  final String id;

  /// Human-readable display name
  final String displayName;

  /// Maximum character limit for posts on this platform
  final int characterLimit;

  /// Convert from string ID to enum value
  static PlatformType fromId(String id) {
    return PlatformType.values.firstWhere(
      (platform) => platform.id == id,
      orElse: () => throw ArgumentError('Unknown platform ID: $id'),
    );
  }

  /// Get all platform IDs as a list
  static List<String> get allIds =>
      PlatformType.values.map((p) => p.id).toList();

  /// Get all display names as a list
  static List<String> get allDisplayNames =>
      PlatformType.values.map((p) => p.displayName).toList();
}
