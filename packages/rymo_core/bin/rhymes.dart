// CLI: dart run rymo_core:rhymes [--pack path] [--assonance] [--cite] <word or line>
import 'dart:io';

import 'package:rymo_core/rymo_core.dart';

void main(List<String> args) {
  var pack = '../../work/cs/cs.rpack';
  var assonance = false, cite = false;
  final words = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--pack':
        pack = args[++i];
      case '--assonance':
        assonance = true;
      case '--cite':
        cite = true;
      default:
        words.add(args[i]);
    }
  }
  if (words.isEmpty) {
    stderr.writeln('usage: rhymes [--pack path] [--assonance] [--cite] <word>');
    exit(2);
  }
  final core = SuggestCore.open(pack);
  final target = words.join(' ');
  final end = lineEndOf(core.profile, target);
  stdout.writeln('${end.word} /${end.phon}/ ${end.keys}');
  final sw = Stopwatch()..start();
  final res = core.suggest(
    SuggestQuery(
      target,
      assonance: assonance,
      minLevel: assonance ? RhymeLevel.assonance : RhymeLevel.loose,
    ),
  );
  final ms = sw.elapsedMicroseconds / 1000;
  RhymeLevel? last;
  for (final s in res) {
    if (s.level != last) {
      stdout.write('\n[${s.level.name}] ');
      last = s.level;
    }
    stdout.write(
      '${s.word}${s.attested > 0 ? '·${s.attested}' : ''}'
      '${s.grammatical ? '(g)' : ''}  ',
    );
  }
  stdout.writeln('\n\n${res.length} návrhů za $ms ms');
  if (cite) {
    for (final s in res.where((s) => s.attested > 0).take(3)) {
      for (final c in core.citations(end.word, s.word)) {
        stdout.writeln(
          '  ${c.lineA} / ${c.lineB} — ${c.author}, ${c.work}'
          '${c.year != null ? ' (${c.year})' : ''}',
        );
      }
    }
  }
  core.close();
}
