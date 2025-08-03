import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';
import '../models/post_data.dart';
import '../models/media_attachment.dart';
import 'error_handler.dart';
import 'social_platform_service.dart';

/// Service for interacting with Mastodon instances
class MastodonService extends SocialPlatformService {
  final http.Client _httpClient;
  final ErrorHandler _errorHandler = ErrorHandler();

  MastodonService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  PlatformType get platformType => PlatformType.mastodon;

  @override
  List<String> get requiredCredentialFields => ['instance_url', 'access_token'];

  @override
  bool get supportsMediaUploads => true;

  @override
  int get maxMediaAttachments => 4;

  @override
  int get maxMediaFileSize => 40 * 1024 * 1024; // 40MB

  @override
  List<String> get supportedMediaTypes => [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'video/webm',
  ];

  /// Optional credential fields that may be present
  static const List<String> optionalCredentialFields = [
    'client_id',
    'client_secret',
    'refresh_token',
  ];

  @override
  Future<bool> authenticate(Account account) async {
    try {
      if (!hasRequiredCredentials(account)) {
        final error = SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.invalidCredentials,
          message:
              'Missing required credentials: ${requiredCredentialFields.join(', ')}',
        );
        _errorHandler.logError(
          'Mastodon authentication',
          error,
          context: {'account_id': account.id},
          platform: platformType,
        );
        throw error;
      }

      final instanceUrl = account.getCredential<String>('instance_url')!;
      final accessToken = account.getCredential<String>('access_token')!;

      // Verify credentials by getting account info
      final response = await _httpClient.get(
        Uri.parse('$instanceUrl/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final error = SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.authenticationError,
          message: 'Invalid access token',
        );
        _errorHandler.logError(
          'Mastodon authentication',
          error,
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        throw error;
      } else {
        final error = SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.serverError,
          message: 'Authentication failed with status ${response.statusCode}',
        );
        _errorHandler.logError(
          'Mastodon authentication',
          error,
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        throw error;
      }
    } on SocketException catch (e, stackTrace) {
      final error = SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.networkError,
        message: 'Network connection failed',
      );
      _errorHandler.logError(
        'Mastodon authentication',
        error,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      throw error;
    } on HttpException catch (e, stackTrace) {
      final error = SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.networkError,
        message: 'HTTP error: ${e.message}',
      );
      _errorHandler.logError(
        'Mastodon authentication',
        error,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      throw error;
    } catch (e, stackTrace) {
      if (e is SocialPlatformException) rethrow;
      final error = SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.unknownError,
        message: 'Authentication failed: ${e.toString()}',
        originalError: e,
      );
      _errorHandler.logError(
        'Mastodon authentication',
        error,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      throw error;
    }
  }

