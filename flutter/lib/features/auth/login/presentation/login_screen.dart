import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/auth/login/presentation/widgets/login_form.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onAuthenticated,
    super.key,
    this.redirectPath,
  });

  final VoidCallback onAuthenticated;
  final String? redirectPath;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    unawaited(
      context.read<AuthCubit>().login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticated():
            widget.onAuthenticated();
          case AuthError(:final failure):
            if (failure is! InvalidCredentialsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.auth.login.errors.generic)),
              );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(t.auth.login.title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LoginForm(
                authState: state,
                formKey: _formKey,
                usernameController: _usernameController,
                passwordController: _passwordController,
                onSubmit: () => _submit(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
