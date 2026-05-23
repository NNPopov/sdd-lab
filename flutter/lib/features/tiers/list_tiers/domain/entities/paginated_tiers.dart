import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';

class PaginatedTiers {
  const PaginatedTiers({
    required this.tiers,
    required this.totalCount,
    required this.page,
    required this.itemsPerPage,
  });

  final List<Tier> tiers;
  final int totalCount;
  final int page;
  final int itemsPerPage;

  bool get hasMore => page * itemsPerPage < totalCount;
}
