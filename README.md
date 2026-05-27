# Folio CLI

A Folio CLI egy parancssoros alkalmazás a Kréta e-napló rendszerhez. Az iOS alkalmazás OAuth2 hitelesítési folyamatait szimulálva közvetlen terminálos elérést biztosít a diákok adatlapjához és jegyeihez. A projekt a Folio ökoszisztéma hivatalos parancssoros eszköze.

## Főbb funkciók
- Intézménykereső név alapján.
- Automatikus hitelesítés és lokális multi-profil kezelés.
- Jegyek, órarend, mulasztások, vizsgák és üzenetek gyors lekérdezése.
- Célátlag kalkulátor a szükséges érdemjegyek kiszámításához.
- Globális kereső funkció.
- Órarend exportálása ICS naptárformátumba és jegyek mentése CSV-be.
- Windows feladatütemező integráció (háttér-értesítések új jegyek esetén).
- Személyre szabható témák.

## Telepítés

Forráskódból történő futtatás és fordítás:
```bash
git clone https://github.com/te-felhasznaloneved/folio-cli.git
cd folio-cli
dart pub get
dart compile exe bin/folio_cli.dart
```

## Használat
Az alkalmazás indítása után egy interaktív menürendszer fogad. 
Gyors belépéshez és démon futtatáshoz támogatott argumentumok:
`folio_cli.exe -i <intezmenykod> -u <felhasznalonev> -p <jelszo>` vagy `folio_cli.exe --daemon`

## Dokumentáció
- [USER.md](docs/USER.md): Felhasználói útmutató.
- [DEV.md](docs/DEV.md): Fejlesztői és architektúrális dokumentáció.
- [CONTRIBUTIONS.md](docs/CONTRIBUTIONS.md): Irányelvek hozzájárulóknak.