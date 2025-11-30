# StrayCare Chat Messaging System

## Overview

The chat messaging system is now fully integrated into the StrayCare app, featuring a modern messaging interface with support for both user-to-user chats and AI Vet Bot interactions.

## Features

### ✨ Chat List Screen
- **Initial Messages Tab**: Shows all conversations sorted by most recent
- **Profile Pictures**: Each chat displays a profile picture with AI bot badge for the AI Vet Bot
- **Last Message Preview**: Quick preview of the last message sent
- **Unread Badges**: Visual indicator for unread message counts
- **Tag Display**: AI Vet Bot shows "Ask Vet Bot" tag for easy identification
- **Timestamps**: Shows when each message was last sent (m ago, h ago, etc.)
- **Long-Press Options**: Delete chats with confirmation
- **Add Chat Button**: Placeholder for creating new chats
- **Empty State**: Friendly UI when no chats exist
- **Pull-to-Refresh**: Update chat list by refreshing

### 🤖 Chat Detail Screen
- **Full Conversation View**: Display all messages in a conversation
- **Message Bubbles**: User messages on right (purple), others on left (gray)
- **AI Responses**: Intelligent responses from AI Vet Bot with automatic typing simulation
- **Message Timestamps**: Precise timing for each message
- **Auto-Scroll**: Automatically scrolls to the latest message
- **Send Functionality**: Type and send new messages
- **Real-Time Status**: Message delivery/read status indicators
- **Smart AI Responses**: Context-aware AI bot responses for health topics

## File Structure

```
lib/features/ai_bot/
├── models/
│   └── chat_model.dart
│       ├── Chat class
│       ├── Message class
│       └── MessageStatus enum
├── services/
│   ├── chat_service.dart
│   │   ├── ChatService interface
│   │   ├── LocalChatService (current)
│   │   └── Sample data initialization
│   ├── backend_chat_service_example.dart
│   │   └── Example backend implementation (ready to uncomment)
│   └── (future: websocket_chat_service.dart)
├── screens/
│   ├── chat_list_screen.dart
│   │   └── Main messaging tab interface
│   ├── chat_detail_screen.dart
│   │   └── Individual chat UI
│   └── (future: new_chat_screen.dart)
├── CHAT_SYSTEM_GUIDE.md
│   └── Architecture & technical documentation
├── BACKEND_INTEGRATION_GUIDE.md
│   └── Step-by-step guide to connect backend
└── README.md (this file)
```

## Current Sample Data

### AI Vet Bot
- **ID**: `ai_vet_bot_001`
- **Status**: AI Bot (badge displayed)
- **Tag**: "Ask Vet Bot"
- **Sample Messages**: Conversation about chocolate toxicity in dogs
- **Purpose**: Demo conversation showing AI capabilities

### Random User (Sarah Anderson)
- **ID**: `user_001`
- **Name**: Sarah Anderson
- **Unread Count**: 2
- **Sample Messages**: Casual conversation about puppy care
- **Purpose**: Demo user conversation

## How to Use

### For Users

1. **View Messages Tab**
   - Tap the Messages icon in the bottom navigation bar
   - See all your conversations listed

2. **Start Conversation with AI Vet Bot**
   - Tap "AI Vet Bot" in the chat list
   - Ask your pet health questions
   - Get instant AI responses

3. **Chat with Other Users**
   - Tap any user in the chat list
   - Send and receive messages
   - See message delivery status

4. **Manage Chats**
   - Long-press a chat to see options
   - Delete chats you no longer need

### For Developers

#### Running the Current Demo

```bash
flutter run
# Navigate to Messages tab using bottom navigation
```

#### Switching to Backend

1. **Review the integration guide**:
   ```
   lib/features/ai_bot/BACKEND_INTEGRATION_GUIDE.md
   ```

2. **Uncomment backend service** (or create new one):
   ```
   lib/features/ai_bot/services/backend_chat_service_example.dart
   ```

3. **Update service initialization**:
   ```dart
   // In chat_list_screen.dart, initState():
   _chatService = BackendChatService(
     baseUrl: 'your-backend-url',
     authToken: userToken,
   );
   ```

4. **Test with your backend API**

#### Testing

```bash
# Run tests
flutter test

# Test specific file
flutter test test/features/ai_bot/chat_service_test.dart

# Run with coverage
flutter test --coverage
```

## Architecture Highlights

### Service-Oriented Design
- **ChatService Interface**: Abstract interface for all chat operations
- **LocalChatService**: In-memory implementation for demo/offline mode
- **BackendChatService**: HTTP-based implementation for production
- Easy to switch between implementations

