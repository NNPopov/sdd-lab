class NewPostData {
  const NewPostData({
    required this.userId,
    required this.title,
    required this.text,
    this.mediaUrl,
  });

  final int userId;
  final String title;
  final String text;
  final String? mediaUrl;
}
