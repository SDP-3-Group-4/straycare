// EXAMPLE BACKEND INTEGRATION
// This file demonstrates how to integrate with a backend API
// Uncomment and customize this when you have your backend ready

/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';

class BackendChatService implements ChatService {
  final String baseUrl;
  final String authToken;
  final http.Client httpClient;

  BackendChatService({
    required this.baseUrl,
    required this.authToken,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken',
  };

  @override
  Future<List<Chat>> getAllChats() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/v1/chats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => Chat.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesForChat(String chatId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/api/v1/chats/$chatId/messages'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  @override
  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/chats/$chatId/messages'),
        headers: _headers,
        body: jsonEncode({
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return Message.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  @override
  Future<Chat> createChat(String name, String profileImageUrl) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/chats'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'profileImageUrl': profileImageUrl,
        }),
      );

      if (response.statusCode == 201) {
        return Chat.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    try {
      final response = await httpClient.patch(
        Uri.parse('$baseUrl/api/v1/chats/$chatId/read'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark chat as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking chat as read: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/api/v1/chats/$chatId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting chat: $e');
    }
  }

  /// Additional method for AI Vet Bot response
  /// Add this to the ChatService abstract class when implementing
  Future<Message> generateAiBotResponse(
    String chatId,
    String userMessage,
  ) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/api/v1/ai/vet-bot/response'),
        headers: _headers,
        body: jsonEncode({
          'chatId': chatId,
          'userMessage': userMessage,
        }),
      );

      if (response.statusCode == 200) {
        return Message.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting AI response: $e');
    }
  }
}

// USAGE IN chat_list_screen.dart:
// 
// Replace this line in initState():
//   _chatService = LocalChatService();
// 
// With:
//   final authToken = await getAuthTokenFromStorage(); // Your implementation
//   _chatService = BackendChatService(
//     baseUrl: 'https://your-backend.com',
//     authToken: authToken,
//   );
//

// ENVIRONMENT-SPECIFIC CONFIGURATION:
//
// Create a constants file:
// lib/config/api_config.dart
//
// class ApiConfig {
//   static const String devBaseUrl = 'http://localhost:3000';
//   static const String prodBaseUrl = 'https://api.straycare.com';
//   
//   static String get baseUrl {
//     // Use kDebugMode from flutter/foundation to determine environment
//     return const bool.fromEnvironment('dart.vm.product')
//         ? prodBaseUrl
//         : devBaseUrl;
//   }
// }
//
// Then use: BackendChatService(baseUrl: ApiConfig.baseUrl, authToken: token)
//

// ERROR HANDLING & RETRY LOGIC:
//
// class BackendChatServiceWithRetry extends BackendChatService {
//   static const maxRetries = 3;
//   static const retryDelay = Duration(seconds: 2);
//   
//   Future<T> _retryOnFailure<T>(Future<T> Function() operation) async {
//     int retries = 0;
//     while (retries < maxRetries) {
//       try {
//         return await operation();
//       } catch (e) {
//         retries++;
//         if (retries >= maxRetries) rethrow;
//         await Future.delayed(retryDelay * retries);
//       }
//     }
//     throw Exception('Max retries exceeded');
//   }
//   
//   @override
//   Future<List<Chat>> getAllChats() async {
//     return _retryOnFailure(() => super.getAllChats());
//   }
// }
//

// WEBSOCKET FOR REAL-TIME MESSAGING:
//
// import 'package:web_socket_channel/web_socket_channel.dart';
//
// class RealtimeChatService extends BackendChatService {
//   late WebSocketChannel _webSocket;
//   final StreamController<Message> messageStream =
//       StreamController<Message>.broadcast();
//   
//   void connectWebSocket(String chatId) {
//     _webSocket = WebSocketChannel.connect(
//       Uri.parse('wss://your-backend.com/ws/chats/$chatId'),
//     );
//     
//     _webSocket.stream.listen(
//       (message) {
//         final msg = Message.fromJson(jsonDecode(message));
//         messageStream.add(msg);
//       },
//       onError: (error) => print('WebSocket error: $error'),
//       onDone: () => print('WebSocket closed'),
//     );
//   }
//   
//   void closeWebSocket() {
//     _webSocket.sink.close();
//     messageStream.close();
//   }
// }
//

*/
