import '../../processes/model/process_models.dart';
import '../../processes/model/evidence_expectation.dart' as evidence_model;

/// Result status returned by the M2 results contract.
enum VerificationResultStatus {
  complies('COMPLIES', 'Cumple'),
  doesNotComply('DOES_NOT_COMPLY', 'No cumple'),
  reviewRequired('REVIEW_REQUIRED', 'Requiere revisión'),
  notApplicable('NOT_APPLICABLE', 'No aplica'),
  unknown('UNKNOWN', 'Estado no reconocido');

  const VerificationResultStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static VerificationResultStatus fromApi(String? value) {
    return values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => VerificationResultStatus.unknown,
    );
  }
}

enum ReviewReasonCode {
  applicabilityPending(
    'APPLICABILITY_PENDING',
    'Falta decidir si aplica',
    'Primero confirmá si esta evidencia corresponde al caso.',
  ),
  missingTicketSelection(
    'MISSING_TICKET_SELECTION',
    'Falta seleccionar un ticket',
    'No se consultó Redmine porque no se recibió un ticket para esta expectativa.',
  ),
  sourceNotConfigured(
    'SOURCE_NOT_CONFIGURED',
    'Fuente sin configurar',
    'El servicio no tiene configurada la fuente necesaria para esta comprobación.',
  ),
  sourceUnavailable(
    'SOURCE_UNAVAILABLE',
    'Fuente no disponible',
    'No se pudo consultar la fuente. No se comprobó una ausencia de evidencia.',
  ),
  sourceDataInvalid(
    'SOURCE_DATA_INVALID',
    'Respuesta inconsistente',
    'La fuente devolvió datos que no permiten identificar la evidencia con seguridad.',
  ),
  searchIncomplete(
    'SEARCH_INCOMPLETE',
    'Búsqueda incompleta',
    'La consulta terminó sin revisar todo el ámbito configurado.',
  ),
  multipleMatches(
    'MULTIPLE_MATCHES',
    'Varias coincidencias',
    'Se encontraron varias evidencias y hace falta identificar cuál corresponde.',
  ),
  ruleNotDefined(
    'RULE_NOT_DEFINED',
    'Regla insuficiente',
    'La expectativa no define un campo o cambio comprobable de forma automática.',
  ),
  aiInconclusive(
    'AI_INCONCLUSIVE',
    'Interpretación no concluyente',
    'La interpretación automática no alcanzó para proponer cumplimiento o incumplimiento.',
  ),
  unsupportedSource(
    'UNSUPPORTED_SOURCE',
    'Comprobación no disponible',
    'Esta clase de registro todavía no tiene un lector operativo.',
  ),
  other(
    'OTHER',
    'Revisión necesaria',
    'Revisá el fundamento y las limitaciones de esta evidencia.',
  ),
  unknown(
    'UNKNOWN',
    'Motivo no informado',
    'El backend no informó un motivo codificado; revisá el fundamento.',
  );

  const ReviewReasonCode(this.apiValue, this.label, this.explanation);
  final String apiValue;
  final String label;
  final String explanation;

  static ReviewReasonCode fromApi(String? value) => values.firstWhere(
    (reason) => reason.apiValue == value,
    orElse: () => ReviewReasonCode.unknown,
  );
}

enum EvidenceSearchStatus {
  notAttempted(
    'NOT_ATTEMPTED',
    'Todavía no se buscó',
    'No se consultó la fuente para esta evidencia.',
  ),
  found(
    'FOUND',
    'Se encontró evidencia',
    'La fuente devolvió una referencia; el cumplimiento depende de la regla evaluada.',
  ),
  notFound(
    'NOT_FOUND',
    'Se buscó y no se encontró',
    'La búsqueda terminó sin encontrar la evidencia esperada.',
  ),
  incomplete(
    'INCOMPLETE',
    'Búsqueda sin completar',
    'La consulta no permitió concluir si existe la evidencia.',
  ),
  unknown(
    'UNKNOWN',
    'Búsqueda no determinada',
    'Los datos disponibles no permiten afirmar si se consultó la fuente.',
  );

