import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';

class EditUserForm extends StatefulWidget {
  const EditUserForm({
    required this.original,
    required this.submitting,
    required this.serverErrors,
    required this.onSubmit,
    super.key,
  });

  final User original;
  final bool submitting;
  final Map<String, String> serverErrors;
  final void Function(UserUpdate update) onSubmit;

  @override
  State<EditUserForm> createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _profileImageUrlController;
  Map<String, String> _serverErrors = {};

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.original.name);
    _usernameController = TextEditingController(text: widget.original.username);
    _emailController = TextEditingController(text: widget.original.email);
    _profileImageUrlController = TextEditingController(
      text: widget.original.profileImageUrl ?? '',
    );
    _serverErrors = widget.serverErrors;
  }

  @override
  void didUpdateWidget(EditUserForm old) {
    super.didUpdateWidget(old);
    if (widget.serverErrors != old.serverErrors) {
      setState(() => _serverErrors = widget.serverErrors);
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _profileImageUrlController.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = Map.of(_serverErrors)..remove(field));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final profileImageUrl = _profileImageUrlController.text.trim();

    final update = UserUpdate(
      name: name != widget.original.name ? name : null,
      username: username != widget.original.username ? username : null,
      email: email != widget.original.email ? email : null,
      profileImageUrl:
          profileImageUrl != (widget.original.profileImageUrl ?? '')
          ? (profileImageUrl.isEmpty ? null : profileImageUrl)
          : null,
    );

    if (update.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.users.edit.errors.nothingToUpdate)),
      );
      return;
    }

    widget.onSubmit(update);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final formError = _serverErrors['_form'];
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: t.users.edit.name),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearServerError('name'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return t.users.edit.errors.required;
              }
              return _serverErrors['name'];
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: t.users.edit.username),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearServerError('username'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return t.users.edit.errors.required;
              }
              return _serverErrors['username'];
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: t.users.edit.email),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearServerError('email'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return t.users.edit.errors.required;
              }
              if (!_emailRegex.hasMatch(v.trim())) {
                return t.users.edit.errors.emailInvalid;
              }
              return _serverErrors['email'];
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _profileImageUrlController,
            decoration: InputDecoration(
              labelText: t.users.edit.profileImageUrl,
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _clearServerError('profile_image_url'),
            onFieldSubmitted: (_) {
              if (!widget.submitting) _submit();
            },
            validator: (_) => _serverErrors['profile_image_url'],
          ),
          if (formError != null) ...[
            const SizedBox(height: 8),
            Text(
              formError,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: widget.submitting ? null : _submit,
            child: widget.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.users.edit.save),
          ),
        ],
      ),
    );
  }
}
