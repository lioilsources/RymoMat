# Release RymoMat — ruční kroky

Pipeline je z repa Distribution (`release-ios.yml`, `release-android.yml`); release spouští tag
(skill `release-flutter`). Skript neudělá tyto kroky v účtech:

1. **Apple Developer**: App ID `com.ol1n.rymomat` (bez App Group a extension),
   distribuční profil App Store pro `com.ol1n.rymomat`.
2. **App Store Connect**: nová aplikace RymoMat, bundle `com.ol1n.rymomat`, jazyk čeština.
   Privacy Policy URL `https://lioilsources.github.io/RymoMat/privacy.html`,
   Support URL `https://lioilsources.github.io/RymoMat/support.html`,
   Marketing URL `https://olin.now/rymomat`. Privacy: „Data Not Collected“.
3. **Google Play** (firemní účet, rovnou produkce): aplikace `com.ol1n.rymomat`, zásady
   ochrany soukromí = privacy URL výše; Data safety: žádná data se nesbírají ani nesdílejí.
4. **Firebase App Distribution**: Android aplikace `com.ol1n.rymomat`.
5. **Secrets**: `Distribution/scripts/setup-gh-secrets.sh` pro `lioilsources/RymoMat`
   (profil ulož do složky appky RymoMat, jak skript očekává).
6. **Pack v buildu**: `app/assets/packs/cs-v1.zip` je gitignorovaný. Release workflowy ho stahují
   z release `cs-v1` repa `lioilsources/rymomat-packs` a kontrolují sha256 (krok „Fetch rhyme pack“).
   Nová verze packu: `run/rymo release cs`, nový release v `rymomat-packs`, aktualizovat `catalog.json`
   tamtéž a URL + sha256 v obou workflowech. Lokálně: `cp work/release/cs-v1.zip app/assets/packs/`.

## Stav (2026-11-28)

Hotovo: App ID a distribuční profil, aplikace v App Store Connect (URL, privacy „Data Not Collected“,
interní skupina TestFlight „Alfa“), aplikace v Google Play (zásady, bezpečnost údajů, reklamy,
přístup, cílové publikum 16+), GitHub secrets, repo `rymomat-packs` s `cs-v1`.

Chybí: Firebase App Distribution (projekt má plný limit 30 aplikací; krok ve workflow se bez
`FIREBASE_ANDROID_APP_ID` přeskočí); v Google Play hodnocení obsahu, kategorie a záznam v obchodě
(screenshoty, grafika) před prvním vydáním.

## Podpisový tým iOS

Team ID se do veřejného repa necommituje. Lokálně ho drží gitignorovaný
`app/ios/Flutter/Team.xcconfig` (`DEVELOPMENT_TEAM = …`), který `Debug.xcconfig` a `Release.xcconfig`
načítají přes `#include?`. CI ho dostává ze secretu `IOS_TEAM_ID`.
