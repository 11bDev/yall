import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:yall/models/account.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/providers/post_manager.dart';
import 'package:yall/services/social_platform_service.dart';

import 'post_manager_test.mocks.dart';

@GenerateMocks([SocialPlatformService])
void main() {
  group('PostManager', () {
    late PostManager postManager;
    late MockSocialPlatformService mockMastodonService;
    late MockSocialPlatformService mockBlueskyService;
    late MockSocialPlatformService mockNostrService;

    late Account mastodonAccount;
    late Account blueskyAccount;
    late Account nostrAccount;

    setUp(() {
      mockMastodonService = MockSocialPlatformService();
      mockBlueskyService = MockSocialPlatformService();
      mockNostrService = MockSocialPlatformService();

      // Set up mock service properties
      when(mockMastodonService.platformType).thenReturn(PlatformType.mastodon);
      when(mockMastodonService.characterLimit).thenReturn(500);
      when(mockMastodonService.platformName).thenReturn('Mastodon');

      when(mockBlueskyService.platformType).thenReturn(PlatformType.bluesky);
      when(mockBlueskyService.characterLimit).thenReturn(300);
      when(mockBlueskyService.platformName).thenReturn('Bluesky');

      when(mockNostrService.platformType).thenReturn(PlatformType.nostr);
      when(mockNostrService.characterLimit).thenReturn(1000);
      when(mockNostrService.platformName).thenReturn('Nostr');

      postManager = PostManager(
        platformServices: {
          PlatformType.mastodon: mockMastodonService,
          PlatformType.bluesky: mockBlueskyService,
          PlatformType.nostr: mockNostrService,
        },
      );

      // Create test accounts
      mastodonAccount = Account(
        id: 'mastodon-1',
        platform: PlatformType.mastodon,
        displayName: 'Test Mastodon',
        username: 'test@mastodon.social',
        createdAt: DateTime.now(),
        isActive: true,
        credentials: {'access_token': 'token123', 'instance_url': 'https://mastodon.social'},
      );

      blueskyAccount = Account(
        id: 'bluesky-1',
        platform: PlatformType.bluesky,
        displayName: 'Test Bluesky',
        username: 'test.bsky.social',
        createdAt: DateTime.now(),
        isActive: true,
        credentials: {'identifier': 'test.bsky.social', 'password': 'password123'},
      );

      nostrAccount = Account(
        id: 'nostr-1',
        platform: PlatformType.nostr,
        displayName: 'Test Nostr',
        username: 'npub123',
        createdAt: DateTime.now(),
        isActive: true,
        credentials: {'private_key': 'key123', 'relays': ['wss://relay.damus.io']},
      );
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(postManager.isPosting, false);
        expect(postManager.lastPostResult, null);
        expect(postManager.error, null);
      });
    });

    group('Character Limit Validation', () {
      test('should validate character limits correctly', () {
        const shortContent = 'Hello world!';
        final mediumContent = 'A' * 250;
        final longContent = 'A' * 400;
        final veryLongContent = 'A' * 600;

        // Mock isContentValid for all services
        when(mockMastodonService.isContentValid(any)).thenReturn(true);
        when(mockBlueskyService.isContentValid(any)).thenReturn(true);
        when(mockNostrService.isContentValid(any)).thenReturn(true);

        // Short content should be valid for all platforms
        var validation = postManager.validateCharacterLimits(
          shortContent,
          {PlatformType.mastodon, PlatformType.bluesky, PlatformType.nostr},
        );
        expect(validation.isValid, true);

        // Medium content should be valid for all platforms
        validation = postManager.validateCharacterLimits(
          mediumContent,
          {PlatformType.mastodon, PlatformType.bluesky, PlatformType.nostr},
        );
        expect(validation.isValid, true);

        // Long content should fail for Bluesky (300 char limit)
        when(mockMastodonService.isContentValid(longContent)).thenReturn(true);
        when(mockBlueskyService.isContentValid(longContent)).thenReturn(false);
        validation = postManager.validateCharacterLimits(
          longContent,
          {PlatformType.mastodon, PlatformType.bluesky},
        );
        expect(validation.isValid, false);
        expect(validation.violatingPlatforms, contains(PlatformType.bluesky));
        expect(validation.violatingPlatforms, isNot(contains(PlatformType.mastodon)));

        // Very long content should fail for Mastodon and Bluesky
        when(mockMastodonService.isContentValid(veryLongContent)).thenReturn(false);
        when(mockBlueskyService.isContentValid(veryLongContent)).thenReturn(false);
        when(mockNostrService.isContentValid(veryLongContent)).thenReturn(true);
        validation = postManager.validateCharacterLimits(
          veryLongContent,
          {PlatformType.mastodon, PlatformType.bluesky, PlatformType.nostr},
        );
        expect(validation.isValid, false);
        expect(validation.violatingPlatforms, contains(PlatformType.mastodon));
        expect(validation.violatingPlatforms, contains(PlatformType.bluesky));
        expect(validation.violatingPlatforms, isNot(contains(PlatformType.nostr)));
      });

      test('should handle empty platform set', () {
        const content = 'Hello world!';
        final validation = postManager.validateCharacterLimits(content, {});
        expect(validation.isValid, false);
        expect(validation.errorMessage, contains('No platforms selected'));
      });

      test('should return correct minimum character limit', () {
        // Bluesky has the lowest limit (300)
        final limit = postManager.getCharacterLimit({
          PlatformType.mastodon,
          PlatformType.bluesky,
          PlatformType.nostr,
        });
        expect(limit, 300);

        // Single platform
        final singleLimit = postManager.getCharacterLimit({PlatformType.mastodon});
        expect(singleLimit, 500);

        // Empty set
        final emptyLimit = postManager.getCharacterLimit({});
        expect(emptyLimit, 0);
      });

      test('should calculate remaining characters correctly', () {
        const content = 'Hello world!'; // 12 characters
        final remaining = postManager.getRemainingCharacters(
          content,
          {PlatformType.bluesky}, // 300 char limit
        );
        expect(remaining, 288);
      });
    });

    group('canPost', () {
      test('should return true for valid content and platforms', () {
        const content = 'Hello world!';
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        final canPost = postManager.canPost(content, {PlatformType.mastodon});
        expect(canPost, true);
      });

      test('should return false for empty content', () {
        final canPost = postManager.canPost('', {PlatformType.mastodon});
        expect(canPost, false);
      });

      test('should return false for whitespace-only content', () {
        final canPost = postManager.canPost('   ', {PlatformType.mastodon});
        expect(canPost, false);
      });

      test('should return false for empty platform set', () {
        const content = 'Hello world!';
        final canPost = postManager.canPost(content, {});
        expect(canPost, false);
      });

      test('should return false when posting is in progress', () {
        const content = 'Hello world!';
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        postManager.setPostingForTesting(true);
        final canPost = postManager.canPost(content, {PlatformType.mastodon});
        expect(canPost, false);
      });

      test('should return false for content exceeding character limits', () {
        final longContent = 'A' * 400; // Exceeds Bluesky limit
        when(mockBlueskyService.isContentValid(longContent)).thenReturn(false);
        final canPost = postManager.canPost(longContent, {PlatformType.bluesky});
        expect(canPost, false);
      });
    });

    group('publishToSelectedPlatforms', () {
      test('should successfully post to single platform', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        // Mock successful posting
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(PlatformType.mastodon, true));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allSuccessful, true);
        expect(result.successfulPlatforms, contains(PlatformType.mastodon));
        expect(postManager.lastPostResult, equals(result));
        expect(postManager.isPosting, false);

        verify(mockMastodonService.publishPost(content, mastodonAccount)).called(1);
      });

      test('should successfully post to multiple platforms in parallel', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon, PlatformType.bluesky};
        final selectedAccounts = {
          PlatformType.mastodon: mastodonAccount,
          PlatformType.bluesky: blueskyAccount,
        };

        // Mock successful posting for both platforms
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(PlatformType.mastodon, true));

        when(mockBlueskyService.isContentValid(content)).thenReturn(true);
        when(mockBlueskyService.hasRequiredCredentials(blueskyAccount)).thenReturn(true);
        when(mockBlueskyService.publishPost(content, blueskyAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(PlatformType.bluesky, true));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allSuccessful, true);
        expect(result.successfulPlatforms, containsAll([PlatformType.mastodon, PlatformType.bluesky]));
        expect(result.totalPlatforms, 2);

        verify(mockMastodonService.publishPost(content, mastodonAccount)).called(1);
        verify(mockBlueskyService.publishPost(content, blueskyAccount)).called(1);
      });

      test('should handle partial posting failures', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon, PlatformType.bluesky};
        final selectedAccounts = {
          PlatformType.mastodon: mastodonAccount,
          PlatformType.bluesky: blueskyAccount,
        };

        // Mock successful posting for Mastodon, failure for Bluesky
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(PlatformType.mastodon, true));

        when(mockBlueskyService.isContentValid(content)).thenReturn(true);
        when(mockBlueskyService.hasRequiredCredentials(blueskyAccount)).thenReturn(true);
        when(mockBlueskyService.publishPost(content, blueskyAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(
              PlatformType.bluesky,
              false,
              error: 'Network error',
              errorType: PostErrorType.networkError,
            ));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allSuccessful, false);
        expect(result.allFailed, false);
        expect(result.successfulPlatforms, contains(PlatformType.mastodon));
        expect(result.failedPlatforms, contains(PlatformType.bluesky));
        expect(result.getError(PlatformType.bluesky), 'Network error');
        expect(result.getErrorType(PlatformType.bluesky), PostErrorType.networkError);
      });

      test('should handle all platforms failing', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon, PlatformType.bluesky};
        final selectedAccounts = {
          PlatformType.mastodon: mastodonAccount,
          PlatformType.bluesky: blueskyAccount,
        };

        // Mock failures for both platforms
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(
              PlatformType.mastodon,
              false,
              error: 'Auth error',
              errorType: PostErrorType.authenticationError,
            ));

        when(mockBlueskyService.isContentValid(content)).thenReturn(true);
        when(mockBlueskyService.hasRequiredCredentials(blueskyAccount)).thenReturn(true);
        when(mockBlueskyService.publishPost(content, blueskyAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(
              PlatformType.bluesky,
              false,
              error: 'Server error',
              errorType: PostErrorType.serverError,
            ));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allFailed, true);
        expect(result.successCount, 0);
        expect(result.failureCount, 2);
        expect(result.hasErrors, true);
      });

      test('should throw exception for empty content', () async {
        const content = '';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        expect(
          () => postManager.publishToSelectedPlatforms(content, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('Content cannot be empty'),
          )),
        );
      });

      test('should throw exception for no platforms selected', () async {
        const content = 'Hello world!';
        final selectedPlatforms = <PlatformType>{};
        final selectedAccounts = <PlatformType, Account>{};

        expect(
          () => postManager.publishToSelectedPlatforms(content, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('No platforms selected'),
          )),
        );
      });

      test('should throw exception for content exceeding character limits', () async {
        final longContent = 'A' * 400; // Exceeds Bluesky limit
        final selectedPlatforms = {PlatformType.bluesky};
        final selectedAccounts = {PlatformType.bluesky: blueskyAccount};

        // Mock that the content is too long for Bluesky
        when(mockBlueskyService.isContentValid(longContent)).thenReturn(false);

        expect(
          () => postManager.publishToSelectedPlatforms(longContent, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('exceeds character limit'),
          )),
        );
      });

      test('should throw exception for missing account', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = <PlatformType, Account>{}; // No account provided

        // Mock that content is valid to pass character limit validation
        when(mockMastodonService.isContentValid(content)).thenReturn(true);

        expect(
          () => postManager.publishToSelectedPlatforms(content, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('No account selected'),
          )),
        );
      });

      test('should throw exception for inactive account', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final inactiveAccount = mastodonAccount.copyWith(isActive: false);
        final selectedAccounts = {PlatformType.mastodon: inactiveAccount};

        // Mock that content is valid to pass character limit validation
        when(mockMastodonService.isContentValid(content)).thenReturn(true);

        expect(
          () => postManager.publishToSelectedPlatforms(content, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('is not active'),
          )),
        );
      });

      test('should throw exception when posting is already in progress', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        postManager.setPostingForTesting(true);

        expect(
          () => postManager.publishToSelectedPlatforms(content, selectedPlatforms, selectedAccounts),
          throwsA(isA<PostManagerException>().having(
            (e) => e.message,
            'message',
            contains('posting operation is already in progress'),
          )),
        );
      });

      test('should handle platform service unavailable', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        // Create PostManager without Mastodon service
        final postManagerWithoutService = PostManager(platformServices: {});

        final result = await postManagerWithoutService.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allFailed, true);
        expect(result.getError(PlatformType.mastodon), contains('Platform service not available'));
        expect(result.getErrorType(PlatformType.mastodon), PostErrorType.platformUnavailable);
      });

      test('should set posting state correctly during operation', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        // Mock delayed response to test posting state
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return PostResult.empty(content).addPlatformResult(PlatformType.mastodon, true);
        });

        expect(postManager.isPosting, false);

        final future = postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        // Should be posting now
        expect(postManager.isPosting, true);

        await future;

        // Should not be posting anymore
        expect(postManager.isPosting, false);
      });
    });

    group('Utility Methods', () {
      test('should clear error correctly', () {
        postManager.setErrorForTesting('Test error');
        expect(postManager.error, 'Test error');

        postManager.clearError();
        expect(postManager.error, null);
      });

      test('should clear last result correctly', () {
        final testResult = PostResult.empty('test');
        postManager.setLastResultForTesting(testResult);
        expect(postManager.lastPostResult, testResult);

        postManager.clearLastResult();
        expect(postManager.lastPostResult, null);
      });

      test('should get character limits for platforms', () {
        final limits = postManager.getCharacterLimitsForPlatforms({
          PlatformType.mastodon,
          PlatformType.bluesky,
          PlatformType.nostr,
        });

        expect(limits[PlatformType.mastodon], 500);
        expect(limits[PlatformType.bluesky], 300);
        expect(limits[PlatformType.nostr], 1000);
      });

      test('should validate content for platforms', () {
        const shortContent = 'Hello!';
        final longContent = 'A' * 400;

        // Set up mocks before calling the method
        when(mockMastodonService.isContentValid(shortContent)).thenReturn(true);
        when(mockBlueskyService.isContentValid(shortContent)).thenReturn(true);

        final shortValidation = postManager.validateContentForPlatforms(
          shortContent,
          {PlatformType.mastodon, PlatformType.bluesky},
        );

        expect(shortValidation[PlatformType.mastodon], true);
        expect(shortValidation[PlatformType.bluesky], true);

        // Set up mocks for long content
        when(mockMastodonService.isContentValid(longContent)).thenReturn(true);
        when(mockBlueskyService.isContentValid(longContent)).thenReturn(false);

        final longValidation = postManager.validateContentForPlatforms(
          longContent,
          {PlatformType.mastodon, PlatformType.bluesky},
        );

        expect(longValidation[PlatformType.mastodon], true);
        expect(longValidation[PlatformType.bluesky], false);
      });
    });

    group('Error Handling', () {
      test('should handle service exceptions gracefully', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenThrow(Exception('Service error'));
        when(mockMastodonService.handleError(content, any))
            .thenReturn(PostResult.empty(content).addPlatformResult(
              PlatformType.mastodon,
              false,
              error: 'Service error',
              errorType: PostErrorType.unknownError,
            ));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allFailed, true);
        expect(result.getError(PlatformType.mastodon), 'Service error');
      });

      test('should handle content validation failures', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        // Mock that content passes character limit validation but fails during posting
        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(true);
        when(mockMastodonService.publishPost(content, mastodonAccount))
            .thenAnswer((_) async => PostResult.empty(content).addPlatformResult(
              PlatformType.mastodon,
              false,
              error: 'Content validation failed during posting',
              errorType: PostErrorType.contentTooLong,
            ));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allFailed, true);
        expect(result.getError(PlatformType.mastodon), contains('Content validation failed'));
        expect(result.getErrorType(PlatformType.mastodon), PostErrorType.contentTooLong);
      });

      test('should handle missing credentials', () async {
        const content = 'Hello world!';
        final selectedPlatforms = {PlatformType.mastodon};
        final selectedAccounts = {PlatformType.mastodon: mastodonAccount};

        when(mockMastodonService.isContentValid(content)).thenReturn(true);
        when(mockMastodonService.hasRequiredCredentials(mastodonAccount)).thenReturn(false);
        when(mockMastodonService.createFailureResult(
          content,
          'Account missing required credentials',
          PostErrorType.invalidCredentials,
        )).thenReturn(PostResult.empty(content).addPlatformResult(
          PlatformType.mastodon,
          false,
          error: 'Account missing required credentials',
          errorType: PostErrorType.invalidCredentials,
        ));

        final result = await postManager.publishToSelectedPlatforms(
          content,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allFailed, true);
        expect(result.getError(PlatformType.mastodon), contains('missing required credentials'));
        expect(result.getErrorType(PlatformType.mastodon), PostErrorType.invalidCredentials);
      });
    });

    group('State Management', () {
      test('should notify listeners when posting state changes', () {
        var notificationCount = 0;
        postManager.addListener(() => notificationCount++);

        postManager.setPostingForTesting(true);
        expect(notificationCount, 1);

        postManager.setPostingForTesting(false);
        expect(notificationCount, 2);
      });

      test('should notify listeners when error changes', () {
        var notificationCount = 0;
        postManager.addListener(() => notificationCount++);

        postManager.setErrorForTesting('Test error');
        expect(notificationCount, 1);

        postManager.clearError();
        expect(notificationCount, 2);
      });

      test('should notify listeners when last result changes', () {
        var notificationCount = 0;
        postManager.addListener(() => notificationCount++);

        final testResult = PostResult.empty('test');
        postManager.setLastResultForTesting(testResult);
        expect(notificationCount, 1);

        postManager.clearLastResult();
        expect(notificationCount, 2);
      });
    });
  });

  group('CharacterLimitValidation', () {
    test('should create valid validation result', () {
      const validation = CharacterLimitValidation(
        isValid: true,
        contentLength: 100,
      );

      expect(validation.isValid, true);
      expect(validation.contentLength, 100);
      expect(validation.errorMessage, null);
      expect(validation.violatingPlatforms, null);
      expect(validation.minCharacterLimit, null);
    });

    test('should create invalid validation result', () {
      final validation = CharacterLimitValidation(
        isValid: false,
        errorMessage: 'Content too long',
        violatingPlatforms: {PlatformType.bluesky},
        contentLength: 400,
        minCharacterLimit: 300,
      );

      expect(validation.isValid, false);
      expect(validation.errorMessage, 'Content too long');
      expect(validation.violatingPlatforms, contains(PlatformType.bluesky));
      expect(validation.contentLength, 400);
      expect(validation.minCharacterLimit, 300);
    });

    test('should have correct toString representation', () {
      final validation = CharacterLimitValidation(
        isValid: false,
        errorMessage: 'Test error',
        violatingPlatforms: {PlatformType.mastodon},
        contentLength: 600,
        minCharacterLimit: 500,
      );

      final stringRepresentation = validation.toString();
      expect(stringRepresentation, contains('isValid: false'));
      expect(stringRepresentation, contains('errorMessage: Test error'));
      expect(stringRepresentation, contains('contentLength: 600'));
      expect(stringRepresentation, contains('minCharacterLimit: 500'));
    });
  });
}