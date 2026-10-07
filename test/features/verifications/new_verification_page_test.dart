import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_tema_frontend/features/verifications/view/new_verification_page.dart';
import 'package:proyecto_tema_frontend/features/verifications/viewmodel/new_verification_view_model.dart';

void main() {
  testWidgets('shows loading then an understandable empty state on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completion = Completer<NewVerificationState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          newVerificationViewModelProvider.overrideWith(
            () => _PendingViewModel(completion),
          ),
        ],
        child: const MaterialApp(home: NewVerificationPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completion.complete(const NewVerificationState(services: []));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Todavía no hay servicios. Creá uno y asignale una versión publicada antes de verificar.',
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _PendingViewModel extends NewVerificationViewModel {
  _PendingViewModel(this.completion);
  final Completer<NewVerificationState> completion;
  @override
  Future<NewVerificationState> build() => completion.future;
}
