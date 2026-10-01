import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/dto/process_dtos.dart';
import '../data/process_repository_provider.dart';
import '../model/process_models.dart';
import 'process_list_view_model.dart';

typedef ProcessEditorKey = ({String processId, String versionId});

enum ProcessNodeType { macroActivity, activity }

class ProcessNodeSelection {
  const ProcessNodeSelection.macro(this.macroKey)
      : type = ProcessNodeType.macroActivity,
        activityKey = null;

  const ProcessNodeSelection.activity(this.macroKey, this.activityKey)
      : type = ProcessNodeType.activity;

  final ProcessNodeType type;
  final String macroKey;
  final String? activityKey;
}

abstract final class ProcessEditorFieldKeys {
  static const officialVersion = 'officialVersion';
  static const versionDate = 'versionDate';
  static const objective = 'objective';
  static const owner = 'owner';

  static String policyText(String localKey) => 'policy:$localKey:text';
  static String macroName(String localKey) => 'macro:$localKey:name';
  static String activityName(String localKey) => 'activity:$localKey:name';
  static String activityInstructions(String localKey) =>
      'activity:$localKey:instructions';
}

class ProcessEditorState {
  const ProcessEditorState({
    required this.definition,
    required this.version,
    this.selectedNode,
    this.validationErrors = const {},
    this.actionFailure,
    this.isSaving = false,
    this.saveSucceeded = false,
  });

  final ProcessDefinition definition;
  final ProcessVersion version;
  final ProcessNodeSelection? selectedNode;
  final Map<String, String> validationErrors;
  final AppFailure? actionFailure;
  final bool isSaving;
  final bool saveSucceeded;

  ProcessMacroActivity? get selectedMacroActivity {
    final selection = selectedNode;
    if (selection == null) return null;
    for (final macro in version.macroActivities) {
      if (macro.localKey == selection.macroKey) return macro;
    }
    return null;
  }

  ProcessActivity? get selectedActivity {
    final selection = selectedNode;
    if (selection?.type != ProcessNodeType.activity) return null;
    final macro = selectedMacroActivity;
    if (macro == null) return null;
    for (final activity in macro.activities) {
      if (activity.localKey == selection!.activityKey) return activity;
    }
    return null;
  }

  ProcessEditorState copyWith({
    ProcessVersion? version,
    ProcessNodeSelection? selectedNode,
    bool clearSelectedNode = false,
    Map<String, String>? validationErrors,
    bool clearValidationErrors = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isSaving,
    bool? saveSucceeded,
  }) {
    return ProcessEditorState(
      definition: definition,
      version: version ?? this.version,
      selectedNode:
          clearSelectedNode ? null : selectedNode ?? this.selectedNode,
      validationErrors: clearValidationErrors
          ? const {}
          : validationErrors ?? this.validationErrors,
      actionFailure:
          clearActionFailure ? null : actionFailure ?? this.actionFailure,
      isSaving: isSaving ?? this.isSaving,
      saveSucceeded: saveSucceeded ?? this.saveSucceeded,
    );
  }
}

class ProcessEditorViewModel extends AsyncNotifier<ProcessEditorState> {
  ProcessEditorViewModel(this.key);

  final ProcessEditorKey key;
  String? _initialFingerprint;
  var _temporaryId = 0;

  @override
  Future<ProcessEditorState> build() async {
    return _load(key);
  }

  Future<ProcessEditorState> _load(ProcessEditorKey key) async {
    final repository = ref.read(processRepositoryProvider);
    final definition = await repository.getProcess(key.processId);
    final version = await repository.getVersion(
      processId: key.processId,
      versionId: key.versionId,
    );

    if (version.processId != definition.id) {
      throw const UnexpectedFailure(
        'La versión recibida no pertenece al proceso seleccionado.',
      );
    }

    _initialFingerprint = _fingerprint(version);
    return ProcessEditorState(
      definition: definition,
      version: version,
      selectedNode: _initialSelection(version),
    );
  }

