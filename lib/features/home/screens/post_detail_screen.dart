import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';
import 'package:straycare_demo/features/home/widgets/post_card.dart';
import 'package:straycare_demo/shared/enums.dart';
import '../../../../l10n/app_localizations.dart';

import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import '../../../../services/auth_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = true;
  String? _error;
  DocumentSnapshot? _postDoc;
  Map<String, dynamic>? _authorData;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final posts = await _postRepository.getPostsByIds([widget.postId]);
      if (posts.isNotEmpty) {
        final post = posts.first;
        final postData = post.data() as Map<String, dynamic>;

        // Fetch author details if authorImage is missing
        if ((postData['authorImage'] ?? '').isEmpty &&
            postData['authorId'] != null) {
          try {
            final userDoc = await _userRepository.getUser(postData['authorId']);
            if (userDoc.exists) {
              _authorData = userDoc.data() as Map<String, dynamic>;
            }
          } catch (e) {
            debugPrint('Error fetching author data: $e');
          }
        }

        setState(() {
          _postDoc = post;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Post not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading post: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('from Notifications'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchPost();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_postDoc == null) {
      return const Center(child: Text('Post not found'));
    }

    final post = _postDoc!.data() as Map<String, dynamic>;
    final createdAt =
        (post['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Use fetched author data if available, otherwise fallback to post data
    final authorName =
        _authorData?['displayName'] ?? post['authorName'] ?? 'Unknown User';
    final authorImage =
        _authorData?['photoUrl'] ?? post['authorPhotoUrl'] ?? '';

    final currentUser = AuthService().currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: PostCard(
        userName: authorName,
        userAvatarUrl: authorImage,
        postContent: post['content'] ?? post['description'] ?? '',
        postImageUrl: post['imageUrl'] ?? '',
        likes: (post['likes'] as List?)?.length ?? 0,
        comments: post['commentsCount'] ?? 0,
        postId: _postDoc!.id,
        userId: post['authorId'] ?? '',
        isLiked: (post['likes'] as List?)?.contains(currentUser?.uid) ?? false,
        onLike: () async {
          await _postRepository.toggleLike(_postDoc!.id);
        },
        raisedAmount:
            (post['raisedAmount'] as num?)?.toDouble() ??
            (post['currentAmount'] as num?)?.toDouble() ??
            0.0,
        goalAmount: (post['fundraiseGoal'] ?? post['targetAmount'] ?? 0)
            .toDouble(),
        donorCount: post['donorCount'] ?? 0,
        category: _parseCategory(post['category']),
        location: post['location'] ?? '',
        timeAgo: _getTimeAgo(createdAt),
        isEdited: post['isEdited'] ?? false,
      ),
    );
  }

  PostCategory _parseCategory(String? category) {
    if (category == null) return PostCategory.fun;
    return PostCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => PostCategory.fun,
    );
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
}
