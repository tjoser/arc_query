import 'package:flutter/widgets.dart';

import '../core/query_state.dart';
import '../query/query.dart';

/// A Flutter widget that rebuilds from a [Query] state.
class QueryBuilder<T> extends StatelessWidget {
  /// Creates a query-driven widget builder.
  const QueryBuilder({
    super.key,
    required this.query,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.emptyBuilder,
  });

  /// The query to listen to.
  final Query<T> query;

  /// A fully custom builder that receives the raw [QueryState].
  final Widget Function(BuildContext context, QueryState<T> state)? builder;

  /// Builds the loading UI when no data is available yet.
  final WidgetBuilder? loadingBuilder;

  /// Builds the error UI when the query fails without data.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? errorBuilder;

  /// Builds the success UI when data is available.
  final Widget Function(BuildContext context, T data)? dataBuilder;

  /// Builds the empty UI when the data is `null` or an empty iterable.
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: query,
      builder: (context, _) {
        final state = query.state;

        if (builder != null) {
          return builder!(context, state);
        }

        if (state is QueryLoading<T> && !state.hasData) {
          return loadingBuilder?.call(context) ?? const SizedBox.shrink();
        }

        if (state is QueryError<T> && !state.hasData) {
          final error = state.error;
          if (error != null && errorBuilder != null) {
            return errorBuilder!(context, error, state.stackTrace);
          }
        }

        final data = state.data;
        if (data == null) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

        if (data is Iterable && data.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }

        if (dataBuilder != null) {
          return dataBuilder!(context, data);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
