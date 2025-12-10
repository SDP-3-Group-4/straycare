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
