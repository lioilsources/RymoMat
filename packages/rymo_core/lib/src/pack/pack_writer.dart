import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../phon/cs_g2p.dart';
import '../rhyme/profile.dart';
import 'schema.dart';

class LexEntry {
  final String form;
  final int freq;
  final String? lemma;

  /// Prague positional tag (or null).
  final String? tag;
  const LexEntry(this.form, this.freq, {this.lemma, this.tag});
}

class PairEntry {
  final String a, b;
  final int n, authors;
  const PairEntry(this.a, this.b, this.n, this.authors);
}

class CiteEntry {
  final String a, b, lineA, lineB, author, work;
  final int? year;
  const CiteEntry(
    this.a,
    this.b,
    this.lineA,
    this.lineB,
    this.author,
    this.work,
    this.year,
  );
}

class PackStats {
  final int words, families, pairs, cites, exceptions, bytes;
  const PackStats(
    this.words,
    this.families,
    this.pairs,
    this.cites,
    this.exceptions,
    this.bytes,
  );
  Map<String, int> toJson() => {
    'words': words,
    'families': families,
    'pairs': pairs,
    'cites': cites,
    'exceptions': exceptions,
    'bytes': bytes,
  };
}

/// Builds a `.rpack`. The only place where phonemes and keys for a pack
/// come into existence (plan R2).
class PackWriter {
  final String lang;
  final int version;
  final Map<String, String> meta;
  final bool assonanceIndex;

  /// Budget lever 2: max attested partners per word (null = unlimited).
  final int? maxPartners;

  /// Budget lever 3: max citations (null = unlimited).
  final int? maxCites;

  PackWriter({
    this.lang = 'cs',
    this.version = 1,
    this.meta = const {},
    this.assonanceIndex = true,
    this.maxPartners,
    this.maxCites,
  });

