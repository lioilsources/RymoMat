// Evaluation of a pack (plan §8 `rymo eval`, gate M0):
//  1. golden: f1 of our G2P vs f1 of the KČV XSAMPA transcription,
//  2. classification of attested pairs,
//  3. suggest latency on 1 000 random words (direct core and via the isolate).
//
//   dart run rymo_core:eval --pack work/cs/cs.rpack --dir work/cs --out docs/eval_cs.md
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:rymo_core/rymo_core.dart';
import 'package:rymo_core/src/phon/xsampa.dart';

Future<void> main(List<String> args) async {
  String arg(String k, String d) {
    final i = args.indexOf('--$k');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : d;
  }

  final dir = arg('dir', '../../work/cs');
  final packPath = arg('pack', p.join(dir, 'cs.rpack'));
  final outPath = arg('out', '../../docs/eval_cs.md');
  final core = SuggestCore.open(packPath);
  final profile = core.profile;
  // Golden test measures the rules alone, without the exception table.
  final rules = CzechProfile();
  final md = StringBuffer('# Evaluace packu `cs`\n\n')
    ..writeln(
      'Generuje `rymo eval cs` (`packages/rymo_core/bin/eval.dart`). '
      'Pack: ${(File(packPath).lengthSync() / 1e6).toStringAsFixed(1)} MB, '
      '${core.pack.meta['levers'] ?? 'bez pák'}, '
      'verze ${core.pack.meta['version']}, sestaven ${core.pack.meta['built_at']}.\n',
    );

  // 1. Golden test against KČV transcriptions.
  final golden = _tsv(p.join(dir, 'golden.tsv'));
  final unknown = <String>{};
  var ok = 0, total = 0, skipped = 0;
  final miss = <String, int>{};
  final missInfo = <String, (String, String, String, String)>{};
  for (final r in golden) {
    final form = r[0];
    final ref = XSampa.toPhon(r[1], unknown);
    final ours = rules.phonemize(form);
    final kr = ref == null ? null : rules.keysFor(ref);
    final ko = rules.keysFor(ours);
    if (ref == null || kr == null || ko == null) {
      skipped++;
      continue;
    }
    total++;
    if (kr.f1 == ko.f1) {
      ok++;
    } else {
      miss.update(form, (v) => v + 1, ifAbsent: () => 1);
      missInfo[form] = (ours, ref, ko.f1, kr.f1);
    }
  }
  final gPct = 100 * ok / max(total, 1);
  md
    ..writeln('## 1. Golden test G2P proti přepisu KČV\n')
    ..writeln(
      'Vzorek ${golden.length} náhodných posledních slov veršů '
      '(seed 2026), porovnává se klíč `f1`.\n',
    )
    ..writeln(
      '- shoda: **$ok / $total = ${gPct.toStringAsFixed(2)} %** '
      '(brána ≥ 97 %)',
    )
    ..writeln(
      '- přeskočeno (neznámý symbol XSAMPA nebo slovo bez jádra): '
      '$skipped${unknown.isEmpty ? '' : ', neznámé symboly: ${unknown.join(' ')}'}\n',
    )
    ..writeln(
      'Nejčastější neshody (slovo, počet, náš přepis, KČV, f1 náš / KČV):\n',
    )
    ..writeln(
      '| slovo | n | náš | KČV | f1 náš | f1 KČV |\n|---|---|---|---|---|---|',
    );
  final missSorted = miss.entries.toList()..sort((a, b) => b.value - a.value);
  for (final e in missSorted.take(60)) {
    final (o, r, fo, fr) = missInfo[e.key]!;
    md.writeln('| ${e.key} | ${e.value} | $o | $r | $fo | $fr |');
  }
  final cand = StringBuffer('form\tphon\tn\n');
  for (final e in missSorted) {
    cand.writeln('${e.key}\t${missInfo[e.key]!.$2}\t${e.value}');
  }
  File(p.join(dir, 'exc_candidates.tsv')).writeAsStringSync(cand.toString());

  // 2. Attested pairs.
  final byLevel = <RhymeLevel, int>{}, byLevelN = <RhymeLevel, int>{};
  final examples = <RhymeLevel, List<String>>{};
  var pairsTotal = 0, occTotal = 0;
  final noneTypes = <String, int>{};
  final noneExamples = <String, List<String>>{};
  for (final r in _tsv(p.join(dir, 'pairs.tsv'))) {
    final n = int.parse(r[2]);
    final pa = profile.phonemize(r[0]), pb = profile.phonemize(r[1]);
    final lvl = profile.classify(pa, pb);
    byLevel.update(lvl, (v) => v + 1, ifAbsent: () => 1);
    byLevelN.update(lvl, (v) => v + n, ifAbsent: () => n);
    pairsTotal++;
    occTotal += n;
    if (lvl == RhymeLevel.none) {
      final t = _noneType(profile, pa, pb, r[0], r[1]);
      noneTypes.update(t, (v) => v + n, ifAbsent: () => n);
      final ex = noneExamples.putIfAbsent(t, () => []);
      if (ex.length < 10) ex.add('${r[0]}/${r[1]} ($n)');
    }
    final ex = examples.putIfAbsent(lvl, () => []);
    if (ex.length < 25) ex.add('${r[0]}/${r[1]} ($n)');
  }
  const rhyme = {
    RhymeLevel.identical,
    RhymeLevel.full,
    RhymeLevel.masc,
    RhymeLevel.weak,
    RhymeLevel.looseFull,
    RhymeLevel.loose,
  };
  int sumOf(Map<RhymeLevel, int> m) => rhyme.fold(0, (s, l) => s + (m[l] ?? 0));
  final rPct = 100 * sumOf(byLevel) / max(pairsTotal, 1);
  final rPctN = 100 * sumOf(byLevelN) / max(occTotal, 1);
  md
    ..writeln('\n## 2. Doložené páry KČV podle levelu\n')
    ..writeln(
      '$pairsTotal různých párů, $occTotal výskytů. Jako rým '
      '(`identical`…`loose`) engine označí **${rPct.toStringAsFixed(2)} %** '
      'párů a **${rPctN.toStringAsFixed(2)} %** výskytů (brána ≥ 85 %).\n',
    )
    ..writeln(
      '| level | páry | % | výskyty | % | příklady |\n|---|---|---|---|---|---|',
    );
  for (final l in RhymeLevel.values) {
    final c = byLevel[l] ?? 0, cn = byLevelN[l] ?? 0;
    md.writeln(
      '| ${l.name} | $c | ${(100 * c / max(pairsTotal, 1)).toStringAsFixed(2)} '
      '| $cn | ${(100 * cn / max(occTotal, 1)).toStringAsFixed(2)} '
      '| ${(examples[l] ?? []).take(8).join(', ')} |',
    );
  }

  md
    ..writeln('\nRozbor `none` (výskyty):\n')
    ..writeln('| typ | výskyty | příklady |\n|---|---|---|');
  for (final e
      in noneTypes.entries.toList()..sort((a, b) => b.value - a.value)) {
    md.writeln(
      '| ${e.key} | ${e.value} | ${noneExamples[e.key]!.join(', ')} |',
    );
  }

  // 3. Latency.
  final lex = _tsv(p.join(dir, 'lexicon.tsv')).map((r) => r[0]).toList();
  final rnd = Random(2026);
  final sample = [for (var i = 0; i < 1000; i++) lex[rnd.nextInt(lex.length)]];
  for (final w in sample.take(50)) {
    core.suggest(SuggestQuery(w));
  }
  final direct = <int>[];
  var empty = 0;
  // First pass warms the OS page cache; the second one is measured.
  for (final w in sample) {
    core.suggest(SuggestQuery(w));
  }
  for (final w in sample) {
    final sw = Stopwatch()..start();
    final res = core.suggest(SuggestQuery(w));
    direct.add(sw.elapsedMicroseconds);
    if (res.isEmpty) empty++;
  }
  core.close();
  final engine = await RhymeEngine.open(packPath);
  for (final w in sample.take(50)) {
    await engine.suggest(SuggestQuery(w));
  }
  final viaIsolate = <int>[];
  for (final w in sample) {
    final sw = Stopwatch()..start();
    await engine.suggest(SuggestQuery(w));
    viaIsolate.add(sw.elapsedMicroseconds);
  }
  engine.close();
  String pct(List<int> l, double q) {
    final s = [...l]..sort();
    return (s[min(s.length - 1, (q * s.length).floor())] / 1000)
        .toStringAsFixed(2);
  }

  md
    ..writeln(
      '\n## 3. Latence `suggest` (1 000 náhodných slov z lexikonu, '
      '${Platform.operatingSystem}, ${Platform.numberOfProcessors} jader)\n',
    )
    ..writeln(
      '| cesta | p50 ms | p95 ms | p99 ms | max ms |\n|---|---|---|---|---|',
    )
    ..writeln(
      '| SuggestCore přímo | ${pct(direct, .5)} | ${pct(direct, .95)} '
      '| ${pct(direct, .99)} | ${pct(direct, 1)} |',
    )
    ..writeln(
      '| RhymeEngine (izolát) | ${pct(viaIsolate, .5)} | '
      '${pct(viaIsolate, .95)} | ${pct(viaIsolate, .99)} | ${pct(viaIsolate, 1)} |',
    )
    ..writeln('\nSlov bez jediného návrhu: $empty / 1000.');

  File(outPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(md.toString());
  stdout.writeln(
    'golden f1 ${gPct.toStringAsFixed(2)} %, pairs rhyme '
    '${rPct.toStringAsFixed(2)} % (occurrences ${rPctN.toStringAsFixed(2)} %), '
    'suggest p95 ${pct(direct, .95)} ms / isolate ${pct(viaIsolate, .95)} ms '
    '-> $outPath',
  );
}

List<List<String>> _tsv(String path) => File(path)
    .readAsLinesSync()
    .skip(1)
    .where((l) => l.isNotEmpty)
    .map((l) => l.split('\t'))
    .toList();

/// Rough type of an attested pair the engine does not call a rhyme.
String _noneType(CzechProfile pr, String pa, String pb, String a, String b) {
  final ka = pr.keysFor(pa), kb = pr.keysFor(pb);
  if (ka == null || kb == null) return 'slovo bez jádra';
  final foreign = RegExp('[qwxäöüëàèâêîôûçñ]');
  if (foreign.hasMatch(a) || foreign.hasMatch(b)) {
    return 'přejaté slovo (možná chyba G2P)';
  }
  final va = pr.fold(pa[pr.nuclei(pa).last]),
      vb = pr.fold(pb[pr.nuclei(pb).last]);
  if (va == vb && ka.open && kb.open) {
    return 'otevřený konec, stejné jádro, jiná opěrná souhláska (dá/má)';
  }
  if (va == vb && !ka.open && !kb.open) {
    return 'zavřený konec, stejné jádro, jiná koda (souzvuk)';
  }
  if (va == vb) return 'stejné jádro, jedno otevřené a jedno zavřené';
  return 'jiné jádro (chyba anotace nebo oční rým)';
}
