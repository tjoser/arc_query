import '../models/page_result.dart';

/// A function that fetches a single query result.
typedef QueryFetcher<T> = Future<T> Function();

/// A function that fetches one page for a paginated query.
typedef PageFetcher<TItem, TPageParam>
    = Future<PageResult<List<TItem>, TPageParam>> Function(
        TPageParam pageParam);

/// A function that merges an existing value with a newly fetched page.
typedef PageMerger<T> = T Function(T? current, T nextPage);
