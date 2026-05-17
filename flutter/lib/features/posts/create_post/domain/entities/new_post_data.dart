class NewPostData {
  const NewPostData({
    required this.username,
    required this.title,
    required this.text,
    this.mediaUrl,
  });

  final String username;
  final String title;
  final String text;
  final String? mediaUrl;
}
