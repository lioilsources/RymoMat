# RYMOMAT_PLAN.md — handoff pro Opus (Claude Code)

Stav: plán, 2026-11-22. Ulož do nového repa jako `Prompts/00-RYMOMAT_PLAN.md`.
Jazyk: komunikace a dokumentace česky, identifikátory a komentáře v kódu anglicky.

## 0. Jak s plánem pracovat

- Milníky dělej v pořadí M0 → M5. Každý končí **bránou** (měřitelná kritéria). Když brána nevyjde,
  zastav, napiš `docs/M<n>_REPORT.md` s čísly a zeptej se Ol1na — neobcházej ji.
- Nic si nedomýšlej. Co plán neurčuje, je v §15 (otevřené otázky) nebo je označeno „zjisti v discovery".
- Každá funkce je izolovaná a jde dogfoodovat sama (žádné velké PR, žádný refaktoring cizího kódu).
- Změny v repech `lioilsources/PoetryStream` a `lioilsources/Webtoon` jdou **výhradně přes PR**
  z vlastní větve, nikdy přímo.
- `CLAUDE.md` nového repa: max 80 řádků, veřejné repo → žádné LAN IP, domovské cesty, ID, tokeny.

## 1. Co stavíme

**RymoMat** = mobilní editor na psaní básní a veršovaných textů, který **při psaní v reálném čase
nabízí rýmy**. Rýmy bere ze dvou zdrojů:

1. **slovník rýmů** — všechna slova jazyka seřazená podle fonetického zakončení (funguje i pro slovo,
   které ve slovníku není, protože výslovnost se počítá pravidly);
2. **doložené rýmy** — dvojice, které skuteční básníci v korpusech volných děl opravdu zrýmovali,
   s ukázkou obou veršů a autorem.

Běží **offline, bez účtu, bez sledování**. První uživatel: Ol1nův kamarád básník (autor sbírek
v aplikaci PoetryStreamSC). První jazyk: čeština.

Důležitý vstup z jeho textů: je to převážně **volný verš s občasným rýmem a asonancí**, psaný malými
písmeny bez interpunkce. Editor proto **nesmí vnucovat schéma** — výchozí je „volný režim" (viz §9.2).

**Mimo rozsah v1:** AI, která píše básně za autora; sociální síť a sdílení mezi uživateli; účty a
synchronizace; stahování chráněných textů písní (§2.3).

## 2. Vstupy z rešerše (ověřeno 2026-11-22)

### 2.1 Korpusy a nástroje

