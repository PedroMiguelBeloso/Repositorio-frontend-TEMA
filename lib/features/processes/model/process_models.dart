enum M1ProcessCode {
  startUp('START_UP', 'Start Up'),
  takeOver('TAKE_OVER', 'Take Over'),
  supportSoftwareFactory(
    'SUPPORT_SOFTWARE_FACTORY',
    'Soporte y Software Factory',
  ),
  qualityContinuousImprovement(
    'QUALITY_CONTINUOUS_IMPROVEMENT',
    'Calidad y Mejora Continua',
  ),
  unknown('UNKNOWN', 'Proceso no reconocido');

  const M1ProcessCode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static List<M1ProcessCode> get creatableValues => const [
        startUp,
        takeOver,
        supportSoftwareFactory,
        qualityContinuousImprovement,
      ];

  static M1ProcessCode fromApi(String? value) {
    return M1ProcessCode.values.firstWhere(
      (code) => code.apiValue == value,
      orElse: () => M1ProcessCode.unknown,
    );
  }
}

enum ProcessVersionStatus {
  draft('DRAFT', 'Borrador'),
  published('PUBLISHED', 'Publicada'),
  archived('ARCHIVED', 'Archivada'),
  unknown('UNKNOWN', 'Estado no reconocido');

  const ProcessVersionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isDraft => this == ProcessVersionStatus.draft;

  static ProcessVersionStatus fromApi(String? value) {
    return ProcessVersionStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ProcessVersionStatus.unknown,
    );
  }
}

enum EvidenceType {
  document('DOCUMENT'),
  folder('FOLDER'),
  ticket('TICKET'),
  imputations('IMPUTATIONS'),
  toolRecord('TOOL_RECORD'),
  unknown('UNKNOWN');

  const EvidenceType(this.apiValue);
  final String apiValue;

  static EvidenceType fromApi(String? value) {
    return EvidenceType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => EvidenceType.unknown,
    );
  }
}

enum ApplicabilityMode {
  always('ALWAYS'),
  caseDependent('CASE_DEPENDENT'),
  unknown('UNKNOWN');

  const ApplicabilityMode(this.apiValue);
  final String apiValue;

  static ApplicabilityMode fromApi(String? value) {
    return ApplicabilityMode.values.firstWhere(
      (mode) => mode.apiValue == value,
      orElse: () => ApplicabilityMode.unknown,
    );
  }
}

enum EvidenceCardinality {
  one('ONE'),
  multiple('MULTIPLE'),
  unknown('UNKNOWN');

  const EvidenceCardinality(this.apiValue);
  final String apiValue;

  static EvidenceCardinality fromApi(String? value) {
    return EvidenceCardinality.values.firstWhere(
      (cardinality) => cardinality.apiValue == value,
      orElse: () => EvidenceCardinality.unknown,
    );
  }
}

enum EvidenceLocation {
  input('INPUT'),
  activityRecord('ACTIVITY_RECORD'),
  output('OUTPUT'),
  unknown('UNKNOWN');

  const EvidenceLocation(this.apiValue);
  final String apiValue;

  static EvidenceLocation fromApi(String? value) {
    return EvidenceLocation.values.firstWhere(
      (location) => location.apiValue == value,
      orElse: () => EvidenceLocation.unknown,
    );
  }
}

class ProcessDefinition {
  const ProcessDefinition({
    required this.id,
    required this.code,
    required this.name,
    required this.m2Enabled,
    required this.createdAt,
  });

  final String id;
  final M1ProcessCode code;
  final String name;
  final bool m2Enabled;
  final DateTime createdAt;

  String get displayName => code == M1ProcessCode.unknown ? name : code.label;
}

