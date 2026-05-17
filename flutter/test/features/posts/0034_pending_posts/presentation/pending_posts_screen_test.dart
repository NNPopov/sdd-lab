import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_state.dart';
import 'package:flutter_application_1/features/posts/pending_posts/presentation/pending_posts_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPendingPostsCubit extends MockCubit<PendingPostsState>
    implements PendingPostsCubit {}

PendingPostItem _item({
  String postUuid = 'uuid-1',
  String title = 'Post Title',
}) => PendingPostItem(
  postUuid: postUuid,
  title: title,
  text: 'Body.',
  status: PostStatus.pendingReview,
  createdAt: DateTime(2026, 5, 16),
  updatedAt: DateTime(2026, 5, 16),
  authorUsername: 'alice',
  moderationLog: const [],
);

Widget _wrap(_MockPendingPostsCubit cubit) => TranslationProvider(
  child: MaterialApp(
    home: BlocProvider<PendingPostsCubit>.value(
      value: cubit,
      child: const PendingPostsScreen(),
    ),
  ),
);

void main() {
  late _MockPendingPostsCubit cubit;

  setUp(() {
    cubit = _MockPendingPostsCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.loadMore()).thenAnswer((_) async {});
  });

  tearDown(() async => cubit.close());

  testWidgets('state=loading shows CircularProgressIndicator', (tester) async {
    when(() => cubit.state).thenReturn(const PendingPostsState.loading());

    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'state=loaded empty list shows empty-state text',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const PendingPostsState.loaded(
          items: [],
          page: 1,
          hasMore: false,
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('No pending posts'), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded with one item shows item title',
    (tester) async {
      when(() => cubit.state).thenReturn(
        PendingPostsState.loaded(
          items: [_item(title: 'Visible Post Title')],
          page: 1,
          hasMore: false,
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Visible Post Title'), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded with loadMoreStatus.loading shows spinner at bottom',
    (tester) async {
      when(() => cubit.state).thenReturn(
        PendingPostsState.loaded(
          items: [_item()],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded with loadMoreStatus.error shows retry, tap calls loadMore',
    (tester) async {
      when(() => cubit.state).thenReturn(
        PendingPostsState.loaded(
          items: [_item()],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: const Failure.network(),
        ),
      );

      await tester.pumpWidget(_wrap(cubit));
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      verify(() => cubit.loadMore()).called(greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'state=error shows error text and Retry FilledButton, tap calls load',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const PendingPostsState.error(Failure.network()),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Failed to load pending posts'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => cubit.load()).called(greaterThanOrEqualTo(1));
    },
  );
}
