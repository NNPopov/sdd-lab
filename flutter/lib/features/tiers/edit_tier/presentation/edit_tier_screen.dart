import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_state.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditTierScreen extends StatefulWidget {
  const EditTierScreen({required this.tierName, super.key});

  final String tierName;

  @override
  State<EditTierScreen> createState() => _EditTierScreenState();
}

class _EditTierScreenState extends State<EditTierScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.tierName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthCubit>().state;
    final isSuperuser = switch (authState) {
      AuthAuthenticated(:final currentUser) =>
        currentUser?.isSuperuser ?? false,
      _ => false,
    };
    unawaited(
      context.read<EditTierCubit>().submit(
        data: EditTierData(
          tierCurrentName: widget.tierName,
          newName: _nameController.text.trim(),
        ),
        isSuperuser: isSuperuser,
      ),
    );
  }

  String _errorMessage(Failure failure, Translations t) => switch (failure) {
    NotFoundFailure() => t.tiers.editTier.errors.notFound,
    PermissionDenied() => t.tiers.editTier.errors.permissionDenied,
    _ => t.tiers.editTier.errors.generic,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<EditTierCubit, EditTierState>(
      listener: (context, state) {
        switch (state) {
          case EditTierSuccess(:final newName):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.tiers.editTier.success)),
            );
            unawaited(context.router.maybePop(newName));
          case EditTierFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_errorMessage(failure, t))),
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is EditTierSubmitting;
        return Scaffold(
          appBar: AppBar(title: Text(t.tiers.editTier.title)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t.tiers.editTier.name,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!isSubmitting) _submit(context);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.tiers.editTier.errors.required;
                    }
                    return null;
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
                      : Text(t.tiers.editTier.save),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
