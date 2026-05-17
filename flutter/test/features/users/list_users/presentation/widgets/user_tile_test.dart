import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/widgets/user_tile.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'a@a.com',
  isModerator: false,
);

Widget _wrap(Widget child) => TranslationProvider(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('UserTile', () {
    testWidgets('T-01: tap Details calls onDetailsTap only', (tester) async {
      var detailsCalls = 0;
      var postsCalls = 0;

      await tester.pumpWidget(
        _wrap(
          UserTile(
            user: _user,
            onDetailsTap: () => detailsCalls++,
            onPostsTap: () => postsCalls++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.person_outline));
      expect(detailsCalls, 1);
      expect(postsCalls, 0);
    });

    testWidgets('T-02: tap Posts calls onPostsTap only', (tester) async {
      var detailsCalls = 0;
      var postsCalls = 0;

      await tester.pumpWidget(
        _wrap(
          UserTile(
            user: _user,
            onDetailsTap: () => detailsCalls++,
            onPostsTap: () => postsCalls++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.article_outlined));
      expect(postsCalls, 1);
      expect(detailsCalls, 0);
    });

    testWidgets('T-03: tap tile body triggers no callbacks', (tester) async {
      var detailsCalls = 0;
      var postsCalls = 0;

      await tester.pumpWidget(
        _wrap(
          UserTile(
            user: _user,
            onDetailsTap: () => detailsCalls++,
            onPostsTap: () => postsCalls++,
          ),
        ),
      );

      await tester.tap(find.text('Alice'));
      expect(detailsCalls, 0);
      expect(postsCalls, 0);
    });

    testWidgets('T-04: Details button has person_outline icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UserTile(
            user: _user,
            onDetailsTap: () {},
            onPostsTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('T-05: Posts button has article_outlined icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UserTile(
            user: _user,
            onDetailsTap: () {},
            onPostsTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });
  });
}
