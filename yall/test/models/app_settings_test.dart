import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/app_settings.dart';
import 'package:yall/models/platform_type.dart';

void main() {
  group('AppSettings', () {
    test('should create with default values', () {
      const settings = AppSettings();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.minimizeToTray, true);
      expect(settings.startMinimized, false);
      expect(settings.defaultAccounts, isEmpty);
      expect(settings.autoSaveContent, true);
      expect(settings.showCharacterCount, true);
      expect(settings.confirmBeforePosting, false);
    });

    test('defaultSettings factory should create default settings', () {
      final settings = AppSettings.defaultSettings();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.minimizeToTray, true);
      expect(settings.startMinimized, false);
      expect(settings.defaultAccounts, isEmpty);
      expect(settings.autoSaveContent, true);
      expect(settings.showCharacterCount, true);
      expect(settings.confirmBeforePosting, false);
    });

    test('should create with custom values', () {
      final defaultAccounts = {
        PlatformType.mastodon: 'mastodon-account-id',
        PlatformType.bluesky: 'bluesky-account-id',
      };

      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
        startMinimized: true,
        defaultAccounts: defaultAccounts,
        autoSaveContent: false,
        showCharacterCount: false,
        confirmBeforePosting: true,
      );

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.minimizeToTray, false);
      expect(settings.startMinimized, true);
      expect(settings.defaultAccounts, defaultAccounts);
      expect(settings.autoSaveContent, false);
      expect(settings.showCharacterCount, false);
      expect(settings.confirmBeforePosting, true);
    });

    test('copyWith should create new instance with updated fields', () {
      const original = AppSettings();
      final updated = original.copyWith(
        themeMode: ThemeMode.light,
        minimizeToTray: false,
        confirmBeforePosting: true,
      );

      expect(updated.themeMode, ThemeMode.light);
      expect(updated.minimizeToTray, false);
      expect(updated.startMinimized, original.startMinimized);
      expect(updated.defaultAccounts, original.defaultAccounts);
      expect(updated.autoSaveContent, original.autoSaveContent);
      expect(updated.showCharacterCount, original.showCharacterCount);
      expect(updated.confirmBeforePosting, true);
    });

    test('toJson should serialize settings correctly', () {
      final defaultAccounts = {
        PlatformType.mastodon: 'mastodon-account-id',
        PlatformType.nostr: 'nostr-account-id',
      };

      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
        startMinimized: true,
        defaultAccounts: defaultAccounts,
        autoSaveContent: false,
        showCharacterCount: false,
        confirmBeforePosting: true,
      );

      final json = settings.toJson();

      expect(json['themeMode'], 'dark');
      expect(json['minimizeToTray'], false);
      expect(json['startMinimized'], true);
      expect(json['defaultAccounts']['mastodon'], 'mastodon-account-id');
      expect(json['defaultAccounts']['nostr'], 'nostr-account-id');
      expect(json['autoSaveContent'], false);
      expect(json['showCharacterCount'], false);
      expect(json['confirmBeforePosting'], true);
    });

    test('fromJson should deserialize settings correctly', () {
      final json = {
        'themeMode': 'light',
        'minimizeToTray': false,
        'startMinimized': true,
        'defaultAccounts': {
          'mastodon': 'mastodon-account-id',
          'bluesky': 'bluesky-account-id',
        },
        'autoSaveContent': false,
        'showCharacterCount': false,
        'confirmBeforePosting': true,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.themeMode, ThemeMode.light);
      expect(settings.minimizeToTray, false);
      expect(settings.startMinimized, true);
      expect(settings.defaultAccounts[PlatformType.mastodon], 'mastodon-account-id');
      expect(settings.defaultAccounts[PlatformType.bluesky], 'bluesky-account-id');
      expect(settings.autoSaveContent, false);
      expect(settings.showCharacterCount, false);
      expect(settings.confirmBeforePosting, true);
    });

    test('fromJson should handle missing fields with defaults', () {
      final json = <String, dynamic>{};
      final settings = AppSettings.fromJson(json);

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.minimizeToTray, true);
      expect(settings.startMinimized, false);
      expect(settings.defaultAccounts, isEmpty);
      expect(settings.autoSaveContent, true);
      expect(settings.showCharacterCount, true);
      expect(settings.confirmBeforePosting, false);
    });

    test('fromJson should skip invalid platform IDs', () {
      final json = {
        'defaultAccounts': {
          'mastodon': 'mastodon-account-id',
          'invalid-platform': 'invalid-account-id',
          'bluesky': 'bluesky-account-id',
        },
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.defaultAccounts.length, 2);
      expect(settings.defaultAccounts[PlatformType.mastodon], 'mastodon-account-id');
      expect(settings.defaultAccounts[PlatformType.bluesky], 'bluesky-account-id');
    });

    test('toJsonString and fromJsonString should work correctly', () {
      final original = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
        defaultAccounts: {PlatformType.mastodon: 'test-account'},
      );

      final jsonString = original.toJsonString();
      final recreated = AppSettings.fromJsonString(jsonString);

      expect(recreated.themeMode, original.themeMode);
      expect(recreated.minimizeToTray, original.minimizeToTray);
      expect(recreated.defaultAccounts, original.defaultAccounts);
    });

    test('getDefaultAccount should return account ID for platform', () {
      final settings = AppSettings(
        defaultAccounts: {
          PlatformType.mastodon: 'mastodon-account-id',
          PlatformType.bluesky: 'bluesky-account-id',
        },
      );

      expect(settings.getDefaultAccount(PlatformType.mastodon), 'mastodon-account-id');
      expect(settings.getDefaultAccount(PlatformType.bluesky), 'bluesky-account-id');
      expect(settings.getDefaultAccount(PlatformType.nostr), null);
    });

    test('setDefaultAccount should add/update default account', () {
      const original = AppSettings();
      final updated = original.setDefaultAccount(PlatformType.mastodon, 'new-account-id');

      expect(updated.getDefaultAccount(PlatformType.mastodon), 'new-account-id');
      expect(original.getDefaultAccount(PlatformType.mastodon), null);
    });

    test('removeDefaultAccount should remove default account', () {
      final original = AppSettings(
        defaultAccounts: {
          PlatformType.mastodon: 'mastodon-account-id',
          PlatformType.bluesky: 'bluesky-account-id',
        },
      );

      final updated = original.removeDefaultAccount(PlatformType.mastodon);

      expect(updated.getDefaultAccount(PlatformType.mastodon), null);
      expect(updated.getDefaultAccount(PlatformType.bluesky), 'bluesky-account-id');
      expect(original.getDefaultAccount(PlatformType.mastodon), 'mastodon-account-id');
    });

    test('equality should work correctly', () {
      final settings1 = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
        defaultAccounts: {PlatformType.mastodon: 'account-id'},
      );

      final settings2 = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
        defaultAccounts: {PlatformType.mastodon: 'account-id'},
      );

      final settings3 = AppSettings(
        themeMode: ThemeMode.light,
        minimizeToTray: false,
        defaultAccounts: {PlatformType.mastodon: 'account-id'},
      );

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
      expect(settings1.hashCode, equals(settings2.hashCode));
    });

    test('toString should provide readable representation', () {
      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        minimizeToTray: false,
      );

      final string = settings.toString();
      expect(string, contains('ThemeMode.dark'));
      expect(string, contains('false'));
    });

    group('Theme mode conversion', () {
      test('should convert theme modes to strings correctly', () {
        expect(AppSettings(themeMode: ThemeMode.light).toJson()['themeMode'], 'light');
        expect(AppSettings(themeMode: ThemeMode.dark).toJson()['themeMode'], 'dark');
        expect(AppSettings(themeMode: ThemeMode.system).toJson()['themeMode'], 'system');
      });

      test('should convert strings to theme modes correctly', () {
        expect(AppSettings.fromJson({'themeMode': 'light'}).themeMode, ThemeMode.light);
        expect(AppSettings.fromJson({'themeMode': 'dark'}).themeMode, ThemeMode.dark);
        expect(AppSettings.fromJson({'themeMode': 'system'}).themeMode, ThemeMode.system);
        expect(AppSettings.fromJson({'themeMode': 'invalid'}).themeMode, ThemeMode.system);
        expect(AppSettings.fromJson({}).themeMode, ThemeMode.system);
      });
    });
  });
}