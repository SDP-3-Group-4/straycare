import 'package:flutter/material.dart';

// --- SCREEN 3: AI VET BOT ---
class AiVetBotScreen extends StatelessWidget {
  const AiVetBotScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Vet Bot')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: const [
                ChatBubble(
                  isMe: false,
                  message:
                      'Hello! I am the StrayCare AI Vet Bot. How can I assist you today?',
                ),
                ChatBubble(
                  isMe: true,
                  message: 'My dog just ate some chocolate. What should I do?',
                ),
                ChatBubble(
                  isMe: false,
                  message:
                      '''Chocolate can be toxic to dogs. Observe your dog for symptoms like vomiting or hyperactivity. It is highly recommended to contact a professional veterinarian immediately for advice.\n\n---
⚠️ *Disclaimer: I am an AI assistant, not a veterinarian. This advice is for preliminary guidance only. Please consult a professional for medical emergencies.*''',
                ),
              ],
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
