import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/models/platform_type.dart';

void main() {
  group('PostResult', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
    });

    test('should create empty result', () {
      final result = PostResult.empty('test content');

      expect(result.platformResults, isEmpty);
      expect(result.errors, isEmpty);
      expect(result.errorTypes, isEmpty);
      expect(result.originalContent, 'test content');
      expect(result.hasErrors, false);
      expect(result.totalPlatforms, 0);
    });

    test('should create all successful result', () {
      final platforms = {PlatformType.mastodon, PlatformType.bluesky};
      final result = PostResult.allSuccessful(platforms, 'test content');

      expect(result.platformResults.length, 2);
      expect(result.platformResults[PlatformType.mastodon], true);
      expect(result.platformResults[PlatformType.bluesky], true);
      expect(result.errors, isEmpty);
      expect(result.errorTypes, isEmpty);
      expect(result.originalContent, 'test content');
      expect(result.allSuccessful, true);
      expect(result.hasErrors, false);
    });

    test('should create all failed result', () {
      final platforms = {PlatformType.mastodon, PlatformType.bluesky};
      final result = PostResult.allFailed(
        platforms,
        'test content',
        'Network error',
        PostErrorType.networkError,
      );

      expect(result.platformResults.length, 2);
      expect(result.platformResults[PlatformType.mastodon], false);
      expect(result.platformResults[PlatformType.bluesky], false);
      expect(result.errors.length, 2);
      expect(result.errors[PlatformType.mastodon], 'Network error');
      expect(result.errors[PlatformType.bluesky], 'Network error');
      expect(result.errorTypes[PlatformType.mastodon], PostErrorType.networkError);
      expect(result.errorTypes[PlatformType.bluesky], PostErrorType.networkError);
      expect(result.allFailed, true);
      expect(result.hasErrors, true);
    });

    test('should calculate success and failure counts correctly', () {
      final result = PostResult(
        platformResults: {
          PlatformType.mastodon: true,
          PlatformType.bluesky: false,
          PlatformType.nostr: true,
        },
        errors: {PlatformType.bluesky: 'Error'},
        errorTypes: {PlatformType.bluesky: PostErrorType.networkError},
        originalContent: 'test',
        timestamp: testDate,
      );

      expect(result.successCount, 2);
      expect(result.failureCount, 1);
      expect(result.totalPlatforms, 3);
      expect(result.successfulPlatforms, {PlatformType.mastodon, PlatformType.nostr});
      expect(result.failedPlatforms, {PlatformType.bluesky});
    });

    test('addPlatformResult should add successful result', () {
      final original = PostResult.empty('test');
      final updated = original.addPlatformResult(PlatformType.mastodon, true);

      expect(updated.platformResults[PlatformType.mastodon], true);
      expect(updated.errors.containsKey(PlatformType.mastodon), false);
      expect(updated.errorTypes.containsKey(PlatformType.mastodon), false);
      expect(original.platformResults, isEmpty);
    });

    test('addPlatformResult should add failed result with error', () {
      final original = PostResult.empty('test');
      final updated = original.addPlatformResult(
        PlatformType.mastodon,
        false,
        error: 'Auth failed',
        errorType: PostErrorType.authenticationError,
      );

      expect(updated.platformResults[PlatformType.mastodon], false);
      expect(updated.errors[PlatformType.mastodon], 'Auth failed');
      expect(updated.errorTypes[PlatformType.mastodon], PostErrorType.authenticationError);
    });

    test('addPlatformResult should remove error when updating to success', () {
      final original = PostResult(
        platformResults: {PlatformType.mastodon: false},
        errors: {PlatformType.mastodon: 'Error'},
        errorTypes: {PlatformType.mastodon: PostErrorType.networkError},
        originalContent: 'test',
        timestamp: testDate,
      );

      final updated = original.addPlatformResult(PlatformType.mastodon, true);

      expect(updated.platformResults[PlatformType.mastodon], true);
      expect(updated.errors.containsKey(PlatformType.mastodon), false);
      expect(updated.errorTypes.containsKey(PlatformType.mastodon), false);
    });

    test('should provide correct status checks', () {
      final mixedResult = PostResult(
        platformResults: {
          PlatformType.mastodon: true,
          PlatformType.bluesky: false,
        },
        errors: {PlatformType.bluesky: 'Error'},
        errorTypes: {PlatformType.bluesky: PostErrorType.networkError},
        originalContent: 'test',
        timestamp: testDate,
      );

      expect(mixedResult.allSuccessful, false);
      expect(mixedResult.allFailed, false);
      expect(mixedResult.hasErrors, true);
      expect(mixedResult.isSuccessful(PlatformType.mastodon), true);
      expect(mixedResult.isSuccessful(PlatformType.bluesky), false);
      expect(mixedResult.isSuccessful(PlatformType.nostr), false);
    });

    test('should get error information correctly', () {
      final result = PostResult(
        platformResults: {PlatformType.mastodon: false},
        errors: {PlatformType.mastodon: 'Auth error'},
        errorTypes: {PlatformType.mastodon: PostErrorType.authenticationError},
        originalContent: 'test',
        timestamp: testDate,
      );

      expect(result.getError(PlatformType.mastodon), 'Auth error');
      expect(result.getError(PlatformType.bluesky), null);
      expect(result.getErrorType(PlatformType.mastodon), PostErrorType.authenticationError);
      expect(result.getErrorType(PlatformType.bluesky), null);
    });

    test('getSummaryMessage should provide correct messages', () {
      final allSuccess = PostResult.allSuccessful({PlatformType.mastodon, PlatformType.bluesky}, 'test');
      expect(allSuccess.getSummaryMessage(), 'Successfully posted to all 2 platforms');

      final allFailed = PostResult.allFailed({PlatformType.mastodon}, 'test', 'Error', PostErrorType.networkError);
      expect(allFailed.getSummaryMessage(), 'Failed to post to all 1 platform');

      final mixed = PostResult(
        platformResults: {
          PlatformType.mastodon: true,
          PlatformType.bluesky: false,
          PlatformType.nostr: true,
        },
        errors: {PlatformType.bluesky: 'Error'},
        errorTypes: {PlatformType.bluesky: PostErrorType.networkError},
        originalContent: 'test',
        timestamp: testDate,
      );
      expect(mixed.getSummaryMessage(), 'Posted to 2 of 3 platforms successfully');
    });

    test('getDetailedErrors should return formatted error messages', () {
      final result = PostResult(
        platformResults: {
          PlatformType.mastodon: false,
          PlatformType.bluesky: false,
        },
        errors: {
          PlatformType.mastodon: 'Auth failed',
          PlatformType.bluesky: 'Rate limited',
        },
        errorTypes: {
          PlatformType.mastodon: PostErrorType.authenticationError,
          PlatformType.bluesky: PostErrorType.rateLimitError,
        },
        originalContent: 'test',
        timestamp: testDate,
      );

      final detailedErrors = result.getDetailedErrors();
      expect(detailedErrors.length, 2);
      expect(detailedErrors, contains('Mastodon: Auth failed'));
      expect(detailedErrors, contains('Bluesky: Rate limited'));
    });

    test('toJson should serialize correctly', () {
      final result = PostResult(
        platformResults: {
          PlatformType.mastodon: true,
          PlatformType.bluesky: false,
        },
        errors: {PlatformType.bluesky: 'Error message'},
        errorTypes: {PlatformType.bluesky: PostErrorType.networkError},
        originalContent: 'test content',
        timestamp: testDate,
      );

      final json = result.toJson();

      expect(json['platformResults']['mastodon'], true);
      expect(json['platformResults']['bluesky'], false);
      expect(json['errors']['bluesky'], 'Error message');
      expect(json['errorTypes']['bluesky'], 'networkError');
      expect(json['originalContent'], 'test content');
      expect(json['timestamp'], testDate.toIso8601String());
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'platformResults': {
          'mastodon': true,
          'bluesky': false,
        },
        'errors': {
          'bluesky': 'Error message',
        },
        'errorTypes': {
          'bluesky': 'networkError',
        },
        'originalContent': 'test content',
        'timestamp': testDate.toIso8601String(),
      };

      final result = PostResult.fromJson(json);

      expect(result.platformResults[PlatformType.mastodon], true);
      expect(result.platformResults[PlatformType.bluesky], false);
      expect(result.errors[PlatformType.bluesky], 'Error message');
      expect(result.errorTypes[PlatformType.bluesky], PostErrorType.networkError);
      expect(result.originalContent, 'test content');
      expect(result.timestamp, testDate);
    });

    test('fromJson should handle missing fields', () {
      final json = <String, dynamic>{};
      final result = PostResult.fromJson(json);

      expect(result.platformResults, isEmpty);
      expect(result.errors, isEmpty);
      expect(result.errorTypes, isEmpty);
      expect(result.originalContent, '');
    });

    test('fromJson should skip invalid platform IDs', () {
      final json = {
        'platformResults': {
          'mastodon': true,
          'invalid-platform': false,
        },
        'errors': {
          'invalid-platform': 'Error',
        },
        'errorTypes': {
          'invalid-platform': 'networkError',
        },
      };

      final result = PostResult.fromJson(json);

      expect(result.platformResults.length, 1);
      expect(result.platformResults[PlatformType.mastodon], true);
      expect(result.errors, isEmpty);
      expect(result.errorTypes, isEmpty);
    });

    test('fromJson should handle invalid error types', () {
      final json = {
        'platformResults': {
          'mastodon': false,
        },
        'errors': {
          'mastodon': 'Error',
        },
        'errorTypes': {
          'mastodon': 'invalidErrorType',
        },
      };

      final result = PostResult.fromJson(json);

      expect(result.errorTypes[PlatformType.mastodon], PostErrorType.unknownError);
    });

    test('toJsonString and fromJsonString should work correctly', () {
      final original = PostResult(
        platformResults: {PlatformType.mastodon: true},
        errors: {},
        errorTypes: {},
        originalContent: 'test',
        timestamp: testDate,
      );

      final jsonString = original.toJsonString();
      final recreated = PostResult.fromJsonString(jsonString);

      expect(recreated.platformResults, original.platformResults);
      expect(recreated.errors, original.errors);
      expect(recreated.errorTypes, original.errorTypes);
      expect(recreated.originalContent, original.originalContent);
      expect(recreated.timestamp, original.timestamp);
    });

    test('equality should work correctly', () {
      final result1 = PostResult(
        platformResults: {PlatformType.mastodon: true},
        errors: {},
        errorTypes: {},
        originalContent: 'test',
        timestamp: testDate,
      );

      final result2 = PostResult(
        platformResults: {PlatformType.mastodon: true},
        errors: {},
        errorTypes: {},
        originalContent: 'test',
        timestamp: testDate,
      );

      final result3 = PostResult(
        platformResults: {PlatformType.mastodon: false},
        errors: {},
        errorTypes: {},
        originalContent: 'test',
        timestamp: testDate,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('toString should provide readable representation', () {
      final result = PostResult(
        platformResults: {PlatformType.mastodon: true},
        errors: {},
        errorTypes: {},
        originalContent: 'This is a very long test content that should be truncated in the toString method',
        timestamp: testDate,
      );

      final string = result.toString();
      expect(string, contains('platformResults'));
      expect(string, contains('This is a very long test content that should be tr...'));
    });
  });

  group('PostErrorType', () {
    test('should have all expected error types', () {
      expect(PostErrorType.values.length, 8);
      expect(PostErrorType.values, contains(PostErrorType.networkError));
      expect(PostErrorType.values, contains(PostErrorType.authenticationError));
      expect(PostErrorType.values, contains(PostErrorType.rateLimitError));
      expect(PostErrorType.values, contains(PostErrorType.contentTooLong));
      expect(PostErrorType.values, contains(PostErrorType.platformUnavailable));
      expect(PostErrorType.values, contains(PostErrorType.invalidCredentials));
      expect(PostErrorType.values, contains(PostErrorType.serverError));
      expect(PostErrorType.values, contains(PostErrorType.unknownError));
    });
  });
}