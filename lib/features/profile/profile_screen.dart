import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator

import 'package:straycare_demo/features/settings/settings_screen.dart';
import 'package:straycare_demo/features/profile/widgets/edit_profile_sheet.dart';
import 'package:straycare_demo/services/auth_service.dart';
import 'package:straycare_demo/features/profile/vet_verification_screen.dart';
import 'package:straycare_demo/features/profile/screens/saved_posts_screen.dart';
import 'package:straycare_demo/features/profile/screens/order_history_screen.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';
import 'package:straycare_demo/features/profile/screens/connections_screen.dart';
import 'package:straycare_demo/features/profile/screens/clinics_near_me_screen.dart'; // Import Screen
import 'package:straycare_demo/features/home/widgets/post_card.dart';
import 'package:straycare_demo/shared/enums.dart';
import 'package:straycare_demo/shared/widgets/verified_badge.dart';
import '../../l10n/app_localizations.dart';

// --- SCREEN 5: PROFILE ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  final PostRepository _postRepository = PostRepository();
  StreamSubscription<User?>? _authSubscription;
  User? _user;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to keep the UI in sync
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
    // Initial load
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // AuthWrapper in main.dart will handle the navigation
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).translate('logout_failed')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeletePost(String postId) async {
    try {
      await _postRepository.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
      }
    }
  }

  String _getTimeAgo(DateTime timestamp, BuildContext context) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _handleRefresh() async {
    // Reload the current user to get the latest data
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  PostCategory _parseCategory(String? category) {
    if (category == null) return PostCategory.rescue;
    try {
      return PostCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => PostCategory.rescue,
      );
    } catch (_) {
      return PostCategory.rescue;
    }
  }

  Widget _buildStatItem(String count, String label, {bool isFlexible = false}) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          overflow: isFlexible ? TextOverflow.ellipsis : null,
          maxLines: isFlexible ? 1 : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get user details wrapper to provide data to both Header and Posts
    return StreamBuilder<DocumentSnapshot>(
      stream: _user != null
          ? _userRepository.getUserStream(_user!.uid)
          : const Stream.empty(),
      builder: (context, snapshot) {
        // Default values
        String displayName = _user?.displayName ?? 'Shopnil Karmakar';
        String? photoUrl = _user?.photoURL;
        String bio = "No bio yet.";
        String petInfo = "No pet info";
        int connectionsCount = 0;
        bool isVerified = false;

        // Parse data if available
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['displayName'] != null) displayName = data['displayName'];
          if (data['photoUrl'] != null) photoUrl = data['photoUrl'];
          if (data['bio'] != null && data['bio'].toString().isNotEmpty) {
            bio = data['bio'];
          }

          if (data['verifiedStatus'] == true ||
              _user?.email == 'shopnilmax@gmail.com') {
            isVerified = true;
          }

          if (data['petDetails'] != null) {
            final pet = data['petDetails'] as Map<String, dynamic>;
            petInfo =
                "${pet['name'] ?? 'Pet'} • ${pet['age'] ?? '?'} • ${pet['breed'] ?? 'Unknown'}";
          }

          if (data['connections'] != null) {
            connectionsCount = (data['connections'] as List).length;
          }
        }

        final String username =
            "@${displayName.replaceAll(' ', '').toLowerCase()}";

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header with gradient background
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6B46C1), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          children: [
                            // Top Bar (Menu)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Header Edit Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Personalize Header',
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).translate(
                                              'header_upload_coming_soon',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'logout') {
                                        _signOut();
                                      } else if (value == 'settings') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingsScreen(),
                                          ),
                                        );
                                      } else if (value == 'saved_items') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SavedPostsScreen(),
                                          ),
                                        );
                                      } else if (value == 'order_history') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const OrderHistoryScreen(),
                                          ),
                                        );
                                      } else if (value == 'become_merchant') {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Become a Merchant: Coming soon!',
                                            ),
                                          ),
                                        );
                                      } else if (value == 'verify_vet') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const VetVerificationScreen(),
                                          ),
                                        );
                                      } else if (value == 'clinics_near_me') {
                                        // Check Location Service Status
                                        bool isEnabled =
                                            await Geolocator.isLocationServiceEnabled();
                                        if (!isEnabled) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enable GPS to find nearby clinics.',
                                                ),
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ClinicsNearMeScreen(),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'clinics_near_me',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.local_hospital,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: const Text(
                                                'Clinics Near Me',
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'settings',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.settings,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('settings_title'),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'become_merchant',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.store,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: const Text(
                                                'Become a Merchant',
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'verify_vet',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.verified_user,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: const Text(
                                                'Get Verified as a Vet',
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'saved_items',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.bookmark_border,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('saved_items'),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'order_history',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.history,
                                                color: Color(0xFF6c7278),
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('order_history'),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          PopupMenuItem<String>(
                                            value: 'logout',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.logout,
                                                color: Colors.red,
                                              ),
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('logout'),
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                            ),

                            // Profile Info
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Profile Picture
                                      Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 4,
                                              ),
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: photoUrl != null
                                                  ? CachedNetworkImage(
                                                      imageUrl: photoUrl!,
                                                      fit: BoxFit.cover,
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Icon(
                                                            Icons.person,
                                                            size: 40,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: InkWell(
                                              onTap: () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      ).translate(
                                                        'dp_upload_coming_soon',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 16,
                                                  color: Color(0xFF6B46C1),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Name and Stats
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const VerifiedBadge(
                                                      size: 18,
                                                      baseColor: Colors.white,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  StreamBuilder<QuerySnapshot>(
                                                    stream: _postRepository
                                                        .getPostsByUserStream(
                                                          _user?.uid ?? '',
                                                        ),
                                                    builder:
                                                        (
                                                          context,
                                                          postSnapshot,
                                                        ) {
                                                          final count =
                                                              postSnapshot
                                                                  .hasData
                                                              ? postSnapshot
                                                                    .data!
                                                                    .docs
                                                                    .length
                                                              : 0;
                                                          return _buildStatItem(
                                                            count.toString(),
                                                            AppLocalizations.of(
                                                              context,
                                                            ).translate(
                                                              'posts',
                                                            ),
                                                          );
                                                        },
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Flexible(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ConnectionsScreen(),
                                                          ),
                                                        );
                                                      },
                                                      child: _buildStatItem(
                                                        connectionsCount
                                                            .toString(),
                                                        "Connections",
                                                        isFlexible: true,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (isVerified)
                                                    Image.asset(
                                                      'assets/images/verified_vet.png',
                                                      height: 40,
                                                      fit: BoxFit.contain,
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Bio Section
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bio,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.pets,
                                                      size: 14,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      petInfo,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.9,
                                                            ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: InkWell(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    builder: (context) =>
                                                        const EditProfileSheet(),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Posts Feed Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('posts'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: _user != null
                              ? _postRepository.getPostsByUserStream(_user!.uid)
                              : const Stream.empty(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return Text(
                              "$count ${AppLocalizations.of(context).translate('posts')}",
                              style: const TextStyle(color: Color(0xFF6c7278)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Posts Feed List
                StreamBuilder<QuerySnapshot>(
                  stream: _user != null
                      ? _postRepository.getPostsByUserStream(_user!.uid)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(child: Text('Error: ${snapshot.error}')),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final posts = snapshot.data?.docs ?? [];

                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No posts yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final postDoc = posts[index];
                        final post = postDoc.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          child: PostCard(
                            postId: postDoc.id,
                            userId: post['authorId'] ?? '',
                            userName: username,
                            userAvatarUrl: photoUrl ?? '',
                            timeAgo: post['createdAt'] != null
                                ? _getTimeAgo(
                                    (post['createdAt'] as Timestamp).toDate(),
                                    context,
                                  )
                                : 'Just now',
                            location: post['location'] ?? '',
                            category: _parseCategory(post['category']),
                            postContent: post['content'] ?? '',
                            isEdited: post['isEdited'] ?? false,
                            postImageUrl: post['imageUrl'] ?? '',
                            likes: (post['likes'] as List?)?.length ?? 0,
                            comments: post['commentsCount'] ?? 0,
                            isLiked:
                                (post['likes'] as List?)?.contains(
                                  FirebaseAuth.instance.currentUser?.uid,
                                ) ??
                                false,
                            raisedAmount:
                                (post['raisedAmount'] as num?)?.toDouble() ??
                                (post['currentAmount'] as num?)?.toDouble(),
                            goalAmount: (post['fundraiseGoal'] as num?)
                                ?.toDouble(),
                            donorCount:
                                (post['donorCount'] as num?)?.toInt() ?? 0,
                            isCompact: true,
                            isAuthorVerified: isVerified,
                            onLike: () async {
                              await _postRepository.toggleLike(postDoc.id);
                            },
                            onDelete: () => _handleDeletePost(postDoc.id),
                            onSave: () {
                              // Save functionality
                            },
                          ),
                        );
                      }, childCount: posts.length),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
