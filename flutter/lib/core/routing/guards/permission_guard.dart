import 'package:auto_route/auto_route.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';

class PermissionGuard extends AutoRouteGuard {
  PermissionGuard(this._required, this._permissionCubit);

  final Set<Permission> _required;
  final PermissionCubit _permissionCubit;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_required.every(_permissionCubit.state.contains)) {
      resolver.next();
    } else {
      resolver.next(false);
    }
  }
}
