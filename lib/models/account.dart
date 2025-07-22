import 'dart:convert';
import 'platform_type.dart';

/// Model representing a user account for a specific social media platform
class Account {
  final String id;
  final PlatformType platform;
  final String displayName;
  final String username;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic> _credentials;

  Account({
    required this.id,
    required this.platform,
    required this.displayName,
    required this.username,
    required this.createdAt,
    this.isActive = true,
    Map<String, dynamic>? credentials,
  }) : _credentials = credentials ?? {};

  /// Get credentials (read-only access)
  Map<String, dynamic> get credentials => Map.unmodifiable(_credentials);

  /// Create a copy of this account with updated fields
  Account copyWith({
    String? id,
    PlatformType? platform,
    String? displayName,
    String? username,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? credentials,
  }) {
    return Account(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      credentials: credentials ?? Map.from(_credentials),
    );
  }

  /// Convert account to JSON (excluding sensitive credentials)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.id,
      'displayName': displayName,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      platform: PlatformType.fromId(json['platform'] as String),
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert account to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create account from JSON string
  factory Account.fromJsonString(String jsonString) {
    return Account.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Update credentials (returns new instance for immutability)
  Account withCredentials(Map<String, dynamic> newCredentials) {
    return copyWith(credentials: Map.from(newCredentials));
  }

  /// Check if account has specific credential field
  bool hasCredential(String key) => _credentials.containsKey(key);

  /// Get specific credential value
  T? getCredential<T>(String key) => _credentials[key] as T?;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.platform == platform &&
        other.displayName == displayName &&
        other.username == username &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      platform,
      displayName,
      username,
      createdAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, platform: ${platform.displayName}, '
        'displayName: $displayName, username: $username, '
        'isActive: $isActive, createdAt: $createdAt)';
  }
}