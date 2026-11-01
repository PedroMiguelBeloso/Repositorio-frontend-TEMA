import '../../../processes/model/process_models.dart';
import '../../model/verification_result_models.dart';
import 'verification_history_dtos.dart';
import '../../../services/model/service_models.dart';

class VerificationResultPageDto {
  const VerificationResultPageDto({required this.items, required this.page});

  final List<VerificationResult> items;
  final PageInfoDto page;

  factory VerificationResultPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Falta la colección de resultados.');
    }
    final rawPage = json['page'];
    if (rawPage is! Map) {
      throw const FormatException('Falta la información de paginación.');
    }

    return VerificationResultPageDto(
      items: rawItems
          .map((item) => VerificationResultDto.fromJson(_asMap(item)).toModel())
          .toList(),
      page: PageInfoDto.fromJson(_asMap(rawPage)),
    );
  }

  PagedResult<VerificationResult> toModel() =>
      PagedResult(items: items, page: page.toModel());
}

class VerificationResultDto {
  const VerificationResultDto({
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

  factory VerificationResultDto.fromJson(Map<String, dynamic> json) {
    final applicability = ApplicabilityAssessment(
      decision: ApplicabilityDecision.fromApi(
        _requiredString(json, 'applicability', nested: 'decision'),
      ),
      origin: DecisionOrigin.fromApi(
        _requiredString(json, 'applicability', nested: 'origin'),
      ),
      rationale: _requiredString(json, 'applicability', nested: 'rationale'),
      limitations: _stringList(
        _asMap(json['applicability'])['limitations'],
        fallback: const [],
      ),
    );

    return VerificationResultDto(
      id: _requiredString(json, 'id'),
      runId: _requiredString(json, 'runId'),
      expectationId: _requiredString(json, 'expectationId'),
      macroActivityId: _requiredString(json, 'macroActivityId'),
      activityId: _optionalString(json, 'activityId'),
      displayName: _requiredString(json, 'displayName'),
      evidenceType: EvidenceType.fromApi(_requiredString(json, 'evidenceType')),
      location: EvidenceLocation.fromApi(_requiredString(json, 'location')),
      subjectTicketId: _optionalString(json, 'subjectTicketId'),
      applicability: applicability,
      proposedStatus: VerificationResultStatus.fromApi(
        _requiredString(json, 'proposedStatus'),
      ),
      effectiveStatus: VerificationResultStatus.fromApi(
        _requiredString(json, 'effectiveStatus'),
      ),
      reviewReason: ReviewReasonCode.fromApi(
        _optionalString(json, 'reviewReason'),
      ),
      searchStatus: EvidenceSearchStatus.fromApi(
        _optionalString(json, 'searchStatus'),
      ),
      rationale: _requiredString(json, 'rationale'),
      limitations: _stringList(json['limitations'], fallback: const []),
      evidence: _list(
        json['evidence'],
      ).map((item) => EvidenceReferenceDto.fromJson(item).toModel()).toList(),
      humanDecisions: _list(
        json['humanDecisions'],
      ).map((item) => HumanDecisionEventDto.fromJson(item).toModel()).toList(),
      revision: _int(json['revision']),
    );
  }

  VerificationResult toModel() => VerificationResult(
    id: id,
    runId: runId,
    expectationId: expectationId,
    macroActivityId: macroActivityId,
    activityId: activityId,
    displayName: displayName,
    evidenceType: evidenceType,
    location: location,
    subjectTicketId: subjectTicketId,
    applicability: applicability,
    proposedStatus: proposedStatus,
    effectiveStatus: effectiveStatus,
    reviewReason: reviewReason,
    searchStatus: searchStatus,
    rationale: rationale,
    limitations: limitations,
    evidence: evidence,
    humanDecisions: humanDecisions,
    revision: revision,
  );
}

class EvidenceReferenceDto {
  const EvidenceReferenceDto({
    required this.kind,
    required this.source,
    required this.externalId,
    required this.displayName,
    required this.webUrl,
    required this.observedAt,
    required this.ticketId,
  });

  final EvidenceType kind;
  final EvidenceSource source;
  final String externalId;
  final String displayName;
  final String? webUrl;
  final DateTime observedAt;
  final String? ticketId;

  factory EvidenceReferenceDto.fromJson(Map<String, dynamic> json) {
    return EvidenceReferenceDto(
      kind: EvidenceType.fromApi(_requiredString(json, 'kind')),
      source: EvidenceSource.fromApi(_requiredString(json, 'source')),
      externalId: _requiredString(json, 'externalId'),
      displayName: _requiredString(json, 'displayName'),
      webUrl: _optionalString(json, 'webUrl'),
      observedAt: DateTime.parse(_requiredString(json, 'observedAt')),
      ticketId: _optionalString(json, 'ticketId'),
    );
  }

  EvidenceReference toModel() => EvidenceReference(
    kind: kind,
    source: source,
    externalId: externalId,
    displayName: displayName,
    webUrl: webUrl,
    observedAt: observedAt,
    ticketId: ticketId,
  );
}

class HumanDecisionEventDto {
  const HumanDecisionEventDto({
    required this.id,
    required this.decisionType,
    required this.applicabilityDecision,
    required this.finalStatus,
    required this.rationale,
    required this.decidedAt,
  });

  final String id;
  final HumanDecisionType decisionType;
  final HumanApplicabilityDecision? applicabilityDecision;
  final VerificationResultStatus? finalStatus;
  final String rationale;
  final DateTime decidedAt;

  factory HumanDecisionEventDto.fromJson(Map<String, dynamic> json) {
    return HumanDecisionEventDto(
      id: _requiredString(json, 'id'),
      decisionType: HumanDecisionType.fromApi(
        _requiredString(json, 'decisionType'),
      ),
      applicabilityDecision: HumanApplicabilityDecision.fromApi(
        _optionalString(json, 'applicabilityDecision'),
      ),
      finalStatus: json['finalStatus'] is String
          ? VerificationResultStatus.fromApi(json['finalStatus'] as String)
          : null,
      rationale: _requiredString(json, 'rationale'),
      decidedAt: DateTime.parse(_requiredString(json, 'decidedAt')),
    );
  }

  HumanDecisionEvent toModel() => HumanDecisionEvent(
    id: id,
    decisionType: decisionType,
    applicabilityDecision: applicabilityDecision,
    finalStatus: finalStatus,
    rationale: rationale,
    decidedAt: decidedAt,
  );
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  String? nested,
}) {
  final value = nested == null ? json[key] : _asMap(json[key])[nested];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Falta el campo requerido $key.');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  throw FormatException('El campo $key debe ser texto.');
}

List<String> _stringList(Object? value, {required List<String> fallback}) {
  if (value == null) return List<String>.unmodifiable(fallback);
  if (value is! List) throw const FormatException('Se esperaba una lista.');
  final values = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw const FormatException('La lista contiene un valor inválido.');
    }
    if (item.trim().isNotEmpty) values.add(item.trim());
  }
  return List.unmodifiable(values);
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Se esperaba una lista.');
  return value.map(_asMap).toList();
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