class EvidenceExpectation {
  const EvidenceExpectation({
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
  final EvidenceType evidenceType;
  final ApplicabilityMode applicability;
  final EvidenceCardinality cardinality;
  final EvidenceLocation location;
  final int order;
  final String? officialNomenclature;

  EvidenceExpectation copyWith({int? order}) {
    return EvidenceExpectation(
      id: id,
      registryDefinitionId: registryDefinitionId,
      displayName: displayName,
      evidenceType: evidenceType,
      applicability: applicability,
      cardinality: cardinality,
      location: location,
      order: order ?? this.order,
      officialNomenclature: officialNomenclature,
    );
  }
}

class ProcessPolicy {
  const ProcessPolicy({
    required this.localKey,
    required this.order,
    required this.text,
    this.id,
  });

  final String localKey;
  final String? id;
  final int order;
  final String text;

  ProcessPolicy copyWith({String? text, int? order}) {
    return ProcessPolicy(
      localKey: localKey,
      id: id,
      order: order ?? this.order,
      text: text ?? this.text,
    );
  }
}

class ProcessActivity {
  const ProcessActivity({
    required this.localKey,
    required this.name,
    required this.responsible,
    required this.instructions,
    required this.etaText,
    required this.order,
    required this.records,
    this.id,
  });

  final String localKey;
  final String? id;
  final String name;
  final String responsible;
  final String instructions;
  final String etaText;
  final int order;
  final List<EvidenceExpectation> records;

  ProcessActivity copyWith({
    String? name,
    String? responsible,
    String? instructions,
    String? etaText,
    int? order,
    List<EvidenceExpectation>? records,
  }) {
    return ProcessActivity(
      localKey: localKey,
      id: id,
      name: name ?? this.name,
      responsible: responsible ?? this.responsible,
      instructions: instructions ?? this.instructions,
      etaText: etaText ?? this.etaText,
      order: order ?? this.order,
      records: records ?? this.records,
    );
  }
}

class ProcessMacroActivity {
  const ProcessMacroActivity({
    required this.localKey,
    required this.name,
    required this.description,
    required this.order,
    required this.inputs,
    required this.activities,
    required this.outputs,
    this.id,
  });

  final String localKey;
  final String? id;
  final String name;
  final String description;
  final int order;
  final List<EvidenceExpectation> inputs;
  final List<ProcessActivity> activities;
  final List<EvidenceExpectation> outputs;

  ProcessMacroActivity copyWith({
    String? name,
    String? description,
    int? order,
    List<EvidenceExpectation>? inputs,
    List<ProcessActivity>? activities,
    List<EvidenceExpectation>? outputs,
  }) {
    return ProcessMacroActivity(
      localKey: localKey,
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      inputs: inputs ?? this.inputs,
      activities: activities ?? this.activities,
      outputs: outputs ?? this.outputs,
    );
  }
}

class ProcessVersion {
  const ProcessVersion({
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
  final ProcessVersionStatus status;
  final int revision;
  final String objective;
  final String owner;
  final List<ProcessPolicy> policies;
  final List<ProcessMacroActivity> macroActivities;
  final DateTime? publishedAt;
  final DateTime createdAt;

  ProcessVersion copyWith({
    String? officialVersion,
    DateTime? versionDate,
    int? revision,
    String? objective,
    String? owner,
    List<ProcessPolicy>? policies,
    List<ProcessMacroActivity>? macroActivities,
  }) {
    return ProcessVersion(
      id: id,
      processId: processId,
      officialVersion: officialVersion ?? this.officialVersion,
      versionDate: versionDate ?? this.versionDate,
      status: status,
      revision: revision ?? this.revision,
      objective: objective ?? this.objective,
      owner: owner ?? this.owner,
      policies: policies ?? this.policies,
      macroActivities: macroActivities ?? this.macroActivities,
      publishedAt: publishedAt,
      createdAt: createdAt,
    );
  }
}

class ProcessOverview {
  const ProcessOverview({required this.definition, required this.versions});

  final ProcessDefinition definition;
  final List<ProcessVersion> versions;

  ProcessVersion? get draftVersion {
    final drafts = versions.where((version) => version.status.isDraft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return drafts.isEmpty ? null : drafts.first;
  }

  ProcessVersion? get latestVersion {
    if (versions.isEmpty) return null;
    final sorted = [...versions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.first;
  }

  ProcessVersion? get versionToOpen => draftVersion ?? latestVersion;
  bool get hasDraft => draftVersion != null;
  bool get canStartFirstDraft => versions.isEmpty;
}
