import 'phonemes.dart';

/// Rule-based Czech grapheme-to-phoneme conversion (plan §6.2).
///
/// Must stay in sync with `Prompts/cs_g2p_prototype.py`; the prototype wins
/// on any disagreement with the plan text.
class CzechG2P {
  /// Exceptions `form -> phon` (pack table `exc`); they take precedence.
  final Map<String, String> exceptions;

  const CzechG2P({this.exceptions = const {}});

  static const _letters = {
    'á': 'A',
    'é': 'E',
    'í': 'I',
    'ó': 'O',
    'ú': 'U',
    'ů': 'U',
    'y': 'i',
    'ý': 'I',
    'š': 'S',
    'ž': 'Z',
    'č': 'C',
    'ř': 'R',
    'ď': 'D',
    'ť': 'T',
    'ň': 'N',
  };
  static const _soft = {'d': 'D', 't': 'T', 'n': 'N'};
  static const _vowelLetters = 'aáeéěíoóuúů';
  static final _nonLetter = RegExp(r'[^\p{L}]', unicode: true);

  /// Lowercase and strip everything except letters.
  static String normalize(String word) =>
      word.toLowerCase().replaceAll(_nonLetter, '');

  String toPhonemes(String word, {bool beforePause = true}) {
    final w = normalize(word);
    if (w.isEmpty) return '';
    final exc = exceptions[w];
    if (exc != null) return exc;

    final out = <String>[];
    var i = 0;
    while (i < w.length) {
      final c = w[i];
      final two = i + 1 < w.length ? w.substring(i, i + 2) : '';
      switch (two) {
        case 'ch':
          out.add('x');
          i += 2;
          continue;
        case 'dž':
          out.add('4');
          i += 2;
          continue;
        case 'dz':
          out.add('3');
          i += 2;
          continue;
        case 'ou':
          out.add('W');
          i += 2;
          continue;
        case 'au':
          out.add('Y');
          i += 2;
          continue;
        case 'eu':
          out.add('Q');
          i += 2;
          continue;
      }
      switch (c) {
        case 'q':
          out.addAll(['k', 'v']);
          i++;
          continue;
        case 'w':
          out.add('v');
          i++;
          continue;
        case 'x':
          out.addAll(['k', 's']);
          i++;
          continue;
        case 'ě':
          final p = out.isEmpty ? '' : out.last;
          if (_soft.containsKey(p)) {
            out[out.length - 1] = _soft[p]!;
            out.add('e');
          } else if (p.isNotEmpty && 'bpvf'.contains(p)) {
            out.addAll(['j', 'e']);
          } else if (p == 'm') {
            out.addAll(['N', 'e']);
          } else {
            out.add('e');
          }
          i++;
          continue;
      }
      // Written i/í soften d t n; y/ý never do.
      if ((c == 'i' || c == 'í') && out.isNotEmpty) {
        final s = _soft[out.last];
        if (s != null) out[out.length - 1] = s;
      }
      out.add(_letters[c] ?? c);
      // Hiatus glide: consonant + i/í + vowel -> ij (melodie -> meloDije).
      if ((c == 'i' || c == 'í') &&
          out.length >= 2 &&
          !isCzVowel(out[out.length - 2]) &&
          i + 1 < w.length &&
          _vowelLetters.contains(w[i + 1])) {
        out.add('j');
      }
      i++;
    }

    // Geminate consonants collapse.
    final ph = <String>[];
    for (final p in out) {
      if (ph.isNotEmpty && ph.last == p && !isCzVowel(p)) continue;
      ph.add(p);
    }
    // sh -> sx
    for (var k = 0; k < ph.length - 1; k++) {
      if (ph[k] == 's' && ph[k + 1] == 'h') ph[k + 1] = 'x';
    }
    // Final devoicing before a pause.
    if (beforePause && ph.isNotEmpty) {
      final v = czVoicedToVoiceless[ph.last];
      if (v != null) ph[ph.length - 1] = v;
    }
    // Regressive voicing assimilation, right to left; v adapts but never
    // triggers voicing.
    for (var k = ph.length - 2; k >= 0; k--) {
      final a = ph[k], b = ph[k + 1];
      if (!isObstruent(a) || !isObstruent(b)) continue;
      if (czVoicelessToVoiced.containsKey(b)) {
        final v = czVoicedToVoiceless[a];
        if (v != null) ph[k] = v;
      } else if (czVoicedToVoiceless.containsKey(b) && b != 'v') {
        final v = czVoicelessToVoiced[a];
        if (v != null) ph[k] = v;
      }
    }
    return ph.join();
  }
}
