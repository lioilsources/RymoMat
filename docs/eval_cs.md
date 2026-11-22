# Evaluace packu `cs`

Generuje `rymo eval cs` (`packages/rymo_core/bin/eval.dart`). Pack: 50.3 MB, bez indexu word_as, max 30 partnerů, max 100000 citací, verze 1, sestaven 2026-11-22T09:25:43.277354Z.

## 1. Golden test G2P proti přepisu KČV

Vzorek 20000 náhodných posledních slov veršů (seed 2026), porovnává se klíč `f1`.

- shoda: **19931 / 19998 = 99.66 %** (brána ≥ 97 %)
- přeskočeno (neznámý symbol XSAMPA nebo slovo bez jádra): 2

Nejčastější neshody (slovo, počet, náš přepis, KČV, f1 náš / KČV):

| slovo | n | náš | KČV | f1 náš | f1 KČV |
|---|---|---|---|---|---|
| melodie | 3 | meloDie | meloDije | e | je |
| francie | 3 | francie | francije | e | je |
| bestie | 2 | besTie | besTije | e | je |
| symfonie | 2 | simfoNie | simfoNije | e | je |
| aurelie | 2 | Yrelie | Yrelije | e | je |
| lilie | 2 | lilie | lilije | e | je |
| italie | 2 | italie | italije | e | je |
| klytie | 1 | kliTie | kliTije | e | je |
| mandžurie | 1 | man4urie | mandZurije | e | je |
| vous | 1 | vWs | vu | Ws | vu |
| ironií | 1 | iroNiI | iroNijI | I | jI |
| fantasie | 1 | fantasie | fantasije | e | je |
| macabre | 1 | macabre | makabr | re | br |
| marií | 1 | mariI | marijI | I | jI |
| domitia | 1 | domiTia | domiTija | a | ja |
| linie | 1 | liNie | liNije | e | je |
| marseillaisy | 1 | marseilaisi | marsejEzi | si | zi |
| relikvie | 1 | relikvie | relikvije | e | je |
| missie | 1 | misie | misije | e | je |
| studií | 1 | stuDiI | stuDijI | I | jI |
| disharmonie | 1 | DisxarmoNie | DisxarmoNije | e | je |
| poesií | 1 | poesiI | poesijI | I | jI |
| julie | 1 | julie | julije | e | je |
| francií | 1 | franciI | francijI | I | jI |
| harmonie | 1 | harmoNie | harmoNije | e | je |
| commis | 1 | comis | komi | is | mi |
| voltaire | 1 | voltaire | voltEr | re | Er |
| tragédie | 1 | tragEDie | tragEDije | e | je |
| irae | 1 | irae | irE | e | rE |
| aventur | 1 | aventur | aventir | ur | ir |
| sieg | 1 | siek | sIk | ek | Ik |
| marie | 1 | marie | marije | e | je |
| žaluzie | 1 | Zaluzie | Zaluzije | e | je |
| sfaer | 1 | sfaer | sfEr | er | Er |
| kastilie | 1 | kasTilie | kasTilije | e | je |
| bestií | 1 | besTiI | besTijI | I | jI |
| gloria | 1 | gloria | glorija | a | ja |
| genie | 1 | geNie | geNije | e | je |
| iusti | 1 | iusTi | justi | Ti | ti |
| littengrün | 1 | litengrün | litengrIn | rün | In |
| incroyable | 1 | incroiable | inkrojAbl | le | bl |
| golgothu | 1 | golgodhu | golgotu | hu | tu |
| historie | 1 | historie | historije | e | je |
| zenobia | 1 | zenobia | zenobija | a | ja |
| sympatie | 1 | simpaTie | simpaTije | e | je |
| demokracie | 1 | demokracie | demokracije | e | je |
| žofie | 1 | Zofie | Zofije | e | je |
| poesie | 1 | poesie | poesije | e | je |
| bergerie | 1 | bergerie | bergerije | e | je |
| theorie | 1 | dheorie | teorije | e | je |
| klein | 1 | klein | klajn | in | ajn |
| gentleman | 1 | gentleman | dZentlmen | an | en |
| italií | 1 | italiI | italijI | I | jI |
| bonvivant | 1 | bonvivant | bonvivan | ant | an |
| anglie | 1 | anglie | anglije | e | je |
| mysterie | 1 | misterie | misterije | e | je |
| tragedií | 1 | trageDiI | trageDijI | I | jI |
| poggio | 1 | pogio | poDZo | o | Zo |

## 2. Doložené páry KČV podle levelu

