import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ai_bot/models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Chats ---

  /// Creates a new chat (direct or group)
  Future<String> createChat(List<String> userIds, {String? groupName}) async {
    final isGroup = userIds.length > 2 || groupName != null;

    // For direct chats, check if one already exists
    if (!isGroup && userIds.length == 2) {
      final existingChat = await _findDirectChat(userIds[0], userIds[1]);
      if (existingChat != null) return existingChat;
    }

    final docRef = await _firestore.collection('chats').add({
      'participants': userIds,
      'type': isGroup ? 'group' : 'direct',
      'name': groupName, // Null for direct chats
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userIds.first, // Assumes first ID is creator
      'unreadCounts': {for (var uid in userIds) uid: 0},
    });

    return docRef.id;
  }

  /// Helper to find existing direct chat between two users
  Future<String?> _findDirectChat(String user1, String user2) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: user1)
        .get();

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(user2)) {
        return doc.id;
      }
    }
    return null;
  }

  /// Stream of chats for a specific user
  Stream<List<Chat>> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final chats = <Chat>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Determine chat name and image
            String chatName = data['name'] ?? 'Chat';
            String chatImage = ''; // Default empty, UI handles fallback
            bool isVerified = false;

            // For direct chats, fetch the other user's info
            if (data['type'] == 'direct') {
              final otherUserId = (data['participants'] as List).firstWhere(
                (id) => id != userId,
                orElse: () => '',
              );

              if (otherUserId.isNotEmpty) {
                final userDoc = await _firestore
                    .collection('users')
                    .doc(otherUserId)
                    .get();
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  chatName = userData['displayName'] ?? 'StrayCare User';
                  if (chatName == 'StrayCare User' &&
                      userData['email'] != null) {
                    chatName = (userData['email'] as String).split('@')[0];
                  }
                  chatImage = userData['photoUrl'] ?? '';
                  if (userData['verifiedStatus'] == true ||
                      userData['email'] == 'shopnilmax@gmail.com') {
                    isVerified = true;
                  }
                }
              }
            }

            chats.add(
              Chat(
                id: doc.id,
                name: chatName,
                profileImageUrl: chatImage,
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime:
                    (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isAiBot: false, // Firestore chats are human for now
                unreadCount: data['unreadCounts']?[userId] ?? 0,
                iconEmoji: data['iconEmoji'],
                isVerified: isVerified,
              ),
            );
          }
          return chats;
        });
  }

  Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
            if (unreadCounts != null) {
              totalUnread += (unreadCounts[userId] as num?)?.toInt() ?? 0;
            }
          }
          return totalUnread;
        });
  }

  // --- Messages ---

  /// Stream of messages for a specific chat
  Stream<List<Message>> getMessagesStream(String chatId, String currentUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Message(
              id: doc.id,
              chatId: chatId,
              senderId: data['senderId'],
              content: data['content'],
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isUserMessage: data['senderId'] == currentUserId,
              status: MessageStatus.read, // Simplified for now
            );
          }).toList();
        });
  }

  /// Send a message
  Future<void> sendMessage(
    String chatId,
    String content,
    String senderId,
  ) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add(
      {
        'senderId': senderId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'readBy': [senderId],
      },
    );

    // Update chat metadata and unread counts
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);

      final bool hasUnreadCounts = data.containsKey('unreadCounts');

      final Map<String, dynamic> updates = {
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      if (hasUnreadCounts) {
        // Increment unread count for all other participants
        for (var uid in participants) {
          if (uid != senderId) {
            updates['unreadCounts.$uid'] = FieldValue.increment(1);
          }
        }
      } else {
        // Initialize unread counts if missing (migration for old chats)
        final Map<String, int> initialCounts = {};
        for (var uid in participants) {
          initialCounts[uid] = (uid == senderId) ? 0 : 1;
        }
        updates['unreadCounts'] = initialCounts;
      }

      await _firestore.collection('chats').doc(chatId).update(updates);
    }
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      // Ignore errors (e.g. document doesn't have unreadCounts yet)
      // If it doesn't exist, count is effectively 0 anyway.
      print('Error marking chat as read: $e');
    }
  }

  // --- Typing Status ---

  /// Set typing status for a user in a chat
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingStatus.$userId': isTyping,
      });
    } catch (e) {
      print('Error setting typing status: $e');
      // If update fails (e.g. field doesn't exist), try setting with merge
      try {
        await _firestore.collection('chats').doc(chatId).set({
          'typingStatus': {userId: isTyping},
        }, SetOptions(merge: true));
      } catch (e2) {
        print('Error setting typing status fallback: $e2');
      }
    }
  }

  /// Stream of typing status map
  Stream<Map<String, bool>> getTypingStatusStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists || !doc.data()!.containsKey('typingStatus')) return {};
      final data = doc.data()!['typingStatus'] as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as bool));
    });
  }
}
