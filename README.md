# Folio CLI 🚀

Egy modern, gyors és teljesen önálló parancssoros alkalmazás a Kréta e-napló rendszerhez. A hivatalos Kréta mobilalkalmazás (iOS) OAuth2 hitelesítési folyamatait szimulálva képes kikerülni a böngészős korlátozásokat, és közvetlen hozzáférést biztosít a diákok adatlapjához és jegyeihez a terminál kényelméből.

A projekt a szélesebb **Folio ökoszisztéma** (`folio`, `foliomap`, `folioWeb`) hivatalos parancssoros kiegészítője.

## Főbb funkciók
- 🏫 **Beépített intézménykereső:** Nem tudod a suli kódját? Keresd meg a neve alapján!
- 🔐 **Automatikus hitelesítés és Multi-Profil:** Képes több diák profilját is kezelni (Profilváltás), a háttérben biztonságosan tárolva a frissülő tokeneket.
- 🎯 **Kiterjesztett adatelérés:** Jegyek, órarend, mulasztások, vizsgák, házi feladatok és Kréta üzenetek lekérdezése másodpercek alatt.
- 📊 **Célátlag kalkulátor:** Kiszámolja, hány darab és milyen jegy kell még ahhoz, hogy elérd a megálmodott tantárgyi átlagot.
- 🔍 **Globális Kereső:** Egyetlen kulcsszó alapján kereshetsz a jegyeid, házi feladataid és dolgozataid között.
- 📅 **Naptár Export (ICS) és CSV Export:** Exportáld az órarendedet és a dolgozataidat egyenesen a Google/Apple naptáradba, vagy töltsd le az adataidat CSV formátumban!
- 🔔 **Windows Háttér-értesítések:** Állíts be egy beépített háttér-démont (Windows Task Scheduler), ami óránként csekkolja, kaptál-e új jegyet vagy házit, és asztali értesítést (Toast Notification) küld!
- 🎨 **Témák:** Világos és Sötét színtémák, amik tiszteletben tartják a terminálod natív/áttetsző hátterét.

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
*Tipp: Az alkalmazás le is fordítható egyetlen natív .exe fájllá a `dart compile exe bin/folio_cli.dart` paranccsal.*

## Használat
Az indítás után egy interaktív, nyilakkal vezérelhető menü fogad. Csak kövesd a képernyőn megjelenő utasításokat!
Támogatott CLI paraméterek gyors belépéshez és démon futtatáshoz:
`folio_cli.exe -i <intezmenykod> -u <felhasznalonev> -p <jelszo>` vagy `folio_cli.exe --daemon`

## További dokumentációk
Ha elakadtál, vagy mélyebben érdekel a projekt, nézd meg az alábbi leírásokat:
- 📖 [USER.md](USER.md) - Részletes útmutató felhasználóknak, funkciók leírása.
- 🛠️ [DEV.md](DEV.md) - Fejlesztői dokumentáció, fordítási és architektúrális segédlet.
- 🤝 [CONTRIBUTIONS.md](CONTRIBUTIONS.md) - Ha szeretnél beszállni a fejlesztésbe.

## Csapat
A Folio ökoszisztéma csapata:
- **CsPS**
- **Zan**