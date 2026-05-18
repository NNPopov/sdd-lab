import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ModerationLogPanel extends StatelessWidget {
  const ModerationLogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<ModerationLogCubit, ModerationLogState>(
      builder: (context, state) => switch (state) {
        ModerationLogInitial() || ModerationLogLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        ModerationLogLoaded(:final entries) =>
          entries.isEmpty
              ? Center(child: Text(t.posts.editPost.log.empty))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _LogEntryTile(entry: entries[index]),
                ),
        ModerationLogError() => Center(
          child: Text(t.posts.editPost.log.loadError),
        ),
      },
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final ModerationLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final eventLabel = switch (entry.eventType) {
      ModerationEventType.moderatorReview =>
        t.posts.moderatePost.log.eventTypes.moderatorReview,
      ModerationEventType.authorRevision =>
        t.posts.moderatePost.log.eventTypes.authorRevision,
    };
    final actionLabel = switch (entry.action) {
      ModerationAction.approved => t.posts.moderatePost.log.actions.approved,
      ModerationAction.changesRequested =>
        t.posts.moderatePost.log.actions.changesRequested,
      null => null,
    };

    return ListTile(
      leading: const Icon(Icons.history),
      title: Row(
        children: [
          Text(entry.actorUsername ?? '', style: theme.textTheme.bodyMedium),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Chip(label: Text(actionLabel)),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$eventLabel · '
            '${DateFormat('d MMM yyyy, HH:mm').format(entry.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (entry.message != null) Text(entry.message!),
        ],
      ),
    );
  }
}
