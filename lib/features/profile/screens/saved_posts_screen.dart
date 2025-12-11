import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums.dart';
import '../../home/widgets/post_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../create_post/repositories/post_repository.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../services/auth_service.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();

  List<DocumentSnapshot> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
  }

  Future<void> _fetchSavedPosts() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get user doc to get saved IDs
      final userDoc = await _userRepository.getUser(user.uid);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final savedIds = List<String>.from(data['savedPostIds'] ?? []);

        if (savedIds.isNotEmpty) {
          final posts = await _postRepository.getPostsByIds(savedIds);
          setState(() {
            _savedPosts = posts;
            _isLoading = false;
          });
        } else {
          setState(() {
            _savedPosts = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching saved posts: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRemove(String postId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _userRepository.unsavePost(user.uid, postId);
      setState(() {
        _savedPosts.removeWhere((doc) => doc.id == postId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from saved items')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing post: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('saved_items')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved items yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _savedPosts.length,
              itemBuilder: (context, index) {
                final post = _savedPosts[index];
                final data = post.data() as Map<String, dynamic>;

                // Parse category
                PostCategory category = PostCategory.rescue;
                try {
                  category = PostCategory.values.firstWhere(
                    (e) => e.name == data['category'],
                    orElse: () => PostCategory.rescue,
                  );
                } catch (_) {}

                // Calculate time ago
                String timeAgo = 'Just now';
                if (data['createdAt'] != null) {
                  final date = (data['createdAt'] as Timestamp).toDate();
                  final diff = DateTime.now().difference(date);
                  if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeAgo = '${diff.inHours}h ago';
                  } else {
                    timeAgo = '${diff.inDays}d ago';
                  }
                }

                final currentUser = _authService.currentUser;
                final isLiked =
                    (data['likes'] as List?)?.contains(currentUser?.uid) ??
                    false;

                return PostCard(
                  postId: post.id,
                  userId: data['authorId'] ?? '',
                  userName: data['authorName'] ?? 'Anonymous',
                  userAvatarUrl: data['authorPhotoUrl'] ?? '',
                  timeAgo: timeAgo,
                  location: data['location'] ?? '',
                  category: category,
                  postContent: data['content'] ?? '',
                  isEdited: data['isEdited'] ?? false,
                  postImageUrl: data['imageUrl'] ?? '',
                  likes: (data['likes'] as List?)?.length ?? 0,
                  comments: data['commentsCount'] ?? 0,
                  raisedAmount: (data['currentAmount'] as num?)?.toDouble(),
                  goalAmount: (data['fundraiseGoal'] as num?)?.toDouble(),
                  donorCount: 0,
                  isLiked: isLiked,
                  isSaved: true,
                  onSave: () => _handleRemove(post.id),
                  onLike: () {
                    final repo = PostRepository();
                    if (isLiked) {
                      repo.unlikePost(post.id);
                    } else {
                      repo.likePost(post.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
