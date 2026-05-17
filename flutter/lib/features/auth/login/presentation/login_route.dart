import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/auth/login/presentation/login_screen.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    @QueryParam('redirect') this.redirectPath,
  });

  final String? redirectPath;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      redirectPath: redirectPath,
      onAuthenticated: () async {
        final router = context.router;
        await router.replaceAll([const UsersRoute()]);
        final redirect = redirectPath;
        if (redirect != null && redirect.isNotEmpty) {
          await router.navigatePath(redirect);
        }
      },
    );
  }
}
