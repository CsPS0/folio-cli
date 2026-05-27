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
- api/client.dart: Hálózati réteg és OAuth2 token menedzsment.
- app/cli_app.dart: UI vezérlés, lekérdező ciklusok, globális kereső és a Windows háttérfolyamat (Démon) kezelése.
- utils/chart_generator.dart: ANSI alapú, terminál-szélességre skálázódó oszlopdiagram generátor az átlagokhoz.
- utils/ics_exporter.dart: RFC 5545 iCalendar kompatibilis naptárexportáló.

## Kréta API Specifikumok
A Kréta API V3 végpontjai szigorú paraméterezést követelnek. A `HaziFeladatok` például `500 Internal Server Error` hibát ad vissza, ha hiányzik a `datumTol` paraméter. Ennek elkerülése érdekében 30 napos alapértelmezett időablakot alkalmazunk. Továbbá az API által visszaadott JSON struktúrák (pl. a `Tantargy` kulcs típusai) inkonzisztensek lehetnek, így a kliensoldali típusellenőrzés (null check, type casting) elengedhetetlen.
Windows rendszereken a PowerShell alapértelmezett Windows-1252 kódolása miatt az UTF-8 karakterek és táblázatrajzoló elemek explicit kezelést igényelnek.

## Build és Fordítás
A natív végrehajtható fájl (`.exe`) előállításához az alábbi parancs használatos:
```bash
dart compile exe bin/folio_cli.dart
```
A fordított állomány a Windows Task Scheduler-en keresztüli háttérfutáskor láthatatlan módban indul.
