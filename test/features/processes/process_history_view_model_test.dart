import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/viewmodel/process_history_view_model.dart';

import 'fake_process_repository.dart';
import 'process_test_fixtures.dart';

void main() {
  test('loads every version and creates a copied draft from this process', () async {
    final source = sampleProcessVersion();
    final earlier = ProcessVersion(
      id: 'version-0',
      processId: source.processId,
      officialVersion: '1.0',
      versionDate: DateTime(2025, 1, 1),
      status: ProcessVersionStatus.published,
      revision: source.revision,
      objective: source.objective,
      owner: source.owner,
      policies: source.policies,
      macroActivities: source.macroActivities,
      publishedAt: DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    );
    final repository = FakeProcessRepository(
      definitions: [_definition],
      versionsByProcess: {
        _definition.id: [source, earlier],
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final provider = processHistoryViewModelProvider(_definition.id);
    await container.read(provider.future);

    expect(container.read(provider).value!.versions, hasLength(2));
    final created = await container
        .read(provider.notifier)
        .createDraftVersion(
          officialVersion: '3.0',
          versionDate: DateTime(2026, 10, 1),
          copyFromVersionId: earlier.id,
        );

    expect(created, isNotNull);
    expect(repository.copyFromVersionId, earlier.id);
    expect(container.read(provider).value!.versions, hasLength(3));
  });

  test('a reader cannot create a version', () async {
    final repository = FakeProcessRepository(definitions: [_definition]);
    final container = _container(repository, isAdmin: false);
    addTearDown(container.dispose);
    final provider = processHistoryViewModelProvider(_definition.id);
    await container.read(provider.future);

    final created = await container
        .read(provider.notifier)
        .createDraftVersion(
          officialVersion: '2.0',
          versionDate: DateTime(2026, 10, 1),
        );

    expect(created, isNull);
    expect(container.read(provider).value!.actionFailure, isA<PermissionFailure>());
    expect(repository.versionsByProcess[_definition.id] ?? const [], isEmpty);
  });
}

final _definition = ProcessDefinition(
  id: 'process-1',
  code: M1ProcessCode.startUp,
  name: 'Start Up',
  m2Enabled: true,
  createdAt: DateTime(2026, 10, 1),
);

ProviderContainer _container(
  FakeProcessRepository repository, {
  bool isAdmin = true,
}) =>
    ProviderContainer(
      overrides: [
        processRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith(
          () => _TestSessionNotifier(isAdmin),
        ),
      ],
    );

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.isAdmin);

  final bool isAdmin;

  @override
  Session? build() => Session(
        role: isAdmin ? UserRole.administrator : UserRole.reader,
      );
}