sealed class QueryState<T> {
  const QueryState({
    this.data,
    this.error,
    this.stackTrace,
    this.updatedAt,
    this.isStale = false,
    this.attempt = 0,
  });

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime? updatedAt;
  final bool isStale;
  final int attempt;

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isLoading =>
      this is QueryLoading<T> ||
      this is QueryRefreshing<T> ||
      this is QueryFetchingMore<T>;
}

final class QueryIdle<T> extends QueryState<T> {
  const QueryIdle({super.data, super.updatedAt, super.isStale});
}

final class QueryLoading<T> extends QueryState<T> {
  const QueryLoading({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}

final class QuerySuccess<T> extends QueryState<T> {
  const QuerySuccess({
    required T data,
    required DateTime updatedAt,
    super.isStale,
    super.attempt,
  }) : super(data: data, updatedAt: updatedAt);
}

final class QueryError<T> extends QueryState<T> {
  const QueryError({
    super.data,
    required Object error,
    required StackTrace stackTrace,
    super.updatedAt,
    super.isStale,
    super.attempt,
  }) : super(error: error, stackTrace: stackTrace);
}

final class QueryRefreshing<T> extends QueryState<T> {
  const QueryRefreshing({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}

final class QueryFetchingMore<T> extends QueryState<T> {
  const QueryFetchingMore({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}
