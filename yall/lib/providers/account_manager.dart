import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/platform_type.dart';
import '../services/secure_storage_service.dart';
import '../services/social_platform_service.dart';
import '../services/mastodon_service.dart';
import '../services/bluesky_service.dart';
import '../services/nostr_service.dart';
import '../services/retry_manager.dart';

/// Exception thrown by AccountManager operations
class AccountManagerException implements Exception {
  final String message;
  final dynamic originalError;

  const AccountManagerException(this.message, [this.originalError]);

  @override
  String toString() => 'AccountManagerException: $message';
}

/// Provider for managing user accounts across different social media platforms
class AccountManager extends ChangeNotifier {
  final SecureStorageService _storageService;
  final Map<PlatformType, SocialPlatformService> _platformServices;
  final List<Account> _accounts = [];
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  AccountManager({
    SecureStorageService? storageService,
    Map<PlatformType, SocialPlatformService>? platformServices,
  }) : _storageService = storageService ?? SecureStorageService(),
       _platformServices = platformServices ?? {
         PlatformType.mastodon: MastodonService(),
         PlatformType.bluesky: BlueskyService(),
         PlatformType.nostr: NostrService(),
       };

  /// Get all accounts
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Get accounts for a specific platform
  List<Account> getAccountsForPlatform(PlatformType platform) {
    return _accounts.where((account) => account.platform == platform).toList();
  }

  /// Get active accounts for a specific platform
  List<Account> getActiveAccountsForPlatform(PlatformType platform) {
    return _accounts
        .where((account) => account.platform == platform && account.isActive)
        .toList();
  }

  /// Get account by ID
  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Check if loading operation is in progress
  bool get isLoading => _isLoading;