### Data Models
- **Chat Model**: Represents a conversation with metadata
- **Message Model**: Individual message with status tracking
- Both include `toJson()` and `fromJson()` for serialization

### Reactive UI
- **FutureBuilder**: Loading states and error handling
- **setState**: Real-time UI updates when data changes
- **StreamController**: Ready for WebSocket integration

### Ready for Backend
- All async operations use Future
- Models support JSON serialization
- Service layer is abstract and replaceable
- Error handling built-in

## Backend Integration Checklist

- [ ] Review `BACKEND_INTEGRATION_GUIDE.md`
- [ ] Design backend API endpoints
- [ ] Create `BackendChatService` implementation
- [ ] Set up authentication token management
- [ ] Implement error handling and retries
- [ ] Add WebSocket for real-time messages (optional)
- [ ] Test with staging environment
- [ ] Deploy to production

## API Endpoints Required

When you have a backend, implement these endpoints:

```
GET    /api/v1/chats
POST   /api/v1/chats
GET    /api/v1/chats/{chatId}
GET    /api/v1/chats/{chatId}/messages
POST   /api/v1/chats/{chatId}/messages
PATCH  /api/v1/chats/{chatId}/read
DELETE /api/v1/chats/{chatId}
POST   /api/v1/ai/vet-bot/response
```

See `BACKEND_INTEGRATION_GUIDE.md` for full specifications.

## Key Classes & Methods

### ChatService Interface

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

### Chat Model

```dart
Chat(
  id: String,
  name: String,
  profileImageUrl: String,
  lastMessage: String,
  lastMessageTime: DateTime,
  isAiBot: bool,
  tag: String?,
  unreadCount: int,
)
```

### Message Model

```dart
Message(
  id: String,
  chatId: String,
  senderId: String,
  content: String,
  timestamp: DateTime,
  isUserMessage: bool,
  status: MessageStatus,
)
```

## Future Enhancements

1. **Real-Time Updates**
   - WebSocket integration for instant messaging
   - Typing indicators
   - Online/offline status

2. **Rich Media**
   - Image sharing
   - Voice messages
   - File attachments

3. **Advanced Features**
   - Group chats
   - Message search
   - Message reactions/emojis
   - Message editing/deletion
   - Read receipts

4. **AI Improvements**
   - Context-aware responses
   - Multi-language support
   - Appointment booking integration
   - Vet recommendations

5. **Performance**
   - Local message caching
   - Pagination for large chat histories
   - Offline message queue

## Troubleshooting

### Chat List Not Loading
1. Check network connectivity
2. Ensure auth token is valid
3. Check backend API status
4. Look at console logs for errors

### Messages Not Showing
1. Verify chatId is correct
2. Check message timestamps are valid
3. Ensure sender IDs are properly set

### AI Bot Not Responding
1. Check AI service is enabled
2. Verify message format is correct
3. Check for API rate limiting

## Common Tasks

### Add a New Chat
```dart
await _chatService.createChat('New User', 'profile_url');
```

### Send a Message
```dart
await _chatService.sendMessage('chat_id', 'Hello!');
```

### Delete a Chat
```dart
await _chatService.deleteChat('chat_id');
```

### Mark Chat as Read
```dart
await _chatService.markChatAsRead('chat_id');
```

## Performance Tips

1. **Pagination**: Implement lazy loading for large message lists
2. **Caching**: Cache frequently accessed chats locally
3. **Debouncing**: Debounce search and typing indicators
4. **Connection Pool**: Reuse HTTP connections
5. **Image Optimization**: Compress profile pictures before upload

## Security Considerations

1. **Token Storage**: Use `flutter_secure_storage` for tokens
2. **SSL Pinning**: Implement certificate pinning for API
3. **Message Encryption**: Consider end-to-end encryption
4. **Input Validation**: Validate all user inputs
5. **Rate Limiting**: Implement on backend

## Documentation

- **CHAT_SYSTEM_GUIDE.md**: Complete architecture and design details
- **BACKEND_INTEGRATION_GUIDE.md**: Step-by-step integration instructions
- **backend_chat_service_example.dart**: Commented example implementation

## Support

For issues or questions:
1. Check the documentation files
2. Review the example implementations
3. Check Flutter/Dart official documentation
4. Review error messages in console

## Version History

- **v1.0.0** (Current)
  - Initial chat system implementation
  - Chat list screen
  - Chat detail screen
  - AI Vet Bot integration
  - Service-oriented architecture
  - Ready for backend integration

---

**Last Updated**: November 16, 2024
**Status**: Production Ready (Local Demo)
**Next Phase**: Backend Integration
