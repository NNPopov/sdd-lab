import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/users_screen.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/widgets/load_more_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersListCubit extends MockCubit<UsersListState>
    implements UsersListCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

Widget _wrap(Widget child, UsersListCubit listCubit) => TranslationProvider(
  child: MaterialApp(
    home: BlocProvider<UsersListCubit>.value(
      value: listCubit,
      child: child,
    ),
  ),
);

Widget _wrapWithRouter(
  Widget child,
  UsersListCubit listCubit,
  StackRouter router,
) => TranslationProvider(
  child: StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: BlocProvider<UsersListCubit>.value(
        value: listCubit,
        child: child,
      ),
    ),
  ),
);

const _users = [
  User(
    id: 1,
    name: 'Alice',
    username: 'alice',
    email: 'a@a.com',
    isModerator: false,
  ),
  User(
    id: 2,
    name: 'Bob',
    username: 'bob',
    email: 'b@b.com',
    isModerator: false,
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePageRouteInfo());
  });

  group('UsersScreen', () {
    late _MockUsersListCubit listCubit;

    setUp(() {
      listCubit = _MockUsersListCubit();
      when(() => listCubit.stream).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await listCubit.close();
    });

    Widget buildScreen() => _wrap(const UsersScreen(), listCubit);

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      when(() => listCubit.state).thenReturn(const UsersListState.loading());

      await tester.pumpWidget(buildScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ListView with tiles when loaded', (tester) async {
      when(() => listCubit.state).thenReturn(
        const UsersListState.loaded(users: _users, page: 1, hasMore: false),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows LoadMoreIndicator when loadMoreStatus is loading', (
      tester,
    ) async {
      when(() => listCubit.state).thenReturn(
        const UsersListState.loaded(
          users: _users,
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.byType(LoadMoreIndicator), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      when(
        () => listCubit.state,
      ).thenReturn(const UsersListState.error(Failure.network()));

      await tester.pumpWidget(buildScreen());

      expect(find.byType(FilledButton), findsOneWidget);
    });

    group('Navigation callbacks', () {
      late _MockStackRouter mockRouter;

      setUp(() {
        mockRouter = _MockStackRouter();
        when(() => mockRouter.push(any())).thenAnswer((_) async => null);
      });

      testWidgets('T-06: Details tap calls refresh after navigation returns', (
        tester,
      ) async {
        when(() => listCubit.state).thenReturn(
          const UsersListState.loaded(users: _users, page: 1, hasMore: false),
        );
        when(() => listCubit.refresh()).thenAnswer((_) async {});

        await tester.pumpWidget(
          _wrapWithRouter(const UsersScreen(), listCubit, mockRouter),
        );

        await tester.tap(find.byIcon(Icons.person_outline).first);
        await tester.pumpAndSettle();

        verify(() => listCubit.refresh()).called(1);
      });

      testWidgets('T-07: Posts tap does not call refresh', (tester) async {
        when(() => listCubit.state).thenReturn(
          const UsersListState.loaded(users: _users, page: 1, hasMore: false),
        );

        await tester.pumpWidget(
          _wrapWithRouter(const UsersScreen(), listCubit, mockRouter),
        );

        await tester.tap(find.byIcon(Icons.article_outlined).first);
        await tester.pumpAndSettle();

        verifyNever(() => listCubit.refresh());
      });
    });
  });
}
