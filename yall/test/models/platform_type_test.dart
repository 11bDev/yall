import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/platform_type.dart';

void main() {
  group('PlatformType', () {
    test('should have correct enum values', () {
      expect(PlatformType.values.length, 3);
      expect(PlatformType.values, contains(PlatformType.mastodon));
      expect(PlatformType.values, contains(PlatformType.bluesky));
      expect(PlatformType.values, contains(PlatformType.nostr));
    });

    test('should have correct properties for each platform', () {
      // Mastodon
      expect(PlatformType.mastodon.id, 'mastodon');
      expect(PlatformType.mastodon.displayName, 'Mastodon');
      expect(PlatformType.mastodon.characterLimit, 500);

      // Bluesky
      expect(PlatformType.bluesky.id, 'bluesky');
      expect(PlatformType.bluesky.displayName, 'Bluesky');
      expect(PlatformType.bluesky.characterLimit, 300);

      // Nostr
      expect(PlatformType.nostr.id, 'nostr');
      expect(PlatformType.nostr.displayName, 'Nostr');
      expect(PlatformType.nostr.characterLimit, 280);
    });

    test('fromId should return correct platform', () {
      expect(PlatformType.fromId('mastodon'), PlatformType.mastodon);
      expect(PlatformType.fromId('bluesky'), PlatformType.bluesky);
      expect(PlatformType.fromId('nostr'), PlatformType.nostr);
    });

    test('fromId should throw for invalid ID', () {
      expect(() => PlatformType.fromId('invalid'), throwsArgumentError);
      expect(() => PlatformType.fromId(''), throwsArgumentError);
    });

    test('allIds should return all platform IDs', () {
      final allIds = PlatformType.allIds;
      expect(allIds.length, 3);
      expect(allIds, contains('mastodon'));
      expect(allIds, contains('bluesky'));
      expect(allIds, contains('nostr'));
    });

    test('allDisplayNames should return all display names', () {
      final allNames = PlatformType.allDisplayNames;
      expect(allNames.length, 3);
      expect(allNames, contains('Mastodon'));
      expect(allNames, contains('Bluesky'));
      expect(allNames, contains('Nostr'));
    });
  });
}