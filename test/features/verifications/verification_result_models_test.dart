import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart'
    as evidence_model;
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';

void main() {
  test('human status choices follow resolved applicability', () {
    expect(
      allowedHumanFinalStatuses(
        _resultWithApplicability(ApplicabilityDecision.applies),
        evidence_model.ApplicabilityMode.always,
      ),
      [
        VerificationResultStatus.complies,
        VerificationResultStatus.doesNotComply,
        VerificationResultStatus.reviewRequired,
      ],
    );
    expect(
      allowedHumanFinalStatuses(
        _resultWithApplicability(ApplicabilityDecision.notApplicable),
        evidence_model.ApplicabilityMode.caseDependent,
      ),
      [VerificationResultStatus.notApplicable],
    );
    expect(
      allowedHumanFinalStatuses(
        _resultWithApplicability(ApplicabilityDecision.notApplicable),
        evidence_model.ApplicabilityMode.always,
      ),
      isEmpty,
    );
    expect(
      allowedHumanFinalStatuses(
        _resultWithApplicability(ApplicabilityDecision.undetermined),
        evidence_model.ApplicabilityMode.caseDependent,
      ),
      isEmpty,
    );
  });
  test('maps all result statuses to functional Spanish labels', () {
    expect(VerificationResultStatus.fromApi('COMPLIES').label, 'Cumple');
    expect(
      VerificationResultStatus.fromApi('DOES_NOT_COMPLY').label,
      'No cumple',
    );
    expect(
      VerificationResultStatus.fromApi('REVIEW_REQUIRED').label,
      'Requiere revisión',
    );
    expect(
      VerificationResultStatus.fromApi('NOT_APPLICABLE').label,
      'No aplica',
    );
  });

  test('unknown API status is represented without breaking model parsing', () {
    expect(
      VerificationResultStatus.fromApi('NEW_STATUS'),
      VerificationResultStatus.unknown,
    );
  });

  test('human result-status decisions cannot contain applicability data', () {
    expect(
      () => HumanDecisionEvent(
        id: 'decision-1',
        decisionType: HumanDecisionType.resultStatus,
        applicabilityDecision: HumanApplicabilityDecision.applies,
        finalStatus: VerificationResultStatus.complies,
        rationale: 'Corrección registrada.',
        decidedAt: DateTime.utc(2026, 10, 8),
      ),
      throwsFormatException,
    );
  });

  test('unknown human decision type remains parseable defensively', () {
    final event = HumanDecisionEvent(
      id: 'decision-unknown',
      decisionType: HumanDecisionType.unknown,
      rationale: 'Evento de un tipo futuro desconocido.',
      decidedAt: DateTime.utc(2026, 10, 8),
    );

    expect(event.decisionType, HumanDecisionType.unknown);
    expect(event.finalStatus, isNull);
    expect(event.applicabilityDecision, isNull);
  });

  test('undetermined applicability exposes human intervention requirement', () {
    final assessment = ApplicabilityAssessment(
      decision: ApplicabilityDecision.undetermined,
      origin: DecisionOrigin.aiApplicability,
      rationale: 'No hay información suficiente.',
      limitations: const ['Falta contexto del servicio.'],
    );

    expect(assessment.requiresHumanIntervention, isTrue);
    expect(assessment.hasContextualAssessment, isTrue);
  });

  test('invalid reference URL does not become an actionable URI', () {
    final reference = EvidenceReference(
      kind: EvidenceType.document,
      source: EvidenceSource.drive,
      externalId: 'drive-1',
      displayName: 'Procedimiento',
      webUrl: 'javascript:alert(1)',
      observedAt: DateTime.utc(2026, 10, 8),
    );

    expect(reference.safeWebUri, isNull);
  });
}

VerificationResult _resultWithApplicability(ApplicabilityDecision decision) =>
    VerificationResult(
      id: 'result-1',
      runId: 'run-1',
      expectationId: 'expectation-1',
      macroActivityId: 'macro-1',
      displayName: 'Registro',
      evidenceType: EvidenceType.document,
      location: EvidenceLocation.input,
      applicability: ApplicabilityAssessment(
        decision: decision,
        origin: DecisionOrigin.deterministic,
        rationale: 'Evaluación de prueba.',
        limitations: const [],
      ),
      proposedStatus: VerificationResultStatus.reviewRequired,
      effectiveStatus: VerificationResultStatus.reviewRequired,
      rationale: 'Resultado de prueba.',
      limitations: const [],
      evidence: const [],
      humanDecisions: const [],
      revision: 0,
    );