| Zdroj | Co dává | Licence | Použití |
|---|---|---|---|
| Korpus českého verše (KČV), `github.com/versotym/corpusCzechVerse` | 1 305 knih (z 1 689; zbytek je chráněný a v repu není), ~80 tis. básní 19.–zač. 20. stol. JSON po řádcích: text, přízvuk, **index rýmu**, metrum; slova s lemmatem, morfologickou značkou a **fonetickým přepisem** (XSAMPA + interní „phoebe") | CC BY-SA, vyžaduje uvedení ÚČL AV ČR a citaci (Plecháč–Kolár 2015, Plecháč 2016) | cs: doložené páry, citace, frekvence, golden data pro G2P |
| PoeTree 1.0.0 (Zenodo 17414036) | 11 jazyků v jednotném JSON: cs ~80k, de ~74k, en ~40k, ru ~45k, it ~40k, fr ~18k, hu ~13k, es ~9k, pt ~5k, sl ~5k, no ~3k básní | **CC BY-SA 4.0**: cs, de, en, es (část DISCO), hu, no, pt, ru, sl · **CC BY-NC-SA 4.0**: fr, it, es (část „oro") | páry + citace pro další jazyky; NC části **nepoužívat** |
| RhymeTagger, `github.com/versotym/rhymetagger` | rozpoznání rýmů v korpusu; předtrénované modely cs, de, en, es, fr, it, pt, ru, sl (starší verze i nl) | **licence v repu neuvedena**; vyžaduje eSpeak NG | jen build pipeline pro jazyky bez anotace rýmů; před použitím napsat autorům (ÚČL AV ČR, Praha) |
| eSpeak NG | fonetický přepis 100+ jazyků | **GPL v3+** | jen na build stroji, **nikdy nelinkovat do aplikace** |
| Epitran, `github.com/dmort27/epitran` | pravidlový G2P: ces, pol, deu, spa, ita, rus, ukr, hun, nld, vie; fra a por s omezenou kvalitou; angličtina vyžaduje Flite; slovenština chybí | MIT | build pipeline, lexikony ne-českých jazyků |
| CMUdict | výslovnost 134 tis. anglických slov včetně přízvuku | BSD 2-clause | lexikon en |
| WikiPron | výslovnosti vytěžené z Wikislovníku (2,5 mil. párů slovo–výslovnost) | nástroj Apache 2.0; data mají licenci Wikislovníku | doplněk lexikonů (fr, pt, …) |
| MorfFlex CZ | český morfologický slovník | **CC BY-NC-SA 4.0** (komerční licence na vyžádání) | **nepoužívat** bez komerční licence |
| EduPo (ÚFAL), `github.com/ufal/edupo` | generování české poezie, složka `rhyming` | MIT | inspirace / případné převzetí kódu po prostudování |
| vlastní texty básníka | 4 sbírky, 48 básní v YAML (`PoetryStream/poetry_stream/assets/poems/`) | autorské, jen s jeho souhlasem | osobní korpus, zůstává na zařízení |

### 2.2 Co z licencí plyne (není to právní rada — před placenou distribucí ověřit u právníka)

- Rhyme pack odvozený z CC BY-SA dat je odvozené dílo → **pack vydáváme pod CC BY-SA 4.0**, veřejně,
  s atribucí (`ATTRIBUTION.md` v packu + obrazovka „O datech" v aplikaci). Kód aplikace je samostatný.
- Zpeněžujeme **funkce aplikace**, ne data (§15).
- Pipeline má **licenční bránu**: zdroj s `license_class: nc | unknown` se do release packu nedostane.
- Citovat celé verše smíme jen z volných děl: `death_year + 70 < aktuální rok` (v roce 2026 autoři
  zemřelí 1955 a dříve) nebo z dat, jejichž licence to dovoluje.

### 2.3 Texty písní („lyrics")

Texty písní jsou až na staré výjimky chráněné a weby je zobrazují na licenci od vydavatelů. Česká
výjimka pro vytěžování textů a dat (§ 39c AZ) sice dovoluje pořizovat rozmnoženiny pro automatickou
analýzu i komerčně, ale nositel práv ji může strojově čitelnou výhradou vyloučit a výjimka nepokrývá
zveřejnění původního textu. **Rozhodnutí pro v1: žádné chráněné texty písní.** Zdroje „písňového"
typu jsou jen volné lidové písně a říkadla (Wikizdroje) a vlastní texty uživatele. Varianta „ukládat
jen statistiku rýmových dvojic bez textů" je možná až po právním posouzení (§15, otázka 3).

### 2.4 Konkurence (proč to má smysl)

- rymovac.cz páruje podle posledních N **písmen**, ne podle výslovnosti; má webový editor a komunitu.
- RhymeZone a Rhymer's Block jsou anglické; Rhymebook má i české stránky rýmů, ale je to nástroj pro
  textaře písní (nahrávání dem, sdílení hudby).
- Mezera: **fonetický** český rýmovník s doloženými rýmy od básníků, offline, přímo v editoru.

## 3. Princip

```
 ZDROJE               PIPELINE (build stroj, Go + Dart + Python)            ZAŘÍZENÍ (Flutter, offline)
 KČV / PoeTree  ─┐   fetch → normalize ─┬→ lexikon (slovo, frekvence)  ─┐
 Wikizdroje     ─┼→                     └→ páry + citace (kdo co zrýmoval)├→ build_pack → cs.rpack ─→ rymo_core
 frekvenční     ─┘                                                      ─┘   (SQLite: slova,         │
 seznamy                                                                      rodiny, páry, citace)   ▼
                                                                                              editor: konec verše
 vlastní básně (YAML) ───────────────── import v aplikaci ────────────────→ osobní index ──→  → fonetický klíč
                                                                                              → rodina rýmů → čipy
```

Jádro je **fonetický klíč konce verše**. Slovo se převede na fonémy, z nich se vezme zakončení od
poslední (a předposlední) slabiky; slova se stejným zakončením tvoří **rodinu rýmů**. Návrh rýmu =
dotaz na rodinu seřazený podle doložených párů a frekvence. Hledání je jeden indexový dotaz, proto
stíhá psaní.

## 4. Rozhodnutí

| # | Rozhodnutí | Důvod |
|---|---|---|
| R1 | **Package-first**: `rymo_core` (čistý Dart) + `rymo_editor` (Flutter widgety) + tenká aplikace | stejný engine a pole jdou vložit do PoetryStreamSC i Toonforku |
| R2 | **Jediná implementace fonetiky a klíčů je `rymo_core`**; pack staví Dart nástroj ze stejného balíčku | klíč v packu a klíč spočítaný na zařízení se nesmí rozejít |
| R3 | Pipeline (fetch, normalizace, páry, katalog) v **Go**; Python jen pro RhymeTagger/Epitran (M3+) | Ol1nův stack; žádný bash |
| R4 | Pack = **SQLite** soubor, jen pro čtení, stahuje se jako obsahový balíček | indexové dotazy, snadné ladění; vzor z Webtoon `PACK_FORMAT.md` |
| R5 | Čeština: výslovnost **pravidly na zařízení**; ostatní jazyky: lexikon v packu + odhad podle přípony | čeština je téměř fonetická; angličtina ne |
| R6 | Úložiště básní = **YAML sbírka ve formátu PoetryStreamu** | export do PoetryStreamSC je pak kopie souboru |
| R7 | Žádný backend ve v1; jediná síť = stažení packu z GitHub Releases | offline, bez účtu, bez sledování |
| R8 | LLM jen jako volitelný doplněk v M5 a vždy **ověřený enginem** | jazykové modely bez fonetické reprezentace rýmy poznávají špatně |

## 5. Repo a balíčky

Nové veřejné repo `lioilsources/RymoMat`:

```
CLAUDE.md  README.md  Prompts/00-RYMOMAT_PLAN.md
packages/rymo_core/      # čistý Dart, sdk ^3.10.0 (musí jít do PoetryStreamu ^3.10.7 i Webtoonu ^3.12.2)
  lib/src/phon/          # cs_g2p.dart, phoneme sets, lexicon_phonemizer.dart
  lib/src/rhyme/         # profile.dart, keys.dart, classify.dart, analysis.dart
  lib/src/pack/          # pack_reader.dart (sqlite3), schema.dart, pack_writer.dart
  lib/src/engine.dart    # RhymeEngine (veřejné API)
  bin/build_pack.dart    # lexicon.tsv + pairs.tsv + cites.tsv → *.rpack
  bin/rhymes.dart        # CLI: dart run rymo_core:rhymes <slovo>
  test/  testdata/       # golden TSV
packages/rymo_editor/    # Flutter: RhymeTextField, RhymeEditingController, RhymeBar, RhymeSheet
app/                     # Flutter aplikace (Riverpod), iOS + Android
pipeline/                # Go modul, cmd/rymo (fetch | normalize | lexicon | pairs | release | eval)
pipeline/py/             # M3+: rhymetagger_tag.py, g2p_lexicon.py (requirements.txt)
pipeline/sources.yaml    # registr zdrojů včetně licencí
docs/                    # M*_REPORT.md, PACK_FORMAT.md, GitHub Pages
```

Packy se vydávají do samostatného veřejného repa `lioilsources/rymomat-packs` (GitHub Releases +
`catalog.json`), licence CC BY-SA 4.0.

Testovací fixtures jsou jen volná díla (Mácha, Erben). Texty žijícího autora do testů nepatří.

## 6. `rymo_core` — specifikace

### 6.1 Fonémy

Každý foném je **jeden ASCII znak**, řetězec fonémů je obyčejný `String`. Čeština:

- krátké samohlásky `a e i o u`, dlouhé `A E I O U`, dvojhlásky `W`=ou, `Y`=au, `Q`=eu
- souhlásky `p b t d T(ť) D(ď) k g f v s z S(š) Z(ž) x(ch) h c C(č) 3(dz) 4(dž) m n N(ň) l r R(ř) j`
- slabičné souhlásky určuje funkce `isNucleus(phon, i)`, ne zvláštní znak: `r` a `l` jsou **jádrem
  slabiky**, když před nimi stojí souhláska a za nimi nenásleduje samohláska (`vlk`, `krk`, `nesl`,
  `zrno`, `jablko`; ne `rty`, `lhát`, `sklo`); `m` jen na konci slova po souhlásce (`sedm`, `osm`).

### 6.2 Český G2P (`CzechG2P.toPhonemes(String word, {bool beforePause = true})`)

Vstup: malá písmena, pryč vše kromě písmen. Pravidla v tomto pořadí (pořadí je závazné):

1. Výjimky: tabulka `form → phon` z packu (`exc`), má přednost (přejatá slova, švy jako `po|učit`).
2. Průchod zleva doprava po grafémech:
   - spřežky `ch`→x, `dž`→4, `dz`→3, `ou`→W, `au`→Y, `eu`→Q; `q`→kv, `w`→v, `x`→ks;
   - `ě`: po `d t n` změkčí předchozí souhlásku a dá e (`dě`→De); po `b p v f` vloží j (`bě`→bje);
     po `m` dá Ne (`mě`→mNe);
   - **psané** `i`, `í` po `d t n` změkčí předchozí souhlásku na `D T N`; psané `y`, `ý` nikdy
     (`dým`→dIm, `ticho`→Tixo, `tykev`→tikef). Tvrdé `di ti ni` v přejatých slovech řeší jen výjimky;
   - teprve potom `y`→i, `ý`→I, `á é í ó`→`A E I O`, `ú ů`→U a písmena s háčkem podle tabulky v §6.1.
3. Zdvojené souhlásky zjednodušit (`kk`→k, `nn`→n).
4. `sh` → sx.
5. Při `beforePause` (konec verše): koncová znělá párová souhláska ztrácí znělost (`led`→let).
6. Asimilace znělosti jedním průchodem **zprava doleva** přes sousední párové souhlásky; páry b/p, d/t,
   D/T, g/k, v/f, z/s, Z/S, h/x, 3/c, 4/C. Neznělá vpravo odznělí levou (`vstát`→fstAt,
   `hvozd`→hvost); znělá vpravo zezní levou (`kdo`→gdo), **kromě `v`**, které se přizpůsobuje, ale samo
   znělost nevynucuje (`svět`→svjet). Sonory `m n N l r j` a `R` asimilaci nespouštějí.

Povinné testovací vektory (`testdata/cs_g2p.tsv`):
`led`→let, `hrad`→hrat, `hvozd`→hvost, `sníh`→sNIx, `hřích`→hRIx, `oběd`→objet, `město`→mNesto,
`dítě`→DITe, `děti`→DeTi, `chata`→xata, `kdo`→gdo, `vstát`→fstAt, `sbor`→zbor, `shoda`→sxoda,
`tužka`→tuSka, `zpěv`→spjef, `mouka`→mWka, `taxi`→taksi, `být`→bIt, `bít`→bIt, `vůz`→vUs, `krk`→krk,
`dým`→dIm, `ticho`→Tixo, `tykev`→tikef, `lev`→lef, `svět`→svjet, `mráz`→mrAs.

Počty slabik: `vlk` 1, `krk` 1, `nesl` 2, `sedm` 2, `rty` 1, `lhát` 1, `mnoho` 2, `zrno` 2, `jablko` 3,
`mlha` 2, `sklo` 1, `hrdlo` 2, `vítr` 2.

**Referenční prototyp** `Prompts/cs_g2p_prototype.py` (přiložen k plánu) implementuje §6.2–§6.3 a
všechny uvedené vektory, počty slabik i tabulku klasifikace jím prochází. Dart implementace se s ním
musí shodnout; při rozporu textu a prototypu platí prototyp.

**Golden test proti KČV**: na 20 000 náhodných posledních slovech veršů porovnej klíč `f1` (§6.3)
spočítaný z našeho G2P s klíčem spočítaným z přepisu v KČV (napiš převodník XSAMPA → naše znaky).
Neshody vypiš seřazené podle četnosti do `docs/M0_REPORT.md`; z nich vznikne první tabulka výjimek.

### 6.3 Klíče a rodiny rýmů (profil `cs`)

Pro fonémy `p[0..n-1]` a seznam jader `N`:

- bez jádra (předložky `k s v z`) → slovo nemá klíče a samo se nerýmuje;
- `open` = za posledním jádrem není žádná souhláska;
- **f1** (minimální klíč): zavřená slabika → od posledního jádra do konce (`hrat`→`at`);
  otevřená → opěrná souhláska + jádro (`voda`→`da`), bez opěrné souhlásky jen jádro;
- **f2** (dvouslabičný klíč): od předposledního jádra do konce (`lAska`→`Aska`), jinak `null`;
- **as2** (asonance): samohlásky posledních dvou jader po `fold` (`lAska`→`aa`), jinak `null`;
- `fold` = volná shoda: dlouhá samohláska → krátká. Volná rodina = skupina přesných rodin se stejným
  `fold(key)`;
- `syl` = počet jader.

Klasifikace dvojice konců A, B (`RhymeLevel`, od nejsilnější):

| Level | Podmínka | Příklad |
|---|---|---|
| `identical` | stejné fonémy | být / bít, led / let — ukázat jen při různém pravopisu, označit „homofonum" |
| `full` | shodné `f2` | láska / páska, voda / svoboda |
| `masc` | shodné `f1`, zavřené; nebo otevřené a obě slova jednoslabičná | hrad / sad, hvozd / most |
| `weak` | shodné `f1`, otevřené, aspoň jedno slovo víceslabičné | voda / věda |
| `looseFull` | shodné `fold(f2)` | děti / letí |
| `loose` | shodné `fold(f1)` a stejná otevřenost | mráz / hlas |
| `assonance` | shodné `as2` | láska / dáma |
| `none` | jinak | voda / ryba |

„Bohatost" uvnitř levelu = délka společné fonémové přípony (počítá se na zařízení z `phon`).

**Gramatický rým** (stejná koncovka, stejný tvar — `chodila / nosila`): obě slova mají stejné `gram`
a shodují se v posledních 3 písmenech → příznak `grammatical`, v řazení jde na konec svého levelu.

Profil je rozhraní `RhymeProfile { isNucleus, fold, keysFor(phon), classify(a, b) }`. Pro přízvukové
jazyky (en, de, ru, es, it, pt…) v M3: `f1` = od posledního **přízvučného** jádra do konce, `f2` se
nepoužívá, `as2` = samohlásky od přízvučného jádra; příznak `openNeedsSupport` (ruština).

### 6.4 Veřejné API

```dart
class RhymeEngine {
  static Future<RhymeEngine> open(String packPath);       // read-only
  LineEnd lineEnd(String line);                            // poslední slovo, phon, klíče, syl řádku
  PoemAnalysis analyze(String text, {int window = 6, bool assonance = false});
  Future<List<Suggestion>> suggest(SuggestQuery q);        // běží na izolátu enginu
  Future<List<Citation>> citations(String wordA, String wordB);
  void close();
}
class SuggestQuery { final String target; final String prefix; final RhymeLevel minLevel;
  final int? syllables; final int limit; final Set<String> usedWords; }
class Suggestion { final String word; final RhymeLevel level; final int common; final int attested;
  final int freq; final bool grammatical; final bool used; }
class PoemAnalysis { final List<LineInfo> lines; }         // LineInfo: stanza, syl, endWord, group, letter
class Citation { final String lineA, lineB, author, work; final int? year; }
```

`analyze` nesahá do databáze (jen G2P + klíče): rýmové skupiny = union-find přes dvojice řádků
v okně `window` s levelem ≥ `loose` (při `assonance: true` i `assonance`); písmena schématu po slokách.

### 6.5 Algoritmus `suggest`

1. `end = lineEnd(target)`; pro slovo mimo lexikon se klíče spočítají pravidly (cs) nebo odhadem
   podle nejdelší shodné psané přípony se slovem v lexikonu (lexikonové jazyky).
2. Vrstvy v tomto pořadí, každá doplňuje jen dosud nenalezená slova:
   a) **doložené**: `pair WHERE a = id(target) ORDER BY n DESC LIMIT 40`;
   b) `full`: slova rodiny `f2`, `ORDER BY freq DESC LIMIT 200`;
   c) `masc`/`weak`: rodina `f1`, stejný limit;
   d) `looseFull`, `loose`: ostatní přesné rodiny se stejným `loose_id` (dotaz na každou zvlášť, sloučit);
   e) `assonance`: rodina `as2` — jen když to uživatel zapnul.
