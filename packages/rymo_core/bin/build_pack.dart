// Builds a rhyme pack: lexicon.tsv + pairs.tsv + cites.tsv (+ exc.tsv) -> <lang>.rpack.
//
//   dart run rymo_core:build_pack --dir work/cs --out work/cs/cs.rpack
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rymo_core/rymo_core.dart';

void main(List<String> args) {
  final opt = _parse(args);
  final dir = opt['dir'] ?? '.';
  final lang = opt['lang'] ?? 'cs';
  final out = opt['out'] ?? p.join(dir, '$lang.rpack');
  final sw = Stopwatch()..start();

  final minFreq = int.tryParse(opt['min-freq'] ?? '') ?? 0;
  final lexicon = <LexEntry>[];
  for (final r in _tsv(p.join(dir, 'lexicon.tsv'))) {
    if (int.parse(r[1]) < minFreq) continue;
    lexicon.add(
      LexEntry(r[0], int.parse(r[1]), lemma: _nz(r, 2), tag: _nz(r, 3)),
    );
  }
  final pairs = [
    for (final r in _tsv(p.join(dir, 'pairs.tsv')))
      PairEntry(r[0], r[1], int.parse(r[2]), int.parse(r[3])),
  ];
  final cites = opt.containsKey('no-cites')
      ? <CiteEntry>[]
      : [
          for (final r in _tsv(p.join(dir, 'cites.tsv')))
            CiteEntry(
              r[0],
              r[1],
              r[2],
              r[3],
              r[4],
              r[5],
              r.length > 6 ? int.tryParse(r[6]) : null,
            ),
        ];
  final excFile = File(opt['exc'] ?? p.join(dir, 'exc.tsv'));
  final exc = <String, String>{
    if (excFile.existsSync())
      for (final r in _tsv(excFile.path)) r[0]: r[1],
  };
  final srcFile = File(p.join(dir, 'sources.json'));
  final sources = srcFile.existsSync() ? srcFile.readAsStringSync() : '[]';
  final attribution = [
    for (final s in jsonDecode(sources) as List)
      '${s['id']}: ${s['license']} — ${s['attribution']}'.trim(),
  ].join('\n');

  final writer = PackWriter(
    lang: lang,
    version: int.parse(opt['version'] ?? '1'),
    meta: {
      'sources_json': sources,
      'attribution': attribution,
      'levers': [
        if (opt.containsKey('no-as-index')) 'bez indexu word_as',
        if (opt['max-partners'] != null) 'max ${opt['max-partners']} partnerů',
        if (opt['max-cites'] != null) 'max ${opt['max-cites']} citací',
        if (opt['min-freq'] != null) 'freq ≥ ${opt['min-freq']}',
      ].join(', '),
    },
    assonanceIndex: !opt.containsKey('no-as-index'),
    maxPartners: int.tryParse(opt['max-partners'] ?? ''),
    maxCites: int.tryParse(opt['max-cites'] ?? ''),
  );
  final stats = writer.write(
    out,
    lexicon: lexicon,
    pairs: pairs,
    cites: cites,
    exceptions: exc,
  );
  stdout.writeln(
    jsonEncode({
      'out': out,
      ...stats.toJson(),
      'seconds': sw.elapsedMilliseconds / 1000,
    }),
  );
}

String? _nz(List<String> r, int i) =>
    i < r.length && r[i].trim().isNotEmpty ? r[i] : null;

Iterable<List<String>> _tsv(String path) sync* {
  var first = true;
  for (final l in File(path).readAsLinesSync()) {
    if (first) {
      first = false;
      continue;
    }
    if (l.isEmpty) continue;
    yield l.split('\t');
  }
}

/// Parses `--key value` and bare `--flag` options.
Map<String, String> _parse(List<String> args) {
  final m = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;
    final k = a.substring(2);
    if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      m[k] = args[++i];
    } else {
      m[k] = '';
    }
  }
  return m;
}
