import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../../shared/enums.dart';
import '../marketplace/models/marketplace_category.dart';
import '../marketplace/models/marketplace_model.dart';

import '../notifications/notifications_screen.dart';
import '../create_post/create_post_screen.dart';
import '../../l10n/app_localizations.dart';

// --- HOME FEED SCREEN (MERGED) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Mock Data with Coordinates (Dhaka)
  final List<_PostData> _allPosts = [
    _PostData(
      userName: 'Sabrina Tasnim Imu',
      userAvatarUrl: 'https://picsum.photos/seed/sabrina/100/100',
      timeAgo: '5m ago',
      location: 'Near BUBT Campus, Dhaka',
      latitude: 23.8151,
      longitude: 90.3654,
      category: PostCategory.rescue,
      postContent:
          'Found an injured dog near BUBT campus. Needs immediate help! It seems to have a broken leg.',
      postImageUrl: 'https://picsum.photos/seed/dog/600/400',
      likes: 15,
      comments: 3,
    ),
    _PostData(
      userName: 'Muzahidul Islam Joy',
      userAvatarUrl: 'https://picsum.photos/seed/joy/100/100',
      timeAgo: '1h ago',
      location: 'Mirpur DOHS, Dhaka',
      latitude: 23.8365,
      longitude: 90.3695,
      category: PostCategory.adoption,
      postContent:
          'Rescued 3 lovely kittens, fully vaccinated and dewormed. Looking for a forever home. They are very playful!',
      postImageUrl: 'https://picsum.photos/seed/kittens/600/400',
      likes: 42,
      comments: 8,
    ),
    _PostData(
      userName: 'Arpita Biswas',
      userAvatarUrl: 'https://picsum.photos/seed/arpita/100/100',
      timeAgo: '3h ago',
      location: 'Dhaka',
      latitude: 23.8103,
      longitude: 90.4125,
      category: PostCategory.fundraise,
      postContent:
          'Raising funds for "Happy Paws" shelter. We need to buy food and medicine for 50+ rescued animals for the winter.',
      postImageUrl: 'https://picsum.photos/seed/shelter/600/400',
      likes: 120,
      comments: 15,
      raisedAmount: 4200.0,
      goalAmount: 10000.0,
      donorCount: 124,
    ),
  ];

  List<_PostData> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _filteredPosts = _allPosts;
  }

  Future<void> _handleToggle(int index) async {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
        _filteredPosts = _allPosts;
      });
    } else {
      setState(() {
        _selectedIndex = 1;
        _isLoading = true;
      });
      await _filterByLocation();
    }
  }

  Future<void> _filterByLocation() async {
    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        // Permission denied or service disabled, revert to Explore
        setState(() {
          _selectedIndex = 0;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        // Filter posts within 5km (5000 meters)
        _filteredPosts = _allPosts.where((post) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            post.latitude,
            post.longitude,
          );
          return distance <= 5000; // 5km radius
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedIndex = 0; // Revert on error
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location from device settings.'),
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 1,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.pets,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.edit_square,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  tooltip: 'Create Post',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
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
                    selectedIndex: _selectedIndex,
                    onTap: _handleToggle,
                  ),
                ),
              ),
            ),

            // // --- Categories Header ---
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            //     child: Text(
            //       AppLocalizations.of(context).translate('categories'),
            //       style: Theme.of(
            //         context,
            //       ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            //     ),
            //   ),
            // ),

            // --- Feed Posts ---
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredPosts.isEmpty)
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      if (_selectedIndex == 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: () => _handleToggle(0),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('back_to_explore'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = _filteredPosts[index];
                  return PostCard(
                    userName: post.userName,
                    userAvatarUrl: post.userAvatarUrl,
                    timeAgo: post.timeAgo,
                    location: post.location,
                    category: post.category,
                    postContent: post.postContent,
                    postImageUrl: post.postImageUrl,
                    likes: post.likes,
                    comments: post.comments,
                    raisedAmount: post.raisedAmount,
                    goalAmount: post.goalAmount,
                    donorCount: post.donorCount,
                  );
                }, childCount: _filteredPosts.length),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostData {
  final String userName;
  final String userAvatarUrl;
  final String timeAgo;
  final String location;
  final double latitude;
  final double longitude;
  final PostCategory category;
  final String postContent;
  final String postImageUrl;
  final int likes;
  final int comments;
  final double? raisedAmount;
  final double? goalAmount;
  final int? donorCount;

  _PostData({
    required this.userName,
    required this.userAvatarUrl,
    required this.timeAgo,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.postContent,
    required this.postImageUrl,
    required this.likes,
    required this.comments,
    this.raisedAmount,
    this.goalAmount,
    this.donorCount,
  });
}

