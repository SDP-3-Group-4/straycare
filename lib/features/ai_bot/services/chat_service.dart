import '../models/chat_model.dart';

/// Service layer for chat operations
/// This is structured to easily integrate with backend APIs
abstract class ChatService {
  /// Fetch all chats for the current user
  Future<List<Chat>> getAllChats();

  /// Fetch messages for a specific chat
  Future<List<Message>> getMessagesForChat(String chatId);

  /// Send a message
  Future<Message> sendMessage(
    String chatId,
    String content, {
    bool isUserMessage = true,
  });

  /// Create a new chat
  Future<Chat> createChat(String name, String profileImageUrl);

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId);

  /// Delete a chat
  Future<void> deleteChat(String chatId);
}

/// Local implementation (will be replaced with backend implementation)
class LocalChatService implements ChatService {
  // In-memory storage for demo purposes
  final Map<String, List<Message>> _messagesMap = {};
  final List<Chat> _chats = [];

  LocalChatService() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Initialize with sample chats
    final aiVetBotChat = Chat(
      id: 'ai_vet_bot_001',
      name: 'AI Vet Bot',
      profileImageUrl: 'assets/images/bot.png',
      lastMessage:
          'Hello! I am the StrayCare AI Vet Bot. How can I assist you today?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isAiBot: true,
      tag: 'Anvil 1 Beta',
    );

    final randomUserChat = Chat(
      id: 'user_001',
      name: 'Arpita Biswas',
      profileImageUrl: 'https://via.placeholder.com/150/A78BFA/FFFFFF?text=SA',
      lastMessage: 'Hey! How is your puppy doing now?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isAiBot: false,
      unreadCount: 2,
    );

    _chats.addAll([aiVetBotChat, randomUserChat]);

    // Initialize messages for AI Vet Bot
    _messagesMap['ai_vet_bot_001'] = [
      Message(
        id: 'msg_001',
        chatId: 'ai_vet_bot_001',
        senderId: 'ai_vet_bot_001',
        content:
            'Hello! I am the StrayCare AI Vet Bot. How can I assist you today?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isUserMessage: false,
        status: MessageStatus.delivered,
      ),
      Message(
        id: 'msg_002',
        chatId: 'ai_vet_bot_001',
        senderId: 'user_current',
        content: 'My dog just ate some chocolate. What should I do?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isUserMessage: true,
        status: MessageStatus.read,
      ),
      Message(
        id: 'msg_003',
        chatId: 'ai_vet_bot_001',
        senderId: 'ai_vet_bot_001',
        content:
            '''Chocolate can be toxic to dogs. Observe your dog for symptoms like vomiting or hyperactivity. It is highly recommended to contact a professional veterinarian immediately for advice.

---
⚠️ *Disclaimer: I am an AI assistant, not a veterinarian. This advice is for preliminary guidance only. Please consult a professional for medical emergencies.*''',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isUserMessage: false,
        status: MessageStatus.delivered,
      ),
    ];

    // Initialize messages for random user
    _messagesMap['user_001'] = [
      Message(
        id: 'msg_004',
        chatId: 'user_001',
        senderId: 'user_001',
        content: 'Hey! How is your puppy doing now?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isUserMessage: false,
        status: MessageStatus.read,
      ),
      Message(
        id: 'msg_005',
        chatId: 'user_001',
        senderId: 'user_001',
        content: 'Did you take her to the vet?',
        timestamp: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 50),
        ),
        isUserMessage: false,
        status: MessageStatus.read,
      ),
    ];
  }

  @override
  Future<List<Chat>> getAllChats() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Sort by last message time (most recent first)
    _chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return _chats;
  }

  @override
  Future<List<Message>> getMessagesForChat(String chatId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    return _messagesMap[chatId] ?? [];
  }

  @override
  Future<Message> sendMessage(
    String chatId,
    String content, {
    bool isUserMessage = true,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: isUserMessage ? 'user_current' : chatId,
      content: content,
      timestamp: DateTime.now(),
      isUserMessage: isUserMessage,
      status: MessageStatus.sent,
    );

    // Add to messages map
    if (_messagesMap[chatId] != null) {
      _messagesMap[chatId]!.add(message);
    } else {
      _messagesMap[chatId] = [message];
    }

    // Update chat's last message
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        name: _chats[chatIndex].name,
        profileImageUrl: _chats[chatIndex].profileImageUrl,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        isAiBot: _chats[chatIndex].isAiBot,
        tag: _chats[chatIndex].tag,
      );
    }

    return message;
  }

  @override
  Future<Chat> createChat(String name, String profileImageUrl) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final chat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      profileImageUrl: profileImageUrl,
      lastMessage: 'No messages yet',
      lastMessageTime: DateTime.now(),
    );

    _chats.add(chat);
    _messagesMap[chat.id] = [];

    return chat;
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        name: _chats[chatIndex].name,
        profileImageUrl: _chats[chatIndex].profileImageUrl,
        lastMessage: _chats[chatIndex].lastMessage,
        lastMessageTime: _chats[chatIndex].lastMessageTime,
        isAiBot: _chats[chatIndex].isAiBot,
        tag: _chats[chatIndex].tag,
        unreadCount: 0,
      );
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    _chats.removeWhere((c) => c.id == chatId);
    _messagesMap.remove(chatId);
  }
}
