# Felhasználói Kézikönyv (USER) 🧑‍💻

Üdvözlünk a Folio CLI-ben! A Folio egy terminál-alapú Kréta e-napló kliens, amivel szupergyorsan és hatékonyan férhetsz hozzá az iskolai adataidhoz.

## 1. Első bejelentkezés
A legelső indításkor a program megkérdezi az intézményed kódját:
- **Tudod a kódod?** Válaszd az "Igen, tudom a kódját" opciót (pl. `bmszc-neumann`).
- **Nem tudod a kódod?** Válaszd a "Nem, keresés név alapján" lehetőséget. Gépeld be az iskolád nevét (pl. `Neumann`), és válaszd ki a listából!

Ezután a **CLI Automatikus bejelentkezést** érdemes választanod, ami bekéri az oktatási azonosítódat (11 jegyű szám) és a jelszavadat (általában a születési dátumod `ÉÉÉÉ-HH-NN` formátumban). A jelszót biztonsági okokból rejtve gépelheted be. A bejelentkezés sikeres végrehajtása után a profilod elmentődik, így legközelebb már nem kell beírnod az adataidat!

## 2. Főmenü Funkciók
A nyilakkal navigálhatsz, Enterrel választhatsz:
- **Tanulói adatlap:** Személyes adataid, és a különleges **Célátlag kalkulátor**, amivel kiszámolhatod, mennyi és milyen jegy kell még az áhított átlagodhoz!
- **Legutóbbi jegyek:** Kilistázza a legfrissebb érdemjegyeidet.
- **Órarend:** A terminál szélességéhez dinamikusan alkalmazkodó táblázatos órarend, e heti és jövő heti nézettel.
- **Mulasztások:** Igazolt és igazolatlan hiányzások részletes listája.
- **Tantárgyi átlagok:** Az aktuális tantárgyi átlagaid színkódolt oszlopdiagrammal vizualizálva.
- **Számonkérések & Házi feladatok:** Itt láthatod a dolgozataidat és a házikat, a lejárat dátumával és a feladat leírásával.
- **Üzenetek:** A Kréta rendszeres üzeneteinek böngészése.
- **Keresés:** Egy szupergyors globális kereső, amivel egyszerre tudsz keresni a jegyeid, házi feladataid és vizsgáid szövegében.

## 3. Extra Funkciók (Exportálás és Démön)
A Folio CLI túlmutat egy egyszerű naplón:
- **Naptár exportálása (.ics):** Kimenti az elkövetkező 2 hét órarendjét és dolgozatait a Windows Asztalodra egy naptárfájlba, amit egy kattintással importálhatsz Google vagy Apple Naptárba.
- **Adatok exportálása (CSV):** Kimenti a teljes évi jegy- és mulasztás-kivonatodat a projekt mappájába táblázatkezelővel (Excel) nyitható formátumba.
- **Beállítások:**
  - **Profilváltás:** Ha testvéred is van, vagy több iskolába jársz, itt válthatsz a fiókok között anélkül, hogy mindig újra be kéne jelentkezni.
  - **Téma beállítása:** Válassz a Sötét és Világos témák közül, melyek a terminálod natív hátterét is megőrzik!
  - **Háttér-értesítések beállítása (Windows):** Bekapcsolhatod a Démont, ami bekerül a Windows Feladatütemezőjébe. Óránként a háttérben (láthatatlanul) csekkolja a Krétát, és Windowsos felugró értesítést (Toast) küld, ha új jegyet vagy házit kaptál!

## 4. Gyakori hibák (Troubleshooting)
- **"Hiba az API lekérdezés során / Ismeretlen hiba történt"**
  *Megoldás:* A Kréta szerverei túlterheltek lehetnek, vagy módosult az API struktúrájuk. A legtöbb végpontnál beépítettünk védekezést (pl. 30 napos alapértelmezett intervallum), de időnként frissítened kellhet a Folio CLI-t.
- **Nem látszódnak jól az ékezetek vagy a táblázat vonalai?**
  *Megoldás:* Frissíts a legújabb verzióra, a kódolási és "Mojibake" problémákat teljeskörűen javítottuk a terminálok (PowerShell/CMD) számára is.
- **A program lefagyott, nem reagál a billentyűkre**
  *Megoldás:* Zárd be az ablakot (`Ctrl+C` vagy piros X), majd futtasd újra. Ritkán a Windows terminál eseménykezelője beakadhat.
