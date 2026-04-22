class PageResult<TData, TPageParam> {
  const PageResult({
    required this.data,
    this.nextPageParam,
    this.hasMore = false,
  });

  final TData data;
  final TPageParam? nextPageParam;
  final bool hasMore;
}