  bool get hasUnsavedChanges {
    final current = state.value;
    if (current == null || _initialFingerprint == null) return false;
    return _fingerprint(current.version) != _initialFingerprint;
  }

  void updateOfficialVersion(String value) {
    _updateVersion(
      (version) => version.copyWith(officialVersion: value),
    );
  }

  void updateVersionDate(DateTime value) {
    _updateVersion(
      (version) => version.copyWith(versionDate: value),
    );
  }

  void updateObjective(String value) {
    _updateVersion((version) => version.copyWith(objective: value));
  }

  void updateOwner(String value) {
    _updateVersion((version) => version.copyWith(owner: value));
  }

  void addPolicy() {
    final current = state.value;
    if (current == null || current.isSaving) return;
    final policy = ProcessPolicy(
      localKey: _nextTemporaryKey('policy'),
      order: current.version.policies.length,
      text: '',
    );
    _updateVersion(
      (version) => version.copyWith(policies: [...version.policies, policy]),
    );
  }

  void updatePolicyText(String localKey, String value) {
    _updateVersion(
      (version) => version.copyWith(
        policies: version.policies
            .map(
              (policy) => policy.localKey == localKey
                  ? policy.copyWith(text: value)
                  : policy,
            )
            .toList(),
      ),
    );
  }

  void removePolicy(String localKey) {
    _updateVersion(
      (version) => version.copyWith(
        policies: _normalizePolicies(
          version.policies
              .where((policy) => policy.localKey != localKey)
              .toList(),
        ),
      ),
    );
  }

