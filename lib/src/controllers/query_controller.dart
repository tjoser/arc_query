import '../cache/query_cache.dart';
import '../query/query.dart';

/// Coordinates cache invalidation and refetching across multiple queries.
class QueryController {
  /// Creates a controller with an optional custom [QueryCache].
  QueryController({QueryCache? cache}) : cache = cache ?? QueryCache();

  /// A shared singleton controller for simple setups.
  static final QueryController instance = QueryController();

  /// The cache used by registered queries.
  final QueryCache cache;
  final Set<Query<dynamic>> _queries = <Query<dynamic>>{};

  /// Registers a query with this controller.
  void register(Query<dynamic> query) {
    _queries.add(query);
  }

  /// Unregisters a query from this controller.
  void unregister(Query<dynamic> query) {
    _queries.remove(query);
  }

  /// Invalidates the cache entry for [key] and marks matching queries stale.
  void invalidate(String key) {
    cache.invalidate(key);
    for (final query in _queries.where((query) => query.key == key)) {
      query.markStale();
    }
  }

  /// Forces all registered queries matching [key] to fetch again.
  Future<void> refetch(String key) async {
    final matches = _queries.where((query) => query.key == key).toList();
    await Future.wait<void>(
      matches.map((query) => query.execute(force: true)),
    );
  }

  /// Forces every registered query to fetch again.
  Future<void> refetchAll() async {
    final queries = _queries.toList();
    await Future.wait<void>(
      queries.map((query) => query.execute(force: true)),
    );
  }

  /// Clears the entire cache and marks registered queries stale.
  void clearCache() {
    cache.clear();
    for (final query in _queries) {
      query.markStale();
    }
  }
}
