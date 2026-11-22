import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_editor/rymo_editor.dart';

/// Fake source: rhymes are computed by the real profile, suggestions come
/// from a fixed word list; optional per-target delays simulate slow queries.
class FakeSource extends RhymeSource {
  final CzechProfile _p = CzechProfile();
  final List<String> words;
  final Map<String, Completer<void>> gates = {};
  final List<SuggestQuery> queries = [];
  FakeSource(this.words);

  @override
  RhymeProfile get profile => _p;

  @override
  LineEnd lineEnd(String line) => lineEndOf(_p, line);

  @override
  Future<List<Suggestion>> suggest(SuggestQuery q) async {
    queries.add(q);
    final gate = gates[q.prefix];
    if (gate != null) await gate.future;
    final t = lineEnd(q.target);
    final out = <Suggestion>[];
    for (final w in words) {
      if (w == t.word || !w.startsWith(q.prefix)) continue;
      final e = lineEnd(w);
      final lvl = classify(t, e);
      if (lvl == RhymeLevel.none || !lvl.atLeast(RhymeLevel.loose)) continue;
      out.add(
        Suggestion(
          word: w,
          level: lvl,
          common: 0,
          attested: 0,
          freq: 0,
          grammatical: false,
          used: q.usedWords.contains(w),
        ),
      );
    }
    return out.take(q.limit).toList();
  }

  @override
  Future<List<Citation>> citations(String a, String b) async => const [];
}

final labels = RhymeEditorLabels(
  syllables: (n) => '$n syl',
  newRhyme: 'new rhyme',
  noSuggestions: 'none',
  rhymesFor: (w) => 'rhymes for $w',
  level: (l) => l.name,
  attested: (n) => '$n×',
  grammatical: 'gram',
  used: 'used',
  prefixIgnored: 'prefix ignored',
  citations: 'citations',
  noCitations: 'no citations',
  insert: 'insert',
);

TextEditingValue v(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  group('insertSuggestion', () {
    test('replaces the token being typed', () {
      final r = insertSuggestion(v('byl pozdní večer\nkde zelený h'), 'háj');
      expect(r.text, 'byl pozdní večer\nkde zelený háj');
      expect(r.selection.extentOffset, r.text.length);
    });
    test('appends with a space after a finished word', () {
      final r = insertSuggestion(v('první řádek\nzelený '), 'háj');
      expect(r.text, 'první řádek\nzelený háj');
      final r2 = insertSuggestion(
        v('a\nb\nc', 2),
        'x',
      ); // cursor at start of "b"
      expect(r2.text, 'a\nb x\nc');
      expect(r2.selection.extentOffset, 5);
    });
    test('fills an empty line', () {
      expect(insertSuggestion(v('a\n'), 'háj').text, 'a\nháj');
    });
  });

  group('free mode targets', () {
    final src = FakeSource(const []);
    List<String> targets(String text) {
      final vt = VerseText(text);
      return freeModeTargets(
        src,
        vt,
        vt.lineAt(text.length),
      ).map((t) => t.end.word).toList();
    }

    test('previous verses of the stanza, unpartnered first', () {
      // máj/háj rhyme, čas is free → čas first, then háj, máj (nearest first).
      expect(
        targets(
          'byl pozdní večer první máj\nvečerní máj byl lásky čas\nkde borový zaváněl háj\n',
        ),
        ['čas', 'háj', 'máj'],
      );
    });
    test('short stanza adds the last verse of the previous one', () {
      expect(targets('jedna voda\ndruhá ryba\n\ntřetí strom\n'), [
        'strom',
        'ryba',
      ]);
      expect(targets('jedna voda\n\n\n'), ['voda']);
    });
    test('typing prefix', () {
      expect(VerseText('a\nzelený h').typingPrefix(10), 'h');
      expect(VerseText('a\nzelený ').typingPrefix(9), '');
      expect(VerseText('a\nzelený háj').typingPrefix(3), '');
    });
  });

  testWidgets('bar shows chips; tap replaces typed token', (tester) async {
    final src = FakeSource(['háj', 'ráj', 'kraj', 'hrad']);
    final c = RhymeEditingController(
      text: 'byl pozdní večer první máj\nkde borový zaváněl h',
      source: src,
    );
    c.selection = TextSelection.collapsed(offset: c.text.length);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: RhymeTextField(controller: c, labels: labels),
              ),
              RhymeBar(controller: c, labels: labels, source: src),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(src.queries.last.prefix, 'h');
    expect(find.byKey(const ValueKey('chip-háj')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chip-ráj')),
      findsNothing,
    ); // prefix filter
    await tester.tap(find.byKey(const ValueKey('chip-háj')));
    expect(c.text, 'byl pozdní večer první máj\nkde borový zaváněl háj');
    expect(c.selection.extentOffset, c.text.length);
    await tester.pump(const Duration(milliseconds: 100));
    c.dispose();
  });

  testWidgets('stale result is not shown', (tester) async {
    final src = FakeSource(['háj', 'ráj']);
    final slow = Completer<void>();
    src.gates['r'] = slow;
    final c = RhymeEditingController(text: 'první máj\nr', source: src);
    c.selection = TextSelection.collapsed(offset: c.text.length);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RhymeBar(controller: c, labels: labels, source: src),
        ),
      ),
    );
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // slow request for "r"
    c.value = v('první máj\nh');
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // fast request for "h"
    await tester.pump();
    expect(find.byKey(const ValueKey('chip-háj')), findsOneWidget);
    slow.complete();
    await tester.pump();
    expect(find.byKey(const ValueKey('chip-ráj')), findsNothing);
    expect(find.byKey(const ValueKey('chip-háj')), findsOneWidget);
    c.dispose();
  });
}
