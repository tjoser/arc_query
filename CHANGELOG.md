# Changelog

## 0.1.1

- Added comprehensive dartdoc comments across the public API.
- Improved package documentation quality for pub.dev.

## 0.1.0

- Initial release of `arc_query`.
- Added strongly typed `Query` and `PaginatedQuery`.
- Added immutable query states for loading, error, success, refresh, and fetch-more flows.
- Added in-memory cache with stale duration support.
- Added `QueryController` for invalidation, refetching, and cache clearing.
- Added `QueryBuilder` for Flutter widgets.
- Added tests covering state transitions, cache behavior, retry, refresh, and pagination.
- Added example Flutter app with fake API, retry, pull-to-refresh, and pagination.
