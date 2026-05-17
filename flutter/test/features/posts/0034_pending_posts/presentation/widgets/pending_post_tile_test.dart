import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/presentation/widgets/pending_post_tile.dart';
import 'package:flutter_test/flutter_test.dart';

ModerationLogEntry _logEntry(int id) => ModerationLogEntry(
  id: id,
  eventType: ModerationEventType.moderatorReview,
  createdAt: DateTime(2026),
  actorUserId: 1,
  actorUsername: 'mod',
);

PendingPostItem _item({
  String title = 'Default Title',
  String authorUsername = 'alice',
  DateTime? createdAt,
  int logCount = 0,
}) => PendingPostItem(
  postUuid: 'test-uuid',
  title: title,
  text: 'Body.',
  status: PostStatus.pendingReview,
  createdAt: createdAt ?? DateTime(2026, 5, 16),
  updatedAt: DateTime(2026, 5, 16),
  authorUsername: authorUsername,
  moderationLog: List.generate(logCount, _logEntry),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders item.title', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PendingPostTile(
          item: _item(title: 'My Pending Post'),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('My Pending Post'), findsOneWidget);
  });

  testWidgets('renders item.authorUsername', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PendingPostTile(
          item: _item(authorUsername: 'charlie'),
          onTap: () {},
        ),
      ),
    );
    expect(find.textContaining('charlie'), findsOneWidget);
  });

  testWidgets('renders formatted createdAt (d MMM yyyy)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PendingPostTile(
          item: _item(createdAt: DateTime(2026, 5, 16)),
          onTap: () {},
        ),
      ),
    );
    expect(find.textContaining('16 May 2026'), findsOneWidget);
  });

  testWidgets('renders moderation log count in chip', (tester) async {
    await tester.pumpWidget(
      _wrap(PendingPostTile(item: _item(logCount: 3), onTap: () {})),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('onTap callback is invoked when tile is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        PendingPostTile(
          item: _item(title: 'Tappable Title'),
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('Tappable Title'));
    expect(tapped, isTrue);
  });
}
