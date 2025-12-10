import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/enums.dart';

import '../notifications/notifications_screen.dart';
import '../notifications/repositories/notification_repository.dart';
import '../create_post/create_post_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'providers/home_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/sliding_chip_toggle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = Provider.of<HomeProvider>(context, listen: false);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        provider.loadMorePosts();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<HomeProvider>(context, listen: false).checkLocationStatus();
    }
  }

  Future<void> _handleToggle(int index) async {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    final success = await provider.setCategoryIndex(index);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location from device settings to use this feature',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: provider.refreshPosts,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // --- App Bar ---
                SliverAppBar(
                  floating: true,
                  title: Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  centerTitle: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.add_box_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreatePostScreen(),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: NotificationRepository().getNotificationsStream(
                        AuthService().currentUser?.uid ?? '',
                      ),
                      builder: (context, snapshot) {
                        bool hasUnread = false;
                        if (snapshot.hasData) {
                          hasUnread = snapshot.data!.docs.any(
                            (doc) =>
                                (doc.data()
                                    as Map<String, dynamic>)['isRead'] ==
                                false,
                          );
                        }

                        return Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 8,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                // --- Toggle: Explore / Near Me ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                    child: Center(
                      child: SlidingChipToggle(
                        selectedIndex: provider.selectedCategoryIndex,
                        onTap: _handleToggle,
                      ),
                    ),
                  ),
                ),

                // --- Feed Posts ---
                if (provider.isLoading && provider.posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null && provider.posts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (provider.posts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_posts_nearby'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == provider.posts.length) {
                        return provider.isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final post = provider.posts[index];
                      final data = post.data() as Map<String, dynamic>;

                      // Parse category
                      PostCategory category = PostCategory.rescue;
                      try {
                        category = PostCategory.values.firstWhere(
                          (e) => e.name == data['category'],
                          orElse: () => PostCategory.rescue,
                        );
                      } catch (_) {}

                      // Calculate time ago (simplified)
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

                      final currentUser = AuthService().currentUser;
                      final isLiked =
                          (data['likes'] as List?)?.contains(
                            currentUser?.uid,
                          ) ??
                          false;
                      final isSaved = provider.savedPostIds.contains(post.id);

                      return PostCard(
                        postId: post.id,
                        userId: data['authorId'] ?? '',
                        userName: data['authorName'] ?? 'Anonymous',
                        userAvatarUrl: data['authorPhotoUrl'] ?? '',
                        timeAgo: timeAgo,
                        location: data['location'] ?? '',
                        category: category,
                        postContent: data['content'] ?? '',
                        postImageUrl: data['imageUrl'] ?? '',
                        likes: (data['likes'] as List?)?.length ?? 0,
                        comments: data['commentsCount'] ?? 0,
                        isLiked: isLiked,
                        raisedAmount:
                            (data['raisedAmount'] as num?)?.toDouble() ??
                            (data['currentAmount'] as num?)?.toDouble(),
                        goalAmount: (data['fundraiseGoal'] as num?)?.toDouble(),
                        donorCount: (data['donorCount'] as num?)?.toInt() ?? 0,
                        isSaved: isSaved,
                        onLike: () {
                          provider.toggleLike(post.id);
                        },
                        onSave: () {
                          provider.toggleSave(post.id);
                        },
                      );
                    }, childCount: provider.posts.length + 1),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
