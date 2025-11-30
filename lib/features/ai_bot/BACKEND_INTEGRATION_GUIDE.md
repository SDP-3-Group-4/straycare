# Chat System Backend Integration Guide

## Quick Start

### Step 1: Prepare Your Backend API

Your backend should provide these endpoints:

#### Authentication
```
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh-token
```

#### Chats
```
GET    /api/v1/chats                          → Get all chats for user
GET    /api/v1/chats/:chatId                  → Get specific chat
POST   /api/v1/chats                          → Create new chat
DELETE /api/v1/chats/:chatId                  → Delete chat
PATCH  /api/v1/chats/:chatId/read             → Mark as read
```

#### Messages
```
GET    /api/v1/chats/:chatId/messages         → Get all messages in chat
POST   /api/v1/chats/:chatId/messages         → Send message
PATCH  /api/v1/messages/:messageId            → Edit message
DELETE /api/v1/messages/:messageId            → Delete message
```

#### AI Vet Bot
```
POST   /api/v1/ai/vet-bot/response           → Get AI bot response
GET    /api/v1/ai/vet-bot/info               → Get AI bot info
```

---

### Step 2: Data Model Requirements

Your backend should return data in this format:

#### Chat Response
```json
{
  "id": "chat_123",
  "name": "Sarah Anderson",
  "profileImageUrl": "https://example.com/profile.jpg",
  "lastMessage": "Hey! How is your puppy?",
  "lastMessageTime": "2024-11-16T10:30:00Z",
  "isAiBot": false,
  "tag": null,
  "unreadCount": 2
}
```

#### Message Response
```json
{
  "id": "msg_456",
  "chatId": "chat_123",
  "senderId": "user_789",
  "content": "Hello! How can I help?",
  "timestamp": "2024-11-16T10:30:00Z",
  "isUserMessage": false,
  "status": "delivered"
}
```

#### AI Vet Bot Response
```json
{
  "id": "msg_789",
  "chatId": "ai_vet_bot_001",
  "senderId": "ai_vet_bot_001",
  "content": "Chocolate can be toxic to dogs...",
  "timestamp": "2024-11-16T10:31:00Z",
  "isUserMessage": false,
  "status": "sent"
}
```

---

### Step 3: Update Flutter App

#### 3.1 Create Configuration File

Create `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String devBaseUrl = 'http://localhost:3000';
  static const String stagingBaseUrl = 'https://staging-api.straycare.com';
  static const String prodBaseUrl = 'https://api.straycare.com';

  static String get baseUrl {
    // You can use const kDebugMode to determine environment
    const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
    
    switch (environment) {
      case 'staging':
        return stagingBaseUrl;
      case 'prod':
        return prodBaseUrl;
      default:
        return devBaseUrl;
    }
  }

  // API Endpoints
  static String get chatsEndpoint => '$baseUrl/api/v1/chats';
  static String messagesEndpoint(String chatId) => '$baseUrl/api/v1/chats/$chatId/messages';
  static String get aiVetBotEndpoint => '$baseUrl/api/v1/ai/vet-bot';
}
```

#### 3.2 Create AuthService (if not exists)

Create `lib/services/auth_service.dart` (or update existing):

```dart
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  Future<String?> getToken() async {
    // Implementation to retrieve stored token
    // For example, using shared_preferences
  }
  
  Future<void> saveToken(String token, String refreshToken) async {
    // Implementation to save tokens
  }
  
  Future<void> clearToken() async {
    // Implementation to clear stored tokens
  }
}
```

#### 3.3 Create BackendChatService

Copy and uncomment the code from `backend_chat_service_example.dart` and save as `lib/features/ai_bot/services/backend_chat_service.dart`.

#### 3.4 Update ChatListScreen

In `lib/features/ai_bot/screens/chat_list_screen.dart`, update `initState()`:

```dart
@override
void initState() {
  super.initState();
  
  // Old (local):
  // _chatService = LocalChatService();
  
  // New (backend):
  _initializeChatService();
  _chatsFuture = _chatService.getAllChats();
}

void _initializeChatService() async {
  try {
    final authService = AuthService();
    final token = await authService.getToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    _chatService = BackendChatService(
      baseUrl: ApiConfig.baseUrl,
      authToken: token,
    );
  } catch (e) {
    debugPrint('Error initializing chat service: $e');
    // Fallback to local service or show error
    _chatService = LocalChatService();
  }
}
```

#### 3.5 Update pubspec.yaml

Add required dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  http: ^1.1.0
  shared_preferences: ^2.2.0
  # Optional: for better HTTP client management
  dio: ^5.3.0
  # Optional: for WebSocket support (real-time)
  web_socket_channel: ^2.4.0
```

Run: `flutter pub get`

---

### Step 4: Handle Authentication

#### 4.1 Token Management

Create `lib/services/token_manager.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  static final TokenManager _instance = TokenManager._internal();
  
  factory TokenManager() {
    return _instance;
  }
  
  TokenManager._internal();
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }
  
  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
  
  bool get isTokenValid {
    final token = accessToken;
    if (token == null) return false;
    
    // Decode JWT and check expiration
    // This is a simplified check
    return true;
  }
}
```

#### 4.2 Refresh Token Interceptor

```dart
class BackendChatServiceWithRefresh extends BackendChatService {
  final AuthService authService;
  
