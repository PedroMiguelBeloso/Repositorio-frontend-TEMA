import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_provider.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository.dart';
import 'package:proyecto_tema_frontend/features/services/data/service_repository_provider.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/services/view/service_detail_page.dart';
import 'package:proyecto_tema_frontend/features/services/view/service_form_page.dart';

void main() {
  testWidgets(
    'reader can view service detail without the edit action',
    (tester) async {
      final repository = _FakeServiceRepository(_service);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceRepositoryProvider.overrideWithValue(repository),
            sessionProvider.overrideWith(
              () => _TestSessionNotifier(
                const Session(role: UserRole.reader),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ServiceDetailPage(serviceId: 'service-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Detalle del servicio'), findsOneWidget);
      expect(find.text('Servicio Norte'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    },
  );

  testWidgets(
    'service form exposes exactly the five configured service types',
    (tester) async {
      final repository = _FakeServiceRepository(_service);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: ServiceFormPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<ServiceType>));
      await tester.pumpAndSettle();

      expect(find.text('Soporte Ariba'), findsOneWidget);
      expect(find.text('Soporte ERP'), findsOneWidget);
      expect(find.text('Software Factory'), findsOneWidget);
      expect(find.text('Proyecto SAP Ariba'), findsOneWidget);
      expect(find.text('Proyecto ERP'), findsOneWidget);
      expect(find.text('Tipo no reconocido'), findsNothing);
    },
  );
}

final _service = Service(
  id: 'service-1',
  name: 'Servicio Norte',
  client: 'Cliente Norte',
  serviceType: ServiceType.supportAriba,
  status: ServiceStatus.active,
  revision: 4,
  processes: const [],
  sources: const ServiceSource(
    driveFolderId: 'drive-1',
    driveFolderName: '/Servicios/Norte',
    redmineProjectId: 'redmine-1',
    redmineProjectName: 'Cliente Norte',
  ),
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

class _FakeServiceRepository implements ServiceRepository {
  _FakeServiceRepository(this.service);

  final Service service;

  @override
  Future<PagedResult<Service>> listServices({
    required int page,
    required int size,
  }) async {
    return PagedResult(
      items: [service],
      page: const PageInfo(
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<Service> getService(String id) async => service;

  @override
  Future<Service> createService(ServiceInput input) async => service;

  @override
  Future<Service> updateService(String id, ServiceInput input) async => service;

  @override
  Future<List<AssignableProcessGroup>> getAssignableProcessVersions() async =>
      const [];

  @override
  Future<PagedResult<DriveFolderOption>> getDriveFolders({
    String query = '',
    required int page,
    required int size,
  }) async {
    return const PagedResult(
      items: [],
      page: PageInfo(
        page: 0,
        size: 10,
        totalElements: 0,
        totalPages: 0,
      ),
    );
  }

  @override
  Future<PagedResult<RedmineProjectOption>> getRedmineProjects({
    required int page,
    required int size,
  }) async {
    return const PagedResult(
      items: [],
      page: PageInfo(
        page: 0,
        size: 10,
        totalElements: 0,
        totalPages: 0,
      ),
    );
  }
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this.initialSession);

  final Session? initialSession;

  @override
  Session? build() => initialSession;
}
