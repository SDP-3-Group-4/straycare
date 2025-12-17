import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:straycare_demo/features/notifications/repositories/notification_repository.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/features/home/screens/post_detail_screen.dart';
import 'package:straycare_demo/features/home/widgets/user_profile_dialog.dart';
import 'package:straycare_demo/services/auth_service.dart';

// --- SCREEN 4: NOTIFICATIONS ---
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _notificationRepository.markAllAsRead(currentUser.uid);
    }
  }

  Future<void> _handleAccept(String notificationId, String fromUserId) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _userRepository.acceptConnectionRequest(currentUserId, fromUserId);
      await _notificationRepository.deleteNotification(notificationId);

      // Notify sender
      await _notificationRepository.sendNotification(
        toUserId: fromUserId,
        fromUserId: currentUserId,
        type: 'connection_accepted',
        message:
            '${_authService.currentUser?.displayName ?? 'Someone'} accepted your connection request.',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection accepted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleDecline(String notificationId, String fromUserId) async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _userRepository.declineConnectionRequest(currentUserId, fromUserId);
      await _notificationRepository.deleteNotification(notificationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationRepository.getNotificationsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawNotifications = snapshot.data?.docs ?? [];

          if (rawNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Aggregation Logic
          final List<Map<String, dynamic>> aggregatedList = [];
          final Map<String, List<DocumentSnapshot>> grouped = {};

          // First pass: group aggregate-able notifications
          for (var doc in rawNotifications) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'];
            final relatedId = data['relatedId'];

            if ((type == 'like' || type == 'comment') && relatedId != null) {
              final key = '${type}_$relatedId';
              if (!grouped.containsKey(key)) {
                grouped[key] = [];
              }
              grouped[key]!.add(doc);
            } else {
              // Non-aggregate-able, add directly as single item
              aggregatedList.add({
                'isAggregate': false,
                'doc': doc,
                'timestamp':
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              });
            }
          }

          // Second pass: Process groups
          grouped.forEach((key, docs) {
            // Sort by time within group to get latest actor
            docs.sort((a, b) {
              final tA =
                  ((a.data() as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.toDate() ??
                  DateTime.now();
              final tB =
                  ((b.data() as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.toDate() ??
                  DateTime.now();
              return tB.compareTo(tA); // Newest first
            });

            final newestDoc = docs.first;
            final newestData = newestDoc.data() as Map<String, dynamic>;

            aggregatedList.add({
              'isAggregate': true,
              'docs': docs, // Full list for counting
              'latestDoc': newestDoc, // For display info
              'timestamp':
                  (newestData['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            });
          });

          // Sort final list by timestamp
          aggregatedList.sort(
            (a, b) => (b['timestamp'] as DateTime).compareTo(
              a['timestamp'] as DateTime,
            ),
          );

          return ListView.builder(
            itemCount: aggregatedList.length,
            itemBuilder: (context, index) {
              final item = aggregatedList[index];

              if (item['isAggregate'] == true) {
                return _buildAggregatedNotification(context, item);
              } else {
                return _buildSingleNotification(
                  context,
                  item['doc'] as DocumentSnapshot,
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAggregatedNotification(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final docs = item['docs'] as List<DocumentSnapshot>;
    final latestDoc = item['latestDoc'] as DocumentSnapshot;
    final latestData = latestDoc.data() as Map<String, dynamic>;
    final type = latestData['type'];
    final relatedId = latestData['relatedId'];
    final fromUserId = latestData['fromUserId'];
    final timestamp = item['timestamp'] as DateTime;
    final isRead = docs.every(
      (d) => (d.data() as Map<String, dynamic>)['isRead'] == true,
    );

    final uniqueUserIds = docs
        .map((d) => (d.data() as Map<String, dynamic>)['fromUserId'] as String)
        .toSet();
    final count = uniqueUserIds.length;
    final othersCount = count - 1;

    return FutureBuilder<DocumentSnapshot>(
      future: _userRepository.getUser(fromUserId),
      builder: (context, userSnapshot) {
        String name = 'Someone';
        String avatarUrl = '';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          name = userData['displayName'] ?? 'Someone';
          avatarUrl = userData['photoUrl'] ?? '';
        }

        String messageText;
        if (type == 'like') {
          messageText = othersCount > 0
              ? '$name and $othersCount others liked your post'
              : '$name liked your post';
        } else {
          // comment
          messageText = othersCount > 0
              ? '$name and $othersCount others commented on your post'
              : '$name commented on your post';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: !isRead ? Colors.blue.withOpacity(0.05) : null,
          child: InkWell(
            onTap: () {
              // Mark all in group as read
              for (var doc in docs) {
                _notificationRepository.markAsRead(doc.id);
              }
              // Navigate to post
              if (relatedId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: relatedId),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => UserProfileDialog(
                          userId: fromUserId,
                          userName: name,
                          userAvatarUrl: avatarUrl,
                          isVerified: false,
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      backgroundColor: _getIconColor(type),
                      child: avatarUrl.isEmpty
                          ? Icon(_getIcon(type), color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          messageText,
                          style: TextStyle(
                            fontWeight: !isRead
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (relatedId != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleNotification(
    BuildContext context,
    DocumentSnapshot notificationDoc,
  ) {
    final notification = notificationDoc.data() as Map<String, dynamic>;
    final notificationId = notificationDoc.id;
    final type = notification['type'];
    final message = notification['message'];
    final timestamp =
        (notification['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final fromUserId = notification['fromUserId'];
    final relatedId = notification['relatedId'];
    final isRead = notification['isRead'] == true;

    return FutureBuilder<DocumentSnapshot>(
      future: _userRepository.getUser(fromUserId),
      builder: (context, userSnapshot) {
        String avatarUrl = '';
        String name = 'User';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          avatarUrl = userData['photoUrl'] ?? '';
          name = userData['displayName'] ?? 'User';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: !isRead ? Colors.blue.withOpacity(0.05) : null,
          child: InkWell(
            onTap: () {
              _notificationRepository.markAsRead(notificationId);
              if (relatedId != null &&
                  (type == 'like' || type == 'comment' || type == 'donation')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: relatedId),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => UserProfileDialog(
                              userId: fromUserId,
                              userName: name,
                              userAvatarUrl: avatarUrl,
                              isVerified: false,
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          backgroundColor: _getIconColor(type),
                          child: avatarUrl.isEmpty
                              ? Icon(
                                  _getIcon(type),
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                fontWeight: !isRead
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getTimeAgo(timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (type == 'connection_request') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              _handleDecline(notificationId, fromUserId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _handleAccept(notificationId, fromUserId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'connection_request':
        return Icons.person_add;
      case 'connection_accepted':
        return Icons.check_circle;
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'connection_request':
        return Colors.blue;
      case 'connection_accepted':
        return Colors.green;
      case 'like':
        return Colors.pink;
      case 'comment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
