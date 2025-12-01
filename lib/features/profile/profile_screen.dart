import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:straycare_demo/features/auth/login_screen.dart';
import 'package:straycare_demo/features/settings/settings_screen.dart';
import 'package:straycare_demo/features/profile/widgets/edit_profile_sheet.dart';
import 'package:straycare_demo/services/auth_service.dart';
import 'package:straycare_demo/features/profile/vet_verification_screen.dart';
import 'package:straycare_demo/features/profile/screens/saved_posts_screen.dart';
import 'package:straycare_demo/features/profile/screens/order_history_screen.dart';

import '../../l10n/app_localizations.dart';

// --- SCREEN 5: PROFILE ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  User? _user;

  // Mock Data for Posts
  final List<Map<String, dynamic>> _posts = [
    {
      "id": "1",
      "image":
          "https://images.unsplash.com/photo-1650458766256-e438ef846ecd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBkb2clMjBjdXRlfGVufDF8fHx8MTc2NDIyNjE4MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      "caption":
          "Meet my new buddy! 🐕 Can't wait for all our adventures together. He's already stolen my heart and my favorite spot on the couch.",
      "likes": 342,
      "comments": 28,
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "id": "2",
      "image":
          "https://images.unsplash.com/photo-1668838289210-e7665d947145?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmb29kJTIwbWVhbHxlbnwxfHx8fDE3NjQyMTQ0NTZ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      "caption":
          "Sunday brunch done right 🥗✨ Living my best life one meal at a time. This place has the most amazing ambiance!",
      "likes": 456,
      "comments": 34,
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      "id": "3",
      "image":
          "https://images.unsplash.com/photo-1617634667039-8e4cb277ab46?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmUlMjBsYW5kc2NhcGV8ZW58MXx8fHwxNzY0MjY2OTQzfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      "caption":
          "Nature therapy 🌿 Sometimes you just need to disconnect and breathe. Found this hidden gem during my weekend hike.",
      "likes": 589,
      "comments": 42,
      "timestamp": DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      "id": "4",
      "image":
          "https://images.unsplash.com/photo-1650458766256-e438ef846ecd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXQlMjBkb2clMjBjdXRlfGVufDF8fHx8MTc2NDIyNjE4MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      "caption":
          "Throwback to the best decision I ever made. Life is so much better with a furry companion by your side. 🐾❤️",
      "likes": 234,
      "comments": 19,
      "timestamp": DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      "id": "5",
      "image":
          "https://images.unsplash.com/photo-1668838289210-e7665d947145?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmb29kJTIwbWVhbHxlbnwxfHx8fDE3NjQyMTQ0NTZ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
      "caption":
          "Experimenting with new recipes this week. Who knew cooking could be this therapeutic? 👨‍🍳",
      "likes": 178,
      "comments": 12,
      "timestamp": DateTime.now().subtract(const Duration(days: 7)),
    },
  ];

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

      if (!mounted) return;
      // Navigate to the login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
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

  void _handleDeletePost(String postId) {
    setState(() {
      _posts.removeWhere((post) => post['id'] == postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get user details, with fallbacks for safety
    final String displayName = _user?.displayName ?? 'Shopnil Karmakar';
    final String? photoUrl = _user?.photoURL;
    final String username = "@${displayName.replaceAll(' ', '').toLowerCase()}";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
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
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Personalize Header',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).translate('header_upload_coming_soon'),
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
                              onSelected: (value) {
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
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
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
                                        title: const Text('Become a Merchant'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: Colors.white.withOpacity(0.2),
                                          width: 4,
                                        ),
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      child: ClipOval(
                                        child: photoUrl != null
                                            ? Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Image.network(
                                                "https://images.unsplash.com/photo-1638996030249-abc99a735463?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMHBlcnNvbiUyMHBvcnRyYWl0fGVufDF8fHx8MTc2NDI3ODM3OXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
                                                fit: BoxFit.cover,
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
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
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
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
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
                                                  Text(
                                                    username,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            _buildStatItem(
                                              _posts.length.toString(),
                                              AppLocalizations.of(
                                                context,
                                              ).translate('posts'),
                                            ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: _buildStatItem(
                                                "1234",
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('followers'),
                                                isFlexible: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Product designer passionate about creating intuitive experiences 🎨✨",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.pets,
                                                size: 14,
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Calvin • 5 yrs • Formosan Mountain Dog",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
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
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
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
                  Text(
                    "${_posts.length} ${AppLocalizations.of(context).translate('posts')}",
                    style: const TextStyle(color: Color(0xFF6c7278)),
                  ),
                ],
              ),
            ),
          ),

          // Posts Feed List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = _posts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFe4e5e7).withOpacity(0.24),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Color(0xFF6B46C1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _handleDeletePost(post['id']),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Color(0xFF6c7278),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post['caption'],
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildActionIcon(
                                  Icons.thumb_up_outlined,
                                  post['likes'].toString(),
                                ),
                                const SizedBox(width: 16),
                                _buildActionIcon(
                                  Icons.comment_outlined,
                                  post['comments'].toString(),
                                ),
                                const Spacer(),
                                Text(
                                  _getTimeAgo(
                                    post['timestamp'] as DateTime,
                                    context,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFacb5bb),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post['image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: _posts.length),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {bool isFlexible = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          overflow: isFlexible ? TextOverflow.ellipsis : null,
          maxLines: isFlexible ? 1 : null,
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6c7278)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6c7278), fontSize: 13),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime time, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(time);
    final localizations = AppLocalizations.of(context);

    if (difference.inSeconds < 60) {
      return localizations.translate('just_now');
    } else if (difference.inMinutes < 60) {
      return localizations
          .translate('x_minutes_ago')
          .replaceAll('{count}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return localizations
          .translate('x_hours_ago')
          .replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return localizations
          .translate('x_days_ago')
          .replaceAll('{count}', difference.inDays.toString());
    } else {
      return localizations
          .translate('x_weeks_ago')
          .replaceAll('{count}', (difference.inDays / 7).floor().toString());
    }
  }
}
