import 'pack/pack_reader.dart';
import 'pack/schema.dart';
import 'phon/cs_g2p.dart';
import 'rhyme/analysis.dart';
import 'rhyme/keys.dart';
import 'rhyme/profile.dart';

class SuggestQuery {
  /// Target line (its last word is rhymed) or a single word.
  final String target;

  /// Written prefix of the word being typed; empty = no filter.
  final String prefix;
  final RhymeLevel minLevel;
  final int? syllables;
  final int limit;

  /// Words already at line ends in this poem or notebook.
  final Set<String> usedWords;
  final bool assonance;

  const SuggestQuery(
    this.target, {
    this.prefix = '',
    this.minLevel = RhymeLevel.loose,
    this.syllables,
    this.limit = 40,
    this.usedWords = const {},
    this.assonance = false,
  });
}

class Suggestion {
  final String word;
  final RhymeLevel level;

  /// Length of the common phoneme suffix with the target.
  final int common;

  /// Times the pair was rhymed in the corpus (0 = not attested).
  final int attested;
  final int freq;
  final bool grammatical;
  final bool used;

  /// True when [SuggestQuery.prefix] matched nothing and was ignored.
  final bool prefixIgnored;

  const Suggestion({
    required this.word,
    required this.level,
    required this.common,
    required this.attested,
    required this.freq,
    required this.grammatical,
    required this.used,
    this.prefixIgnored = false,
  });

  Suggestion _withPrefixIgnored() => Suggestion(
    word: word,
    level: level,
    common: common,
    attested: attested,
    freq: freq,
    grammatical: grammatical,
    used: used,
    prefixIgnored: true,
  );

  @override
  String toString() =>
      '$word(${level.name}${attested > 0 ? ' x$attested' : ''}'
      '${grammatical ? ' gram' : ''})';
}

class Citation {
  final String lineA, lineB, author, work;
  final int? year;
  const Citation(this.lineA, this.lineB, this.author, this.work, this.year);
}

/// Synchronous suggestion core over an open pack (plan §6.5). Runs inside
/// the engine isolate; usable directly by CLI tools and benchmarks.
class SuggestCore {
  final PackReader pack;
  final CzechProfile profile;

  SuggestCore(this.pack)
    : profile = CzechProfile(g2p: CzechG2P(exceptions: pack.exceptions()));

  static SuggestCore open(String path) => SuggestCore(PackReader.open(path));

  List<Suggestion> suggest(SuggestQuery q) {
    final end = lineEndOf(profile, q.target);
    final tk = end.keys;
    if (tk == null) return const [];
    final tRow = pack.word(end.word);
    final tTail = _tail(end.word);

    final seen = <String>{end.word};
    final layers = <List<Suggestion>>[];

    Suggestion? make(WordRow w, int attested) {
      if (!seen.add(w.form)) return null;
      if (tRow?.lemma != null && w.lemma == tRow!.lemma) return null;
      if (q.syllables != null && w.syl != q.syllables) return null;
      final wk = profile.keysFor(w.phon);
      final lvl = profile.classifyKeys(end.phon, tk, w.phon, wk);
      if (lvl == RhymeLevel.none || !lvl.atLeast(q.minLevel)) return null;
      if (lvl == RhymeLevel.assonance && !q.assonance && attested == 0) {
        return null;
      }
      final gram =
          tRow?.gram != null &&
          tRow!.gram == w.gram &&
          tTail.length == 3 &&
          _tail(w.form) == tTail;
      return Suggestion(
        word: w.form,
        level: lvl,
        common: RhymeProfile.commonSuffix(end.phon, w.phon),
        attested: attested,
        freq: w.freq,
        grammatical: gram,
        used: q.usedWords.contains(w.form),
      );
    }

    void layer(Iterable<(WordRow, int)> rows) {
      final l = <Suggestion>[];
      for (final (w, n) in rows) {
        final s = make(w, n);
        if (s != null) l.add(s);
      }
      l.sort(_cmp);
      layers.add(l);
    }

    // a) attested pairs
    if (tRow != null) layer(pack.partners(tRow.id, 40));

    final f2 = tk.f2 == null ? null : pack.fam(FamLevel.f2, tk.f2!);
    final f1 = pack.fam(FamLevel.f1, tk.f1);
    // b) full
    if (f2 != null) {
      layer(pack.wordsInFam(FamLevel.f2, f2.id, 200).map((w) => (w, 0)));
    }
    // c) masc / weak
    if (f1 != null) {
      layer(pack.wordsInFam(FamLevel.f1, f1.id, 200).map((w) => (w, 0)));
    }
    // d) looseFull, loose: other exact families with the same loose_id
    final loose = <(WordRow, int)>[];
    for (final (lvl, key) in [
      if (tk.f2 != null) (FamLevel.f2, tk.f2!),
      (FamLevel.f1, tk.f1),
    ]) {
      for (final fam in _looseFamilies(lvl, key)) {
        loose.addAll(pack.wordsInFam(lvl, fam.id, 200).map((w) => (w, 0)));
      }
    }
    // Open monosyllables with another onset (dá/má): probe `C + vowel`.
    if (tk.open && tk.syl == 1 && tk.f1.length == 2) {
      final v = profile.fold(tk.f1[1]);
      for (final c in _consonants.split('')) {
        for (final key in {c + v, ..._variants(c + v)}) {
          if (key == tk.f1) continue;
          final fam = pack.fam(FamLevel.f1, key);
          if (fam == null) continue;
          loose.addAll(
            pack.wordsInFam(FamLevel.f1, fam.id, 60).map((w) => (w, 0)),
          );
        }
      }
    }
    layer(loose);
    // e) assonance
    if (q.assonance && tk.as2 != null) {
      final fa = pack.fam(FamLevel.as2, tk.as2!);
      if (fa != null) {
        layer(pack.wordsInFam(FamLevel.as2, fa.id, 200).map((w) => (w, 0)));
      }
    }

    final all = [for (final l in layers) ...l];
    if (q.prefix.isNotEmpty) {
      final p = q.prefix.toLowerCase();
      final filtered = all.where((s) => s.word.startsWith(p)).toList();
      if (filtered.isNotEmpty) return filtered.take(q.limit).toList();
      return all.take(q.limit).map((s) => s._withPrefixIgnored()).toList();
    }
    return all.take(q.limit).toList();
  }

