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
- **api/client.dart**: Hálózati réteg és OAuth2 token menedzsment. Erősen típusos objektumokkal tér vissza a JSON map-ek helyett.
- **models/**: Típusbiztos model osztályok (Grade, Student, Absence, stb.) a Kréta API válaszok feldolgozására (`fromJson` factory-kkal). Null-safety garanciák, valamint az API által visszaadott UTC dátumok lokális időzónára konvertálása (`.toLocal()`).
- **app/state/app_state.dart**: Singleton objektum a `~/.config/folio/` (vagy Windows-on `C:\Users\User\.config\folio\`) mappában lévő `state.json` és `auth.json` konfigurációk központosított kezelésére (automatikus migrációval a régebbi `.folio_*` fájlokról).
- **app/cli_app.dart**: UI vezérlés, lekérdező ciklusok, globális kereső, GitHub API alapú frissítés-ellenőrzés (`_checkForUpdates`) és a Windows háttérfolyamat (Démon) kezelése. Itt történik a null-safety ellenőrzés (`_ensureClientReady`).
- **utils/chart_generator.dart**: ANSI alapú, terminál-szélességre skálázódó oszlopdiagram generátor az átlagokhoz.
- **utils/ics_exporter.dart**: RFC 5545 iCalendar kompatibilis naptárexportáló, ami immár erős típusú modellekkel dolgozik.

## Tesztelés
A fejlesztés során az alábbi ellenőrzéseket javasolt lefolytatni minden commit előtt:
1. Statikus analízis: `dart analyze` (nem lehet hiba, vagy force-unwrap `!`).
2. Nyers CLI indítás: `dart run bin/folio_cli.dart --help` futtathatósága.
3. Dummy adatok: Off-line fallback tesztelés cache-ből hálózat leválasztásával.

## Kréta API Specifikumok és Időzónák
A Kréta API V3 végpontjai szigorú paraméterezést követelnek. A `HaziFeladatok` például `500 Internal Server Error` hibát ad vissza, ha hiányzik a `datumTol` paraméter. Ennek elkerülése érdekében 30 napos alapértelmezett időablakot alkalmazunk. Továbbá az API által visszaadott JSON struktúrák (pl. a `Tantargy` kulcs típusai) inkonzisztensek lehetnek, így a kliensoldali típusellenőrzés (null check, type casting) elengedhetetlen.

**Kritikus:** A Kréta API a dátumokat (pl. órarend kezdete) **UTC időzónában** adja vissza. Ha ezeket egy az egyben jelenítjük meg, az eltolódásokat eredményezhet a napok között. Ennek kiküszöbölésére a modellek (`fromJson`) minden dátum parsolás után meghívják a `.toLocal()` függvényt.
Windows rendszereken a PowerShell alapértelmezett Windows-1252 kódolása miatt az UTF-8 karakterek és táblázatrajzoló elemek explicit kezelést igényelnek.

## Build és Fordítás
A natív végrehajtható fájl (`.exe`) előállításához az alábbi parancs használatos:
```bash
dart compile exe bin/folio_cli.dart
```
A fordított állomány a Windows Task Scheduler-en keresztüli háttérfutáskor láthatatlan módban indul.
