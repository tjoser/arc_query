import 'cached_query.dart';

/// An in-memory cache used to store query results by key.
class QueryCache {
  final Map<String, CachedQuery<dynamic>> _entries =
      <String, CachedQuery<dynamic>>{};

  /// Returns a cached entry for [key], or `null` if none exists.
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

  /// Returns `true` when the cache contains an entry for [key].
  bool contains(String key) => _entries.containsKey(key);

  /// Stores [entry] under [key].
  void set<T>(String key, CachedQuery<T> entry) {
    _entries[key] = entry;
  }

  /// Removes the cached entry for [key].
  void invalidate(String key) {
    _entries.remove(key);
  }

  /// Removes all cached entries.
  void clear() {
    _entries.clear();
  }

  /// The number of cached entries currently stored.
  int get size => _entries.length;
}
