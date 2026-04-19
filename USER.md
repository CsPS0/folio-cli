# Felhasználói Kézikönyv (USER) 🧑‍💻

Üdvözlünk a Folio CLI-ben! Ha elakadtál a terminálban, vagy nem sikerül a bejelentkezés, ez a dokumentum pont neked szól.

## 1. Intézmény kód megadása
A bejelentkezéshez a rendszernek tudnia kell, melyik iskolába jársz. Ezt az **Intézmény kódja** alapján tudja beazonosítani (pl. `bmszc-neumann`).
- **Tudod a kódod?** Csak válaszd az "Igen, tudom a kódját" opciót, és gépeld be!
- **Nem tudod a kódod?** Semmi gond! Válaszd a "Nem, keresés név alapján" lehetőséget. Gépeld be az iskolád nevét (pl. `Neumann`), és a program kilistázza a lehetséges találatokat, amikből a nyilakkal kiválaszthatod a sajátodat.

## 2. Bejelentkezési módok (A legfontosabb lépés)
Mivel a Kréta hivatalos rendszere nagyon szigorú, kétféleképpen is próbálkozhatsz a bejutással:

### A) CLI Automatikus bejelentkezés (Kísérleti) - AJÁNLOTT!
Ez a legegyszerűbb és leggyorsabb módszer. A program teljesen automatikusan elvégzi a bejelentkezést a háttérben.
1. Válaszd ki ezt a módszert a menüből.
2. Add meg a felhasználónevedet (ez általában a 11 jegyű oktatási azonosítód, pl. `72613...`).
3. Add meg a jelszavadat (ami alapértelmezetten a születési dátumod `ÉÉÉÉ-HH-NN` formátumban). **A jelszó gépelése közben biztonsági okokból csak csillagok (`*`) jelennek meg.**
4. Dőlj hátra, a program intézi a többit!

### B) Webes bejelentkezés (Böngészőn keresztül) - TARTALÉK
Ha a Kréta rendszere valamiért visszautasítja az automatikus (A) módszert, ezt az opciót használd!
1. A program meg fog jeleníteni egy nagyon hosszú linket a képernyőn.
2. Kattints rá a linkre (Windows: `Ctrl + Kattintás`), ami megnyílik a böngésződben.
3. Jelentkezz be a hivatalos Kréta felületen.
4. Miután bejelentkeztél, a böngésző át fog dobni egy olyan oldalra, ahol az lesz kiírva, hogy "Nem található", vagy egy `mobil.e-kreta.hu` kezdetű címre jutsz. **Ez normális! Ne ijedj meg!**
5. **Másold ki a teljes címet a böngésződ címsorából**, térj vissza a terminálba, és illeszd be az "Ide másold a linket:" részhez, majd nyomj Entert.

## 3. A menü használata
Sikeres bejelentkezés után egy menüt kapsz, ahol a fel/le nyilakkal navigálhatsz:
- **Tanulói adatlap:** Kiírja a nevedet és az iskolád hivatalos nevét.
- **Legutóbbi jegyek:** Kilistázza a Kréta naplóban szereplő legfrissebb érdemjegyeidet.
- **Kilépés:** Bezárja a programot.

## Gyakori hibák (Troubleshooting)

- **"Nem kaptunk kódot a bejelentkezés végén (statusCode: 200)"**
  *Megoldás:* Valószínűleg elírtad a felhasználónevet vagy a jelszót. Ellenőrizd, hogy az oktatási azonosítód helyes-e, és a jelszavad jó formátumban adtad-e meg (ÉÉÉÉ-HH-NN).

- **"Hiba az intézménykeresés során"**
  *Megoldás:* Ellenőrizd az internetkapcsolatodat, vagy próbálj meg kevesebb karaktert (de minimum 3-at) megadni a keresésnél.

- **A terminál "lefagyott" (Nem reagál a billentyűkre)**
  *Megoldás:* Ritkán előfordulhat Windows terminál esetén. Zárd be a terminál ablakot, nyiss egy újat, és futtasd újra a programot.
