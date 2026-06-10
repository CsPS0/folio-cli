# Folio CLI
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/CsPS0/folio-cli)](https://github.com/CsPS0/folio-cli/releases)
[![Build Status](https://github.com/CsPS0/folio-cli/actions/workflows/release.yml/badge.svg)](https://github.com/CsPS0/folio-cli/actions)

A Folio CLI egy parancssoros alkalmazás a Kréta e-napló rendszerhez. Az iOS alkalmazás OAuth2 hitelesítési folyamatait szimulálva közvetlen terminálos elérést biztosít a diákok adatlapjához és jegyeihez. A projekt a Folio ökoszisztéma hivatalos parancssoros eszköze.

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

### Letöltés (Manuális / Ajánlott)
Töltsd le az előre lefordított binárisokat a [Releases](https://github.com/CsPS0/folio-cli/releases) oldalról. Ubuntu/Debian/Mint felhasználók számára külön `.deb` telepítőfájl is elérhető!

**Linux bináris futtatása lépésről lépésre:**
```bash
# 1. Töltsd le a fájlt a gépedre:
wget https://github.com/CsPS0/folio-cli/releases/download/v1.0.1/folio-cli-linux

# 2. Adj neki futtatási jogosultságot:
chmod +x folio-cli-linux

# 3. Indítsd el az alkalmazást:
./folio-cli-linux
```

### Csomagkezelők

**Debian / Ubuntu / Linux Mint (APT Repository)**
A program elérhető egy hivatalos APT csomagtárolóból is, így az operációs rendszer automatikusan tudja frissíteni.
```bash
# 1. Hozzáadjuk a hitelesítő kulcsot
curl -fsSL https://CsPS0.github.io/folio-cli/public.key | sudo gpg --dearmor -o /usr/share/keyrings/folio-cli-archive-keyring.gpg

# 2. Hozzáadjuk a tárolót a rendszerhez
echo "deb [signed-by=/usr/share/keyrings/folio-cli-archive-keyring.gpg] https://CsPS0.github.io/folio-cli/repo stable main" | sudo tee /etc/apt/sources.list.d/folio-cli.list > /dev/null

# 3. Telepítés
sudo apt update
sudo apt install folio-cli
```

**Arch Linux (AUR)**
```bash
yay -S folio-cli-bin
```
*Ha nincs AUR helper (pl. `yay`) a gépeden, vagy a csomag még nem indexelődött, telepítheted manuálisan is:*
```bash
git clone https://aur.archlinux.org/folio-cli-bin.git
cd folio-cli-bin
makepkg -si
```

**macOS (Homebrew)**
```bash
brew tap CsPS0/folio-cli https://github.com/CsPS0/folio-cli
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
Ha valamelyik fenti csomagkezelővel telepítetted, az alkalmazást bárhonnan indíthatod a terminálból az alábbi paranccsal:
```bash
folio-cli
```
Gyors belépéshez és démon futtatáshoz támogatott argumentumok:
`folio-cli -i <intezmenykod> -u <felhasznalonev> -p <jelszo>` vagy `folio-cli --daemon`

## Dokumentáció
- [USER.md](docs/USER.md): Felhasználói útmutató.
- [DEV.md](docs/DEV.md): Fejlesztői és architektúrális dokumentáció.
- [CONTRIBUTIONS.md](docs/CONTRIBUTIONS.md): Irányelvek hozzájárulóknak.
- [DATA_SECURITY.md](docs/DATA_SECURITY.md): Adatkezelés és biztonsági tájékoztató.