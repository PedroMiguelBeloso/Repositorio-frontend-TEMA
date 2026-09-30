import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/core/widgets/async_content.dart';

void main() {
  testWidgets('shows a loading indicator while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncContent<List<String>>(
            value: const AsyncLoading<List<String>>(),
            errorMessage: 'No se pudieron cargar los datos.',
            builder: (_) => const Text('Contenido'),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Contenido'), findsNothing);
  });

  testWidgets('shows an error and calls the retry callback', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncContent<List<String>>(
            value: AsyncError<List<String>>(
              const NetworkFailure('No hay conexión.'),
              StackTrace.empty,
            ),
            errorMessage: 'No se pudieron cargar los datos.',
            onRetry: () => retryCount++,
            builder: (_) => const Text('Contenido'),
          ),
        ),
      ),
    );

    expect(find.text('No hay conexión.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retryCount, 1);
  });

  testWidgets('shows the empty state when there are no items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncContent<List<String>>(
            value: const AsyncData<List<String>>([]),
            errorMessage: 'No se pudieron cargar los datos.',
            isEmpty: (items) => items.isEmpty,
            builder: (_) => const Text('Contenido'),
          ),
        ),
      ),
    );

    expect(find.text('No hay datos disponibles.'), findsOneWidget);
    expect(find.text('Contenido'), findsNothing);
  });
}
