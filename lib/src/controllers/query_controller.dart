import '../cache/query_cache.dart';
import '../query/query.dart';

class QueryController {
  QueryController({QueryCache? cache}) : cache = cache ?? QueryCache();

  static final QueryController instance = QueryController();

  final QueryCache cache;
  final Set<Query<dynamic>> _queries = <Query<dynamic>>{};

  void register(Query<dynamic> query) {
    _queries.add(query);
  }

  void unregister(Query<dynamic> query) {
    _queries.remove(query);
  }

  void invalidate(String key) {
    cache.invalidate(key);
    for (final query in _queries.where((query) => query.key == key)) {
      query.markStale();
    }
  }

  Future<void> refetch(String key) async {
    final matches = _queries.where((query) => query.key == key).toList();
    await Future.wait<void>(
      matches.map((query) => query.execute(force: true)),
    );
  }

  Future<void> refetchAll() async {
    final queries = _queries.toList();
    await Future.wait<void>(
      queries.map((query) => query.execute(force: true)),
    );
  }

  void clearCache() {
    cache.clear();
    for (final query in _queries) {
      query.markStale();
    }
  }
}
