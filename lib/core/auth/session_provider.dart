import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';
import '../../features/auth/model/auth_models.dart';

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  void setSession(Session? session) => state = session;

  void setSessionFromResponse(TokenResponse response) {
    state = Session(
      user: response.user,
      accessToken: response.accessToken,
      expiresAt: response.expiresAt,
    );
  }

  void clearSession() => state = null;
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);
