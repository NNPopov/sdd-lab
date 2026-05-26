import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/presentation/edit_post_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditPostCubit extends MockCubit<EditPostState>
    implements EditPostCubit {}

class _MockModerationLogCubit extends MockCubit<ModerationLogState>
    implements ModerationLogCubit {}

// The loaded post whose author id is the identity the edit screen must use.
const _authorId = 99;

Post _post() => Post(
  id: 7,
  title: 'Valid Title',
  text: 'x' * 120,
  createdAt: DateTime(2024),
  createdByUserId: _authorId,
  postUuid: 'uuid-7',
  status: PostStatus.pendingReview,
);

Widget _wrap({
  required EditPostCubit editCubit,
  required ModerationLogCubit logCubit,
  required Post post,
}) {
  return TranslationProvider(
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<EditPostCubit>.value(value: editCubit),
          BlocProvider<ModerationLogCubit>.value(value: logCubit),
        ],
        child: EditPostScreen(post: post),
      ),
    ),
  );
}

void main() {
  late _MockEditPostCubit editCubit;
  late _MockModerationLogCubit logCubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
    registerFallbackValue(
      const UpdatedPostData(
        userId: 0,
        id: 0,
        postUuid: '',
        status: PostStatus.pendingReview,
        title: '',
        text: '',
      ),
    );
  });

  setUp(() {
    editCubit = _MockEditPostCubit();
    logCubit = _MockModerationLogCubit();

    when(() => editCubit.state).thenReturn(const EditPostState.initial());
    when(() => editCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => editCubit.submit(any())).thenAnswer((_) async {});

    when(() => logCubit.state).thenReturn(const ModerationLogState.initial());
    when(() => logCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => logCubit.load(any())).thenAnswer((_) async {});
  });

  testWidgets(
    'tapping Save submits UpdatedPostData whose userId is post.createdByUserId',
    (tester) async {
      // Force a narrow layout so the screen does not auto-load the wide-mode
      // moderation log on first frame.
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(editCubit: editCubit, logCubit: logCubit, post: _post()),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final captured = verify(() => editCubit.submit(captureAny())).captured;
      final data = captured.single as UpdatedPostData;
      expect(data.userId, _authorId);
      expect(data.id, 7);
      expect(data.title, 'Valid Title');
    },
  );
}