3. Filtry: vyřadit samotné slovo a tvary téhož lemmatu; `prefix` (psané písmenné začátky) — když po
   filtru nic nezbude, vrátit výsledek bez něj s příznakem; volitelně `syllables`.
4. Řazení uvnitř vrstvy: `grammatical` na konec → `common` sestupně → `freq` sestupně. `used` slova
   (už stojí na konci verše v této básni nebo sbírce) se nevyřazují, jen označí.
5. Vrátit prvních `limit` (výchozí 40). Pořadí vrstev se zachovává.

## 7. Rhyme pack (`<lang>-v<N>.rpack`, SQLite)

```sql
CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- schema, lang, profile, version, built_at, sources_json, attribution
CREATE TABLE fam(id INTEGER PRIMARY KEY, lvl INTEGER NOT NULL,      -- 1=f1, 2=f2, 3=as2
  key TEXT NOT NULL, open INTEGER NOT NULL DEFAULT 0, loose_id INTEGER NOT NULL,
  n INTEGER NOT NULL, UNIQUE(lvl, key));                            -- loose_id = id nejmenší rodiny se stejným fold(key)
CREATE TABLE word(id INTEGER PRIMARY KEY, form TEXT NOT NULL UNIQUE, phon TEXT NOT NULL,
  syl INTEGER NOT NULL, freq INTEGER NOT NULL, lemma INTEGER, gram INTEGER,
  f1 INTEGER, f2 INTEGER, as2 INTEGER);
CREATE INDEX word_f1 ON word(f1, freq DESC);
CREATE INDEX word_f2 ON word(f2, freq DESC);
CREATE INDEX word_as ON word(as2, freq DESC);
CREATE INDEX fam_loose ON fam(loose_id);
CREATE TABLE pair(a INTEGER NOT NULL, b INTEGER NOT NULL, n INTEGER NOT NULL, authors INTEGER NOT NULL,
  PRIMARY KEY(a, b)) WITHOUT ROWID;                                 -- uloženy oba směry
CREATE TABLE cite(a INTEGER NOT NULL, b INTEGER NOT NULL, k INTEGER NOT NULL,   -- a < b, k = 0..1
  line_a TEXT NOT NULL, line_b TEXT NOT NULL, author TEXT NOT NULL, work TEXT NOT NULL, year INTEGER,
  PRIMARY KEY(a, b, k)) WITHOUT ROWID;
CREATE TABLE exc(form TEXT PRIMARY KEY, phon TEXT NOT NULL) WITHOUT ROWID;      -- výjimky G2P
```

