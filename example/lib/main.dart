import 'dart:async';

import 'package:arc_query/arc_query.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ArcQueryExampleApp());
}

class ArcQueryExampleApp extends StatelessWidget {
  const ArcQueryExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'arc_query Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C7D69)),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  late final FakeApi _api;
  late final Query<User> _userQuery;
  late final PaginatedQuery<Post, int> _postsQuery;

  @override
  void initState() {
    super.initState();
    _api = FakeApi();
    _userQuery = Query<User>(
      key: 'user',
      staleDuration: const Duration(minutes: 5),
      fetcher: _api.fetchUser,
    );
    _postsQuery = PaginatedQuery<Post, int>(
      key: 'posts',
      staleDuration: const Duration(minutes: 2),
      initialPageParam: 1,
      pageFetcher: _api.fetchPosts,
    );

    unawaited(_userQuery.execute());
    unawaited(_postsQuery.execute());
  }

  @override
  void dispose() {
    _userQuery.dispose();
    _postsQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('arc_query'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait<void>(<Future<void>>[
            _userQuery.refresh(),
            _postsQuery.refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionCard(
              title: 'User Query',
              child: QueryBuilder<User>(
                query: _userQuery,
                loadingBuilder: (_) =>
                    const _LoadingState(label: 'Loading user'),
                errorBuilder: (context, error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: _userQuery.retry,
                ),
                dataBuilder: (context, user) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(user.email),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _userQuery.refresh,
                        child: const Text('Refresh user'),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Paginated Posts',
              child: QueryBuilder<List<Post>>(
                query: _postsQuery,
                loadingBuilder: (_) =>
                    const _LoadingState(label: 'Loading posts'),
                errorBuilder: (context, error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: _postsQuery.retry,
                ),
                emptyBuilder: (_) => const Text('No posts yet'),
                dataBuilder: (context, posts) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final post in posts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(post.title),
                          subtitle: Text(post.body),
                        ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _postsQuery,
                        builder: (context, _) {
                          return FilledButton(
                            onPressed: _postsQuery.hasMore &&
                                    !_postsQuery.isFetchingMore
                                ? _postsQuery.fetchMore
                                : null,
                            child: Text(
                              _postsQuery.isFetchingMore
                                  ? 'Loading more...'
                                  : _postsQuery.hasMore
                                      ? 'Load more'
                                      : 'No more posts',
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class FakeApi {
  bool _firstUserRequest = true;

  Future<User> fetchUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_firstUserRequest) {
      _firstUserRequest = false;
      throw Exception('User request failed. Tap retry.');
    }
    return const User(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
    );
  }

  Future<PageResult<List<Post>, int>> fetchPosts(int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    const pageSize = 10;
    final start = (page - 1) * pageSize;
    final posts = List<Post>.generate(
      pageSize,
      (index) => Post(
        title: 'Post #${start + index + 1}',
        body: 'This post came from the fake paginated API.',
      ),
    );

    return PageResult<List<Post>, int>(
      data: posts,
      nextPageParam: page < 3 ? page + 1 : null,
      hasMore: page < 3,
    );
  }
}

class User {
  const User({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;
}

class Post {
  const Post({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
