import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:straycare_demo/shared/widgets/verified_badge.dart';

import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/features/notifications/repositories/notification_repository.dart';
import 'package:straycare_demo/services/auth_service.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';

class UserProfileDialog extends StatefulWidget {
  final String userName;
  final String userAvatarUrl;
  final bool isVerified;
  final String?
  userId; // Make userId optional for backward compatibility but it should be passed

  const UserProfileDialog({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    this.isVerified = false,
    this.userId,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final UserRepository _userRepository = UserRepository();
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final PostRepository _postRepository = PostRepository();
  final AuthService _authService = AuthService();

  String _bio = "Loading...";
  String _petInfo = "No pet info";
  int _postsCount = 0;
  int _connectionsCount = 0;
  String _connectionStatus =
      'none'; // 'none', 'pending', 'connected', 'received'
  bool _isLoading = true;
  String? _currentUserId;
  late String _displayName;
  late String _avatarUrl;
  late bool _isVerified;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid;
    _displayName = widget.userName;
    _avatarUrl = widget.userAvatarUrl;
    _isVerified = widget.isVerified;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) {
      setState(() {
        _bio = "User info unavailable";
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await _userRepository.getUser(widget.userId!);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Check connection status
        String status = 'none';
        if (_currentUserId != null) {
          final connections = List<String>.from(data['connections'] ?? []);
          final receivedRequests = List<String>.from(
            data['receivedRequests'] ?? [],
          );
          final sentRequests = List<String>.from(data['sentRequests'] ?? []);

          if (connections.contains(_currentUserId)) {
            status = 'connected';
          } else if (receivedRequests.contains(_currentUserId)) {
            status = 'pending';
          } else if (sentRequests.contains(_currentUserId)) {
            status = 'received';
          }
        }

        // Get post count
        final postsCount = await _postRepository.getPostCount(widget.userId!);

        if (mounted) {
          setState(() {
            _bio = data['bio'] ?? "No bio available";
            _displayName = data['displayName'] ?? _displayName;
            _avatarUrl = data['photoUrl'] ?? _avatarUrl;
            if (data['verifiedStatus'] == true ||
                data['email'] == 'shopnilmax@gmail.com') {
              _isVerified = true;
            }

            if (data['petDetails'] != null) {
              final pet = data['petDetails'] as Map<String, dynamic>;
              _petInfo =
                  "${pet['name'] ?? 'Pet'} • ${pet['age'] ?? '?'} • ${pet['breed'] ?? 'Unknown'}";
            } else {
              _petInfo = "No pet info";
            }

            _connectionsCount = (data['connections'] as List?)?.length ?? 0;
            _postsCount = postsCount;
            _connectionStatus = status;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleConnect() async {
    if (_currentUserId == null || widget.userId == null) return;

    setState(() => _isLoading = true);

    try {
      if (_connectionStatus == 'none') {
        // Send request
        await _userRepository.sendConnectionRequest(
          _currentUserId!,
          widget.userId!,
        );
        await _notificationRepository.sendNotification(
          toUserId: widget.userId!,
          fromUserId: _currentUserId!,
          type: 'connection_request',
          message:
              '${_authService.currentUser?.displayName ?? 'Someone'} sent you a connection request.',
        );
        setState(() => _connectionStatus = 'pending');
      } else if (_connectionStatus == 'connected') {
        // Disconnect
        await _userRepository.removeConnection(_currentUserId!, widget.userId!);
        setState(() => _connectionStatus = 'none');
      } else if (_connectionStatus == 'received') {
        // Accept request
        await _userRepository.acceptConnectionRequest(
          _currentUserId!,
          widget.userId!,
        );
        await _notificationRepository.deleteConnectionRequestNotification(
          _currentUserId!,
          widget.userId!,
        );
        // Notify sender that request was accepted
        await _notificationRepository.sendNotification(
          toUserId: widget.userId!,
          fromUserId: _currentUserId!,
          type: 'connection_accepted',
          message:
              '${_authService.currentUser?.displayName ?? 'Someone'} accepted your connection request.',
        );
        setState(() => _connectionStatus = 'connected');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = _currentUserId == widget.userId;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B46C1), Color(0xFFA78BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(_avatarUrl)
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: _avatarUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name & Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_isVerified) ...[
                          const SizedBox(width: 8),
                          const VerifiedBadge(
                            baseColor: Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${_displayName.replaceAll(' ', '').toLowerCase()}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bio
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading && _bio == "Loading..."
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),
                    // Pet Info
                    if (_petInfo != "No pet info")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _petInfo,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          "Posts",
                          _postsCount > 0 ? _postsCount.toString() : "-",
                        ), // Placeholder
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          "Connections",
                          _connectionsCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Connect Button
                    if (!isMe)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading || _connectionStatus == 'pending'
                              ? null
                              : _handleConnect,
                          icon: Icon(
                            _getButtonIcon(),
                            color: _connectionStatus == 'connected'
                                ? Colors.white
                                : const Color(0xFF6B46C1),
                          ),
                          label: Text(
                            _getButtonLabel(),
                            style: TextStyle(
                              color: _connectionStatus == 'connected'
                                  ? Colors.white
                                  : const Color(0xFF6B46C1),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _connectionStatus == 'connected'
                                ? Colors.red
                                : Colors.white,
                            disabledBackgroundColor: Colors.white.withOpacity(
                              0.7,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Close Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getButtonIcon() {
    switch (_connectionStatus) {
      case 'connected':
        return Icons.person_remove;
      case 'pending':
        return Icons.hourglass_empty;
      case 'received':
        return Icons.person_add;
      default:
        return Icons.person_add;
    }
  }

  String _getButtonLabel() {
    switch (_connectionStatus) {
      case 'connected':
        return "Disconnect";
      case 'pending':
        return "Requested";
      case 'received':
        return "Accept Request";
      default:
        return "Connect";
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}
