import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_tema_frontend/core/auth/session.dart';
import 'package:proyecto_tema_frontend/core/auth/session_store.dart';
import 'package:proyecto_tema_frontend/features/auth/model/auth_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores a valid session and removes it on logout', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesSessionStore(preferences);
    final session = Session(
      accessToken: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: User(
        id: 'user-1',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: Role.admin,
        active: true,
      ),
    );

    store.write(session);
    expect(
      PreferencesSessionStore(preferences).read()?.accessToken,
      'test-token',
    );
    store.clear();
    expect(PreferencesSessionStore(preferences).read(), isNull);
  });

  test('does not restore an expired session', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesSessionStore(preferences);
    store.write(
      Session(
        accessToken: 'expired-token',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        user: User(
          id: 'user-2',
          email: 'reader@example.com',
          displayName: 'Reader',
          role: Role.reader,
          active: true,
        ),
      ),
    );
    expect(store.read(), isNull);
  });
}