- Lexikonové jazyky navíc: `word.rform TEXT` (psaná podoba pozpátku) + index, pro odhad podle přípony.
- Zip packu obsahuje `<lang>.rpack`, `manifest.json` (schema, lang, version, sha256, velikost, zdroje
  s licencemi) a `ATTRIBUTION.md`.
- `catalog.json` v `rymomat-packs`: seznam packů s URL release assetu a sha256 — stejný princip jako
  `app/lib/shop/catalog_repository.dart` a `pack_downloader.dart` ve Webtoonu (přečti si je jako vzor,
  kód nekopíruj slepě).
- **Rozpočet** (odhad, změří M0): cs zip ≤ 25 MB, rozbalený ≤ 80 MB. Páky při překročení, v tomto
  pořadí: vypustit index `word_as` → max 30 partnerů na slovo v `pair` → max 100 tis. citací →
  odříznout slova s nejnižší frekvencí.
- Slovník cs: všechny tvary z KČV s četností ≥ 2 + moderní slovní zásoba z frekvenčního seznamu
  (kandidáti k ověření licence v M0: výtah z Wikislovníku přes kaikki.org, FrequencyWords
  z OpenSubtitles, vlastní počty z dumpu cs Wikipedie). `freq` = větší z normalizovaných četností.
  `lemma` a `gram` jsou jen u slov z KČV; `gram` = kompaktní kód slovního druhu + pádu/čísla/osoby
  z poziční značky.

