import '../phon/cs_g2p.dart';
import '../phon/phonemes.dart';
import 'keys.dart';

/// Language-specific definition of syllables, keys and rhyme classes.
abstract class RhymeProfile {
  String get id;

  /// Converts a written word to phonemes.
  String phonemize(String word, {bool beforePause = true});

  bool isNucleus(String phon, int i);

  String fold(String key);

  /// Null when the word has no nucleus (e.g. prepositions `k s v z`).
  RhymeKeys? keysFor(String phon);

  /// Classifies two line ends given as phoneme strings.
  RhymeLevel classify(String a, String b);

  /// Indexes of nuclei in [phon].
  List<int> nuclei(String phon) => [
    for (var i = 0; i < phon.length; i++)
      if (isNucleus(phon, i)) i,
  ];

  /// Length of the common phoneme suffix ("richness" inside a level).
  static int commonSuffix(String a, String b) {
    var n = 0;
    while (n < a.length &&
        n < b.length &&
        a.codeUnitAt(a.length - 1 - n) == b.codeUnitAt(b.length - 1 - n)) {
      n++;
    }
    return n;
  }
}

/// Czech profile `cs`.
class CzechProfile extends RhymeProfile {
  final CzechG2P g2p;

  CzechProfile({CzechG2P? g2p}) : g2p = g2p ?? const CzechG2P();

  @override
  String get id => 'cs';

  @override
  String phonemize(String word, {bool beforePause = true}) =>
      g2p.toPhonemes(word, beforePause: beforePause);

  @override
  bool isNucleus(String p, int i) {
    final c = p[i];
    if (isCzVowel(c)) return true;
    if (i == 0 || isCzVowel(p[i - 1])) return false;
    final last = i + 1 == p.length;
    if (c == 'r' || c == 'l') return last || !isCzVowel(p[i + 1]);
    if (c == 'm') return last;
    return false;
  }

  @override
  String fold(String key) => foldCz(key);

  @override
  RhymeKeys? keysFor(String p) {
    final n = nuclei(p);
    if (n.isEmpty) return null;
    final last = n.last;
    final open = last == p.length - 1;
    final f1 = (open && last > 0 && !n.contains(last - 1))
        ? p.substring(last - 1)
        : p.substring(last);
    final hasTwo = n.length >= 2;
    return RhymeKeys(
      f1: f1,
      f2: hasTwo ? p.substring(n[n.length - 2]) : null,
      as2: hasTwo ? fold(p[n[n.length - 2]] + p[last]) : null,
      open: open,
      syl: n.length,
    );
  }

  @override
  RhymeLevel classify(String a, String b) =>
      classifyKeys(a, keysFor(a), b, keysFor(b));

  /// Classification with precomputed keys (avoids recomputing in hot loops).
  RhymeLevel classifyKeys(String pa, RhymeKeys? ka, String pb, RhymeKeys? kb) {
    if (pa == pb) return RhymeLevel.identical;
    if (ka == null || kb == null) return RhymeLevel.none;
    if (ka.f2 != null && ka.f2 == kb.f2) return RhymeLevel.full;
    if (ka.f1 == kb.f1) {
      if (!ka.open) return RhymeLevel.masc;
      return ka.syl == 1 && kb.syl == 1 ? RhymeLevel.masc : RhymeLevel.weak;
    }
    if (ka.f2 != null && kb.f2 != null && fold(ka.f2!) == fold(kb.f2!)) {
      return RhymeLevel.looseFull;
    }
    if (fold(ka.f1) == fold(kb.f1) && ka.open == kb.open) {
      return RhymeLevel.loose;
    }
    if (ka.as2 != null && ka.as2 == kb.as2) return RhymeLevel.assonance;
    return RhymeLevel.none;
  }
}