//
// --- POST CARD WIDGET ---
//
class PostCard extends StatefulWidget {
  final String userName;
  final String userAvatarUrl;
  final String timeAgo;
  final String location;
  final PostCategory category;
  final String postContent;
  final String postImageUrl;
  final int likes;
  final int comments;
  final double? raisedAmount;
  final double? goalAmount;
  final int? donorCount;

  const PostCard({
    Key? key,
    required this.userName,
    required this.userAvatarUrl,
    required this.timeAgo,
    required this.location,
    required this.category,
    required this.postContent,
    required this.postImageUrl,
    required this.likes,
    required this.comments,
    this.raisedAmount,
    this.goalAmount,
    this.donorCount,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  late int _currentLikes;
  late int _currentCommentCount;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.likes;
    _currentCommentCount = widget.comments;
    _initializeComments();
  }

  void _initializeComments() {
    // Mock comments
    _comments = [
      Comment(
        id: '1',
        userName: 'Jane Doe',
        userAvatarUrl: 'https://picsum.photos/seed/jane/100/100',
        content: 'This is amazing! God bless you.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Comment(
        id: '2',
        userName: 'John Smith',
        userAvatarUrl: 'https://picsum.photos/seed/john/100/100',
        content: 'I can help with transport if needed.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        comments: _comments,
        onAddComment: (comment) {
          setState(() {
            _comments.add(comment);
            _currentCommentCount++;
          });
        },
        onEditComment: (id, content) {
          setState(() {
            final index = _comments.indexWhere((c) => c.id == id);
            if (index != -1) {
              _comments[index].content = content;
            }
          });
        },
        onDeleteComment: (id) {
          setState(() {
            _comments.removeWhere((c) => c.id == id);
            _currentCommentCount--;
          });
        },
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _currentLikes += _isLiked ? 1 : -1;
    });
  }

  void _showDonationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => DonationInputDialog(
        postTitle: widget.postContent,
        fundraiserName: widget.userName,
        onDonate: (amount) {
          // Create a temporary cart object for the donation
          final donationItem = _createDonationItem(amount);
          final cartItem = CartItem(
            id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
            item: donationItem,
            quantity: 1,
            addedAt: DateTime.now(),
          );
          final cart = Cart(
            userId: 'user_current',
            items: [cartItem],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          Navigator.of(context).pushNamed('/payment', arguments: cart);
        },
      ),
    );
  }

