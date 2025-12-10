import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../create_post/repositories/post_repository.dart';
import '../../../services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

class Comment {
  String id;
  String userName;
  String userAvatarUrl;
  String content;
  DateTime timestamp;
  bool isCurrentUser;
  bool isEdited;

  Comment({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.timestamp,
    this.isCurrentUser = false,
    this.isEdited = false,
  });
}

class CommentBottomSheet extends StatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PostRepository _postRepository = PostRepository();
  final AuthService _authService = AuthService();

  String? _replyingToCommentId;
  String? _replyingToUserName;

  // Edit state
  String? _editingCommentId;
  String? _editingReplyId;
  String? _editingParentCommentId; // For replies

  final Set<String> _expandedComments = {};

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (_editingCommentId != null) {
        // Update Comment
        await _postRepository.updateComment(
          widget.postId,
          _editingCommentId!,
          text,
        );
        _cancelEdit();
      } else if (_editingReplyId != null && _editingParentCommentId != null) {
        // Update Reply
        await _postRepository.updateReply(
          widget.postId,
          _editingParentCommentId!,
          _editingReplyId!,
          text,
        );
        _cancelEdit();
      } else if (_replyingToCommentId != null) {
        // Add Reply
        // Capture locally to avoid race condition with setState
        final parentId = _replyingToCommentId!;

        await _postRepository.addReply(widget.postId, parentId, {
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'userAvatarUrl': user.photoURL ?? '',
          'content': text,
        });

        setState(() {
          _replyingToCommentId = null;
          _replyingToUserName = null;
          // Auto-expand the comment we just replied to
          _expandedComments.add(parentId);
        });
        _commentController.clear();
        _focusNode.unfocus();
      } else {
        // Add Comment
        await _postRepository.addComment(widget.postId, {
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'userAvatarUrl': user.photoURL ?? '',
          'content': text,
        });
        _commentController.clear();
        _focusNode.unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleReply(String commentId, String userName) {
    _cancelEdit(); // Cancel any active edit
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
    _focusNode.unfocus();
  }

  void _handleEditComment(Comment comment) {
    _cancelReply(); // Cancel any active reply
    setState(() {
      _editingCommentId = comment.id;
      _editingReplyId = null;
      _editingParentCommentId = null;
      _commentController.text = comment.content;
    });
    _focusNode.requestFocus();
  }

  void _handleEditReply(Comment reply, String parentCommentId) {
    _cancelReply(); // Cancel any active reply
    setState(() {
      _editingReplyId = reply.id;
      _editingParentCommentId = parentCommentId;
      _editingCommentId = null;
      _commentController.text = reply.content;
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editingReplyId = null;
      _editingParentCommentId = null;
      _commentController.clear();
    });
    _focusNode.unfocus();
  }

  Future<void> _handleDeleteComment(String commentId) async {
    try {
      await _postRepository.deleteComment(widget.postId, commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
      }
    }
  }

  Future<void> _handleDeleteReply(String commentId, String replyId) async {
    try {
      await _postRepository.deleteReply(widget.postId, commentId, replyId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting reply: $e')));
      }
    }
  }

  void _toggleReplies(String commentId) {
    setState(() {
      if (_expandedComments.contains(commentId)) {
        _expandedComments.remove(commentId);
      } else {
        _expandedComments.add(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = _editingCommentId != null || _editingReplyId != null;

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
            child: Center(
              child: Container(
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _postRepository.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).translate('no_comments_yet'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final comment = Comment(
                      id: comments[index].id,
                      userName: data['userName'] ?? 'Anonymous',
                      userAvatarUrl: data['userAvatarUrl'] ?? '',
                      content: data['content'] ?? '',
                      timestamp:
                          (data['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      isCurrentUser:
                          data['userId'] == _authService.currentUser?.uid,
                      isEdited: data['isEdited'] ?? false,
                    );
                    return _buildCommentItem(context, comment);
                  },
                );
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
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyingToCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Replying to ${_replyingToUserName ?? 'User'}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Editing comment',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _cancelEdit,
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          _authService.currentUser?.photoURL != null
                          ? CachedNetworkImageProvider(
                              _authService.currentUser!.photoURL!,
                            )
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: _authService.currentUser?.photoURL == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
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
                            hintText: _replyingToCommentId != null
                                ? 'Write a reply...'
                                : isEditing
                                ? 'Update comment...'
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
                        isEditing ? Icons.check_circle : Icons.send_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    final isExpanded = _expandedComments.contains(comment.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: comment.userAvatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(comment.userAvatarUrl)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: comment.userAvatarUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                                  height: 20,
                                  width: 20,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.more_horiz,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _handleEditComment(comment);
                                      } else if (value == 'delete') {
                                        _handleDeleteComment(comment.id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        height: 32,
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        height: 32,
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.red,
                                          ),
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
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (comment.isEdited)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '(edited)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                _handleReply(comment.id, comment.userName),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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

          // View/Hide Replies Button
          StreamBuilder<QuerySnapshot>(
            stream: _postRepository.getRepliesStream(widget.postId, comment.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              final replyCount = snapshot.data!.docs.length;

              return Padding(
                padding: const EdgeInsets.only(left: 56.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleReplies(comment.id),
                      child: Text(
                        isExpanded
                            ? 'Hide replies'
                            : 'View $replyCount replies',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final reply = Comment(
                              id: doc.id,
                              userName: data['userName'] ?? 'Anonymous',
                              userAvatarUrl: data['userAvatarUrl'] ?? '',
                              content: data['content'] ?? '',
                              timestamp:
                                  (data['timestamp'] as Timestamp?)?.toDate() ??
                                  DateTime.now(),
                              isCurrentUser:
                                  data['userId'] ==
                                  _authService.currentUser?.uid,
                              isEdited: data['isEdited'] ?? false,
                            );
                            return _buildReplyItem(context, reply, comment.id);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(
    BuildContext context,
    Comment reply,
    String parentCommentId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: reply.userAvatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(reply.userAvatarUrl)
                : null,
            backgroundColor: Colors.grey[200],
            child: reply.userAvatarUrl.isEmpty
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                        children: [
                          Text(
                            reply.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (reply.isCurrentUser)
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_horiz,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _handleEditReply(reply, parentCommentId);
                                  } else if (value == 'delete') {
                                    _handleDeleteReply(
                                      parentCommentId,
                                      reply.id,
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    height: 32,
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    height: 32,
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reply.content,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: Row(
                    children: [
                      Text(
                        _formatTimestamp(reply.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      if (reply.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            '(edited)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
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
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
