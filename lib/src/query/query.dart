import 'package:flutter/foundation.dart';

import '../cache/cached_query.dart';
import '../controllers/query_controller.dart';
import '../core/query_state.dart';
import '../utils/typedefs.dart';

/// A lightweight asynchronous query with caching and retry support.
class Query<T> extends ChangeNotifier {
  /// Creates a query that loads data with [fetcher] and stores results by [key].
  Query({
    required this.key,
    required QueryFetcher<T> fetcher,
    this.staleDuration = Duration.zero,
    QueryController? controller,
    this.keepPreviousDataOnRefresh = true,
  })  : _fetcher = fetcher,
        controller = controller ?? QueryController.instance,
        _state = QueryIdle<T>() {
    this.controller.register(this);
  }

  Query.internal({
    required this.key,
    this.staleDuration = Duration.zero,
    QueryController? controller,
    this.keepPreviousDataOnRefresh = true,
  })  : _fetcher = _unsupportedFetcher,
        controller = controller ?? QueryController.instance,
        _state = QueryIdle<T>() {
    this.controller.register(this);
  }

  /// The cache key used for storing and invalidating this query.
  final String key;

  /// How long a cached result should be treated as fresh.
  final Duration staleDuration;

  /// Whether refresh operations should keep the previous data visible.
  final bool keepPreviousDataOnRefresh;

  /// The controller that manages this query and its cache.
  final QueryController controller;
  final QueryFetcher<T> _fetcher;

  QueryState<T> _state;
  Future<void>? _activeRequest;

  /// The current immutable state snapshot.
  QueryState<T> get state => _state;

  /// Whether the query is actively loading, refreshing, or fetching more.
  bool get isLoading => state.isLoading;

  /// Whether the query is refreshing previously loaded data.
  bool get isRefreshing => state is QueryRefreshing<T>;

  /// Whether the query is appending another page.
  bool get isFetchingMore => state is QueryFetchingMore<T>;

  /// Whether the current state contains an error.
  bool get hasError => state.hasError;

  /// Whether the current state contains data.
  bool get hasData => state.hasData;

  /// Whether the query has not executed yet.
  bool get isIdle => state is QueryIdle<T>;

  /// Whether the current data is stale.
  bool get isStale => state.isStale;

  /// The current data value, if available.
  T? get data => state.data;

  /// The current error value, if available.
  Object? get error => state.error;

  /// The stack trace captured from the latest error.
  StackTrace? get stackTrace => state.stackTrace;

  /// The last successful update time.
  DateTime? get updatedAt => state.updatedAt;

  /// The number of failed attempts since the last success.
  int get attempt => state.attempt;

  /// Whether more pages can be loaded. Always `false` for non-paginated queries.
  bool get hasMore => false;

  /// Executes the query.
  ///
  /// When cached data is still fresh, this may resolve from cache unless
  /// [force] is `true`.
  Future<void> execute({bool force = false}) {
    return _run(
      force: force,
      mode: _QueryRunMode.execute,
    );
  }

  /// Forces a refetch while keeping previous data when configured.
  Future<void> refresh() {
    return _run(
      force: true,
      mode: _QueryRunMode.refresh,
    );
  }

  /// Re-runs the query after an error.
  Future<void> retry() {
    return _run(
      force: true,
      mode: hasData ? _QueryRunMode.refresh : _QueryRunMode.execute,
    );
  }

  /// Loads the next page.
  ///
  /// This is only supported by [PaginatedQuery].
  Future<void> fetchMore() {
    throw StateError('fetchMore() is only supported by PaginatedQuery.');
  }

  /// Marks the query state as stale without removing its current data.
  void markStale() {
    final currentData = data;
    if (currentData != null) {
      _setState(
        QuerySuccess<T>(
          data: currentData,
          updatedAt: updatedAt ?? DateTime.now(),
          isStale: true,
          attempt: attempt,
        ),
      );
      return;
    }

    _setState(
      QueryIdle<T>(
        updatedAt: updatedAt,
        isStale: true,
      ),
      allowEmptyData: true,
    );
  }

  /// Returns the cached entry for this query key, if present.
  CachedQuery<T>? readCache() => controller.cache.get<T>(key);

