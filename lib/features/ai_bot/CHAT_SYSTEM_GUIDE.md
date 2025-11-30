# Chat Messaging System - Implementation Guide

## Overview

This document provides a comprehensive guide for the chat messaging system implementation in the StrayCare app. The system is designed with backend integration in mind and follows a service-oriented architecture.

## Architecture

### File Structure

```
lib/features/ai_bot/
├── models/
│   └── chat_model.dart          # Data models for Chat and Message
├── services/
│   └── chat_service.dart        # Service layer for chat operations
└── screens/
    ├── chat_list_screen.dart    # Chat list (messages tab home)
    └── chat_detail_screen.dart  # Individual chat screen
```

## Components

### 1. Data Models (`models/chat_model.dart`)

#### Chat Model
Represents a conversation with a user or AI bot.

```dart
Chat(
  id: String,                      // Unique chat identifier
  name: String,                    // Chat/Person name
  profileImageUrl: String,         // Profile picture URL
  lastMessage: String,             // Latest message preview
  lastMessageTime: DateTime,       // When last message was sent
  isAiBot: bool,                   // Whether this is an AI conversation
  tag: String?,                    // Optional tag (e.g., "Ask Vet Bot")
  unreadCount: int,                // Number of unread messages
)
```

**Backend Integration**: `toJson()` and `fromJson()` methods are built-in for easy serialization/deserialization.

#### Message Model
Represents individual messages in a chat.

```dart
Message(
  id: String,                      // Unique message identifier
  chatId: String,                  // Reference to the chat
  senderId: String,                // Who sent the message
  content: String,                 // Message text
  timestamp: DateTime,             // When it was sent
  isUserMessage: bool,             // Whether user or other party sent it
  status: MessageStatus,           // pending, sent, delivered, read
)
```

**Backend Integration**: Supports message status tracking for delivery acknowledgments.

### 2. Service Layer (`services/chat_service.dart`)

The `ChatService` is an abstract class defining the interface for all chat operations:

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

#### Current Implementation: LocalChatService

A local implementation that stores data in memory. It includes:
- Sample data initialization (AI Vet Bot + random user)
- In-memory persistence
- Simulated network delays

#### For Backend Integration

Create a new class implementing `ChatService`:

```dart
class BackendChatService implements ChatService {
  final String baseUrl = 'your-backend-url';
  
  @override
  Future<List<Chat>> getAllChats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    
    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => Chat.fromJson(json)).toList();
    }
    throw Exception('Failed to load chats');
  }
  
  // Implement other methods similarly...
}
```

Then switch in `chat_list_screen.dart`:

```dart
// Change from:
_chatService = LocalChatService();

// To:
_chatService = BackendChatService(authToken: currentUserToken);
```

### 3. Screens

#### Chat List Screen (`screens/chat_list_screen.dart`)

The main messaging tab showing all conversations.

**Features**:
- Lists all chats with most recent first
- Displays profile pictures with fallback initials
- Shows "Ask Vet Bot" tag for AI bot
- Unread message badges
- Long-press for delete options
- Add new chat button
- Pull-to-refresh support
- Empty state UI

**Data Flow**:
```
1. initState → _chatService.getAllChats()
2. FutureBuilder renders list
3. Tap chat → Navigate to ChatDetailScreen
4. After return → _refreshChats() updates list
```

#### Chat Detail Screen (`screens/chat_detail_screen.dart`)

Individual conversation view with message history and input.

**Features**:
- Displays all messages for a chat
- Auto-scrolls to latest message
- Sends user messages
- Auto-responses from AI Vet Bot with intelligent responses
- Message timestamps
- Read status indicators
- Works with both users and AI bot

**AI Response Generation**:
The `_generateAiResponse()` method provides demo responses. For backend integration, replace with actual API call:

```dart
// Current (demo):
String _generateAiResponse(String userMessage) {
  // Simple keyword matching
  if (userMessage.contains('chocolate')) {
    return 'Chocolate is toxic...';
  }
  // ...
}

// For backend:
Future<String> _generateAiResponse(String userMessage) async {
  final response = await _chatService.generateAiBotResponse(
    chatId: widget.chat.id,
    message: userMessage,
  );
  return response.content;
}
```

## Sample Data

The system initializes with:

1. **AI Vet Bot** (`ai_vet_bot_001`)
   - Name: "AI Vet Bot"
   - Tag: "Ask Vet Bot"
   - AI Badge displayed
   - Sample conversation about chocolate toxicity

