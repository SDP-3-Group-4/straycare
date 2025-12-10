import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../ai_bot/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/repositories/user_repository.dart';
import '../repositories/chat_repository.dart';
import 'chat_info_screen.dart';
import '../../home/widgets/user_profile_dialog.dart';
import 'package:straycare_demo/shared/widgets/verified_badge.dart';
import '../../../../services/ai_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const ChatDetailScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  Map<String, Map<String, dynamic>> _participantsData = {};
  bool _isGroup = false;
  List<String> _participantIds = [];

  // Typing Indicator Logic
  Timer? _typingTimer;
  bool _isTyping = false;
  static const Duration _typingDebounce = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId != null) {
      _chatRepository.markChatAsRead(widget.chat.id, _currentUserId!);
      _loadChatDetails();
    }
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_currentUserId == null) return;

    if (_messageController.text.isNotEmpty && !_isTyping) {
      _setIsTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDebounce, () {
      if (_isTyping) {
        _setIsTyping(false);
      }
    });
  }

  void _setIsTyping(bool isTyping) {
    setState(() {
      _isTyping = isTyping;
    });
    _chatRepository.setTypingStatus(widget.chat.id, _currentUserId!, isTyping);
  }

  Future<void> _loadChatDetails() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participants'] ?? []);
        final type = data['type'] as String?;

        setState(() {
          _isGroup = type == 'group' || (participantIds.length > 2);
          _participantIds = participantIds;
        });

        if (participantIds.isNotEmpty) {
          // Fetch profiles for all members
          final users = await _userRepository.getUsersByIds(participantIds);
          final pData = <String, Map<String, dynamic>>{};

          for (var doc in users) {
            final d = doc.data() as Map<String, dynamic>;
            pData[doc.id] = {
              'name': d['displayName'] ?? 'Unknown',
              'photoUrl': d['photoUrl'] ?? '',
              'isVerified':
                  (d['verifiedStatus'] == true ||
                  d['email'] == 'shopnilmax@gmail.com'),
            };
          }
          if (mounted) {
            setState(() {
              _participantsData = pData;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading chat details: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    if (_isTyping && _currentUserId != null) {
      _chatRepository.setTypingStatus(widget.chat.id, _currentUserId!, false);
    }
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send: You appear to be offline or logged out.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatRepository.sendMessage(
        widget.chat.id,
        content,
        _currentUserId!,
      );

      // AI Bot Logic
      if (widget.chat.isAiBot) {
        // 1. Fake typing from bot
        _chatRepository.setTypingStatus(widget.chat.id, 'anvil_1_beta', true);

        // 2. Get response
        final aiResponse = await AIService().getAnvilResponse(content);

        // 3. Stop typing
        _chatRepository.setTypingStatus(widget.chat.id, 'anvil_1_beta', false);

        // 4. Send response
        await _chatRepository.sendMessage(
          widget.chat.id,
          aiResponse,
          'anvil_1_beta',
        );
      }

      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.chat.name),
                if (widget.chat.isVerified) ...[
                  const SizedBox(width: 4),
                  VerifiedBadge(
                    size: 14,
                    baseColor: Theme.of(context).primaryColor,
                  ),
                ],
              ],
            ),
            if (widget.chat.isAiBot)
              Text(
                '${widget.chat.tag ?? "AI Assistant"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              if (widget.chat.isAiBot) return;

              if (!_isGroup) {
                final otherId = _participantIds.firstWhere(
                  (id) => id != _currentUserId,
                  orElse: () => '',
                );
                if (otherId.isNotEmpty) {
                  final p = _participantsData[otherId];
                  showDialog(
                    context: context,
                    builder: (context) => UserProfileDialog(
                      userId: otherId,
                      userName: p?['name'] ?? widget.chat.name,
                      userAvatarUrl:
                          p?['photoUrl'] ?? widget.chat.profileImageUrl,
                      isVerified: p?['isVerified'] ?? widget.chat.isVerified,
                    ),
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatInfoScreen(chat: widget.chat),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatRepository.getMessagesStream(
                widget.chat.id,
                _currentUserId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom on initial load / new message
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),

          // Typing Indicator Stream
          StreamBuilder<Map<String, bool>>(
            stream: _chatRepository.getTypingStatusStream(widget.chat.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final typingUsers = snapshot.data!.entries
                  .where((e) => e.value == true && e.key != _currentUserId)
                  .map((e) => e.key)
                  .toList();

              if (typingUsers.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTypingString(typingUsers),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Message Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.isUserMessage;
    final showAvatar = _isGroup && !isMe;
    final pData = _participantsData[message.senderId];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatar) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    (pData != null && pData['photoUrl']!.isNotEmpty)
                    ? NetworkImage(pData['photoUrl']!)
                    : null,
                child: (pData == null || pData['photoUrl']!.isEmpty)
                    ? Text(
                        (pData?['name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (_isGroup && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4.0),
                      child: Text(
                        pData?['name'] ?? 'User',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.secondary
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isMe
                            ? const Radius.circular(15)
                            : const Radius.circular(0),
                        bottomRight: isMe
                            ? const Radius.circular(0)
                            : const Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 16,
                              color: isMe
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white70
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getTypingString(List<String> userIds) {
    if (userIds.isEmpty) return '';
    final names = userIds.map((id) {
      final pData = _participantsData[id];
      return pData?['name'] ?? 'Someone';
    }).toList();

    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }
}
