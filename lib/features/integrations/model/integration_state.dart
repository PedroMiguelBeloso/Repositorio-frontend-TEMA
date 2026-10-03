import '../../../core/errors/app_failure.dart';

enum IntegrationState {
  available('AVAILABLE', 'Disponible'),
  authError('AUTH_ERROR', 'Error de autenticación'),
  permissionError('PERMISSION_ERROR', 'Sin permiso para consultar'),
  unavailable('UNAVAILABLE', 'No disponible'),
  notConfigured('NOT_CONFIGURED', 'No configurada');

  const IntegrationState(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static IntegrationState fromApi(Object? value) {
    for (final state in values) {
      if (state.apiValue == value) return state;
    }
    throw const UnexpectedFailure(
      'La respuesta de integraciones contiene un estado desconocido.',
    );
  }
}