  /// Get current error message
  String? get error => _error;

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load all accounts from secure storage
  Future<void> loadAccounts() async {
    _setLoading(true);
    _clearError();

    try {
      final accountIds = await _storageService.getAllAccountIds();
      final loadedAccounts = <Account>[];

      for (final accountId in accountIds) {
        try {
          final accountData = await _storageService.getAccountData(accountId);
          if (accountData != null) {
            final account = Account.fromJson(accountData);

            // Load credentials for the account
            final credentials = await _storageService.getAccountCredentials(accountId);
            if (credentials != null) {
              final accountWithCredentials = account.withCredentials(credentials);
              loadedAccounts.add(accountWithCredentials);
            } else {
              // Account exists but no credentials - add without credentials
              loadedAccounts.add(account);
            }
          }
        } catch (e) {
          // Log error but continue loading other accounts
          debugPrint('Failed to load account $accountId: $e');
        }
      }

      _accounts.clear();
      _accounts.addAll(loadedAccounts);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load accounts: ${e.toString()}');
      throw AccountManagerException('Failed to load accounts', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new account
  Future<Account> addAccount({
    required PlatformType platform,
    required String displayName,
    required String username,
    required Map<String, dynamic> credentials,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate credentials format
      final service = _platformServices[platform];
      if (service == null) {
        throw AccountManagerException('Unsupported platform: ${platform.displayName}');
      }

      // Create account with generated ID
      final accountId = _uuid.v4();
      final account = Account(
        id: accountId,
        platform: platform,
        displayName: displayName,
        username: username,
        createdAt: DateTime.now(),
        isActive: true,
        credentials: credentials,
      );

      // Validate credentials with the service
      if (!service.hasRequiredCredentials(account)) {
        throw AccountManagerException(
          'Missing required credentials for ${platform.displayName}: ${service.requiredCredentialFields.join(', ')}'
        );
      }

      // Test authentication
      final isValid = await validateAccount(account);
      if (!isValid) {
        throw AccountManagerException('Account authentication failed');
      }

      // Store account data and credentials separately
      await _storageService.storeAccountData(accountId, account.toJson());
      await _storageService.storeAccountCredentials(accountId, credentials);

      // Add to local list
      _accounts.add(account);
      notifyListeners();

      return account;
    } catch (e) {
      _setError('Failed to add account: ${e.toString()}');
      if (e is AccountManagerException) {
        rethrow;
      }
      throw AccountManagerException('Failed to add account', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing account
  Future<Account> updateAccount(Account updatedAccount) async {
    _setLoading(true);
    _clearError();

    try {
      final existingIndex = _accounts.indexWhere((a) => a.id == updatedAccount.id);
      if (existingIndex == -1) {
        throw AccountManagerException('Account not found: ${updatedAccount.id}');
      }

      // Validate credentials if they were updated
      final service = _platformServices[updatedAccount.platform];
      if (service != null && !service.hasRequiredCredentials(updatedAccount)) {
        throw AccountManagerException(
          'Missing required credentials for ${updatedAccount.platform.displayName}: ${service.requiredCredentialFields.join(', ')}'
        );
      }

      // Update storage
      await _storageService.storeAccountData(updatedAccount.id, updatedAccount.toJson());
      if (updatedAccount.credentials.isNotEmpty) {
        await _storageService.storeAccountCredentials(updatedAccount.id, updatedAccount.credentials);
      }

      // Update local list
      _accounts[existingIndex] = updatedAccount;
      notifyListeners();

      return updatedAccount;
    } catch (e) {
      _setError('Failed to update account: ${e.toString()}');
      if (e is AccountManagerException) {
        rethrow;
      }
      throw AccountManagerException('Failed to update account', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Remove an account
  Future<void> removeAccount(String accountId) async {
    _setLoading(true);
    _clearError();

    try {
      final accountIndex = _accounts.indexWhere((a) => a.id == accountId);
      if (accountIndex == -1) {
        throw AccountManagerException('Account not found: $accountId');
      }

      // Remove from storage
      await _storageService.deleteAllAccountData(accountId);

      // Remove from local list
      _accounts.removeAt(accountIndex);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove account: ${e.toString()}');
      if (e is AccountManagerException) {
        rethrow;
      }
      throw AccountManagerException('Failed to remove account', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Validate account connection
  Future<bool> validateAccount(Account account) async {
    try {
      final service = _platformServices[account.platform];
      if (service == null) {
        return false;
      }

      return await service.validateConnectionWithRetry(account);
    } catch (e) {
      debugPrint('Account validation failed for ${account.id}: $e');
      return false;
    }
  }

  /// Test authentication for an account
  Future<bool> testAuthentication(Account account) async {
    try {
      final service = _platformServices[account.platform];
      if (service == null) {
        return false;
      }

      return await service.authenticateWithRetry(account);
    } catch (e) {
      debugPrint('Authentication test failed for ${account.id}: $e');
      return false;
    }
  }

  /// Activate or deactivate an account
  Future<void> setAccountActive(String accountId, bool isActive) async {
    final account = getAccountById(accountId);
    if (account == null) {
      throw AccountManagerException('Account not found: $accountId');
    }

    final updatedAccount = account.copyWith(isActive: isActive);
    await updateAccount(updatedAccount);
  }

  /// Get the default account for a platform (first active account)
  Account? getDefaultAccountForPlatform(PlatformType platform) {
    final activeAccounts = getActiveAccountsForPlatform(platform);
    return activeAccounts.isNotEmpty ? activeAccounts.first : null;
  }

  /// Check if any accounts exist for a platform
  bool hasAccountsForPlatform(PlatformType platform) {
    return getAccountsForPlatform(platform).isNotEmpty;
  }

  /// Check if any active accounts exist for a platform
  bool hasActiveAccountsForPlatform(PlatformType platform) {
    return getActiveAccountsForPlatform(platform).isNotEmpty;
  }

  /// Get total number of accounts
  int get totalAccountCount => _accounts.length;

  /// Get number of active accounts
  int get activeAccountCount => _accounts.where((a) => a.isActive).length;

  /// Validate all accounts and return results
  Future<Map<String, bool>> validateAllAccounts() async {
    final results = <String, bool>{};

    for (final account in _accounts) {
      results[account.id] = await validateAccount(account);
    }

    return results;
  }

  /// Refresh account credentials (re-authenticate)
  Future<bool> refreshAccount(String accountId) async {
    final account = getAccountById(accountId);
    if (account == null) {
      throw AccountManagerException('Account not found: $accountId');
    }

    return await testAuthentication(account);
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Helper method for testing - adds account directly to the list
  @visibleForTesting
  void addAccountForTesting(Account account) {
    _accounts.add(account);
    notifyListeners();
  }

  /// Helper method for testing - clears all accounts
  @visibleForTesting
  void clearAccountsForTesting() {
    _accounts.clear();
    notifyListeners();
  }

  /// Helper method for testing - sets error state
  @visibleForTesting
  void setErrorForTesting(String error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _accounts.clear();
    super.dispose();
  }
}