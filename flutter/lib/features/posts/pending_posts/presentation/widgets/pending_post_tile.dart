import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:intl/intl.dart';

class PendingPostTile extends StatelessWidget {
  const PendingPostTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final PendingPostItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.authorUsername} · '
                      '${DateFormat('d MMM yyyy').format(item.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Events',
                child: Chip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text('${item.moderationLog.length}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
