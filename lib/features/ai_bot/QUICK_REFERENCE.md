# Chat System - Quick Reference Guide

## 📋 Quick Links

| Document | Purpose |
|----------|---------|
| `README.md` | Overview and user guide |
| `CHAT_SYSTEM_GUIDE.md` | Architecture & technical details |
| `BACKEND_INTEGRATION_GUIDE.md` | Step-by-step backend integration |
| `backend_chat_service_example.dart` | Example implementation (commented) |

---

## 🚀 Quick Start

### Run Current Demo
```bash
cd f:\SW_Development\straycare_demo
flutter run
# Navigate to Messages tab
```

### Switch to Backend (When Ready)

1. **Prepare Backend Endpoints**
   ```
   GET    /api/v1/chats
   POST   /api/v1/chats/{chatId}/messages
   ```

2. **Create Backend Service**
   ```dart
   class BackendChatService implements ChatService {
     Future<List<Chat>> getAllChats() async {
       // HTTP call to backend
     }
   }
   ```

3. **Update Chat List Screen**
   ```dart
   _chatService = BackendChatService(
     baseUrl: 'your-backend-url',
     authToken: userToken,
   );
   ```

---

## 📁 Project Structure

```
ai_bot/
├── models/
│   └── chat_model.dart              ← Data models
├── services/
│   ├── chat_service.dart            ← Service interface & local impl
│   └── backend_chat_service_example.dart  ← Backend example
├── screens/
│   ├── chat_list_screen.dart        ← Messages tab home
│   └── chat_detail_screen.dart      ← Individual chat
├── README.md                         ← Start here
├── CHAT_SYSTEM_GUIDE.md             ← Architecture details
└── BACKEND_INTEGRATION_GUIDE.md     ← Backend setup
```

---

## 🔑 Key Classes

### ChatService (Interface)
```dart
abstract class ChatService {
  Future<List<Chat>> getAllChats();
  Future<List<Message>> getMessagesForChat(String chatId);
  Future<Message> sendMessage(String chatId, String content);
  Future<Chat> createChat(String name, String profileImageUrl);
  Future<void> markChatAsRead(String chatId);
  Future<void> deleteChat(String chatId);
}
```

### Chat (Model)
```dart
Chat(
  id: 'unique_id',
  name: 'Display Name',
  profileImageUrl: 'url',
  lastMessage: 'Preview text',
  lastMessageTime: DateTime.now(),
  isAiBot: false,
  tag: null,
  unreadCount: 0,
)
```

### Message (Model)
```dart
Message(
  id: 'msg_id',
  chatId: 'chat_id',
  senderId: 'user_id',
  content: 'Message text',
  timestamp: DateTime.now(),
  isUserMessage: true,
  status: MessageStatus.sent,
)
```

---

## 🔄 Data Flow

### Chat List Screen
```
initState()
    ↓
_chatService.getAllChats()
    ↓
FutureBuilder → build UI
    ↓
tap chat → ChatDetailScreen
    ↓
on return → _refreshChats()
```

### Chat Detail Screen
```
initState()
    ↓
_chatService.getMessagesForChat(chatId)
    ↓
FutureBuilder → build message list
    ↓
user types message
    ↓
tap send → _sendMessage()
    ↓
_chatService.sendMessage(chatId, content)
    ↓
if AI Bot → auto-generate response
    ↓
refresh messages → auto-scroll to bottom
```

---

## 💾 Sample Data

### AI Vet Bot
```
ID: ai_vet_bot_001
Name: AI Vet Bot
Tag: Ask Vet Bot
Badge: ✓ Displayed
Status: Online
```

### Sample User
```
ID: user_001
Name: Sarah Anderson
Unread: 2
Last Message: "Did you take her to the vet?"
```

---

## 🛠️ Common Tasks

### Get All Chats
```dart
final chats = await _chatService.getAllChats();
```

### Send Message
```dart
final message = await _chatService.sendMessage(
  'chat_123',
  'Hello!',
);
```

