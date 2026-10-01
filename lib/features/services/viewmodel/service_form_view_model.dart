import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../data/service_repository_provider.dart';
import '../model/service_draft.dart';
import '../model/service_models.dart';

class ServiceFormState {
  const ServiceFormState({
    required this.draft,
    required this.processGroups,
    required this.initialDriveFolders,
    required this.initialRedmineProjects,
    this.driveFailure,
    this.redmineFailure,
    this.actionFailure,
    this.isSaving = false,
    this.savedService,
  });

  final ServiceDraft draft;
  final List<AssignableProcessGroup> processGroups;
  final List<DriveFolderOption> initialDriveFolders;
  final List<RedmineProjectOption> initialRedmineProjects;
  final AppFailure? driveFailure;
  final AppFailure? redmineFailure;
  final AppFailure? actionFailure;
  final bool isSaving;
  final Service? savedService;

  ServiceFormState copyWith({
    ServiceDraft? draft,
    List<AssignableProcessGroup>? processGroups,
    List<DriveFolderOption>? initialDriveFolders,
    List<RedmineProjectOption>? initialRedmineProjects,
    AppFailure? driveFailure,
    bool clearDriveFailure = false,
    AppFailure? redmineFailure,
    bool clearRedmineFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isSaving,
    Service? savedService,
    bool clearSavedService = false,
  }) {
    return ServiceFormState(
      draft: draft ?? this.draft,
      processGroups: processGroups ?? this.processGroups,
      initialDriveFolders:
          initialDriveFolders ?? this.initialDriveFolders,
      initialRedmineProjects:
          initialRedmineProjects ?? this.initialRedmineProjects,
      driveFailure:
          clearDriveFailure ? null : driveFailure ?? this.driveFailure,
      redmineFailure: clearRedmineFailure
          ? null
          : redmineFailure ?? this.redmineFailure,
      actionFailure:
          clearActionFailure ? null : actionFailure ?? this.actionFailure,
      isSaving: isSaving ?? this.isSaving,
      savedService:
          clearSavedService ? null : savedService ?? this.savedService,
    );
  }
}

class ServiceFormViewModel extends AsyncNotifier<ServiceFormState> {
  ServiceFormViewModel(this.serviceId);

  final String? serviceId;

  ServiceDraft? _initialDraft;

  @override
  Future<ServiceFormState> build() => _loadFormState();

  Future<ServiceFormState> _loadFormState() async {
    final repository = ref.read(serviceRepositoryProvider);

    final service = serviceId == null
        ? null
        : await repository.getService(serviceId!);

    final processGroups =
        await repository.getAssignableProcessVersions();

    final draft = service == null
        ? ServiceDraft.empty()
        : ServiceDraft.fromService(
            service,
            knownVersions: [
              for (final group in processGroups)
                ...group.publishedVersions,
            ],
          );

    _initialDraft = draft;

    AppFailure? driveFailure;
    List<DriveFolderOption> driveFolders = const [];

    try {
      final result = await repository.getDriveFolders(
        page: 0,
        size: 20,
      );

      driveFolders = result.items;
    } on AppFailure catch (failure) {
      driveFailure = failure;
    }

    AppFailure? redmineFailure;
    List<RedmineProjectOption> redmineProjects = const [];

    try {
      final result = await repository.getRedmineProjects(
        page: 0,
        size: 20,
      );

      redmineProjects = result.items;
    } on AppFailure catch (failure) {
      redmineFailure = failure;
    }

    return ServiceFormState(
      draft: draft,
      processGroups: processGroups,
      initialDriveFolders: driveFolders,
      initialRedmineProjects: redmineProjects,
      driveFailure: driveFailure,
      redmineFailure: redmineFailure,
    );
  }

  bool get hasUnsavedChanges {
    final current = state.value;
    final original = _initialDraft;

    if (current == null || original == null) {
      return false;
    }

    return _fingerprint(current.draft) != _fingerprint(original);
  }

  void updateName(String value) {
    _updateDraft(
      (draft) => draft.copyWith(name: value),
    );
  }

  void updateClient(String value) {
    _updateDraft(
      (draft) => draft.copyWith(client: value),
    );
  }

  void updateServiceType(ServiceType value) {
    _updateDraft(
      (draft) => draft.copyWith(serviceType: value),
    );
  }

  void updateStatus(ServiceStatus value) {
    _updateDraft(
      (draft) => draft.copyWith(status: value),
    );
  }

