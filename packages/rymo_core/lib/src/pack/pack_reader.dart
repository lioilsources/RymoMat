import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class WordRow {
  final int id;
  final String form, phon;
  final int syl, freq;
  final int? lemma, gram, f1, f2, as2;
  const WordRow(
    this.id,
    this.form,
    this.phon,
    this.syl,
    this.freq,
    this.lemma,
    this.gram,
    this.f1,
    this.f2,
    this.as2,
  );

  static WordRow fromRow(Row r) => WordRow(
    r.columnAt(0) as int,
    r.columnAt(1) as String,
    r.columnAt(2) as String,
    r.columnAt(3) as int,
    r.columnAt(4) as int,
    r.columnAt(5) as int?,
    r.columnAt(6) as int?,
    r.columnAt(7) as int?,
    r.columnAt(8) as int?,
    r.columnAt(9) as int?,
  );
}

class FamRow {
  final int id, lvl, looseId, n;
  final String key;
  final bool open;
  const FamRow(this.id, this.lvl, this.key, this.open, this.looseId, this.n);
}

class CiteRow {
  final int a, b, k;
  final String lineA, lineB, author, work;
  final int? year;
  const CiteRow(
    this.a,
    this.b,
    this.k,
    this.lineA,
    this.lineB,
    this.author,
    this.work,
    this.year,
  );
}

/// Read-only access to a `.rpack` with prepared statements.
class PackReader {
  final Database _db;
  late final PreparedStatement _wordByForm,
      _wordById,
      _fam,
      _famsByLoose,
      _wordsF1,
      _wordsF2,
      _wordsAs,
      _pairs,
      _cites;
  late final Map<String, String> meta;

  static const _cols = 'id, form, phon, syl, freq, lemma, gram, f1, f2, as2';

  PackReader._(this._db) {
    meta = {
      for (final r in _db.select('SELECT key, value FROM meta'))
        r['key'] as String: r['value'] as String,
    };
    final schema = int.tryParse(meta['schema'] ?? '');
    if (schema != packSchemaVersion) {
      throw StateError('Unsupported pack schema $schema');
    }
    _wordByForm = _db.prepare('SELECT $_cols FROM word WHERE form = ?');
    _wordById = _db.prepare('SELECT $_cols FROM word WHERE id = ?');
    _fam = _db.prepare(
      'SELECT id, lvl, key, open, loose_id, n FROM fam WHERE lvl = ? AND key = ?',
    );
    _famsByLoose = _db.prepare(
      'SELECT id, lvl, key, open, loose_id, n FROM fam WHERE loose_id = ?',
    );
    _wordsF1 = _db.prepare(
      'SELECT $_cols FROM word WHERE f1 = ? ORDER BY freq DESC LIMIT ?',
    );
    _wordsF2 = _db.prepare(
      'SELECT $_cols FROM word WHERE f2 = ? ORDER BY freq DESC LIMIT ?',
    );
    _wordsAs = _db.prepare(
      'SELECT $_cols FROM word WHERE as2 = ? ORDER BY freq DESC LIMIT ?',
    );
    _pairs = _db.prepare(
      'SELECT w.id, w.form, w.phon, w.syl, w.freq, w.lemma, w.gram, w.f1, '
      'w.f2, w.as2, p.n FROM pair p JOIN word w ON w.id = p.b '
      'WHERE p.a = ? ORDER BY p.n DESC LIMIT ?',
    );
    _cites = _db.prepare(
      'SELECT a, b, k, line_a, line_b, author, work, year FROM cite '
      'WHERE a = ? AND b = ? ORDER BY k',
    );
  }

  static PackReader open(String path) =>
      PackReader._(sqlite3.open(path, mode: OpenMode.readOnly));

  Map<String, String> exceptions() => {
    for (final r in _db.select('SELECT form, phon FROM exc'))
      r['form'] as String: r['phon'] as String,
  };

  WordRow? word(String form) {
    final rs = _wordByForm.select([form]);
    return rs.isEmpty ? null : WordRow.fromRow(rs.first);
  }

  WordRow? wordById(int id) {
    final rs = _wordById.select([id]);
    return rs.isEmpty ? null : WordRow.fromRow(rs.first);
  }

  FamRow? fam(int lvl, String key) {
    final rs = _fam.select([lvl, key]);
    return rs.isEmpty ? null : _famRow(rs.first);
  }

  List<FamRow> famsByLoose(int looseId) => [
    for (final r in _famsByLoose.select([looseId])) _famRow(r),
  ];

  List<WordRow> wordsInFam(int lvl, int famId, int limit) {
    final st = switch (lvl) {
      FamLevel.f1 => _wordsF1,
      FamLevel.f2 => _wordsF2,
      _ => _wordsAs,
    };
    return [
      for (final r in st.select([famId, limit])) WordRow.fromRow(r),
    ];
  }

  /// Attested partners of word [id] with pair counts.
  List<(WordRow, int)> partners(int id, int limit) => [
    for (final r in _pairs.select([id, limit]))
      (WordRow.fromRow(r), r.columnAt(10) as int),
  ];

  List<CiteRow> cites(int a, int b) {
    if (a > b) (a, b) = (b, a);
    return [
      for (final r in _cites.select([a, b]))
        CiteRow(
          r.columnAt(0) as int,
          r.columnAt(1) as int,
          r.columnAt(2) as int,
          r.columnAt(3) as String,
          r.columnAt(4) as String,
          r.columnAt(5) as String,
          r.columnAt(6) as String,
          r.columnAt(7) as int?,
        ),
    ];
  }

  FamRow _famRow(Row r) => FamRow(
    r.columnAt(0) as int,
    r.columnAt(1) as int,
    r.columnAt(2) as String,
    (r.columnAt(3) as int) != 0,
    r.columnAt(4) as int,
    r.columnAt(5) as int,
  );

  void close() {
    for (final s in [
      _wordByForm,
      _wordById,
      _fam,
      _famsByLoose,
      _wordsF1,
      _wordsF2,
      _wordsAs,
      _pairs,
      _cites,
    ]) {
      s.close();
    }
    _db.close();
  }
}
