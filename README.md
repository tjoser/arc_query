# arc_query

**The easiest way to handle async data in Flutter**

`arc_query` is a lightweight React Query-style toolkit for Flutter. It gives you a simple, strongly typed API for loading, error, success, retry, refresh, caching, and pagination without forcing Bloc, Riverpod, Provider, or any specific app architecture.

## Why This Exists

Async UI code in Flutter usually turns into repeated `isLoading`, `try/catch`, and manual refresh logic scattered across widgets and services.

`arc_query` keeps that flow in one place:

- one query object
- one execute call
- one source of truth for loading, error, and data
- built-in cache and stale handling
- built-in pagination support

## Quick Start

```dart
import 'package:arc_query/arc_query.dart';

final userQuery = Query<User>(
  key: 'user',
  fetcher: () => api.getUser(),
);

await userQuery.execute();

if (userQuery.isLoading) {
  // show spinner
}

if (userQuery.hasError) {
  // show error
}

final user = userQuery.data;
```

## Core Concepts

Every query exposes:

- `isLoading`
- `isRefreshing`
- `isFetchingMore`
- `hasError`
- `hasData`
- `data`
- `error`
- `updatedAt`
- `isStale`

Under the hood, queries move through immutable states:

- `QueryIdle`
- `QueryLoading`
- `QuerySuccess`
- `QueryError`
- `QueryRefreshing`
- `QueryFetchingMore`

## Basic Example

```dart
final profileQuery = Query<Profile>(
  key: 'profile',
  staleDuration: const Duration(minutes: 5),
  fetcher: () => api.fetchProfile(),
);

await profileQuery.execute();
await profileQuery.refresh();
await profileQuery.retry();
```

## QueryBuilder

Use `QueryBuilder` when you want a minimal widget wrapper around a query:

```dart
QueryBuilder<User>(
  query: userQuery,
  loadingBuilder: (_) => const CircularProgressIndicator(),
  errorBuilder: (context, error, _) => Text(error.toString()),
  dataBuilder: (context, user) => Text(user.name),
  emptyBuilder: (_) => const Text('No user'),
)
```

You can also use the generic builder:

```dart
QueryBuilder<User>(
  query: userQuery,
  builder: (context, state) {
    if (state is QueryLoading<User>) {
      return const CircularProgressIndicator();
    }
    if (state is QueryError<User>) {
      return Text(state.error.toString());
    }
    return Text(state.data?.name ?? 'Missing user');
  },
)
```

## Caching

Queries cache successful results in memory by `key`.

```dart
final productsQuery = Query<List<Product>>(
  key: 'products',
  staleDuration: const Duration(minutes: 5),
  fetcher: () => api.fetchProducts(),
);
```

Behavior:

- if cached data is fresh, `execute()` returns cached data immediately
- if cached data is stale, the query keeps the previous value available and refetches
- `QueryController` can invalidate one query or clear all cached entries

```dart
final controller = QueryController();

final productsQuery = Query<List<Product>>(
  key: 'products',
  controller: controller,
  fetcher: () => api.fetchProducts(),
);

controller.invalidate('products');
await controller.refetch('products');
controller.clearCache();
```

## Pagination

Use `PaginatedQuery` for list endpoints:

```dart
final postsQuery = PaginatedQuery<Post, int>(
  key: 'posts',
  initialPageParam: 1,
  pageFetcher: (page) => api.fetchPosts(page),
);

await postsQuery.execute();
await postsQuery.fetchMore();
```

Your fetcher returns a `PageResult`:

```dart
Future<PageResult<List<Post>, int>> fetchPosts(int page) async {
  final response = await api.fetchPosts(page: page);

  return PageResult<List<Post>, int>(
    data: response.items,
    nextPageParam: response.hasMore ? page + 1 : null,
    hasMore: response.hasMore,
  );
}
```

Pagination gives you:

- automatic list append
- `hasMore`
- `isFetchingMore`
- cached paginated results

## Refresh And Retry

Refresh keeps previous data available while a request is running:

```dart
await query.refresh();
```

Retry re-runs the latest failed request:

```dart
await query.retry();
```

## Comparison vs Manual Async Handling

Manual UI state usually means:

- local booleans for loading and errors
- duplicate `try/catch` blocks
- repeated pull-to-refresh wiring
- ad hoc cache maps
- custom pagination state per screen

With `arc_query`, one object owns that behavior and the widget reads from a single typed source.

## Example App

The package includes a full Flutter example in [`example/lib/main.dart`](example/lib/main.dart) showing:

- user fetch
- retry after failure
- pull to refresh
- paginated list loading
- loading more pages

## Testing

Run:

```bash
flutter test
```

## License

MIT
