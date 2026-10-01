import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/process_repository_provider.dart';
import '../model/process_models.dart';

class ProcessListState {
  const ProcessListState({
    required this.items,
    this.actionFailure,
    this.isMutating = false,
  });

  final List<ProcessOverview> items;
  final AppFailure? actionFailure;
  final bool isMutating;

  List<M1ProcessCode> get availableCodes {
    final existing = items.map((item) => item.definition.code).toSet();
    return M1ProcessCode.creatableValues
        .where((code) => !existing.contains(code))
        .toList();
  }

  ProcessListState copyWith({
    List<ProcessOverview>? items,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isMutating,
  }) {
    return ProcessListState(
      items: items ?? this.items,
      actionFailure:
          clearActionFailure ? null : actionFailure ?? this.actionFailure,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class ProcessListViewModel extends AsyncNotifier<ProcessListState> {
  @override
  Future<ProcessListState> build() => _load();

  Future<ProcessListState> _load({AppFailure? actionFailure}) async {
    final repository = ref.read(processRepositoryProvider);
    final definitions = await repository.listProcesses();
    final overviews = await Future.wait(
      definitions.map((definition) async {
        final versions = await repository.listVersions(definition.id);
        return ProcessOverview(definition: definition, versions: versions);
      }),
    );
    overviews.sort(
      (a, b) => a.definition.displayName.compareTo(b.definition.displayName),
    );
    return ProcessListState(items: overviews, actionFailure: actionFailure);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<ProcessDefinition?> createDefinition(M1ProcessCode code) async {
    final current = state.value;
    if (current == null || current.isMutating) return null;

    if (!current.availableCodes.contains(code)) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'Ese proceso ya existe y no puede crearse nuevamente.',
          ),
        ),
      );
      return null;
    }

    state = AsyncData(
      current.copyWith(isMutating: true, clearActionFailure: true),
    );

    try {
      final created = await ref.read(processRepositoryProvider).createProcess(code);
      final latest = state.value ?? current;
      final items = [
        ...latest.items,
        ProcessOverview(definition: created, versions: const []),
      ]..sort(
          (a, b) =>
              a.definition.displayName.compareTo(b.definition.displayName),
        );
      state = AsyncData(latest.copyWith(items: items, isMutating: false));
      return created;
    } on ConflictFailure {
      try {
        state = AsyncData(
          await _load(
            actionFailure: const ConflictFailure(
              'Ese proceso fue creado por otro usuario mientras trabajabas. '
              'Actualizamos el listado para mostrar el estado vigente.',
            ),
          ),
        );
      } catch (_) {
        state = AsyncData(
          current.copyWith(
            isMutating: false,
            actionFailure: const ConflictFailure(
              'Ese proceso ya fue creado por otro usuario. Recargá el listado '
              'antes de volver a intentarlo.',
            ),
          ),
        );
      }
      return null;
    } on AppFailure catch (failure) {
      state = AsyncData(
        current.copyWith(isMutating: false, actionFailure: failure),
      );
      return null;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isMutating: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo crear el proceso. Intentá nuevamente.',
          ),
        ),
      );
      return null;
    }
  }

  Future<ProcessVersion?> startFirstDraft({
    required String processId,
    required String officialVersion,
    required DateTime versionDate,
  }) async {
    final current = state.value;
    if (current == null || current.isMutating) return null;

    final overview = current.items
        .where((item) => item.definition.id == processId)
        .firstOrNull;
    if (overview == null) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'No se encontró el proceso seleccionado.',
          ),
        ),
      );
      return null;
    }
    if (!overview.canStartFirstDraft) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'Este proceso ya tiene una versión. Las versiones posteriores se '
            'gestionan desde publicación e historial.',
          ),
        ),
      );
      return null;
    }
    if (officialVersion.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(
          actionFailure: const ValidationFailure(
            'Ingresá la versión oficial antes de iniciar el borrador.',
          ),
        ),
      );
      return null;
    }

    state = AsyncData(
      current.copyWith(isMutating: true, clearActionFailure: true),
    );

    try {
      final version = await ref.read(processRepositoryProvider).createDraftVersion(
            processId: processId,
            officialVersion: officialVersion,
            versionDate: versionDate,
          );
      final latest = state.value ?? current;
      final items = latest.items.map((item) {
        if (item.definition.id != processId) return item;
        return ProcessOverview(
          definition: item.definition,
          versions: [...item.versions, version],
        );
      }).toList();
      state = AsyncData(latest.copyWith(items: items, isMutating: false));
      return version;
    } on AppFailure catch (failure) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isMutating: false, actionFailure: failure),
      );
      return null;
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isMutating: false,
          actionFailure: const UnexpectedFailure(
            'El proceso existe, pero no se pudo iniciar su borrador. '
            'Podés retomarlo desde el listado sin crear otra definición.',
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

final processListViewModelProvider =
    AsyncNotifierProvider<ProcessListViewModel, ProcessListState>(
  ProcessListViewModel.new,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
