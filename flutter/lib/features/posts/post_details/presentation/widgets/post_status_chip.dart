import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

class PostStatusChip extends StatelessWidget {
  const PostStatusChip({required this.status, super.key});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bg, fg) = switch (status) {
      PostStatus.pendingReview => (
        t.posts.postStatus.pendingReview,
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      PostStatus.approved => (
        t.posts.postStatus.approved,
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      PostStatus.changesRequested => (
        t.posts.postStatus.changesRequested,
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: fg)),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }
}
