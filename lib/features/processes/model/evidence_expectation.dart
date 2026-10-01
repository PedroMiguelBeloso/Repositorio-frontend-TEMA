enum EvidenceType {
  document('DOCUMENT', 'Documento'),
  folder('FOLDER', 'Carpeta'),
  ticket('TICKET', 'Ticket'),
  imputations('IMPUTATIONS', 'Imputaciones'),
  toolRecord('TOOL_RECORD', 'Registro de herramienta'),
  unknown('UNKNOWN', 'Tipo no reconocido');

  const EvidenceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EvidenceType fromApi(String? value) => EvidenceType.values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => EvidenceType.unknown,
  );
}

enum ApplicabilityMode {
  always('ALWAYS', 'Siempre'),
  caseDependent('CASE_DEPENDENT', 'Depende del caso');

  const ApplicabilityMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ApplicabilityMode fromApi(String? value) =>
      ApplicabilityMode.values.firstWhere(
        (mode) => mode.apiValue == value,
        orElse: () => ApplicabilityMode.always,
      );
}

enum EvidenceCardinality {
  one('ONE', 'Una'),
  multiple('MULTIPLE', 'Una o varias');

  const EvidenceCardinality(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EvidenceCardinality fromApi(String? value) =>
      EvidenceCardinality.values.firstWhere(
        (cardinality) => cardinality.apiValue == value,
        orElse: () => EvidenceCardinality.one,
      );
}

class RegistryDefinition {
  const RegistryDefinition({
    required this.id,
    required this.key,
    required this.canonicalName,
    required this.evidenceType,
    this.officialNomenclature,
    required this.preloaded,
  });

  final String id;
  final String key;
  final String canonicalName;
  final EvidenceType evidenceType;
  final String? officialNomenclature;
  final bool preloaded;

  bool get requiresNomenclature =>
      evidenceType == EvidenceType.document ||
      evidenceType == EvidenceType.folder;
}

class EvidenceExpectation {
  const EvidenceExpectation({
    this.id,
    required this.registryDefinitionId,
    required this.registryDefinition,
    this.displayName = '',
    this.applicability = ApplicabilityMode.always,
    this.cardinality = EvidenceCardinality.one,
    required this.order,
  });

  final String? id;
  final String registryDefinitionId;
  final RegistryDefinition registryDefinition;
  final String displayName;
  final ApplicabilityMode applicability;
  final EvidenceCardinality cardinality;
  final int order;

  String get effectiveName => displayName.trim().isEmpty
      ? registryDefinition.canonicalName
      : displayName.trim();

  EvidenceExpectation copyWith({
    String? id,
    String? displayName,
    ApplicabilityMode? applicability,
    EvidenceCardinality? cardinality,
    int? order,
  }) {
    return EvidenceExpectation(
      id: id ?? this.id,
      registryDefinitionId: registryDefinitionId,
      registryDefinition: registryDefinition,
      displayName: displayName ?? this.displayName,
      applicability: applicability ?? this.applicability,
      cardinality: cardinality ?? this.cardinality,
      order: order ?? this.order,
    );
  }

  factory EvidenceExpectation.fromJson(
    Map<String, dynamic> json, {
    required RegistryDefinition registryDefinition,
  }) {
    return EvidenceExpectation(
      id: json['id'] as String?,
      registryDefinitionId: json['registryDefinitionId'] as String,
      registryDefinition: registryDefinition,
      displayName: json['displayName'] as String? ?? '',
      applicability: ApplicabilityMode.fromApi(
        json['applicability'] as String?,
      ),
      cardinality: EvidenceCardinality.fromApi(json['cardinality'] as String?),
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'registryDefinitionId': registryDefinitionId,
    if (displayName.trim().isNotEmpty) 'displayName': displayName.trim(),
    'applicability': applicability.apiValue,
    'cardinality': cardinality.apiValue,
    'order': order,
  };
}