### Mark Chat as Read
```dart
await _chatService.markChatAsRead('chat_123');
```

### Delete Chat
```dart
await _chatService.deleteChat('chat_123');
```

### Switch Service Implementation
```dart
// Local (demo)
_chatService = LocalChatService();

// Backend
_chatService = BackendChatService(
  baseUrl: 'https://api.example.com',
  authToken: 'user_token',
);
```

---

## 🌐 Backend Integration Steps

1. **Design Endpoints** (see BACKEND_INTEGRATION_GUIDE.md)
2. **Create BackendChatService** (see backend_chat_service_example.dart)
3. **Add Authentication** (TokenManager)
4. **Update Chat Screens** (change service initialization)
5. **Test** (mock API responses)
6. **Deploy** (staging → production)

---

## 📊 Message Status

```dart
enum MessageStatus {
  pending,    // Waiting to send
  sent,       // Sent to server
  delivered,  // Delivered to recipient
  read,       // Read by recipient
}
```

---

## ⚙️ Configuration

### API Base URL
```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://api.straycare.com';
```

### Auth Token
```dart
// Get from SharedPreferences or secure storage
final token = await prefs.getString('auth_token');
```

### Environment
```bash
# Development
flutter run --dart-define=ENV=dev

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter build apk --dart-define=ENV=prod
```

---

## 🧪 Testing

### Unit Tests
```bash
flutter test test/services/chat_service_test.dart
```

### Widget Tests
```bash
flutter test test/screens/chat_list_screen_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

---

## 🐛 Debugging

### Enable Debug Logging
```dart
debugPrint('Chat loaded: $chat');
```

### Check Service Status
```dart
print(_chatService.runtimeType); // LocalChatService or BackendChatService
```

### Monitor Network
```dart
// Android Studio → Logcat
// VS Code → Debug Console
```

---

## 📱 UI Components

### Chat List Item
- Profile picture with fallback initials
- AI bot badge if applicable
- Chat name and tag display
- Last message preview
- Unread badge
- Time indicator

### Message Bubble
- Align right for user messages
- Align left for other messages
- Different colors (purple/gray)
- Timestamp below message
- Status indicator

### Input Area
- Text field with placeholder
- Send button (enabled when text exists)
- Auto-focus on open
- Submit on Enter key

---

## 🚨 Error Handling

### Network Error
```dart
if (snapshot.hasError) {
  return ErrorWidget(error: snapshot.error);
}
```

### Empty State
```dart
if (chats.isEmpty) {
  return EmptyStateWidget();
}
```

### Auth Error
```dart
if (response.statusCode == 401) {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## 📈 Performance Tips

1. **Lazy Load**: Load messages as user scrolls
2. **Cache**: Store frequently accessed chats locally
3. **Debounce**: Delay search/typing updates
4. **Pagination**: Load 20 messages at a time
5. **Image Resize**: Compress profile pictures

---

## 🔐 Security

- [ ] Use HTTPS for all API calls
- [ ] Store tokens in secure storage
- [ ] Validate inputs server-side
- [ ] Implement rate limiting
- [ ] Use JWT with expiration
- [ ] Implement CORS properly

---

## 📞 Support

| Issue | Solution |
|-------|----------|
| Chat list not loading | Check network, auth token, API status |
| Messages not appearing | Verify chatId, timestamps, sender info |
| AI bot not responding | Check service enabled, message format |
| Can't send messages | Check token valid, network connected |
| Memory leak | Dispose streams in dispose() |

---

## 🔗 Related Files

- `lib/main.dart` - Integration point
- `lib/services/auth_service.dart` - Authentication (if exists)
- `pubspec.yaml` - Dependencies

---

## 📚 External Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart HTTP Package](https://pub.dev/packages/http)
- [Firebase Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [WebSocket Implementation](https://dart.dev/articles/libraries/using-streams)

---

**Last Updated**: November 16, 2024
**Version**: 1.0.0
**Status**: Ready for Backend Integration
