// lib/services/chat_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_conversation_summary_model.dart';
import '../models/chat_message_model.dart';
import 'auth_service.dart';

class ChatService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static String get _socketBaseUrl {
    if (kIsWeb) {
      return 'ws://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'ws://127.0.0.1:8000';
      default:
        return 'ws://127.0.0.1:8000';
    }
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<WebSocketChannel> connectToChatSocket({
    required int chatId,
  }) async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ChatServiceException('No active session found.');
    }

    final encodedToken = Uri.encodeComponent(token);
    final socketUri = Uri.parse(
      '$_socketBaseUrl/ws/chats/$chatId/?token=$encodedToken',
    );

    _log('Connecting socket: $socketUri');

    return WebSocketChannel.connect(socketUri);
  }

  /// Matches Django `routing.websocket_urlpatterns` entry `ws/chats/inbox/`.
  /// Receives `presence_update`, `chat_list_updated`, etc. ([UserChatsConsumer]).
  static Future<WebSocketChannel> connectToUserChatsInboxSocket() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ChatServiceException('No active session found.');
    }

    final encodedToken = Uri.encodeComponent(token);
    final socketUri = Uri.parse(
      '$_socketBaseUrl/ws/chats/inbox/?token=$encodedToken',
    );

    _log('Connecting user chats inbox socket: $socketUri');

    return WebSocketChannel.connect(socketUri);
  }

  static void sendSocketMessage({
    required WebSocketChannel channel,
    required String content,
  }) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) return;

    channel.sink.add(
      jsonEncode({
        'content': trimmedContent,
      }),
    );
  }

  static void _log(String message) {
    debugPrint('[CHAT_SERVICE] $message');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    final storedRole = await AuthService.getStoredRole();
    final storedUserId = await AuthService.getStoredUserId();

    _log('Stored user id: $storedUserId');
    _log('Stored role: $storedRole');
    _log('Has token: ${token != null && token.isNotEmpty}');

    if (token != null && token.isNotEmpty) {
      final tokenPreview = token.length > 25 ? token.substring(0, 25) : token;
      _log('Token preview: $tokenPreview...');
    }

    if (token == null || token.isEmpty) {
      throw const ChatServiceException('No active session found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<ChatListResponse> getCurrentUserChats() async {
    _log('================ CHAT DEBUG START ================');
    _log('Base URL: $_baseUrl');
    _log('Chat list URL: ${_uri('/api/chats/list/')}');

    final decoded = await _getJson(
      path: '/api/chats/list/',
      expectedStatusCode: 200,
    );

    _log('Decoded chats response type: ${decoded.runtimeType}');
    _log('Decoded chats response: $decoded');

    if (decoded is! Map<String, dynamic>) {
      _log('ERROR: Invalid chats response from server.');
      throw const ChatServiceException('Invalid chats response from server.');
    }

    final response = ChatListResponse.fromJson(decoded);

    _log('Parsed currentUserRole: ${response.currentUserRole}');
    _log('Parsed count: ${response.count}');
    _log('Parsed chats length: ${response.chats.length}');

    for (final chat in response.chats) {
      _log(
        'Parsed chat => id: ${chat.id}, '
        'status: ${chat.status}, '
        'otherUser: ${chat.displayName}, '
        'offer: ${chat.offerTitle}, '
        'unread: ${chat.unreadCount}',
      );
    }

    _log('================ CHAT DEBUG END ==================');

    return response;
  }

  static Future<ChatConversationSummaryModel> getChatById({
    required int chatId,
  }) async {
    _log('================ GET CHAT BY ID DEBUG START ================');
    _log('Chat ID: $chatId');
    _log('Chat detail URL: ${_uri('/api/chats/$chatId/')}');

    final decoded = await _getJson(
      path: '/api/chats/$chatId/',
      expectedStatusCode: 200,
    );

    _log('Decoded chat detail type: ${decoded.runtimeType}');
    _log('Decoded chat detail response: $decoded');

    if (decoded is! Map<String, dynamic>) {
      _log('ERROR: Invalid chat response from server.');
      throw const ChatServiceException('Invalid chat response from server.');
    }

    final chat = ChatConversationSummaryModel.fromJson(decoded);

    _log(
      'Parsed chat detail => id: ${chat.id}, '
      'otherUser: ${chat.displayName}, '
      'offer: ${chat.offerTitle}',
    );

    _log('================ GET CHAT BY ID DEBUG END ==================');

    return chat;
  }

  static Future<List<ChatMessageModel>> getMessages({
    required ChatConversationSummaryModel chat,
  }) async {
    _log('================ GET MESSAGES DEBUG START ================');
    _log('Chat ID: ${chat.id}');
    _log('Messages URL: ${_uri('/api/chats/${chat.id}/messages/')}');
    _log('Client ID: ${chat.client?.id}');
    _log('Agent ID: ${chat.agent?.id}');

    final decoded = await _getJson(
      path: '/api/chats/${chat.id}/messages/',
      expectedStatusCode: 200,
    );

    _log('Decoded messages type: ${decoded.runtimeType}');
    _log('Decoded messages response: $decoded');

    if (decoded is! List) {
      _log('ERROR: Invalid messages response from server.');
      throw const ChatServiceException('Invalid messages response from server.');
    }

    final clientId = chat.client?.id ?? 0;
    final agentId = chat.agent?.id ?? 0;

    final messages = decoded
        .whereType<Map>()
        .map(
          (item) => ChatMessageModel.fromJson(
            json: Map<String, dynamic>.from(item),
            clientId: clientId,
            agentId: agentId,
          ),
        )
        .toList();

    _log('Parsed messages length: ${messages.length}');

    for (final message in messages) {
      _log(
        'Message => id: ${message.id}, '
        'senderId: ${message.senderId}, '
        'sender: ${message.sender.name}, '
        'text: ${message.text}, '
        'isRead: ${message.isRead}',
      );
    }

    _log('================ GET MESSAGES DEBUG END ==================');

    return messages;
  }

  static Future<ChatMessagesPage> getMessagesPage({
    required ChatConversationSummaryModel chat,
    int limit = 10,
    int? beforeMessageId,
  }) async {
    final queryParameters = <String, String>{
      'limit': '$limit',
    };

    if (beforeMessageId != null) {
      queryParameters['before'] = '$beforeMessageId';
    }

    final path = Uri(
      path: '/api/chats/${chat.id}/messages/',
      queryParameters: queryParameters,
    ).toString();

    _log('================ GET MESSAGES PAGE DEBUG START ================');
    _log('Chat ID: ${chat.id}');
    _log('Messages page path: $path');
    _log('Client ID: ${chat.client?.id}');
    _log('Agent ID: ${chat.agent?.id}');
    _log('Limit: $limit');
    _log('Before message ID: $beforeMessageId');

    final decoded = await _getJson(
      path: path,
      expectedStatusCode: 200,
    );

    _log('Decoded messages page type: ${decoded.runtimeType}');
    _log('Decoded messages page response: $decoded');

    if (decoded is! Map<String, dynamic>) {
      _log('ERROR: Invalid paginated messages response from server.');
      throw const ChatServiceException(
        'Invalid messages response from server.',
      );
    }

    final rawMessages = decoded['results'];

    final clientId = chat.client?.id ?? 0;
    final agentId = chat.agent?.id ?? 0;

    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map(
              (item) => ChatMessageModel.fromJson(
                json: Map<String, dynamic>.from(item),
                clientId: clientId,
                agentId: agentId,
              ),
            )
            .toList()
        : <ChatMessageModel>[];

    final page = ChatMessagesPage(
      messages: messages,
      hasMore: _parseBool(decoded['hasMore']) ?? false,
      nextBefore: _parseInt(decoded['nextBefore']),
    );

    _log(
      'Parsed messages page => length: ${page.messages.length}, '
      'hasMore: ${page.hasMore}, '
      'nextBefore: ${page.nextBefore}',
    );

    _log('================ GET MESSAGES PAGE DEBUG END ==================');

    return page;
  }

  static Future<ChatMessageModel> sendMessage({
    required ChatConversationSummaryModel chat,
    required String content,
  }) async {
    final trimmedContent = content.trim();

    _log('================ SEND MESSAGE DEBUG START ================');
    _log('Chat ID: ${chat.id}');
    _log('Send message URL: ${_uri('/api/chats/${chat.id}/messages/create/')}');
    _log('Message content: $trimmedContent');

    if (trimmedContent.isEmpty) {
      _log('ERROR: Message is empty.');
      throw const ChatServiceException('Message cannot be empty.');
    }

    final decoded = await _postJson(
      path: '/api/chats/${chat.id}/messages/create/',
      payload: {
        'content': trimmedContent,
      },
      expectedStatusCode: 201,
    );

    _log('Decoded send message type: ${decoded.runtimeType}');
    _log('Decoded send message response: $decoded');

    if (decoded is! Map<String, dynamic>) {
      _log('ERROR: Invalid message response from server.');
      throw const ChatServiceException('Invalid message response from server.');
    }

    final message = ChatMessageModel.fromJson(
      json: decoded,
      clientId: chat.client?.id ?? 0,
      agentId: chat.agent?.id ?? 0,
    );

    _log(
      'Parsed sent message => id: ${message.id}, '
      'senderId: ${message.senderId}, '
      'text: ${message.text}',
    );

    _log('================ SEND MESSAGE DEBUG END ==================');

    return message;
  }

  static Future<ChatMessageModel> updateMessage({
    required ChatConversationSummaryModel chat,
    required int messageId,
    required String content,
  }) async {
    final trimmedContent = content.trim();

    _log('================ UPDATE MESSAGE DEBUG START ================');
    _log('Chat ID: ${chat.id}');
    _log('Message ID: $messageId');
    _log(
      'Update message URL: ${_uri('/api/chats/${chat.id}/messages/$messageId/update/')}',
    );
    _log('Updated content: $trimmedContent');

    if (trimmedContent.isEmpty) {
      _log('ERROR: Message is empty.');
      throw const ChatServiceException('Message cannot be empty.');
    }

    final decoded = await _patchJson(
      path: '/api/chats/${chat.id}/messages/$messageId/update/',
      payload: {
        'content': trimmedContent,
      },
      expectedStatusCode: 200,
    );

    _log('Decoded update message type: ${decoded.runtimeType}');
    _log('Decoded update message response: $decoded');

    if (decoded is! Map<String, dynamic>) {
      _log('ERROR: Invalid updated message response from server.');
      throw const ChatServiceException(
        'Invalid updated message response from server.',
      );
    }

    final message = ChatMessageModel.fromJson(
      json: decoded,
      clientId: chat.client?.id ?? 0,
      agentId: chat.agent?.id ?? 0,
    );

    _log(
      'Parsed updated message => id: ${message.id}, '
      'senderId: ${message.senderId}, '
      'text: ${message.text}',
    );

    _log('================ UPDATE MESSAGE DEBUG END ==================');

    return message;
  }

  static Future<int> deleteMessage({
    required ChatConversationSummaryModel chat,
    required int messageId,
  }) async {
    _log('================ DELETE MESSAGE DEBUG START ================');
    _log('Chat ID: ${chat.id}');
    _log('Message ID: $messageId');
    _log(
      'Delete message URL: ${_uri('/api/chats/${chat.id}/messages/$messageId/delete/')}',
    );

    final decoded = await _deleteJson(
      path: '/api/chats/${chat.id}/messages/$messageId/delete/',
      expectedStatusCode: 200,
    );

    _log('Decoded delete message response: $decoded');

    final deletedMessageId = decoded is Map<String, dynamic>
        ? (_parseInt(decoded['deletedMessageId']) ?? messageId)
        : messageId;

    _log('Parsed deleted message id: $deletedMessageId');
    _log('================ DELETE MESSAGE DEBUG END ==================');

    return deletedMessageId;
  }

  static Future<void> deleteChat({
    required int chatId,
  }) async {
    _log('================ DELETE CHAT DEBUG START ================');
    _log('Chat ID: $chatId');

    final candidates = [
      '/api/chats/$chatId/delete/',
      '/api/chats/$chatId/',
    ];

    Object? lastError;

    for (final path in candidates) {
      for (final statusCode in [200, 204]) {
        try {
          _log('Trying DELETE $path (expect $statusCode)');
          await _deleteJson(
            path: path,
            expectedStatusCode: statusCode,
          );
          _log('================ DELETE CHAT DEBUG END ==================');
          return;
        } catch (e) {
          lastError = e;
          _log('DELETE failed for $path ($statusCode): $e');
        }
      }
    }

    _log('================ DELETE CHAT DEBUG END ==================');

    if (lastError is ChatServiceException) {
      throw lastError;
    }

    throw const ChatServiceException('Unable to delete conversation.');
  }

  /// Closes the offer linked to this chat (`POST` or `PATCH` `/api/chats/{id}/close/`).
  static Future<void> closeChatOffer({
    required int chatId,
  }) async {
    _log('================ CLOSE CHAT OFFER DEBUG START ================');
    _log('Chat ID: $chatId');

    final path = '/api/chats/$chatId/close/';
    final statusCodes = [200, 201, 204];
    Object? lastError;

    for (final statusCode in statusCodes) {
      try {
        _log('Trying POST $path (expect $statusCode)');
        await _postJson(
          path: path,
          payload: const {},
          expectedStatusCode: statusCode,
        );
        _log('================ CLOSE CHAT OFFER DEBUG END ==================');
        return;
      } catch (e) {
        lastError = e;
        _log('POST failed for $path ($statusCode): $e');
      }
    }

    for (final statusCode in statusCodes) {
      try {
        _log('Trying PATCH $path (expect $statusCode)');
        await _patchJson(
          path: path,
          payload: const {},
          expectedStatusCode: statusCode,
        );
        _log('================ CLOSE CHAT OFFER DEBUG END ==================');
        return;
      } catch (e) {
        lastError = e;
        _log('PATCH failed for $path ($statusCode): $e');
      }
    }

    _log('================ CLOSE CHAT OFFER DEBUG END ==================');

    if (lastError is ChatServiceException) {
      throw lastError;
    }

    throw const ChatServiceException('Unable to close offer.');
  }

  static Future<void> markAllMessagesAsRead({
    required int chatId,
  }) async {
    _log('================ MARK READ DEBUG START ================');
    _log('Chat ID: $chatId');
    _log('Mark read URL: ${_uri('/api/chats/$chatId/messages/read-all/')}');

    final decoded = await _patchJson(
      path: '/api/chats/$chatId/messages/read-all/',
      payload: {},
      expectedStatusCode: 200,
    );

    _log('Decoded mark read response: $decoded');
    _log('================ MARK READ DEBUG END ==================');
  }

  static Future<dynamic> _getJson({
    required String path,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      _log('GET request: $uri');
      _log('GET expected status: $expectedStatusCode');
      _log('GET has Authorization: ${headers.containsKey('Authorization')}');

      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      _log('GET status code: ${response.statusCode}');
      _log('GET response body: ${response.body}');

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      final errorMessage = _extractErrorMessage(decoded);
      _log('GET ERROR message: $errorMessage');

      throw ChatServiceException(errorMessage);
    } on TimeoutException {
      _log('GET ERROR: timeout');
      throw const ChatServiceException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      _log('GET HTTP CLIENT ERROR: $e');
      throw const ChatServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      _log('GET UNKNOWN ERROR: $e');

      if (e is ChatServiceException) rethrow;

      throw const ChatServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Future<dynamic> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      _log('POST request: $uri');
      _log('POST expected status: $expectedStatusCode');
      _log('POST payload: $payload');
      _log('POST has Authorization: ${headers.containsKey('Authorization')}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      _log('POST status code: ${response.statusCode}');
      _log('POST response body: ${response.body}');

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      final errorMessage = _extractErrorMessage(decoded);
      _log('POST ERROR message: $errorMessage');

      throw ChatServiceException(errorMessage);
    } on TimeoutException {
      _log('POST ERROR: timeout');
      throw const ChatServiceException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      _log('POST HTTP CLIENT ERROR: $e');
      throw const ChatServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      _log('POST UNKNOWN ERROR: $e');

      if (e is ChatServiceException) rethrow;

      throw const ChatServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Future<dynamic> _patchJson({
    required String path,
    required Map<String, dynamic> payload,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      _log('PATCH request: $uri');
      _log('PATCH expected status: $expectedStatusCode');
      _log('PATCH payload: $payload');
      _log('PATCH has Authorization: ${headers.containsKey('Authorization')}');

      final response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      _log('PATCH status code: ${response.statusCode}');
      _log('PATCH response body: ${response.body}');

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      final errorMessage = _extractErrorMessage(decoded);
      _log('PATCH ERROR message: $errorMessage');

      throw ChatServiceException(errorMessage);
    } on TimeoutException {
      _log('PATCH ERROR: timeout');
      throw const ChatServiceException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      _log('PATCH HTTP CLIENT ERROR: $e');
      throw const ChatServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      _log('PATCH UNKNOWN ERROR: $e');

      if (e is ChatServiceException) rethrow;

      throw const ChatServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Future<dynamic> _deleteJson({
    required String path,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      _log('DELETE request: $uri');
      _log('DELETE expected status: $expectedStatusCode');
      _log('DELETE has Authorization: ${headers.containsKey('Authorization')}');

      final response = await http
          .delete(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      _log('DELETE status code: ${response.statusCode}');
      _log('DELETE response body: ${response.body}');

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      final errorMessage = _extractErrorMessage(decoded);
      _log('DELETE ERROR message: $errorMessage');

      throw ChatServiceException(errorMessage);
    } on TimeoutException {
      _log('DELETE ERROR: timeout');
      throw const ChatServiceException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      _log('DELETE HTTP CLIENT ERROR: $e');
      throw const ChatServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      _log('DELETE UNKNOWN ERROR: $e');

      if (e is ChatServiceException) rethrow;

      throw const ChatServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      _log('Response body is empty.');
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      _log('JSON decode error: $e');
      return null;
    }
  }

  static String _extractErrorMessage(dynamic body) {
    if (body == null) {
      return 'Something went wrong. Please try again.';
    }

    if (body is String && body.trim().isNotEmpty) {
      return body;
    }

    if (body is Map<String, dynamic>) {
      if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
        return body['error'].toString();
      }

      if (body['detail'] != null &&
          body['detail'].toString().trim().isNotEmpty) {
        return body['detail'].toString();
      }

      if (body['message'] != null &&
          body['message'].toString().trim().isNotEmpty) {
        return body['message'].toString();
      }

      for (final value in body.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

class ChatMessagesPage {
  final List<ChatMessageModel> messages;
  final bool hasMore;
  final int? nextBefore;

  const ChatMessagesPage({
    required this.messages,
    required this.hasMore,
    required this.nextBefore,
  });
}

class ChatServiceException implements Exception {
  final String message;

  const ChatServiceException(this.message);

  @override
  String toString() => message;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final normalized = value.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return null;
}