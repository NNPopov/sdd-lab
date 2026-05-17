import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_state.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateTierScreen extends StatefulWidget {
  const CreateTierScreen({super.key});

  @override
  State<CreateTierScreen> createState() => _CreateTierScreenState();
}

class _CreateTierScreenState extends State<CreateTierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _nameController.dispose();
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
      context.read<CreateTierCubit>().submit(
        NewTierData(name: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<CreateTierCubit, CreateTierState>(
      listener: (context, state) {
        switch (state) {
          case CreateTierSuccess(:final tier):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.tiers.createTier.success)),
            );
            unawaited(context.router.maybePop(tier));
          case CreateTierFailure(:final failure):
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
                  SnackBar(
                    content: Text(t.tiers.createTier.errors.generic),
                  ),
                );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateTierSubmitting;
        return Scaffold(
          appBar: AppBar(title: Text(t.tiers.createTier.title)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t.tiers.createTier.name,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearServerError('name'),
                  onFieldSubmitted: (_) {
                    if (!isSubmitting) _submit(context);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.tiers.createTier.errors.required;
                    }
                    return _serverErrors['name'];
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
                      : Text(t.tiers.createTier.submit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
