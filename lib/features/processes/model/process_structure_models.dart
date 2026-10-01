import 'evidence_expectation.dart';

enum ProcessStatus {
  draft('DRAFT', 'Borrador'),
  published('PUBLISHED', 'Publicado'),
  archived('ARCHIVED', 'Archivado'),
  unknown('UNKNOWN', 'Estado no reconocido');

  const ProcessStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ProcessStatus fromApi(String? value) =>
      ProcessStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => ProcessStatus.unknown,
      );
}

class ProcessDefinition {
  const ProcessDefinition({
    required this.id,
    required this.code,
    required this.name,
    required this.m2Enabled,
  });

  final String id;
  final String code;
  final String name;
  final bool m2Enabled;

  factory ProcessDefinition.fromJson(Map<String, dynamic> json) =>
      ProcessDefinition(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        m2Enabled: json['m2Enabled'] as bool? ?? false,
      );
}

class ProcessPage<T> {
  const ProcessPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int totalPages;

  bool get hasNext => page + 1 < totalPages;
}

class ProcessVersionSummary {
  const ProcessVersionSummary({
    required this.id,
    required this.processId,
    required this.officialVersion,
    required this.versionDate,
    required this.status,
    required this.revision,
  });

  final String id;
  final String processId;
  final String officialVersion;
  final DateTime versionDate;
  final ProcessStatus status;
  final int revision;

  factory ProcessVersionSummary.fromJson(Map<String, dynamic> json) =>
      ProcessVersionSummary(
        id: json['id'] as String,
        processId: json['processId'] as String,
        officialVersion: json['officialVersion'] as String? ?? '',
        versionDate:
            DateTime.tryParse(json['versionDate'] as String? ?? '') ??
            DateTime(1970),
        status: ProcessStatus.fromApi(json['status'] as String?),
        revision: json['revision'] as int? ?? 0,
      );
}

class ProcessPolicy {
  const ProcessPolicy({this.id, required this.order, required this.text});

  final String? id;
  final int order;
  final String text;

  factory ProcessPolicy.fromJson(Map<String, dynamic> json) => ProcessPolicy(
        id: json['id'] as String?,
        order: json['order'] as int? ?? 0,
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'order': order,
        'text': text,
      };
}

class ActivityDraft {
  const ActivityDraft({
    this.id,
    required this.name,
    this.responsible,
    required this.instructions,
    this.etaText,
    required this.order,
    this.records = const [],
  });

  final String? id;
  final String name;
  final String? responsible;
  final String instructions;
  final String? etaText;
  final int order;
  final List<EvidenceExpectation> records;

  factory ActivityDraft.fromJson(
    Map<String, dynamic> json,
    Map<String, RegistryDefinition> definitions,
  ) => ActivityDraft(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        responsible: json['responsible'] as String?,
        instructions: json['instructions'] as String? ?? '',
        etaText: json['etaText'] as String?,
        order: json['order'] as int? ?? 0,
        records: _readEvidence(json['records'], definitions),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (responsible != null) 'responsible': responsible,
        'instructions': instructions,
        if (etaText != null) 'etaText': etaText,
        'order': order,
        'records': records.map((record) => record.toJson()).toList(),
      };

  ActivityDraft copyWith({List<EvidenceExpectation>? records}) =>
      ActivityDraft(
        id: id,
        name: name,
        responsible: responsible,
        instructions: instructions,
        etaText: etaText,
        order: order,
        records: records ?? this.records,
      );
}

class MacroActivityDraft {
  const MacroActivityDraft({
    this.id,
    required this.name,
    this.description,
    required this.order,
    this.inputs = const [],
    this.activities = const [],
    this.outputs = const [],
  });

  final String? id;
  final String name;
  final String? description;
  final int order;
  final List<EvidenceExpectation> inputs;
  final List<ActivityDraft> activities;
  final List<EvidenceExpectation> outputs;

