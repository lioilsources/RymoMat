import 'package:rymo_core/rymo_core.dart';

/// What the editor needs from the engine; widget tests use a fake.
abstract class RhymeSource {
  RhymeProfile get profile;
  LineEnd lineEnd(String line);
  Future<List<Suggestion>> suggest(SuggestQuery q);
  Future<List<Citation>> citations(String wordA, String wordB);

  /// Rhyme level of two line ends (no database access).
  RhymeLevel classify(LineEnd a, LineEnd b) {
    final p = profile;
    if (p is CzechProfile) {
      return p.classifyKeys(a.phon, a.keys, b.phon, b.keys);
    }
    return p.classify(a.phon, b.phon);
  }
}

/// [RhymeSource] backed by a [RhymeEngine].
class EngineRhymeSource extends RhymeSource {
  final RhymeEngine engine;
  EngineRhymeSource(this.engine);

  @override
  RhymeProfile get profile => engine.profile;

  @override
  LineEnd lineEnd(String line) => engine.lineEnd(line);

  @override
  Future<List<Suggestion>> suggest(SuggestQuery q) => engine.suggest(q);

  @override
  Future<List<Citation>> citations(String wordA, String wordB) =>
      engine.citations(wordA, wordB);
}
