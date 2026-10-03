import '../../model/process_models.dart';

class ProcessDefinitionDto {
  const ProcessDefinitionDto({
    required this.id,
    required this.code,
    required this.name,
    required this.m2Enabled,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final bool m2Enabled;
  final DateTime createdAt;

  factory ProcessDefinitionDto.fromJson(Map<String, dynamic> json) {
    return ProcessDefinitionDto(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      name: _requiredString(json, 'name'),
      m2Enabled: _requiredBool(json, 'm2Enabled'),
      createdAt: _requiredDateTime(json, 'createdAt'),
    );
  }

  ProcessDefinition toModel() => ProcessDefinition(
    id: id,
    code: M1ProcessCode.fromApi(code),
    name: name,
    m2Enabled: m2Enabled,
    createdAt: createdAt,
  );
}

class ProcessVersionDto {
  const ProcessVersionDto({
    required this.id,
    required this.processId,
    required this.officialVersion,
    required this.versionDate,
    required this.status,
    required this.revision,
    required this.objective,
    required this.owner,
    required this.policies,
    required this.macroActivities,
    required this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String processId;
  final String officialVersion;
  final DateTime versionDate;
  final String status;
  final int revision;
  final String objective;
  final String owner;
  final List<ProcessPolicyDto> policies;
  final List<ProcessMacroActivityDto> macroActivities;
  final DateTime? publishedAt;
  final DateTime createdAt;

  factory ProcessVersionDto.fromJson(Map<String, dynamic> json) {
    return ProcessVersionDto(
      id: _requiredString(json, 'id'),
      processId: _requiredString(json, 'processId'),
      officialVersion: _requiredString(json, 'officialVersion'),
      versionDate: _requiredDate(json, 'versionDate'),
      status: _requiredString(json, 'status'),
      revision: _requiredInt(json, 'revision'),
      objective: _stringOrEmpty(json['objective']),
      owner: _stringOrEmpty(json['owner']),
      policies: _listOfMaps(
        json,
        'policies',
      ).map(ProcessPolicyDto.fromJson).toList(),
      macroActivities: _listOfMaps(
        json,
        'macroActivities',
      ).map(ProcessMacroActivityDto.fromJson).toList(),
      publishedAt: _optionalDateTime(json['publishedAt']),
      createdAt: _requiredDateTime(json, 'createdAt'),
    );
  }

  ProcessVersion toModel() => ProcessVersion(
    id: id,
    processId: processId,
    officialVersion: officialVersion,
    versionDate: versionDate,
    status: ProcessVersionStatus.fromApi(status),
    revision: revision,
    objective: objective,
    owner: owner,
    policies: policies.map((policy) => policy.toModel()).toList(),
    macroActivities: macroActivities
        .map((macroActivity) => macroActivity.toModel())
        .toList(),
    publishedAt: publishedAt,
    createdAt: createdAt,
  );
}

class ProcessPolicyDto {
  const ProcessPolicyDto({
    required this.id,
    required this.order,
    required this.text,
  });

  final String id;
  final int order;
  final String text;

  factory ProcessPolicyDto.fromJson(Map<String, dynamic> json) {
    return ProcessPolicyDto(
      id: _requiredString(json, 'id'),
      order: _requiredInt(json, 'order'),
      text: _requiredString(json, 'text'),
    );
  }

  ProcessPolicy toModel() =>
      ProcessPolicy(id: id, localKey: id, order: order, text: text);
}

class ProcessMacroActivityDto {
  const ProcessMacroActivityDto({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.inputs,
    required this.activities,
    required this.outputs,
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final List<EvidenceExpectationDto> inputs;
  final List<ProcessActivityDto> activities;
  final List<EvidenceExpectationDto> outputs;

  factory ProcessMacroActivityDto.fromJson(Map<String, dynamic> json) {
    return ProcessMacroActivityDto(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      description: _stringOrEmpty(json['description']),
      order: _requiredInt(json, 'order'),
      inputs: _listOfMaps(
        json,
        'inputs',
      ).map(EvidenceExpectationDto.fromJson).toList(),
      activities: _listOfMaps(
        json,
        'activities',
      ).map(ProcessActivityDto.fromJson).toList(),
      outputs: _listOfMaps(
        json,
        'outputs',
      ).map(EvidenceExpectationDto.fromJson).toList(),
    );
  }

  ProcessMacroActivity toModel() => ProcessMacroActivity(
    id: id,
    localKey: id,
    name: name,
    description: description,
    order: order,
    inputs: inputs.map((item) => item.toModel()).toList(),
    activities: activities.map((item) => item.toModel()).toList(),
    outputs: outputs.map((item) => item.toModel()).toList(),
  );
}

class ProcessActivityDto {
  const ProcessActivityDto({
    required this.id,
    required this.name,
    required this.responsible,
    required this.instructions,
    required this.etaText,
    required this.order,
    required this.records,
  });

  final String id;
  final String name;
  final String responsible;
  final String instructions;
  final String etaText;
  final int order;
  final List<EvidenceExpectationDto> records;

  factory ProcessActivityDto.fromJson(Map<String, dynamic> json) {
    return ProcessActivityDto(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      responsible: _stringOrEmpty(json['responsible']),
      instructions: _requiredString(json, 'instructions'),
      etaText: _stringOrEmpty(json['etaText']),
      order: _requiredInt(json, 'order'),
      records: _listOfMaps(
        json,
        'records',
      ).map(EvidenceExpectationDto.fromJson).toList(),
    );
  }

  ProcessActivity toModel() => ProcessActivity(
    id: id,
    localKey: id,
    name: name,
    responsible: responsible,
    instructions: instructions,
    etaText: etaText,
    order: order,
    records: records.map((item) => item.toModel()).toList(),
  );
}

class EvidenceExpectationDto {
  const EvidenceExpectationDto({
    required this.id,
    required this.registryDefinitionId,
    required this.displayName,
    required this.evidenceType,
    required this.applicability,
    required this.cardinality,
    required this.location,
    required this.order,
    this.officialNomenclature,
  });

  final String id;
  final String registryDefinitionId;
  final String displayName;
  final String evidenceType;
  final String applicability;
  final String cardinality;
  final String location;
  final int order;
  final String? officialNomenclature;

  factory EvidenceExpectationDto.fromJson(Map<String, dynamic> json) {
    return EvidenceExpectationDto(
      id: _requiredString(json, 'id'),
      registryDefinitionId: _requiredString(json, 'registryDefinitionId'),
      displayName: _stringOrEmpty(json['displayName']),
      evidenceType: _requiredString(json, 'evidenceType'),
      applicability: _requiredString(json, 'applicability'),
      cardinality: _requiredString(json, 'cardinality'),
      location: _requiredString(json, 'location'),
      order: _requiredInt(json, 'order'),
      officialNomenclature: _optionalString(json['officialNomenclature']),
    );
  }

  EvidenceExpectation toModel() => EvidenceExpectation(
    id: id,
    registryDefinitionId: registryDefinitionId,
    displayName: displayName,
    evidenceType: EvidenceType.fromApi(evidenceType),
    applicability: ApplicabilityMode.fromApi(applicability),
    cardinality: EvidenceCardinality.fromApi(cardinality),
    location: EvidenceLocation.fromApi(location),
    order: order,
    officialNomenclature: officialNomenclature,
  );
}

class CreateProcessRequestDto {
  const CreateProcessRequestDto({required this.code, required this.name});

  final M1ProcessCode code;
  final String name;

  Map<String, dynamic> toJson() => {'code': code.apiValue, 'name': name};
}

class CreateVersionRequestDto {
  const CreateVersionRequestDto({
    required this.officialVersion,
    required this.versionDate,
    this.copyFromVersionId,
  });

  final String officialVersion;
  final DateTime versionDate;
  final String? copyFromVersionId;

  Map<String, dynamic> toJson() => {
    'officialVersion': officialVersion.trim(),
    'versionDate': _dateToApi(versionDate),
    if (copyFromVersionId != null) 'copyFromVersionId': copyFromVersionId,
  };
}

class PublishVersionRequestDto {
  const PublishVersionRequestDto({required this.revision});

  final int revision;

  Map<String, dynamic> toJson() => {'revision': revision};
}

class SaveDraftRequestDto {
  const SaveDraftRequestDto({required this.version});

  final ProcessVersion version;

  Map<String, dynamic> toJson() => {
    'revision': version.revision,
    'officialVersion': version.officialVersion.trim(),
    'versionDate': _dateToApi(version.versionDate),
    'objective': version.objective.trim(),
    'owner': version.owner.trim(),
    'policies': version.policies
        .map(
          (policy) => {
            if (policy.id != null) 'id': policy.id,
            'order': policy.order,
            'text': policy.text.trim(),
          },
        )
        .toList(),
    'macroActivities': version.macroActivities
        .map(
          (macroActivity) => {
            if (macroActivity.id != null) 'id': macroActivity.id,
            'name': macroActivity.name.trim(),
            'description': macroActivity.description.trim(),
            'order': macroActivity.order,
            'inputs': macroActivity.inputs.map(_evidenceInput).toList(),
            'activities': macroActivity.activities
                .map(
                  (activity) => {
                    if (activity.id != null) 'id': activity.id,
                    'name': activity.name.trim(),
                    'responsible': activity.responsible.trim(),
                    'instructions': activity.instructions.trim(),
                    'etaText': activity.etaText.trim(),
                    'order': activity.order,
                    'records': activity.records.map(_evidenceInput).toList(),
                  },
                )
                .toList(),
            'outputs': macroActivity.outputs.map(_evidenceInput).toList(),
          },
        )
        .toList(),
  };

  static Map<String, dynamic> _evidenceInput(EvidenceExpectation evidence) => {
    if (evidence.id != null) 'id': evidence.id,
    'registryDefinitionId': evidence.registryDefinitionId,
    if (evidence.displayName.trim().isNotEmpty)
      'displayName': evidence.displayName.trim(),
    'applicability': evidence.applicability.apiValue,
    'cardinality': evidence.cardinality.apiValue,
    'order': evidence.order,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Falta el campo $key.');
}

String _stringOrEmpty(Object? value) => value is String ? value : '';

String? _optionalString(Object? value) => value is String ? value : null;

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Falta el campo $key.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Falta el campo $key.');
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Fecha inválida en $key.');
  return parsed;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Fecha inválida en $key.');
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _optionalDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

List<Map<String, dynamic>> _listOfMaps(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Falta la colección $key.');
  return value.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    throw FormatException('Elemento inválido en $key.');
  }).toList();
}

String _dateToApi(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
