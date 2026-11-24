import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rymo_core/rymo_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late String pack;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('rymo_test');
    pack = p.join(dir.path, 'cs.rpack');
    PackWriter(meta: {'sources_json': '[]'}).write(
      pack,
      lexicon: const [
        LexEntry('láska', 500, lemma: 'láska', tag: 'NNFS1-----A----'),
        LexEntry('lásky', 300, lemma: 'láska', tag: 'NNFS2-----A----'),
        LexEntry('páska', 50, lemma: 'páska', tag: 'NNFS1-----A----'),
        LexEntry('kráska', 80, lemma: 'kráska', tag: 'NNFS1-----A----'),
        LexEntry('otázka', 200, lemma: 'otázka', tag: 'NNFS1-----A----'),
        LexEntry('praská', 40, lemma: 'praskat', tag: 'VB-S---3P-AA---'),
        LexEntry('maska', 90, lemma: 'maska', tag: 'NNFS1-----A----'),
        LexEntry('dáma', 70, lemma: 'dáma', tag: 'NNFS1-----A----'),
        LexEntry('voda', 900),
        LexEntry('ryba', 100),
        LexEntry('dá', 400),
        LexEntry('zná', 300),
        LexEntry('tvá', 200),
      ],
      pairs: const [PairEntry('láska', 'otázka', 7, 3)],
      cites: const [
        CiteEntry(
          'otázka',
          'láska',
          'Hlavnější zde jest otázka,',
          'Jsem-li tvoje první láska,',
          'Josef Uhlíř',
          'Básně',
          1858,
        ),
      ],
      exceptions: const {'ryba': 'rIba'},
    );
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  test('layers: attested first, then full, loose; lemma filtered', () {
    final core = SuggestCore.open(pack);
    final res = core.suggest(const SuggestQuery('a byla to láska'));
    final words = res.map((s) => s.word).toList();
    expect(words.first, 'otázka');
    expect(res.first.attested, 7);
    expect(words, isNot(contains('lásky')));
    expect(words, isNot(contains('láska')));
    expect(words, isNot(contains('dáma'))); // assonance is off
    // Grammatical rhymes (same tag, same last 3 letters) go last in a level.
    final full = res.where(
      (s) => s.level == RhymeLevel.full && s.attested == 0,
    );
    expect(full.map((s) => s.word), ['kráska', 'páska']);
    expect(full.every((s) => s.grammatical), isTrue);
    expect(
      res.firstWhere((s) => s.word == 'praská').level,
      RhymeLevel.looseFull,
    );
    core.close();
  });

  test('prefix filter falls back with a flag', () {
    final core = SuggestCore.open(pack);
    final pr = core.suggest(const SuggestQuery('láska', prefix: 'Kr'));
    expect(pr.map((s) => s.word), ['kráska']);
    final none = core.suggest(const SuggestQuery('láska', prefix: 'zz'));
    expect(none, isNotEmpty);
    expect(none.every((s) => s.prefixIgnored), isTrue);
    core.close();
  });

  test('assonance and used words', () {
    final core = SuggestCore.open(pack);
    final res = core.suggest(
      const SuggestQuery(
        'láska',
        assonance: true,
        minLevel: RhymeLevel.assonance,
        usedWords: {'páska'},
      ),
    );
    expect(res.map((s) => s.word), contains('dáma'));
    expect(res.firstWhere((s) => s.word == 'páska').used, isTrue);
    core.close();
  });

  test('open monosyllables rhyme across onsets (dá/má)', () {
    final core = SuggestCore.open(pack);
    final res = core.suggest(const SuggestQuery('to je má'));
    final words = res.map((s) => s.word).toList();
    expect(words, containsAll(['dá', 'zná', 'tvá']));
    expect(words, isNot(contains('voda')));
    expect(res.every((s) => s.level == RhymeLevel.loose), isTrue);
    core.close();
  });

  test('words outside the lexicon get keys by rules', () {
    final core = SuggestCore.open(pack);
    final res = core.suggest(const SuggestQuery('sedmihláska'));
    expect(res.map((s) => s.word), containsAll(['páska', 'kráska']));
    core.close();
  });

  test('engine on isolate: suggest, citations, exceptions', () async {
    final e = await RhymeEngine.open(pack);
    final res = await e.suggest(const SuggestQuery('láska'));
    expect(res.first.word, 'otázka');
    final c = await e.citations('láska', 'otázka');
    expect(c.single.lineA, 'Jsem-li tvoje první láska,');
    expect(c.single.author, 'Josef Uhlíř');
    expect(e.lineEnd('velká ryba').phon, 'rIba');
    expect(e.analyze('voda\nryba').lines.length, 2);
    e.close();
  });
}
