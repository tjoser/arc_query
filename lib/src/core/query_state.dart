/// The immutable state snapshot of a `Query`.
sealed class QueryState<T> {
  /// Creates a query state snapshot.
  const QueryState({
    this.data,
    this.error,
    this.stackTrace,
    this.updatedAt,
    this.isStale = false,
    this.attempt = 0,
  });

  /// The current data value, if any.
  final T? data;

  /// The latest error, if the query failed.
  final Object? error;

  /// The stack trace associated with [error], if available.
  final StackTrace? stackTrace;

  /// The last successful update timestamp.
  final DateTime? updatedAt;

  /// Whether the current data should be considered stale.
  final bool isStale;

  /// The current retry attempt counter since the last success.
  final int attempt;

  /// Whether the state currently contains data.
  bool get hasData => data != null;

  /// Whether the state currently contains an error.
  bool get hasError => error != null;

  /// Whether the query is actively performing work.
  bool get isLoading =>
      this is QueryLoading<T> ||
      this is QueryRefreshing<T> ||
      this is QueryFetchingMore<T>;
}

/// The initial state before a query has executed.
final class QueryIdle<T> extends QueryState<T> {
  /// Creates an idle state.
  const QueryIdle({super.data, super.updatedAt, super.isStale});
}

/// The state emitted while a query is loading for the first time.
final class QueryLoading<T> extends QueryState<T> {
  /// Creates a loading state.
  const QueryLoading({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}

/// The state emitted after a successful query result.
final class QuerySuccess<T> extends QueryState<T> {
  /// Creates a success state.
  const QuerySuccess({
    required T data,
    required DateTime updatedAt,
    super.isStale,
    super.attempt,
  }) : super(data: data, updatedAt: updatedAt);
}

/// The state emitted when a query fails.
final class QueryError<T> extends QueryState<T> {
  /// Creates an error state.
  const QueryError({
    super.data,
    required Object error,
    required StackTrace stackTrace,
    super.updatedAt,
    super.isStale,
    super.attempt,
  }) : super(error: error, stackTrace: stackTrace);
}

/// The state emitted while a query refreshes existing data.
final class QueryRefreshing<T> extends QueryState<T> {
  /// Creates a refreshing state.
  const QueryRefreshing({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}

/// The state emitted while a paginated query fetches another page.
final class QueryFetchingMore<T> extends QueryState<T> {
  /// Creates a fetching-more state.
  const QueryFetchingMore({
    super.data,
    super.updatedAt,
    super.isStale,
    super.attempt,
  });
}