  void _showUserProfile() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'User Profile',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserProfileDialog(
          userName: widget.userName,
          userAvatarUrl: widget.userAvatarUrl,
          isVerified: widget.category == PostCategory.rescue, // Mock logic
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFundraise = widget.category == PostCategory.fundraise;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showUserProfile,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                widget.userAvatarUrl,
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.timeAgo,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (widget.location.isNotEmpty)
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.location,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          widget.category.icon,
                          size: 16,
                          color: widget.category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.category.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.postImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.postContent,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (isFundraise) ...[
                const SizedBox(height: 8),
                DonationProgress(
                  raised: widget.raisedAmount ?? 0,
                  goal: widget.goalAmount ?? 0,
                  donors: widget.donorCount ?? 0,
                  onDonate: _showDonationDialog,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton.icon(
                    icon: Icon(
                      _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    label: Text(
                      '$_currentLikes ${AppLocalizations.of(context).translate('likes')}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    onPressed: _toggleLike,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.comment_outlined,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    label: Text(
                      '$_currentCommentCount ${AppLocalizations.of(context).translate('comments')}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    onPressed: _showCommentSheet,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_border,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  MarketplaceItem _createDonationItem(double amount) {
    return MarketplaceItem(
      id: 'donation_${widget.userName}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Donation for "${widget.postContent}"',
      description:
          'A generous donation to support the fundraising post by ${widget.userName}.',
      price: amount,
      currency: 'BDT',
      imageUrl: widget.postImageUrl,
      seller: widget.userName,
      category: MarketplaceCategory.donation, // Using a new category
      rating: 0,
      reviews: 0,
      inStock: true,
      stockCount: 1,
      features: [
        'One-time donation',
        'Supports animal welfare',
        '100% of this goes to the cause',
      ],
      deliveryTime: 'N/A',
    );
  }
}

//
// --- DONATION PROGRESS ---
//
class DonationProgress extends StatelessWidget {
  final double raised;
  final double goal;
  final int donors;
  final VoidCallback onDonate;

  const DonationProgress({
    Key? key,
    required this.raised,
    required this.goal,
    required this.onDonate,
    this.donors = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (goal <= 0) ? 0.0 : (raised / goal).clamp(0.0, 1.0);
    final percentLabel = (percent * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '৳${raised.toStringAsFixed(2)} ${AppLocalizations.of(context).translate('raised')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context).translate('goal')}: ৳${goal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: onDonate,
              child: Text(AppLocalizations.of(context).translate('donate')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            LinearProgressIndicator(
              value: percent,
              minHeight: 26,
              borderRadius: BorderRadius.circular(15),
              backgroundColor: Colors.grey.shade300,
            ),
            Positioned.fill(child: Center(child: Text('$percentLabel%'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.flag, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text('৳${raised.toStringAsFixed(0)} / ৳${goal.toStringAsFixed(0)}'),
            const Spacer(),
            Icon(Icons.people, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text('$donors ${AppLocalizations.of(context).translate('donors')}'),
          ],
        ),
      ],
    );
  }
}

//
// --- DONATION INPUT DIALOG ---
//
class DonationInputDialog extends StatefulWidget {
  final String postTitle;
  final String fundraiserName;
  final Function(double) onDonate;

  const DonationInputDialog({
    Key? key,
    required this.postTitle,
    required this.fundraiserName,
    required this.onDonate,
  }) : super(key: key);

  @override
  _DonationInputDialogState createState() => _DonationInputDialogState();
}

class _DonationInputDialogState extends State<DonationInputDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount > 0) {
        Navigator.of(context).pop(); // Pop first
        widget.onDonate(amount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('donate'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorated Box for Fundraiser Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Donating to ${widget.fundraiserName}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Payment Method: bKash / Card",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).translate('enter_donation_amount'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(AppLocalizations.of(context).translate('donate')),
        ),
      ],
    );
  }
}

//
// --- SLIDING CHIP TOGGLE ---
//
class SlidingChipToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const SlidingChipToggle({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final selectedColor = isDark ? theme.cardColor : Colors.white;
    final unselectedIconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 45,
        width: screenWidth * 0.6,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _buildOption(
                  context,
                  title: AppLocalizations.of(context).translate('explore'),
                  icon: Icons.explore,
                  index: 0,
                  isSelected: selectedIndex == 0,
                  primaryColor: primaryColor,
                  unselectedColor: unselectedIconColor ?? Colors.grey,
                ),
                _buildOption(
                  context,
                  title: AppLocalizations.of(context).translate('near_me'),
                  icon: Icons.near_me,
                  index: 1,
                  isSelected: selectedIndex == 1,
                  primaryColor: primaryColor,
                  unselectedColor: unselectedIconColor ?? Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
    required Color primaryColor,
    required Color unselectedColor,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => onTap(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryColor : unselectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? primaryColor : unselectedColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// --- COMMENT MODEL ---
//
class Comment {
  String id;
  String userName;
  String userAvatarUrl;
  String content;
  DateTime timestamp;
  bool isCurrentUser;

  Comment({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.timestamp,
    this.isCurrentUser = false,
  });
}

//
// --- COMMENT BOTTOM SHEET ---
//
class CommentBottomSheet extends StatefulWidget {
  final List<Comment> comments;
  final Function(Comment) onAddComment;
  final Function(String, String) onEditComment;
  final Function(String) onDeleteComment;

  const CommentBottomSheet({
    Key? key,
    required this.comments,
    required this.onAddComment,
    required this.onEditComment,
    required this.onDeleteComment,
  }) : super(key: key);

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _editingCommentId;
  late List<Comment> _localComments;

  @override
  void initState() {
    super.initState();
    _localComments = List.from(widget.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_editingCommentId != null) {
      setState(() {
        final index = _localComments.indexWhere(
          (c) => c.id == _editingCommentId,
        );
        if (index != -1) {
          _localComments[index].content = text;
        }
      });
      widget.onEditComment(_editingCommentId!, text);
      _editingCommentId = null;
    } else {
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userName: 'You',
        userAvatarUrl: 'https://picsum.photos/seed/user/100/100',
        content: text,
        timestamp: DateTime.now(),
        isCurrentUser: true,
      );
      setState(() {
        _localComments.add(newComment);
      });
      widget.onAddComment(newComment);
    }

    _commentController.clear();
    _focusNode.unfocus();
  }

  void _startEditing(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
      _focusNode.requestFocus();
    });
  }

  void _deleteComment(String id) {
    setState(() {
      _localComments.removeWhere((c) => c.id == id);
    });
    widget.onDeleteComment(id);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            // decoration: BoxDecoration(
            //   border: Border(
            //     bottom: BorderSide(
            //       color: const Color.fromARGB(
            //         255,
            //         167,
            //         21,
            //         21,
            //       ).withOpacity(0.2),
            //     ),
            //   ),
            // ),
            child: Center(
              child: Container(
                //add padding
                //padding: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 1.2,
              bottom: 16.0,
            ),
            child: Text(
              AppLocalizations.of(context).translate('comments'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _localComments.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).translate('no_comments_yet'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _localComments.length,
                    itemBuilder: (context, index) {
                      final comment = _localComments[index];
                      return _buildCommentItem(context, comment);
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + bottomInset,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage(
                    'https://picsum.photos/seed/user/100/100',
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: _editingCommentId != null
                            ? AppLocalizations.of(
                                context,
                              ).translate('edit_comment_hint')
                            : AppLocalizations.of(
                                context,
                              ).translate('leave_comment_hint'),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(comment.userAvatarUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.isCurrentUser)
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _startEditing(comment);
                              } else if (value == 'delete') {
                                _deleteComment(comment.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                height: 32,
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).translate('edit'),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                height: 32,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).translate('delete'),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileDialog extends StatelessWidget {
  final String userName;
  final String userAvatarUrl;
  final String userBio;
  final int postsCount;
  final int connectionsCount;
  final bool isVerified;

  const UserProfileDialog({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    this.userBio = "Pet lover & enthusiast 🐾",
    this.postsCount = 12,
    this.connectionsCount = 154,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
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
                        backgroundImage: NetworkImage(userAvatarUrl),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name & Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${userName.replaceAll(' ', '').toLowerCase()}",
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
                      child: Text(
                        userBio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem("Posts", postsCount.toString()),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          "Connections",
                          connectionsCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Connect Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement connect logic
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Connection request sent!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_add,
                          color: Color(0xFF6B46C1),
                        ),
                        label: const Text(
                          "Connect",
                          style: TextStyle(
                            color: Color(0xFF6B46C1),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
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
