import '../model/process_models.dart';

abstract interface class ProcessRepository {
  Future<List<ProcessDefinition>> listProcesses();
  Future<ProcessDefinition> getProcess(String processId);
  Future<ProcessDefinition> createProcess(M1ProcessCode code);

  Future<List<ProcessVersion>> listVersions(String processId);
  Future<ProcessVersion> createDraftVersion({
    required String processId,
    required String officialVersion,
    required DateTime versionDate,
    String? copyFromVersionId,
  });
  Future<ProcessVersion> getVersion({
    required String processId,
    required String versionId,
  });
  Future<ProcessVersion> saveDraft(ProcessVersion version);
  Future<ProcessVersion> publishVersion({
    required String processId,
    required String versionId,
    required int revision,
  });
}
