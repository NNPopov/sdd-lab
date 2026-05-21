import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
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
          case CreateUserConflict(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          case CreateUserFailure():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.users.create.errors.generic)),
            );
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
                _CreateUserForm(
                  nameController: _nameController,
                  usernameController: _usernameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isSubmitting: isSubmitting,
                  onSubmit: () => _submit(context),
                ),
                const SizedBox(height: 32),
                _SubmitSection(onSubmit: () => _submit(context)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreateUserForm extends StatelessWidget {
  const _CreateUserForm({
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(labelText: t.users.create.name),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(labelText: t.users.create.username),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(labelText: t.users.create.email),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return t.users.create.errors.required;
            }
            if (!_emailRegex.hasMatch(v.trim())) {
              return t.users.create.errors.emailInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(labelText: t.users.create.password),
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) {
            if (!isSubmitting) onSubmit();
          },
          validator: (v) {
            if (v == null || v.isEmpty) {
              return t.users.create.errors.required;
            }
            if (v.length < 8) {
              return t.users.create.errors.passwordTooShort;
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SubmitSection extends StatelessWidget {
  const _SubmitSection({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<CreateUserCubit, CreateUserState>(
      builder: (context, state) {
        final isSubmitting = state is CreateUserSubmitting;
        final validationMessage = state is CreateUserValidationError
            ? state.message
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.users.create.submit),
            ),
            if (validationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  validationMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
