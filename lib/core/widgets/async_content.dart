import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';
import 'app_error_view.dart';
import 'empty_state.dart';

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.builder,
    required this.errorMessage,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'No hay datos disponibles.',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final String errorMessage;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorView(
        failure: safeAppFailure(error, fallbackMessage: errorMessage),
        onRetry: onRetry,
      ),
      data: (data) => isEmpty?.call(data) == true
          ? EmptyState(message: emptyMessage)
          : builder(data),
    );
  }
}
