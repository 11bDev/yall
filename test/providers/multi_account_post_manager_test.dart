import 'package:flutter_test/flutter_test.dart';
import 'package:yall/models/account.dart';
import 'package:yall/models/platform_type.dart';
import 'package:yall/models/post_data.dart';
import 'package:yall/models/post_result.dart';
import 'package:yall/providers/post_manager.dart';
import 'package:yall/services/social_platform_service.dart';

// Mock service for testing
class MockSocialPlatformService extends SocialPlatformService {
  final bool shouldSucceed;
  final String? errorMessage;

  MockSocialPlatformService({this.shouldSucceed = true, this.errorMessage});

  @override
  PlatformType get platformType => PlatformType.nostr;

  @override
  List<String> get requiredCredentialFields => ['private_key'];

  @override
  Future<bool> authenticate(Account account) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return shouldSucceed;
  }

  @override
  Future<PostResult> publishPost(String content, Account account) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (shouldSucceed) {
      return createSuccessResult(content);
    } else {
      return createFailureResult(
        content,
        errorMessage ?? 'Test error',
        PostErrorType.unknownError,
      );
    }
  }

  @override
  Future<bool> validateConnection(Account account) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return shouldSucceed;
  }
}

void main() {
  group('PostManager Multi-Account Tests', () {
    late PostManager postManager;
    late Account account1;
    late Account account2;

    setUp(() {
      // Create test accounts
      account1 = Account(
        id: 'test-account-1',
        platform: PlatformType.nostr,
        displayName: 'Test Account 1',
        username: 'testuser1',
        createdAt: DateTime.now(),
        credentials: {'private_key': 'test_key_1'},
      );

      account2 = Account(
        id: 'test-account-2',
        platform: PlatformType.nostr,
        displayName: 'Test Account 2',
        username: 'testuser2',
        createdAt: DateTime.now(),
        credentials: {'private_key': 'test_key_2'},
      );

      // Create PostManager with mock services
      postManager = PostManager(
        platformServices: {PlatformType.nostr: MockSocialPlatformService()},
      );
    });

    test(
      'should post to multiple accounts of the same platform successfully',
      () async {
        final postData = PostData(
          content: 'Test post content',
          mediaAttachments: [],
        );

        final selectedPlatforms = {PlatformType.nostr};
        final selectedAccounts = {
          PlatformType.nostr: [account1, account2],
        };

        final result = await postManager.publishToMultipleAccounts(
          postData,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allSuccessful, isTrue);
        expect(result.platformResults[PlatformType.nostr], isTrue);
      },
    );

    test(
      'should handle mixed success/failure when posting to multiple accounts',
      () async {
        // Create PostManager with one failing service
        final failingPostManager = PostManager(
          platformServices: {
            PlatformType.nostr: MockSocialPlatformService(
              shouldSucceed: false,
              errorMessage: 'Network error',
            ),
          },
        );

        final postData = PostData(
          content: 'Test post content',
          mediaAttachments: [],
        );

        final selectedPlatforms = {PlatformType.nostr};
        final selectedAccounts = {
          PlatformType.nostr: [account1, account2],
        };

        final result = await failingPostManager.publishToMultipleAccounts(
          postData,
          selectedPlatforms,
          selectedAccounts,
        );

        expect(result.allSuccessful, isFalse);
        expect(result.hasErrors, isTrue);
      },
    );

    test('should validate that platforms have selected accounts', () async {
      final postData = PostData(
        content: 'Test post content',
        mediaAttachments: [],
      );

      final selectedPlatforms = {PlatformType.nostr};
      final selectedAccounts = <PlatformType, List<Account>>{
        PlatformType.nostr: [], // Empty list - should fail validation
      };

      expect(
        () => postManager.publishToMultipleAccounts(
          postData,
          selectedPlatforms,
          selectedAccounts,
        ),
        throwsA(isA<PostManagerException>()),
      );
    });

    test(
      'should validate account platform matches selected platform',
      () async {
        // Create account with different platform
        final mismatchedAccount = Account(
          id: 'mismatched-account',
          platform: PlatformType.mastodon, // Different platform
          displayName: 'Mismatched Account',
          username: 'mismatched',
          createdAt: DateTime.now(),
          credentials: {'access_token': 'test_token'},
        );

        final postData = PostData(
          content: 'Test post content',
          mediaAttachments: [],
        );

        final selectedPlatforms = {PlatformType.nostr};
        final selectedAccounts = {
          PlatformType.nostr: [mismatchedAccount], // Platform mismatch
        };

        expect(
          () => postManager.publishToMultipleAccounts(
            postData,
            selectedPlatforms,
            selectedAccounts,
          ),
          throwsA(isA<PostManagerException>()),
        );
      },
    );

    test('should validate that all accounts are active', () async {
      // Create inactive account
      final inactiveAccount = Account(
        id: 'inactive-account',
        platform: PlatformType.nostr,
        displayName: 'Inactive Account',
        username: 'inactive',
        createdAt: DateTime.now(),
        isActive: false, // Inactive
        credentials: {'private_key': 'test_key'},
      );

      final postData = PostData(
        content: 'Test post content',
        mediaAttachments: [],
      );

      final selectedPlatforms = {PlatformType.nostr};
      final selectedAccounts = {
        PlatformType.nostr: [inactiveAccount],
      };

      expect(
        () => postManager.publishToMultipleAccounts(
          postData,
          selectedPlatforms,
          selectedAccounts,
        ),
        throwsA(isA<PostManagerException>()),
      );
    });
  });
}
