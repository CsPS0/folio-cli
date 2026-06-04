# Felhasználói Kézikönyv

A Folio CLI egy parancssoros Kréta e-napló kliens. Ez a dokumentum a főbb funkciók használatát mutatja be.

## 1. Bejelentkezés
Az első indításkor meg kell adni az intézmény kódját (pl. `bmszc-neumann`). Ha nem tudod a kódot, használd a beépített keresőt az iskola neve alapján.
A bejelentkezéshez az oktatási azonosítóra és a jelszóra (általában a születési dátum: ÉÉÉÉ-HH-NN) van szükség. Sikeres belépés után a profil menthető, így a továbbiakban a bejelentkezés automatikus.

## 2. Főmenü Funkciók
- Tanulói adatlap: Személyes adatok és Célátlag kalkulátor.
- Legutóbbi jegyek: A legfrissebb érdemjegyek listája színkódolt értékekkel.
- Órarend: Dinamikus, táblázatos nézet az e heti és jövő heti órákról.
- Mulasztások: Igazolt, igazolandó és igazolatlan hiányzások, valamint késések színkódolt nézete.
- Tantárgyi átlagok: Színkódolt oszlopdiagram.
- Számonkérések & Házi feladatok: Vizsgák és beadandók határidőkkel.
- Üzenetek: A Kréta üzenőfal elérése.

Minden listanézetnél elérhető az "Összes megtekintése" opció a régebbi bejegyzések betöltéséhez.
- Keresés: Globális kereső a napló teljes tartalmában.

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
