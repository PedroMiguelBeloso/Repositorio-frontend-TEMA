import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/dto/verification_result_dtos.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';

void main() {
  test(
    'reads stable review reason and distinguishes an unattempted search',
    () {
      final result = VerificationResultDto.fromJson({
        ..._resultJson,
        'reviewReason': 'APPLICABILITY_PENDING',
        'searchStatus': 'NOT_ATTEMPTED',
      }).toModel();

      expect(result.reviewReason, ReviewReasonCode.applicabilityPending);
      expect(result.searchStatus, EvidenceSearchStatus.notAttempted);
      expect(result.searchStatus.label, 'Todavía no se buscó');
    },
  );

  test('older responses remain readable without inferring a search', () {
    final result = VerificationResultDto.fromJson(_resultJson).toModel();

    expect(result.reviewReason, ReviewReasonCode.unknown);
    expect(result.searchStatus, EvidenceSearchStatus.unknown);
  });
}

final _resultJson = <String, dynamic>{
  'id': 'result-1',
  'runId': 'run-1',
  'expectationId': 'expectation-1',
  'macroActivityId': 'macro-1',
  'activityId': null,
  'displayName': 'Riesgos comerciales',
  'evidenceType': 'DOCUMENT',
  'location': 'INPUT',
  'subjectTicketId': null,
  'applicability': {
    'decision': 'UNDETERMINED',
    'origin': 'AI_APPLICABILITY',
    'rationale': 'No se pudo decidir si aplica.',
    'limitations': <String>[],
  },
  'proposedStatus': 'REVIEW_REQUIRED',
  'effectiveStatus': 'REVIEW_REQUIRED',
  'rationale': 'Primero falta decidir la aplicabilidad.',
  'limitations': <String>[],
  'evidence': <Object>[],
  'humanDecisions': <Object>[],
  'revision': 1,
};