  const EvidenceSearchStatus(this.apiValue, this.label, this.explanation);
  final String apiValue;
  final String label;
  final String explanation;

  static EvidenceSearchStatus fromApi(String? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => EvidenceSearchStatus.unknown,
  );
}

enum ApplicabilityDecision {
  applies('APPLIES', 'Aplica'),
  notApplicable('NOT_APPLICABLE', 'No aplica'),
  undetermined('UNDETERMINED', 'Indeterminada'),
  unknown('UNKNOWN', 'No reconocida');

  const ApplicabilityDecision(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ApplicabilityDecision fromApi(String? value) {
    return values.firstWhere(
      (decision) => decision.apiValue == value,
      orElse: () => ApplicabilityDecision.unknown,
    );
  }
}

enum DecisionOrigin {
  deterministic('DETERMINISTIC', 'Comprobación programada'),
  aiApplicability('AI_APPLICABILITY', 'IA para aplicabilidad'),
  human('HUMAN', 'Decisión humana'),
  notEvaluated('NOT_EVALUATED', 'No evaluada'),
  unknown('UNKNOWN', 'Origen no reconocido');

  const DecisionOrigin(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DecisionOrigin fromApi(String? value) {
    return values.firstWhere(
      (origin) => origin.apiValue == value,
      orElse: () => DecisionOrigin.unknown,
    );
  }
}

enum EvidenceSource {
  drive('DRIVE', 'Google Drive'),
  redmine('REDMINE', 'Redmine'),
  imputations('IMPUTATIONS', 'Imputaciones'),
  toolRecord('TOOL_RECORD', 'Registro de herramienta'),
  unknown('UNKNOWN', 'Otra fuente');

  const EvidenceSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EvidenceSource fromApi(String? value) {
    return values.firstWhere(
      (source) => source.apiValue == value,
      orElse: () => EvidenceSource.unknown,
    );
  }
}

enum HumanDecisionType {
  applicability('APPLICABILITY', 'Aplicabilidad'),
  resultStatus('RESULT_STATUS', 'Estado final'),
  unknown('UNKNOWN', 'Decisión');

  const HumanDecisionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HumanDecisionType fromApi(String? value) {
    return values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => HumanDecisionType.unknown,
    );
  }
}

enum HumanApplicabilityDecision {
  applies('APPLIES', 'Sí, aplica'),
  notApplicable('NOT_APPLICABLE', 'No aplica');

  const HumanApplicabilityDecision(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HumanApplicabilityDecision? fromApi(String? value) {
    if (value == null) return null;
    for (final decision in values) {
      if (decision.apiValue == value) return decision;
    }
    return null;
  }
}

class ApplicabilityAssessment {
  ApplicabilityAssessment._({
    required this.decision,
    required this.origin,
    required this.rationale,
    required this.limitations,
  });

  factory ApplicabilityAssessment({
    required ApplicabilityDecision decision,
    required DecisionOrigin origin,
    required String rationale,
    required List<String> limitations,
  }) {
    if (rationale.trim().isEmpty) {
      throw const FormatException(
        'La evaluación de aplicabilidad requiere un fundamento.',
      );
    }
    return ApplicabilityAssessment._(
      decision: decision,
      origin: origin,
      rationale: rationale.trim(),
      limitations: List.unmodifiable(limitations),
    );
  }

  final ApplicabilityDecision decision;
  final DecisionOrigin origin;
  final String rationale;
  final List<String> limitations;

  bool get requiresHumanIntervention =>
      decision == ApplicabilityDecision.undetermined;

  /// The API does not repeat M1's applicability mode in a result. An origin
  /// other than NOT_EVALUATED identifies a contextual applicability assessment.
  bool get hasContextualAssessment =>
      origin != DecisionOrigin.notEvaluated || requiresHumanIntervention;
}

class EvidenceReference {
  EvidenceReference._({
    required this.kind,
    required this.source,
    required this.externalId,
    required this.displayName,
    required this.webUrl,
    required this.observedAt,
    required this.ticketId,
  });

