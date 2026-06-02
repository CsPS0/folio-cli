# Folio CLI
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/CsPS0/folio-cli)](https://github.com/CsPS0/folio-cli/releases)
[![Build Status](https://github.com/CsPS0/folio-cli/actions/workflows/release.yml/badge.svg)](https://github.com/CsPS0/folio-cli/actions)

A Folio CLI egy parancssoros alkalmazás a Kréta e-napló rendszerhez. Az iOS alkalmazás OAuth2 hitelesítési folyamatait szimulálva közvetlen terminálos elérést biztosít a diákok adatlapjához és jegyeihez. A projekt a Folio ökoszisztéma hivatalos parancssoros eszköze.

> **English Summary:** Folio CLI is a fast, terminal-based client for the Hungarian 'Kréta' electronic school diary system. It provides direct access to grades, timetable, homework, and absences via a text-based UI, with multi-profile support and Windows background notifications.

## Főbb funkciók
- Intézménykereső név alapján.
- Automatikus hitelesítés és lokális multi-profil kezelés.
- Jegyek, órarend, mulasztások, vizsgák és üzenetek gyors lekérdezése ("Összes megtekintése" opcióval).
- Célátlag kalkulátor a szükséges érdemjegyek kiszámításához.
- Globális kereső funkció.
- Naptár exportálása (.ics): Az elkövetkező két hét órarendjének és vizsgáinak kimentése importálható naptárfájlba.
- Windows feladatütemező integráció (háttér-értesítések új jegyek esetén).
- Automatikus frissítés-ellenőrzés a legújabb GitHub verziókhoz.
- Teljesen önálló futtatható állomány (`.exe`), használatához nincs szükség a Dart SDK telepítésére.

## Telepítés

### Letöltés (Ajánlott)
Letöltheted az előre lefordított binárisokat a [Releases](https://github.com/CsPS0/folio-cli/releases) oldalról.

### Csomagkezelők

**Arch Linux (AUR)**
```bash
yay -S folio-cli-bin
```

**macOS (Homebrew)**
```bash
brew tap CsPS0/folio-cli
brew install folio-cli
```

**Windows (Scoop)**
```bash
scoop bucket add folio https://github.com/CsPS0/folio-cli
scoop install folio-cli
```

### Forráskódból történő futtatás és fordítás:
```bash
git clone https://github.com/CsPS0/folio-cli.git
cd folio-cli
dart pub get
dart compile exe bin/folio_cli.dart
dart run
```

## Használat
Az alkalmazás indítása után egy interaktív menürendszer fogad. 
Gyors belépéshez és démon futtatáshoz támogatott argumentumok:
`folio-cli.exe -i <intezmenykod> -u <felhasznalonev> -p <jelszo>` vagy `folio-cli.exe --daemon`

## Dokumentáció
- [USER.md](docs/USER.md): Felhasználói útmutató.
- [DEV.md](docs/DEV.md): Fejlesztői és architektúrális dokumentáció.
- [CONTRIBUTIONS.md](docs/CONTRIBUTIONS.md): Irányelvek hozzájárulóknak.