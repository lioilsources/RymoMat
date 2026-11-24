# M1 — aplikace pro básníka: stav

Stav 2026-11-22. Hotový kód M1; brána M1 potřebuje kroky, které nejdou udělat bez Ol1na
a básníka (reálný telefon, TestFlight, dogfooding).

## Hotovo

- `packages/rymo_editor`: `RhymeEditingController` (debounce 80 ms, zastaralé výsledky
  zahazuje podle pořadového čísla), `RhymeTextField` (velká písmena i automatické opravy
  vypnuté, akce výběru „Rýmy na ‚…'“), `RhymeBar` (slabiky aktivního verše, max 3 cíle
  s barevnou tečkou a čipy), `RhymeSheet` (návrhy po levelech, doklady), `CitationList`.
  Volný režim podle §9.2: konce předchozích veršů sloky (max 6), u krátké sloky poslední
  verš předchozí sloky, nezrýmované napřed. Rozepsané slovo jde jako `prefix`; čip ho nahradí.
- `rymo_core`: `Notebook` — zápis a čtení YAML ve formátu PoetryStreamu (mapa i seznam),
  vlastní zapisovač (uvozovky, blok `|`, indikátor odsazení), import prostého textu.
- `app/` (Flutter, Riverpod, iOS + Android, `com.ol1n.rymomat`): Sbírky → báseň → Editor
  (automatické ukládání), Rýmovník (filtry slabik, jen doložené, bez gramatických, doklady),
  Nastavení (pack, psaní, „O datech“ s atribucí z manifestu). UI česky a anglicky (ARB).
  Pack cs je přibalený (`assets/packs/cs-v1.zip`) a při prvním spuštění se rozbalí s kontrolou
  sha256. Žádná síť.
- Export `.yaml` (sbírka) a `.txt` (báseň) přes systémové sdílení, import `.yaml`/`.txt`.
- Testy: rymo_core 81, rymo_editor 8 (vložení čipu, cíle volného režimu, zastaralý výsledek),
  app 3 (+ regresní test dialogu) a integrační test na simulátoru iPhone 17 Pro: založí sbírku
  a báseň, napíše dva verše, z reálného packu nabídne „háj“, klepnutí ho vloží.
  `suggest` přes izolát na simulátoru: p50 1,2 ms, p95 3,4 ms (200 dotazů).
- Kompatibilita s PoetryStreamem: všech 48 básní ze 4 sbírek prošlo čtením a zápisem beze ztráty
  textu (lokální kontrola, texty do repa nepatří).
- Release: Android podpis z `key.properties`, `docs/release.md` s ručními kroky,
  stránky `docs/index.html`, `privacy.html`, `support.html` pro GitHub Pages.

## Brána M1 — co zbývá

| Kritérium | Stav |
|---|---|
| básník napíše a vyexportuje báseň | čeká na TestFlight / interní test |
| export jde vložit do `PoetryStream/poetry_stream/assets/poems/` a zobrazí se | formát ověřen testy proti `loadYaml`; lokální build PoetryStreamu s exportem ještě ne |
| `suggest` p95 ≤ 30 ms na reálném telefonu | simulátor 3,4 ms; telefon čeká (stejný integrační test, `-d <telefon>`) |
| letecký režim od prvního spuštění | aplikace nemá síťový kód; ověřit na telefonu |
| `docs/M1_FEEDBACK.md` | po dogfoodingu |

## Nalezené a opravené

- Dialog s názvem sbírky uvolnil svůj `TextEditingController` během zavírací animace
  (zachytil to integrační test) → dialog vlastní controller sám; regresní test `test/dialog_test.dart`.

## Nezměřeno

- Doba prvního spuštění (rozbalení 22 MB zipu a kontrola sha256 packu 50 MB) v release buildu
  na telefonu. V debug režimu na simulátoru to trvalo desítky sekund; lišta mezitím ukazuje
  „Připravuji slovník rýmů…“.

## Odchylky

- Citace jsou v RhymeSheetu už v M1 (plán je řadí do M2); Rýmovník je potřebuje tak jako tak.
- Režim schématu, obarvení skupin, asonance v UI, historie verzí a `meta.json` jsou M2.

## Doplněno 2026-11-24

- Ikona: vektorový symbol (tři verše, jantarový oblouk spojuje rýmující se konce), zdroj
  `app/assets/icon/icon.svg`, generuje `flutter_launcher_icons`; `docs/icon.png` pro Pages.
- Rozhodnutí z M0 (`dá/má`, pravidlo `-ie → -ije`, MIT) jsou zapracovaná, viz `M0_REPORT.md`.
