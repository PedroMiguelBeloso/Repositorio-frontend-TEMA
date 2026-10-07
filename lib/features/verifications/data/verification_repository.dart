import '../model/verification_models.dart';

abstract interface class VerificationRepository {
  Future<VerificationPreview> previewVerification({
    required String serviceId,
    required String processVersionId,
    required VerificationScope scope,
    String? macroActivityId,
  });

  Future<VerificationRun> startVerification(StartVerificationRequest request);

  Future<PagedResult<TicketSummary>> searchServiceTickets({
    required String serviceId,
    String query = '',
    required int page,
    required int size,
  });
}

class PagedResult<T> {
  const PagedResult({required this.items, required this.page});

  final List<T> items;
  final PageInfo page;
}
