/// Converts Czech XSAMPA transcriptions of the Corpus of Czech Verse into the
/// one-character phoneme alphabet of `rymo_core` (golden tests only).
class XSampa {
  static const _table = <String, String>{
    'o_u': 'W',
    'a_u': 'Y',
    'E_u': 'Q',
    'e_u': 'Q',
    't_s': 'c',
    't_S': 'C',
    'd_z': '3',
    'd_Z': '4',
    'J\\': 'D',
    'P\\': 'R',
    'Q\\': 'R',
    'h\\': 'h',
    'r=': 'r',
    'l=': 'l',
    'm=': 'm',
    'a:': 'A',
    'E:': 'E',
    'e:': 'E',
    'i:': 'I',
    'o:': 'O',
    'u:': 'U',
    'a': 'a',
    'E': 'e',
    'e': 'e',
    'I': 'i',
    'i': 'i',
    'o': 'o',
    'u': 'u',
    'c': 'T',
    'J': 'N',
    'N': 'n',
    'F': 'm',
    'G': 'h',
    '?': '',
    'p': 'p',
    'b': 'b',
    't': 't',
    'd': 'd',
    'k': 'k',
    'g': 'g',
    'f': 'f',
    'v': 'v',
    's': 's',
    'z': 'z',
    'S': 'S',
    'Z': 'Z',
    'x': 'x',
    'h': 'h',
    'm': 'm',
    'n': 'n',
    'l': 'l',
    'r': 'r',
    'j': 'j',
  };

  /// Returns null when the transcription contains an unknown symbol.
  static String? toPhon(String xs, [Set<String>? unknown]) {
    final b = StringBuffer();
    var i = 0;
    outer:
    while (i < xs.length) {
      for (final len in const [3, 2, 1]) {
        if (i + len > xs.length) continue;
        final t = _table[xs.substring(i, i + len)];
        if (t != null) {
          b.write(t);
          i += len;
          continue outer;
        }
      }
      unknown?.add(xs[i]);
      return null;
    }
    return b.toString();
  }
}
