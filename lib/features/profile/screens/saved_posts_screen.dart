import 'package:flutter/material.dart';
import '../../../shared/enums.dart';
import '../../home/home_screen.dart';
import '../../../l10n/app_localizations.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  // Mock Data for Saved Posts
  final List<Map<String, dynamic>> _savedPosts = [
    {
      'userName': 'Sabrina Tasnim Imu',
      'userAvatarUrl': 'https://picsum.photos/seed/sabrina/100/100',
      'timeAgo': '2d ago',
      'location': 'Near BUBT Campus, Dhaka',
      'category': PostCategory.rescue,
      'postContent':
          'Found an injured dog near BUBT campus. Needs immediate help! It seems to have a broken leg.',
      'postImageUrl': 'https://picsum.photos/seed/dog/600/400',
      'likes': 15,
      'comments': 3,
    },
    {
      'userName': 'Arpita Biswas',
      'userAvatarUrl': 'https://picsum.photos/seed/arpita/100/100',
      'timeAgo': '1w ago',
      'location': 'Dhaka',
      'category': PostCategory.fundraise,
      'postContent':
          'Raising funds for "Happy Paws" shelter. We need to buy food and medicine for 50+ rescued animals for the winter.',
      'postImageUrl': 'https://picsum.photos/seed/shelter/600/400',
      'likes': 120,
      'comments': 15,
      'raisedAmount': 4200.0,
      'goalAmount': 10000.0,
      'donorCount': 124,
    },
  ];

  void _handleRemove(int index) {
    setState(() {
      _savedPosts.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Removed from saved items')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('saved_items')),
        centerTitle: true,
      ),
      body: _savedPosts.isEmpty
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
                return PostCard(
                  key: ValueKey(post['postContent']),
                  userName: post['userName'],
                  userAvatarUrl: post['userAvatarUrl'],
                  timeAgo: post['timeAgo'],
                  location: post['location'],
                  category: post['category'],
                  postContent: post['postContent'],
                  postImageUrl: post['postImageUrl'],
                  likes: post['likes'],
                  comments: post['comments'],
                  raisedAmount: post['raisedAmount'],
                  goalAmount: post['goalAmount'],
                  donorCount: post['donorCount'],
                  isSaved: true,
                  onSave: () => _handleRemove(index),
                );
              },
            ),
    );
  }
}
