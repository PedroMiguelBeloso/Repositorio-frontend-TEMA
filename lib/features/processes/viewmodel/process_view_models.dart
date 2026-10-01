import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../data/process_repository_provider.dart';
import '../model/evidence_expectation.dart';
import '../model/process_models.dart';

final class ProcessListViewModel
    extends AsyncNotifier<List<ProcessDefinition>> {
  @override
  Future<List<ProcessDefinition>> build() async => _load();

  Future<List<ProcessDefinition>> _load() async {
    try {
      final result = await ref
          .read(processRepositoryProvider)
          .listProcesses(page: 0, size: 100);
      return result.items;
    } catch (error) {
      throw const ApiExceptionMapper().mapError(
        error,
        fallbackMessage: 'No se pudieron cargar los procesos.',
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final processListViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ProcessListViewModel,
      List<ProcessDefinition>
    >(ProcessListViewModel.new);

class ProcessDetailState {
  const ProcessDetailState({required this.process, required this.versions});

  final ProcessDefinition process;
  final List<ProcessVersionSummary> versions;
}

final class ProcessDetailViewModel extends AsyncNotifier<ProcessDetailState> {
  ProcessDetailViewModel(this.processId);

  final String processId;

  @override
  Future<ProcessDetailState> build() async {
    final repository = ref.read(processRepositoryProvider);
    final process = await repository.getProcess(processId);
    final versions = await repository.listVersions(
      processId: processId,
      page: 0,
      size: 100,
    );
    return ProcessDetailState(process: process, versions: versions.items);
  }
}

final processDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProcessDetailViewModel, ProcessDetailState, String>(
      ProcessDetailViewModel.new,
    );

enum EvidenceSection { inputs, records, outputs }

class ProcessEditorState {
  const ProcessEditorState({
    required this.draft,
    required this.definitions,
    this.isSaving = false,
    this.actionFailure,
    this.fieldErrors = const {},
  });

  final ProcessVersionDraft draft;
  final List<RegistryDefinition> definitions;
  final bool isSaving;
  final AppFailure? actionFailure;
  final Map<String, String> fieldErrors;

  ProcessEditorState copyWith({
    ProcessVersionDraft? draft,
    List<RegistryDefinition>? definitions,
    bool? isSaving,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    Map<String, String>? fieldErrors,
  }) => ProcessEditorState(
    draft: draft ?? this.draft,
    definitions: definitions ?? this.definitions,
    isSaving: isSaving ?? this.isSaving,
    actionFailure: clearActionFailure
        ? null
        : actionFailure ?? this.actionFailure,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
}

final class ProcessEditorViewModel extends AsyncNotifier<ProcessEditorState> {
  ProcessEditorViewModel(this.versionKey);

  final (String, String) versionKey;
  String? _initialFingerprint;

  String get processId => versionKey.$1;
  String get versionId => versionKey.$2;

  @override
  Future<ProcessEditorState> build() async => _load();

  Future<ProcessEditorState> _load() async {
    final draft = await ref
        .read(processRepositoryProvider)
        .getVersion(processId: processId, versionId: versionId);
    final editorState = ProcessEditorState(
      draft: draft,
      definitions: _collectDefinitions(draft),
    );
    _initialFingerprint = _fingerprint(draft);
    return editorState;
  }

  bool get hasUnsavedChanges {
    final current = state.value;
    return current != null &&
        _initialFingerprint != _fingerprint(current.draft);
  }

  bool get canEdit {
    final current = state.value?.draft;
    return ref.read(sessionProvider)?.isAdmin == true &&
        current?.status == ProcessStatus.draft;
  }

  Future<ProcessPage<RegistryDefinition>> searchRegistry({
    required String query,
    required int page,
  }) => ref
      .read(processRepositoryProvider)
      .searchRegistry(query: query, page: page, size: 20);

  Future<RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) async {
    if (!_canMutate(state.value)) {
      throw const PermissionFailure(
        'Solo un Administrador puede crear registros desde un borrador.',
      );
    }
    final created = await ref
        .read(processRepositoryProvider)
        .createRegistryDefinition(
          canonicalName: canonicalName,
          evidenceType: evidenceType,
          officialNomenclature: officialNomenclature,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          definitions: [...current.definitions, created],
          clearActionFailure: true,
        ),
      );
    }
    return created;
  }

  bool addEvidence({
    required int macroIndex,
    required EvidenceSection section,
    int? activityIndex,
    required RegistryDefinition definition,
    String displayName = '',
    ApplicabilityMode applicability = ApplicabilityMode.always,
    EvidenceCardinality cardinality = EvidenceCardinality.one,
  }) {
    final current = state.value;
    if (!_canMutate(current)) return false;
    final macro = current!.draft.macroActivities[macroIndex];
    if (section == EvidenceSection.inputs &&
        definition.evidenceType == EvidenceType.ticket &&
        macro.inputs.any(
          (item) => item.registryDefinition.evidenceType == EvidenceType.ticket,
        )) {
      _setFailure(
        current,
        const ValidationFailure(
          'Esta macroactividad ya tiene una entrada de tipo Ticket. '
          'Configure una sola entrada con cantidad «Una o varias» si corresponde.',
        ),
      );
      return false;
    }
    final evidence = EvidenceExpectation(
      registryDefinitionId: definition.id,
      registryDefinition: definition,
      displayName: displayName,
      applicability: applicability,
      cardinality: cardinality,
      order: _sectionItems(macro, section, activityIndex).length,
    );
    _updateMacro(
      current,
      macroIndex,
      (value) => _replaceSection(value, section, activityIndex, [
        ..._sectionItems(value, section, activityIndex),
        evidence,
      ]),
    );
    return true;
  }

  void updateEvidence({
    required int macroIndex,
    required EvidenceSection section,
    int? activityIndex,
    required int evidenceIndex,
    required RegistryDefinition definition,
    required String displayName,
    required ApplicabilityMode applicability,
    required EvidenceCardinality cardinality,
  }) {
    final current = state.value;
    if (!_canMutate(current)) return;
    final macro = current!.draft.macroActivities[macroIndex];
    final items = [..._sectionItems(macro, section, activityIndex)];
    final previous = items[evidenceIndex];
    items[evidenceIndex] = EvidenceExpectation(
      id: previous.id,
      registryDefinitionId: definition.id,
      registryDefinition: definition,
      displayName: displayName,
      applicability: applicability,
      cardinality: cardinality,
      order: evidenceIndex,
    );
    _updateMacro(
      current,
      macroIndex,
      (value) => _replaceSection(value, section, activityIndex, items),
    );
  }

  void removeEvidence({
    required int macroIndex,
    required EvidenceSection section,
    int? activityIndex,
    required int evidenceIndex,
  }) {
    final current = state.value;
    if (!_canMutate(current)) return;
    final macro = current!.draft.macroActivities[macroIndex];
    final items = [..._sectionItems(macro, section, activityIndex)]
      ..removeAt(evidenceIndex);
    _updateMacro(
      current,
      macroIndex,
      (value) => _replaceSection(value, section, activityIndex, items),
    );
  }

  void moveEvidence({
    required int macroIndex,
    required EvidenceSection section,
    int? activityIndex,
    required int evidenceIndex,
    required int offset,
  }) {
    final current = state.value;
    if (!_canMutate(current)) return;
    final macro = current!.draft.macroActivities[macroIndex];
    final items = [..._sectionItems(macro, section, activityIndex)];
    final target = evidenceIndex + offset;
    if (target < 0 || target >= items.length) return;
    final moved = items.removeAt(evidenceIndex);
    items.insert(target, moved);
    final reordered = [
      for (var index = 0; index < items.length; index++)
        items[index].copyWith(order: index),
    ];
    _updateMacro(
      current,
      macroIndex,
      (value) => _replaceSection(value, section, activityIndex, reordered),
    );
  }

  Future<bool> save() async {
    final current = state.value;
    if (!_canMutate(current) || current!.isSaving) return false;
    final ticketIssue = _ticketRuleFailure(current.draft);
    if (ticketIssue != null) {
      _setFailure(current, ValidationFailure(ticketIssue));
      return false;
    }

    state = AsyncData(
      current.copyWith(
        isSaving: true,
        clearActionFailure: true,
        fieldErrors: const {},
      ),
    );
    try {
      final saved = await ref
          .read(processRepositoryProvider)
          .saveDraft(current.draft, current.definitions);
      _initialFingerprint = _fingerprint(saved);
      state = AsyncData(
        current.copyWith(
          draft: saved,
          definitions: _collectDefinitions(
            saved,
            existing: current.definitions,
          ),
          isSaving: false,
          clearActionFailure: true,
          fieldErrors: const {},
        ),
      );
      return true;
    } on AppFailure catch (failure) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: failure,
          fieldErrors: failure is ValidationFailure
              ? failure.fieldErrors
              : const {},
        ),
      );
      return false;
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo guardar el borrador. Intentá nuevamente.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load());
    } catch (error, stackTrace) {
      state = AsyncError(
        const ApiExceptionMapper().mapError(
          error,
          fallbackMessage: 'No se pudo recargar el borrador.',
        ),
        stackTrace,
      );
    }
  }

  void _updateMacro(
    ProcessEditorState current,
    int macroIndex,
    MacroActivityDraft Function(MacroActivityDraft) transform,
  ) {
    final macros = [...current.draft.macroActivities];
    macros[macroIndex] = transform(macros[macroIndex]);
    state = AsyncData(
      current.copyWith(
        draft: current.draft.copyWith(macroActivities: macros),
        clearActionFailure: true,
        fieldErrors: const {},
      ),
    );
  }

  List<EvidenceExpectation> _sectionItems(
    MacroActivityDraft macro,
    EvidenceSection section,
    int? activityIndex,
  ) => switch (section) {
    EvidenceSection.inputs => macro.inputs,
    EvidenceSection.outputs => macro.outputs,
    EvidenceSection.records => macro.activities[activityIndex!].records,
  };

  MacroActivityDraft _replaceSection(
    MacroActivityDraft macro,
    EvidenceSection section,
    int? activityIndex,
    List<EvidenceExpectation> items,
  ) => switch (section) {
    EvidenceSection.inputs => macro.copyWith(inputs: _withOrder(items)),
    EvidenceSection.outputs => macro.copyWith(outputs: _withOrder(items)),
    EvidenceSection.records => macro.copyWith(
      activities: [
        for (var index = 0; index < macro.activities.length; index++)
          if (index == activityIndex)
            macro.activities[index].copyWith(records: _withOrder(items))
          else
            macro.activities[index],
      ],
    ),
  };

  List<EvidenceExpectation> _withOrder(List<EvidenceExpectation> items) => [
    for (var index = 0; index < items.length; index++)
      items[index].copyWith(order: index),
  ];

  bool _canMutate(ProcessEditorState? current) =>
      current != null &&
      !current.isSaving &&
      ref.read(sessionProvider)?.isAdmin == true &&
      current.draft.status == ProcessStatus.draft;

  void _setFailure(ProcessEditorState current, AppFailure failure) {
    state = AsyncData(current.copyWith(actionFailure: failure));
  }

  String? _ticketRuleFailure(ProcessVersionDraft draft) {
    for (final macro in draft.macroActivities) {
      final ticketInputs = macro.inputs
          .where(
            (item) =>
                item.registryDefinition.evidenceType == EvidenceType.ticket,
          )
          .toList();
      if (ticketInputs.length > 1) {
        return '«${macro.name}» admite una sola entrada de tipo Ticket. '
            'Use una única entrada con cantidad «Una o varias». ';
      }
      final ticketUses =
          [
            ...macro.inputs,
            ...macro.outputs,
            ...macro.activities.expand((activity) => activity.records),
          ].where(
            (item) =>
                item.registryDefinition.evidenceType == EvidenceType.ticket,
          );
      if (ticketUses.map((item) => item.cardinality).toSet().length > 1) {
        return 'Las evidencias de tipo Ticket de «${macro.name}» deben tener '
            'la misma cantidad.';
      }
    }
    return null;
  }

  String _fingerprint(ProcessVersionDraft draft) =>
      jsonEncode(draft.toSaveJson());

  List<RegistryDefinition> _collectDefinitions(
    ProcessVersionDraft draft, {
    List<RegistryDefinition> existing = const [],
  }) {
    final byId = {for (final item in existing) item.id: item};
    for (final macro in draft.macroActivities) {
      for (final expectation in [
        ...macro.inputs,
        ...macro.outputs,
        ...macro.activities.expand((activity) => activity.records),
      ]) {
        byId[expectation.registryDefinition.id] =
            expectation.registryDefinition;
      }
    }
    return byId.values.toList();
  }
}

final processEditorViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProcessEditorViewModel, ProcessEditorState, (String, String)>(
      ProcessEditorViewModel.new,
    );
