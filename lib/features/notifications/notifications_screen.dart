import 'package:flutter/material.dart';

// --- SCREEN 4: NOTIFICATIONS ---
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade700, // Consistent blue
              child: const Icon(Icons.comment, color: Colors.white),
            ),
            title: const Text(
              'Sabrina Tasnim Imu commented on your "Kittens" post.',
            ),
            subtitle: const Text('2 minutes ago'),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).primaryColor, // Use primary purple
              child: const Icon(Icons.chat, color: Colors.white),
            ),
            title: const Text(
              'You have a new message from "Dr. Arpita Biswas".',
            ),
            subtitle: const Text('1 hour ago'),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink.shade400, // Consistent pink
              child: const Icon(Icons.thumb_up, color: Colors.white),
            ),
            title: const Text('Muzahidul Islam Joy liked your post.'),
            subtitle: const Text('3 hours ago'),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade700, // Consistent green
              child: const Icon(Icons.monetization_on, color: Colors.white),
            ),
            title: const Text(
              'Your "Happy Paws" fundraiser just received a donation!',
            ),
            subtitle: const Text('1 day ago'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
