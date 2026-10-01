import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart';

void main() {
  const ticket = RegistryDefinition(
    id: 'registry-ticket',
    key: 'ticket',
    canonicalName: 'Tickets',
    evidenceType: EvidenceType.ticket,
    preloaded: true,
  );

  test('new evidence omits server ID and empty display name', () {
    const evidence = EvidenceExpectation(
      registryDefinitionId: 'registry-ticket',
      registryDefinition: ticket,
      applicability: ApplicabilityMode.caseDependent,
      cardinality: EvidenceCardinality.multiple,
      order: 0,
    );

    expect(evidence.toJson(), {
      'registryDefinitionId': 'registry-ticket',
      'applicability': 'CASE_DEPENDENT',
      'cardinality': 'MULTIPLE',
      'order': 0,
    });
  });

  test('saved evidence preserves its server ID and display name', () {
    const evidence = EvidenceExpectation(
      id: 'saved-expectation',
      registryDefinitionId: 'registry-ticket',
      registryDefinition: ticket,
      displayName: 'Ticket actualizado',
      order: 2,
    );

    expect(evidence.toJson(), {
      'id': 'saved-expectation',
      'registryDefinitionId': 'registry-ticket',
      'displayName': 'Ticket actualizado',
      'applicability': 'ALWAYS',
      'cardinality': 'ONE',
      'order': 2,
    });
  });
}
