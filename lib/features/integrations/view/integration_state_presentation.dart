import '../../../core/widgets/status_chip.dart';
import '../model/integration_state.dart';

extension IntegrationStatePresentation on IntegrationState {
  StatusTone get tone => switch (this) {
    IntegrationState.available => StatusTone.success,
    IntegrationState.permissionError => StatusTone.warning,
    IntegrationState.authError || IntegrationState.unavailable =>
      StatusTone.danger,
    IntegrationState.notConfigured => StatusTone.info,
  };
}