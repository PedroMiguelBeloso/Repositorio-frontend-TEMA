import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';

void main() {
  test('maps all result statuses to functional Spanish labels', () {
    expect(VerificationResultStatus.fromApi('COMPLIES').label, 'Cumple');
    expect(VerificationResultStatus.fromApi('DOES_NOT_COMPLY').label, 'No cumple');
    expect(
      VerificationResultStatus.fromApi('REVIEW_REQUIRED').label,
      'Requiere revisión',
    );
    expect(VerificationResultStatus.fromApi('NOT_APPLICABLE').label, 'No aplica');
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
