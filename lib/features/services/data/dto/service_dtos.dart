import '../../model/service_models.dart';

class PageInfoDto {
  const PageInfoDto({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory PageInfoDto.fromJson(Map<String, dynamic> json) {
    return PageInfoDto(
      page: _int(json['page']),
      size: _int(json['size']),
      totalElements: _int(json['totalElements']),
      totalPages: _int(json['totalPages']),
    );
  }

  PageInfo toModel() {
    return PageInfo(
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
    );
  }
}

class ServiceProcessDto {
  const ServiceProcessDto({
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

  factory ServiceProcessDto.fromJson(Map<String, dynamic> json) {
    return ServiceProcessDto(
      processVersionId: json['processVersionId'] as String,
      processId: json['processId'] as String,
      processName: json['processName'] as String,
      officialVersion: json['officialVersion'] as String,
      m2Enabled: json['m2Enabled'] as bool,
    );
  }

  ServiceProcess toModel() {
    return ServiceProcess(
      processVersionId: processVersionId,
      processId: processId,
      processName: processName,
      officialVersion: officialVersion,
      m2Enabled: m2Enabled,
    );
  }
}

class ServiceSourceDto {
  const ServiceSourceDto({
    this.driveFolderId,
    this.driveFolderName,
    this.redmineProjectId,
    this.redmineProjectName,
  });

  final String? driveFolderId;
  final String? driveFolderName;
  final String? redmineProjectId;
  final String? redmineProjectName;

  factory ServiceSourceDto.fromJson(Map<String, dynamic>? json) {
    return ServiceSourceDto(
      driveFolderId: json?['driveFolderId'] as String?,
      driveFolderName: json?['driveFolderName'] as String?,
      redmineProjectId: json?['redmineProjectId'] as String?,
      redmineProjectName: json?['redmineProjectName'] as String?,
    );
  }

  ServiceSource toModel() {
    return ServiceSource(
      driveFolderId: driveFolderId,
      driveFolderName: driveFolderName,
      redmineProjectId: redmineProjectId,
      redmineProjectName: redmineProjectName,
    );
  }
}

class ServiceDto {
  const ServiceDto({
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
  final String serviceType;
  final String status;
  final int revision;
  final List<ServiceProcessDto> processes;
  final ServiceSourceDto sources;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id'] as String,
      name: json['name'] as String,
      client: json['client'] as String,
      serviceType: json['serviceType'] as String,
      status: json['status'] as String,
      revision: _int(json['revision']),
      processes: (json['processes'] as List<dynamic>? ?? const [])
          .map((item) => ServiceProcessDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      sources: ServiceSourceDto.fromJson(
        json['sources'] as Map<String, dynamic>?,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Service toModel() {
    return Service(
      id: id,
      name: name,
      client: client,
      serviceType: ServiceType.fromApi(serviceType),
      status: ServiceStatus.fromApi(status),
      revision: revision,
      processes: processes.map((item) => item.toModel()).toList(),
      sources: sources.toModel(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ServiceWriteRequestDto {
  const ServiceWriteRequestDto({
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
  final String serviceType;
  final String status;
  final List<String> processVersionIds;
  final int? revision;
  final String? driveFolderId;
  final String? redmineProjectId;

  factory ServiceWriteRequestDto.fromModel(ServiceInput input) {
    return ServiceWriteRequestDto(
      name: input.name,
      client: input.client,
      serviceType: input.serviceType.apiValue,
      status: input.status.apiValue,
      processVersionIds: List.unmodifiable(input.processVersionIds),
      revision: input.revision,
      driveFolderId: input.driveFolderId,
      redmineProjectId: input.redmineProjectId,
    );
  }

  Map<String, dynamic> toJson({required bool includeRevision}) {
    return {
      'name': name,
      'client': client,
      'serviceType': serviceType,
      'status': status,
      'processVersionIds': processVersionIds,
      if (includeRevision && revision != null) 'revision': revision,
      if (driveFolderId != null) 'driveFolderId': driveFolderId,
      if (redmineProjectId != null) 'redmineProjectId': redmineProjectId,
    };
  }
}

class ProcessDefinitionDto {
  const ProcessDefinitionDto({
    required this.id,
    required this.code,
    required this.name,
    required this.m2Enabled,
  });

  final String id;
  final String code;
  final String name;
  final bool m2Enabled;

  factory ProcessDefinitionDto.fromJson(Map<String, dynamic> json) {
    return ProcessDefinitionDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      m2Enabled: json['m2Enabled'] as bool,
    );
  }

  ProcessDefinitionSummary toModel() {
    return ProcessDefinitionSummary(
      id: id,
      code: ProcessCode.fromApi(code),
      name: name,
      m2Enabled: m2Enabled,
    );
  }
}

class ProcessVersionDto {
  const ProcessVersionDto({
    required this.id,
    required this.processId,
    required this.officialVersion,
    required this.versionDate,
    required this.status,
  });

  final String id;
  final String processId;
  final String officialVersion;
  final DateTime versionDate;
  final String status;

  factory ProcessVersionDto.fromJson(Map<String, dynamic> json) {
    return ProcessVersionDto(
      id: json['id'] as String,
      processId: json['processId'] as String,
      officialVersion: json['officialVersion'] as String,
      versionDate: DateTime.parse(json['versionDate'] as String),
      status: json['status'] as String,
    );
  }

  ProcessVersionOption toModel({required String processName}) {
    return ProcessVersionOption(
      id: id,
      processId: processId,
      processName: processName,
      officialVersion: officialVersion,
      versionDate: versionDate,
      status: ProcessStatus.fromApi(status),
    );
  }
}

class ExternalFolderDto {
  const ExternalFolderDto({
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

  factory ExternalFolderDto.fromJson(Map<String, dynamic> json) {
    return ExternalFolderDto(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      webUrl: json['webUrl'] as String?,
      parentId: json['parentId'] as String?,
    );
  }

  DriveFolderOption toModel() {
    return DriveFolderOption(
      id: id,
      name: name,
      path: path,
      webUrl: webUrl,
      parentId: parentId,
    );
  }
}

class ExternalProjectDto {
  const ExternalProjectDto({
    required this.id,
    required this.name,
    this.identifier,
  });

  final String id;
  final String name;
  final String? identifier;

  factory ExternalProjectDto.fromJson(Map<String, dynamic> json) {
    return ExternalProjectDto(
      id: json['id'] as String,
      name: json['name'] as String,
      identifier: json['identifier'] as String?,
    );
  }

  RedmineProjectOption toModel() {
    return RedmineProjectOption(
      id: id,
      name: name,
      identifier: identifier,
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Se esperaba un entero en la respuesta del backend.');
}
