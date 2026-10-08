import '../../processes/data/process_structure_repository.dart';
import '../../processes/model/evidence_expectation.dart' as evidence_model;
import '../../processes/model/process_models.dart' as process_models;
import '../../processes/model/process_structure_models.dart';
import '../../services/data/service_repository.dart';
import '../model/verification_history_models.dart';
import '../model/verification_result_models.dart';

/// Optional process hierarchy context used to explain where a result belongs.
///
/// The results endpoint returns stable macro/activity identifiers but not their
/// display names. This resolver enriches results only when the corresponding
/// published process version can be resolved. Failure to resolve the context is
/// intentionally non-fatal: the result itself remains available.
class VerificationResultLocationContext {
  const VerificationResultLocationContext({
    required this.macroActivityName,
    this.activityName,
    this.applicabilityMode,
  });

  final String macroActivityName;
  final String? activityName;
  final evidence_model.ApplicabilityMode? applicabilityMode;

  bool get hasActivity => activityName?.trim().isNotEmpty == true;
}

abstract interface class VerificationResultLocationResolver {
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  });
}

class VerificationResultLocationResolverImpl
    implements VerificationResultLocationResolver {
  VerificationResultLocationResolverImpl(this._services, this._processes);

  final ServiceRepository _services;
  final ProcessStructureRepository _processes;

  @override
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  }) async {
    if (results.isEmpty) return const {};

    try {
      final service = await _services.getService(run.serviceId);
      final process = service.processForVersion(run.processVersionId);
      if (process == null) return const {};

      final version = await _processes.getVersion(
        processId: process.processId,
        versionId: run.processVersionId,
      );

      final macroById = <String, MacroActivityDraft>{};

      for (final macro in version.macroActivities) {
        final macroId = macro.id;
        if (macroId == null || macroId.trim().isEmpty) continue;
        macroById[macroId] = macro;
      }

      final contextByResultId = <String, VerificationResultLocationContext>{};
      for (final result in results) {
        final macro = macroById[result.macroActivityId];
        if (macro == null || macro.name.trim().isEmpty) {
          continue;
        }

        ActivityDraft? activity;
        final activityId = result.activityId?.trim();
        if (activityId != null && activityId.isNotEmpty) {
          for (final candidate in macro.activities) {
            if (candidate.id?.trim() == activityId) {
              activity = candidate;
              break;
            }
          }

          // A result referencing an activity must resolve that activity under
          // the same macroactivity. Do not fall back to another activity with
          // the same ID elsewhere in the process hierarchy.
          if (activity == null) {
            continue;
          }
        }

        final activityName = activity?.name.trim();
        final expectations = switch (result.location) {
          process_models.EvidenceLocation.input => macro.inputs,
          process_models.EvidenceLocation.output => macro.outputs,
          process_models.EvidenceLocation.activityRecord =>
            activity?.records ?? const <evidence_model.EvidenceExpectation>[],
          process_models.EvidenceLocation.unknown =>
            const <evidence_model.EvidenceExpectation>[],
        };
        evidence_model.ApplicabilityMode? applicabilityMode;
        for (final expectation in expectations) {
          if (expectation.id == result.expectationId) {
            applicabilityMode = expectation.applicability;
            break;
          }
        }
        contextByResultId[result.id] = VerificationResultLocationContext(
          macroActivityName: macro.name.trim(),
          activityName: activityName?.isEmpty == true ? null : activityName,
          applicabilityMode: applicabilityMode,
        );
      }

      return contextByResultId;
    } catch (_) {
      // Result loading must not fail merely because historical hierarchy
      // metadata is unavailable. The stable IDs remain in the model.
      return const {};
    }
  }
}
