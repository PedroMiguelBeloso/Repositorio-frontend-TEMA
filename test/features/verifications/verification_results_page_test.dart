import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/processes/model/evidence_expectation.dart'
    as evidence_model;
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/processes/model/process_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_result_location_resolver_provider.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_result_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/verification_results_page.dart';

void main() {
  testWidgets('admin corrects a ticket result with a required rationale', (
    tester,
  ) async {
    final repository = _PageRepository(
      run: _run(VerificationRunStatus.completed),
      page: PagedResult(
        items: [_result('r1', 'Ticket actualizado', subjectTicketId: '204')],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    await _pump(tester, repository, const Size(900, 1000), admin: true);
    await tester.tap(find.text('Ticket actualizado'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmar o corregir resultado'));
    await tester.tap(find.text('Confirmar o corregir resultado'));
    await tester.pumpAndSettle();
    expect(find.text('Propuesta automática: Cumple'), findsOneWidget);
    expect(find.text('Estado actual: Cumple'), findsOneWidget);
    expect(find.text('No aplica'), findsNothing);
    await tester.tap(find.text('Registrar decisión'));
    await tester.pumpAndSettle();
    expect(find.text('Escribí el fundamento de la decisión.'), findsOneWidget);
    await tester.tap(find.text('No cumple'));
    await tester.enterText(
      find.byType(TextFormField),
      'El ticket no muestra la validación solicitada.',
    );
    await tester.tap(find.text('Registrar decisión'));
    await tester.pumpAndSettle();
    expect(repository.statusDecisionCalled, isTrue);
    expect(repository.statusDecisionRevision, 1);
    expect(
      repository.statusDecisionFinalStatus,
      VerificationResultStatus.doesNotComply,
    );
    expect(
      find.text('Decisión registrada. Estado actual: No cumple.'),
      findsOneWidget,
    );
    expect(find.text('Decisiones humanas previas'), findsOneWidget);
  });

  testWidgets('reader cannot open human status review', (tester) async {
    final repository = _PageRepository(
      run: _run(VerificationRunStatus.completed),
      page: PagedResult(
        items: [_result('r1', 'Ticket actualizado', subjectTicketId: '204')],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    await _pump(tester, repository, const Size(390, 800));
    await tester.tap(find.text('Ticket actualizado'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar o corregir resultado'), findsNothing);
  });

  testWidgets(
    'admin can resolve pending applicability and sees the updated status',
    (tester) async {
      final repository = _PageRepository(
        run: _run(VerificationRunStatus.completed),
        page: PagedResult(
          items: [
            _result(
              'r3',
              'Orden de transporte',
              proposedStatus: VerificationResultStatus.reviewRequired,
              effectiveStatus: VerificationResultStatus.reviewRequired,
              applicabilityDecision: ApplicabilityDecision.undetermined,
            ),
          ],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      );
      await _pump(tester, repository, const Size(900, 1000), admin: true);
      await tester.tap(find.text('Orden de transporte'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Resolver aplicabilidad'));
      await tester.tap(find.text('Resolver aplicabilidad'));
      await tester.pumpAndSettle();
      expect(find.text('Orden de transporte'), findsNWidgets(2));
      await tester.tap(find.text('Guardar decisión'));
      await tester.pumpAndSettle();
      expect(find.text('Elegí si esta evidencia aplica.'), findsOneWidget);
      await tester.tap(find.text('No aplica').last);
      await tester.enterText(find.byType(TextFormField), 'No hubo desarrollo.');
      await tester.tap(find.text('Guardar decisión'));
      await tester.pumpAndSettle();
      expect(repository.resolveCalled, isTrue);
      expect(repository.resolvedRevision, 1);
      expect(
        repository.resolvedDecision,
        HumanApplicabilityDecision.notApplicable,
      );
      expect(
        find.text('Aplicabilidad guardada. Estado actual: No aplica.'),
        findsOneWidget,
      );
      expect(find.text('Decisiones humanas previas'), findsOneWidget);
    },
  );

  testWidgets('reader does not see applicability action', (tester) async {
    final repository = _PageRepository(
      run: _run(VerificationRunStatus.completed),
      page: PagedResult(
        items: [
          _result(
            'r3',
            'Orden de transporte',
            applicabilityDecision: ApplicabilityDecision.undetermined,
          ),
        ],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    await _pump(tester, repository, const Size(900, 1000));
    await tester.tap(find.text('Orden de transporte'));
    await tester.pumpAndSettle();
    expect(find.text('Resolver aplicabilidad'), findsNothing);
  });
  testWidgets(
    'completed execution shows four statuses and ticket-specific results',
    (tester) async {
      final repository = _PageRepository(
        run: _run(VerificationRunStatus.completed),
        page: PagedResult(
          items: [
            _result(
              'r2',
              'Ticket actualizado',
              subjectTicketId: '205',
              proposedStatus: VerificationResultStatus.complies,
              effectiveStatus: VerificationResultStatus.doesNotComply,
            ),
            _result(
              'r1',
              'Ticket actualizado',
              subjectTicketId: '204',
              proposedStatus: VerificationResultStatus.complies,
              effectiveStatus: VerificationResultStatus.complies,
            ),
            _result(
              'r3',
              'Registro documental',
              proposedStatus: VerificationResultStatus.reviewRequired,
              effectiveStatus: VerificationResultStatus.reviewRequired,
              applicabilityDecision: ApplicabilityDecision.undetermined,
              applicabilityOrigin: DecisionOrigin.aiApplicability,
            ),
            _result(
              'r4',
              'Evidencia fuera de alcance',
              proposedStatus: VerificationResultStatus.notApplicable,
              effectiveStatus: VerificationResultStatus.notApplicable,
            ),
          ],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 4,
            totalPages: 1,
          ),
        ),
      );
      await _pump(tester, repository, const Size(900, 1000));

      expect(find.text('Cumple'), findsOneWidget);
      expect(find.text('No cumple'), findsOneWidget);
      expect(find.text('Requiere revisión'), findsOneWidget);
      expect(find.text('No aplica'), findsOneWidget);
      expect(find.text('Ticket 204'), findsOneWidget);
      expect(find.text('Ticket 205'), findsOneWidget);
      expect(find.text('Macroactividad: Gestión operativa'), findsOneWidget);
      expect(
        find.text('Macroactividad: Atención de incidentes'),
        findsOneWidget,
      );
      expect(find.text('· Actividad: Actualizar ticket'), findsOneWidget);
      expect(find.text('Sin resultados'), findsNothing);

      await tester.tap(find.text('Ticket actualizado').first);
      await tester.pumpAndSettle();

      expect(find.text('Fundamento'), findsOneWidget);
      expect(
        find.textContaining('La evidencia de prueba respalda'),
        findsOneWidget,
      );
      expect(find.text('Referencias encontradas'), findsOneWidget);
      expect(find.text('Hubo una decisión humana posterior'), findsOneWidget);
      expect(find.text('Propuesta automática'), findsOneWidget);

      await tester.tap(find.text('Ticket actualizado').first);
      await tester.pumpAndSettle();
      expect(find.text('Hubo una decisión humana posterior'), findsNothing);
    },
  );

  testWidgets(
    'queued execution shows progress and never renders empty results',
    (tester) async {
      final repository = _PageRepository(
        run: _run(VerificationRunStatus.queued, processed: 1, total: 4),
      );
      await _pump(tester, repository, const Size(390, 800));

      expect(find.text('La ejecución todavía está en espera.'), findsOneWidget);
      expect(find.text('Volver al detalle de la ejecución'), findsOneWidget);
      expect(
        find.text('La ejecución finalizó y no hay resultados para mostrar.'),
        findsNothing,
      );
      expect(repository.listResultsCalls, 0);
    },
  );

  testWidgets(
    'failed execution shows failure and retry instead of an empty list',
    (tester) async {
      final repository = _PageRepository(
        run: _run(
          VerificationRunStatus.failed,
          failureMessage: 'La conexión con Redmine no está disponible.',
        ),
      );
      await _pump(tester, repository, const Size(390, 800));

      expect(find.text('La ejecución tuvo un error'), findsOneWidget);
      expect(
        find.text('La conexión con Redmine no está disponible.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(
        find.text('La ejecución finalizó y no hay resultados para mostrar.'),
        findsNothing,
      );
      expect(repository.listResultsCalls, 0);
    },
  );

  testWidgets('completed empty execution shows explicit empty state', (
    tester,
  ) async {
    final repository = _PageRepository(
      run: _run(VerificationRunStatus.completed),
      page: const PagedResult(
        items: [],
        page: PageInfo(page: 0, size: 20, totalElements: 0, totalPages: 0),
      ),
    );
    await _pump(tester, repository, const Size(390, 800));

    expect(
      find.text('La ejecución finalizó y no hay resultados para mostrar.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows applicability origin, undetermined intervention and reference metadata',
    (tester) async {
      final repository = _PageRepository(
        run: _run(VerificationRunStatus.completed),
        page: PagedResult(
          items: [
            _result(
              'r3',
              'Registro con aplicabilidad pendiente',
              proposedStatus: VerificationResultStatus.reviewRequired,
              effectiveStatus: VerificationResultStatus.reviewRequired,
              applicabilityDecision: ApplicabilityDecision.undetermined,
              applicabilityOrigin: DecisionOrigin.aiApplicability,
              evidence: [
                EvidenceReference(
                  kind: EvidenceType.toolRecord,
                  source: EvidenceSource.toolRecord,
                  externalId: 'tool-33',
                  displayName: 'Registro de auditoría',
                  observedAt: DateTime.utc(2026, 10, 8, 12),
                  webUrl: 'https://example.test/reference/33',
                ),
              ],
            ),
          ],
          page: const PageInfo(
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
          ),
        ),
      );
      await _pump(tester, repository, const Size(390, 800));

      await tester.tap(find.text('Registro con aplicabilidad pendiente'));
      await tester.pumpAndSettle();

      expect(find.text('Indeterminada'), findsOneWidget);
      expect(find.text('Origen: IA para aplicabilidad'), findsOneWidget);
      expect(
        find.textContaining('requiere intervención de un Administrador'),
        findsOneWidget,
      );
      expect(find.text('Registro de auditoría'), findsOneWidget);
      expect(find.text('Registro de herramienta'), findsOneWidget);
      expect(find.text('Ticket'), findsNothing);
      expect(find.text('Abrir referencia'), findsOneWidget);
      expect(find.textContaining('08/10/2026'), findsOneWidget);
    },
  );

  testWidgets('webUrl controls are absent when URL is missing', (tester) async {
    final repository = _PageRepository(
      run: _run(VerificationRunStatus.completed),
      page: PagedResult(
        items: [
          _result(
            'r1',
            'Documento de evidencia',
            evidence: [
              EvidenceReference(
                kind: EvidenceType.document,
                source: EvidenceSource.drive,
                externalId: 'drive-1',
                displayName: 'Procedimiento oficial',
                observedAt: DateTime.utc(2026, 10, 8, 12),
              ),
            ],
          ),
        ],
        page: const PageInfo(
          page: 0,
          size: 20,
          totalElements: 1,
          totalPages: 1,
        ),
      ),
    );
    await _pump(tester, repository, const Size(390, 800));
    await tester.tap(find.text('Documento de evidencia'));
    await tester.pumpAndSettle();

    expect(find.text('Procedimiento oficial'), findsOneWidget);
    expect(find.text('Abrir referencia'), findsNothing);
    expect(
      find.textContaining('Identificador externo: drive-1'),
      findsOneWidget,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  _PageRepository repository,
  Size size, {
  bool admin = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (admin) sessionProvider.overrideWith(() => _AdminSessionNotifier()),
        verificationRepositoryProvider.overrideWithValue(repository),
        verificationResultLocationResolverProvider.overrideWithValue(
          _FakeLocationResolver(),
        ),
      ],
      child: const MaterialApp(home: VerificationResultsPage(runId: 'run-1')),
    ),
  );
  await tester.pumpAndSettle();
}

VerificationRun _run(
  VerificationRunStatus status, {
  int processed = 4,
  int total = 4,
  String? failureMessage,
}) {
  return VerificationRun(
    id: 'run-1',
    serviceId: 'service-1',
    processVersionId: 'version-1',
    scope: VerificationScope.process,
    status: status,
    progress: RunProgress.fromValues(total: total, processed: processed),
    startedAt: DateTime.utc(2026, 10, 8, 10),
    failureMessage: failureMessage,
  );
}

VerificationResult _result(
  String id,
  String name, {
  String? subjectTicketId,
  VerificationResultStatus proposedStatus = VerificationResultStatus.complies,
  VerificationResultStatus effectiveStatus = VerificationResultStatus.complies,
  ApplicabilityDecision applicabilityDecision = ApplicabilityDecision.applies,
  DecisionOrigin applicabilityOrigin = DecisionOrigin.deterministic,
  List<EvidenceReference> evidence = const [],
}) {
  return VerificationResult(
    id: id,
    runId: 'run-1',
    expectationId: 'expectation-$id',
    macroActivityId: 'macro-1',
    activityId: 'activity-1',
    displayName: name,
    evidenceType: subjectTicketId == null
        ? EvidenceType.document
        : EvidenceType.ticket,
    location: subjectTicketId == null
        ? EvidenceLocation.input
        : EvidenceLocation.activityRecord,
    subjectTicketId: subjectTicketId,
    applicability: ApplicabilityAssessment(
      decision: applicabilityDecision,
      origin: applicabilityOrigin,
      rationale: applicabilityDecision == ApplicabilityDecision.undetermined
          ? 'No hay información suficiente para resolver la aplicabilidad.'
          : 'La evidencia aplica al alcance seleccionado.',
      limitations: const [],
    ),
    proposedStatus: proposedStatus,
    effectiveStatus: effectiveStatus,
    rationale:
        'La evidencia de prueba respalda la conclusión de este resultado.',
    limitations: const [],
    evidence: evidence,
    humanDecisions: effectiveStatus == VerificationResultStatus.doesNotComply
        ? [
            HumanDecisionEvent(
              id: 'decision-$id',
              decisionType: HumanDecisionType.resultStatus,
              finalStatus: effectiveStatus,
              rationale:
                  'El Administrador corrigió el estado después de revisar el resultado.',
              decidedAt: DateTime.utc(2026, 10, 8, 13),
            ),
          ]
        : const [],
    revision: 1,
  );
}

class _FakeLocationResolver implements VerificationResultLocationResolver {
  @override
  Future<Map<String, VerificationResultLocationContext>> resolve({
    required VerificationRun run,
    required List<VerificationResult> results,
  }) async {
    final resolved = <String, VerificationResultLocationContext>{};
    for (final result in results) {
      if (result.id == 'r2') {
        resolved[result.id] = const VerificationResultLocationContext(
          macroActivityName: 'Atención de incidentes',
          activityName: 'Actualizar ticket',
        );
      } else if (result.id == 'r1') {
        resolved[result.id] = const VerificationResultLocationContext(
          macroActivityName: 'Gestión operativa',
          activityName: 'Registrar seguimiento',
        );
      }
      if (result.id == 'r3') {
        resolved[result.id] = const VerificationResultLocationContext(
          macroActivityName: 'Gestión de solicitudes',
          applicabilityMode: evidence_model.ApplicabilityMode.caseDependent,
        );
      }
    }
    return resolved;
  }
}

class _AdminSessionNotifier extends SessionNotifier {
  @override
  Session? build() => const Session(role: UserRole.administrator);
}

class _PageRepository implements VerificationRepository {
  @override
  Future<VerificationResult> decideResult({
    required String runId,
    required String resultId,
    required int revision,
    required VerificationResultStatus finalStatus,
    required String rationale,
  }) async {
    statusDecisionCalled = true;
    statusDecisionRevision = revision;
    statusDecisionFinalStatus = finalStatus;
    final original = page.items.firstWhere((item) => item.id == resultId);
    return VerificationResult(
      id: original.id,
      runId: original.runId,
      expectationId: original.expectationId,
      macroActivityId: original.macroActivityId,
      activityId: original.activityId,
      displayName: original.displayName,
      evidenceType: original.evidenceType,
      location: original.location,
      subjectTicketId: original.subjectTicketId,
      applicability: original.applicability,
      proposedStatus: original.proposedStatus,
      effectiveStatus: finalStatus,
      rationale: rationale,
      limitations: original.limitations,
      evidence: original.evidence,
      humanDecisions: [
        ...original.humanDecisions,
        HumanDecisionEvent(
          id: 'status-decision-new',
          decisionType: HumanDecisionType.resultStatus,
          finalStatus: finalStatus,
          rationale: rationale,
          decidedAt: DateTime.utc(2026, 10, 8),
        ),
      ],
      revision: revision + 1,
    );
  }

  @override
  Future<VerificationResult> resolveApplicability({
    required String runId,
    required String resultId,
    required int revision,
    required HumanApplicabilityDecision decision,
    required String rationale,
  }) async {
    resolveCalled = true;
    resolvedRevision = revision;
    resolvedDecision = decision;
    final original = page.items.single;
    return VerificationResult(
      id: original.id,
      runId: original.runId,
      expectationId: original.expectationId,
      macroActivityId: original.macroActivityId,
      activityId: original.activityId,
      displayName: original.displayName,
      evidenceType: original.evidenceType,
      location: original.location,
      subjectTicketId: original.subjectTicketId,
      applicability: ApplicabilityAssessment(
        decision: ApplicabilityDecision.notApplicable,
        origin: DecisionOrigin.human,
        rationale: rationale,
        limitations: const [],
      ),
      proposedStatus: original.proposedStatus,
      effectiveStatus: VerificationResultStatus.notApplicable,
      rationale: 'La evidencia no aplica.',
      limitations: const [],
      evidence: original.evidence,
      humanDecisions: [
        HumanDecisionEvent(
          id: 'decision-new',
          decisionType: HumanDecisionType.applicability,
          applicabilityDecision: decision,
          rationale: rationale,
          decidedAt: DateTime.utc(2026, 10, 8),
        ),
      ],
      revision: revision + 1,
    );
  }

  _PageRepository({
    required this.run,
    this.page = const PagedResult(
      items: [],
      page: PageInfo(page: 0, size: 20, totalElements: 0, totalPages: 0),
    ),
  });

  final VerificationRun run;
  final PagedResult<VerificationResult> page;
  int listResultsCalls = 0;
  bool resolveCalled = false;
  int? resolvedRevision;
  HumanApplicabilityDecision? resolvedDecision;
  bool statusDecisionCalled = false;
  int? statusDecisionRevision;
  VerificationResultStatus? statusDecisionFinalStatus;

  @override
  Future<VerificationRun> getVerification(String runId) async => run;

  @override
  Future<PagedResult<VerificationResult>> listResults({
    required String runId,
    required int page,
    required int size,
  }) async {
    listResultsCalls++;
    return this.page;
  }

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) => throw UnimplementedError();

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) => throw UnimplementedError();

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(String serviceId) =>
      throw UnimplementedError();

  @override
  Future<VerificationPreview> preview(VerificationTarget target) =>
      throw UnimplementedError();

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) => throw UnimplementedError();

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) => throw UnimplementedError();
}
