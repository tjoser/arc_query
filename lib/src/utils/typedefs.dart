import '../models/page_result.dart';

typedef QueryFetcher<T> = Future<T> Function();
typedef PageFetcher<TItem, TPageParam>
    = Future<PageResult<List<TItem>, TPageParam>> Function(
        TPageParam pageParam);
typedef PageMerger<T> = T Function(T? current, T nextPage);
