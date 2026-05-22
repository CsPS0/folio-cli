# Fejlesztői Dokumentáció (DEV) 🛠️

Ez a leírás a `folio-cli` architektúráját, fejlesztési és buildelési folyamatát foglalja össze.

## Architektúra és Csomagok

Az alkalmazás szigorúan a **Dart** ökoszisztémára épít (nincs Flutter függőség), ezzel garantálva a villámgyors indulást (AOT fordítással).

### Kiemelt könyvtárak:
1. `interact` (v2.1.1 felett): Ez a csomag felel az interaktív terminál-felületért (menük, bevitel, jelszó maszkolás). Hatalmas szerepe van a `Select` és `Confirm` promtok megjelenítésében, amiket be is témeztünk a Folio arculatára (egyedi zöld pipák, nyíl karakterek, terminál-háttér megőrzése).
2. `http`: A hivatalos Kréta IDP és V3 API-val (Ellenőrző) történő kommunikációra használjuk.
3. `html`: A webes fallback login során (B módszer) egy vékony OAuth2 wrapper generálásához van benne a projektben, de a natív "IDP-Flow" (A módszer) futása a default és ajánlott.
4. `args`: A parancssori argumentumok (felhasználónév, jelszó, intézmény) feldolgozásához.

### Fő modulok a `lib/` alatt:
- `api/client.dart`: Maga a hálózati réteg és az OAuth2 token menedzsment (beleértve a refresh tokent is).
- `app/cli_app.dart`: A CLI UI vezérlése. Itt laknak a lekérdező ciklusok (`_showGrades`, `_showTimetable`), a Démön hívó kódja (ami a Windows Task Schedulert programozza), a Theme Injektor, valamint a globális kereső iterációja.
- `utils/`: Segédfájlok
  - `chart_generator.dart`: Egy ANSI alapú "Bar Chart" generáló, ami százalékosan skálázva vizualizálja az átlagokat a terminál szélességét kitöltve.
  - `ics_exporter.dart`: A hivatalos RFC 5545 iCalendar szabvány szerint fűzi össze a lekért vizsgákat és órarendi elemeket egy .ics fájlba.

## Kréta API kihívások és Fixek
A Kréta API V3 (pl. `HaziFeladatok`) rendkívül érzékeny a paraméterezésre. Ha nem kap `datumTol` értéket, akkor egy `500 Internal Server Error`-ral elszáll. Emiatt a lekérdezéseknél beépített 30 napos csúsztatásokat használunk, ha a felhasználó nem szűr dátumra. Emellett az API visszaadott adatszerkezete gyakran eltér a dokumentált formáktól (pl. a `Tantargy` kulcs hol string, hol egy Object/Map). Ezek típusellenőrzését kiterjedten végezzük a kliensben, hogy elkerüljük az exception-öket. 
Továbbá a Windows PowerShell default Windows-1252 (Latin-1) kódolása miatt az egyedi UTF-8 ANSI és Box-drawing karaktereket (┌─│) explicit kódoltuk le, és elkerültük a hátterek agresszív színezését (`\x1B[48;2;...`).

## Fordítás (Build & Compile)
Ha szeretnéd teljesen natív, egyetlen `.exe` fájllá alakítani az alkalmazást (hogy Dart futtatókörnyezet nélkül is vihető legyen):
```bash
dart compile exe bin/folio_cli.dart
```
A generált futtatható állományt a `bin/folio_cli.exe` alatt találod. Windows esetén ez automatikusan elrejti a CMD ablakot a Démön (Task Scheduler) bekapcsolásánál, mivel a flag-ekben `-WindowStyle Hidden` parancsot hívunk meg.
