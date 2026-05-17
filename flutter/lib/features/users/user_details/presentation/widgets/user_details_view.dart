import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:intl/intl.dart';

class UserDetailsView extends StatelessWidget {
  const UserDetailsView({
    required this.user,
    required this.tierLoading,
    required this.onPostsTap,
    this.tierName,
    this.tierCreatedAt,
    super.key,
  });

  final User user;
  final String? tierName;
  final DateTime? tierCreatedAt;
  final bool tierLoading;
  final VoidCallback onPostsTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: theme.textTheme.headlineLarge,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('@${user.username}', style: theme.textTheme.bodyLarge),
          if (user.isModerator) ...[
            const SizedBox(height: 8),
            Chip(label: Text(t.users.moderator.badge)),
          ],
          const SizedBox(height: 16),
          _InfoRow(label: t.users.details.email, value: user.email),
          if (tierLoading)
            _InfoRow(label: t.users.details.tier, value: t.common.loading)
          else if (tierName != null) ...[
            _InfoRow(label: t.users.details.tier, value: tierName!),
            if (tierCreatedAt != null)
              _InfoRow(
                label: t.users.details.tierSince,
                value: _formatDate(tierCreatedAt!),
              ),
          ],
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.article_outlined),
              label: Text(t.users.list.userPosts),
              onPressed: onPostsTap,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
