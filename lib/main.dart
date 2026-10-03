import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/auth/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionStore sessionStore;
  try {
    sessionStore = PreferencesSessionStore(await SharedPreferences.getInstance());
  } catch (_) {
    sessionStore = MemorySessionStore();
  }
  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(sessionStore),
      ],
      child: const App(),
    ),
  );
}
