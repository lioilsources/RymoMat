# M0 — spike enginu a dat: zpráva

Stav 2026-11-22. Všechna čísla z `rymo eval cs` (plné tabulky v [eval_cs.md](eval_cs.md)),
stroj: Mac (Apple Silicon, 8 jader), Dart 3.12, Go 1.26.

## Brána M0

| # | Kritérium | Výsledek | |
|---|---|---|---|
| 1a | vektory §6.2, počty slabik, tabulka klasifikace | 28/28 G2P, 17/17 slabik, 20/20 klasifikace (`dart test`, 75 testů) | ✅ |
| 1b | shoda `f1` s přepisem KČV ≥ 97 % (20 000 slov) | **99,66 %** (19 931 / 19 998; 2 slova přeskočena — bez jádra) | ✅ |
| 2 | doložené páry jako `full`…`loose` ≥ 85 % | **96,41 %** párů, **97,94 %** výskytů | ✅ |
| 3 | rozpočet cs packu (zip ≤ 25 MB, rozbalený ≤ 80 MB) | zip **22,2 MB**, rozbalený **50,3 MB** — použity páky 1–3 (níže) | ✅ |
| 4 | `suggest` p95 ≤ 5 ms na 1 000 slov | **2,56 ms** přímo, **2,70 ms** přes izolát `RhymeEngine` (p50 1,2 ms) | ✅ |
| 5 | licence frekvenčních seznamů, `sources.yaml` s `license_class` | FrequencyWords: obsah CC BY-SA 4.0 → `by-sa`; registr v `pipeline/sources.yaml` | ✅ |

## Data

- KČV: 1 305 knih → **63 612 básní** po deduplikaci přesných reedic (2 816 vyřazeno), 2,26 mil. veršů.
  Index rýmu platí **pro báseň** (číslování pokračuje přes sloky, `null` = bez rýmu).
  Deduplikace podle hashe písmen nesloučí reedice s pravopisnou změnou (Máj 0675/0676: „amaranth“ × „amarant“).
- Doložené páry: 403 073 různých dvojic, 999 547 výskytů; kandidáti citací 600 733
  (jen autoři zemřelí ≤ 1955, verše ≤ 80 znaků).
- Lexikon: 234 385 tvarů (KČV s četností ≥ 2 + FrequencyWords cs 50k), v packu 277 051 slov
  (navíc slova z párů). `freq` = výskyty na miliardu tokenů, větší z obou zdrojů.

## Rozpočet a páky (§7)

| Varianta | rozbalený pack |
|---|---|
| bez pák | 110,3 MB (citace 67 MB, slova 14 MB, páry 12 MB) |
| 1: bez indexu `word_as` | 106,5 MB |
| 1 + 2: max 30 partnerů na slovo | 104,6 MB |
| 1 + 2 + 3: max 100 000 citací | **50,3 MB** (zip 22,2 MB) |

Páka 4 (ořez slov podle frekvence) nebyla potřeba. Citace dostávají přednost nejčastěji doložené páry.
Bez indexu `word_as` jde asonance přes plný průchod tabulkou — změřit, až bude asonance v UI (M2).
Páky jsou výchozí pro `rymo pack cs` (`packLevers` v `pipeline/cmd/rymo/main.go`).

## Zbytek doložených párů (3,6 %)

| Typ | výskyty | příklad |
|---|---|---|
| otevřený konec, stejné jádro, jiná opěrná souhláska | 10 915 | dá/má, jsou/svou, má/tvá |
| asonance | 7 656 | větší/řečí, poesie/žije |
| zavřený konec, stejné jádro, jiná koda | 1 804 | jest/zvěsť, loď/pojď |
| jiné jádro (oční rým, chyba anotace) | 730 | dům/museum, neví/revue |
| přejatá slova (chyby G2P) | 131 | watteau/zlato, waterloo/zlo |
| ostatní (otevřený × zavřený, slovo bez jádra) | 217 | musset/se, k/čeká |

**Hlavní nález:** 1,1 % výskytů tvoří jednoslabičné otevřené konce bez společné opěrné souhlásky
(`dá/má`). Podle §6.3 jsou `none`, básníci 19. století je ale rýmovali běžně. Viz otázka níže.

## Tabulka výjimek

Neshody golden testu (58 tvarů, hlavně `-ie/-ií` → `-ije/-ijí`: melodie, Francie, poesie)
jsou v `pipeline/data/exc_cs.tsv` jako první tabulka `exc`. Golden test se měří **bez** výjimek,
aby čísla ukazovala samotná pravidla. Systematické `i + samohláska → ij` by šlo řešit pravidlem
místo výjimek, ale plán ho nedefinuje.

## Odchylky od plánu

- `suggest`: uvnitř vrstvy se nejdřív řadí podle levelu (vrstvy a) a d) mají víc levelů),
  pak podle §6.5 (gramatické na konec → `common` → `freq`).
- `Suggestion.prefixIgnored` = příznak z §6.5 bod 3 (prefix nic nenašel a byl ignorován).
- Asonance se nabízí jen s `SuggestQuery.assonance: true` (u doložených párů i bez něj, pokud
  `minLevel` dovolí).
- Pro klíče mimo pack hledá volná rodina varianty délek samohlásek (žádná změna schématu).
- `classify.dart` je součástí `profile.dart` (`CzechProfile.classify`).
- `gram` = 8 pozic poziční značky (slovní druh, poddruh, rod, číslo, pád, osoba, čas, slovesný rod)
  po 7 bitech v jednom čísle; `lemma` = pořadové číslo lemmatu v packu.

## Otázky pro Ol1na

1. **`dá/má`**: počítat otevřené jednoslabičné konce se stejnou samohláskou jako `loose`
   (nebo nový level)? Zvedlo by to pokrytí o ~1 % a hlavně nabídky na `má`, `já`, `jsou`.
2. **`-ie → -ije`**: nechat výjimky, nebo přidat pravidlo `i + samohláska → ij` (změna §6.2 a prototypu)?
3. Otázky z §15 plánu platí dál (název, bundle id, souhlas básníka, …).

## Jak to zopakovat

```
cd pipeline && go build -o ../run/rymo ./cmd/rymo && cd ..
run/rymo fetch kcv && run/rymo fetch freqwords-cs
run/rymo normalize kcv && run/rymo lexicon cs && run/rymo pairs cs
run/rymo pack cs && run/rymo eval cs && run/rymo release cs
```

## Rozhodnutí Ol1na (2026-11-24)

1. **`dá/má` = `loose`.** Otevřené jednoslabičné konce se stejnou samohláskou (bez ohledu na délku)
   a jinou opěrnou souhláskou jsou volný rým. `CzechProfile.classify` i prototyp; `suggest` je
   nabízí ve vrstvě d) (sonduje rodiny `souhláska + samohláska`).
2. **Pravidlo `i + samohláska → ij`** v G2P (souhláska + `i/í` + samohláska kromě `i y ý`):
   `melodie → meloDije`, `marií → marijI`, ale `melodii → meloDii` (tak přepisuje KČV).
   Golden test 99,66 % → **99,91 %**; tabulka výjimek 58 → 19 tvarů (zbyla cizí slova).
   Doložené páry rozpoznané jako rým 96,4 % → **96,8 %** (výskyty 98,3 %).
3. Licence kódu **MIT** (`LICENSE`); pack dál CC BY-SA 4.0.
4. Otázky z §15: platí doporučené varianty plánu (název RymoMat, písně mimo, export A+B, …).