  factory EvidenceReference({
    required EvidenceType kind,
    required EvidenceSource source,
    required String externalId,
    required String displayName,
    String? webUrl,
    required DateTime observedAt,
    String? ticketId,
  }) {
    if (externalId.trim().isEmpty || displayName.trim().isEmpty) {
      throw const FormatException(
        'La referencia de evidencia requiere identificación y nombre.',
      );
    }
    return EvidenceReference._(
      kind: kind,
      source: source,
      externalId: externalId.trim(),
      displayName: displayName.trim(),
      webUrl: webUrl?.trim().isEmpty == true ? null : webUrl?.trim(),
      observedAt: observedAt,
      ticketId: ticketId?.trim().isEmpty == true ? null : ticketId?.trim(),
    );
  }

  final EvidenceType kind;
  final EvidenceSource source;
  final String externalId;
  final String displayName;
  final String? webUrl;
  final DateTime observedAt;
  final String? ticketId;

  Uri? get safeWebUri {
    if (webUrl == null) return null;
    final uri = Uri.tryParse(webUrl!);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }
}

class HumanDecisionEvent {
  HumanDecisionEvent._({
    required this.id,
    required this.decisionType,
    required this.applicabilityDecision,
    required this.finalStatus,
    required this.rationale,
    required this.decidedAt,
  });

  factory HumanDecisionEvent({
    required String id,
    required HumanDecisionType decisionType,
    HumanApplicabilityDecision? applicabilityDecision,
    VerificationResultStatus? finalStatus,
    required String rationale,
    required DateTime decidedAt,
  }) {
    if (id.trim().isEmpty || rationale.trim().isEmpty) {
      throw const FormatException(
        'Una decisión humana requiere identificación y fundamento.',
      );
    }
    final isApplicability = decisionType == HumanDecisionType.applicability;
    final isResultStatus = decisionType == HumanDecisionType.resultStatus;
    if (isApplicability) {
      if (applicabilityDecision == null || finalStatus != null) {
        throw const FormatException(
          'La decisión humana de aplicabilidad no tiene una forma válida.',
        );
      }
    } else if (isResultStatus) {
      if (finalStatus == null || applicabilityDecision != null) {
        throw const FormatException(
          'La decisión humana de estado no tiene una forma válida.',
        );
      }
    }
    return HumanDecisionEvent._(
      id: id.trim(),
      decisionType: decisionType,
      applicabilityDecision: applicabilityDecision,
      finalStatus: finalStatus,
      rationale: rationale.trim(),
      decidedAt: decidedAt,
    );
  }

  final String id;
  final HumanDecisionType decisionType;
  final HumanApplicabilityDecision? applicabilityDecision;
  final VerificationResultStatus? finalStatus;
  final String rationale;
  final DateTime decidedAt;
}

class VerificationResult {
  VerificationResult._({
    required this.id,
    required this.runId,
    required this.expectationId,
    required this.macroActivityId,
    required this.activityId,
    required this.displayName,
    required this.evidenceType,
    required this.location,
    required this.subjectTicketId,
    required this.applicability,
    required this.proposedStatus,
    required this.effectiveStatus,
    required this.reviewReason,
    required this.searchStatus,
    required this.rationale,
    required this.limitations,
    required this.evidence,
    required this.humanDecisions,
    required this.revision,
  });

  factory VerificationResult({
    required String id,
    required String runId,
    required String expectationId,
    required String macroActivityId,
    String? activityId,
    required String displayName,
    required EvidenceType evidenceType,
    required EvidenceLocation location,
    String? subjectTicketId,
    required ApplicabilityAssessment applicability,
    required VerificationResultStatus proposedStatus,
    required VerificationResultStatus effectiveStatus,
    ReviewReasonCode reviewReason = ReviewReasonCode.unknown,
    EvidenceSearchStatus searchStatus = EvidenceSearchStatus.unknown,
    required String rationale,
    required List<String> limitations,
    required List<EvidenceReference> evidence,
    required List<HumanDecisionEvent> humanDecisions,
    required int revision,
  }) {
    if (id.trim().isEmpty ||
        runId.trim().isEmpty ||
        expectationId.trim().isEmpty ||
        macroActivityId.trim().isEmpty ||
        displayName.trim().isEmpty ||
        rationale.trim().isEmpty ||
        revision < 0) {
      throw const FormatException(
        'El resultado de verificación tiene datos obligatorios inválidos.',
      );
    }
    final normalizedTicket = subjectTicketId?.trim();
    return VerificationResult._(
      id: id.trim(),
      runId: runId.trim(),
      expectationId: expectationId.trim(),
      macroActivityId: macroActivityId.trim(),
      activityId: activityId?.trim().isEmpty == true
          ? null
          : activityId?.trim(),
      displayName: displayName.trim(),
      evidenceType: evidenceType,
      location: location,
      subjectTicketId: normalizedTicket?.isEmpty == true
          ? null
          : normalizedTicket,
      applicability: applicability,
      proposedStatus: proposedStatus,
      effectiveStatus: effectiveStatus,
      reviewReason: reviewReason,
      searchStatus: searchStatus,
      rationale: rationale.trim(),
      limitations: List.unmodifiable(limitations),
      evidence: List.unmodifiable(evidence),
      humanDecisions: List.unmodifiable(humanDecisions),
      revision: revision,
    );
  }

