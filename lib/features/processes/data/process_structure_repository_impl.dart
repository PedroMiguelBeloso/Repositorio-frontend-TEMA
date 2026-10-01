import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/evidence_expectation.dart';
import '../model/process_structure_models.dart';
import 'process_structure_repository.dart';

class ProcessStructureRepositoryImpl implements ProcessStructureRepository {
  ProcessStructureRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

  @override
  Future<ProcessPage<ProcessDefinition>> listProcesses({
    required int page,
    required int size,
  }) => _guard(
    () => _readPage(
      '/processes',
      page: page,
      size: size,
      parseItem: ProcessDefinition.fromJson,
    ),
    'La respuesta de procesos no tiene un formato válido.',
  );

  @override
  Future<ProcessDefinition> getProcess(String processId) => _guard(() async {
    final response = await _apiClient.get('/processes/$processId');
    return ProcessDefinition.fromJson(_asMap(response.data));
  }, 'No se pudo interpretar el proceso seleccionado.');

  @override
  Future<ProcessPage<ProcessVersionSummary>> listVersions({
    required String processId,
    required int page,
    required int size,
  }) => _guard(
    () => _readPage(
      '/processes/$processId/versions',
      page: page,
      size: size,
      parseItem: ProcessVersionSummary.fromJson,
    ),
    'No se pudieron cargar las versiones del proceso.',
  );

  @override
  Future<ProcessVersionDraft> getVersion({
    required String processId,
    required String versionId,
  }) => _guard(() async {
    final response = await _apiClient.get(
      '/processes/$processId/versions/$versionId',
    );
    final definitions = await _readAllDefinitions();
    return ProcessVersionDraft.fromJson(
      _asMap(response.data),
      {for (final definition in definitions) definition.id: definition},
    );
  }, 'No se pudo interpretar la estructura de la versión.');

  @override
  Future<ProcessVersionDraft> saveDraft(
    ProcessVersionDraft draft,
    List<RegistryDefinition> definitions,
  ) => _guard(() async {
    final response = await _apiClient.put(
      '/processes/${draft.processId}/versions/${draft.id}',
      data: draft.toSaveJson(),
    );
    return ProcessVersionDraft.fromJson(
      _asMap(response.data),
      {for (final definition in definitions) definition.id: definition},
    );
  }, 'No se pudo interpretar la respuesta al guardar el borrador.');

  @override
  Future<ProcessPage<RegistryDefinition>> searchRegistry({
    required String query,
    required int page,
    required int size,
  }) => _guard(() async {
    final response = await _apiClient.get(
      '/registry-definitions',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'page': page,
        'size': size,
      },
    );
    return _pageFromJson(_asMap(response.data), _readRegistryDefinition);
  }, 'La respuesta del catálogo no tiene un formato válido.');

  @override
  Future<RegistryDefinition> createRegistryDefinition({
    required String canonicalName,
    required EvidenceType evidenceType,
    String? officialNomenclature,
  }) => _guard(() async {
    final response = await _apiClient.post(
      '/registry-definitions',
      data: {
        'canonicalName': canonicalName.trim(),
        'evidenceType': evidenceType.apiValue,
        if (officialNomenclature?.trim().isNotEmpty == true)
          'officialNomenclature': officialNomenclature!.trim(),
      },
    );
    return _readRegistryDefinition(_asMap(response.data));
  }, 'No se pudo interpretar el registro creado.');

  Future<List<RegistryDefinition>> _readAllDefinitions() async {
    const size = 50;
    var page = 0;
    final definitions = <RegistryDefinition>[];
    while (true) {
      final result = await searchRegistry(query: '', page: page, size: size);
      definitions.addAll(result.items);
      if (!result.hasNext) return definitions;
      page = result.page + 1;
    }
  }

  Future<ProcessPage<T>> _readPage<T>(
    String path, {
    required int page,
    required int size,
    required T Function(Map<String, dynamic>) parseItem,
  }) async {
    final response = await _apiClient.get(
      path,
      queryParameters: {'page': page, 'size': size},
    );
    return _pageFromJson(_asMap(response.data), parseItem);
  }

  ProcessPage<T> _pageFromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Falta la colección de resultados.');
    }
    final pageInfo = _asMap(json['page']);
    return ProcessPage(
      items: items.map((item) => parseItem(_asMap(item))).toList(),
      page: _readInt(pageInfo['page']),
      totalPages: _readInt(pageInfo['totalPages']),
    );
  }

  RegistryDefinition _readRegistryDefinition(Map<String, dynamic> json) =>
      RegistryDefinition(
        id: json['id'] as String,
        key: json['key'] as String? ?? '',
        canonicalName: json['canonicalName'] as String? ?? '',
        evidenceType: EvidenceType.fromApi(json['evidenceType'] as String?),
        officialNomenclature: json['officialNomenclature'] as String?,
        preloaded: json['preloaded'] as bool? ?? false,
      );

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Respuesta JSON inválida.');
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Valor numérico inválido.');
  }

  Future<T> _guard<T>(Future<T> Function() operation, String message) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw UnexpectedFailure(message);
    }
  }
}
