import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';
import 'session_store.dart';
import '../../features/auth/model/auth_models.dart';

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => ref.read(sessionStoreProvider).read();

  void setSession(Session? session) {
    if (session == null) {
      clearSession();
    } else {
      ref.read(sessionStoreProvider).write(session);
      state = session;
    }
  }

  void setSessionFromResponse(TokenResponse response) {
    setSession(
      Session(
        user: response.user,
        accessToken: response.accessToken,
        expiresAt: response.expiresAt,
      ),
    );
  }

  void clearSession() {
    ref.read(sessionStoreProvider).clear();
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);
