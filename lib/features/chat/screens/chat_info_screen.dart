import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/repositories/user_repository.dart';
import '../../ai_bot/models/chat_model.dart';
import '../../home/widgets/user_profile_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatInfoScreen extends StatefulWidget {
  final Chat chat;

  const ChatInfoScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  final UserRepository _userRepository = UserRepository();
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _isAdmin = false;

  bool _isGroup = false;
  String? _iconEmoji;
  String _chatName = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadChatDetails();
  }

  Future<void> _loadChatDetails() async {
    setState(() => _isLoading = true);
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participants'] ?? []);
        final createdBy = data['createdBy'] as String?;
        final type = data['type'] as String?;

        final iconEmoji = data['iconEmoji'] as String?;

        setState(() {
          _iconEmoji = iconEmoji;
          _chatName = data['name'] ?? widget.chat.name;
        });

        // Determine type
        _isGroup = type == 'group' || (participantIds.length > 2);

        // Check if admin
        if (_currentUserId != null) {
          if (createdBy == _currentUserId) {
            _isAdmin = true;
          } else if (createdBy == null &&
              participantIds.isNotEmpty &&
              participantIds.first == _currentUserId) {
            // Fallback for legacy chats properties
            _isAdmin = true;
          }
        }

        if (participantIds.isNotEmpty) {
          final users = await _userRepository.getUsersByIds(participantIds);
          _participants = users.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'displayName': d['displayName'] ?? 'Unknown',
              'photoUrl': d['photoUrl'],
              'email': d['email'],
              'isVerified':
                  (d['verifiedStatus'] == true ||
                  d['email'] == 'shopnilmax@gmail.com'),
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading info: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGroupName() async {
    String? newName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          controller: TextEditingController(text: _chatName),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName!.trim().isNotEmpty && newName != _chatName) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .update({'name': newName!.trim()});
        setState(() {
          _chatName = newName!.trim();
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating name: $e')));
        }
      }
    }
  }

  Future<void> _pickEmoji() async {
    String? emoji;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Group Emoji'),
        content: TextField(
          autofocus: true,
          maxLength: 2,
          decoration: const InputDecoration(
            hintText: 'Type an emoji (e.g. 🐶)',
            counterText: '',
          ),
          onChanged: (val) => emoji = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (emoji != null && emoji!.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .update({'iconEmoji': emoji!.trim()});
        setState(() {
          _iconEmoji = emoji!.trim();
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating emoji: $e')));
        }
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group for everyone? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .delete();
        if (mounted) {
          // Pop back to list (pop info, then pop detail)
          Navigator.of(context).pop(); // pop info
          Navigator.of(context).pop(); // pop detail
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isGroup) {
      // Direct Chat Info (Profile View)
      // For now, assuming direct chat has only 2 participants, find the other one.
      final otherUser = _participants.firstWhere(
        (u) => u['id'] != _currentUserId,
        orElse: () => {},
      );

      if (otherUser.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('Contact Info')),
          body: const Center(child: Text('User not found')),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Contact Info')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundImage: otherUser['photoUrl'] != null
                    ? NetworkImage(otherUser['photoUrl'])
                    : null,
                child: otherUser['photoUrl'] == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                otherUser['displayName'] ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                otherUser['email'] ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              // More profile details can be added here
            ],
          ),
        ),
      );
    }

    // Group Info
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _deleteGroup,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Group Icon Upload Placeholder
                  GestureDetector(
                    onTap: _pickEmoji,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.purple[50],
                          child: _iconEmoji != null
                              ? Text(
                                  _iconEmoji!,
                                  style: const TextStyle(fontSize: 40),
                                )
                              : const Icon(
                                  Icons.groups,
                                  size: 50,
                                  color: Colors.purple,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _chatName.isNotEmpty ? _chatName : widget.chat.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: _updateGroupName,
                        ),
                    ],
                  ),
                  Text(
                    '${_participants.length} participants',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Participants',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final p = _participants[index];
                      final isMe = p['id'] == _currentUserId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: p['photoUrl'] != null
                              ? NetworkImage(p['photoUrl'])
                              : null,
                          child: p['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(isMe ? 'You' : p['displayName']),
                            if (p['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(p['email'] ?? ''),
                        onTap: () {
                          if (!isMe) {
                            showDialog(
                              context: context,
                              builder: (context) => UserProfileDialog(
                                userId: p['id'],
                                userName: p['displayName'],
                                userAvatarUrl: p['photoUrl'],
                                isVerified: p['isVerified'] ?? false,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