  PackStats write(
    String path, {
    required List<LexEntry> lexicon,
    List<PairEntry> pairs = const [],
    List<CiteEntry> cites = const [],
    Map<String, String> exceptions = const {},
  }) {
    if (lang != 'cs') {
      throw UnsupportedError('Only the cs profile exists so far (M3).');
    }
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
    final profile = CzechProfile(g2p: CzechG2P(exceptions: exceptions));

    // Merge lexicon with pair words so every pair resolves to a word id.
    final byForm = <String, LexEntry>{};
    for (final e in lexicon) {
      final form = CzechG2P.normalize(e.form);
      if (form.isEmpty) continue;
      final old = byForm[form];
      if (old == null || old.freq < e.freq) byForm[form] = e;
    }
    for (final p in pairs) {
      for (final w in [CzechG2P.normalize(p.a), CzechG2P.normalize(p.b)]) {
        if (w.isNotEmpty) byForm.putIfAbsent(w, () => LexEntry(w, 1));
      }
    }
    final forms = byForm.keys.toList()..sort();

    final phon = <String, String>{};
    final keyF1 = <String, String?>{};
    final keyF2 = <String, String?>{};
    final keyAs = <String, String?>{};
    final open = <String, bool>{};
    final syl = <String, int>{};
    final famCount = <(int, String), int>{};
    final famOpen = <String, bool>{};
    for (final w in forms) {
      final p = profile.phonemize(w);
      final k = profile.keysFor(p);
      phon[w] = p;
      keyF1[w] = k?.f1;
      keyF2[w] = k?.f2;
      keyAs[w] = k?.as2;
      open[w] = k?.open ?? false;
      syl[w] = k?.syl ?? 0;
      if (k == null) continue;
      famCount.update((FamLevel.f1, k.f1), (v) => v + 1, ifAbsent: () => 1);
      famOpen[k.f1] = k.open;
      if (k.f2 != null) {
        famCount.update((FamLevel.f2, k.f2!), (v) => v + 1, ifAbsent: () => 1);
      }
      if (k.as2 != null) {
        famCount.update(
          (FamLevel.as2, k.as2!),
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final famKeys = famCount.keys.toList()
      ..sort((x, y) => x.$1 != y.$1 ? x.$1 - y.$1 : x.$2.compareTo(y.$2));
    final famId = <(int, String), int>{};
    final looseMin = <(int, String), int>{};
    for (var i = 0; i < famKeys.length; i++) {
      final id = i + 1;
      famId[famKeys[i]] = id;
      final (lvl, key) = famKeys[i];
      final lk = (lvl, lvl == FamLevel.as2 ? key : profile.fold(key));
      looseMin.putIfAbsent(lk, () => id);
    }

    final lemmaId = <String, int>{};
    final db = sqlite3.open(path);
    try {
      db.execute('PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF;');
      db.execute(packSchemaSql);
      db.execute('BEGIN');

      final allMeta = {
        'schema': '$packSchemaVersion',
        'lang': lang,
        'profile': profile.id,
        'version': '$version',
        'built_at': DateTime.now().toUtc().toIso8601String(),
        ...meta,
      };
      final insMeta = db.prepare('INSERT INTO meta VALUES(?, ?)');
      allMeta.forEach((k, v) => insMeta.execute([k, v]));
      insMeta.close();

      final insFam = db.prepare('INSERT INTO fam VALUES(?, ?, ?, ?, ?, ?)');
      for (final fk in famKeys) {
        final (lvl, key) = fk;
        final lk = (lvl, lvl == FamLevel.as2 ? key : profile.fold(key));
        final isOpen = lvl == FamLevel.f1 ? (famOpen[key]! ? 1 : 0) : 0;
        insFam.execute([
          famId[fk],
          lvl,
          key,
          isOpen,
          looseMin[lk],
          famCount[fk],
        ]);
      }
      insFam.close();

      final wordId = <String, int>{};
      final insWord = db.prepare(
        'INSERT INTO word VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      );
      for (var i = 0; i < forms.length; i++) {
        final w = forms[i];
        final e = byForm[w]!;
        final id = i + 1;
        wordId[w] = id;
        final lemma = e.lemma == null
            ? null
            : lemmaId.putIfAbsent(e.lemma!, () => lemmaId.length + 1);
        insWord.execute([
          id,
          w,
          phon[w],
          syl[w],
          e.freq,
          lemma,
          gramCode(e.tag),
          keyF1[w] == null ? null : famId[(FamLevel.f1, keyF1[w]!)],
          keyF2[w] == null ? null : famId[(FamLevel.f2, keyF2[w]!)],
          keyAs[w] == null ? null : famId[(FamLevel.as2, keyAs[w]!)],
        ]);
      }
      insWord.close();

      // Pairs in both directions, optionally capped per word.
      final dir = <int, List<(int, int, int)>>{};
      for (final p in pairs) {
        final a = wordId[CzechG2P.normalize(p.a)];
        final b = wordId[CzechG2P.normalize(p.b)];
        if (a == null || b == null || a == b) continue;
        dir.putIfAbsent(a, () => []).add((b, p.n, p.authors));
        dir.putIfAbsent(b, () => []).add((a, p.n, p.authors));
      }
      final insPair = db.prepare(
        'INSERT OR REPLACE INTO pair VALUES(?, ?, ?, ?)',
      );
      var pairRows = 0;
      final kept = <(int, int), int>{};
      for (final a in dir.keys) {
        final list = dir[a]!..sort((x, y) => y.$2 - x.$2);
        final cap = maxPartners ?? list.length;
        for (final (b, n, au) in list.take(cap)) {
          insPair.execute([a, b, n, au]);
          kept[a < b ? (a, b) : (b, a)] = n;
          pairRows++;
        }
      }
      insPair.close();

      // Citations: a < b, at most 2 per pair, distinct authors first.
      final byPair = <(int, int), List<CiteEntry>>{};
      for (final c in cites) {
        var a = wordId[CzechG2P.normalize(c.a)];
        var b = wordId[CzechG2P.normalize(c.b)];
        if (a == null || b == null || a == b) continue;
        var e = c;
        if (a > b) {
          (a, b) = (b, a);
          e = CiteEntry(c.b, c.a, c.lineB, c.lineA, c.author, c.work, c.year);
        }
        byPair.putIfAbsent((a, b), () => []).add(e);
      }
      final insCite = db.prepare(
        'INSERT INTO cite VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
      );
      var citeRows = 0;
      // Most attested pairs get their citations first (budget lever 3);
      // only pairs that survived the partner cap are cited.
      final pairKeys = byPair.keys.where(kept.containsKey).toList()
        ..sort((x, y) {
          final c = kept[y]! - kept[x]!;
          return c != 0 ? c : (x.$1 != y.$1 ? x.$1 - y.$1 : x.$2 - y.$2);
        });
      for (final pk in pairKeys) {
        if (maxCites != null && citeRows >= maxCites!) break;
        final list = byPair[pk]!;
        final chosen = <CiteEntry>[];
        for (final c in list) {
          if (chosen.length == 2) break;
          if (chosen.every((x) => x.author != c.author)) chosen.add(c);
        }
        for (final c in list) {
          if (chosen.length == 2) break;
          if (!chosen.contains(c)) chosen.add(c);
        }
        for (var k = 0; k < chosen.length; k++) {
          final c = chosen[k];
          insCite.execute([
            pk.$1,
            pk.$2,
            k,
            c.lineA,
            c.lineB,
            c.author,
            c.work,
            c.year,
          ]);
          citeRows++;
        }
      }
      insCite.close();

      final insExc = db.prepare('INSERT INTO exc VALUES(?, ?)');
      exceptions.forEach((k, v) => insExc.execute([k, v]));
      insExc.close();

      db.execute('COMMIT');
      db.execute(packIndexSql);
      if (assonanceIndex) db.execute(packAssonanceIndexSql);
      db.execute('ANALYZE; VACUUM;');
      return PackStats(
        forms.length,
        famKeys.length,
        pairRows,
        citeRows,
        exceptions.length,
        File(path).lengthSync(),
      );
    } finally {
      db.close();
    }
  }

  static String encodeSources(List<Map<String, Object?>> sources) =>
      jsonEncode(sources);
}
