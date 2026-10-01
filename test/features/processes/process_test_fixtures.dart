import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';

ProcessVersion sampleProcessVersion({
  ProcessVersionStatus status = ProcessVersionStatus.draft,
}) {
  EvidenceExpectation evidence(String id, EvidenceLocation location, int order) {
    return EvidenceExpectation(
      id: id,
      registryDefinitionId: 'registry-$id',
      displayName: id,
      evidenceType: EvidenceType.document,
      applicability: ApplicabilityMode.always,
      cardinality: EvidenceCardinality.one,
      location: location,
      order: order,
      officialNomenclature: '$id.pdf',
    );
  }

  return ProcessVersion(
    id: 'version-1',
    processId: 'process-1',
    officialVersion: '2.0',
    versionDate: DateTime(2026, 10, 1),
    status: status,
    revision: 7,
    objective: 'Objetivo vigente',
    owner: 'Responsable vigente',
    policies: const [
      ProcessPolicy(
        id: 'policy-1',
        localKey: 'policy-1',
        order: 0,
        text: 'Política vigente',
      ),
    ],
    macroActivities: [
      ProcessMacroActivity(
        id: 'macro-1',
        localKey: 'macro-1',
        name: 'Organización interna',
        description: 'Descripción',
        order: 0,
        inputs: [evidence('input-1', EvidenceLocation.input, 0)],
        activities: [
          ProcessActivity(
            id: 'activity-1',
            localKey: 'activity-1',
            name: 'Asignar responsable',
            responsible: 'PM',
            instructions: 'Asignar responsable del servicio.',
            etaText: 'Al inicio',
            order: 0,
            records: [
              evidence('record-1', EvidenceLocation.activityRecord, 0),
            ],
          ),
        ],
        outputs: [evidence('output-1', EvidenceLocation.output, 0)],
      ),
    ],
    createdAt: DateTime(2026, 10, 1),
  );
}
