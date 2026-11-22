# Formát rhyme packu

Pack je soubor SQLite `<lang>.rpack`, jen pro čtení. Vzniká jen nástrojem
`dart run rymo_core:build_pack` (fonémy a klíče počítá `rymo_core`, nikdy pipeline).
Schéma je v `packages/rymo_core/lib/src/pack/schema.dart` (`packSchemaVersion = 1`).

## Tabulky

| Tabulka | Obsah |
|---|---|
| `meta` | `schema`, `lang`, `profile`, `version`, `built_at`, `sources_json`, `attribution`, `levers` |
| `fam` | rodiny rýmů: `lvl` 1 = `f1`, 2 = `f2`, 3 = `as2`; `loose_id` = nejmenší id rodiny téže úrovně se stejným `fold(key)` |
| `word` | tvar, fonémy, slabiky, `freq` (na miliardu tokenů), `lemma` (číslo), `gram` (kód poziční značky), odkazy na rodiny |
| `pair` | doložené páry v obou směrech: `n` výskytů, `authors` různých autorů |
| `cite` | citace párů (`a < b`, `k` = 0..1): dva verše, autor, dílo, rok |
| `exc` | výjimky G2P `form → phon` |

Indexy: `word_f1`, `word_f2` (a volitelně `word_as`) podle `(rodina, freq DESC)`, `fam_loose`.

## Zip

`<lang>-v<N>.zip` obsahuje `<lang>.rpack`, `manifest.json` (schema, lang, version,
sha256 a velikost packu, zdroje s licencemi) a `ATTRIBUTION.md`. `catalog.json`
v repu `rymomat-packs` drží URL release assetu, sha256 a velikost zipu.

Aplikace přibalený zip při prvním spuštění rozbalí do `<support>/packs/<lang>/`
a ověří sha256 packu proti manifestu.
