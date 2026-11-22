/// Rhyme pack schema (plan §7). Bump [packSchemaVersion] on any change.
const int packSchemaVersion = 1;

/// Family levels in table `fam`.
abstract final class FamLevel {
  static const int f1 = 1;
  static const int f2 = 2;
  static const int as2 = 3;
}

const String packSchemaSql = '''
CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE fam(id INTEGER PRIMARY KEY, lvl INTEGER NOT NULL,
  key TEXT NOT NULL, open INTEGER NOT NULL DEFAULT 0, loose_id INTEGER NOT NULL,
  n INTEGER NOT NULL, UNIQUE(lvl, key));
CREATE TABLE word(id INTEGER PRIMARY KEY, form TEXT NOT NULL UNIQUE, phon TEXT NOT NULL,
  syl INTEGER NOT NULL, freq INTEGER NOT NULL, lemma INTEGER, gram INTEGER,
  f1 INTEGER, f2 INTEGER, as2 INTEGER);
CREATE TABLE pair(a INTEGER NOT NULL, b INTEGER NOT NULL, n INTEGER NOT NULL,
  authors INTEGER NOT NULL, PRIMARY KEY(a, b)) WITHOUT ROWID;
CREATE TABLE cite(a INTEGER NOT NULL, b INTEGER NOT NULL, k INTEGER NOT NULL,
  line_a TEXT NOT NULL, line_b TEXT NOT NULL, author TEXT NOT NULL, work TEXT NOT NULL,
  year INTEGER, PRIMARY KEY(a, b, k)) WITHOUT ROWID;
CREATE TABLE exc(form TEXT PRIMARY KEY, phon TEXT NOT NULL) WITHOUT ROWID;
''';

/// Indexes are created after bulk insert. `word_as` is the first budget lever.
const String packIndexSql = '''
CREATE INDEX word_f1 ON word(f1, freq DESC);
CREATE INDEX word_f2 ON word(f2, freq DESC);
CREATE INDEX fam_loose ON fam(loose_id);
''';
const String packAssonanceIndexSql =
    'CREATE INDEX word_as ON word(as2, freq DESC);';

/// Packs the grammatical positions of a Prague positional tag into an int:
/// POS, SubPOS, gender, number, case, person, tense, voice (7 bits each).
int? gramCode(String? tag) {
  if (tag == null || tag.length < 12) return null;
  var code = 0;
  for (final i in const [0, 1, 2, 3, 4, 7, 8, 11]) {
    code = (code << 7) | (tag.codeUnitAt(i) & 0x7f);
  }
  return code;
}
