enum ServiceType {
  supportAriba('SUPPORT_ARIBA', 'Soporte Ariba'),
  supportErp('SUPPORT_ERP', 'Soporte ERP'),
  softwareFactory('SOFTWARE_FACTORY', 'Software Factory'),
  projectSapAriba('PROJECT_SAP_ARIBA', 'Proyecto SAP Ariba'),
  projectErp('PROJECT_ERP', 'Proyecto ERP'),
  unknown('UNKNOWN', 'Tipo no reconocido');

  const ServiceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ServiceType fromApi(String? value) {
    return ServiceType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => ServiceType.unknown,
    );
  }
}

enum ServiceStatus {
  active('ACTIVE', 'Activo'),
  inactive('INACTIVE', 'Inactivo'),
  unknown('UNKNOWN', 'Estado no reconocido');

  const ServiceStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ServiceStatus fromApi(String? value) {
    return ServiceStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ServiceStatus.unknown,
    );
  }
}

enum ProcessCode {
  startUp('START_UP'),
  takeOver('TAKE_OVER'),
  supportSoftwareFactory('SUPPORT_SOFTWARE_FACTORY'),
  qualityContinuousImprovement('QUALITY_CONTINUOUS_IMPROVEMENT'),
  unknown('UNKNOWN');

  const ProcessCode(this.apiValue);

  final String apiValue;

  static ProcessCode fromApi(String? value) {
    return ProcessCode.values.firstWhere(
      (code) => code.apiValue == value,
      orElse: () => ProcessCode.unknown,
    );
  }
}

enum ProcessStatus {
  draft('DRAFT'),
  published('PUBLISHED'),
  archived('ARCHIVED'),
  unknown('UNKNOWN');

  const ProcessStatus(this.apiValue);

  final String apiValue;

  static ProcessStatus fromApi(String? value) {
    return ProcessStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ProcessStatus.unknown,
    );
  }
}

class PageInfo {
  const PageInfo({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

class PagedResult<T> {
  const PagedResult({required this.items, required this.page});

  final List<T> items;
  final PageInfo page;
}

class ProcessDefinitionSummary {
  const ProcessDefinitionSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.m2Enabled,
  });

  final String id;
  final ProcessCode code;
  final String name;
  final bool m2Enabled;
}

class ProcessVersionOption {
  const ProcessVersionOption({
    required this.id,
    required this.processId,
    required this.processName,
    required this.officialVersion,
    required this.versionDate,
    required this.status,
  });

  final String id;
  final String processId;
  final String processName;
  final String officialVersion;
  final DateTime versionDate;
  final ProcessStatus status;

  bool get isPublished => status == ProcessStatus.published;
}

class ServiceProcess {
  const ServiceProcess({
    required this.processVersionId,
    required this.processId,
    required this.processName,
    required this.officialVersion,
    required this.m2Enabled,
  });

  final String processVersionId;
  final String processId;
  final String processName;
  final String officialVersion;
  final bool m2Enabled;
}

class ServiceSource {
  const ServiceSource({
    this.driveFolderId,
    this.driveFolderName,
    this.redmineProjectId,
    this.redmineProjectName,
  });

  final String? driveFolderId;
  final String? driveFolderName;
  final String? redmineProjectId;
  final String? redmineProjectName;

  bool get hasDrive => driveFolderId?.isNotEmpty == true;
  bool get hasRedmine => redmineProjectId?.isNotEmpty == true;
}

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.client,
    required this.serviceType,
    required this.status,
    required this.revision,
    required this.processes,
    required this.sources,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String client;
  final ServiceType serviceType;
  final ServiceStatus status;
  final int revision;
  final List<ServiceProcess> processes;
  final ServiceSource sources;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceProcess? processForVersion(String processVersionId) {
    for (final process in processes) {
      if (process.processVersionId == processVersionId) return process;
    }
    return null;
  }
}

class DriveFolderOption {
  const DriveFolderOption({
    required this.id,
    required this.name,
    required this.path,
    this.webUrl,
    this.parentId,
  });

  final String id;
  final String name;
  final String path;
  final String? webUrl;
  final String? parentId;

  String get displayName => path.isNotEmpty ? path : name;
}

class RedmineProjectOption {
  const RedmineProjectOption({
    required this.id,
    required this.name,
    this.identifier,
  });

  final String id;
  final String name;
  final String? identifier;
}

class ServiceInput {
  const ServiceInput({
    required this.name,
    required this.client,
    required this.serviceType,
    required this.status,
    required this.processVersionIds,
    this.revision,
    this.driveFolderId,
    this.redmineProjectId,
  });

  final String name;
  final String client;
  final ServiceType serviceType;
  final ServiceStatus status;
  final List<String> processVersionIds;
  final int? revision;
  final String? driveFolderId;
  final String? redmineProjectId;
}

class AssignableProcessGroup {
  const AssignableProcessGroup({
    required this.process,
    required this.publishedVersions,
  });

  final ProcessDefinitionSummary process;
  final List<ProcessVersionOption> publishedVersions;
}
