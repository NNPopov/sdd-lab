import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_application_1/features/tiers/tier_details/presentation/tier_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTierDetailsCubit extends MockCubit<TierDetailsState>
    implements TierDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockTierDetailsCubit cubit;
  late _MockAuthCubit authCubit;
  late _MockStackRouter router;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    cubit = _MockTierDetailsCubit();
    authCubit = _MockAuthCubit();
    router = _MockStackRouter();

    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildSubject(
    TierDetailsState state, {
    Stream<TierDetailsState>? stream,
  }) {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer(
      (_) => stream ?? const Stream.empty(),
    );
    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: router,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<TierDetailsCubit>.value(value: cubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const MaterialApp(
            home: TierDetailsScreen(tierId: 1, tierName: 'Free'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'TierDetailsLoading: AppBar shows tierName and spinner is visible',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(const TierDetailsState.loading()),
      );

      expect(find.text('Free'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'TierDetailsLoaded: AppBar shows tier.name and card content is visible',
    (tester) async {
      final tier = TierDetail(
        id: 1,
        name: 'Premium',
        createdAt: DateTime(2026, 4, 25),
      );
      await tester.pumpWidget(
        buildSubject(TierDetailsState.loaded(tier: tier)),
      );

      expect(find.text('Premium'), findsWidgets);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'TierDetailsError(NotFoundFailure): not-found text visible, no retry button',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          const TierDetailsState.error(failure: Failure.notFound()),
        ),
      );

      expect(find.text('Tier not found'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'TierDetailsError(UnknownFailure): generic error text visible, '
    'retry button present',
    (tester) async {
      when(() => cubit.retry(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSubject(
          const TierDetailsState.error(failure: Failure.unknown()),
        ),
      );

      expect(find.text('Failed to load tier'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );
}
