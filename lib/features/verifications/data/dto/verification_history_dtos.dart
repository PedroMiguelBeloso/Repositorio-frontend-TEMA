import '../../../services/model/service_models.dart';
import '../../model/new_verification_models.dart';
import '../../model/verification_history_models.dart';

class VerificationRunDto {
  const VerificationRunDto({
    required this.id,
    required this.serviceId,
    required this.processVersionId,
    required this.scope,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.macroActivityId,
    this.note,
    this.finishedAt,
    this.failureMessage,
    this.serviceNameSnapshot,
    this.processNameSnapshot,
    this.processOfficialVersionSnapshot,
    this.macroActivityNameSnapshot,
  });

  final String id;
  final String serviceId;
  final String processVersionId;
  final String scope;
  final String status;
  final RunProgress progress;
  final DateTime startedAt;
  final String? macroActivityId;
  final String? note;
  final DateTime? finishedAt;
  final String? failureMessage;
  final String? serviceNameSnapshot;
  final String? processNameSnapshot;
  final String? processOfficialVersionSnapshot;
  final String? macroActivityNameSnapshot;

  factory VerificationRunDto.fromJson(Map<String, dynamic> json) {
    final rawProgress = _asMap(json['progress']);
    return VerificationRunDto(
      id: _requiredString(json, 'id'),
      serviceId: _requiredString(json, 'serviceId'),
      processVersionId: _requiredString(json, 'processVersionId'),
      scope: _requiredString(json, 'scope'),
      status: _requiredString(json, 'status'),
      progress: RunProgress.fromValues(
        total: _int(rawProgress['total']),
        processed: _int(rawProgress['processed']),
        reviewRequired: _int(rawProgress['reviewRequired']),
      ),
      startedAt: DateTime.parse(_requiredString(json, 'startedAt')),
      macroActivityId: json['macroActivityId'] as String?,
      note: _optionalString(json, 'note'),
      finishedAt: _optionalDateTime(json, 'finishedAt'),
      failureMessage: _optionalString(json, 'failureMessage'),
      serviceNameSnapshot: _optionalString(json, 'serviceNameSnapshot'),
      processNameSnapshot: _optionalString(json, 'processNameSnapshot'),
      processOfficialVersionSnapshot: _optionalString(json, 'processOfficialVersionSnapshot'),
      macroActivityNameSnapshot: _optionalString(json, 'macroActivityNameSnapshot'),
    );
  }

  VerificationRun toRun() {
    return VerificationRun(
      id: id,
      serviceId: serviceId,
      processVersionId: processVersionId,
      scope: VerificationScope.fromApi(scope),
      status: VerificationRunStatus.fromApi(status),
      progress: progress,
      startedAt: startedAt,
      macroActivityId: macroActivityId,
      note: note,
      finishedAt: finishedAt,
      failureMessage: failureMessage,
      serviceNameSnapshot: serviceNameSnapshot,
      processNameSnapshot: processNameSnapshot,
      processOfficialVersionSnapshot: processOfficialVersionSnapshot,
      macroActivityNameSnapshot: macroActivityNameSnapshot,
    );
  }

  VerificationRunSummary toModel() {
    return VerificationRunSummary(
      id: id,
      serviceId: serviceId,
      processVersionId: processVersionId,
      scope: VerificationScope.fromApi(scope),
      status: VerificationRunStatus.fromApi(status),
      progress: progress,
      startedAt: startedAt,
      macroActivityId: macroActivityId,
      serviceNameSnapshot: serviceNameSnapshot,
      processNameSnapshot: processNameSnapshot,
      processOfficialVersionSnapshot: processOfficialVersionSnapshot,
      macroActivityNameSnapshot: macroActivityNameSnapshot,
    );
  }
}

class VerificationHistoryPageDto {
  const VerificationHistoryPageDto({required this.items, required this.page});

  final List<VerificationRunDto> items;
  final PageInfoDto page;

  factory VerificationHistoryPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Falta la colección de ejecuciones.');
    }

    final rawPage = json['page'];
    if (rawPage is! Map) {
      throw const FormatException('Falta la información de paginación.');
    }

    return VerificationHistoryPageDto(
      items: rawItems.map((item) {
        return VerificationRunDto.fromJson(_asMap(item));
      }).toList(),
      page: PageInfoDto.fromJson(_asMap(rawPage)),
    );
  }

  PagedResult<VerificationRunSummary> toModel() {
    return PagedResult(
      items: items.map((item) => item.toModel()).toList(),
      page: page.toModel(),
    );
  }
}

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

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Falta el campo requerido $key.');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('El campo $key debe ser texto.');
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  return value == null ? null : DateTime.parse(value);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Respuesta JSON inválida.');
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw const FormatException('Se esperaba un entero en la respuesta.');
}
