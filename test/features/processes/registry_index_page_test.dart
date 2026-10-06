import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/features/processes/data/registry_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/data/registry_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/registry_definition.dart';
import 'package:proyecto_tema_frontend/features/processes/view/registry_index_page.dart';

void main() {
  testWidgets('two records show their fields and no pagination controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, [_record(0), _record(1)]);

    expect(find.text('Registro 0'), findsOneWidget);
    expect(find.text('Documento'), findsNWidgets(2));
    expect(find.text('Nomenclatura_0.pdf'), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Precargado'), findsOneWidget);
    expect(find.text('Creado por administrador'), findsOneWidget);
    expect(find.text('2 registros'), findsOneWidget);
    expect(find.byTooltip('Página siguiente'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paginates twenty-one records using the real total', (
    tester,
  ) async {
    await _pump(tester, [
      for (var index = 0; index < 21; index++) _record(index),
    ]);

    expect(find.text('Mostrando 1–20 de 21'), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 21–21 de 21'), findsOneWidget);
    expect(find.text('Registro 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and narrow layouts do not overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, [_record(0), _record(1)]);
    expect(find.text('Registro 0'), findsOneWidget);
    expect(
      find.textContaining('Nomenclatura_0.pdf', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('each selector opening starts with the complete catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registryRepositoryProvider.overrideWithValue(
            _RegistryRepository([_record(0), _record(1)]),
          ),
        ],
        child: MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => selectRegistryDefinition(context),
                child: const Text('Seleccionar'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    expect(find.text('Registro 0'), findsOneWidget);
    expect(find.text('Registro 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Registro 1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Registro 0'), findsNothing);
    await tester.tap(find.text('Registro 1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    expect(find.text('Registro 0'), findsOneWidget);
    expect(find.text('Registro 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty catalog explains that no definitions exist', (
    tester,
  ) async {
    await _pump(tester, []);
    expect(find.text('Todavía no hay registros en el índice.'), findsOneWidget);
    expect(find.text('0 registros'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, List<RegistryDefinition> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        registryRepositoryProvider.overrideWithValue(
          _RegistryRepository(items),
        ),
      ],
      child: MaterialApp(theme: appTheme, home: const RegistryIndexPage()),
    ),
  );
  await tester.pumpAndSettle();
}

RegistryDefinition _record(int index) => RegistryDefinition(
  id: '$index',
  key: 'REG-$index',
  canonicalName: 'Registro $index',
  evidenceType: EvidenceType.document,
  preloaded: index == 0,
  officialNomenclature: 'Nomenclatura_$index.pdf',
);

class _RegistryRepository implements RegistryRepository {
  _RegistryRepository(this.items);
  final List<RegistryDefinition> items;

  @override
  Future<RegistryPage> search({
    String query = '',
    int page = 0,
    int size = 20,
  }) async {
    final filtered = items
        .where(
          (item) =>
              item.canonicalName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final start = page * size;
    return RegistryPage(
      items: filtered.skip(start).take(size).toList(),
      page: page,
      size: size,
      totalElements: filtered.length,
      totalPages: (filtered.length + size - 1) ~/ size,
    );
  }

  @override
  Future<RegistryDefinition> create({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) => throw UnimplementedError();
}
