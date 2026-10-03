import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_tema_frontend/app/router/app_router.dart';
import 'package:proyecto_tema_frontend/app/router/route_names.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/data/registry_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/data/registry_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/registry_definition.dart';
import 'package:proyecto_tema_frontend/features/processes/view/process_editor_page.dart';
import 'package:proyecto_tema_frontend/features/processes/view/process_list_page.dart';

import 'fake_process_repository.dart';
import 'process_test_fixtures.dart';

void main() {
  testWidgets('administrator can create an activity from the macro detail',
      (tester) async {
    final version = sampleProcessVersion();
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {_definition.id: [version]},
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        processRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith(() => _TestSessionNotifier(
            const Session(role: UserRole.administrator))),
      ],
      child: MaterialApp(home: ProcessEditorPage(
        processId: _definition.id,
        versionId: version.id,
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estructura'));
    await tester.pumpAndSettle();
    final addActivity = find.text('Agregar actividad').last;
    await tester.ensureVisible(addActivity);
    await tester.tap(addActivity);
    await tester.pumpAndSettle();
    expect(find.text('Nombre de la actividad'), findsOneWidget);
    expect(find.text('Registros de la actividad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('administrator adds an input from the registry in the main editor',
      (tester) async {
    final version = sampleProcessVersion();
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {_definition.id: [version]},
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        processRepositoryProvider.overrideWithValue(repository),
        registryRepositoryProvider.overrideWithValue(_FakeRegistryRepository()),
        sessionProvider.overrideWith(() => _TestSessionNotifier(
            const Session(role: UserRole.administrator))),
      ],
      child: MaterialApp(home: ProcessEditorPage(
        processId: _definition.id,
        versionId: version.id,
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estructura'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agregar entrada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar entrada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir del índice de registros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highlights').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();

    expect(find.text('Highlights'), findsWidgets);
    expect(find.text('Entradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new-process selector shows the four visible names and sends the selected internal code',
    (tester) async {
      final repository = FakeProcessRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            processRepositoryProvider.overrideWithValue(repository),
            sessionProvider.overrideWith(
              () => _TestSessionNotifier(
                const Session(role: UserRole.administrator),
              ),
            ),
          ],
          child: const MaterialApp(home: ProcessListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo proceso').first);
      await tester.pumpAndSettle();

      expect(find.text('Start Up'), findsOneWidget);
      expect(find.text('Take Over'), findsOneWidget);
      expect(find.text('Soporte y Software Factory'), findsOneWidget);
      expect(find.text('Calidad y Mejora Continua'), findsOneWidget);
      expect(find.text('START_UP'), findsNothing);
      expect(find.text('TAKE_OVER'), findsNothing);

      await tester.tap(find.text('Calidad y Mejora Continua'));
      await tester.tap(find.text('Crear proceso'));
      await tester.pumpAndSettle();

      expect(repository.createdCode, M1ProcessCode.qualityContinuousImprovement);
      expect(find.text('Iniciar primer borrador'), findsOneWidget);
    },
  );

  testWidgets('reader can consult a draft but has no editing actions',
      (tester) async {
    final version = sampleProcessVersion();
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {
        _definition.id: [version],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
          sessionProvider.overrideWith(
            () => _TestSessionNotifier(const Session(role: UserRole.reader)),
          ),
        ],
        child: MaterialApp(
          home: ProcessEditorPage(
            processId: _definition.id,
            versionId: version.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Up'), findsWidgets);
    expect(find.text('Modo consulta'), findsOneWidget);
    expect(find.text('Objetivo vigente'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
    expect(find.textContaining('Agregar'), findsNothing);
    expect(find.byTooltip('Eliminar política'), findsNothing);
    expect(find.byTooltip('Subir política'), findsNothing);
  });

  testWidgets('a published version is read-only even for an administrator',
      (tester) async {
    final version = sampleProcessVersion(status: ProcessVersionStatus.published);
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {
        _definition.id: [version],
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          processRepositoryProvider.overrideWithValue(repository),
          sessionProvider.overrideWith(
            () => _TestSessionNotifier(
              const Session(role: UserRole.administrator),
            ),
          ),
        ],
        child: MaterialApp(
          home: ProcessEditorPage(
            processId: _definition.id,
            versionId: version.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publicada'), findsOneWidget);
    expect(find.text('Modo consulta'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
    expect(find.textContaining('Agregar'), findsNothing);
  });

  testWidgets('leaving the route with local changes shows a warning',
      (tester) async {
    final version = sampleProcessVersion();
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {
        _definition.id: [version],
      },
    );
    final container = ProviderContainer(
      overrides: [
        processRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith(
          () => _TestSessionNotifier(
            const Session(role: UserRole.administrator),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    router.go(RouteNames.processVersion(_definition.id, version.id));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final objective = find.byKey(const ValueKey('objective-7'));
    expect(objective, findsOneWidget);
    await tester.enterText(objective, 'Objetivo modificado sin guardar');
    await tester.pump();

    router.go(RouteNames.servicesPath);
    await tester.pumpAndSettle();

    expect(find.text('Cambios sin guardar'), findsWidgets);
    expect(
      find.text('Hay cambios sin guardar. Si salís ahora, se perderán.'),
      findsOneWidget,
    );
    expect(find.text('Seguir editando'), findsOneWidget);
    expect(find.text('Salir sin guardar'), findsOneWidget);

    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Datos generales'), findsWidgets);
  });
}

final _definition = ProcessDefinition(
  id: 'process-1',
  code: M1ProcessCode.startUp,
  name: 'Start Up',
  m2Enabled: true,
  createdAt: DateTime(2026, 10, 1),
);

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.initialSession);

  final Session? initialSession;

  @override
  Session? build() => initialSession;
}

class _FakeRegistryRepository implements RegistryRepository {
  static const highlight = RegistryDefinition(
    id: 'registry-highlights',
    key: 'HIGHLIGHTS',
    canonicalName: 'Highlights',
    evidenceType: EvidenceType.document,
    officialNomenclature: 'Highlights',
    preloaded: true,
  );

  @override
  Future<RegistryPage> search({String query = '', int page = 0, int size = 20})
      async => RegistryPage(items: [highlight], page: 0, totalPages: 1);

  @override
  Future<RegistryDefinition> create({required String canonicalName,
      required EvidenceType evidenceType, String? officialNomenclature}) async =>
      highlight;
}
