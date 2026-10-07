import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/verification_models.dart';
import 'verification_repository.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  const VerificationRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

  @override
  Future<VerificationPreview> previewVerification({
    required String serviceId,
    required String processVersionId,
    required VerificationScope scope,
    String? macroActivityId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/verifications/preview',
        data: {
          'serviceId': serviceId,
          'processVersionId': processVersionId,
          'scope': scope.apiValue,
          if (macroActivityId != null && macroActivityId.isNotEmpty)
            'macroActivityId': macroActivityId,
        },
      );
      return VerificationPreview.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La vista previa de verificación no tiene un formato válido.',
      );
    }
  }

  @override
  Future<VerificationRun> startVerification(StartVerificationRequest request) async {
    try {
      final response = await _apiClient.post(
        '/verifications',
        data: request.toJson(),
      );
      return VerificationRun.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de inicio de verificación no tiene un formato válido.',
      );
    }
  }

  @override
  Future<PagedResult<TicketSummary>> searchServiceTickets({
    required String serviceId,
    String query = '',
    required int page,
    required int size,
  }) async {
    try {
      final response = await _apiClient.get(
        '/services/$serviceId/tickets',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'size': size,
        },
      );
      final json = _asMap(response.data);
      return PagedResult(
        items: _readItems(json)
            .map((item) => TicketSummary.fromJson(item))
            .toList(),
        page: PageInfo(
          page: _readPage(json)['page'] as int? ?? 0,
          size: _readPage(json)['size'] as int? ?? size,
          totalElements: _readPage(json)['totalElements'] as int? ?? 0,
          totalPages: _readPage(json)['totalPages'] as int? ?? 0,
        ),
      );
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de tickets de Redmine no tiene un formato válido.',
      );
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Respuesta JSON inválida.');
  }

  Map<String, dynamic> _readPage(Map<String, dynamic> json) {
    final page = json['page'];
    if (page is Map<String, dynamic>) return page;
    if (page is Map) return Map<String, dynamic>.from(page);
    throw const FormatException('Falta la información de paginación.');
  }

  List<Map<String, dynamic>> _readItems(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Falta la colección de resultados.');
    }
    return items.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      throw const FormatException('Elemento JSON inválido.');
    }).toList();
  }
}
