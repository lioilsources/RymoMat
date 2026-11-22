/// Czech phoneme inventory. Every phoneme is one ASCII character.
///
/// Vowels: short `a e i o u`, long `A E I O U`, diphthongs `W`=ou, `Y`=au,
/// `Q`=eu. Consonants: `p b t d T D k g f v s z S Z x h c C 3 4 m n N l r R j`.
library;

const String czVowels = 'aeiouAEIOUWYQ';

/// Voiced -> voiceless obstruent pairs.
const Map<String, String> czVoicedToVoiceless = {
  'b': 'p',
  'd': 't',
  'D': 'T',
  'g': 'k',
  'v': 'f',
  'z': 's',
  'Z': 'S',
  'h': 'x',
  '3': 'c',
  '4': 'C',
};

final Map<String, String> czVoicelessToVoiced = {
  for (final e in czVoicedToVoiceless.entries) e.value: e.key,
};

bool isCzVowel(String p) => czVowels.contains(p);

bool isObstruent(String p) =>
    czVoicedToVoiceless.containsKey(p) || czVoicelessToVoiced.containsKey(p);

/// Long vowel -> short vowel ("loose" match).
String foldCz(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    b.write(switch (c) {
      'A' => 'a',
      'E' => 'e',
      'I' => 'i',
      'O' => 'o',
      'U' => 'u',
      _ => c,
    });
  }
  return b.toString();
}
