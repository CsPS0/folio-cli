# Felhasználói Kézikönyv

A Folio CLI egy parancssoros Kréta e-napló kliens. Ez a dokumentum a főbb funkciók használatát mutatja be.

## 1. Bejelentkezés
Az első indításkor meg kell adni az intézmény kódját (pl. `bmszc-neumann`). Ha nem tudod a kódot, használd a beépített keresőt az iskola neve alapján.
A bejelentkezéshez az oktatási azonosítóra és a jelszóra (általában a születési dátum: ÉÉÉÉ-HH-NN) van szükség. Sikeres belépés után a profil menthető, így a továbbiakban a bejelentkezés automatikus.

## 2. Főmenü Funkciók és Kimutatások
- **Élő Dashboard**: Azonnali visszaszámlálás az óra végéig, óraközi szünetek ideje, mai órarend és rendszer-karbantartási figyelmeztetések. 30 másodpercenként automatikusan frissül.
- **Legutóbbi jegyek**: Legfrissebb érdemjegyek, amelyek mellett elérhető a **Szellem Jegyek** szimulátor és a **Heti Heatmap** (átlag alakulása heti bontásban).
- **Órarend**: Dinamikus táblázatos órarend, amely jelzi az elmaradt órákat, a helyettesítéseket (tanárnévvel), dolgozatokat és a saját mulasztásaidat is.
- **Mulasztások**: Igazolt, igazolandó, igazolatlan órák és késések listája, valamint a 250 órás határt mérő **Veszélyzóna Kalkulátor**.
- **Tantárgyi átlagok**: Áttekinthető táblázat a saját átlagaidról, az osztályátlagokról, az eltérésekről és az átlag-trendekről (↗ / ↘), valamint a jegy-határhelyzet figyelmeztetésekről (pl. *Veszélyben a 4-es!*).
- **Jegy-trendek**: Heti bontású grafikon az éves átlagod alakulásáról (dinamikusan skálázott y-tengellyel), részletes statisztikákkal (legjobb/leggyengébb hónap) és az érdemjegyek eloszlási bar chartjával.
- **Számonkérések & Házi feladatok**: Dolgozatok és feladatok leírásokkal és határidőkkel, valamint a csatolt fájlok letöltésének lehetőségével.
- **Üzenetek**: Parancssoros üzenőfal a beérkezett üzenetek elolvasásához és mellékleteik letöltéséhez.
- **Haladó Kereső**: Ékezet-érzéketlen keresőmotor, amellyel a napló teljes tartalmában (jegyek, órák, házi feladatok, üzenetek, hiányzások) kereshetsz, és megnyithatod a részleteket.
- **Folio Wrapped**: Spotify-style éves diákstatisztika, amely bemutatja a legtöbb jegyet adó tanárodat, legszorgalmasabb napodat, késéseid összesített perceit és az üzenetküldő bajnokodat.

Minden listanézetnél és az üzeneteknél is elérhető az arrow-key alapú lapozás (Bal/Jobb nyilak).

## 3. Haladó Funkciók és Beállítások
A főmenü "Beállítások" opciójában az alábbi funkciók érhetők el:
- **Főmenü testreszabása**: Kiválaszthatod (SPACE gombbal), hogy mely menüpontok jelenjenek meg a főképernyőn, így elrejtheted a ritkán használt funkciókat.
- **Exportálások**:
  - Naptár exportálása (.ics): Az elkövetkező két hét órarendjének és vizsgáinak kimentése importálható naptárfájlba.
  - Adatok exportálása (CSV): Jegyek és mulasztások táblázatos kimentése.
- **Profilkezelés**: Váltás a mentett fiókok között.
- **Háttér-értesítések**: Windows Feladatütemező integráció. A háttérben futva óránként és bejelentkezéskor ellenőrzi az új jegyeket, majd értesítést küld.

## 4. Rendszer és Frissítések
- **Konfigurációs Fájlok**: Az alkalmazás minden mentett adatot a `~/.config/folio/` (Windows-on `C:\Users\Felhasználónév\.config\folio\`) könyvtárban tárol.
- **Csomagkezelők**: A Folio CLI natívan támogatja a Windows (Scoop), macOS/Linux (Homebrew), Arch Linux (AUR) és Debian/Ubuntu (APT) csomagkezelőket, így a frissítések a rendszer saját eszközeivel automatizálhatók.
- **Frissítések**: Az alkalmazás induláskor automatikusan ellenőrzi a GitHub-ot, és sárga szöveges üzenettel jelez, ha új verzió érhető el. A frissítés ezután a telepítés módjától függően (pl. `scoop update folio-cli`, `brew upgrade folio-cli`, `sudo apt upgrade folio-cli` vagy `yay -Syu`) könnyedén elvégezhető.

## 5. Hibaelhárítás
- **Hálózati vagy API hibák**: A Kréta szervereinek túlterheltsége vagy az API módosulása okozhatja. A program beépített védelemmel rendelkezik a leggyakoribb hibák ellen.
- **Szövegbeviteli / Másolási hibák**: A bejelentkezési kód beillesztésekor a program automatikusan kezeli a vágólapot (beleértve a Linux/macOS "Bracketed Paste" funkcióját és a Windows terminál specifikumait is). Különleges terminál emulátorok esetén javasolt a jobb gombos beillesztés használata.
- **Megjelenítési hibák**: Ékezet- és táblázatproblémák esetén javasolt a terminál (PowerShell/CMD) frissítése és a Folio legújabb verziójának használata.
- **Lefagyás**: Ha régebbi verziót használsz, Windows terminál esetén előfordulhatott eseménykezelési hiba (befagyott beviteli mező). Ezt a legújabb verziókban javítottuk a platform-specifikus I/O szétválasztásával. Ilyenkor frissíts a legújabb verzióra.
