import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';

class TierTile extends StatelessWidget {
  const TierTile({required this.tier, this.onTap, super.key});

  final Tier tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${tier.id}')),
      title: Text(tier.name),
      onTap: onTap,
    );
  }
}
