import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  void setSession(Session? session) => state = session;
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);
