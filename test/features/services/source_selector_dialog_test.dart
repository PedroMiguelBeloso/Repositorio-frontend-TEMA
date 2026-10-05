import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/services/model/service_models.dart';
import 'package:proyecto_tema_frontend/features/services/widgets/drive_folder_selector.dart';
import 'package:proyecto_tema_frontend/features/services/widgets/redmine_project_selector.dart';

void main() {
  testWidgets('Drive selector renders two folders and returns the chosen one', (
    tester,
  ) async {
    DriveFolderOption? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriveFolderSelector(
            loadPage: ({required query, required page}) async =>
                const PagedResult(
                  items: [
                    DriveFolderOption(
                      id: 'root',
                      name: 'Prueba Tema-Iso',
                      path: '/Prueba Tema-Iso',
                    ),
                    DriveFolderOption(
                      id: 'child',
                      name: 'Carpeta Prueba',
                      path: '/Prueba Tema-Iso/Carpeta Prueba',
                      parentId: 'root',
                    ),
                  ],
                  page: PageInfo(
                    page: 0,
                    size: 20,
                    totalElements: 2,
                    totalPages: 1,
                  ),
                ),
            onSelected: (folder) => selected = folder,
            onClear: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seleccionar carpeta'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Prueba Tema-Iso'), findsOneWidget);
    expect(find.text('Carpeta Prueba'), findsOneWidget);

    await tester.tap(find.text('Carpeta Prueba'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(selected?.id, 'child');
  });

  testWidgets('Redmine selector also lays out on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RedmineProjectSelector(
            loadPage: ({required page}) async => const PagedResult(
              items: [RedmineProjectOption(id: 'project-1', name: 'Proyecto')],
              page: PageInfo(
                page: 0,
                size: 20,
                totalElements: 1,
                totalPages: 1,
              ),
            ),
            onSelected: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seleccionar proyecto'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Proyecto'), findsOneWidget);
  });
}