  /// Families sharing `fold(key)` other than the exact one. Works also for
  /// keys missing in the pack by probing long/short vowel variants.
  List<FamRow> _looseFamilies(int lvl, String key) {
    final exact = pack.fam(lvl, key);
    int? looseId = exact?.looseId;
    if (looseId == null) {
      for (final v in _variants(profile.fold(key))) {
        final f = pack.fam(lvl, v);
        if (f != null) {
          looseId = f.looseId;
          break;
        }
      }
    }
    if (looseId == null) return const [];
    return pack
        .famsByLoose(looseId)
        .where((f) => f.lvl == lvl && f.key != key)
        .toList();
  }

  static Iterable<String> _variants(String folded) sync* {
    const long = {'a': 'A', 'e': 'E', 'i': 'I', 'o': 'O', 'u': 'U'};
    final idx = [
      for (var i = 0; i < folded.length; i++)
        if (long.containsKey(folded[i])) i,
    ];
    if (idx.length > 4) {
      yield folded;
      return;
    }
    for (var m = 0; m < 1 << idx.length; m++) {
      final c = folded.split('');
      for (var j = 0; j < idx.length; j++) {
        if (m & (1 << j) != 0) c[idx[j]] = long[c[idx[j]]]!;
      }
      yield c.join();
    }
  }

  List<Citation> citations(String a, String b) {
    final wa = pack.word(CzechG2P.normalize(a));
    final wb = pack.word(CzechG2P.normalize(b));
    if (wa == null || wb == null) return const [];
    final swap = wa.id > wb.id;
    return [
      for (final c in pack.cites(wa.id, wb.id))
        swap
            ? Citation(c.lineB, c.lineA, c.author, c.work, c.year)
            : Citation(c.lineA, c.lineB, c.author, c.work, c.year),
    ];
  }

  static const _consonants = 'pbtdTDkgfvszSZxhcC34mnNlrRj';

  static String _tail(String w) =>
      w.length >= 3 ? w.substring(w.length - 3) : w;

  /// Inside a layer: level, then grammatical last, common suffix, frequency.
  /// (Layers a and d mix levels; the plan's order applies within a level.)
  static int _cmp(Suggestion x, Suggestion y) {
    if (x.level != y.level) return x.level.index - y.level.index;
    if (x.grammatical != y.grammatical) return x.grammatical ? 1 : -1;
    if (x.common != y.common) return y.common - x.common;
    return y.freq - x.freq;
  }

  void close() => pack.close();
}
