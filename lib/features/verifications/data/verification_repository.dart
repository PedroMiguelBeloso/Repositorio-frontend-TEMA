import '../../services/model/service_models.dart';
import '../model/new_verification_models.dart';
import '../model/verification_history_models.dart';

abstract interface class VerificationRepository {
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  });
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  });
  Future<VerificationRun> getVerification(String runId);
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId);
  Future<VerificationPreview> preview(VerificationTarget target);
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  });
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  );
}