2. **Random User** (`user_001`)
   - Name: "Sarah Anderson"
   - 2 Unread messages
   - Sample conversation about puppy care

## Integration Points for Backend

### 1. Authentication
The system needs the current user's authentication token:

```dart
// In chat_list_screen.dart or chat_detail_screen.dart
final authToken = await getAuthToken(); // Implement this
_chatService = BackendChatService(authToken: authToken);
```

### 2. Real-time Updates
For real-time messaging, consider integrating WebSockets:

```dart
class BackendChatService implements ChatService {
  late WebSocket _webSocket;
  
  void _connectWebSocket() {
    _webSocket = await WebSocket.connect('ws://your-backend/chat');
    _webSocket.listen(_handleWebSocketMessage);
  }
  
  void _handleWebSocketMessage(dynamic message) {
    // Handle incoming messages
    notifyListeners();
  }
}
```

### 3. File Uploads (Future)
For images/media in messages:

```dart
Future<Message> sendMessageWithMedia(
  String chatId,
  String content,
  File? mediaFile,
) async {
  // Upload media first, get URL
  final mediaUrl = await uploadToStorage(mediaFile);
  
  // Send message with media URL
  return sendMessage(chatId, '$content\n$mediaUrl');
}
```

### 4. Typing Indicators
Implement presence/typing status:

```dart
Future<void> setTypingStatus(String chatId, bool isTyping) async {
  await http.post(
    Uri.parse('$baseUrl/chats/$chatId/typing'),
    body: jsonEncode({'isTyping': isTyping}),
  );
}
```

## Usage in Main App

The `ChatListScreen` is integrated as the Messages tab in the bottom navigation:

```dart
// In main.dart
final List<Widget> _screens = [
  const HomeScreen(),
  const MarketplaceScreen(),
  const ChatListScreen(),  // ← Messages tab
  const ProfileScreen(),
];

BottomNavigationBar(
  // ...
  BottomNavigationBarItem(
    icon: Icon(Icons.chat_bubble_outline),
    activeIcon: Icon(Icons.chat_bubble),
    label: 'Messages',  // ← This tab
  ),
)
```

## Testing

### Test LocalChatService
```dart
void main() {
  test('LocalChatService loads sample chats', () async {
    final service = LocalChatService();
    final chats = await service.getAllChats();
    
    expect(chats.length, greaterThanOrEqualTo(2));
    expect(chats.any((c) => c.isAiBot), true);
  });
}
```

### Test ChatDetailScreen
```dart
testWidgets('ChatDetailScreen sends message', (WidgetTester tester) async {
  final chat = Chat(
    id: 'test_chat',
    name: 'Test',
    profileImageUrl: 'url',
    lastMessage: 'Hi',
    lastMessageTime: DateTime.now(),
  );
  
  await tester.pumpWidget(
    MaterialApp(home: ChatDetailScreen(chat: chat)),
  );
  
  await tester.enterText(find.byType(TextField), 'Hello');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
  
  expect(find.text('Hello'), findsOneWidget);
});
```

## Future Enhancements

1. **Group Chats**: Extend Chat model to support multiple participants
2. **Message Search**: Add search functionality to find messages
3. **Message Reactions**: Allow emoji reactions to messages
4. **Voice Messages**: Support audio messaging
5. **Message Editing**: Allow users to edit sent messages
6. **Message Deletion**: Allow users to delete messages
7. **Notifications**: Push notifications for new messages
8. **Message Encryption**: End-to-end encryption for privacy

## Migration Checklist

When switching to backend:

- [ ] Create `BackendChatService` class implementing `ChatService`
- [ ] Update `chat_list_screen.dart` to use new service
- [ ] Update `chat_detail_screen.dart` to use new service
- [ ] Implement real-time message sync (WebSocket or polling)
- [ ] Set up authentication token management
- [ ] Test message sending and receiving
- [ ] Implement error handling and retry logic
- [ ] Add loading states and animations
- [ ] Set up analytics tracking
- [ ] Handle offline scenarios (queue messages, sync on reconnect)

## Notes

- All chat operations are asynchronous (Future-based) for easy backend integration
- Models include `toJson()` and `fromJson()` for serialization
- Service layer is abstracted, allowing multiple implementations
- UI is reactive and updates when data changes
- Demo AI responses can be replaced with backend API calls
- The system is ready for production backend integration
