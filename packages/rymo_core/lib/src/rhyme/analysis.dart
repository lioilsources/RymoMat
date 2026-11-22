import 'keys.dart';
import 'profile.dart';

final _wordRe = RegExp(r'[\p{L}]+', unicode: true);

/// The last word of a line with its phonemes and keys.
class LineEnd {
  final String line;

  /// Last word as written (lowercase), empty for a line without words.
  final String word;

  /// Phonemes of [word] before a pause.
  final String phon;

  /// Null when the word has no nucleus.
  final RhymeKeys? keys;

  /// Syllables of the whole line.
  final int syl;

  const LineEnd({
    required this.line,
    required this.word,
    required this.phon,
    required this.keys,
    required this.syl,
  });

  bool get isEmpty => word.isEmpty;
}

/// Computes line ends with a profile; no database access.
LineEnd lineEndOf(RhymeProfile profile, String line) {
  final words = _wordRe.allMatches(line).map((m) => m.group(0)!).toList();
  if (words.isEmpty) {
    return LineEnd(line: line, word: '', phon: '', keys: null, syl: 0);
  }
  var syl = 0;
  for (var i = 0; i < words.length - 1; i++) {
    syl += profile
        .nuclei(profile.phonemize(words[i], beforePause: false))
        .length;
  }
  final word = words.last.toLowerCase();
  final phon = profile.phonemize(word);
  final keys = profile.keysFor(phon);
  syl += keys?.syl ?? 0;
  return LineEnd(line: line, word: word, phon: phon, keys: keys, syl: syl);
}

class LineInfo {
  /// Index of the line in the text (split by `\n`).
  final int line;

  /// Stanza index; null for blank lines.
  final int? stanza;
  final int syl;
  final String endWord;

  /// Rhyme group shared by rhyming lines; null when the line has no partner.
  final int? group;

  /// Scheme letter inside the stanza (`A`, `B`, …); null for blank lines.
  final String? letter;

  const LineInfo({
    required this.line,
    required this.stanza,
    required this.syl,
    required this.endWord,
    required this.group,
    required this.letter,
  });
}

class PoemAnalysis {
  final List<LineInfo> lines;
  const PoemAnalysis(this.lines);
}

/// Rhyme groups via union-find over line pairs within [window] verses.
PoemAnalysis analyzePoem(
  RhymeProfile profile,
  String text, {
  int window = 6,
  bool assonance = false,
}) {
  final raw = text.split('\n');
  final minLevel = assonance ? RhymeLevel.assonance : RhymeLevel.loose;
  final ends = <LineEnd?>[];
  final stanzaOf = <int?>[];
  var stanza = -1;
  var prevBlank = true;
  for (final l in raw) {
    if (l.trim().isEmpty) {
      ends.add(null);
      stanzaOf.add(null);
      prevBlank = true;
      continue;
    }
    if (prevBlank) stanza++;
    prevBlank = false;
    ends.add(lineEndOf(profile, l));
    stanzaOf.add(stanza);
  }

  // Verse indexes (non-blank lines) for the window distance.
  final verses = [
    for (var i = 0; i < ends.length; i++)
      if (ends[i] != null) i,
  ];
  final parent = List<int>.generate(ends.length, (i) => i);
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  final partnered = <int>{};
  for (var vi = 0; vi < verses.length; vi++) {
    final a = ends[verses[vi]]!;
    if (a.keys == null) continue;
    for (var vj = vi + 1; vj < verses.length && vj - vi <= window; vj++) {
      final b = ends[verses[vj]]!;
      if (b.keys == null) continue;
      final lvl = profile is CzechProfile
          ? profile.classifyKeys(a.phon, a.keys, b.phon, b.keys)
          : profile.classify(a.phon, b.phon);
      if (lvl == RhymeLevel.none || !lvl.atLeast(minLevel)) continue;
      parent[find(verses[vi])] = find(verses[vj]);
      partnered
        ..add(verses[vi])
        ..add(verses[vj]);
    }
  }

  final groupIds = <int, int>{};
  final letters = <int, Map<int, String>>{};
  final out = <LineInfo>[];
  for (var i = 0; i < ends.length; i++) {
    final e = ends[i];
    if (e == null) {
      out.add(
        LineInfo(
          line: i,
          stanza: null,
          syl: 0,
          endWord: '',
          group: null,
          letter: null,
        ),
      );
      continue;
    }
    final root = find(i);
    final group = partnered.contains(i)
        ? groupIds.putIfAbsent(root, () => groupIds.length)
        : null;
    final st = stanzaOf[i]!;
    final perStanza = letters.putIfAbsent(st, () => {});
    final key = partnered.contains(i) ? root : -1 - i;
    final letter = perStanza.putIfAbsent(
      key,
      () => String.fromCharCode(65 + perStanza.length % 26),
    );
    out.add(
      LineInfo(
        line: i,
        stanza: st,
        syl: e.syl,
        endWord: e.word,
        group: group,
        letter: letter,
      ),
    );
  }
  return PoemAnalysis(out);
}
