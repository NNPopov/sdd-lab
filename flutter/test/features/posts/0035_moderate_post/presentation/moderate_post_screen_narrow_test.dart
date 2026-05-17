import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/moderate_post_screen.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/moderation_panel.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/post_content_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockModeratePostCubit extends MockCubit<ModeratePostState>
    implements ModeratePostCubit {}

class _MockModerationLogCubit extends MockCubit<ModerationLogState>
    implements ModerationLogCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

final _post = PendingPostItem(
  postUuid: 'post-uuid-1',
  title: 'Test Post',
  text: 'Body text',
  status: PostStatus.pendingReview,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  authorUsername: 'author1',
  moderationLog: const [],
);

void main() {
  late _MockModeratePostCubit moderateCubit;
  late _MockModerationLogCubit logCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  setUp(() {
    moderateCubit = _MockModeratePostCubit();
    logCubit = _MockModerationLogCubit();
    mockRouter = _MockStackRouter();

    when(() => moderateCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => logCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => moderateCubit.state).thenReturn(
      const ModeratePostState.initial(),
    );
    when(() => logCubit.state).thenReturn(
      const ModerationLogState.initial(),
    );
    when(() => mockRouter.pop()).thenAnswer((_) async => true);
    when(() => logCubit.load(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await moderateCubit.close();
    await logCubit.close();
  });

  Widget buildNarrow() {
    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: mockRouter,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ModeratePostCubit>.value(value: moderateCubit),
                BlocProvider<ModerationLogCubit>.value(value: logCubit),
              ],
              child: ModeratePostScreen(
                postUuid: 'post-uuid-1',
                post: _post,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'narrow: Post tab visible initially, Moderation tab not rendered',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildNarrow());
      await tester.pump();

      expect(find.byType(PostContentView), findsOneWidget);
      expect(find.byType(ModerationPanel), findsNothing);
    },
  );

  testWidgets(
    'narrow: tapping Moderation tab shows ModerationPanel and calls load',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildNarrow());
      await tester.pump();

      await tester.tap(find.text('Moderation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ModerationPanel), findsOneWidget);
      verify(() => logCubit.load('post-uuid-1')).called(1);
    },
  );

  testWidgets(
    'narrow: ModerationLogCubit.load() not called on initial render',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildNarrow());
      await tester.pump();

      verifyNever(() => logCubit.load(any()));
    },
  );

  testWidgets('narrow: switching tabs twice calls load only once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Simulate state changing to loaded after load() is called.
    const stateAfterLoad = ModerationLogState.loaded([]);
    when(() => logCubit.load(any())).thenAnswer((_) async {
      when(() => logCubit.state).thenReturn(stateAfterLoad);
    });

    await tester.pumpWidget(buildNarrow());
    await tester.pump();

    // First tap → load should be called.
    await tester.tap(find.text('Moderation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Go back to Post tab.
    await tester.tap(find.text('Post'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Second tap → load should NOT be called again (state is loaded).
    await tester.tap(find.text('Moderation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => logCubit.load(any())).called(1);
  });
}
