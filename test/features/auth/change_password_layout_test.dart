import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/app/theme/app_theme.dart';
import 'package:proyecto_tema_frontend/features/auth/view/change_password_page.dart';

void main() {
  testWidgets('password form stays readable on a wide screen', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cambiar mi contraseña'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextFormField).first).width,
      lessThanOrEqualTo(472),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('password form fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: appTheme, home: const ChangePasswordPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cambiar mi contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
