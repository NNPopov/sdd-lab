import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.authState,
    required this.onSubmit,
    required this.usernameController,
    required this.passwordController,
    required this.formKey,
    super.key,
  });

  final AuthState authState;
  final VoidCallback onSubmit;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isAuthenticating = authState is AuthAuthenticating;

    String? inlineError;
    if (authState is AuthError) {
      final failure = (authState as AuthError).failure;
      inlineError = switch (failure) {
        InvalidCredentialsFailure() => t.auth.login.errors.invalidCredentials,
        _ => t.auth.login.errors.generic,
      };
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('usernameField'),
            controller: usernameController,
            decoration: InputDecoration(labelText: t.auth.login.username),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.auth.login.errors.required
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('passwordField'),
            controller: passwordController,
            decoration: InputDecoration(labelText: t.auth.login.password),
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) {
              if (!isAuthenticating) onSubmit();
            },
            validator: (v) =>
                (v == null || v.isEmpty) ? t.auth.login.errors.required : null,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isAuthenticating ? null : onSubmit,
            child: isAuthenticating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.auth.login.submit),
          ),
          if (inlineError != null) ...[
            const SizedBox(height: 16),
            Text(
              inlineError,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
