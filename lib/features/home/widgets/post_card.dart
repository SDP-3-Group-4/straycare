import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../marketplace/models/marketplace_model.dart';
import '../../marketplace/models/marketplace_category.dart';
import '../../../shared/widgets/full_screen_image.dart';
import 'donation_progress.dart';
import 'donation_input_dialog.dart';
import 'comment_bottom_sheet.dart';
import 'user_profile_dialog.dart';
import '../../../../services/auth_service.dart';
import '../../../shared/widgets/verified_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../create_post/create_post_screen.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String userId;
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
  final bool isSaved;
  final VoidCallback? onSave;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final bool isCompact;
  final bool isAuthorVerified;
  final bool isEdited;

  const PostCard({
    Key? key,
    required this.postId,
    required this.userId,
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
    this.isSaved = false,
    this.onSave,
    this.isLiked = false,
    this.onLike,
    this.onDelete,
    this.isCompact = false,
    this.isAuthorVerified = false,
    this.isEdited = false,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Local state for optimistic UI updates
  late bool _isLiked;
  late int _currentLikes;
  late int _currentCommentCount;
  late bool _isSaved;

  // Fundraiser specific state
  late double _currentRaisedAmount;
  late int _currentDonorCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _currentLikes = widget.likes;
    _currentCommentCount = widget.comments;
    _isSaved = widget.isSaved;
    _currentRaisedAmount = widget.raisedAmount ?? 0;
    _currentDonorCount = widget.donorCount ?? 0;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
    if (oldWidget.likes != widget.likes) {
      _currentLikes = widget.likes;
    }
    if (oldWidget.comments != widget.comments) {
      _currentCommentCount = widget.comments;
    }
    if (oldWidget.isSaved != widget.isSaved) {
      _isSaved = widget.isSaved;
    }
    // Update fundraiser stats if widget updates from parent
    if (oldWidget.raisedAmount != widget.raisedAmount) {
      _currentRaisedAmount = widget.raisedAmount ?? 0;
    }
    if (oldWidget.donorCount != widget.donorCount) {
      _currentDonorCount = widget.donorCount ?? 0;
    }
  }

  Future<void> _refreshPostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _currentRaisedAmount =
              (data['raisedAmount'] as num?)?.toDouble() ??
              _currentRaisedAmount;
          _currentDonorCount =
              (data['donorCount'] as num?)?.toInt() ?? _currentDonorCount;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing post data: $e');
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(postId: widget.postId),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _currentLikes += _isLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  void _showDonationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => DonationInputDialog(
        postTitle: widget.postContent,
        fundraiserName: widget.userName,
        onDonate: (amount) async {
          // Create a temporary cart object for the donation
          final donationItem = _createDonationItem(amount);
          final cartItem = CartItem(
            id: 'donation_${DateTime.now().millisecondsSinceEpoch}',
            item: donationItem,
            quantity: 1,
            addedAt: DateTime.now(),
            metadata: {
              'postId': widget.postId, // Add postId to metadata
              'postTitle': widget.postContent,
              'postOwnerId': widget.userId,
            },
          );
          final cart = Cart(
            userId: 'user_current',
            items: [cartItem],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Wait for payment screen to close
          await Navigator.of(context).pushNamed('/payment', arguments: cart);

          // Refresh post data to check for updates
          if (mounted) {
            _refreshPostData();
          }
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
          isVerified: widget.isAuthorVerified,
          userId: widget.userId,
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
    final isMe = widget.userId == AuthService().currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        elevation: 0,
        margin: widget.isCompact ? EdgeInsets.zero : null,
        child: Padding(
          padding: widget.isCompact
              ? const EdgeInsets.all(10)
              : const EdgeInsets.all(16),
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
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                // Get live photo URL and display name or fall back to stored values
                                String photoUrl = widget.userAvatarUrl;
                                String displayName = widget.userName;
                                bool isVerified = widget.isAuthorVerified;

                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                  photoUrl =
                                      userData?['photoUrl'] ??
                                      widget.userAvatarUrl;
                                  displayName =
                                      userData?['displayName'] ??
                                      widget.userName;
                                  isVerified =
                                      userData?['verifiedStatus'] ??
                                      widget.isAuthorVerified;
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: photoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(photoUrl)
                                          : null,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.2),
                                      child: photoUrl.isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isVerified)
                                                const VerifiedBadge(size: 14),
                                            ],
                                          ),
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                widget.timeAgo,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (widget.isEdited) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(Edited)',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (widget.location.isNotEmpty)
                                            InkWell(
                                              onTap: () async {
                                                final query =
                                                    Uri.encodeComponent(
                                                      widget.location,
                                                    );
                                                final url = Uri.parse(
                                                  'https://www.google.com/maps/search/?api=1&query=$query',
                                                );
                                                try {
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(
                                                      url,
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                    'Error launching maps: \$e',
                                                  );
                                                }
                                              },
                                              child: Row(
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      widget.location,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      if (isMe && widget.onDelete != null)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              widget.onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.postImageUrl.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(
                                imageUrl: widget.postImageUrl,
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: widget.postImageUrl,
                          height: widget.isCompact ? 140 : 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: widget.isCompact ? 140 : 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: widget.isCompact ? 140 : 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Text(
                widget.postContent,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (isFundraise) ...[
                const SizedBox(height: 8),
                DonationProgress(
                  raised: _currentRaisedAmount,
                  goal: widget.goalAmount ?? 0,
                  donors: _currentDonorCount,
                  onDonate: (AuthService().currentUser?.uid == widget.userId)
                      ? null
                      : _showDonationDialog,
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
                  if (isMe)
                    TextButton.icon(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                      label: Text(
                        'Edit',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(
                              editPostData: {
                                'content': widget.postContent,
                                'imageUrl': widget.postImageUrl,
                                'category': widget.category.name,
                                'location': widget.location,
                                'fundraiseGoal': widget.goalAmount,
                                'paymentMethod': 'bank_transfer',
                              },
                              editPostId: widget.postId,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSaved = !_isSaved;
                        });
                        widget.onSave?.call();
                      },
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
