import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    required this.user,
    required this.onDetailsTap,
    required this.onPostsTap,
    super.key,
  });

  final User user;
  final VoidCallback onDetailsTap;
  final VoidCallback onPostsTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null
            ? Text(user.name[0].toUpperCase())
            : null,
      ),
      title: Text(user.name),
      subtitle: Text('@${user.username}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.person_outline),
            label: Text(t.users.list.userDetails),
            onPressed: onDetailsTap,
          ),
          TextButton.icon(
            icon: const Icon(Icons.article_outlined),
            label: Text(t.users.list.userPosts),
            onPressed: onPostsTap,
          ),
        ],
      ),
    );
  }
}
