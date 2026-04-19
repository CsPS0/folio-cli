# Folio CLI 🚀

Egy modern, gyors és teljesen önálló parancssoros alkalmazás a Kréta e-napló rendszerhez. A hivatalos Kréta mobilalkalmazás (iOS) OAuth2 hitelesítési folyamatait szimulálva képes kikerülni a böngészős korlátozásokat, és közvetlen hozzáférést biztosít a diákok adatlapjához és jegyeihez a terminál kényelméből.

A projekt a szélesebb **Folio ökoszisztéma** (`folio`, `foliomap`, `folioWeb`) hivatalos parancssoros kiegészítője.

## Főbb funkciók
- 🏫 **Beépített intézménykereső:** Nem tudod a suli kódját? Keresd meg a neve alapján!
- 🔐 **Automatikus hitelesítés:** A háttérben lezajló IDP kommunikáció rejtett HTML `<form>` mezőkön keresztül, iOS álcával.
- 🎯 **Jegyek és adatok lekérdezése:** Másodpercek alatt listázza az utolsó jegyeidet és tanulói információidat.
- 🌐 **Webes tartalék hitelesítés:** Arra az esetre, ha a Kréta API túlságosan szigorítana az automata bejelentkezésen.

## Gyors telepítés
*A csomagkezelőkbe (Scoop, Winget, APT, AUR) való integráció jelenleg folyamatban van.*

Addig is forráskódból futtatható:
```bash
# Repo klónozása
git clone https://github.com/te-felhasznaloneved/folio-cli.git
cd folio-cli

# Függőségek letöltése
dart pub get

# Futattás
dart run
```

## Használat
Az indítás után egy interaktív, nyilakkal vezérelhető menü fogad (köszönhetően az `interact` csomagnak). Csak kövesd a képernyőn megjelenő utasításokat!

```bash
==============================
    Folio CLI (Kréta API)     
==============================
? Tudod az intézmény kódját? › 
❯ Igen, tudom a kódját
  Nem, keresés név alapján
```

## További dokumentációk
Ha elakadtál, vagy mélyebben érdekel a projekt, nézd meg az alábbi leírásokat:
- 📖 [USER.md](USER.md) - Részletes útmutató felhasználóknak, ha elakadtál a bejelentkezéssel.
- 🛠️ [DEV.md](DEV.md) - Fejlesztői dokumentáció, fordítási és csomagkezelőkhöz való feltöltési (publish) segédlet.
- 🤝 [CONTRIBUTIONS.md](CONTRIBUTIONS.md) - Ha szeretnél beszállni a fejlesztésbe.

## Csapat
A Folio ökoszisztéma csapata:
- **CsPS**
- **Zan**