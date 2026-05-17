class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.itemsPerPage,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int itemsPerPage;

  bool get hasMore => page * itemsPerPage < totalCount;
}
