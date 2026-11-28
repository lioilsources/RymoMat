# RymoMat

<!-- Max 80 řádků. Veřejné repo: žádné LAN IP, domovské cesty, ID, tokeny. -->

## Účel
Mobilní editor básní, který při psaní nabízí rýmy: fonetický slovník rýmů + doložené rýmy
z korpusů volných děl. Offline, bez účtu. Plán: `Prompts/00-RYMOMAT_PLAN.md`.

## Build a test
```
cd packages/rymo_core && dart format . && dart analyze --fatal-infos && dart test
cd pipeline && gofmt -l . && go vet ./... && go test ./...
cd pipeline && go build -o ../run/rymo ./cmd/rymo     # CLI pipeline, spouštěj z kořene repa
run/rymo fetch kcv | normalize kcv | lexicon cs | pairs cs | pack cs | eval cs | release cs
cd packages/rymo_core && dart run rymo_core:rhymes --cite láska
cd packages/rymo_editor && flutter analyze --no-fatal-infos && flutter test
cd app && flutter analyze --no-fatal-infos && flutter test      # pack: cp work/release/cs-v1.zip app/assets/packs/
cd app && flutter test integration_test -d <simulátor>          # celý tok s reálným packem
```

## Mapa
- `packages/rymo_core/` — čistý Dart: G2P (`lib/src/phon`), klíče a klasifikace (`lib/src/rhyme`),
  pack SQLite (`lib/src/pack`), `suggest.dart`, `engine.dart`; nástroje v `bin/`.
- `packages/rymo_editor/` — Flutter: `RhymeEditingController`, `RhymeTextField`, `RhymeBar`,
  `RhymeSheet`, volný režim (`verse_text.dart`); texty dodává aplikace (`RhymeEditorLabels`).
- `app/` — Flutter aplikace (Riverpod), `com.ol1n.rymomat`; l10n v `lib/l10n/*.arb`,
  sbírky v `storage/`, rozbalení packu v `packs/`.
- `pipeline/` — Go: `cmd/rymo`, `internal/{kcv,norm,lexicon,pairs,release,sources}`, `sources.yaml`,
  `data/exc_cs.tsv` (výjimky G2P), `testdata/kcv` (3 zkrácené knihy KČV).
- `work/` — gitignorovaná data pipeline (raw korpusy, norm, `cs/*.tsv`, `cs.rpack`, release).
- `run/` — gitignorované binárky a logy.
- `docs/` — `M*_REPORT.md`, `eval_cs.md`, `PACK_FORMAT.md`, `release.md`; GitHub Pages
  (`index.html`, `privacy.html`, `support.html`).
- `Prompts/` — plán a referenční Python prototyp G2P.

## Invarianty
- Fonémy a klíče počítá jen `rymo_core` (R2). Go pipeline fonémy nepočítá.
- `Prompts/cs_g2p_prototype.py` je referenční: při rozporu s textem plánu platí prototyp.
- Změna schématu packu = zvýšit `packSchemaVersion` v `lib/src/pack/schema.dart`.
- Licenční brána: `rymo release` odmítne zdroj `nc`/`unknown` (bez `--research`).
- Citace jen z autorů s `death_year + 70 < rok`; verše ≤ 80 znaků.
- Testy nestahují nic ze sítě; fixtures jen volná díla (Mácha, Erben).
- Pack se vydává pod CC BY-SA 4.0 s `ATTRIBUTION.md`.
- Sbírky = YAML PoetryStreamu (`Notebook` v rymo_core); PoetryStream čte `title`, `poems[].title|author|text`.
- Release workflowy jsou z repa Distribution; opravy patří tam. Odchylka: monorepo joby v `ci.yml`,
  stažení packu z `rymomat-packs` v `release-*.yml`.

## Kam dál
Plán a milníky: `Prompts/00-RYMOMAT_PLAN.md`. Stav: `docs/M0_REPORT.md`, `docs/M1_REPORT.md`. Release: `docs/release.md`.
