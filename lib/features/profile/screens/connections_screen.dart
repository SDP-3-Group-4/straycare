import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/services/auth_service.dart';
import 'package:straycare_demo/features/home/widgets/user_profile_dialog.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view connections')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userRepository.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final connections = List<String>.from(userData['connections'] ?? []);

          if (connections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No connections yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final userId = connections[index];
              return FutureBuilder<DocumentSnapshot>(
                future: _userRepository.getUser(userId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.grey),
                      title: Container(
                        width: 100,
                        height: 16,
                        color: Colors.grey,
                      ),
                    );
                  }

                  final user =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  String displayName = user['displayName'] ?? 'StrayCare User';
                  if (displayName == 'StrayCare User' &&
                      user['email'] != null) {
                    displayName = (user['email'] as String).split('@')[0];
                  }
                  final photoUrl = user['photoUrl'] ?? '';
                  final bio = user['bio'] ?? 'No bio available';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'User Profile',
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return UserProfileDialog(
                            userName: displayName,
                            userAvatarUrl: photoUrl,
                            isVerified:
                                false, // You might want to fetch this too
                            userId: userId, // Pass userId to dialog
                          );
                        },
                        transitionBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