  /// Returns whether the cache entry updated at [updatedAt] is stale.
  bool isCacheStale(DateTime updatedAt) {
    if (staleDuration == Duration.zero) {
      return false;
    }
    return DateTime.now().difference(updatedAt) > staleDuration;
  }

  /// Stores [data] in the cache with pagination metadata when provided.
  void writeCache({
    required T data,
    required DateTime updatedAt,
    Object? nextPageParam,
    bool hasMore = false,
  }) {
    controller.cache.set<T>(
      key,
      CachedQuery<T>(
        data: data,
        updatedAt: updatedAt,
        nextPageParam: nextPageParam,
        hasMore: hasMore,
      ),
    );
  }

  @override

  /// Disposes the query and unregisters it from its controller.
  void dispose() {
    controller.unregister(this);
    super.dispose();
  }

  /// Performs the actual data fetch.
  ///
  /// Subclasses like [PaginatedQuery] can override this.
  Future<T> fetch() => _fetcher();

  static Future<S> _unsupportedFetcher<S>() async {
    throw StateError('A fetcher is required for this query.');
  }

  @protected

  /// Updates the current query state and notifies listeners.
  void setQueryState(QueryState<T> state, {bool allowEmptyData = false}) {
    _setState(state, allowEmptyData: allowEmptyData);
  }

  Future<void> _run({
    required bool force,
    required _QueryRunMode mode,
  }) {
    if (_activeRequest != null) {
      return _activeRequest!;
    }

    final completer = _execute(force: force, mode: mode);
    _activeRequest = completer.whenComplete(() {
      _activeRequest = null;
    });
    return _activeRequest!;
  }

  Future<void> _execute({
    required bool force,
    required _QueryRunMode mode,
  }) async {
    final cached = readCache();
    final cacheIsFresh =
        cached != null && !isCacheStale(cached.updatedAt) && !force;

    if (cacheIsFresh) {
      _setState(
        QuerySuccess<T>(
          data: cached.data,
          updatedAt: cached.updatedAt,
          attempt: attempt,
        ),
      );
      return;
    }

    final previousData = _resolvePreviousData(cached: cached, mode: mode);
    final previousTimestamp = updatedAt ?? cached?.updatedAt;
    final previousAttempt = attempt;

    _setState(
      switch (mode) {
        _QueryRunMode.refresh => QueryRefreshing<T>(
            data: previousData,
            updatedAt: previousTimestamp,
            isStale: cached != null ? isCacheStale(cached.updatedAt) : isStale,
            attempt: previousAttempt,
          ),
        _QueryRunMode.execute => QueryLoading<T>(
            data: previousData,
            updatedAt: previousTimestamp,
            isStale: cached != null ? isCacheStale(cached.updatedAt) : isStale,
            attempt: previousAttempt,
          ),
      },
      allowEmptyData: true,
    );

    try {
      final result = await fetch();
      final now = DateTime.now();
      writeCache(data: result, updatedAt: now);
      _setState(
        QuerySuccess<T>(
          data: result,
          updatedAt: now,
          attempt: 0,
        ),
      );
    } catch (error, stackTrace) {
      _setState(
        QueryError<T>(
          data: previousData,
          error: error,
          stackTrace: stackTrace,
          updatedAt: previousTimestamp,
          isStale: previousTimestamp != null
              ? isCacheStale(previousTimestamp)
              : isStale,
          attempt: previousAttempt + 1,
        ),
        allowEmptyData: true,
      );
    }
  }

  T? _resolvePreviousData({
    required CachedQuery<T>? cached,
    required _QueryRunMode mode,
  }) {
    if (!keepPreviousDataOnRefresh && mode == _QueryRunMode.refresh) {
      return null;
    }

    return data ?? cached?.data;
  }

  void _setState(QueryState<T> state, {bool allowEmptyData = false}) {
    if (!allowEmptyData && state.data == null && state is! QueryIdle<T>) {
      throw StateError('Query state requires data or explicit allowEmptyData.');
    }

    _state = state;
    notifyListeners();
  }
}

enum _QueryRunMode {
  execute,
  refresh,
}
