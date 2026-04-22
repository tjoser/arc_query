import 'cached_query.dart';

class QueryCache {
  final Map<String, CachedQuery<dynamic>> _entries =
      <String, CachedQuery<dynamic>>{};

  CachedQuery<T>? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }

    return CachedQuery<T>(
      data: entry.data as T,
      updatedAt: entry.updatedAt,
      nextPageParam: entry.nextPageParam,
      hasMore: entry.hasMore,
    );
  }

  bool contains(String key) => _entries.containsKey(key);

  void set<T>(String key, CachedQuery<T> entry) {
    _entries[key] = entry;
  }

  void invalidate(String key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
  }

  int get size => _entries.length;
}
