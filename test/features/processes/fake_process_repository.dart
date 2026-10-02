import 'package:proyecto_tema_frontend/core/errors/app_failure.dart';
import 'package:proyecto_tema_frontend/features/processes/data/process_repository.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';

class FakeProcessRepository implements ProcessRepository {
  FakeProcessRepository({
    List<ProcessDefinition>? definitions,
    Map<String, List<ProcessVersion>>? versionsByProcess,
    this.createProcessFailure,
    this.createDraftFailure,
    this.saveFailure,
    this.publishFailure,
    this.savedVersionFactory,
  })  : definitions = [...?definitions],
        versionsByProcess = {
          for (final entry in (versionsByProcess ?? const <String, List<ProcessVersion>>{}).entries)
            entry.key: [...entry.value],
        };

  final List<ProcessDefinition> definitions;
  final Map<String, List<ProcessVersion>> versionsByProcess;
  final AppFailure? createProcessFailure;
  final AppFailure? createDraftFailure;
  final AppFailure? saveFailure;
  final AppFailure? publishFailure;
  final ProcessVersion Function(ProcessVersion submitted)? savedVersionFactory;

  M1ProcessCode? createdCode;
  ProcessVersion? submittedVersion;
  String? copyFromVersionId;
  ProcessVersion? publishedVersion;

  @override
  Future<List<ProcessDefinition>> listProcesses() async => [...definitions];

  @override
  Future<ProcessDefinition> getProcess(String processId) async {
    return definitions.firstWhere((item) => item.id == processId);
  }

  @override
  Future<ProcessDefinition> createProcess(M1ProcessCode code) async {
    if (createProcessFailure != null) throw createProcessFailure!;
    createdCode = code;
    final definition = ProcessDefinition(
      id: 'process-${definitions.length + 1}',
      code: code,
      name: code.label,
      m2Enabled: code != M1ProcessCode.qualityContinuousImprovement,
      createdAt: DateTime(2026, 10, 1),
    );
    definitions.add(definition);
    versionsByProcess.putIfAbsent(definition.id, () => []);
    return definition;
  }

  @override
  Future<List<ProcessVersion>> listVersions(String processId) async {
    return [...?versionsByProcess[processId]];
  }

  @override
  Future<ProcessVersion> createDraftVersion({
    required String processId,
    required String officialVersion,
    required DateTime versionDate,
    String? copyFromVersionId,
  }) async {
    if (createDraftFailure != null) throw createDraftFailure!;
    this.copyFromVersionId = copyFromVersionId;
    final version = ProcessVersion(
      id: 'version-${(versionsByProcess[processId]?.length ?? 0) + 1}',
      processId: processId,
      officialVersion: officialVersion,
      versionDate: versionDate,
      status: ProcessVersionStatus.draft,
      revision: 0,
      objective: '',
      owner: '',
      policies: const [],
      macroActivities: const [],
      createdAt: DateTime(2026, 10, 1),
    );
    versionsByProcess.putIfAbsent(processId, () => []).add(version);
    return version;
  }

  @override
  Future<ProcessVersion> getVersion({
    required String processId,
    required String versionId,
  }) async {
    return versionsByProcess[processId]!
        .firstWhere((item) => item.id == versionId);
  }

  @override
  Future<ProcessVersion> saveDraft(ProcessVersion version) async {
    submittedVersion = version;
    if (saveFailure != null) throw saveFailure!;
    final saved = savedVersionFactory?.call(version) ??
        version.copyWith(revision: version.revision + 1);
    final versions = versionsByProcess[version.processId]!;
    final index = versions.indexWhere((item) => item.id == version.id);
    if (index >= 0) versions[index] = saved;
    return saved;
  }

  @override
  Future<ProcessVersion> publishVersion({
    required String processId,
    required String versionId,
    required int revision,
  }) async {
    if (publishFailure != null) throw publishFailure!;
    final versions = versionsByProcess[processId]!;
    final index = versions.indexWhere((item) => item.id == versionId);
    final published = versions[index].copyWith(
      status: ProcessVersionStatus.published,
      revision: revision + 1,
      publishedAt: DateTime(2026, 10, 1),
    );
    versions[index] = published;
    publishedVersion = published;
    return published;
  }
}
