import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/viewmodel/process_view_models.dart';

void main() {
  test(
    'adds, edits, removes, and reorders evidence in the correct sections',
    () async {
      final repository = _FakeProcessRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = processEditorViewModelProvider((
        'process-1',
        'version-1',
      ));
      await container.read(provider.future);
      final editor = container.read(provider.notifier);

      expect(
        editor.addEvidence(
          macroIndex: 0,
          section: EvidenceSection.inputs,
          definition: _document,
        ),
        isTrue,
      );
      editor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        definition: _ticket,
      );
      editor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.records,
        activityIndex: 0,
        definition: _ticket,
      );
      editor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.outputs,
        definition: _document,
      );

      editor.moveEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        evidenceIndex: 1,
        offset: -1,
      );
      editor.updateEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        evidenceIndex: 0,
        definition: _ticket,
        displayName: 'Tickets del caso',
        applicability: ApplicabilityMode.caseDependent,
        cardinality: EvidenceCardinality.multiple,
      );
      editor.removeEvidence(
        macroIndex: 0,
        section: EvidenceSection.outputs,
        evidenceIndex: 0,
      );

      final state = container.read(provider).value!;
      final macro = state.draft.macroActivities.single;
      expect(macro.inputs.map((item) => item.order), [0, 1]);
      expect(macro.inputs.first.effectiveName, 'Tickets del caso');
      expect(macro.inputs.first.cardinality, EvidenceCardinality.multiple);
      expect(
        macro.activities.single.records.single.registryDefinitionId,
        _ticket.id,
      );
      expect(macro.outputs, isEmpty);
    },
  );

  test(
    'save assigns server IDs and reload preserves IDs and evidence fields',
    () async {
      final repository = _FakeProcessRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = processEditorViewModelProvider((
        'process-1',
        'version-1',
      ));
      await container.read(provider.future);
      final editor = container.read(provider.notifier);
      editor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        definition: _document,
        applicability: ApplicabilityMode.caseDependent,
        cardinality: EvidenceCardinality.multiple,
      );

      expect(await editor.save(), isTrue);
      final saved = container.read(provider).value!.draft;
      final evidence = saved.macroActivities.single.inputs.single;
      expect(evidence.id, 'server-new');
      expect(evidence.applicability, ApplicabilityMode.caseDependent);
      expect(evidence.cardinality, EvidenceCardinality.multiple);
      expect(repository.lastPayload!['macroActivities'], isA<List>());

      await editor.reload();
      final reloaded = container.read(provider).value!.draft;
      expect(reloaded.revision, 5);
      expect(reloaded.macroActivities.single.inputs.single.id, 'server-new');
      expect(reloaded.macroActivities.single.inputs.single.order, 0);
    },
  );

  test(
    'new catalog entry can be used immediately without losing the draft',
    () async {
      final repository = _FakeProcessRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = processEditorViewModelProvider((
        'process-1',
        'version-1',
      ));
      await container.read(provider.future);
      final editor = container.read(provider.notifier);

      final definition = await editor.createRegistryDefinition(
        canonicalName: 'Highlights',
        evidenceType: EvidenceType.toolRecord,
      );
      editor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.outputs,
        definition: definition,
        displayName: 'Resumen enviado',
      );

      final state = container.read(provider).value!;
      expect(state.definitions.any((item) => item.id == definition.id), isTrue);
      expect(
        state.draft.macroActivities.single.outputs.single.effectiveName,
        'Resumen enviado',
      );
      expect(state.draft.objective, 'Objetivo');
      expect(repository.createRegistryCalls, 1);
    },
  );

  test(
    'preserves existing evidence IDs and blocks a second Ticket input',
    () async {
      final repository = _FakeProcessRepository(
        draft: _makeDraft(
          inputs: [
            EvidenceExpectation(
              id: 'expectation-existing',
              registryDefinitionId: _ticket.id,
              registryDefinition: _ticket,
              order: 0,
            ),
          ],
        ),
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final provider = processEditorViewModelProvider((
        'process-1',
        'version-1',
      ));
      await container.read(provider.future);
      final editor = container.read(provider.notifier);

      expect(
        editor.addEvidence(
          macroIndex: 0,
          section: EvidenceSection.inputs,
          definition: _ticket,
        ),
        isFalse,
      );
      editor.updateEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        evidenceIndex: 0,
        definition: _ticket,
        displayName: 'Ticket con requerimiento',
        applicability: ApplicabilityMode.always,
        cardinality: EvidenceCardinality.one,
      );

      expect(await editor.save(), isTrue);
      expect(
        repository.lastPayload!['macroActivities'][0]['inputs'][0]['id'],
        'expectation-existing',
      );
    },
  );

  test('reader and non-draft versions are read only', () async {
    final readerContainer = _container(
      _FakeProcessRepository(),
      role: UserRole.reader,
    );
    addTearDown(readerContainer.dispose);
    final readerProvider = processEditorViewModelProvider((
      'process-1',
      'version-1',
    ));
    await readerContainer.read(readerProvider.future);
    final readerEditor = readerContainer.read(readerProvider.notifier);
    expect(readerEditor.canEdit, isFalse);
    expect(
      readerEditor.addEvidence(
        macroIndex: 0,
        section: EvidenceSection.inputs,
        definition: _document,
      ),
      isFalse,
    );
    await expectLater(
      readerEditor.createRegistryDefinition(
        canonicalName: 'No autorizado',
        evidenceType: EvidenceType.toolRecord,
      ),
      throwsA(isA<PermissionFailure>()),
    );
    expect(
      (readerContainer.read(processRepositoryProvider)
              as _FakeProcessRepository)
          .createRegistryCalls,
      0,
    );

    final publishedContainer = _container(
      _FakeProcessRepository(
        draft: _makeDraft(status: ProcessStatus.published),
      ),
    );
    addTearDown(publishedContainer.dispose);
    final publishedProvider = processEditorViewModelProvider((
      'process-1',
      'version-1',
    ));
    await publishedContainer.read(publishedProvider.future);
    expect(
      publishedContainer.read(publishedProvider.notifier).canEdit,
      isFalse,
    );
  });
}

