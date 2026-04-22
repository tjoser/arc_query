class CachedQuery<T> {
  const CachedQuery({
    required this.data,
    required this.updatedAt,
    this.nextPageParam,
    this.hasMore = false,
  });

  final T data;
  final DateTime updatedAt;
  final Object? nextPageParam;
  final bool hasMore;
}