403073 různých párů, 999547 výskytů. Jako rým (`identical`…`loose`) engine označí **96.41 %** párů a **97.94 %** výskytů (brána ≥ 85 %).

| level | páry | % | výskyty | % | příklady |
|---|---|---|---|---|---|
| identical | 104 | 0.03 | 377 | 0.04 | led/let (29), bil/byl (22), objetí/obětí (22), praví/pravý (21), víš/výš (16), blízká/blýská (15), bít/být (14), bila/byla (12) |
| full | 204962 | 50.85 | 487220 | 48.74 | nebe/tebe (844), hoře/moře (675), nebe/sebe (673), slova/znova (546), líce/více (500), době/sobě (473), leží/svěží (447), nese/třese (395) |
| masc | 54599 | 13.55 | 166708 | 16.68 | květ/svět (973), den/sen (788), zas/čas (754), hlas/zas (582), hvězd/jest (548), jen/sen (548), tvář/zář (541), hlas/čas (508) |
| weak | 43632 | 10.82 | 103673 | 10.37 | kráse/se (536), mně/země (519), svítí/žití (396), se/zase (383), to/zlato (317), nese/se (307), dýše/tiše (298), plémě/země (287) |
| looseFull | 67515 | 16.75 | 173421 | 17.35 | oči/točí (439), duši/tuší (350), němý/zemi (320), domů/tomu (318), bílé/chvíle (314), hoří/moři (304), děti/letí (285), boji/stojí (282) |
| loose | 17790 | 4.41 | 47530 | 4.76 | bůh/duch (237), sám/tam (236), nic/víc (234), již/tíž (213), blíž/již (207), již/kříž (172), dál/žal (165), pták/zrak (154) |
| assonance | 4937 | 1.22 | 6821 | 0.68 | větší/řečí (111), větší/řeči (87), nebezpečí/větší (53), svědčí/větší (40), křeči/větší (37), květe/světě (31), klečí/větší (27), něčí/větší (25) |
| none | 9534 | 2.37 | 13797 | 1.38 | dá/má (70), jsou/svou (64), mou/svou (62), má/tvá (62), jdou/jsou (58), má/zná (57), jdou/svou (54), svou/tmou (47) |

Rozbor `none` (výskyty):

| typ | výskyty | příklady |
|---|---|---|
| otevřený konec, stejné jádro, jiná opěrná souhláska (dá/má) | 10915 | dá/má (70), jsou/svou (64), mou/svou (62), má/tvá (62), jdou/jsou (58), má/zná (57), jdou/svou (54), svou/tmou (47), svou/zlou (43), já/má (41) |
| zavřený konec, stejné jádro, jiná koda (souzvuk) | 1804 | jest/zvěsť (28), jest/česť (28), loď/pojď (28), jest/pěsť (25), choť/pojď (12), jest/ratolesť (11), doprovoď/pojď (10), jest/lesť (8), květ/odpověď (8), pláč/radš (8) |
| jiné jádro (chyba anotace nebo oční rým) | 730 | dům/museum (8), neví/revue (5), adieu/je (4), vklouz/vous (4), cabotin/sten (3), chmur/pompadour (3), dvůr/pompadour (3), dvůr/troubadour (3), jeví/revue (3), madame/vpadám (3) |
| stejné jádro, jedno otevřené a jedno zavřené | 147 | musset/se (5), affaire/směr (2), baudelaire/šer (2), chápavý/vis (2), dumas/dřímá (2), fléche/lež (2), gras/tygra (2), je/métier (2), jen/prozařuje (2), kopá/pas (2) |
| přejaté slovo (možná chyba G2P) | 131 | watteau/zlato (6), prix/prý (3), waterloo/zlo (3), chère/podvečer (2), chère/šer (2), claque/frak (2), götha/světa (2), göthe/plete (2), montesquieu/žije (2), plato/watteau (2) |
| slovo bez jádra | 70 | kč/pláče (3), d/rozpřede (2), f/krev (2), k/čeká (2), kles/s (2), kč/rváče (2), m/úsměvem (2), nejlépe/p (2), předvečer/r (2), r/šer (2) |

## 3. Latence `suggest` (1 000 náhodných slov z lexikonu, macos, 8 jader)

| cesta | p50 ms | p95 ms | p99 ms | max ms |
|---|---|---|---|---|
| SuggestCore přímo | 1.23 | 2.56 | 3.24 | 20.26 |
| RhymeEngine (izolát) | 1.25 | 2.70 | 4.94 | 9.84 |

Slov bez jediného návrhu: 1 / 1000.
