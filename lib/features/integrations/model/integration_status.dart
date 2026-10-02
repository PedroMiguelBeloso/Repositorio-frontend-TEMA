import 'integration_source.dart';
import 'integration_state.dart';

class IntegrationStatus {
  const IntegrationStatus({
    required this.source,
    required this.state,
    required this.checkedAt,
    this.message,
  });

  final IntegrationSource source;
  final IntegrationState state;
  final DateTime checkedAt;
  final String? message;
}