# Evaluace packu `cs`

Generuje `rymo eval cs` (`packages/rymo_core/bin/eval.dart`). Pack: 50.4 MB, bez indexu word_as, max 30 partnerů, max 100000 citací, verze 1, sestaven 2026-11-24T15:05:00.185341Z.

## 1. Golden test G2P proti přepisu KČV

Vzorek 20000 náhodných posledních slov veršů (seed 2026), porovnává se klíč `f1`.

- shoda: **19981 / 19998 = 99.91 %** (brána ≥ 97 %)
- přeskočeno (neznámý symbol XSAMPA nebo slovo bez jádra): 2

Nejčastější neshody (slovo, počet, náš přepis, KČV, f1 náš / KČV):

| slovo | n | náš | KČV | f1 náš | f1 KČV |
|---|---|---|---|---|---|
| macabre | 1 | macabre | makabr | re | br |
| vous | 1 | vWs | vu | Ws | vu |
| marseillaisy | 1 | marseilaisi | marsejEzi | si | zi |
| commis | 1 | comis | komi | is | mi |
| voltaire | 1 | voltaire | voltEr | re | Er |
| irae | 1 | irae | irE | e | rE |
| aventur | 1 | aventur | aventir | ur | ir |
| sieg | 1 | sijek | sIk | ek | Ik |
| sfaer | 1 | sfaer | sfEr | er | Er |
| poggio | 1 | pogijo | poDZo | jo | Zo |
| iusti | 1 | iusTi | justi | Ti | ti |
| littengrün | 1 | litengrün | litengrIn | rün | In |
| incroyable | 1 | incroiable | inkrojAbl | le | bl |
| golgothu | 1 | golgodhu | golgotu | hu | tu |
| klein | 1 | klein | klajn | in | ajn |
| gentleman | 1 | gentleman | dZentlmen | an | en |
| bonvivant | 1 | bonvivant | bonvivan | ant | an |

## 2. Doložené páry KČV podle levelu

403073 různých párů, 999547 výskytů. Jako rým (`identical`…`loose`) engine označí **96.84 %** párů a **98.34 %** výskytů (brána ≥ 85 %).

| level | páry | % | výskyty | % | příklady |
|---|---|---|---|---|---|
| identical | 105 | 0.03 | 378 | 0.04 | led/let (29), bil/byl (22), objetí/obětí (22), praví/pravý (21), víš/výš (16), blízká/blýská (15), bít/být (14), bila/byla (12) |
| full | 205672 | 51.03 | 488186 | 48.84 | nebe/tebe (844), hoře/moře (675), nebe/sebe (673), slova/znova (546), líce/více (500), době/sobě (473), leží/svěží (447), nese/třese (395) |
| masc | 54564 | 13.54 | 166649 | 16.67 | květ/svět (973), den/sen (788), zas/čas (754), hlas/zas (582), hvězd/jest (548), jen/sen (548), tvář/zář (541), hlas/čas (508) |
| weak | 43806 | 10.87 | 103958 | 10.40 | kráse/se (536), mně/země (519), svítí/žití (396), se/zase (383), to/zlato (317), nese/se (307), dýše/tiše (298), plémě/země (287) |
| looseFull | 67510 | 16.75 | 173430 | 17.35 | oči/točí (439), duši/tuší (350), němý/zemi (320), domů/tomu (318), bílé/chvíle (314), hoří/moři (304), děti/letí (285), boji/stojí (282) |
| loose | 18696 | 4.64 | 50311 | 5.03 | bůh/duch (237), sám/tam (236), nic/víc (234), již/tíž (213), blíž/již (207), již/kříž (172), dál/žal (165), pták/zrak (154) |
| assonance | 4168 | 1.03 | 5744 | 0.57 | větší/řečí (111), větší/řeči (87), nebezpečí/větší (53), svědčí/větší (40), křeči/větší (37), květe/světě (31), klečí/větší (27), něčí/větší (25) |
| none | 8552 | 2.12 | 10891 | 1.09 | jest/zvěsť (28), jest/česť (28), loď/pojď (28), jest/pěsť (25), práce/se (23), modlitbou/svou (19), prsou/svou (17), svou/tebou (15) |

Rozbor `none` (výskyty):

| typ | výskyty | příklady |
|---|---|---|
| otevřený konec, stejné jádro, jiná opěrná souhláska (dá/má) | 8009 | práce/se (23), modlitbou/svou (19), prsou/svou (17), svou/tebou (15), tebou/tvou (13), jedinou/svou (12), krátce/se (12), sebou/svou (12), svou/ubohou (12), jdou/sebou (10) |
| zavřený konec, stejné jádro, jiná koda (souzvuk) | 1804 | jest/zvěsť (28), jest/česť (28), loď/pojď (28), jest/pěsť (25), choť/pojď (12), jest/ratolesť (11), doprovoď/pojď (10), jest/lesť (8), květ/odpověď (8), pláč/radš (8) |
| jiné jádro (chyba anotace nebo oční rým) | 730 | dům/museum (8), neví/revue (5), adieu/je (4), vklouz/vous (4), cabotin/sten (3), chmur/pompadour (3), dvůr/pompadour (3), dvůr/troubadour (3), jeví/revue (3), madame/vpadám (3) |
| stejné jádro, jedno otevřené a jedno zavřené | 147 | musset/se (5), affaire/směr (2), baudelaire/šer (2), chápavý/vis (2), dumas/dřímá (2), fléche/lež (2), gras/tygra (2), je/métier (2), jen/prozařuje (2), kopá/pas (2) |
| přejaté slovo (možná chyba G2P) | 131 | watteau/zlato (6), prix/prý (3), waterloo/zlo (3), chère/podvečer (2), chère/šer (2), claque/frak (2), götha/světa (2), göthe/plete (2), montesquieu/žije (2), plato/watteau (2) |
| slovo bez jádra | 70 | kč/pláče (3), d/rozpřede (2), f/krev (2), k/čeká (2), kles/s (2), kč/rváče (2), m/úsměvem (2), nejlépe/p (2), předvečer/r (2), r/šer (2) |

## 3. Latence `suggest` (1 000 náhodných slov z lexikonu, macos, 8 jader)

| cesta | p50 ms | p95 ms | p99 ms | max ms |
|---|---|---|---|---|
| SuggestCore přímo | 1.03 | 2.20 | 3.89 | 7.50 |
| RhymeEngine (izolát) | 1.07 | 2.27 | 5.09 | 8.40 |

Slov bez jediného návrhu: 1 / 1000.
