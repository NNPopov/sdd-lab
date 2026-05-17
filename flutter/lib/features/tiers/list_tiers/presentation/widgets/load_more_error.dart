import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';

class TiersLoadMoreError extends StatelessWidget {
  const TiersLoadMoreError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(t.tiers.listTiers.loadMoreError),
          TextButton(
            onPressed: onRetry,
            child: Text(t.common.retry),
          ),
        ],
      ),
    );
  }
}
