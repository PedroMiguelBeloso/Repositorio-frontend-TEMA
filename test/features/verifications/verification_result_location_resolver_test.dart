import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_structure_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart'
    as evidence_model;
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart'
    as process_models;
import 'package:proyecto_tema_frontend/features/processes/model/process_structure_models.dart'
    as structure_models;
import 'package:proyecto_tema_frontend/features/services/data/service_repository.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart'
    as service_models;
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';

void main() {
  test('does not mix an activity from another macroactivity', () async {
    final resolver = VerificationResultLocationResolverImpl(
      _ServiceRepository(),
      _MismatchedProcessStructureRepository(),
    );

    final run = VerificationRun(
      id: 'run-1',
      serviceId: 'service-1',
      processVersionId: 'version-1',
      scope: VerificationScope.process,
      status: VerificationRunStatus.completed,
      progress: RunProgress.fromValues(total: 1, processed: 1),
      startedAt: DateTime.utc(2026, 10, 8),
    );
    final result = VerificationResult(
      id: 'result-2',
      runId: 'run-1',
      expectationId: 'expectation-2',
      macroActivityId: 'macro-2',
      activityId: 'activity-1',
      displayName: 'Registro homónimo',
      evidenceType: process_models.EvidenceType.toolRecord,
      location: process_models.EvidenceLocation.activityRecord,
      applicability: ApplicabilityAssessment(
        decision: ApplicabilityDecision.applies,
        origin: DecisionOrigin.deterministic,
        rationale: 'Aplica.',
        limitations: const [],
      ),
      proposedStatus: VerificationResultStatus.complies,
      effectiveStatus: VerificationResultStatus.complies,
      rationale: 'Cumple.',
      limitations: const [],
      evidence: const [],
      humanDecisions: const [],
      revision: 0,
    );

    final resolved = await resolver.resolve(run: run, results: [result]);
    expect(resolved, isEmpty);
  });

  test(
    'resolves macroactivity and activity names from the immutable process version',
    () async {
      final resolver = VerificationResultLocationResolverImpl(
        _ServiceRepository(),
        _ProcessStructureRepository(),
      );

      final run = VerificationRun(
        id: 'run-1',
        serviceId: 'service-1',
        processVersionId: 'version-1',
        scope: VerificationScope.process,
        status: VerificationRunStatus.completed,
        progress: RunProgress.fromValues(total: 1, processed: 1),
        startedAt: DateTime.utc(2026, 10, 8),
      );

      final result = VerificationResult(
        id: 'result-1',
        runId: 'run-1',
        expectationId: 'expectation-1',
        macroActivityId: 'macro-1',
        activityId: 'activity-1',
        displayName: 'Ticket actualizado',
        evidenceType: process_models.EvidenceType.ticket,
        location: process_models.EvidenceLocation.activityRecord,
        applicability: ApplicabilityAssessment(
          decision: ApplicabilityDecision.applies,
          origin: DecisionOrigin.deterministic,
          rationale: 'Aplica.',
          limitations: const [],
        ),
        proposedStatus: VerificationResultStatus.complies,
        effectiveStatus: VerificationResultStatus.complies,
        rationale: 'Cumple.',
        limitations: const [],
        evidence: const [],
        humanDecisions: const [],
        revision: 0,
        subjectTicketId: '204',
      );

      final resolved = await resolver.resolve(run: run, results: [result]);
      expect(resolved['result-1']?.macroActivityName, 'Soporte de incidentes');
      expect(resolved['result-1']?.activityName, 'Actualizar ticket');
      expect(
        resolved['result-1']?.applicabilityMode,
        evidence_model.ApplicabilityMode.caseDependent,
      );
    },
  );
}

