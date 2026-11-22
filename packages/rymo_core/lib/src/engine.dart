import 'dart:async';
import 'dart:isolate';

import 'phon/cs_g2p.dart';
import 'rhyme/analysis.dart';
import 'rhyme/profile.dart';
import 'suggest.dart';

/// Public engine API (plan §6.4). The pack lives on a long-lived isolate;
/// [lineEnd] and [analyze] run synchronously without touching the database.
class RhymeEngine {
  final CzechProfile profile;
  final SendPort _commands;
  final ReceivePort _responses;
  final Isolate _isolate;
  final Map<int, Completer<Object?>> _pending = {};
  int _seq = 0;

  RhymeEngine._(this.profile, this._commands, this._responses, this._isolate) {
    _responses.listen((msg) {
      final (id, result) = msg as (int, Object?);
      final c = _pending.remove(id);
      if (result is _Failure) {
        c?.completeError(StateError(result.message));
      } else {
        c?.complete(result);
      }
    });
  }

  static Future<RhymeEngine> open(String packPath) async {
    final init = ReceivePort();
    final isolate = await Isolate.spawn(_main, (init.sendPort, packPath));
    final first = await init.first;
    if (first is _Failure) {
      isolate.kill();
      throw StateError(first.message);
    }
    final (SendPort commands, Map<String, String> exc) =
        first as (SendPort, Map<String, String>);
    final responses = ReceivePort();
    commands.send(responses.sendPort);
    return RhymeEngine._(
      CzechProfile(g2p: CzechG2P(exceptions: exc)),
      commands,
      responses,
      isolate,
    );
  }

  LineEnd lineEnd(String line) => lineEndOf(profile, line);

  PoemAnalysis analyze(String text, {int window = 6, bool assonance = false}) =>
      analyzePoem(profile, text, window: window, assonance: assonance);

  Future<List<Suggestion>> suggest(SuggestQuery q) async =>
      (await _call(q)) as List<Suggestion>;

  Future<List<Citation>> citations(String wordA, String wordB) async =>
      (await _call((wordA, wordB))) as List<Citation>;

  Future<Object?> _call(Object request) {
    final id = _seq++;
    final c = Completer<Object?>();
    _pending[id] = c;
    _commands.send((id, request));
    return c.future;
  }

  void close() {
    _commands.send(null);
    _responses.close();
    _isolate.kill(priority: Isolate.beforeNextEvent);
    for (final c in _pending.values) {
      c.completeError(StateError('engine closed'));
    }
    _pending.clear();
  }

  static Future<void> _main((SendPort, String) args) async {
    final (init, path) = args;
    final SuggestCore core;
    try {
      core = SuggestCore.open(path);
    } catch (e) {
      init.send(_Failure('$e'));
      return;
    }
    final commands = ReceivePort();
    init.send((commands.sendPort, core.profile.g2p.exceptions));
    SendPort? out;
    await for (final msg in commands) {
      if (msg is SendPort) {
        out = msg;
        continue;
      }
      if (msg == null) break;
      final (id, req) = msg as (int, Object);
      try {
        final Object result = switch (req) {
          SuggestQuery q => core.suggest(q),
          (String a, String b) => core.citations(a, b),
          _ => _Failure('unknown request'),
        };
        out!.send((id, result));
      } catch (e) {
        out!.send((id, _Failure('$e')));
      }
    }
    core.close();
    commands.close();
  }
}

class _Failure {
  final String message;
  const _Failure(this.message);
}
