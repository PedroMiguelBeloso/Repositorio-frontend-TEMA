import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/auth/view/login_page.dart';

void main() {
  testWidgets('login fields stay readable on a wide screen', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginPage()),
    ));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(TextFormField).first).width,
        lessThanOrEqualTo(420));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login fits on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
