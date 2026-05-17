import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';

class EraseDbUserConfirmationDialog extends StatelessWidget {
  const EraseDbUserConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 48,
      ),
      title: Text(t.users.eraseDbUser.confirmTitle),
      content: Text(t.users.eraseDbUser.confirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.users.eraseDbUser.confirmButton),
        ),
      ],
    );
  }
}
