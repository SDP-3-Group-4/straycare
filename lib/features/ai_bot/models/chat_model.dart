/// Data models for chat functionality
/// These are structured to easily integrate with backend services

class Chat {
  final String id;
  final String name;
  final String profileImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isAiBot;
  final String? tag; // e.g., "Ask Vet Bot"
  final int unreadCount;
  final String? iconEmoji;
  final bool isVerified;
  final String? lastMessageSenderId;

  Chat({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isAiBot = false,
    this.tag,
    this.unreadCount = 0,
    this.iconEmoji,
    this.isVerified = false,
    this.lastMessageSenderId,
  });

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'isAiBot': isAiBot,
      'tag': tag,
      'unreadCount': unreadCount,
      'iconEmoji': iconEmoji,
      'isVerified': isVerified,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  /// Create from JSON (backend response)
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      isAiBot: json['isAiBot'] as bool? ?? false,
      tag: json['tag'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
    );
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isUserMessage;
  final MessageStatus status; // pending, sent, delivered, read

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isUserMessage,
    this.status = MessageStatus.sent,
  });

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isUserMessage': isUserMessage,
      'status': status.toString().split('.').last,
    };
  }

  /// Create from JSON (backend response)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isUserMessage: json['isUserMessage'] as bool,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }
}

enum MessageStatus { pending, sent, delivered, read }