class _ServiceRepository implements ServiceRepository {
  @override
  Future<service_models.Service> getService(String id) async =>
      service_models.Service(
        id: 'service-1',
        name: 'Servicio',
        client: 'Cliente',
        serviceType: service_models.ServiceType.supportErp,
        status: service_models.ServiceStatus.active,
        revision: 1,
        processes: const [
          service_models.ServiceProcess(
            processVersionId: 'version-1',
            processId: 'process-1',
            processName: 'Soporte ERP',
            officialVersion: '1.0',
            m2Enabled: true,
          ),
        ],
        sources: const service_models.ServiceSource(),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  @override
  Future<service_models.PagedResult<service_models.Service>> listServices({
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<service_models.Service> createService(
    service_models.ServiceInput input,
  ) => throw UnimplementedError();

  @override
  Future<service_models.Service> updateService(
    String id,
    service_models.ServiceInput input,
  ) => throw UnimplementedError();

  @override
  Future<List<service_models.AssignableProcessGroup>>
  getAssignableProcessVersions() => throw UnimplementedError();

  @override
  Future<service_models.PagedResult<service_models.DriveFolderOption>>
  getDriveFolders({String query = '', required int page, required int size}) =>
      throw UnimplementedError();

  @override
  Future<service_models.PagedResult<service_models.RedmineProjectOption>>
  getRedmineProjects({required int page, required int size}) =>
      throw UnimplementedError();
}

class _ProcessStructureRepository implements ProcessStructureRepository {
  @override
  Future<structure_models.ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  }) async {
    return structure_models.ProcessVersionDraft(
      id: 'version-1',
      processId: 'process-1',
      officialVersion: '1.0',
      versionDate: DateTime.utc(2026, 1, 1),
      status: structure_models.ProcessStatus.published,
      revision: 1,
      objective: 'Objetivo',
      owner: 'Responsable',
      policies: const [],
      macroActivities: const [
        structure_models.MacroActivityDraft(
          id: 'macro-1',
          name: 'Soporte de incidentes',
          order: 1,
          activities: [
            structure_models.ActivityDraft(
              id: 'activity-1',
              name: 'Actualizar ticket',
              instructions: 'Instrucciones',
              order: 1,
              records: [
                evidence_model.EvidenceExpectation(
                  id: 'expectation-1',
                  registryDefinitionId: 'registry-1',
                  registryDefinition: evidence_model.RegistryDefinition(
                    id: 'registry-1',
                    key: 'TICKET_UPDATE',
                    canonicalName: 'Ticket actualizado',
                    evidenceType: evidence_model.EvidenceType.ticket,
                    preloaded: true,
                  ),
                  applicability: evidence_model.ApplicabilityMode.caseDependent,
                  order: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<structure_models.ProcessPage<structure_models.ProcessDefinition>>
  listProcesses({required int page, required int size}) =>
      throw UnimplementedError();

  @override
  Future<structure_models.ProcessDefinition> getProcess(String processId) =>
      throw UnimplementedError();

  @override
  Future<structure_models.ProcessPage<structure_models.ProcessVersionSummary>>
  listVersions({
    required String processId,
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<structure_models.ProcessVersionDraft> saveDraft(
    structure_models.ProcessVersionDraft draft,
    List<evidence_model.RegistryDefinition> definitions,
  ) => throw UnimplementedError();

  @override
  Future<structure_models.ProcessPage<evidence_model.RegistryDefinition>>
  searchRegistry({
    required String query,
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<evidence_model.RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required evidence_model.EvidenceType evidenceType,
    String? officialNomenclature,
  }) => throw UnimplementedError();
}

class _MismatchedProcessStructureRepository
    extends _ProcessStructureRepository {
  @override
  Future<structure_models.ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  }) async {
    return structure_models.ProcessVersionDraft(
      id: 'version-1',
      processId: 'process-1',
      officialVersion: '1.0',
      versionDate: DateTime.utc(2026, 1, 1),
      status: structure_models.ProcessStatus.published,
      revision: 1,
      objective: 'Objetivo',
      owner: 'Responsable',
      policies: const [],
      macroActivities: const [
        structure_models.MacroActivityDraft(
          id: 'macro-1',
          name: 'Soporte de incidentes',
          order: 1,
          activities: [
            structure_models.ActivityDraft(
              id: 'activity-1',
              name: 'Actualizar ticket de otra macro',
              instructions: 'Instrucciones',
              order: 1,
            ),
          ],
        ),
        structure_models.MacroActivityDraft(
          id: 'macro-2',
          name: 'Gestión de solicitudes',
          order: 2,
        ),
      ],
    );
  }
}
