import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository.dart';
import 'package:proyecto_tema_frontend/features/verifications/data/verification_repository_impl.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/new_verification_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/model/verification_history_models.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/new_verification_view_model.dart';

void main() {
  test(
    'previews the assigned version and requires one ticket for ONE',
    () async {
      final repository = _FakeRepository();
      final container = ProviderContainer(
        overrides: [
          verificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        newVerificationViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(newVerificationViewModelProvider.future);
      final vm = container.read(newVerificationViewModelProvider.notifier);

      await vm.selectService('service-1');
      vm.selectProcess('version-1');
      await vm.loadPreview();

      var state = container.read(newVerificationViewModelProvider).requireValue;
      expect(state.preview?.serviceRevision, 7);
      expect(state.canStart, isFalse);
      expect(repository.lastTarget?.processVersionId, 'version-1');
      expect(repository.ticketQueries, ['']);

      vm.toggleTicket(_group, '204');
      state = container.read(newVerificationViewModelProvider).requireValue;
      expect(state.canStart, isTrue);
      vm.toggleTicket(_group, '205');
      state = container.read(newVerificationViewModelProvider).requireValue;
      expect(state.selectedTickets[_group.id], {'205'});

      final runId = await vm.start();
      expect(runId, 'run-1');
      expect(repository.startedRevision, 7);
      expect(repository.startedSelections[_group.id], {'205'});
    },
  );

  test('changing scope discards preview and selected tickets', () async {
    final repository = _FakeRepository();
    final container = ProviderContainer(
      overrides: [verificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      newVerificationViewModelProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(newVerificationViewModelProvider.future);
    final vm = container.read(newVerificationViewModelProvider.notifier);
    await vm.selectService('service-1');
    vm.selectProcess('version-1');
    await vm.loadPreview();
    vm.toggleTicket(_group, '204');

    vm.selectScope(VerificationScope.macroActivity);
    final state = container.read(newVerificationViewModelProvider).requireValue;
    expect(state.preview, isNull);
    expect(state.selectedTickets, isEmpty);
    expect(state.canPreview, isFalse);
    vm.selectMacroActivity('macro-1');
    expect(
      container.read(newVerificationViewModelProvider).requireValue.canPreview,
      isTrue,
    );
  });

  test(
    'a second start call is ignored while the first request is pending',
    () async {
      final repository = _FakeRepository(startCompleter: Completer<String>());
      final container = ProviderContainer(
        overrides: [
          verificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        newVerificationViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(newVerificationViewModelProvider.future);
      final vm = container.read(newVerificationViewModelProvider.notifier);
      await vm.selectService('service-1');
      vm.selectProcess('version-1');
      await vm.loadPreview();
      vm.toggleTicket(_group, '204');

      final first = vm.start();
      final second = vm.start();
      expect(await second, isNull);
      expect(repository.startCalls, 1);
      repository.startCompleter!.complete('run-1');
      expect(await first, 'run-1');
    },
  );
}

final _group = TicketSelectionGroup(
  id: 'macro-1:ticket-input',
  label: 'Ticket recibido',
  cardinality: 'ONE',
  required: true,
  relatedExpectationIds: const ['expectation-1'],
);

final _service = Service(
  id: 'service-1',
  name: 'Servicio de prueba',
  client: 'Cliente',
  serviceType: ServiceType.supportErp,
  status: ServiceStatus.active,
  revision: 7,
  processes: const [],
  sources: const ServiceSource(),
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _FakeRepository implements VerificationRepository {
  _FakeRepository({this.startCompleter});
  final Completer<String>? startCompleter;
  VerificationTarget? lastTarget;
  int? startedRevision;
  Map<String, Set<String>> startedSelections = {};
  int startCalls = 0;
  final List<String> ticketQueries = [];

  @override
  Future<VerificationRun> getVerification(String runId) async =>
      throw UnimplementedError();

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) async => PagedResult(
    items: [_service],
    page: const PageInfo(page: 0, size: 100, totalElements: 1, totalPages: 1),
  );

  @override
  Future<PagedResult<VerificationRunSummary>> listRuns({
    required int page,
    required int size,
    String? serviceId,
  }) async => const PagedResult(
    items: [],
    page: PageInfo(page: 0, size: 20, totalElements: 0, totalPages: 0),
  );

  @override
  Future<List<VerifiableProcess>> verifiableProcesses(
    String serviceId,
  ) async => [
    const VerifiableProcess(
      id: 'version-1',
      name: 'Start Up',
      officialVersion: '2.0',
      macroActivities: [
        VerifiableMacroActivity(id: 'macro-1', name: 'Organización interna'),
      ],
    ),
  ];

  @override
  Future<VerificationPreview> preview(VerificationTarget target) async {
    lastTarget = target;
    return VerificationPreview(
      serviceId: target.serviceId,
      serviceRevision: 7,
      processVersionId: target.processVersionId,
      scope: target.scope,
      macroActivityId: target.macroActivityId,
      expectations: const [],
      ticketSelectionGroups: [_group],
    );
  }

  @override
  Future<TicketPage> searchTickets(
    String serviceId, {
    required String query,
    required int page,
  }) async {
    ticketQueries.add(query);
    return const TicketPage(
      items: [
        TicketSummary(id: '204', subject: 'Primer ticket', status: 'Abierto'),
        TicketSummary(id: '205', subject: 'Segundo ticket', status: 'Abierto'),
      ],
      page: PageInfo(page: 0, size: 20, totalElements: 2, totalPages: 1),
    );
  }

  @override
  Future<String> start(
    VerificationPreview preview,
    String? note,
    Map<String, Set<String>> selections,
  ) async {
    startCalls++;
    startedRevision = preview.serviceRevision;
    startedSelections = selections;
    return startCompleter?.future ?? 'run-1';
  }
}
