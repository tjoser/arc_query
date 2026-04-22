import 'package:arc_query/arc_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Query', () {
    test('transitions from loading to success', () async {
      final controller = QueryController();
      final query = Query<int>(
        key: 'counter',
        controller: controller,
        fetcher: () async => 42,
      );

      expect(query.state, isA<QueryIdle<int>>());

      final future = query.execute();
      expect(query.state, isA<QueryLoading<int>>());

      await future;

      expect(query.state, isA<QuerySuccess<int>>());
      expect(query.data, 42);
      expect(query.hasData, isTrue);
      expect(query.hasError, isFalse);
    });

    test('uses fresh cache without refetching', () async {
      final controller = QueryController();
      var calls = 0;
      final query = Query<String>(
        key: 'user',
        controller: controller,
        staleDuration: const Duration(minutes: 5),
        fetcher: () async {
          calls++;
          return 'Ada';
        },
      );

      await query.execute();
      await query.execute();

      expect(calls, 1);
      expect(query.data, 'Ada');
      expect(controller.cache.contains('user'), isTrue);
    });

    test('retry recovers from a failed request', () async {
      final controller = QueryController();
      var calls = 0;
      final query = Query<String>(
        key: 'retry',
        controller: controller,
        fetcher: () async {
          calls++;
          if (calls == 1) {
            throw StateError('boom');
          }
          return 'ok';
        },
      );

      await query.execute();
      expect(query.state, isA<QueryError<String>>());
      expect(query.attempt, 1);

      await query.retry();

      expect(query.state, isA<QuerySuccess<String>>());
      expect(query.data, 'ok');
      expect(query.attempt, 0);
    });

    test('refresh keeps previous data while refetching', () async {
      final controller = QueryController();
      var value = 'first';
      final query = Query<String>(
        key: 'refresh',
        controller: controller,
        fetcher: () async => value,
      );

      await query.execute();
      value = 'second';

      final future = query.refresh();
      expect(query.state, isA<QueryRefreshing<String>>());
      expect(query.data, 'first');

      await future;

      expect(query.data, 'second');
      expect(query.state, isA<QuerySuccess<String>>());
    });
  });

  group('PaginatedQuery', () {
    test('appends pages and tracks hasMore', () async {
      final controller = QueryController();
      final query = PaginatedQuery<int, int>(
        key: 'numbers',
        controller: controller,
        initialPageParam: 1,
        pageFetcher: (page) async {
          switch (page) {
            case 1:
              return const PageResult<List<int>, int>(
                data: <int>[1, 2, 3],
                nextPageParam: 2,
                hasMore: true,
              );
            case 2:
              return const PageResult<List<int>, int>(
                data: <int>[4, 5, 6],
                nextPageParam: 3,
                hasMore: true,
              );
            default:
              return const PageResult<List<int>, int>(
                data: <int>[7, 8],
                hasMore: false,
              );
          }
        },
      );

      await query.execute();
      expect(query.data, <int>[1, 2, 3]);
      expect(query.hasMore, isTrue);

      final future = query.fetchMore();
      expect(query.state, isA<QueryFetchingMore<List<int>>>());
      await future;

      expect(query.data, <int>[1, 2, 3, 4, 5, 6]);
      expect(query.hasMore, isTrue);

      await query.fetchMore();
      expect(query.data, <int>[1, 2, 3, 4, 5, 6, 7, 8]);
      expect(query.hasMore, isFalse);
    });
  });
}
