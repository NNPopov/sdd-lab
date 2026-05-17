import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';

class DeleteTierConfirmationDialog extends StatelessWidget {
  const DeleteTierConfirmationDialog({required this.tierName, super.key});

  final String tierName;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 48,
      ),
      title: Text(t.tiers.deleteTier.confirmTitle),
      content: Text(
        t.tiers.deleteTier.confirmMessage.replaceAll('{name}', tierName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.tiers.deleteTier.cancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.tiers.deleteTier.confirmButton),
        ),
      ],
    );
  }
}
