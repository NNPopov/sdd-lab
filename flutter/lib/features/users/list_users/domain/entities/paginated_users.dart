import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';

class PaginatedUsers {
  const PaginatedUsers({
    required this.users,
    required this.totalCount,
    required this.page,
    required this.itemsPerPage,
  });

  final List<User> users;
  final int totalCount;
  final int page;
  final int itemsPerPage;

  bool get hasMore => page * itemsPerPage < totalCount;
}
