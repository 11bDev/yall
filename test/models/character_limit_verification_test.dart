import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/platform_type.dart';

void main() {
  group('PlatformType Character Limits', () {
    test('should have correct character limits', () {
      expect(PlatformType.mastodon.characterLimit, equals(500));
      expect(PlatformType.bluesky.characterLimit, equals(300));
      expect(PlatformType.nostr.characterLimit, equals(800));
    });

    test('should validate Nostr character limit is not 0', () {
      // This test ensures Nostr no longer has unlimited (0) characters
      expect(PlatformType.nostr.characterLimit, isNot(equals(0)));
      expect(PlatformType.nostr.characterLimit, equals(800));
    });

    test('should create platform from ID correctly', () {
      final nostr = PlatformType.fromId('nostr');
      expect(nostr.characterLimit, equals(800));
      expect(nostr.displayName, equals('Nostr'));
    });
  });
}
