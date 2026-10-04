import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/process_models.dart';
import '../model/registry_definition.dart';
import 'registry_repository.dart';

final registryRepositoryProvider = Provider<RegistryRepository>(
  (ref) => RegistryRepositoryImpl(ref.watch(apiClientProvider)),
);

class RegistryRepositoryImpl implements RegistryRepository {
  RegistryRepositoryImpl(this._client);

  final ApiClient _client;
  final ApiExceptionMapper _mapper = const ApiExceptionMapper();

  @override
  Future<RegistryPage> search({
    String query = '',
    int page = 0,
    int size = 20,
  }) => _guard(() async {
    final response = await _client.get(
      '/registry-definitions',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'page': page,
        'size': size,
      },
    );
    final json = _asMap(response.data);
    final pageInfo = _asMap(json['page']);
    final items = json['items'] as List<dynamic>;
    return RegistryPage(
      items: items
          .map((item) => RegistryDefinition.fromJson(_asMap(item)))
          .toList(),
      page: pageInfo['page'] as int,
      size: pageInfo['size'] as int,
      totalElements: pageInfo['totalElements'] as int,
      totalPages: pageInfo['totalPages'] as int,
    );
  });

  @override
  Future<RegistryDefinition> create({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) => _guard(() async {
    final response = await _client.post(
      '/registry-definitions',
      data: {
        'canonicalName': canonicalName.trim(),
        'evidenceType': evidenceType.apiValue,
        if (officialNomenclature?.trim().isNotEmpty == true)
          'officialNomenclature': officialNomenclature!.trim(),
      },
    );
    return RegistryDefinition.fromJson(_asMap(response.data));
  });

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('La respuesta del catálogo no es válida.');
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure('No se pudo leer el índice de registros.');
    }
  }
}
