import 'package:flutter/material.dart';
import '../chat/screens/chat_detail_screen.dart';
import 'models/chat_model.dart';

// --- SCREEN 3: AI VET BOT ---
// --- SCREEN 3: AI VET BOT (REDIRECT) ---
class AiVetBotScreen extends StatefulWidget {
  const AiVetBotScreen({Key? key}) : super(key: key);

  @override
  State<AiVetBotScreen> createState() => _AiVetBotScreenState();
}

class _AiVetBotScreenState extends State<AiVetBotScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to the real ChatDetailScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chat: Chat(
              id: 'anvil_1_beta',
              name: 'AI Vet Bot',
              profileImageUrl: '',
              lastMessage: 'Ask me anything about pet care!',
              lastMessageTime: DateTime.now(),
              isAiBot: true,
              tag: 'Anvil 1 Beta',
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// Reusable Chat Bubble Widget (Moved here from main.dart)
class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  const ChatBubble({Key? key, required this.isMe, required this.message})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey[200],
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
        child: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