  factory MacroActivityDraft.fromJson(
    Map<String, dynamic> json,
    Map<String, RegistryDefinition> definitions,
  ) => MacroActivityDraft(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        order: json['order'] as int? ?? 0,
        inputs: _readEvidence(json['inputs'], definitions),
        activities: _readMaps(json['activities'])
            .map((item) => ActivityDraft.fromJson(item, definitions))
            .toList(),
        outputs: _readEvidence(json['outputs'], definitions),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (description != null) 'description': description,
        'order': order,
        'inputs': inputs.map((item) => item.toJson()).toList(),
        'activities': activities.map((item) => item.toJson()).toList(),
        'outputs': outputs.map((item) => item.toJson()).toList(),
      };

  MacroActivityDraft copyWith({
    List<EvidenceExpectation>? inputs,
    List<ActivityDraft>? activities,
    List<EvidenceExpectation>? outputs,
  }) => MacroActivityDraft(
        id: id,
        name: name,
        description: description,
        order: order,
        inputs: inputs ?? this.inputs,
        activities: activities ?? this.activities,
        outputs: outputs ?? this.outputs,
      );
}

class ProcessVersionDraft {
  const ProcessVersionDraft({
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
  });

  final String id;
  final String processId;
  final String officialVersion;
  final DateTime versionDate;
  final ProcessStatus status;
  final int revision;
  final String objective;
  final String owner;
  final List<ProcessPolicy> policies;
  final List<MacroActivityDraft> macroActivities;

  factory ProcessVersionDraft.fromJson(
    Map<String, dynamic> json,
    Map<String, RegistryDefinition> definitions,
  ) => ProcessVersionDraft(
        id: json['id'] as String,
        processId: json['processId'] as String,
        officialVersion: json['officialVersion'] as String? ?? '',
        versionDate:
            DateTime.tryParse(json['versionDate'] as String? ?? '') ??
            DateTime(1970),
        status: ProcessStatus.fromApi(json['status'] as String?),
        revision: json['revision'] as int? ?? 0,
        objective: json['objective'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        policies: _readMaps(json['policies'])
            .map(ProcessPolicy.fromJson)
            .toList(),
        macroActivities: _readMaps(json['macroActivities'])
            .map((item) => MacroActivityDraft.fromJson(item, definitions))
            .toList(),
      );

  Map<String, dynamic> toSaveJson() => {
        'revision': revision,
        'officialVersion': officialVersion,
        'versionDate': _dateOnly(versionDate),
        'objective': objective,
        'owner': owner,
        'policies': policies.map((item) => item.toJson()).toList(),
        'macroActivities': macroActivities.map((item) => item.toJson()).toList(),
      };

  ProcessVersionDraft copyWith({
    int? revision,
    List<MacroActivityDraft>? macroActivities,
  }) => ProcessVersionDraft(
        id: id,
        processId: processId,
        officialVersion: officialVersion,
        versionDate: versionDate,
        status: status,
        revision: revision ?? this.revision,
        objective: objective,
        owner: owner,
        policies: policies,
        macroActivities: macroActivities ?? this.macroActivities,
      );
}

List<Map<String, dynamic>> _readMaps(Object? value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : const [];

List<EvidenceExpectation> _readEvidence(
  Object? value,
  Map<String, RegistryDefinition> definitions,
) => _readMaps(value).map((json) {
      final definitionId = json['registryDefinitionId'] as String? ?? '';
      final definition = definitions[definitionId] ??
          RegistryDefinition(
            id: definitionId,
            key: '',
            canonicalName: json['displayName'] as String? ?? 'Registro',
            evidenceType: EvidenceType.fromApi(json['evidenceType'] as String?),
            officialNomenclature: json['officialNomenclature'] as String?,
            preloaded: true,
          );
      return EvidenceExpectation.fromJson(json, registryDefinition: definition);
    }).toList();

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
