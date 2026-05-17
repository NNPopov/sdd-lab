import 'package:auto_route/auto_route.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/guards/permission_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNavigationResolver extends Mock implements NavigationResolver {}

class MockStackRouter extends Mock implements StackRouter {}

class MockPermissionCubit extends Mock implements PermissionCubit {}

void main() {
  late MockNavigationResolver resolver;
  late MockStackRouter router;
  late MockPermissionCubit permissionCubit;

  setUp(() {
    resolver = MockNavigationResolver();
    router = MockStackRouter();
    permissionCubit = MockPermissionCubit();
  });

  group('PermissionGuard', () {
    test('calls resolver.next() when all required permissions are present', () {
      when(
        () => permissionCubit.state,
      ).thenReturn({Permission.manageTiers, Permission.viewUsers});
      when(() => resolver.next()).thenReturn(null);

      PermissionGuard({
        Permission.manageTiers,
      }, permissionCubit).onNavigation(resolver, router);

      verify(() => resolver.next()).called(1);
      verifyNever(() => resolver.next(false));
    });

    test('calls resolver.next(false) when a required permission is absent', () {
      when(() => permissionCubit.state).thenReturn({Permission.viewUsers});
      when(() => resolver.next(false)).thenReturn(null);

      PermissionGuard({
        Permission.manageTiers,
      }, permissionCubit).onNavigation(resolver, router);

      verify(() => resolver.next(false)).called(1);
      verifyNever(() => resolver.next());
    });

    test('calls resolver.next() when required set is empty', () {
      when(() => permissionCubit.state).thenReturn({});
      when(() => resolver.next()).thenReturn(null);

      PermissionGuard({}, permissionCubit).onNavigation(resolver, router);

      verify(() => resolver.next()).called(1);
      verifyNever(() => resolver.next(false));
    });
  });
}