## 8. Pipeline (`rymo`, Go)

`sources.yaml` — každá položka: `id, kind (git|zenodo|mediawiki|file), url, lang, license,
license_class (pd|by-sa|nc|unknown), attribution, cite_text (bool)`.

| Krok | Vstup → výstup | Poznámky |
|---|---|---|
| `rymo fetch <id>` | zdroj → `work/raw/<id>/` | idempotentní, s cache a obnovením; Wikizdroje přes MediaWiki API se slušným rate limitem a User-Agentem |
| `rymo normalize <id>` | raw → `work/norm/<id>.jsonl` (`poem_id, author, death_year, year, work, lang, license_class, stanzas[[line…]]`, u KČV i `rhyme` a slova s lemmatem a značkou) | deduplikace reedic podle hashe normalizovaného textu; přesné názvy polí KČV zjisti z README repa |
| `rymo lexicon <lang>` | norm + frekvenční seznam → `work/<lang>/lexicon.tsv` (`form, freq, lemma, gram`) | fonémy nepočítá (R2) |
| `rymo pairs <lang>` | norm → `pairs.tsv` (`a, b, n, authors`) + `cites.tsv` | KČV: páry z indexu rýmu (zjisti, zda index platí pro báseň, nebo pro sloku); ostatní jazyky: `py/rhymetagger_tag.py` (M3) |
| `dart run rymo_core:build_pack` | lexicon + pairs + cites → `.rpack` + manifest | jediné místo, kde vznikají fonémy a klíče |
| `rymo eval <lang>` | pack + norm → `docs/eval_<lang>.md` | kolik doložených párů engine klasifikuje jako `full`…`assonance`/`none`; latence dotazů |
| `rymo release <lang>` | pack → zip, sha256, `catalog.json` | licenční brána: odmítne `nc`/`unknown`, pokud není `--research` |

Citace: jen řádky do 80 znaků, nejvýš 2 na pár, přednost mají různí autoři; jen ze zdrojů
s `cite_text: true`.

## 9. Aplikace

### 9.1 Obrazovky

1. **Sbírky** → seznam básní ve sbírce → **Editor**.
2. **Rýmovník** (samostatná záložka): pole pro slovo, výsledky po levelech, filtry (počet slabik, jen
   doložené, bez gramatických), detail s citacemi.
3. **Nastavení**: jazykové packy (stažené / dostupné), volný režim × schéma, asonance ano/ne,
   velká písmena na začátku řádku (výchozí **vypnuto**), automatické opravy systému (výchozí vypnuto),
   „O datech" (atribuce a licence).

UI česky a anglicky (slovensky až s packem sk). Stav v Riverpodu jako v ostatních Ol1nových aplikacích.

### 9.2 Chování editoru (`rymo_editor`)

- `RhymeTextField` = `TextField` + `RhymeEditingController extends TextEditingController`, který
  v `buildTextSpan` obarví **poslední slovo každého verše** podle rýmové skupiny (paleta 8 barev,
  podtržení, ne změna barvy textu). Analýza se spouští 80 ms po poslední změně; zastaralé výsledky se
  zahazují podle pořadového čísla požadavku.
- **Sloka** = blok oddělený prázdným řádkem. **Aktivní verš** = řádek s kurzorem.
- **Volný režim (výchozí)**: cíle = konce předchozích veršů téže sloky (nejvýš 6, od nejbližšího);
  má-li sloka zatím méně než 2 verše, přidá se poslední verš předchozí sloky. Napřed konce, které
  ještě nemají partnera, potom zrýmované. Lišta ukáže nejvýš 3 cíle.
