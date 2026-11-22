import 'dart:io';

import 'package:rymo_core/rymo_core.dart';
import 'package:test/test.dart';

List<List<String>> tsv(String name) => File('testdata/$name')
    .readAsLinesSync()
    .skip(1)
    .where((l) => l.trim().isNotEmpty)
    .map((l) => l.split('\t'))
    .toList();

void main() {
  final profile = CzechProfile();

  group('CzechG2P vectors (§6.2)', () {
    for (final r in tsv('cs_g2p.tsv')) {
      test('${r[0]} -> ${r[1]}', () {
        expect(profile.phonemize(r[0]), r[1]);
      });
    }
  });

  group('syllables', () {
    for (final r in tsv('cs_syllables.tsv')) {
      test('${r[0]} = ${r[1]}', () {
        final k = profile.keysFor(profile.phonemize(r[0]));
        expect(k?.syl ?? 0, int.parse(r[1]));
      });
    }
  });

  group('classification (§6.3)', () {
    for (final r in tsv('cs_classify.tsv')) {
      test('${r[0]} / ${r[1]} = ${r[2]}', () {
        final level = profile.classify(
          profile.phonemize(r[0]),
          profile.phonemize(r[1]),
        );
        expect(level.name, r[2]);
        // Symmetric.
        expect(
          profile
              .classify(profile.phonemize(r[1]), profile.phonemize(r[0]))
              .name,
          r[2],
        );
      });
    }
  });

  test('keys', () {
    final k = profile.keysFor('lAska')!;
    expect([k.f1, k.f2, k.as2, k.open, k.syl], ['ka', 'Aska', 'aa', true, 2]);
    final h = profile.keysFor('hrat')!;
    expect([h.f1, h.f2, h.open], ['at', null, false]);
    expect(profile.keysFor('k'), isNull);
  });

  test('exceptions take precedence', () {
    const g = CzechG2P(exceptions: {'tenis': 'tenis'});
    expect(g.toPhonemes('Tenis!'), 'tenis');
    expect(const CzechG2P().toPhonemes('tenis'), 'teNis');
  });

  test('beforePause=false keeps final voicing', () {
    expect(profile.phonemize('led', beforePause: false), 'led');
  });
}
