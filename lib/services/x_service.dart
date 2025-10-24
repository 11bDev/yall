import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/account.dart';
import '../models/media_attachment.dart';
import '../models/post_result.dart';
import '../models/platform_type.dart';
import '../models/post_data.dart';
import 'error_handler.dart';
import 'social_platform_service.dart';

/// Service for interacting with X (Twitter)
class XService extends SocialPlatformService {
  final ErrorHandler _errorHandler = ErrorHandler();

  XService();

  @override
  PlatformType get platformType => PlatformType.x;

  @override
  List<String> get requiredCredentialFields => [
    'access_token',
    'access_token_secret',
    'api_key',
    'api_secret',
  ];

  @override
  bool get supportsMediaUploads => true;

  @override
  int get maxMediaAttachments => 4;

  @override
  int get maxMediaFileSize => 5 * 1024 * 1024; // 5MB

  @override
  List<String> get supportedMediaTypes => [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
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
          'X authentication',
          error,
          context: {'account_id': account.id},
          platform: platformType,
        );
        throw error;
      }

      // For now, just validate that we have the required fields
      // In a full implementation, you'd verify the tokens with X API
      return true;
    } catch (e) {
      _errorHandler.logError(
        'X authentication error',
        e,
        context: {'account_id': account.id},
        platform: platformType,
      );
      return false;
    }
  }

  @override
  Future<PostResult> publishPost(String content, Account account) async {
    return publishPostWithMedia(
      PostData(content: content, mediaAttachments: []),
      account,
    );
  }

  @override
  Future<PostResult> publishPostWithMedia(
    PostData postData,
    Account account,
  ) async {
    try {
      if (!hasRequiredCredentials(account)) {
        return createFailureResult(
          postData.content,
          'Account not properly configured',
          PostErrorType.invalidCredentials,
        );
      }

      if (!isContentValid(postData.content)) {
        return createFailureResult(
          postData.content,
          'Post too long (${postData.content.length}/$characterLimit characters)',
          PostErrorType.contentTooLong,
        );
      }

      // Upload media if present
      List<String> mediaIds = [];
      if (postData.mediaAttachments.isNotEmpty) {
        for (final attachment in postData.mediaAttachments) {
          try {
            final mediaId = await _uploadMedia(attachment, account);
            if (mediaId != null) {
              mediaIds.add(mediaId);
            }
          } catch (e) {
            // Continue with other media or text-only post
            print('Failed to upload media: $e');
          }
        }
      }

      // Create tweet
      final tweetData = <String, dynamic>{'text': postData.content};

      if (mediaIds.isNotEmpty) {
        // X API v2 expects media_ids as an array of strings
        tweetData['media'] = {
          'media_ids': mediaIds, // Already strings from API response
        };
      }
      
      // Debug logging
      print('X Post - Media IDs count: ${mediaIds.length}');
      print('X Post - Media IDs: $mediaIds');
      print('X Post - Tweet data: ${jsonEncode(tweetData)}');

      final url = Uri.parse('https://api.twitter.com/2/tweets');
      // For JSON body requests, don't include body in OAuth signature
      final authHeader = _generateOAuthHeader(
        'POST',
        url,
        account,
      );

      final client = http.Client();
      try {
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: jsonEncode(tweetData),
        );

        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          print('X Post successful: ${responseData['data']?['id']}');
          return createSuccessResult(postData.content);
        } else {
          print('X Post failed: ${response.statusCode}');
          print('Response body: ${response.body}');
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['detail'] ??
              errorData['title'] ??
              errorData['errors']?[0]?['message'] ??
              'Failed to post to X (${response.statusCode})';
          return createFailureResult(
            postData.content,
            errorMessage,
            PostErrorType.networkError,
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      return handleError(postData.content, e);
    }
  }

  /// Generate OAuth 1.0a authorization header
  String _generateOAuthHeader(
    String method,
    Uri url,
    Account account,
  ) {
    final consumerKey = account.credentials['api_key']!;
    final consumerSecret = account.credentials['api_secret']!;
    final accessToken = account.credentials['access_token']!;
    final accessTokenSecret = account.credentials['access_token_secret']!;

    // Generate OAuth parameters
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final nonce = _generateNonce();

    final oauthParams = <String, String>{
      'oauth_consumer_key': consumerKey,
      'oauth_nonce': nonce,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': timestamp,
      'oauth_token': accessToken,
      'oauth_version': '1.0',
    };

    // Create signature base string
    final baseString = _createSignatureBaseString(method, url, oauthParams);

    // Create signing key
    final signingKey =
        '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(accessTokenSecret)}';

    // Generate signature
    final signature = _hmacSha1(signingKey, baseString);
    oauthParams['oauth_signature'] = signature;

    // Build authorization header
    final headerParams = oauthParams.entries
        .map((entry) => '${entry.key}="${Uri.encodeComponent(entry.value)}"')
        .join(', ');

    return 'OAuth $headerParams';
  }

  /// Generate a random nonce
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Create OAuth signature base string
  String _createSignatureBaseString(
    String method,
    Uri url,
    Map<String, String> params,
  ) {
    final baseUrl = '${url.scheme}://${url.host}${url.path}';
    final paramString =
        params.entries
            .map(
              (entry) =>
                  '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
            )
            .toList()
          ..sort();

    return '${Uri.encodeComponent(method)}&${Uri.encodeComponent(baseUrl)}&${Uri.encodeComponent(paramString.join('&'))}';
  }

  /// Generate HMAC-SHA1 signature
  String _hmacSha1(String key, String data) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha1, keyBytes);
    final digest = hmac.convert(dataBytes);
    return base64.encode(digest.bytes);
  }

  /// Upload media to X and return media ID
  /// Using simple single-step upload like working fragout implementation
  Future<String?> _uploadMedia(
    MediaAttachment attachment,
    Account account,
  ) async {
    try {
      Uint8List bytes;

      if (attachment.file != null) {
        if (!attachment.file!.existsSync()) {
          print('Media file not found: ${attachment.file!.path}');
          return null;
        }
        bytes = await attachment.file!.readAsBytes();
      } else if (attachment.bytes != null) {
        bytes = attachment.bytes!;
      } else {
        print('No file or bytes available for media attachment');
        return null;
      }

      final client = http.Client();

      try {
        // Simple single-step upload to Twitter v1.1 API
        // This matches the working fragout implementation
        final url = Uri.parse('https://upload.twitter.com/1.1/media/upload.json');
        final authHeader = _generateOAuthHeader('POST', url, account);

        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = authHeader;
        request.files.add(
          http.MultipartFile.fromBytes(
            'media',
            bytes,
            filename: attachment.fileName,
          ),
        );

        print('X: Uploading media (${bytes.length} bytes)...');
        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        print('X: Media upload response: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final result = jsonDecode(response.body);
          final mediaId = result['media_id_string'] as String;
          print('X: Media uploaded successfully with ID: $mediaId');
          return mediaId;
        } else {
          print('X: Media upload failed: ${response.statusCode} - ${response.body}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('Error uploading media: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<bool> validateConnection(Account account) async {
    // For testing purposes, just check if we have the required credentials
    return hasRequiredCredentials(account);
  }
}
