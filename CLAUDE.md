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
```

## Mapa
- `packages/rymo_core/` — čistý Dart: G2P (`lib/src/phon`), klíče a klasifikace (`lib/src/rhyme`),
  pack SQLite (`lib/src/pack`), `suggest.dart`, `engine.dart`; nástroje v `bin/`.
- `pipeline/` — Go: `cmd/rymo`, `internal/{kcv,norm,lexicon,pairs,release,sources}`, `sources.yaml`,
  `data/exc_cs.tsv` (výjimky G2P), `testdata/kcv` (3 zkrácené knihy KČV).
- `work/` — gitignorovaná data pipeline (raw korpusy, norm, `cs/*.tsv`, `cs.rpack`, release).
- `run/` — gitignorované binárky a logy.
- `docs/` — `M*_REPORT.md`, `eval_cs.md`.
- `Prompts/` — plán a referenční Python prototyp G2P.

## Invarianty
- Fonémy a klíče počítá jen `rymo_core` (R2). Go pipeline fonémy nepočítá.
- `Prompts/cs_g2p_prototype.py` je referenční: při rozporu s textem plánu platí prototyp.
- Změna schématu packu = zvýšit `packSchemaVersion` v `lib/src/pack/schema.dart`.
- Licenční brána: `rymo release` odmítne zdroj `nc`/`unknown` (bez `--research`).
- Citace jen z autorů s `death_year + 70 < rok`; verše ≤ 80 znaků.
- Testy nestahují nic ze sítě; fixtures jen volná díla (Mácha, Erben).
- Pack se vydává pod CC BY-SA 4.0 s `ATTRIBUTION.md`.

## Kam dál
Plán a milníky: `Prompts/00-RYMOMAT_PLAN.md`. Stav M0: `docs/M0_REPORT.md`.
