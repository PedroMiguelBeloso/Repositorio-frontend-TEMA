import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception_mapper.dart';
import '../../services/data/service_repository_provider.dart';
import '../../services/data/service_repository.dart';
import '../../services/model/service_models.dart';
import '../model/new_verification_models.dart';
import '../model/verification_history_models.dart';
import '../model/verification_result_models.dart';
import 'dto/verification_history_dtos.dart';
import 'dto/verification_result_dtos.dart';
import 'verification_repository.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(serviceRepositoryProvider),
  ),
);

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._api, this._services);
  final ApiClient _api;
  final ServiceRepository _services;
  final _mapper = const ApiExceptionMapper();

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) => _services.listServices(page: page, size: size);

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) async {
    try {
      final response = await _api.get(
        '/verifications',
        queryParameters: {
          'page': page,
          'size': size,
          if (serviceId != null && serviceId.trim().isNotEmpty)
            'serviceId': serviceId,
        },
      );
      return VerificationHistoryPageDto.fromJson(_map(response.data)).toModel();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta del historial de verificaciones no tiene un formato válido.',
      );
    }
  }

  @override
  Future<PagedResult<VerificationResult>> listResults({
    required String runId,
    required int page,
    required int size,
  }) async {
    try {
      final response = await _api.get(
        '/verifications/$runId/results',
        queryParameters: {'page': page, 'size': size},
      );
      return VerificationResultPageDto.fromJson(_map(response.data)).toModel();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de resultados de la verificación no tiene un formato válido.',
      );
    }
  }

  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) async {
    try {
      final response = await _api.post(
        '/verifications/$runId/results/$resultId/applicability',
        data: {
          'revision': revision,
          'decision': decision.apiValue,
          'rationale': rationale.trim(),
        },
      );
      return VerificationResultDto.fromJson(_map(response.data)).toModel();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de aplicabilidad no tiene un formato válido.',
      );
    }
  }

  @override
  Future<VerificationResult> decideResult({
    required String runId,
    required String resultId,
    required int revision,
    required VerificationResultStatus finalStatus,
    required String rationale,
  }) async {
    try {
      final response = await _api.put(
        '/verifications/$runId/results/$resultId/decision',
        data: {
          'revision': revision,
          'finalStatus': finalStatus.apiValue,
          'rationale': rationale.trim(),
        },
      );
      return VerificationResultDto.fromJson(_map(response.data)).toModel();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de la decisión humana no tiene un formato válido.',
      );
    }
  }

  @override
  Future<VerificationRun> getVerification(String runId) async {
    try {
      final response = await _api.get('/verifications/$runId');
      return VerificationRunDto.fromJson(_map(response.data)).toRun();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const UnexpectedFailure(
          'La ejecución no existe o no se encuentra.',
        );
      }
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'La respuesta de la ejecución no tiene un formato válido.',
      );
    }
  }

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId) async {
    try {
      final response = await _api.get(
        '/services/$serviceId/verifiable-processes',
      );
      return _list(response.data)
          .map(
            (json) => VerifiableProcess(
              id: _string(json, 'processVersionId'),
              name: _string(json, 'processName'),
              officialVersion: _string(json, 'officialVersion'),
              macroActivities: _list(json['macroActivities'])
                  .map(
                    (m) => VerifiableMacroActivity(
                      id: _string(m, 'id'),
                      name: _string(m, 'name'),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure(
        'No se pudieron interpretar los procesos verificables.',
      );
    }
  }

  @override
  Future<VerificationPreview> preview(VerificationTarget target) async {
    try {
      final response = await _api.post(
        '/verifications/preview',
        data: {
          'serviceId': target.serviceId,
          'processVersionId': target.processVersionId,
          'scope': target.scope.apiValue,
          if (target.macroActivityId != null)
            'macroActivityId': target.macroActivityId,
          if (target.note?.isNotEmpty == true) 'note': target.note,
        },
      );
      final json = _map(response.data);
      return VerificationPreview(
        serviceId: _string(json, 'serviceId'),
        serviceRevision: json['serviceRevision'] as int,
        processVersionId: _string(json, 'processVersionId'),
        scope: VerificationScope.fromApi(json['scope'] as String?),
        macroActivityId: json['macroActivityId'] as String?,
        expectations: _list(json['expectations'])
            .map(
              (e) => PreviewExpectation(
                id: _string(e, 'id'),
                displayName: _string(e, 'displayName'),
                location: _string(e, 'location'),
                evidenceType: _string(e, 'evidenceType'),
                applicability: _string(e, 'applicability'),
                cardinality: _string(e, 'cardinality'),
                ticketSelectionGroupId: e['ticketSelectionGroupId'] as String?,
              ),
            )
            .toList(),
        ticketSelectionGroups: _list(json['ticketSelectionGroups'])
            .map(
              (g) => TicketSelectionGroup(
                id: _string(g, 'id'),
                label: _string(g, 'label'),
                cardinality: _string(g, 'cardinality'),
                required: g['required'] as bool,
                relatedExpectationIds: (g['relatedExpectationIds'] as List)
                    .cast<String>(),
              ),
            )
            .toList(),
      );
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure('No se pudo interpretar la vista previa.');
    }
  }

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) async {
    try {
      final response = await _api.get(
        '/services/$serviceId/tickets',
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          'page': page,
          'size': 20,
        },
      );
      final json = _map(response.data);
      final paging = _map(json['page']);
      return TicketPage(
        items: _list(json['items'])
            .map(
              (t) => TicketSummary(
                id: _string(t, 'id'),
                subject: _string(t, 'subject'),
                status: _string(t, 'status'),
                assignedTo: t['assignedTo'] as String?,
              ),
            )
            .toList(),
        page: PageInfo(
          page: paging['page'] as int,
          size: paging['size'] as int,
          totalElements: paging['totalElements'] as int,
          totalPages: paging['totalPages'] as int,
        ),
      );
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure('No se pudieron interpretar los tickets.');
    }
  }

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) async {
    try {
      final response = await _api.post(
        '/verifications',
        data: {
          'serviceId': preview.serviceId,
          'serviceRevision': preview.serviceRevision,
          'processVersionId': preview.processVersionId,
          'scope': preview.scope.apiValue,
          if (preview.macroActivityId != null)
            'macroActivityId': preview.macroActivityId,
          if (note?.isNotEmpty == true) 'note': note,
          'ticketSelections': [
            for (final group in preview.ticketSelectionGroups)
              if ((selections[group.id] ?? {}).isNotEmpty)
                {
                  'groupId': group.id,
                  'ticketIds': (selections[group.id] ?? {}).toList(),
                },
          ],
        },
      );
      return _string(_map(response.data), 'id');
    } on DioException catch (error) {
      throw _mapper.map(error);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure('No se pudo iniciar la verificación.');
    }
  }

  static Map<String, dynamic> _map(Object? value) =>
      Map<String, dynamic>.from(value as Map);
  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List).map((item) => _map(item)).toList();
  static String _string(Map<String, dynamic> json, String key) =>
      json[key] as String;
}
