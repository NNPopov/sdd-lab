import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';

class PostContentView extends StatelessWidget {
  const PostContentView({required this.post, super.key});

  final PendingPostItem post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title, style: theme.textTheme.headlineSmall),
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            Image.network(post.mediaUrl!),
          ],
          const SizedBox(height: 12),
          Text(post.text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