  BackendChatServiceWithRefresh({
    required String baseUrl,
    required String authToken,
    required this.authService,
  }) : super(baseUrl: baseUrl, authToken: authToken);
  
  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(String) onSuccess,
  ) async {
    if (response.statusCode == 401) {
      // Token expired, try to refresh
      final newToken = await authService.refreshToken();
      if (newToken != null) {
        // Retry request with new token
        // This is a simplified example
      }
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return onSuccess(response.body);
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }
}
```

---

### Step 5: Error Handling

Update `chat_list_screen.dart` to handle errors gracefully:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    body: FutureBuilder<List<Chat>>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                const Text('Error loading messages'),
                const SizedBox(height: 8),
                Text(snapshot.error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshChats,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // ... rest of build
      },
    ),
  );
}
```

---

### Step 6: Implement Real-Time Messaging (Optional)

For real-time updates, use WebSockets:

```dart
class RealtimeChatService extends BackendChatService {
  late WebSocketChannel _webSocket;
  final StreamController<Message> onNewMessage = StreamController.broadcast();
  
  Future<void> connectWebSocket(String chatId) async {
    try {
      _webSocket = WebSocketChannel.connect(
        Uri.parse('wss://${Uri.parse(baseUrl).host}/ws/chats/$chatId?token=$authToken'),
      );
      
      _webSocket.stream.listen(
        (dynamic data) {
          try {
            final message = Message.fromJson(jsonDecode(data));
            onNewMessage.add(message);
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) => debugPrint('WebSocket error: $error'),
        onDone: () => debugPrint('WebSocket connection closed'),
      );
    } catch (e) {
      debugPrint('Error connecting WebSocket: $e');
    }
  }
  
  void closeWebSocket() {
    _webSocket.sink.close();
  }
}
```

Update `chat_detail_screen.dart` to listen to new messages:

```dart
@override
void initState() {
  super.initState();
  _chatService = LocalChatService();
  _messageController = TextEditingController();
  _messagesFuture = _chatService.getMessagesForChat(widget.chat.id);
  
  // Connect to WebSocket for real-time updates
  if (_chatService is RealtimeChatService) {
    final realtimeService = _chatService as RealtimeChatService;
    realtimeService.connectWebSocket(widget.chat.id);
    
    realtimeService.onNewMessage.stream.listen((message) {
      setState(() {
        _messagesFuture = _chatService.getMessagesForChat(widget.chat.id);
      });
    });
  }
}

@override
void dispose() {
  if (_chatService is RealtimeChatService) {
    (_chatService as RealtimeChatService).closeWebSocket();
  }
  _messageController.dispose();
  _scrollController.dispose();
  super.dispose();
}
```

---

### Step 7: Testing

Create `test/services/backend_chat_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

void main() {
  group('BackendChatService', () {
    late MockHttpClient mockHttpClient;
    late BackendChatService chatService;
    
    setUp(() {
      mockHttpClient = MockHttpClient();
      chatService = BackendChatService(
        baseUrl: 'https://test.com',
        authToken: 'test_token',
        httpClient: mockHttpClient,
      );
    });
    
    test('getAllChats returns list of chats', () async {
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('[{"id":"1","name":"Test"}]', 200));
      
      final chats = await chatService.getAllChats();
      
      expect(chats.length, 1);
      expect(chats[0].name, 'Test');
    });
    
    test('sendMessage sends message to backend', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"id":"msg1","content":"Hello","senderId":"user1"}',
        201,
      ));
      
      final message = await chatService.sendMessage('chat1', 'Hello');
      
      expect(message.content, 'Hello');
    });
  });
}
```

---

### Step 8: Deployment Considerations

#### Environment Variables
```bash
# For development
flutter run --dart-define=ENV=dev

# For staging
flutter run --dart-define=ENV=staging

# For production (release build)
flutter build apk --dart-define=ENV=prod
```

#### Secure Token Storage
- Use `flutter_secure_storage` for sensitive tokens (not SharedPreferences)
- Never log tokens to console in production
- Implement token rotation

#### Performance
- Implement pagination for chat list
- Cache messages locally (use Hive or SQLite)
- Debounce search queries
- Use ConnectionPool for HTTP

#### Monitoring
- Add error tracking (Sentry, Crashlytics)
- Log API performance metrics
- Monitor WebSocket connection stability

---

## Troubleshooting

### Common Issues

**1. 401 Unauthorized**
- Token expired or invalid
- Solution: Implement token refresh logic

**2. Network timeout**
- Backend is slow or unreachable
- Solution: Increase timeout, implement retry logic

**3. Message not appearing in real-time**
- WebSocket not connected properly
- Solution: Check WebSocket URL and token

**4. Memory leaks**
- Not disposing WebSocket connections
- Solution: Always dispose streams in `dispose()`

---

## Rollback Plan

If you need to temporarily fall back to local data:

```dart
void _initializeChatService() async {
  try {
    final token = await authService.getToken();
    _chatService = BackendChatService(
      baseUrl: ApiConfig.baseUrl,
      authToken: token!,
    );
  } catch (e) {
    debugPrint('Failed to initialize backend service: $e');
    // Fallback to local data
    _chatService = LocalChatService();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using offline mode')),
    );
  }
}
```

---

## Support & Next Steps

1. **Implement backend endpoints** following the specification above
2. **Test locally** with mock data using `MockHttpClient`
3. **Deploy backend** to staging environment
4. **Update Flutter app** with staging API URLs
5. **Run integration tests** against staging
6. **Deploy to production** with environment variables

For questions or issues, refer to:
- `CHAT_SYSTEM_GUIDE.md` - Architecture overview
- `backend_chat_service_example.dart` - Implementation example
- Flutter HTTP documentation - `https://flutter.dev/docs/cookbook/networking/fetch-data`
