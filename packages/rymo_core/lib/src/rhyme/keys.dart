/// Rhyme keys of one word end (plan §6.3).
class RhymeKeys {
  /// Minimal key: closed → from last nucleus; open → support consonant + nucleus.
  final String f1;

  /// Two-syllable key from the penultimate nucleus, or null.
  final String? f2;

  /// Assonance key: folded vowels of the last two nuclei, or null.
  final String? as2;

  /// No consonant after the last nucleus.
  final bool open;

  /// Number of nuclei.
  final int syl;

  const RhymeKeys({
    required this.f1,
    required this.f2,
    required this.as2,
    required this.open,
    required this.syl,
  });

  @override
  String toString() =>
      'RhymeKeys(f1: $f1, f2: $f2, as2: $as2, open: $open, syl: $syl)';
}

/// Strength of a rhyme between two line ends, strongest first.
enum RhymeLevel {
  identical,
  full,
  masc,
  weak,
  looseFull,
  loose,
  assonance,
  none;

  /// True when this level is at least as strong as [other].
  bool atLeast(RhymeLevel other) => index <= other.index;
}
