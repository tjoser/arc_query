import '../controllers/query_controller.dart';
import '../core/query_state.dart';
import '../utils/typedefs.dart';
import 'query.dart';

class PaginatedQuery<TItem, TPageParam> extends Query<List<TItem>> {
  // ignore: use_super_parameters
  PaginatedQuery({
    required String key,
    required this.initialPageParam,
    required PageFetcher<TItem, TPageParam> pageFetcher,
    this.merge,
    Duration staleDuration = Duration.zero,
    QueryController? controller,
    bool keepPreviousDataOnRefresh = true,
  })  : _pageFetcher = pageFetcher,
        super.internal(
          key: key,
          staleDuration: staleDuration,
          controller: controller,
          keepPreviousDataOnRefresh: keepPreviousDataOnRefresh,
        );

  final TPageParam initialPageParam;
  final PageFetcher<TItem, TPageParam> _pageFetcher;
  final PageMerger<List<TItem>>? merge;

  TPageParam? _nextPageParam;
  bool _hasMore = false;

  @override
  bool get hasMore => _hasMore;

  @override
  Future<List<TItem>> fetch() async {
    final page = await _pageFetcher(initialPageParam);
    _nextPageParam = page.nextPageParam;
    _hasMore = page.hasMore;
    return page.data;
  }

  @override
  Future<void> execute({bool force = false}) async {
    final cached = readCache();
    final cacheIsFresh =
        cached != null && !isCacheStale(cached.updatedAt) && !force;

    if (cacheIsFresh) {
      _nextPageParam = cached.nextPageParam as TPageParam?;
      _hasMore = cached.hasMore;
    }

    await super.execute(force: force);

    final refreshedCache = readCache();
    if (refreshedCache != null) {
      _nextPageParam = refreshedCache.nextPageParam as TPageParam?;
      _hasMore = refreshedCache.hasMore;
    }
  }

  @override
  Future<void> refresh() async {
    await super.refresh();
    final refreshedCache = readCache();
    if (refreshedCache != null) {
      _nextPageParam = refreshedCache.nextPageParam as TPageParam?;
      _hasMore = refreshedCache.hasMore;
    }
  }

  @override
  Future<void> fetchMore() async {
    if (isFetchingMore || !_hasMore || _nextPageParam == null) {
      return;
    }

    final currentData = data ?? <TItem>[];
    setQueryState(
      QueryFetchingMore<List<TItem>>(
        data: currentData,
        updatedAt: updatedAt,
        isStale: isStale,
        attempt: attempt,
      ),
      allowEmptyData: true,
    );

    try {
      final nextPage = await _pageFetcher(_nextPageParam as TPageParam);
      final merged = merge?.call(currentData, nextPage.data) ??
          <TItem>[...currentData, ...nextPage.data];
      final now = DateTime.now();
      _nextPageParam = nextPage.nextPageParam;
      _hasMore = nextPage.hasMore;
      writeCache(
        data: merged,
        updatedAt: now,
        nextPageParam: _nextPageParam,
        hasMore: _hasMore,
      );
      setQueryState(
        QuerySuccess<List<TItem>>(
          data: merged,
          updatedAt: now,
        ),
      );
    } catch (error, stackTrace) {
      setQueryState(
        QueryError<List<TItem>>(
          data: currentData,
          error: error,
          stackTrace: stackTrace,
          updatedAt: updatedAt,
          isStale: isStale,
          attempt: attempt + 1,
        ),
        allowEmptyData: true,
      );
    }
  }

  @override
  void writeCache({
    required List<TItem> data,
    required DateTime updatedAt,
    Object? nextPageParam,
    bool hasMore = false,
  }) {
    super.writeCache(
      data: data,
      updatedAt: updatedAt,
      nextPageParam: nextPageParam ?? _nextPageParam,
      hasMore: hasMore || _hasMore,
    );
  }
}
