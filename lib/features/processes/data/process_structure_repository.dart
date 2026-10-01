import '../model/evidence_expectation.dart';
import '../model/process_structure_models.dart';

abstract interface class ProcessStructureRepository {
  Future<ProcessPage<ProcessDefinition>> listProcesses({
    required int page,
    required int size,
  });

  Future<ProcessDefinition> getProcess(String processId);

  Future<ProcessPage<ProcessVersionSummary>> listVersions({
    required String processId,
    required int page,
    required int size,
  });

  Future<ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  });

  Future<ProcessVersionDraft> saveDraft(
    ProcessVersionDraft draft,
    List<RegistryDefinition> definitions,
  );

  Future<ProcessPage<RegistryDefinition>> searchRegistry({
    required String query,
    required int page,
    required int size,
  });

  Future<RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  });
}
