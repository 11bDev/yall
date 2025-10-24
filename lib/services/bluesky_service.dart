import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';
import '../models/post_data.dart';
import 'error_handler.dart';
import 'social_platform_service.dart';
import 'image_service.dart';

/// Service for interacting with Bluesky via AT Protocol
class BlueskyService extends SocialPlatformService {
  final http.Client _httpClient;
  final ErrorHandler _errorHandler = ErrorHandler();
  final ImageService _imageService = ImageService();
  static const String _defaultPdsUrl = 'https://bsky.social';

  BlueskyService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  PlatformType get platformType => PlatformType.bluesky;

  @override
  bool get supportsMediaUploads => true;

  @override
  int get maxMediaAttachments => 4;

  @override
  int get maxMediaFileSize => 976560; // 976KB - Bluesky's actual limit (slightly under 1MB)

  @override
  List<String> get supportedMediaTypes => ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

  @override
  List<String> get requiredCredentialFields => ['identifier', 'password'];

  /// Optional credential fields that may be present
  static const List<String> optionalCredentialFields = [
    'pds_url',
    'access_jwt',
    'refresh_jwt',
    'did',
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
          'Bluesky authentication',
          error,
          context: {'account_id': account.id},
          platform: platformType,
        );
        throw error;
      }

      final identifier = account.getCredential<String>('identifier')!;
      final password = account.getCredential<String>('password')!;
      final pdsUrl = account.getCredential<String>('pds_url') ?? _defaultPdsUrl;

      // Create session with AT Protocol
      await _createSession(
        pdsUrl: pdsUrl,
        identifier: identifier,
        password: password,
      );

      // If we get here, authentication was successful
      return true;
    } catch (e, stackTrace) {
      _errorHandler.logError(
        'Bluesky authentication error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return false;
    }
  }

  @override
  Future<PostResult> publishPost(String content, Account account) async {
    // Delegate to publishPostWithMedia for text-only posts
    return publishPostWithMedia(PostData(content: content), account);
  }

  @override
  Future<PostResult> publishPostWithMedia(
    PostData postData,
    Account account,
  ) async {
    try {
      // Validate content length
      if (!isContentValid(postData.content)) {
        final result = createFailureResult(
          postData.content,
          'Content exceeds character limit of $characterLimit',
          PostErrorType.contentTooLong,
        );
        _errorHandler.logError(
          'Bluesky post validation',
          'Content too long: ${postData.content.length} > $characterLimit',
          context: {
            'account_id': account.id,
            'content_length': postData.content.length,
            'character_limit': characterLimit,
          },
          platform: platformType,
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
        _errorHandler.logError(
          'Bluesky post credentials',
          'Missing required credentials',
          context: {
            'account_id': account.id,
            'required_fields': requiredCredentialFields,
          },
          platform: platformType,
        );
        return result;
      }

      final identifier = account.getCredential<String>('identifier')!;
      final password = account.getCredential<String>('password')!;
      final pdsUrl = account.getCredential<String>('pds_url') ?? _defaultPdsUrl;

      // Get or create session
      String accessJwt;
      String did;

      final existingAccessJwt = account.getCredential<String>('access_jwt');
      final existingDid = account.getCredential<String>('did');

      if (existingAccessJwt != null && existingDid != null) {
        // Try to use existing session
        accessJwt = existingAccessJwt;
        did = existingDid;
      } else {
        // Create new session
        final sessionData = await _createSession(
          pdsUrl: pdsUrl,
          identifier: identifier,
          password: password,
        );
        accessJwt = sessionData['accessJwt'] as String;
        did = sessionData['did'] as String;
      }

      // --- Bluesky image upload and embed logic ---
      List<Map<String, dynamic>> embedImages = [];
      for (final attachment in postData.mediaAttachments) {
        try {
          // Get image bytes
          final originalBytes = attachment.bytes ?? await attachment.file!.readAsBytes();
          
          // Compress image to fit within Bluesky's 1MB limit if needed
          final compressedBytes = await _imageService.compressImageToSize(
            originalBytes,
            maxMediaFileSize,
          );
          
          // Upload compressed image as blob
          final blobResponse = await _httpClient.post(
            Uri.parse('$pdsUrl/xrpc/com.atproto.repo.uploadBlob'),
            headers: {
              'Authorization': 'Bearer $accessJwt',
              'Content-Type': attachment.mimeType,
            },
            body: compressedBytes,
          );
          if (blobResponse.statusCode == 200) {
            final blobData = jsonDecode(blobResponse.body);
            if (blobData['blob'] != null) {
              final blob = blobData['blob'] as Map<String, dynamic>;
              embedImages.add({
                'alt': attachment.description ?? '',
                'image': {
                  '\$type': 'blob',
                  'ref': blob['ref'],
                  'mimeType': blob['mimeType'],
                  'size': blob['size'],
                },
              });
            }
          } else {
            print('Failed to upload Bluesky image: ${blobResponse.body}');
          }
        } catch (e) {
          print('Exception uploading Bluesky image: $e');
        }
      }

      // Create the post record
      final now = DateTime.now().toUtc();
      final postRecord = <String, dynamic>{
        '\$type': 'app.bsky.feed.post',
        'text': postData.content,
        'createdAt': now.toIso8601String(),
      };
      if (embedImages.isNotEmpty) {
        postRecord['embed'] = {
          '\$type': 'app.bsky.embed.images',
          'images': embedImages,
        };
      }

      // Create the record via XRPC
      final response = await _httpClient.post(
        Uri.parse('$pdsUrl/xrpc/com.atproto.repo.createRecord'),
        headers: {
          'Authorization': 'Bearer $accessJwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'repo': did,
          'collection': 'app.bsky.feed.post',
          'record': postRecord,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully posted
        return createSuccessResult(postData.content);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ??
            errorData['error'] ??
            'Failed to post to Bluesky (${response.statusCode})';
        final result = createFailureResult(
          postData.content,
          errorMessage,
          PostErrorType.unknownError,
        );
        _errorHandler.logError(
          'Bluesky post error',
          errorMessage,
          context: {
            'account_id': account.id,
            'status_code': response.statusCode,
            'response_body': response.body,
          },
          platform: platformType,
        );
        return result;
      }
    } catch (e, stackTrace) {
      final result = handleError(postData.content, e);
      _errorHandler.logError(
        'Bluesky post unexpected error',
        e,
        stackTrace: stackTrace,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return result;
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

    final identifier = account.getCredential<String>('identifier');
    final password = account.getCredential<String>('password');

    // Validate identifier format (can be handle or email)
    if (identifier == null || identifier.isEmpty) return false;

    // Basic validation - should be either email format or handle format
    if (!_isValidIdentifier(identifier)) return false;

    // Validate password
    if (password == null || password.isEmpty) return false;

    // Validate PDS URL if provided
    final pdsUrl = account.getCredential<String>('pds_url');
    if (pdsUrl != null && pdsUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(pdsUrl);
        if (!uri.hasScheme || !uri.scheme.startsWith('http')) return false;
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  /// Create a new session with AT Protocol
  ///
  /// This method authenticates with the PDS and returns session information
  /// including access and refresh tokens.
  Future<Map<String, dynamic>> _createSession({
    required String pdsUrl,
    required String identifier,
    required String password,
  }) async {
    try {
      final sessionData = {'identifier': identifier, 'password': password};

      final response = await _httpClient.post(
        Uri.parse('$pdsUrl/xrpc/com.atproto.server.createSession'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 401) {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.authenticationError,
          message: 'Invalid credentials',
        );
      } else {
        throw SocialPlatformException(
          platform: platformType,
          errorType: PostErrorType.serverError,
          message: 'Failed to create session: ${response.statusCode}',
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
        message: 'Failed to create session: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Validate identifier format
  ///
  /// Bluesky identifiers can be either handles (e.g., user.bsky.social)
  /// or email addresses.
  bool _isValidIdentifier(String identifier) {
    // Check if it's an email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (emailRegex.hasMatch(identifier)) {
      return true;
    }

    // Check if it's a handle format (domain-like)
    final handleRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$',
    );
    if (handleRegex.hasMatch(identifier)) {
      return true;
    }

    return false;
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
