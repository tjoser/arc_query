/// A cached query entry stored by [QueryCache].
class CachedQuery<T> {
  /// Creates a cached query snapshot.
  const CachedQuery({
    required this.data,
    required this.updatedAt,
    this.nextPageParam,
    this.hasMore = false,
  });

  /// The cached data payload.
  final T data;

  /// The timestamp when this cache entry was last updated.
  final DateTime updatedAt;

  /// The next page cursor or parameter for paginated queries.
  final Object? nextPageParam;

  /// Whether more pages are available for a paginated query.
  final bool hasMore;
}
