import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';

class PaginatedPosts {
  const PaginatedPosts({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.itemsPerPage,
  });

  final List<Post> items;
  final int totalCount;
  final int page;
  final int itemsPerPage;

  bool get hasMore => page * itemsPerPage < totalCount;
}