final _document = RegistryDefinition(
  id: 'registry-document',
  key: 'doc',
  canonicalName: 'Orden de transporte',
  evidenceType: EvidenceType.document,
  officialNomenclature: 'OT-001',
  preloaded: true,
);

final _ticket = RegistryDefinition(
  id: 'registry-ticket',
  key: 'ticket',
  canonicalName: 'Ticket',
  evidenceType: EvidenceType.ticket,
  preloaded: true,
);

ProcessVersionDraft _makeDraft({
  ProcessStatus status = ProcessStatus.draft,
  List<EvidenceExpectation> inputs = const [],
}) => ProcessVersionDraft(
  id: 'version-1',
  processId: 'process-1',
  officialVersion: '1.0',
  versionDate: DateTime(2026, 10, 1),
  status: status,
  revision: 4,
  objective: 'Objetivo',
  owner: 'Responsable',
  policies: const [],
  macroActivities: [
    MacroActivityDraft(
      id: 'macro-1',
      name: 'Gestionar requerimiento',
      order: 0,
      inputs: inputs,
      activities: const [
        ActivityDraft(
          id: 'activity-1',
          name: 'Resolver',
          instructions: 'Resolver el requerimiento.',
          order: 0,
        ),
      ],
    ),
  ],
);

ProviderContainer _container(
  ProcessRepository repository, {
  UserRole role = UserRole.administrator,
}) => ProviderContainer(
  overrides: [
    processRepositoryProvider.overrideWithValue(repository),
    sessionProvider.overrideWith(() => _TestSessionNotifier(role)),
  ],
);

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.role);

  final UserRole role;

  @override
  Session? build() => Session(role: role);
}

class _FakeProcessRepository implements ProcessRepository {
  _FakeProcessRepository({ProcessVersionDraft? draft})
    : loadedDraft = draft ?? _makeDraft();

  ProcessVersionDraft loadedDraft;
  Map<String, dynamic>? lastPayload;
  var createRegistryCalls = 0;

  @override
  Future<ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  }) async => loadedDraft;

  @override
  Future<ProcessVersionDraft> saveDraft(
    ProcessVersionDraft draft,
    List<RegistryDefinition> definitions,
  ) async {
    lastPayload = draft.toSaveJson();
    final macros = [
      for (final macro in draft.macroActivities)
        macro.copyWith(
          inputs: [
            for (var index = 0; index < macro.inputs.length; index++)
              macro.inputs[index].copyWith(
                id: macro.inputs[index].id ?? 'server-new',
                order: index,
              ),
          ],
        ),
    ];
    loadedDraft = draft.copyWith(
      revision: draft.revision + 1,
      macroActivities: macros,
    );
    return loadedDraft;
  }

  @override
  Future<ProcessPage<RegistryDefinition>> searchRegistry({
    required String query,
    required int page,
    required int size,
  }) async =>
      ProcessPage(items: [_document, _ticket], page: page, totalPages: 1);

  @override
  Future<RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) async {
    createRegistryCalls++;
    return RegistryDefinition(
      id: 'new-registry',
      key: 'generated-key',
      canonicalName: canonicalName,
      evidenceType: evidenceType,
      officialNomenclature: officialNomenclature,
      preloaded: false,
    );
  }

  @override
  Future<ProcessDefinition> getProcess(String processId) async =>
      const ProcessDefinition(
        id: 'process-1',
        code: 'SUPPORT_SOFTWARE_FACTORY',
        name: 'Soporte y Software Factory',
        m2Enabled: true,
      );

  @override
  Future<ProcessPage<ProcessDefinition>> listProcesses({
    required int page,
    required int size,
  }) async => const ProcessPage(items: [], page: 0, totalPages: 0);

  @override
  Future<ProcessPage<ProcessVersionSummary>> listVersions({
    required String processId,
    required int page,
    required int size,
  }) async => const ProcessPage(items: [], page: 0, totalPages: 0);
}
