import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/model/auth_models.dart';
import 'session.dart';

abstract interface class SessionStore {
  Session? read();
  void write(Session session);
  void clear();
}

class MemorySessionStore implements SessionStore {
  Session? _session;

  @override
  Session? read() => _session;

  @override
  void write(Session session) => _session = session;

  @override
  void clear() => _session = null;
}

class PreferencesSessionStore implements SessionStore {
  PreferencesSessionStore(this._preferences);

  final SharedPreferences _preferences;
  static const _key = 'tema.session.v1';

  @override
  Session? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final user = User.fromJson(json['user'] as Map<String, dynamic>);
      final session = Session(
        accessToken: json['accessToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: user,
      );
      if (session.isValid) return session;
    } catch (_) {
      // Invalid or outdated saved data must never authenticate the app.
    }
    clear();
    return null;
  }

  @override
  void write(Session session) {
    final user = session.user;
    if (user == null ||
        session.accessToken == null ||
        session.expiresAt == null) {
      clear();
      return;
    }
    _preferences.setString(
      _key,
      jsonEncode({
        'accessToken': session.accessToken,
        'expiresAt': session.expiresAt!.toIso8601String(),
        'user': {
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'role': user.role.value,
          'active': user.active,
        },
      }),
    );
  }

  @override
  void clear() => _preferences.remove(_key);
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => MemorySessionStore(),
);
