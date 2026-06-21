# Folio CLI
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/CsPS0/folio-cli)](https://github.com/CsPS0/folio-cli/releases)
[![Build Status](https://github.com/CsPS0/folio-cli/actions/workflows/release.yml/badge.svg)](https://github.com/CsPS0/folio-cli/actions)

A Folio CLI egy parancssoros alkalmazás a Kréta e-napló rendszerhez. Az iOS alkalmazás OAuth2 hitelesítési folyamatait szimulálva közvetlen terminálos elérést biztosít a diákok adatlapjához és jegyeihez. A projekt a Folio ökoszisztéma hivatalos parancssoros eszköze.

## Főbb funkciók
- **Élő Dashboard (TUI parancs)**: Parancssoros főoldal automatikus frissítéssel, folyamatban lévő óra hátralévő idejének számlálójával és karbantartási riasztásokkal.
- **Folio Wrapped**: Spotify-stílusú interaktív éves statisztikai összefoglaló (legszorgalmasabb nap, tanári rangsor, késések összesítése, üzenetek statisztikája).
- **Bizonyítvány Tervező & Szellem Jegyek**: Célátlag kalkulátor és hipotetikus jegy szimulátor a tantárgyankénti átlagok javításához.
- **Tantárgyi és Osztályátlagok Részletesen**: Saját átlagod összevetése az osztályátlaggal, eltérések, trendek (↗ / ↘) és jegy-határhelyzet figyelmeztetések.
- **Jegy-trendek & Eloszlás Dashboard**: Dinamikus y-tengelyű éves kumulatív átlagvonal-grafikon és színes érdemjegy eloszlási hisztogram.
- **Globális Haladó Kereső**: Ékezet-érzéketlen keresés a jegyekben, házi feladatokban, órarendben, vizsgákban, üzenetekben és hiányzásokban.
- **Téma Választó & ASCII Banner**: Támogatja a Classic Blue, Neon Matrix (Zöld), Midnight Pink, és Classic Amber témákat testreszabható ASCII főmenü bannerrel.
- **ICS Naptár, CSV és Git Export**: Órarend és jegytörténet mentése standard formátumokba vagy helyi Git repóba.
- **Automatikus OAuth2 Token Frissítés**: Megbízható háttér-hitelesítés párhuzamos API hívások és token lejárás esetén is (fájlkorrupció-elleni védelemmel).
- **Windows UTF-8 & FFI Konzol Mód**: Kényszerített UTF-8 kódolás (`chcp 65001`) az ékezetes karakterek hibátlan megjelenítéséhez és FFI alapú billentyűzet-echo helyreállítás.

## Telepítés

- Egyszerűen: szerezz egy előre megépített futtatható programot [innétről](https://github.com/CsPS0/folio-cli/releases/latest). Ubuntu/Debian/Mint felhasználók számára külön `.deb` telepítőfájl is elérhető!

Ha esetleg nem elérhető a platformodra ([tudasd ezt velünk](https://github.com/CsPS0/folio-cli/issues/new)), nem tetszik az ötlet, vagy nem elég friss:

   <details>
   <summary>Linux bináris kézi futtatása</summary>

> ```bash
> wget https://github.com/CsPS0/folio-cli/releases/download/v1.0.1/folio-cli-linux
> chmod +x folio-cli-linux
> ./folio-cli-linux
> ```

   </details>

   <details>
   <summary>Debian / Ubuntu / Linux Mint (APT)</summary>

> ```bash
> curl -fsSL https://CsPS0.github.io/folio-cli/public.key | sudo gpg --dearmor -o /usr/share/keyrings/folio-cli-archive-keyring.gpg
>
> echo "deb [signed-by=/usr/share/keyrings/folio-cli-archive-keyring.gpg] https://CsPS0.github.io/folio-cli/repo stable main" | sudo tee /etc/apt/sources.list.d/folio-cli.list > /dev/null
>
> sudo apt update
> sudo apt install folio-cli
> ```

   </details>

   <details>
   <summary>Arch Linux (AUR)</summary>

> ```bash
> yay -S folio-cli-bin
> ```
> Ha nincs AUR helper (pl. `yay`) a gépeden:
> ```bash
> git clone https://aur.archlinux.org/folio-cli-bin.git
> cd folio-cli-bin
> makepkg -si
> ```

   </details>

   <details>
   <summary>macOS (Homebrew)</summary>

> ```bash
> brew tap CsPS0/folio-cli https://github.com/CsPS0/folio-cli
> brew install folio-cli
> ```

   </details>

   <details>
   <summary>Windows (Scoop)</summary>

> ```bash
> scoop bucket add folio https://github.com/CsPS0/folio-cli
> scoop install folio-cli
> ```

   </details>

   <details>
   <summary>Forráskódból történő fordítás</summary>

> [Dart SDK](https://dart.dev/get-dart) szükséges.
> ```bash
> git clone https://github.com/CsPS0/folio-cli.git
> cd folio-cli
> dart pub get
> dart compile exe bin/folio_cli.dart
> dart run
> ```

   </details>

## Használat
Ha valamelyik fenti csomagkezelővel telepítetted, az alkalmazást bárhonnan indíthatod a terminálból az alábbi paranccsal:
```bash
folio-cli
```
**Gyors parancsok és argumentumok:**
- `folio-cli dash` : Azonnali belépés az Élő Dashboard (TUI) nézetbe.
- `folio-cli --daemon` : Háttérfolyamat indítása az értesítésekhez.
- `folio-cli -i <intezmenykod> -u <felhasznalonev> -p <jelszo>` : Gyors belépés paraméterekkel.

## Dokumentáció
- [USER.md](docs/USER.md): Felhasználói útmutató.
- [DEV.md](docs/DEV.md): Fejlesztői és architektúrális dokumentáció.
- [CONTRIBUTIONS.md](docs/CONTRIBUTIONS.md): Irányelvek hozzájárulóknak.
- [DATA_SECURITY.md](docs/DATA_SECURITY.md): Adatkezelés és biztonsági tájékoztató.

## Elismerések, alternatívák, hasonló appok, dokumentáció

Minden használatba vett Dart csomagnak köszönet, [itt](./pubspec.yaml) találhatóak.
Kréta dokumentáció: <https://nzx.hu/kreta-api/>
Rengeteg dolgot tartalmazó dokumentáció: <https://docs.zan1456.dev/>

### Működő alternatívák
- [Firka](https://github.com/QwIT-Development/firka) & [firka-legacy](https://github.com/QwIT-Development/app-legacy)
- [Folio](https://github.com/Zan1456/folio)
- [rsfilc](https://github.com/jarjk/rsfilc) (Rust alapú Filc Terminál)

### Archivált projektek
- [Szivacs Napló](https://github.com/boapps/Szivacs-Naplo)
- [Filc](https://github.com/filc)
- [reFilc](https://github.com/Monke14/refilc)