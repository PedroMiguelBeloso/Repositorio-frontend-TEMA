import 'service_models.dart';

class ServiceDraft {
  ServiceDraft({
    required this.name,
    required this.client,
    required this.serviceType,
    required this.status,
    required List<ProcessVersionOption> selectedProcessVersions,
    required this.driveFolderId,
    required this.driveFolderName,
    required this.redmineProjectId,
    required this.redmineProjectName,
    this.revision,
  }) : selectedProcessVersions = List.unmodifiable(selectedProcessVersions);

  factory ServiceDraft.empty() {
    return ServiceDraft(
      name: '',
      client: '',
      serviceType: ServiceType.unknown,
      status: ServiceStatus.active,
      selectedProcessVersions: const [],
      driveFolderId: null,
      driveFolderName: null,
      redmineProjectId: null,
      redmineProjectName: null,
    );
  }

  factory ServiceDraft.fromService(
    Service service, {
    List<ProcessVersionOption> knownVersions = const [],
  }) {
    final versionsById = {
      for (final version in knownVersions) version.id: version,
    };
    final assigned = service.processes.map((assignment) {
      return versionsById[assignment.processVersionId] ??
          ProcessVersionOption(
            id: assignment.processVersionId,
            processId: assignment.processId,
            processName: assignment.processName,
            officialVersion: assignment.officialVersion,
            versionDate: DateTime.fromMillisecondsSinceEpoch(0),
            status: ProcessStatus.published,
          );
    }).toList();

    return ServiceDraft(
      name: service.name,
      client: service.client,
      serviceType: service.serviceType,
      status: service.status,
      selectedProcessVersions: assigned,
      driveFolderId: service.sources.driveFolderId,
      driveFolderName: service.sources.driveFolderName,
      redmineProjectId: service.sources.redmineProjectId,
      redmineProjectName: service.sources.redmineProjectName,
      revision: service.revision,
    );
  }

  final String name;
  final String client;
  final ServiceType serviceType;
  final ServiceStatus status;
  final List<ProcessVersionOption> selectedProcessVersions;
  final String? driveFolderId;
  final String? driveFolderName;
  final String? redmineProjectId;
  final String? redmineProjectName;
  final int? revision;

  ServiceDraft copyWith({
    String? name,
    String? client,
    ServiceType? serviceType,
    ServiceStatus? status,
    List<ProcessVersionOption>? selectedProcessVersions,
    String? driveFolderId,
    bool clearDriveFolder = false,
    String? driveFolderName,
    String? redmineProjectId,
    bool clearRedmineProject = false,
    String? redmineProjectName,
    int? revision,
  }) {
    return ServiceDraft(
      name: name ?? this.name,
      client: client ?? this.client,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      selectedProcessVersions:
          selectedProcessVersions ?? this.selectedProcessVersions,
      driveFolderId: clearDriveFolder ? null : driveFolderId ?? this.driveFolderId,
      driveFolderName:
          clearDriveFolder ? null : driveFolderName ?? this.driveFolderName,
      redmineProjectId:
          clearRedmineProject ? null : redmineProjectId ?? this.redmineProjectId,
      redmineProjectName:
          clearRedmineProject
              ? null
              : redmineProjectName ?? this.redmineProjectName,
      revision: revision ?? this.revision,
    );
  }

  /// Replaces the version assigned to a process. Two versions of the same
  /// process can never coexist in the draft.
  ServiceDraft assignProcessVersion(ProcessVersionOption version) {
    if (!version.isPublished) {
      throw ArgumentError('Solo se pueden asignar versiones publicadas.');
    }

    final next = selectedProcessVersions
        .where((item) => item.processId != version.processId)
        .toList(growable: true)
      ..add(version);

    return copyWith(selectedProcessVersions: next);
  }

  ServiceDraft removeProcess(String processId) {
    return copyWith(
      selectedProcessVersions: selectedProcessVersions
          .where((version) => version.processId != processId)
          .toList(),
    );
  }

  ServiceDraft selectDriveFolder(DriveFolderOption folder) {
    return copyWith(
      driveFolderId: folder.id,
      driveFolderName: folder.displayName,
    );
  }

  ServiceDraft clearDriveSelection() => copyWith(clearDriveFolder: true);

  ServiceDraft selectRedmineProject(RedmineProjectOption project) {
    return copyWith(
      redmineProjectId: project.id,
      redmineProjectName: project.name,
    );
  }

  ServiceDraft clearRedmineSelection() => copyWith(clearRedmineProject: true);

  List<String> get processVersionIds =>
      selectedProcessVersions.map((version) => version.id).toList();

  ServiceInput toServiceInput({required bool isEditing}) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Ingresá el nombre del servicio.');
    }
    if (client.trim().isEmpty) {
      throw ArgumentError('Ingresá el cliente.');
    }
    if (serviceType == ServiceType.unknown) {
      throw ArgumentError('Seleccioná un tipo de servicio.');
    }
    if (status == ServiceStatus.unknown) {
      throw ArgumentError('Seleccioná un estado válido.');
    }
    if (isEditing && revision == null) {
      throw StateError('La revisión es obligatoria para editar el servicio.');
    }

    final duplicateProcessIds = <String>{};
    for (final version in selectedProcessVersions) {
      if (!duplicateProcessIds.add(version.processId)) {
        throw StateError('Solo puede haber una versión por proceso.');
      }
      if (!version.isPublished) {
        throw StateError('Solo se pueden asignar versiones publicadas.');
      }
    }

    return ServiceInput(
      name: name.trim(),
      client: client.trim(),
      serviceType: serviceType,
      status: status,
      processVersionIds: List.unmodifiable(processVersionIds),
      revision: isEditing ? revision : null,
      driveFolderId: driveFolderId,
      redmineProjectId: redmineProjectId,
    );
  }
}
