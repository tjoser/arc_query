/// A single page returned by a paginated query fetcher.
class PageResult<TData, TPageParam> {
  /// Creates a paginated result.
  const PageResult({
    required this.data,
    this.nextPageParam,
    this.hasMore = false,
  });

  /// The data for the current page.
  final TData data;

  /// The next page parameter to use with a future fetch.
  final TPageParam? nextPageParam;

  /// Whether another page can be fetched.
  final bool hasMore;
}
