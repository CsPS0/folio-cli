# Fejlesztői Dokumentáció

Ez a leírás a `folio-cli` architektúráját, fejlesztési és buildelési folyamatát foglalja össze.

## Architektúra és Csomagok
Az alkalmazás kizárólag a Dart ökoszisztémára épít, Flutter függőségek nélkül, amely garantálja a gyors AOT fordítást.

Kiemelt függőségek:
1. interact: Interaktív terminál-felületek (menük, bevitel, maszkolás) kezelése.
2. http: Kommunikáció a Kréta IDP és V3 (Ellenőrző) API-kkal.
3. html: Kiegészítő OAuth2 wrapper a webes tartalék bejelentkezéshez.
4. args: Parancssori argumentumok feldolgozása.

Fő modulok:
- **api/client.dart**: Hálózati réteg és OAuth2 token menedzsment. A token-frissítések (`refreshAccessToken`) aszinkron zárolással (`_activeRefreshFuture`) vannak ellátva, így elkerülhetők a párhuzamos API-hívások során fellépő `auth.json` fájl-íródási race-condition hibák és titkosítási korrupciók.
- **models/**: Típusbiztos model osztályok (Grade, Student, Absence, TimetableEntry, stb.) a Kréta API válaszok feldolgozására. Az UTC dátumokat azonnal helyi időzónába konvertálják. A `isSummaryGrade` metódus ékezet-érzékeny és ékezet-mentes szűréssel is kiszűri a félévi/év végi összefoglaló értékeléseket.
- **app/state/app_state.dart**: Singleton a helyi konfigurációk (`state.json` és titkosított `auth.json`) kezelésére, a választott témák és az ASCII banner beállítások perzisztálására.
- **app/theme.dart**: A parancssor globális témasémáit és színkódjait (szövegek, menü jelölők, gombok, grafikonok) vezérlő modul.
- **app/views/**:
  - **dashboard_view.dart**: Aszinkron billentyűzet-olvasó eseményhurok és órarendi óra-visszaszámláló widget. A főmenüből külön alfolyamatként (subprocess) indul, ami izolálja az aszinkron `stdin` folyamatot a főprogram konzol-leíróitól.
  - **wrapped_view.dart**: Spotify-Wrapped stílusú statisztikákat (késések, tanári eloszlás, legszorgalmasabb nap, üzenetek) vizualizáló slides.
  - **absences_view.dart**: Veszélyzóna kalkulátor, osztályátlag és eltérés-táblázat, valamint a heti kumulatív jegy-trendek dashboardja.
  - **grades_view.dart**: Szellem jegyek kalkulátor, jegy heatmap és a globális ékezet-érzéketlen keresőmotor.
- **app/components/utf8_input.dart**: Egyéni parancssoros beviteli wrapper, amely garantálja az echo (karakter-megjelenítés) helyes állapotát a Windows konzolon.
- **utils/win32_console.dart**: Windows-specifikus Win32 API FFI hívásokat tartalmazó segédfájl. A `forceRestoreConsoleMode()` közvetlen kernel-szintű konzol módosításokkal állítja vissza a billentyűzet-echo-t (`ENABLE_ECHO_INPUT`) és letiltja a `0x0200` (virtual terminal input) módot a backspace-törlés helyes működéséhez.
- **utils/chart_generator.dart**: ANSI alapú terminál grafikon-generátor. A `generateLineChart` dinamikus y-tengely skálázást végez az input adathatárvonalak alapján, így kiküszöböli a lapos GPA grafikonokat.
- **utils/ics_exporter.dart**: RFC 5545 iCalendar kompatibilis naptárexportáló.

## Tesztelés
A fejlesztés során az alábbi ellenőrzéseket javasolt lefolytatni minden commit előtt:
1. Statikus analízis: `dart analyze` (nem lehet hiba, vagy force-unwrap `!`).
2. Nyers CLI indítás: `dart run bin/folio_cli.dart --help` futtathatósága.
3. Dummy adatok: Off-line fallback tesztelés cache-ből hálózat leválasztásával.

## Kréta API Specifikumok és Időzónák
A Kréta API V3 végpontjai szigorú paraméterezést követelnek. A `HaziFeladatok` például `500 Internal Server Error` hibát ad vissza, ha hiányzik a `datumTol` paraméter. Ennek elkerülése érdekében 30 napos alapértelmezett időablakot alkalmazunk. Továbbá az API által visszaadott JSON struktúrák (pl. a `Tantargy` kulcs típusai) inkonzisztensek lehetnek, így a kliensoldali típusellenőrzés (null check, type casting) elengedhetetlen.

**Kritikus:** A Kréta API a dátumokat (pl. órarend kezdete) **UTC időzónában** adja vissza. Ha ezeket egy az egyben jelenítjük meg, az eltolódásokat eredményezhet a napok között. Ennek kiküszöbölésére a modellek (`fromJson`) minden dátum parsolás után meghívják a `.toLocal()` függvényt.
Windows rendszereken a PowerShell alapértelmezett Windows-1252 kódolása miatt az UTF-8 karakterek és táblázatrajzoló elemek explicit kezelést igényelnek.

## Build, Fordítás és CI/CD Pipeline
A natív végrehajtható fájl (`.exe` vagy bináris) előállításához az alábbi parancs használatos:
```bash
dart compile exe bin/folio_cli.dart
```

**Automatizált CI/CD (GitHub Actions):**
- **release.yml**: Valahányszor új "Release" jön létre, a GitHub Actions automatikusan lefordítja a kódot Ubuntu, Windows és macOS környezeteken (`ubuntu-latest`, `windows-latest`, `macos-latest`), és feltölti a kiadáshoz az artifactokat (`folio-cli.exe`, `folio-cli-linux`, `folio-cli-macos`).
- **aur.yml**: Arch Linux felhasználóknak az alkalmazás az AUR-on (Arch User Repository) is elérhető (`folio-cli-bin`). A publikálást a `.github/workflows/aur.yml` kezeli, ami a beállított SSH kulccsal szinkronizálja a `packaging/PKGBUILD` fájlt.
- **Csomagkezelők**: A projekt gyökérkönyvtárában található `bucket/folio-cli.json` (Scoop Windows-hoz) és `Formula/folio-cli.rb` (Homebrew macOS/Linux-hoz) fájlok gondoskodnak arról, hogy az alkalmazás telepíthető legyen csomagkezelőkből, anélkül, hogy külön repót kéne fenntartani.
A fordított állomány a Windows Task Scheduler-en keresztüli háttérfutáskor láthatatlan módban indul.