- **Režim schématu** (AABB, ABAB, ABBA, AABBA, vlastní řetězec písmen): cíl určuje schéma podle pořadí
  verše ve sloce; otevírá-li verš nové písmeno, lišta ukáže jen počet slabik a text „nový rým".
- **Filtr podle rozepsaného slova**: je-li kurzor na konci řádku a poslední token nekončí mezerou,
  jde jako `prefix`.
- **RhymeBar** nad klávesnicí (`Column[Expanded(editor), RhymeBar]`, scaffold se zmenšuje
  s klávesnicí): vlevo počet slabik aktivního verše; pak segmenty po cílech (barevná tečka + cílové
  slovo + čipy). Klepnutí na čip nahradí rozepsaný token (nebo vloží slovo s mezerou) a nechá kurzor
  na konci řádku. Dlouhý stisk otevře **RhymeSheet** (všechny návrhy po levelech + citace).
- Označení libovolného slova v textu → akce „Rýmy na ‚…'" → RhymeSheet.
- Sloupec s počtem slabik u každého verše až v M2 (riziko: zalomené řádky; záložní řešení = počet jen
  u aktivního verše).
- Výkon: `analyze` do 5 ms na 200 veršů; `suggest` p95 do 30 ms na běžném telefonu. Databáze se otevírá
  jen pro čtení na dlouho žijícím izolátu.

### 9.3 Úložiště a export

- Sbírka = `notebooks/<slug>.yaml` v dokumentech aplikace, **formát PoetryStreamu (mapová varianta)**:

  ```yaml
  title: Název sbírky
  rymomat: {lang: cs, schema: 1}
  poems:
  - title: "Název básně"
    text: |
      první verš
      druhý verš

      další sloka
  ```

  PoetryStream čte jen `title`, `product_id`, `poems[].title|author|text`; klíč `rymomat` ignoruje.
  `product_id` doplňuje vydavatel při zařazení mezi placené sbírky.
- Balíček `yaml` jen čte → napiš **vlastní zapisovač** pro toto pevné schéma (název v uvozovkách
  s escapováním, text jako blok `|`, ořez koncových mezer; začíná-li text mezerou, použij explicitní
  indikátor odsazení). Test: zápis → `loadYaml` → shoda, včetně prázdných řádků mezi slokami.
- Vedle YAML `notebooks/<slug>.meta.json`: režim a schéma po básních, historie verzí (posledních 20
  snímků každé básně; snímek při odchodu z editoru, pokud se text změnil).
- Export: sdílení `.yaml` (sbírka) a `.txt` (báseň) přes systémový dialog. Import: `.yaml` ve formátu
  PoetryStreamu (obě varianty — seznam i mapa s `poems`) a prostý text.
- **Osobní index**: z konců veršů všech básní v zařízení se drží tabulka „moje rýmy" (slovo → počet
  použití, partneři). Z ní příznak `used` a přehled „nejčastější vlastní rýmy". Nikdy neopouští zařízení.

## 10. Integrace

### 10.1 PoetryStreamSC (repo `lioilsources/PoetryStream`, balíček `com.ab.PoetryStreamSC`, „Poesie Simona Clinae")

Zjištěno v kódu: básně jsou YAML v `poetry_stream/assets/poems/` (bezplatný `default.yaml` jako seznam,
placené sbírky jako mapa s `product_id`, `title`, `poems`); sloky dělí prázdný řádek
(`core/utils/stanza_parser.dart`); uživatelské básně už existují (`collectionId == 'user'`, Hive box
`poems`, `addUserPoem`) a vkládají se přes `PastePoemButton`, který je vypnutý příznakem
`BuildConfig.showPastePoem` (`--dart-define=SHOW_PASTE_POEM=true`).

| Úroveň | Co | Kdy | Cena |
|---|---|---|---|
| A — formát | sbírka z RymoMatu je platný soubor pro `assets/poems/` | M1, zadarmo díky R6 | 0 změn v PoetryStreamu |
| B — osobní korpus | import 4 existujících sbírek do RymoMatu → „moje rýmy", `used` | M2 | jen se souhlasem autora |
| C — vložený editor | v `_PastePoemSheet` nahradit `TextField` za `RhymeTextField` (git závislost na `rymo_editor`), pack stahovat až na vyžádání | M3, volitelné | PR do PoetryStreamu; přidá sqlite a desítky MB dat do meditativní čtečky |

Doporučení: A + B určitě; C až podle zkušenosti básníka s M1 (§15, otázka 4).

### 10.2 Toonfork (repo `lioilsources/Webtoon`, aplikace „Toonfork")

Zjištěno v kódu: všechna textová pole jsou obyčejné `TextField`y — úprava bubliny
(`app/lib/reader/bubble_edit_dialog.dart`, max 300 znaků, druhy řeč/myšlenka/výkřik/vypravěč), editor
větví čtenáře (`app/lib/gamebook/branch_editor_screen.dart`, `_BubblesDialog` až 3 bubliny na obrázek,
texty voleb) a autorský editor grafu (`app/lib/author/gamebook_editor_screen.dart`). Bubliny jsou
overlay (změna textu nepřekresluje obrázek) a mají strojové překlady `i18n` do 11 jazyků, které se po
úpravě generují znovu. Scénáře jsou volný text (`data/scripts/**.md`: nadpis, POSTAVY, SCÉNA n, repliky),
který `m0/adapt.py` se skillem `storyboard-writer` převádí na storyboard.

