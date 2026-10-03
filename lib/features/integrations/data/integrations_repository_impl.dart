import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/integration_status.dart';
import 'integration_status_dto.dart';
import 'integrations_repository.dart';

class IntegrationsRepositoryImpl implements IntegrationsRepository {
  IntegrationsRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

  @override
  Future<List<IntegrationStatus>> loadStatuses() => _guard(
    () async {
      final response = await _apiClient.get('/integrations/status');
      return _readStatuses(response.data);
    },
    'No se pudieron cargar los estados de las integraciones.',
  );

  @override
  Future<List<IntegrationStatus>> testIntegrations() => _guard(
    () async {
      final response = await _apiClient.post('/integrations/test');
      return _readStatuses(response.data);
    },
    'No se pudo probar el estado de las integraciones.',
  );

  List<IntegrationStatus> _readStatuses(Object? data) {
    if (data is! List) {
      throw const UnexpectedFailure(
        'La respuesta de integraciones no tiene un formato válido.',
      );
    }

    final statuses = <IntegrationStatus>[];
    for (final item in data) {
      if (item is! Map) {
        throw const UnexpectedFailure(
          'La respuesta de integraciones no tiene un formato válido.',
        );
      }
      final json = Map<String, dynamic>.from(item);
      final dto = IntegrationStatusDto.tryFromJson(json);
      if (dto != null) statuses.add(dto.toModel());
    }
    return statuses;
  }

  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw _exceptionMapper.mapError(error, fallbackMessage: message);
    }
  }
}