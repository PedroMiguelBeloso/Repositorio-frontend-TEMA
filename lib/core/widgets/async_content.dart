import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

class AsyncContent extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.child,
    this.isLoading = false,
    this.failure,
    this.onRetry,
    this.isEmpty = false,
  });

  final Widget child;
  final bool isLoading;
  final AppFailure? failure;
  final VoidCallback? onRetry;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (failure case final failure?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            if (onRetry case final onRetry?) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      );
    }
    if (isEmpty) {
      return const Center(child: Text('No hay datos disponibles.'));
    }
    return child;
  }
}