  void movePolicy(String localKey, int delta) {
    final current = state.value;
    if (current == null) return;
    final policies = [...current.version.policies];
    final index = policies.indexWhere((policy) => policy.localKey == localKey);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= policies.length) return;
    final item = policies.removeAt(index);
    policies.insert(target, item);
    _updateVersion(
      (version) => version.copyWith(policies: _normalizePolicies(policies)),
    );
  }

  void addMacroActivity() {
    final current = state.value;
    if (current == null || current.isSaving) return;
    final macro = ProcessMacroActivity(
      localKey: _nextTemporaryKey('macro'),
      name: '',
      description: '',
      order: current.version.macroActivities.length,
      inputs: const [],
      activities: const [],
      outputs: const [],
    );
    _updateVersion(
      (version) => version.copyWith(
        macroActivities: [...version.macroActivities, macro],
      ),
      selectedNode: ProcessNodeSelection.macro(macro.localKey),
    );
  }

  void selectMacroActivity(String macroKey) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(selectedNode: ProcessNodeSelection.macro(macroKey)),
    );
  }

  void updateMacroActivity({
    required String macroKey,
    String? name,
    String? description,
  }) {
    _updateVersion(
      (version) => version.copyWith(
        macroActivities: version.macroActivities
            .map(
              (macro) => macro.localKey == macroKey
                  ? macro.copyWith(name: name, description: description)
                  : macro,
            )
            .toList(),
      ),
    );
  }

  void removeMacroActivity(String macroKey) {
    final current = state.value;
    if (current == null) return;
    final macros = _normalizeMacros(
      current.version.macroActivities
          .where((macro) => macro.localKey != macroKey)
          .toList(),
    );
    final selection = current.selectedNode;
    final shouldClearSelection = selection?.macroKey == macroKey;
    _updateVersion(
      (version) => version.copyWith(macroActivities: macros),
      clearSelectedNode: shouldClearSelection,
    );
  }

  void moveMacroActivity(String macroKey, int delta) {
    final current = state.value;
    if (current == null) return;
    final macros = [...current.version.macroActivities];
    final index = macros.indexWhere((macro) => macro.localKey == macroKey);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= macros.length) return;
    final item = macros.removeAt(index);
    macros.insert(target, item);
    _updateVersion(
      (version) => version.copyWith(
        macroActivities: _normalizeMacros(macros),
      ),
    );
  }

  void addActivity(String macroKey) {
    final current = state.value;
    if (current == null || current.isSaving) return;
    final macro = current.version.macroActivities
        .where((item) => item.localKey == macroKey)
        .firstOrNull;
    if (macro == null) return;

    final activity = ProcessActivity(
      localKey: _nextTemporaryKey('activity'),
      name: '',
      responsible: '',
      instructions: '',
      etaText: '',
      order: macro.activities.length,
      records: const [],
    );

    _updateVersion(
      (version) => version.copyWith(
        macroActivities: version.macroActivities
            .map(
              (item) => item.localKey == macroKey
                  ? item.copyWith(activities: [...item.activities, activity])
                  : item,
            )
            .toList(),
      ),
      selectedNode: ProcessNodeSelection.activity(
        macroKey,
        activity.localKey,
      ),
    );
  }

  void selectActivity(String macroKey, String activityKey) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedNode: ProcessNodeSelection.activity(macroKey, activityKey),
      ),
    );
  }

  void updateActivity({
    required String macroKey,
    required String activityKey,
    String? name,
    String? responsible,
    String? instructions,
    String? etaText,
  }) {
    _updateVersion(
      (version) => version.copyWith(
        macroActivities: version.macroActivities.map((macro) {
          if (macro.localKey != macroKey) return macro;
          return macro.copyWith(
            activities: macro.activities
                .map(
                  (activity) => activity.localKey == activityKey
                      ? activity.copyWith(
                          name: name,
                          responsible: responsible,
                          instructions: instructions,
                          etaText: etaText,
                        )
                      : activity,
                )
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  void removeActivity({
    required String macroKey,
    required String activityKey,
  }) {
    final current = state.value;
    if (current == null) return;
    final selection = current.selectedNode;
    final shouldClear = selection?.type == ProcessNodeType.activity &&
        selection?.activityKey == activityKey;

    _updateVersion(
      (version) => version.copyWith(
        macroActivities: version.macroActivities.map((macro) {
          if (macro.localKey != macroKey) return macro;
          return macro.copyWith(
            activities: _normalizeActivities(
              macro.activities
                  .where((activity) => activity.localKey != activityKey)
                  .toList(),
            ),
          );
        }).toList(),
      ),
      clearSelectedNode: shouldClear,
    );
  }

  void moveActivity({
    required String macroKey,
    required String activityKey,
    required int delta,
  }) {
    final current = state.value;
    if (current == null) return;
    final macro = current.version.macroActivities
        .where((item) => item.localKey == macroKey)
        .firstOrNull;
    if (macro == null) return;

    final activities = [...macro.activities];
    final index = activities.indexWhere(
      (activity) => activity.localKey == activityKey,
    );
    final target = index + delta;
    if (index < 0 || target < 0 || target >= activities.length) return;
    final item = activities.removeAt(index);
    activities.insert(target, item);

    _updateVersion(
      (version) => version.copyWith(
        macroActivities: version.macroActivities
            .map(
              (item) => item.localKey == macroKey
                  ? item.copyWith(
                      activities: _normalizeActivities(activities),
                    )
                  : item,
            )
            .toList(),
      ),
    );
  }

  Future<bool> save() async {
    final current = state.value;
    if (current == null || current.isSaving) return false;

    if (!current.version.status.isDraft) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const PermissionFailure(
            'Esta versión está en modo consulta y no puede modificarse.',
          ),
          saveSucceeded: false,
        ),
      );
      return false;
    }

    final validationErrors = _validate(current.version);
    if (validationErrors.isNotEmpty) {
      state = AsyncData(
        current.copyWith(
          validationErrors: validationErrors,
          actionFailure: const ValidationFailure(
            'Revisá los campos señalados antes de guardar.',
          ),
          saveSucceeded: false,
        ),
      );
      return false;
    }

    state = AsyncData(
      current.copyWith(
        isSaving: true,
        clearActionFailure: true,
        clearValidationErrors: true,
        saveSucceeded: false,
      ),
    );

    try {
      final saved = await ref.read(processRepositoryProvider).saveDraft(
            current.version,
          );
      _initialFingerprint = _fingerprint(saved);
      ref.invalidate(processListViewModelProvider);
      final selection = _selectionAfterSave(current.selectedNode, saved);
      state = AsyncData(
        current.copyWith(
          version: saved,
          selectedNode: selection,
          clearSelectedNode: selection == null,
          isSaving: false,
          clearActionFailure: true,
          clearValidationErrors: true,
          saveSucceeded: true,
        ),
      );
      return true;
    } on ValidationFailure catch (failure) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          validationErrors: _mapBackendFieldErrors(
            failure.fieldErrors,
            current.version,
          ),
          actionFailure: failure,
          saveSucceeded: false,
        ),
      );
      return false;
    } on AppFailure catch (failure) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: failure,
          saveSucceeded: false,
        ),
      );
      return false;
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo guardar el borrador. Tus cambios locales se conservaron.',
          ),
          saveSucceeded: false,
        ),
      );
      return false;
    }
  }

  Future<void> reloadFromServer() async {
    state = const AsyncLoading();
    _initialFingerprint = null;
    state = await AsyncValue.guard(() => _load(key));
  }

  void clearActionFailure() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearActionFailure: true));
  }

  void _updateVersion(
    ProcessVersion Function(ProcessVersion) transform, {
    ProcessNodeSelection? selectedNode,
    bool clearSelectedNode = false,
  }) {
    final current = state.value;
    if (current == null || current.isSaving || !current.version.status.isDraft) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        version: transform(current.version),
        selectedNode: selectedNode,
        clearSelectedNode: clearSelectedNode,
        clearActionFailure: true,
        clearValidationErrors: true,
        saveSucceeded: false,
      ),
    );
  }

  Map<String, String> _validate(ProcessVersion version) {
    final errors = <String, String>{};
    if (version.officialVersion.trim().isEmpty) {
      errors[ProcessEditorFieldKeys.officialVersion] =
          'Ingresá la versión oficial.';
    }
    if (version.objective.trim().isEmpty) {
      errors[ProcessEditorFieldKeys.objective] =
          'Ingresá el objetivo del proceso.';
    }
    if (version.owner.trim().isEmpty) {
      errors[ProcessEditorFieldKeys.owner] =
          'Ingresá el responsable del proceso.';
    }

    for (final policy in version.policies) {
      if (policy.text.trim().isEmpty) {
        errors[ProcessEditorFieldKeys.policyText(policy.localKey)] =
            'La política no puede estar vacía.';
      }
    }
    for (final macro in version.macroActivities) {
      if (macro.name.trim().isEmpty) {
        errors[ProcessEditorFieldKeys.macroName(macro.localKey)] =
            'Ingresá el nombre de la macroactividad.';
      }
      for (final activity in macro.activities) {
        if (activity.name.trim().isEmpty) {
          errors[ProcessEditorFieldKeys.activityName(activity.localKey)] =
              'Ingresá el nombre de la actividad.';
        }
        if (activity.instructions.trim().isEmpty) {
          errors[
            ProcessEditorFieldKeys.activityInstructions(activity.localKey)
          ] = 'Ingresá las instrucciones de la actividad.';
        }
      }
    }
    return errors;
  }

  Map<String, String> _mapBackendFieldErrors(
    Map<String, String> fieldErrors,
    ProcessVersion version,
  ) {
    if (fieldErrors.isEmpty) return const {};
    final mapped = <String, String>{};

    for (final entry in fieldErrors.entries) {
      final field = entry.key;
      if (field == 'officialVersion' || field.endsWith('.officialVersion')) {
        mapped[ProcessEditorFieldKeys.officialVersion] = entry.value;
        continue;
      }
      if (field == 'versionDate' || field.endsWith('.versionDate')) {
        mapped[ProcessEditorFieldKeys.versionDate] = entry.value;
        continue;
      }
      if (field == 'objective' || field.endsWith('.objective')) {
        mapped[ProcessEditorFieldKeys.objective] = entry.value;
        continue;
      }
      if (field == 'owner' || field.endsWith('.owner')) {
        mapped[ProcessEditorFieldKeys.owner] = entry.value;
        continue;
      }

      final policyMatch = RegExp(r'policies\[(\d+)\]\.text$').firstMatch(field);
      if (policyMatch != null) {
        final index = int.parse(policyMatch.group(1)!);
        if (index < version.policies.length) {
          mapped[
            ProcessEditorFieldKeys.policyText(
              version.policies[index].localKey,
            )
          ] = entry.value;
        }
        continue;
      }

      final macroMatch = RegExp(
        r'macroActivities\[(\d+)\]\.name$',
      ).firstMatch(field);
      if (macroMatch != null) {
        final index = int.parse(macroMatch.group(1)!);
        if (index < version.macroActivities.length) {
          mapped[
            ProcessEditorFieldKeys.macroName(
              version.macroActivities[index].localKey,
            )
          ] = entry.value;
        }
        continue;
      }

      final activityMatch = RegExp(
        r'macroActivities\[(\d+)\]\.activities\[(\d+)\]\.(name|instructions)$',
      ).firstMatch(field);
      if (activityMatch != null) {
        final macroIndex = int.parse(activityMatch.group(1)!);
        final activityIndex = int.parse(activityMatch.group(2)!);
        final property = activityMatch.group(3)!;
        if (macroIndex < version.macroActivities.length) {
          final macro = version.macroActivities[macroIndex];
          if (activityIndex < macro.activities.length) {
            final activity = macro.activities[activityIndex];
            mapped[property == 'name'
                ? ProcessEditorFieldKeys.activityName(activity.localKey)
                : ProcessEditorFieldKeys.activityInstructions(
                    activity.localKey,
                  )] = entry.value;
          }
        }
      }
    }

    return mapped;
  }

  String _fingerprint(ProcessVersion version) {
    return jsonEncode(SaveDraftRequestDto(version: version).toJson());
  }

  ProcessNodeSelection? _initialSelection(ProcessVersion version) {
    if (version.macroActivities.isEmpty) return null;
    return ProcessNodeSelection.macro(version.macroActivities.first.localKey);
  }

  ProcessNodeSelection? _selectionAfterSave(
    ProcessNodeSelection? previous,
    ProcessVersion saved,
  ) {
    if (previous == null) return _initialSelection(saved);

    // Existing nodes keep their server IDs, so their local keys remain stable.
    // Newly-created nodes receive server IDs after save. Select the node at the
    // same visible position when the temporary key is no longer present.
    for (final macro in saved.macroActivities) {
      if (macro.localKey == previous.macroKey) {
        if (previous.type == ProcessNodeType.macroActivity) {
          return ProcessNodeSelection.macro(macro.localKey);
        }
        final activity = macro.activities
            .where((item) => item.localKey == previous.activityKey)
            .firstOrNull;
        if (activity != null) {
          return ProcessNodeSelection.activity(macro.localKey, activity.localKey);
        }
      }
    }
    return _initialSelection(saved);
  }

  List<ProcessPolicy> _normalizePolicies(List<ProcessPolicy> policies) {
    return [
      for (var i = 0; i < policies.length; i++) policies[i].copyWith(order: i),
    ];
  }

  List<ProcessMacroActivity> _normalizeMacros(
    List<ProcessMacroActivity> macros,
  ) {
    return [
      for (var i = 0; i < macros.length; i++) macros[i].copyWith(order: i),
    ];
  }

  List<ProcessActivity> _normalizeActivities(List<ProcessActivity> activities) {
    return [
      for (var i = 0; i < activities.length; i++)
        activities[i].copyWith(order: i),
    ];
  }

  String _nextTemporaryKey(String prefix) {
    _temporaryId += 1;
    return 'tmp-$prefix-$_temporaryId';
  }
}

final processEditorViewModelProvider = AsyncNotifierProvider.family<
    ProcessEditorViewModel,
    ProcessEditorState,
    ProcessEditorKey>(
  ProcessEditorViewModel.new,
  isAutoDispose: true,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
