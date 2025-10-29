import 'package:flutter/material.dart';
import '../../shared/enums.dart'; // Import the shared enums

// --- SCREEN 1: HOME (FEED) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using CustomScrollView like draft for potential future sticky header
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 1, // Keep subtle elevation
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              // *** UPDATED TITLE TO USE LOGO ***
              title: Row(
                children: [
                  // Use Image.asset to load your logo
                  // Make sure your logo file is named 'logo.png' and placed in 'assets/images/'
                  Image.asset(
                    'assets/images/logo.png', // <-- Make sure this path matches your file
                    height: 32, // Adjust height as needed
                    // Add error handling for the logo itself
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.pets, // Fallback icon if logo fails to load
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            // SliverList for posts
            SliverList(
              delegate: SliverChildListDelegate(const [
                // Fake posts using the new PostCard style
                PostCard(
                  userName: 'Sabrina Tasnim Imu',
                  userAvatarUrl: 'https://picsum.photos/seed/sabrina/100/100',
                  timeAgo: '5m ago',
                  location: 'Near BUBT Campus, Dhaka',
                  category: PostCategory.rescue, // Use Enum
                  postContent:
                      'Found an injured dog near BUBT campus. Needs immediate help! It seems to have a broken leg.',
                  postImageUrl: 'https://picsum.photos/seed/dog/600/400',
                  likes: 15,
                  comments: 3,
                ),
                PostCard(
                  userName: 'Muzahidul Islam Joy',
                  userAvatarUrl: 'https://picsum.photos/seed/joy/100/100',
                  timeAgo: '1h ago',
                  location: 'Mirpur DOHS, Dhaka',
                  category: PostCategory.adoption, // Use Enum
                  postContent:
                      'Rescued 3 lovely kittens, fully vaccinated and dewormed. Looking for a forever home. They are very playful!',
                  postImageUrl: 'https://picsum.photos/seed/kittens/600/400',
                  likes: 42,
                  comments: 8,
                ),
                PostCard(
                  userName: 'Arpita Biswas',
                  userAvatarUrl: 'https://picsum.photos/seed/arpita/100/100',
                  timeAgo: '3h ago',
                  location: 'Dhaka',
                  category: PostCategory.fundraise, // Use Enum
                  postContent:
                      'Raising funds for "Happy Paws" shelter. We need to buy food and medicine for 50+ rescued animals for the winter.',
                  postImageUrl: 'https://picsum.photos/seed/shelter/600/400',
                  likes: 120,
                  comments: 15,
                ),
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      ),
    );
  }
}

// *** POST CARD WIDGET *** (Moved here from main.dart)
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
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  late int _currentLikes;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.likes;
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _currentLikes -= 1;
        _isLiked = false;
      } else {
        _currentLikes += 1;
        _isLiked = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.userAvatarUrl),
                    onBackgroundImageError: (_, __) => Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.2),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.category.color.withOpacity(0.15),
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(/* Loading indicator */);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(/* Error placeholder */);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.postContent,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton.icon(
                    icon: Icon(
                      _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                      size: 18,
                    ),
                    label: Text(
                      '$_currentLikes Likes',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    onPressed: _toggleLike,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  _buildInteractionButton(
                    context,
                    Icons.comment_outlined,
                    '${widget.comments} Comments',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
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

  Widget _buildInteractionButton(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}