| Možnost | Co | Poznámka |
|---|---|---|
| T1 — rýmy v bublinách | `RhymeTextField` v `_BubbleEditDialog` a `_BubblesDialog`; kontext rýmu = předchozí bubliny téhož panelu a dílu (parametr `contextLines`) | veršované gamebooky pro děti; malá změna, PR do Webtoonu |
| T2 — báseň → webtoon | export básně jako scénář `.md`: sloka = scéna, verše = repliky vypravěče, k tomu jednořádkový popis obrazu od autora | naplňuje dávný záměr „obrázkovatelnosti" PoetryStreamu |
| T3 — kontrola rýmu v pipeline | `dart run rymo_core:check` jako validátor veršovaného storyboardu z LLM | až bude veršovaný obsah vznikat strojově |

**Omezení:** rým nepřežije strojový překlad. Veršovaný obsah je proto jednojazyčný (v ostatních
jazycích prozaický překlad), dokud nevznikne překlad ověřovaný enginem pro cílový jazyk.

Verdikt: obojí je proveditelné a levné **díky R1**; pořadí je RymoMat samostatně → PoetryStreamSC (A, B)
→ Toonfork T1 → T2.

## 11. Jazyky

Jazyk potřebuje tři věci: výslovnost (pravidla nebo slovník), definici rýmu (profil) a korpus
s použitelnou licencí pro doložené páry.

| Stupeň | Jazyky | Stav |
|---|---|---|
| 1 — slovník + doložené páry | **cs** (KČV, rýmy už anotované), **de, en, ru, pt, sl**, es (jen část DISCO), **hu, no** | korpusy CC BY-SA v PoeTree; páry přes RhymeTagger (kromě cs); pro hu a no předtrénovaný model není, musel by se natrénovat |
| 2 — slovník hned, páry až s jiným korpusem | **fr, it** | PoeTree části jsou nekomerční → páry z volných textů (Wikizdroje, Gutenberg) nebo dohoda s držiteli |
| 3 — jen slovník | **sk, pl, uk, nl** a další s pravidlovým G2P nebo výslovnostmi ve Wikislovníku | korpus by se musel poskládat z Wikizdrojů a model natrénovat |
| 4 — jiné pojetí rýmu | **vi** (rým slabiky + třída tónu; jde pravidly), **ja, ko** (koncový rým není tradiční prostředek; jen shoda samohlásek pro rap), zh, ar, he | mimo první rok |

Poznámky k profilům: en — od poslední přízvučné samohlásky, více výslovností na slovo; de — koncová
ztráta znělosti, „nečisté" rýmy ü/i, ö/e jako volné; ru — přízvuk není v pravopisu a nepřízvučné
samohlásky se redukují → nutný slovník s přízvukem; es/it/pt — asonance je plnohodnotný druh rýmu;
fr — nevyslovované koncovky; pl — přízvuk na předposlední slabice → převažují dvouslabičné rýmy;
hu — délka samohlásek, tolerantní tradice.

Průnik s jazyky čtečky Toonforku (cs, en, de, it, fr, pl, pt-BR, ja, ko, vi, ru, uk): reálně cs, en,
de, ru, pt (stupeň 1), fr, it (2), pl, uk (3); vi později; ja a ko ne.

## 12. Milníky

### M0 — spike enginu a dat (bez UI)

Práce: repo a kostra; `fetch kcv`, `normalize`, `lexicon cs`, `pairs cs`; `CzechG2P`; klíče a
klasifikace; `build_pack`; `PackReader`; CLI `rhymes`; `rymo eval cs`; golden test proti KČV.

**Brána M0** (`docs/M0_REPORT.md` s čísly):
1. všechny vektory z §6.2 projdou; shoda klíče `f1` s přepisem KČV ≥ 97 % (20 000 slov);
2. z doložených párů KČV engine označí ≥ 85 % jako `full`/`masc`/`weak`/`looseFull`/`loose`; zbytek
   je rozebraný podle typu (asonance, chyby G2P, chyby anotace);
3. cs pack splňuje rozpočet z §7 (nebo je popsáno, které páky byly použity);
4. `suggest` v CLI: p95 ≤ 5 ms na vzorku 1 000 slov;
5. ověřené licence frekvenčních seznamů; seznam zdrojů v `sources.yaml` s `license_class`.

### M1 — aplikace pro básníka (TestFlight / interní test)

Práce: aplikace se Sbírkami a Editorem; `RhymeTextField` + RhymeBar + RhymeSheet ve **volném režimu**;
Rýmovník; YAML úložiště, export a import; pack cs přibalený v aplikaci a rozbalený při prvním spuštění;
„O datech".

**Brána M1:** básník napíše a vyexportuje báseň; export jde bez úprav vložit do
`PoetryStream/poetry_stream/assets/poems/` a aplikace ji zobrazí (ověř lokálním buildem);
`suggest` p95 ≤ 30 ms na reálném telefonu; letecký režim od prvního spuštění funguje.
Dogfooding: Ol1n i básník, seznam výhrad do `docs/M1_FEEDBACK.md` — ten určí pořadí M2.

### M2 — analýza a osobní korpus

Obarvení rýmových skupin; počet slabik u veršů; režim schématu; asonance; import existujících sbírek;
„moje rýmy" a `used`; citace v RhymeSheetu; historie verzí.
**Brána M2:** import 4 sbírek (48 básní) bez ztráty textu; analýza 200 veršů ≤ 5 ms; žádné poskakování
textu při psaní (zalomené řádky).

### M3 — další jazyky a PoetryStreamSC

Katalog a stahování packů; `py/g2p_lexicon.py` a `py/rhymetagger_tag.py` (po vyjasnění licence
RhymeTaggeru); packy **en** (CMUdict + PoeTree.en) a **de**; `sk` jako slovník bez párů (pravidla
blízká češtině); profil pro přízvukové jazyky; volitelně úroveň C z §10.1.
**Brána M3:** pro en a de `rymo eval` + ruční kontrola 100 návrhů rodilým nebo pokročilým mluvčím;
licenční brána odmítne fr/it z PoeTree.

