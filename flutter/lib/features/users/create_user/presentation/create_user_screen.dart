import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, String> _serverErrors = {};

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = Map.of(_serverErrors)..remove(field));
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _serverErrors = {});
    unawaited(
      context.read<CreateUserCubit>().submit(
        NewUserData(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<CreateUserCubit, CreateUserState>(
      listener: (context, state) {
        switch (state) {
          case CreateUserSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.users.create.success)),
            );
            unawaited(context.router.maybePop());
          case CreateUserFailure(:final failure):
            switch (failure) {
              case ValidationFailure(:final fieldErrors):
                setState(() => _serverErrors = fieldErrors);
                _formKey.currentState?.validate();
              case ConflictFailure(:final message):
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.users.create.errors.generic)),
                );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateUserSubmitting;
        return Scaffold(
          appBar: AppBar(title: Text(t.users.create.title)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: t.users.create.name),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearServerError('name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.users.create.errors.required;
                    }
                    return _serverErrors['name'];
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: t.users.create.username,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearServerError('username'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.users.create.errors.required;
                    }
                    return _serverErrors['username'];
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: t.users.create.email),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  onChanged: (_) => _clearServerError('email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.users.create.errors.required;
                    }
                    if (!_emailRegex.hasMatch(v.trim())) {
                      return t.users.create.errors.emailInvalid;
                    }
                    return _serverErrors['email'];
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: t.users.create.password,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => _clearServerError('password'),
                  onFieldSubmitted: (_) {
                    if (!isSubmitting) _submit(context);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return t.users.create.errors.required;
                    }
                    if (v.length < 8) {
                      return t.users.create.errors.passwordTooShort;
                    }
                    return _serverErrors['password'];
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: isSubmitting ? null : () => _submit(context),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.users.create.submit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
