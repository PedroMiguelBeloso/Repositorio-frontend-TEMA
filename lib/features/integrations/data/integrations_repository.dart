import '../model/integration_status.dart';

abstract interface class IntegrationsRepository {
  Future<List<IntegrationStatus>> loadStatuses();
  Future<List<IntegrationStatus>> testIntegrations();
}