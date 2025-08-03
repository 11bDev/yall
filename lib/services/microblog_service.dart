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

/// Service for interacting with Micro.blog
/// Uses Micro.blog's Mastodon-compatible API
class MicroblogService extends SocialPlatformService {
  final http.Client _httpClient;
  final ErrorHandler _errorHandler = ErrorHandler();

  MicroblogService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  PlatformType get platformType => PlatformType.microblog;

  @override
  List<String> get requiredCredentialFields => ['username', 'app_token'];

  @override
  bool get supportsMediaUploads => true;

  @override
  int get maxMediaAttachments => 4;

  @override
  int get maxMediaFileSize => 10 * 1024 * 1024; // 10MB

  @override
  List<String> get supportedMediaTypes => [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  /// Optional credential fields that may be present
  static const List<String> optionalCredentialFields = [
    'blog_id',
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
          'Micro.blog authentication',
          error,
          context: {'account_id': account.id},
          platform: platformType,
        );
        throw error;
      }

      final username = account.getCredential<String>('username')!;
      final appToken = account.getCredential<String>('app_token')!;

      // Test authentication by getting user info
      final response = await _httpClient.get(
        Uri.parse('https://micro.blog/account/verify'),
        headers: {
          'Authorization': 'Token $appToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final error = SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.authenticationError,
          message: 'Invalid app token',
        );
        _errorHandler.logError(
          'Micro.blog authentication',
          error,
          context: {
            'account_id': account.id,
            'username': username,
            'status_code': response.statusCode,
          },
          platform: platformType,
        );
        throw error;
      } else {
        final error = SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.networkError,
          message: 'Authentication failed with status ${response.statusCode}',
        );
        _errorHandler.logError(
          'Micro.blog authentication',
          error,
          context: {
            'account_id': account.id,
            'username': username,
            'status_code': response.statusCode,
          },
          platform: platformType,
        );
        throw error;
      }
    } catch (e, stackTrace) {
      if (e is SocialPlatformException) {
        rethrow;
      }
      final error = SocialPlatformException(
        platform: platformType,
        errorType: PostErrorType.authenticationError,
        message: 'Authentication failed: ${e.toString()}',
        originalError: e,
      );
      _errorHandler.logError(
        'Micro.blog authentication',
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
          'Micro.blog post validation',
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
          'Micro.blog post credentials',
          'Missing required credentials',
          context: {
            'account_id': account.id,
            'required_fields': requiredCredentialFields,
          },
          platform: platformType,
        );
        return result;
      }

      final appToken = account.getCredential<String>('app_token')!;

      // Prepare the post data
      final postData = {
        'content': content,
      };

      // Post using Micro.blog's posting API
      final response = await _httpClient.post(
        Uri.parse('https://micro.blog/micropub'),
        headers: {
          'Authorization': 'Token $appToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        // Successfully posted
        return createSuccessResult(content);
      } else if (response.statusCode == 401) {
        final result = createFailureResult(
          content,
          'Authentication failed - invalid app token',
          PostErrorType.authenticationError,
        );
        _errorHandler.logError(
          'Micro.blog post authentication',
          'Authentication failed',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
          },
          platform: platformType,
        );
        return result;
      } else if (response.statusCode == 400) {
        // Parse error details from response
        String errorMessage = 'Invalid post data';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'] as String;
          } else if (errorData.containsKey('error_description')) {
            errorMessage = errorData['error_description'] as String;
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
          'Micro.blog post validation',
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
          'Micro.blog post rate limit',
          'Rate limit exceeded',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
          },
          platform: platformType,
        );
        return result;
      } else if (response.statusCode >= 500) {
        final result = createFailureResult(
          content,
          'Micro.blog server error (${response.statusCode})',
          PostErrorType.serverError,
        );
        _errorHandler.logError(
          'Micro.blog post server error',
          'Server error occurred',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
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
          'Micro.blog post unknown error',
          'Unknown error occurred',
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
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
        'Micro.blog post network error',
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
        'Micro.blog post HTTP error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return result;
    } catch (e, stackTrace) {
      final result = handleError(content, e);
      _errorHandler.logError(
        'Micro.blog post unexpected error',
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

      final appToken = account.getCredential<String>('app_token')!;

      // For Micro.blog, we'll use the micropub endpoint with multipart form data
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://micro.blog/micropub'),
      );
      
      request.headers['Authorization'] = 'Token $appToken';
      
      // Add content
      request.fields['content'] = postData.content;
      
      // Add media files
      for (int i = 0; i < postData.mediaAttachments.length; i++) {
        final attachment = postData.mediaAttachments[i];
        try {
          final bytes = await attachment.getBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'photo[$i]', // Micro.blog expects photo[0], photo[1], etc.
            bytes,
            filename: attachment.fileName,
          ));
          
          // Add alt text if available
          if (attachment.description != null && attachment.description!.isNotEmpty) {
            request.fields['mp-photo-alt[$i]'] = attachment.description!;
          }
        } catch (e) {
          final result = createFailureResult(
            postData.content,
            'Failed to process media: ${e.toString()}',
            PostErrorType.unknownError,
          );
          return result;
        }
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return createSuccessResult(postData.content);
      } else {
        final result = createFailureResult(
          postData.content,
          'Post with media failed with status ${response.statusCode}',
          PostErrorType.unknownError,
        );
        return result;
      }
    } catch (e) {
      return handleError(postData.content, e);
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

    final username = account.getCredential<String>('username');
    final appToken = account.getCredential<String>('app_token');

    // Validate username format
    if (username == null || username.isEmpty) return false;

    // Validate app token format
    if (appToken == null || appToken.isEmpty) return false;

    return true;
  }
}