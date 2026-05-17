import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/widgets/user_details_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

Widget _wrap(Widget child) => TranslationProvider(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('UserDetailsView', () {
    testWidgets(
      'T-01: Posts button shows article_outlined icon and "Posts" label',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            UserDetailsView(
              user: _user,
              tierLoading: false,
              onPostsTap: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.article_outlined), findsOneWidget);
        expect(find.text('Posts'), findsOneWidget);
      },
    );

    testWidgets('T-02: Tap on Posts button calls onPostsTap exactly once', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        _wrap(
          UserDetailsView(
            user: _user,
            tierLoading: false,
            onPostsTap: () => callCount++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.article_outlined));
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets('T-03: Divider is present between info rows and Posts button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          UserDetailsView(
            user: _user,
            tierLoading: false,
            onPostsTap: () {},
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);

      final dividerCenter = tester.getCenter(find.byType(Divider));
      final postsButtonCenter = tester.getCenter(
        find.byIcon(Icons.article_outlined),
      );
      final emailRowCenter = tester.getCenter(find.text('alice@example.com'));

      expect(dividerCenter.dy, greaterThan(emailRowCenter.dy));
      expect(postsButtonCenter.dy, greaterThan(dividerCenter.dy));
    });
  });
}
