import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const ChatDetailScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatService _chatService;
  late TextEditingController _messageController;
  late Future<List<Message>> _messagesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService = LocalChatService();
    _messageController = TextEditingController();
    _messagesFuture = _chatService.getMessagesForChat(widget.chat.id);
    _chatService.markChatAsRead(widget.chat.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(widget.chat.id, content);
      setState(() {
        _messagesFuture = _chatService.getMessagesForChat(widget.chat.id);
      });

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

      // Simulate AI response for AI Vet Bot
      if (widget.chat.isAiBot) {
        await Future.delayed(const Duration(seconds: 2));
        final aiResponse = _generateAiResponse(content);
        await _chatService.sendMessage(
          widget.chat.id,
          aiResponse,
          isUserMessage: false,
        );
        setState(() {
          _messagesFuture = _chatService.getMessagesForChat(widget.chat.id);
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  String _generateAiResponse(String userMessage) {
    // Simple AI response generation for demo
    // This will be replaced with actual backend API call
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('chocolate')) {
      return 'Chocolate toxicity depends on the type and amount. Dark chocolate is more toxic than milk chocolate. Please observe your pet and contact a vet immediately if you notice any symptoms.';
    } else if (lowerMessage.contains('vaccine')) {
      return 'Vaccinations are important for your pet\'s health. Core vaccines typically include rabies and DHPP. Consult your veterinarian for the best vaccination schedule for your pet.';
    } else if (lowerMessage.contains('appetite') ||
        lowerMessage.contains('eat')) {
      return 'Loss of appetite can indicate various issues. Keep track of any other symptoms and schedule a vet visit soon. Ensure your pet has access to fresh water.';
    } else if (lowerMessage.contains('cough') ||
        lowerMessage.contains('sneeze')) {
      return 'Coughing or sneezing could be signs of a respiratory issue. Monitor your pet\'s behavior and contact your vet if symptoms persist.';
    } else {
      return 'Sorry, failed to reach the Anvil™ AI Platforms. Try again later or contact support at contact.edgeventurers@gmail.com.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chat.name),
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
              // TODO: Implement chat info/details screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
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
                        const SizedBox(height: 8),
                        if (widget.chat.isAiBot)
                          Text(
                            'Start a conversation with the AI Vet Bot',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  );
                }

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
                      hintText: widget.chat.isAiBot
                          ? 'Ask your question...'
                          : 'Type a message...',
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
    return Align(
      alignment: message.isUserMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUserMessage
              ? Theme.of(context).colorScheme.secondary
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: message.isUserMessage
                ? const Radius.circular(15)
                : const Radius.circular(0),
            bottomRight: message.isUserMessage
                ? const Radius.circular(0)
                : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isUserMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 16,
                color: message.isUserMessage
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: message.isUserMessage
                    ? Colors.white70
                    : Theme.of(context).textTheme.bodySmall?.color,
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
}
