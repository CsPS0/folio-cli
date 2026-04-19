# Fejlesztői Dokumentáció (DEV) 🛠️

Ez a dokumentum a projekt architektúráját, a fordítási folyamatot (compilation) és a különböző csomagkezelőkön (Scoop, Winget, AUR, APT) való publikálás részleteit tartalmazza.

## Architektúra és Hitelesítés
A Kréta zárt rendszere miatt hagyományos webes bejelentkezéssel nem érhetőek el a publikus API végpontok (invalid_grant hiba). Ezt a CLI úgy kerüli meg, hogy **teljesen leutánozza a hivatalos iOS alkalmazás** hálózati forgalmát:
1. Felvesszük a mobilalkalmazás `User-Agent`-jét (`eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0`).
2. Generálunk egy OAuth2 implicit flow-t egyedi `code_challenge` és `clientId` használatával az `idp.e-kreta.hu` felé.
3. A háttérben kezeljük a `.AspNetCore.Identity.Application` és `idp.session` sütiket (Cookie state management).
4. Egy speciális `POST` kérést indítunk az `/Account/Login` végpontra, ahol átadjuk az oktatási azonosítót és a jelszót.
5. Végül kinyerjük a titkos `code`-ot a Kréta válaszának rejtett `<form>` mezőiből, és ezt beváltjuk a tényleges `accessToken`-re a Kréta WebAPI eléréséhez.

## Fordítás natív alkalmazássá (Compilation)
Ahhoz, hogy a felhasználóknak ne kelljen a teljes Dart SDK-t telepíteniük, a programot natív, önálló (standalone) binárisként osztjuk el.

Windows, Linux és macOS alatt a fordítás azonos paranccsal történik:
```bash
dart compile exe bin/folio_cli.dart -o folio-cli.exe
```
Ez létrehoz egy független `folio-cli.exe` (vagy Linuxon `folio-cli`) fájlt.

## Publikálás csomagkezelőkbe

Miután a GitHub Releases alá fel lett töltve a bináris fájl (pl. v1.0.0 kiadás), az alábbi módon vihetjük fel a csomagkezelőkbe:

### 1. Scoop (Windows)
A Scoop egy JSON manifest fájl alapján működik. Létre kell hozni egy saját GitHub repót (Scoop Bucket), és abba egy `folio-cli.json` fájlt:
```json
{
    "version": "1.0.0",
    "description": "Folio CLI for Kréta e-napló.",
    "homepage": "https://github.com/te-neved/folio-cli",
    "license": "MIT",
    "url": "https://github.com/te-neved/folio-cli/releases/download/v1.0.0/folio-cli.exe",
    "hash": "IDE_JÖN_A_SHA256_HASH_A_FÁJLRÓL",
    "bin": "folio-cli.exe"
}
```

### 2. Winget (Windows)
A Microsoft hivatalos csomagkezelőjébe a `microsoft/winget-pkgs` repóba küldött Pull Requesttel lehet bekerülni. Egy YAML fájlt kell készíteni a projekt metaadataival:
`manifests/f/FolioTeam/FolioCLI/1.0.0/FolioTeam.FolioCLI.installer.yaml`
```yaml
PackageIdentifier: FolioTeam.FolioCLI
PackageVersion: 1.0.0
InstallerType: portable
Installers:
  - Architecture: x64
    InstallerUrl: https://github.com/te-neved/folio-cli/releases/download/v1.0.0/folio-cli.exe
    InstallerSha256: IDE_JÖN_A_SHA256_HASH
```

### 3. AUR (Arch Linux)
Az Arch User Repository-ban egy `PKGBUILD` fájlt kell létrehozni. Két opció van:
- `folio-cli-bin`: Direktbe a GitHubról tölti le a bináris futtatható állományt.
- `folio-cli`: A felhasználó gépén a `dart` segítségével fordul le a forráskódból.

Példa `PKGBUILD` a `-bin` verzióhoz:
```bash
pkgname=folio-cli-bin
pkgver=1.0.0
pkgrel=1
pkgdesc="Folio CLI for Kréta e-napló"
arch=('x86_64')
url="https://github.com/te-neved/folio-cli"
license=('MIT')
provides=('folio-cli')
conflicts=('folio-cli')
source=("${url}/releases/download/v${pkgver}/folio-cli-linux")
sha256sums=('IDE_JÖN_A_SHA256_HASH')

package() {
    install -Dm755 "${srcdir}/folio-cli-linux" "${pkgdir}/usr/bin/folio-cli"
}
```

### 4. APT (Debian/Ubuntu)
Ehhez egy hagyományos Debian `.deb` csomagot kell készíteni `dpkg-deb` segítségével.
1. Hozd létre a struktúrát: `folio-cli_1.0.0_amd64/usr/bin/`
2. Másold be a lefordított binárist a `usr/bin/` mappába.
3. Hozd létre a `folio-cli_1.0.0_amd64/DEBIAN/control` fájlt a csomag adataival.
4. Futtasd: `dpkg-deb --build folio-cli_1.0.0_amd64`
Az így elkészült `.deb` fájlt felteheted a GitHub Releases-hez.
