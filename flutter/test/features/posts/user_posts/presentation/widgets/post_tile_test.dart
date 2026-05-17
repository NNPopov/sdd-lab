import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/user_posts/presentation/widgets/post_tile.dart';
import 'package:flutter_test/flutter_test.dart';

final _post = Post(
  id: 1,
  title: 'Hello World',
  text: 'A' * 50,
  createdAt: DateTime(2024, 1, 15),
  createdByUserId: 42,
  postUuid: 'test-uuid',
  status: PostStatus.pendingReview,
);

Widget _wrap(Widget child) => TranslationProvider(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('PostTile', () {
    testWidgets('T-01: Open button shows open_in_new icon and label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(PostTile(post: _post, onOpenTap: () {})));

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('T-02: tap Open button calls onOpenTap exactly once', (
      tester,
    ) async {
      var calls = 0;

      await tester.pumpWidget(
        _wrap(PostTile(post: _post, onOpenTap: () => calls++)),
      );
      await tester.tap(find.byIcon(Icons.open_in_new));

      expect(calls, 1);
    });

    testWidgets('T-03: tap card body does not call onOpenTap', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        _wrap(PostTile(post: _post, onOpenTap: () => calls++)),
      );
      await tester.tap(find.text('Hello World'));

      expect(calls, 0);
    });
  });
}
