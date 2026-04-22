import 'package:flutter/foundation.dart';

import '../cache/cached_query.dart';
import '../controllers/query_controller.dart';
import '../core/query_state.dart';
import '../utils/typedefs.dart';

class Query<T> extends ChangeNotifier {
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

  final String key;
  final Duration staleDuration;
  final bool keepPreviousDataOnRefresh;
  final QueryController controller;
  final QueryFetcher<T> _fetcher;

  QueryState<T> _state;
  Future<void>? _activeRequest;

  QueryState<T> get state => _state;

  bool get isLoading => state.isLoading;
  bool get isRefreshing => state is QueryRefreshing<T>;
  bool get isFetchingMore => state is QueryFetchingMore<T>;
  bool get hasError => state.hasError;
  bool get hasData => state.hasData;
  bool get isIdle => state is QueryIdle<T>;
  bool get isStale => state.isStale;
  T? get data => state.data;
  Object? get error => state.error;
  StackTrace? get stackTrace => state.stackTrace;
  DateTime? get updatedAt => state.updatedAt;
  int get attempt => state.attempt;
  bool get hasMore => false;

  Future<void> execute({bool force = false}) {
    return _run(
      force: force,
      mode: _QueryRunMode.execute,
    );
  }

  Future<void> refresh() {
    return _run(
      force: true,
      mode: _QueryRunMode.refresh,
    );
  }

  Future<void> retry() {
    return _run(
      force: true,
      mode: hasData ? _QueryRunMode.refresh : _QueryRunMode.execute,
    );
  }

  Future<void> fetchMore() {
    throw StateError('fetchMore() is only supported by PaginatedQuery.');
  }

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

  CachedQuery<T>? readCache() => controller.cache.get<T>(key);

  bool isCacheStale(DateTime updatedAt) {
    if (staleDuration == Duration.zero) {
      return false;
    }
    return DateTime.now().difference(updatedAt) > staleDuration;
  }

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
  void dispose() {
    controller.unregister(this);
    super.dispose();
  }

  Future<T> fetch() => _fetcher();

  static Future<S> _unsupportedFetcher<S>() async {
    throw StateError('A fetcher is required for this query.');
  }

  @protected
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