  void assignProcessVersion(ProcessVersionOption? version) {
    if (version == null) {
      return;
    }

    _updateDraft(
      (draft) => draft.assignProcessVersion(version),
    );
  }

  void clearProcess(String processId) {
    _updateDraft(
      (draft) => draft.removeProcess(processId),
    );
  }

  void selectDriveFolder(DriveFolderOption folder) {
    _updateDraft(
      (draft) => draft.selectDriveFolder(folder),
    );
  }

  void clearDriveFolder() {
    _updateDraft(
      (draft) => draft.clearDriveSelection(),
    );
  }

  void selectRedmineProject(RedmineProjectOption project) {
    _updateDraft(
      (draft) => draft.selectRedmineProject(project),
    );
  }

  void clearRedmineProject() {
    _updateDraft(
      (draft) => draft.clearRedmineSelection(),
    );
  }

  Future<PagedResult<DriveFolderOption>> searchDriveFolders({
    String query = '',
    required int page,
  }) async {
    final current = state.value;
    if (current != null && current.driveFailure != null) {
      state = AsyncData(
        current.copyWith(
          clearDriveFailure: true,
        ),
      );
    }

    return ref.read(serviceRepositoryProvider).getDriveFolders(
          query: query,
          page: page,
          size: 10,
        );
  }

  Future<PagedResult<RedmineProjectOption>> getRedmineProjects({
    required int page,
  }) async {
    final current = state.value;
    if (current != null && current.redmineFailure != null) {
      state = AsyncData(
        current.copyWith(
          clearRedmineFailure: true,
        ),
      );
    }

    return ref.read(serviceRepositoryProvider).getRedmineProjects(
          page: page,
          size: 10,
        );
  }

  Future<void> save() async {
    final current = state.value;

    if (current == null || current.isSaving) {
      return;
    }

    try {
      final input = current.draft.toServiceInput(
        isEditing: serviceId != null,
      );

      state = AsyncData(
        current.copyWith(
          isSaving: true,
          clearActionFailure: true,
        ),
      );

      final repository = ref.read(serviceRepositoryProvider);

      final saved = serviceId == null
          ? await repository.createService(input)
          : await repository.updateService(
              serviceId!,
              input,
            );

      _initialDraft = ServiceDraft.fromService(
        saved,
        knownVersions: [
          for (final group in current.processGroups)
            ...group.publishedVersions,
        ],
      );

      state = AsyncData(
        current.copyWith(
          draft: _initialDraft!,
          isSaving: false,
          savedService: saved,
        ),
      );
    } on AppFailure catch (failure) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: failure,
        ),
      );
    } on ArgumentError catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure:
              ValidationFailure(error.message.toString()),
        ),
      );
    } on StateError catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure:
              ValidationFailure(error.message.toString()),
        ),
      );
    } catch (_) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSaving: false,
          actionFailure: const UnexpectedFailure(
            'No se pudo guardar el servicio. Intentá nuevamente.',
          ),
        ),
      );
    }
  }

  void clearActionFailure() {
    final current = state.value;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        clearActionFailure: true,
      ),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    _initialDraft = null;

    try {
      state = AsyncData(
        await _loadFormState(),
      );
    } catch (error, stackTrace) {
      final failure = error is AppFailure
          ? error
          : const UnexpectedFailure(
              'No se pudo recargar el servicio.',
            );

      state = AsyncError(
        failure,
        stackTrace,
      );
    }
  }

  void _updateDraft(
    ServiceDraft Function(ServiceDraft) transform,
  ) {
    final current = state.value;

    if (current == null || current.isSaving) {
      return;
    }

    try {
      state = AsyncData(
        current.copyWith(
          draft: transform(current.draft),
          clearActionFailure: true,
          clearSavedService: true,
        ),
      );
    } on ArgumentError catch (error) {
      state = AsyncData(
        current.copyWith(
          actionFailure:
              ValidationFailure(error.message.toString()),
        ),
      );
    }
  }

  String _fingerprint(ServiceDraft draft) {
    final ids = [...draft.processVersionIds]..sort();

    return [
      draft.name.trim(),
      draft.client.trim(),
      draft.serviceType.apiValue,
      draft.status.apiValue,
      ids.join(','),
      draft.driveFolderId ?? '',
      draft.redmineProjectId ?? '',
      draft.revision?.toString() ?? '',
    ].join('|');
  }
}

final serviceFormViewModelProvider =
    AsyncNotifierProvider.family<
        ServiceFormViewModel,
        ServiceFormState,
        String?>(
  ServiceFormViewModel.new,
  isAutoDispose: true,
);