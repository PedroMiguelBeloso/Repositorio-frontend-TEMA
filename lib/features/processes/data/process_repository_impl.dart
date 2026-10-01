import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/process_models.dart';
import 'dto/process_dtos.dart';
import 'process_repository.dart';

class ProcessRepositoryImpl implements ProcessRepository {
  ProcessRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

  @override
  Future<List<ProcessDefinition>> listProcesses() async {
    try {
      final dtos = await _readAllPages<ProcessDefinitionDto>(
        path: '/processes',
        parseItem: ProcessDefinitionDto.fromJson,
      );
      return dtos.map((dto) => dto.toModel()).toList();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de procesos no tiene un formato válido.',
      );
    }
  }

  @override
  Future<ProcessDefinition> getProcess(String processId) async {
    try {
      final response = await _apiClient.get('/processes/$processId');
      return ProcessDefinitionDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta del proceso no tiene un formato válido.',
      );
    }
  }

  @override
  Future<ProcessDefinition> createProcess(M1ProcessCode code) async {
    if (!M1ProcessCode.creatableValues.contains(code)) {
      throw const ValidationFailure('El proceso seleccionado no es válido.');
    }

    try {
      final request = CreateProcessRequestDto(code: code, name: code.label);
      final response = await _apiClient.post(
        '/processes',
        data: request.toJson(),
      );
      return ProcessDefinitionDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudo interpretar la respuesta al crear el proceso.',
      );
    }
  }

  @override
  Future<List<ProcessVersion>> listVersions(String processId) async {
    try {
      final dtos = await _readAllPages<ProcessVersionDto>(
        path: '/processes/$processId/versions',
        parseItem: ProcessVersionDto.fromJson,
      );
      return dtos.map((dto) => dto.toModel()).toList();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de versiones no tiene un formato válido.',
      );
    }
  }

  @override
  Future<ProcessVersion> createDraftVersion({
    required String processId,
    required String officialVersion,
    required DateTime versionDate,
  }) async {
    if (officialVersion.trim().isEmpty) {
      throw const ValidationFailure('La versión oficial es obligatoria.');
    }

    try {
      final request = CreateVersionRequestDto(
        officialVersion: officialVersion,
        versionDate: versionDate,
      );
      final response = await _apiClient.post(
        '/processes/$processId/versions',
        data: request.toJson(),
      );
      return ProcessVersionDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudo interpretar la respuesta al iniciar el borrador.',
      );
    }
  }

  @override
  Future<ProcessVersion> getVersion({
    required String processId,
    required String versionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/processes/$processId/versions/$versionId',
      );
      return ProcessVersionDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta del borrador no tiene un formato válido.',
      );
    }
  }

  @override
  Future<ProcessVersion> saveDraft(ProcessVersion version) async {
    if (!version.status.isDraft) {
      throw const ValidationFailure(
        'Solo se puede guardar una versión en estado borrador.',
      );
    }

    try {
      final request = SaveDraftRequestDto(version: version);
      final response = await _apiClient.put(
        '/processes/${version.processId}/versions/${version.id}',
        data: request.toJson(),
      );
      return ProcessVersionDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudo interpretar la respuesta al guardar el borrador.',
      );
    }
  }

  Future<List<T>> _readAllPages<T>({
    required String path,
    required T Function(Map<String, dynamic>) parseItem,
  }) async {
    const pageSize = 50;
    var page = 0;
    final result = <T>[];

    while (true) {
      final response = await _apiClient.get(
        path,
        queryParameters: {'page': page, 'size': pageSize},
      );
      final json = _asMap(response.data);
      result.addAll(_readItems(json).map(parseItem));

      final pageJson = _asMap(json['page']);
      final currentPage = _readInt(pageJson['page']);
      final totalPages = _readInt(pageJson['totalPages']);
      if (currentPage + 1 >= totalPages) break;
      page = currentPage + 1;
    }

    return result;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Respuesta JSON inválida.');
  }

  List<Map<String, dynamic>> _readItems(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Falta la colección de resultados.');
    }
    return items.map((item) => _asMap(item)).toList();
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Valor numérico inválido.');
  }
}
