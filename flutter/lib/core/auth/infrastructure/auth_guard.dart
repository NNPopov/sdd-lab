import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._auth);

  final AuthCubit _auth;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_auth.state is AuthAuthenticated) {
      resolver.next();
    } else {
      final path = '/${resolver.route.stringMatch}';
      final loginUri = '/login?redirect=${Uri.encodeComponent(path)}';
      unawaited(router.pushPath(loginUri));
      resolver.next(false);
    }
  }
}