  final String id;
  final String runId;
  final String expectationId;
  final String macroActivityId;
  final String? activityId;
  final String displayName;
  final EvidenceType evidenceType;
  final EvidenceLocation location;
  final String? subjectTicketId;
  final ApplicabilityAssessment applicability;
  final VerificationResultStatus proposedStatus;
  final VerificationResultStatus effectiveStatus;
  final ReviewReasonCode reviewReason;
  final EvidenceSearchStatus searchStatus;
  final String rationale;
  final List<String> limitations;
  final List<EvidenceReference> evidence;
  final List<HumanDecisionEvent> humanDecisions;
  final int revision;

  bool get hasHumanStatusDecision => humanDecisions.any(
    (event) => event.decisionType == HumanDecisionType.resultStatus,
  );

  bool get isTicketScoped => subjectTicketId != null;
}

class AiRetryAttempt {
  const AiRetryAttempt({
    required this.attemptedAt,
    required this.outcome,
    required this.previousStatus,
    required this.proposedStatus,
    required this.effectiveStatus,
    required this.rationale,
    required this.ticketSnapshot,
    required this.previousResult,
    required this.model,
  });

  factory AiRetryAttempt.fromJson(Map<String, dynamic> json) => AiRetryAttempt(
    attemptedAt: DateTime.parse(json['attemptedAt'] as String),
    outcome: json['outcome'] as String,
    previousStatus: VerificationResultStatus.fromApi(
      json['previousProposedStatus'] as String?,
    ),
    proposedStatus: VerificationResultStatus.fromApi(
      json['proposedStatus'] as String?,
    ),
    effectiveStatus: VerificationResultStatus.fromApi(
      json['effectiveStatus'] as String?,
    ),
    rationale: json['rationale'] as String,
    ticketSnapshot:
        (json['ticketSnapshot'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const [],
    previousResult: Map<String, dynamic>.from(
      json['previousResult'] as Map? ?? const {},
    ),
    model: json['model'] as String?,
  );

  final DateTime attemptedAt;
  final String outcome;
  final VerificationResultStatus previousStatus;
  final VerificationResultStatus proposedStatus;
  final VerificationResultStatus effectiveStatus;
  final String rationale;
  final List<Map<String, dynamic>> ticketSnapshot;
  final Map<String, dynamic> previousResult;
  final String? model;
}

/// Status choices that can be sent to the human decision endpoint.
/// The backend remains authoritative and checks these rules again.
List<VerificationResultStatus> allowedHumanFinalStatuses(
  VerificationResult result,
  evidence_model.ApplicabilityMode? mode,
) {
  switch (result.applicability.decision) {
    case ApplicabilityDecision.applies:
      return const [
        VerificationResultStatus.complies,
        VerificationResultStatus.doesNotComply,
        VerificationResultStatus.reviewRequired,
      ];
    case ApplicabilityDecision.notApplicable:
      return mode == evidence_model.ApplicabilityMode.caseDependent
          ? const [VerificationResultStatus.notApplicable]
          : const [];
    case ApplicabilityDecision.undetermined:
    case ApplicabilityDecision.unknown:
      return const [];
  }
}
