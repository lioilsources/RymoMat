# RymoMat

Editor básní, který při psaní nabízí rýmy. Rýmy hledá podle **výslovnosti**, ne podle písmen,
a k nim ukazuje **doložené rýmy** — dvojice, které skuteční básníci zrýmovali, s ukázkou veršů.
Běží offline, bez účtu a bez sledování. První jazyk: čeština.

Stav: **M0** (engine a data, bez UI) — viz [docs/M0_REPORT.md](docs/M0_REPORT.md).

## Jak to funguje

Slovo se pravidly převede na fonémy (`led` → `let`, `oběd` → `objet`), z konce se vezme
rýmový klíč a slova se stejným klíčem tvoří rodinu rýmů. Návrh = jeden indexový dotaz do
rhyme packu (SQLite), proto stíhá psaní (p95 pod 3 ms).

```
$ dart run rymo_core:rhymes noc
[masc] moc·371  pomoc·135  čaromoc·15  velkonoc·1 …
```

## Složky

| Složka | Co |
|---|---|
| `packages/rymo_core` | engine v čistém Dartu (G2P, klíče, pack, `RhymeEngine`) |
| `pipeline` | Go nástroj `rymo`: stažení a normalizace korpusů, lexikon, páry, release |
| `docs` | zprávy z milníků a evaluace |
| `Prompts` | plán projektu a referenční prototyp |

## Sestavení packu

Potřeba: Go 1.26+, Dart 3.10+, git, ~5 GB místa pro korpus.

```
cd pipeline && go build -o ../run/rymo ./cmd/rymo && cd ..
run/rymo fetch kcv && run/rymo fetch freqwords-cs
run/rymo normalize kcv && run/rymo lexicon cs && run/rymo pairs cs
run/rymo pack cs && run/rymo eval cs && run/rymo release cs
```

## Data a licence

Rhyme pack je odvozený z Korpusu českého verše (Ústav pro českou literaturu AV ČR, CC BY-SA 4.0)
a frekvenčního seznamu FrequencyWords (CC BY-SA 4.0), proto se šíří pod **CC BY-SA 4.0**
s atribucí v `ATTRIBUTION.md`. Citace:

- Plecháč, P. – Kolár, R. (2015): The Corpus of Czech Verse. *Studia Metrica et Poetica* 2(1), 107–118.
- Plecháč, P. (2016): Czech Verse Processing System KVĚTA – Phonetic and Metrical Components. *Glottotheory* 7(2), 159–174.
