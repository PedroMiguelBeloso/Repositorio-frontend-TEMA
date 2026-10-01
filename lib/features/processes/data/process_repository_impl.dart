import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../model/evidence_expectation.dart';
import '../model/process_models.dart';
import 'process_repository.dart';

class ProcessRepositoryImpl implements ProcessRepository {
	ProcessRepositoryImpl(this._apiClient);

	final ApiClient _apiClient;
	final ApiExceptionMapper _exceptionMapper = const ApiExceptionMapper();

	@override
	Future<ProcessPage<ProcessDefinition>> listProcesses({
		required int page,
		required int size,
	}) async {
		try {
			final response = await _apiClient.get(
				'/processes',
				queryParameters: {'page': page, 'size': size},
			);
			final json = _asMap(response.data);
			return ProcessPage(
				items: _readItems(json).map(ProcessDefinition.fromJson).toList(),
				page: _readPageNumber(json),
				totalPages: _readTotalPages(json),
			);
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
			return ProcessDefinition.fromJson(_asMap(response.data));
		} on DioException catch (error) {
			throw _exceptionMapper.map(error);
		} on AppFailure {
			rethrow;
		} catch (_) {
			throw const UnexpectedFailure(
				'No se pudo interpretar el proceso seleccionado.',
			);
		}
	}

	@override
	Future<ProcessPage<ProcessVersionSummary>> listVersions({
		required String processId,
		required int page,
		required int size,
	}) async {
		try {
			final response = await _apiClient.get(
				'/processes/$processId/versions',
				queryParameters: {'page': page, 'size': size},
			);
			final json = _asMap(response.data);
			return ProcessPage(
				items: _readItems(json).map(ProcessVersionSummary.fromJson).toList(),
				page: _readPageNumber(json),
				totalPages: _readTotalPages(json),
			);
		} on DioException catch (error) {
			throw _exceptionMapper.map(error);
		} on AppFailure {
			rethrow;
		} catch (_) {
			throw const UnexpectedFailure(
				'No se pudieron cargar las versiones del proceso.',
			);
		}
	}

	@override
	Future<ProcessVersionDraft> getVersion({
		required String processId,
		required String versionId,
	}) async {
		try {
			final response = await _apiClient.get(
				'/processes/$processId/versions/$versionId',
			);
			final definitions = await _readAllDefinitions();
			return ProcessVersionDraft.fromJson(
				_asMap(response.data),
				{for (final definition in definitions) definition.id: definition},
			);
		} on DioException catch (error) {
			throw _exceptionMapper.map(error);
		} on AppFailure {
			rethrow;
		} catch (_) {
			throw const UnexpectedFailure(
				'No se pudo interpretar la estructura de la versión.',
			);
		}
	}

	@override
	Future<ProcessVersionDraft> saveDraft(
		ProcessVersionDraft draft,
		List<RegistryDefinition> definitions,
	) async {
		try {
			final response = await _apiClient.put(
				'/processes/${draft.processId}/versions/${draft.id}',
				data: draft.toSaveJson(),
			);
			return ProcessVersionDraft.fromJson(
				_asMap(response.data),
				{for (final definition in definitions) definition.id: definition},
			);
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

	@override
	Future<ProcessPage<RegistryDefinition>> searchRegistry({
		required String query,
		required int page,
		required int size,
	}) async {
		try {
			final response = await _apiClient.get(
				'/registry-definitions',
				queryParameters: {
					if (query.trim().isNotEmpty) 'query': query.trim(),
					'page': page,
					'size': size,
				},
			);
			final json = _asMap(response.data);
			return ProcessPage(
				items: _readItems(json).map(_readRegistryDefinition).toList(),
				page: _readPageNumber(json),
				totalPages: _readTotalPages(json),
			);
		} on DioException catch (error) {
			throw _exceptionMapper.map(error);
		} on AppFailure {
			rethrow;
		} catch (_) {
			throw const UnexpectedFailure(
				'La respuesta del catálogo no tiene un formato válido.',
			);
		}
	}

	@override
	Future<RegistryDefinition> createRegistryDefinition({
		required String canonicalName,
		required EvidenceType evidenceType,
		String? officialNomenclature,
	}) async {
		try {
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
		} on DioException catch (error) {
			throw _exceptionMapper.map(error);
		} on AppFailure {
			rethrow;
		} catch (_) {
			throw const UnexpectedFailure(
				'No se pudo interpretar el registro creado.',
			);
		}
	}

	Future<List<RegistryDefinition>> _readAllDefinitions() async {
		const size = 20;
		var page = 0;
		final definitions = <RegistryDefinition>[];
		while (true) {
			final result = await searchRegistry(query: '', page: page, size: size);
			definitions.addAll(result.items);
			if (!result.hasNext) return definitions;
			page = result.page + 1;
		}
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

	int _readPageNumber(Map<String, dynamic> json) =>
			_readPageInfo(json)['page'] as int? ?? 0;

	int _readTotalPages(Map<String, dynamic> json) =>
			_readPageInfo(json)['totalPages'] as int? ?? 0;

	Map<String, dynamic> _readPageInfo(Map<String, dynamic> json) {
		final page = json['page'];
		if (page is Map<String, dynamic>) return page;
		if (page is Map) return Map<String, dynamic>.from(page);
		throw const FormatException('Falta la información de paginación.');
	}
}
