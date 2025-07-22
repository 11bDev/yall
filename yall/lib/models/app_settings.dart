import 'dart:convert';
import 'package:flutter/material.dart';
import 'platform_type.dart';

/// Model representing application settings and user preferences
class AppSettings {
  final ThemeMode themeMode;
  final bool minimizeToTray;
  final bool startMinimized;
  final Map<PlatformType, String> defaultAccounts;
  final bool autoSaveContent;
  final bool showCharacterCount;
  final bool confirmBeforePosting;
  final List<String> nostrRelays;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.minimizeToTray = true,
    this.startMinimized = false,
    this.defaultAccounts = const {},
    this.autoSaveContent = true,
    this.showCharacterCount = true,
    this.confirmBeforePosting = false,
    this.nostrRelays = const [
      'wss://relay.damus.io',
      'wss://nos.lol',
      'wss://relay.snort.social',
      'wss://relay.nostr.band',
    ],
  });

  /// Create default settings
  factory AppSettings.defaultSettings() {
    return const AppSettings();
  }

  /// Create a copy of settings with updated fields
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? minimizeToTray,
    bool? startMinimized,
    Map<PlatformType, String>? defaultAccounts,
    bool? autoSaveContent,
    bool? showCharacterCount,
    bool? confirmBeforePosting,
    List<String>? nostrRelays,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      startMinimized: startMinimized ?? this.startMinimized,
      defaultAccounts: defaultAccounts ?? Map.from(this.defaultAccounts),
      autoSaveContent: autoSaveContent ?? this.autoSaveContent,
      showCharacterCount: showCharacterCount ?? this.showCharacterCount,
      confirmBeforePosting: confirmBeforePosting ?? this.confirmBeforePosting,
      nostrRelays: nostrRelays ?? List.from(this.nostrRelays),
    );
  }

  /// Convert settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': _themeModeToString(themeMode),
      'minimizeToTray': minimizeToTray,
      'startMinimized': startMinimized,
      'defaultAccounts': defaultAccounts.map(
        (platform, accountId) => MapEntry(platform.id, accountId),
      ),
      'autoSaveContent': autoSaveContent,
      'showCharacterCount': showCharacterCount,
      'confirmBeforePosting': confirmBeforePosting,
      'nostrRelays': nostrRelays,
    };
  }

  /// Create settings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaultAccountsMap = <PlatformType, String>{};
    final defaultAccountsJson =
        json['defaultAccounts'] as Map<String, dynamic>? ?? {};

    for (final entry in defaultAccountsJson.entries) {
      try {
        final platform = PlatformType.fromId(entry.key);
        defaultAccountsMap[platform] = entry.value as String;
      } catch (e) {
        // Skip invalid platform IDs
        continue;
      }
    }

    return AppSettings(
      themeMode: _themeModeFromString(json['themeMode'] as String?),
      minimizeToTray: json['minimizeToTray'] as bool? ?? true,
      startMinimized: json['startMinimized'] as bool? ?? false,
      defaultAccounts: defaultAccountsMap,
      autoSaveContent: json['autoSaveContent'] as bool? ?? true,
      showCharacterCount: json['showCharacterCount'] as bool? ?? true,
      confirmBeforePosting: json['confirmBeforePosting'] as bool? ?? false,
      nostrRelays:
          (json['nostrRelays'] as List<dynamic>?)?.cast<String>() ??
          const [
            'wss://relay.damus.io',
            'wss://nos.lol',
            'wss://relay.snort.social',
            'wss://relay.nostr.band',
          ],
    );
  }

  /// Convert settings to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create settings from JSON string
  factory AppSettings.fromJsonString(String jsonString) {
    return AppSettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Get default account ID for a platform
  String? getDefaultAccount(PlatformType platform) {
    return defaultAccounts[platform];
  }

  /// Set default account for a platform
  AppSettings setDefaultAccount(PlatformType platform, String accountId) {
    final newDefaults = Map<PlatformType, String>.from(defaultAccounts);
    newDefaults[platform] = accountId;
    return copyWith(defaultAccounts: newDefaults);
  }

  /// Remove default account for a platform
  AppSettings removeDefaultAccount(PlatformType platform) {
    final newDefaults = Map<PlatformType, String>.from(defaultAccounts);
    newDefaults.remove(platform);
    return copyWith(defaultAccounts: newDefaults);
  }

  /// Set custom Nostr relays (max 10)
  AppSettings setNostrRelays(List<String> relays) {
    final validRelays = relays
        .where((relay) => _isValidRelayUrl(relay))
        .toList();
    final limitedRelays = validRelays.take(10).toList();
    return copyWith(nostrRelays: limitedRelays);
  }

  /// Add a Nostr relay (max 10 total)
  AppSettings addNostrRelay(String relay) {
    if (!_isValidRelayUrl(relay)) return this;
    if (nostrRelays.contains(relay)) return this;
    if (nostrRelays.length >= 10) return this;

    final newRelays = List<String>.from(nostrRelays);
    newRelays.add(relay);
    return copyWith(nostrRelays: newRelays);
  }

  /// Remove a Nostr relay
  AppSettings removeNostrRelay(String relay) {
    final newRelays = List<String>.from(nostrRelays);
    newRelays.remove(relay);
    return copyWith(nostrRelays: newRelays);
  }

  /// Reset Nostr relays to defaults
  AppSettings resetNostrRelaysToDefault() {
    return copyWith(
      nostrRelays: const [
        'wss://relay.damus.io',
        'wss://nos.lol',
        'wss://relay.snort.social',
        'wss://relay.nostr.band',
      ],
    );
  }

  /// Validate if a URL is a valid WebSocket relay URL
  bool _isValidRelayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'wss' || uri.scheme == 'ws') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to convert ThemeMode to string
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Helper method to convert string to ThemeMode
  static ThemeMode _themeModeFromString(String? mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.minimizeToTray == minimizeToTray &&
        other.startMinimized == startMinimized &&
        _mapEquals(other.defaultAccounts, defaultAccounts) &&
        other.autoSaveContent == autoSaveContent &&
        other.showCharacterCount == showCharacterCount &&
        other.confirmBeforePosting == confirmBeforePosting &&
        _listEquals(other.nostrRelays, nostrRelays);
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      minimizeToTray,
      startMinimized,
      Object.hashAll(
        defaultAccounts.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      autoSaveContent,
      showCharacterCount,
      confirmBeforePosting,
      Object.hashAll(nostrRelays),
    );
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, minimizeToTray: $minimizeToTray, '
        'startMinimized: $startMinimized, defaultAccounts: $defaultAccounts, '
        'autoSaveContent: $autoSaveContent, showCharacterCount: $showCharacterCount, '
        'confirmBeforePosting: $confirmBeforePosting, nostrRelays: $nostrRelays)';
  }
}