### M4 — Toonfork

T1 (PR do Webtoonu: `RhymeTextField` v dialozích bublin, pack na vyžádání), T2 (export básně do
scénáře). Discovery napřed: přečti `PACK_FORMAT.md`, `docs/gamebook.md`, `skills/storyboard-writer/`.
**Brána M4:** `flutter analyze --no-fatal-infos && flutter test` ve Webtoonu zelené; veršovaná větev
gamebooku napsaná v editoru větví se přehraje ve čtečce.

### M5 — volitelné

Významové řazení návrhů (malé statické vektory slov jako doplňkový pack); „dokonči verš" přes LLM na
Sparku (LiteLLM), vždy s kontrolou rýmu enginem, výslovně zapnuté uživatelem; další jazyky stupně 1
(ru, hu, pt, sl, no, es); víceslovné rýmy na konci verše; vnitřní rýmy a aliterace; karta básně jako
obrázek; vydání ve storech přes Ol1novy existující pipeline.

## 13. Testy

- `rymo_core`: jednotkové testy G2P (vektory + golden KČV), klíčů, klasifikace (tabulka z §6.3 včetně
  záporných případů), `suggest` nad malým testovacím packem sestaveným v testu; round-trip YAML.
- `rymo_editor`: widget testy — vložení čipu nahradí rozepsaný token; volba cílů ve volném režimu
  a ve schématu; zastaralý výsledek se nezobrazí.
- `pipeline`: `gofmt`, `go vet`, `go test`; normalizace KČV na vzorku 3 knih v `testdata/`;
  licenční brána (test, že `nc` zdroj shodí `release`).
- CI (GitHub Actions) po vzoru Webtoonu: brána pro `pipeline/` a brána pro Dart/Flutter balíčky.
- Testy nikdy nestahují korpusy ze sítě.

## 14. Rizika

| Riziko | Dopad | Opatření |
|---|---|---|
| Korpusy jsou z 19. a začátku 20. století; básník píše současný volný verš | doložené páry působí archaicky | slovník doplněný moderní slovní zásobou; doložené páry jako inspirace s uvedením autora a roku; osobní korpus; G2P zvládne i novotvary |
| Share-alike a atribuce (CC BY-SA) | pack musí být veřejný pod stejnou licencí | R: packy veřejně v `rymomat-packs`; zpeněžovat funkce; právník před placenou verzí |
| Nekomerční zdroje (fr, it, es-oro, MorfFlex) | nelze v komerční aplikaci | licenční brána v `rymo release` |
| RhymeTagger bez uvedené licence; závislost na eSpeak NG (GPL) | nejasné použití | čeština ho nepotřebuje; před M3 napsat autorům; eSpeak jen na build stroji |
| Přejatá slova a výjimky výslovnosti | špatné rodiny | tabulka `exc` plněná z neshod s KČV a z hlášení básníka |
| Velikost packu a paměť | pomalý start, velká aplikace | brána M0, páky v §7 |
| Lišta nad klávesnicí a zalomené řádky | rozbité UX | lišta bez sloupce slabik v M1; sloupec až v M2 se záložním řešením |
| Očekávání „AI básník" | zklamání | jasně komunikovat nástroj pro autora; LLM až M5 a vypnuté |
| Texty písní | právní riziko | mimo v1 (§2.3) |

## 15. Otevřené otázky pro Ol1na

1. **Název a účet**: „RymoMat", nebo „RýmoMat"? Bundle id a účet (A+B jako PoetryStreamSC?).
2. **Básník**: souhlasí s importem svých 48 básní jako osobního korpusu (zůstává v zařízení)? Chce
   hlavně asonance a volné rýmy, nebo i pravidelná schémata?
3. **Texty písní**: nechat mimo (doporučeno), nebo zadat právní posouzení varianty „jen statistika
   dvojic bez textů"?
4. **PoetryStreamSC**: stačí export souboru (A + B), nebo i editor uvnitř aplikace (C)?
5. **Zpeněžení**: návrh — aplikace a český pack zdarma; jednorázové odemčení „Pro" (další jazyky,
   citace, asonance, moje rýmy, historie verzí); součást Ol1n Passu. Platí?
6. **Slovenština** v M3 jako slovník bez doložených párů — ano/ne?
7. **LLM „dokonči verš"** (M5) — chceme vůbec?
8. Smí Opus napsat autorům KČV/RhymeTaggeru (ÚČL AV ČR) jménem Ol1na, nebo to udělá Ol1n sám?

## 16. Zdroje

- KČV: https://github.com/versotym/corpusCzechVerse
- PoeTree 1.0.0: https://zenodo.org/records/17414036 · knihovna: https://github.com/versotym/poetree
- RhymeTagger: https://github.com/versotym/rhymetagger · studie o velikosti trénovacích dat a srovnání
  s LLM: https://arxiv.org/abs/2604.08156
- EduPo: https://github.com/ufal/edupo
- Epitran: https://github.com/dmort27/epitran · WikiPron: https://github.com/CUNY-CL/wikipron
- CMUdict: https://github.com/cmusphinx/cmudict · eSpeak NG: https://github.com/espeak-ng/espeak-ng
- MorfFlex CZ: https://ufal.mff.cuni.cz/morfflex
- § 39c AZ (vytěžování textů a dat): https://www.epravo.cz/top/aktualne/vytezovani-verejne-dostupnych-autorskych-del-pro-ucely-trenovani-umele-inteligence-118625.html
- Ol1nova repa: https://github.com/lioilsources/PoetryStream · https://github.com/lioilsources/Webtoon
