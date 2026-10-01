import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/service_models.dart';
import 'dto/service_dtos.dart';
import 'service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;
  final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) async {
    try {
      final response = await _apiClient.get(
        '/services',
        queryParameters: {'page': page, 'size': size},
      );
      final json = _asMap(response.data);
      return PagedResult(
        items: _readItems(json)
            .map((item) => ServiceDto.fromJson(item).toModel())
            .toList(),
        page: PageInfoDto.fromJson(_readPage(json)).toModel(),
      );
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de servicios no tiene un formato válido.',
      );
    }
  }

  @override
  Future<Service> getService(String id) async {
    try {
      final response = await _apiClient.get('/services/$id');
      return ServiceDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta del servicio no tiene un formato válido.',
      );
    }
  }

  @override
  Future<Service> createService(ServiceInput input) async {
    try {
      final request = ServiceWriteRequestDto.fromModel(input);
      final response = await _apiClient.post(
        '/services',
        data: request.toJson(includeRevision: false),
      );
      return ServiceDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudo interpretar la respuesta al crear el servicio.',
      );
    }
  }

  @override
  Future<Service> updateService(String id, ServiceInput input) async {
    if (input.revision == null) {
      throw const ValidationFailure(
        'La revisión es obligatoria para editar el servicio.',
      );
    }

    try {
      final request = ServiceWriteRequestDto.fromModel(input);
      final response = await _apiClient.put(
        '/services/$id',
        data: request.toJson(includeRevision: true),
      );
      return ServiceDto.fromJson(_asMap(response.data)).toModel();
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudo interpretar la respuesta al actualizar el servicio.',
      );
    }
  }

  @override
  Future<List<AssignableProcessGroup>> getAssignableProcessVersions() async {
    try {
      final processes = await _readAllPages<ProcessDefinitionDto>(
        path: '/processes',
        parseItem: ProcessDefinitionDto.fromJson,
      );

      final groups = <AssignableProcessGroup>[];
      for (final process in processes) {
        // The API explicitly excludes Quality and Continuous Improvement from
        // service assignment in this delivery. Filtering by code avoids a
        // fragile dependency on the translated process name.
        if (ProcessCode.fromApi(process.code) ==
            ProcessCode.qualityContinuousImprovement) {
          continue;
        }

        final versions = await _readAllPages<ProcessVersionDto>(
          path: '/processes/${process.id}/versions',
          parseItem: ProcessVersionDto.fromJson,
        );
        final published = versions
            .map((version) => version.toModel(processName: process.name))
            .where((version) => version.isPublished)
            .toList();

        groups.add(
          AssignableProcessGroup(
            process: process.toModel(),
            publishedVersions: published,
          ),
        );
      }

      return groups;
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudieron cargar los procesos y sus versiones.',
      );
    }
  }

  @override
  Future<PagedResult<DriveFolderOption>> getDriveFolders({
    String query = '',
    required int page,
    required int size,
  }) async {
    try {
      final response = await _apiClient.get(
        '/integrations/drive/folders',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'size': size,
        },
      );
      final json = _asMap(response.data);
      return PagedResult(
        items: _readItems(json)
            .map((item) => ExternalFolderDto.fromJson(item).toModel())
            .toList(),
        page: PageInfoDto.fromJson(_readPage(json)).toModel(),
      );
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de Google Drive no tiene un formato válido.',
      );
    }
  }

  @override
  Future<PagedResult<RedmineProjectOption>> getRedmineProjects({
    required int page,
    required int size,
  }) async {
    try {
      final response = await _apiClient.get(
        '/integrations/redmine/projects',
        queryParameters: {'page': page, 'size': size},
      );
      final json = _asMap(response.data);
      return PagedResult(
        items: _readItems(json)
            .map((item) => ExternalProjectDto.fromJson(item).toModel())
            .toList(),
        page: PageInfoDto.fromJson(_readPage(json)).toModel(),
      );
    } on DioException catch (error) {
      throw _exceptionMapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de Redmine no tiene un formato válido.',
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
      final pageInfo = PageInfoDto.fromJson(_readPage(json)).toModel();
      if (!pageInfo.hasNext) break;
      page = pageInfo.page + 1;
    }

    return result;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
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
