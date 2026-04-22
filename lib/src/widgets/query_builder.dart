import 'package:flutter/widgets.dart';

import '../core/query_state.dart';
import '../query/query.dart';

class QueryBuilder<T> extends StatelessWidget {
  const QueryBuilder({
    super.key,
    required this.query,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.emptyBuilder,
  });

  final Query<T> query;
  final Widget Function(BuildContext context, QueryState<T> state)? builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )? errorBuilder;
  final Widget Function(BuildContext context, T data)? dataBuilder;
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
