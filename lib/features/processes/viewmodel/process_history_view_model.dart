import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../data/process_repository_provider.dart';
import '../model/process_models.dart';
import 'process_list_view_model.dart';

class ProcessHistoryState {
  const ProcessHistoryState({
    required this.process,
    required this.versions,
    this.isCreatingVersion = false,
    this.actionFailure,
  });

  final ProcessDefinition process;
  final List<ProcessVersion> versions;
  final bool isCreatingVersion;
  final AppFailure? actionFailure;

  ProcessHistoryState copyWith({
    List<ProcessVersion>? versions,
    bool? isCreatingVersion,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) =>
      ProcessHistoryState(
        process: process,
        versions: versions ?? this.versions,
        isCreatingVersion: isCreatingVersion ?? this.isCreatingVersion,
        actionFailure: clearActionFailure
            ? null
            : actionFailure ?? this.actionFailure,
      );
}

class ProcessHistoryViewModel extends AsyncNotifier<ProcessHistoryState> {
  ProcessHistoryViewModel(this.processId);

  final String processId;

  @override
  Future<ProcessHistoryState> build() async {
    final repository = ref.read(processRepositoryProvider);
    final process = await repository.getProcess(processId);
    final versions = await repository.listVersions(processId);
    return ProcessHistoryState(process: process, versions: versions);
  }

  Future<ProcessVersion?> createDraftVersion({
    required String officialVersion,
    required DateTime versionDate,
    String? copyFromVersionId,
  }) async {
    final current = state.value;
    if (current == null || current.isCreatingVersion) return null;
    if (ref.read(sessionProvider)?.isAdmin != true) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const PermissionFailure(
            'Solo un Administrador puede crear versiones.',
          ),
        ),
      );
      return null;
    }
    if (officialVersion.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'Ingresá el nombre o número de la versión oficial.',
          ),
        ),
      );
      return null;
    }
    if (copyFromVersionId != null &&
        !current.versions.any((version) => version.id == copyFromVersionId)) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'La versión de origen no pertenece a este proceso.',
          ),
        ),
      );
      return null;
    }

    state = AsyncData(
      current.copyWith(isCreatingVersion: true, clearActionFailure: true),
    );
    try {
      final created = await ref.read(processRepositoryProvider).createDraftVersion(
            processId: processId,
            officialVersion: officialVersion,
            versionDate: versionDate,
            copyFromVersionId: copyFromVersionId,
          );
      if (created.processId != processId) {
        throw const UnexpectedFailure(
          'La respuesta del borrador no pertenece al proceso seleccionado.',
        );
      }
      final versions = [...current.versions, created]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(
        current.copyWith(versions: versions, isCreatingVersion: false),
      );
      ref.invalidate(processListViewModelProvider);
      return created;
    } on AppFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          isCreatingVersion: false,
          actionFailure: failure,
        ),
      );
      return null;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isCreatingVersion: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo crear el borrador. El historial se conservó; intentá nuevamente.',
          ),
        ),
      );
      return null;
    }
  }

  void clearActionFailure() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearActionFailure: true));
  }
}

final processHistoryViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProcessHistoryViewModel, ProcessHistoryState, String>(
      ProcessHistoryViewModel.new,
    );