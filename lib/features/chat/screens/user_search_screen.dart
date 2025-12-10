import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/repositories/user_repository.dart';
import '../repositories/chat_repository.dart';
import '../../ai_bot/models/chat_model.dart'; // Temporarily using existing model
import 'chat_detail_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  String? _currentUserId;

  // New variables
  bool _isSearching = false;
  List<Map<String, dynamic>> _connections = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);

    try {
      final userDoc = await _userRepository.getUser(_currentUserId!);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final connectionIds = List<String>.from(userData['connections'] ?? []);

        if (connectionIds.isNotEmpty) {
          final docs = await _userRepository.getUsersByIds(connectionIds);
          setState(() {
            _connections = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'displayName': data['displayName'] ?? 'Unknown',
                'photoUrl': data['photoUrl'],
                'email': data['email'],
                'username': data['username'] ?? '',
              };
            }).toList();
            _searchResults = List.from(_connections);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = List.from(_connections);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final docs = await _userRepository.searchUsers(query);
      setState(() {
        _searchResults = docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'displayName': data['displayName'] ?? 'Unknown',
                'photoUrl': data['photoUrl'],
                'email': data['email'],
                'username': data['username'] ?? '',
              };
            })
            // Filter out current user from results
            .where((user) => user['id'] != _currentUserId)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createChat() async {
    if (_selectedUserIds.isEmpty || _currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final participants = [_currentUserId!, ..._selectedUserIds];
      String? groupName;

      // specific logic for group creation
      if (_selectedUserIds.length > 1) {
        // Prompt for group name
        final name = await _showGroupNameDialog();
        if (name == null || name.isEmpty) {
          setState(() => _isLoading = false);
          return; // Cancelled
        }
        groupName = name;
      }

      final chatId = await _chatRepository.createChat(
        participants,
        groupName: groupName,
      );

      if (!mounted) return;

      // Temporarily construct a Chat object to navigate to Detail Screen
      // The Detail Screen will fetch real data later when refactored
      // For now we might need to rely on the ChatDetailScreen fetching messages
      // but the Chat object passed might be incomplete.
      // Ideally we should navigate and let the detail screen fetch the chat.
      // BUT current ChatDetailScreen takes a Chat object.
      // I'll create a dummy Chat object.

      final chat = Chat(
        id: chatId,
        name: groupName ?? 'Chat', // Will be fixed in list
        profileImageUrl: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatDetailScreen(chat: chat)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showGroupNameDialog() {
    String? name;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Name'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter group name'),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, name),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _selectedUserIds.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),

      floatingActionButton: _selectedUserIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _createChat,
              label: Text(
                isGroup ? 'Create Group' : 'Start Chat',
                style: const TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.chat, color: Colors.white),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          if (!_isSearching &&
              _connections.isNotEmpty &&
              _searchResults.length == _connections.length)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Your Connections',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // Selected Users Chips
          if (_selectedUserIds.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _selectedUserIds.map((uid) {
                  // Find user in search results for name, or show ID
                  final user = _searchResults.firstWhere(
                    (u) => u['id'] == uid,
                    orElse: () => {'displayName': 'User'},
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(user['displayName']),
                      onDeleted: () => _toggleSelection(uid),
                    ),
                  );
                }).toList(),
              ),
            ),

          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      _isSearching ? 'No users found' : 'No connections yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUserIds.contains(user['id']);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['photoUrl'] != null
                              ? NetworkImage(user['photoUrl'])
                              : null,
                          child: user['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user['displayName']),
                        subtitle:
                            (user['username'] != null &&
                                user['username'].isNotEmpty)
                            ? Text(user['username'])
                            : null,
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(user['id']),
                        ),
                        onTap: () => _toggleSelection(user['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
