import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:intl/intl.dart';

class ListPostTile extends StatelessWidget {
  const ListPostTile({
    required this.post,
    required this.onOpenTap,
    super.key,
  });

  final Post post;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.username ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(_stripMarkdown(post.text)),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy').format(post.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(context.t.posts.listPosts.openPost),
                onPressed: onOpenTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stripMarkdown(String text) {
  final stripped = text
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*', dotAll: true),
        (m) => m[1] ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\*(.+?)\*', dotAll: true),
        (m) => m[1] ?? '',
      )
      .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
      .replaceAllMapped(
        RegExp(r'\[(.+?)\]\(.+?\)', dotAll: true),
        (m) => m[1] ?? '',
      )
      .replaceAll(RegExp('`+.+?`+', dotAll: true), '')
      .replaceAll(RegExp('\n+'), ' ')
      .trim();
  return stripped.length > 100 ? '${stripped.substring(0, 100)}...' : stripped;
}