  @override
  Future<PostResult> publishPost(String content, Account account) async {
    try {
      // Validate content length
      if (!isContentValid(content)) {
        final result = createFailureResult(
          content,
          'Content exceeds character limit of $characterLimit',
          PostErrorType.contentTooLong,
        );
        _errorHandler.logError(
          'Mastodon post validation',
          'Content too long: ${content.length} > $characterLimit',
          context: {
            'account_id': account.id,
            'content_length': content.length,
            'character_limit': characterLimit,
          },
          platform: platformType,
        );
        return result;
      }

      // Validate credentials
      if (!hasRequiredCredentials(account)) {
        final result = createFailureResult(
          content,
          'Missing required credentials: ${requiredCredentialFields.join(', ')}',
          PostErrorType.invalidCredentials,
        );
        _errorHandler.logError(
          'Mastodon post credentials',
          'Missing required credentials',
          context: {
            'account_id': account.id,
            'required_fields': requiredCredentialFields,
          },
          platform: platformType,
        );
        return result;
      }

      final instanceUrl = account.getCredential<String>('instance_url')!;
      final accessToken = account.getCredential<String>('access_token')!;

      // Prepare the status data
      final statusData = {
        'status': content,
        'visibility': 'public', // Default to public visibility
      };

      // Post the status
      final response = await _httpClient.post(
        Uri.parse('$instanceUrl/api/v1/statuses'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(statusData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully posted
        return createSuccessResult(content);
      } else if (response.statusCode == 401) {
        final result = createFailureResult(
          content,
          'Authentication failed - invalid access token',
          PostErrorType.authenticationError,
        );
        _errorHandler.logError(
          'Mastodon post authentication',
          'Authentication failed',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        return result;
      } else if (response.statusCode == 422) {
        // Parse error details from response
        String errorMessage = 'Invalid post data';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'] as String;
          }
        } catch (_) {
          // Use default error message if parsing fails
        }
        final result = createFailureResult(
          content,
          errorMessage,
          PostErrorType.contentTooLong,
        );
        _errorHandler.logError(
          'Mastodon post validation',
          'Post validation failed',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'error_message': errorMessage,
            'response_body': response.body,
          },
          platform: platformType,
        );
        return result;
      } else if (response.statusCode == 429) {
        final result = createFailureResult(
          content,
          'Rate limit exceeded - please wait before posting again',
          PostErrorType.rateLimitError,
        );
        _errorHandler.logError(
          'Mastodon post rate limit',
          'Rate limit exceeded',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        return result;
      } else if (response.statusCode >= 500) {
        final result = createFailureResult(
          content,
          'Mastodon server error (${response.statusCode})',
          PostErrorType.serverError,
        );
        _errorHandler.logError(
          'Mastodon post server error',
          'Server error occurred',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        return result;
      } else {
        final result = createFailureResult(
          content,
          'Post failed with status ${response.statusCode}',
          PostErrorType.unknownError,
        );
        _errorHandler.logError(
          'Mastodon post unknown error',
          'Unknown error occurred',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'instance_url': instanceUrl,
          },
          platform: platformType,
        );
        return result;
      }
    } on SocketException catch (e, stackTrace) {
      final result = createFailureResult(
        content,
        'Network connection failed',
        PostErrorType.networkError,
      );
      _errorHandler.logError(
        'Mastodon post network error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return result;
    } on HttpException catch (e, stackTrace) {
      final result = createFailureResult(
        content,
        'HTTP error: ${e.message}',
        PostErrorType.networkError,
      );
      _errorHandler.logError(
        'Mastodon post HTTP error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return result;
    } catch (e, stackTrace) {
      final result = handleError(content, e);
      _errorHandler.logError(
        'Mastodon post unexpected error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return result;
    }
  }

  @override
  Future<PostResult> publishPostWithMedia(PostData postData, Account account) async {
    try {
      // Validate content length
      if (!isContentValid(postData.content)) {
        final result = createFailureResult(
          postData.content,
          'Content exceeds character limit of $characterLimit',
          PostErrorType.contentTooLong,
        );
        return result;
      }

      // Validate credentials
      if (!hasRequiredCredentials(account)) {
        final result = createFailureResult(
          postData.content,
          'Missing required credentials: ${requiredCredentialFields.join(', ')}',
          PostErrorType.invalidCredentials,
        );
        return result;
      }

      // Validate media attachments
      if (postData.mediaAttachments.length > maxMediaAttachments) {
        final result = createFailureResult(
          postData.content,
          'Too many media attachments (max: $maxMediaAttachments)',
          PostErrorType.contentTooLong,
        );
        return result;
      }

      final instanceUrl = account.getCredential<String>('instance_url')!;
      final accessToken = account.getCredential<String>('access_token')!;

      // Upload media attachments first
      final mediaIds = <String>[];
      for (final attachment in postData.mediaAttachments) {
        try {
          final mediaId = await _uploadMedia(instanceUrl, accessToken, attachment);
          if (mediaId != null) {
            mediaIds.add(mediaId);
          }
        } catch (e) {
          final result = createFailureResult(
            postData.content,
            'Failed to upload media: ${e.toString()}',
            PostErrorType.unknownError,
          );
          return result;
        }
      }

      // Prepare the status data with media
      final statusData = {
        'status': postData.content,
        'visibility': 'public',
        if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
      };

      // Post the status
      final response = await _httpClient.post(
        Uri.parse('$instanceUrl/api/v1/statuses'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(statusData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return createSuccessResult(postData.content);
      } else {
        final result = createFailureResult(
          postData.content,
          'Post failed with status ${response.statusCode}',
          PostErrorType.unknownError,
        );
        return result;
      }
    } catch (e) {
      return handleError(postData.content, e);
    }
  }

  /// Upload a media attachment to Mastodon
  Future<String?> _uploadMedia(String instanceUrl, String accessToken, MediaAttachment attachment) async {
    try {
      final bytes = await attachment.getBytes();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$instanceUrl/api/v2/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: attachment.fileName,
      ));
      
      if (attachment.description != null && attachment.description!.isNotEmpty) {
        request.fields['description'] = attachment.description!;
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['id'] as String?;
      } else {
        throw Exception('Media upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload media: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateConnection(Account account) async {
    try {
      return await authenticate(account);
    } catch (e) {
      return false;
    }
  }

  @override
  bool validateCredentials(Account account) {
    if (!super.validateCredentials(account)) return false;

    final instanceUrl = account.getCredential<String>('instance_url');
    final accessToken = account.getCredential<String>('access_token');

    // Validate instance URL format
    if (instanceUrl == null || instanceUrl.isEmpty) return false;
    try {
      final uri = Uri.parse(instanceUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) return false;
    } catch (e) {
      return false;
    }

    // Validate access token format
    if (accessToken == null || accessToken.isEmpty) return false;

    return true;
  }

  /// Create OAuth application for a Mastodon instance
  ///
  /// This method registers the application with a Mastodon instance
  /// and returns the client credentials needed for OAuth flow.
  Future<Map<String, String>> createOAuthApp({
    required String instanceUrl,
    required String appName,
    String? website,
    List<String>? scopes,
  }) async {
    try {
      final appData = {
        'client_name': appName,
        'redirect_uris':
            'urn:ietf:wg:oauth:2.0:oob', // Out-of-band for desktop apps
        'scopes': (scopes ?? ['read', 'write']).join(' '),
        if (website != null) 'website': website,
      };

      final response = await _httpClient.post(
        Uri.parse('$instanceUrl/api/v1/apps'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(appData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'client_id': data['client_id'] as String,
          'client_secret': data['client_secret'] as String,
        };
      } else {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.serverError,
          message: 'Failed to create OAuth app: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.networkError,
        message: 'Network connection failed',
      );
    } catch (e) {
      if (e is SocialPlatformException) rethrow;
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.unknownError,
        message: 'Failed to create OAuth app: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get OAuth authorization URL
  ///
  /// Returns the URL where users should be directed to authorize the application.
  String getAuthorizationUrl({
    required String instanceUrl,
    required String clientId,
    List<String>? scopes,
    String? state,
  }) {
    final params = {
      'client_id': clientId,
      'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      'response_type': 'code',
      'scope': (scopes ?? ['read', 'write']).join(' '),
      if (state != null) 'state': state,
    };

    final uri = Uri.parse(
      '$instanceUrl/oauth/authorize',
    ).replace(queryParameters: params);

    return uri.toString();
  }

  /// Exchange authorization code for access token
  ///
  /// This method exchanges the authorization code received from the OAuth flow
  /// for an access token that can be used to make API calls.
  Future<Map<String, String>> exchangeCodeForToken({
    required String instanceUrl,
    required String clientId,
    required String clientSecret,
    required String authorizationCode,
  }) async {
    try {
      final tokenData = {
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
        'grant_type': 'authorization_code',
        'code': authorizationCode,
      };

      final response = await _httpClient.post(
        Uri.parse('$instanceUrl/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tokenData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'access_token': data['access_token'] as String,
          'token_type': data['token_type'] as String,
          'scope': data['scope'] as String,
          if (data.containsKey('refresh_token'))
            'refresh_token': data['refresh_token'] as String,
        };
      } else {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.authenticationError,
          message: 'Failed to exchange code for token: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.networkError,
        message: 'Network connection failed',
      );
    } catch (e) {
      if (e is SocialPlatformException) rethrow;
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.unknownError,
        message: 'Failed to exchange code for token: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get user account information
  ///
  /// Returns information about the authenticated user's account.
  Future<Map<String, dynamic>> getUserInfo(Account account) async {
    try {
      if (!hasRequiredCredentials(account)) {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.invalidCredentials,
          message: 'Missing required credentials',
        );
      }

      final instanceUrl = account.getCredential<String>('instance_url')!;
      final accessToken = account.getCredential<String>('access_token')!;

      final response = await _httpClient.get(
        Uri.parse('$instanceUrl/api/v1/accounts/verify_credentials'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.authenticationError,
          message: 'Invalid access token',
        );
      } else {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.serverError,
          message: 'Failed to get user info: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.networkError,
        message: 'Network connection failed',
      );
    } catch (e) {
      if (e is SocialPlatformException) rethrow;
      throw SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.unknownError,
        message: 'Failed to get user info: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
