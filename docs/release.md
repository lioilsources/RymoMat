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
6. **Pack v buildu**: `app/assets/packs/cs-v1.zip` je gitignorovaný. Před releasem
   `run/rymo release cs` a zkopírovat zip do `app/assets/packs/`; v CI ho stáhnout
   z release `cs-v1` v repu `lioilsources/rymomat-packs` (krok doplnit, až repo vznikne).

## Podpisový tým iOS

Team ID se do veřejného repa necommituje. Lokálně ho drží gitignorovaný
`app/ios/Flutter/Team.xcconfig` (`DEVELOPMENT_TEAM = …`), který `Debug.xcconfig` a `Release.xcconfig`
načítají přes `#include?`. CI ho dostává ze secretu `IOS_TEAM_ID`.
