# Felhasználói Kézikönyv

A Folio CLI egy parancssoros Kréta e-napló kliens. Ez a dokumentum a főbb funkciók használatát mutatja be.

## 1. Bejelentkezés
Az első indításkor meg kell adni az intézmény kódját (pl. `bmszc-neumann`). Ha nem tudod a kódot, használd a beépített keresőt az iskola neve alapján.
A bejelentkezéshez az oktatási azonosítóra és a jelszóra (általában a születési dátum: ÉÉÉÉ-HH-NN) van szükség. Sikeres belépés után a profil menthető, így a továbbiakban a bejelentkezés automatikus.

## 2. Főmenü Funkciók
- Tanulói adatlap: Személyes adatok és Célátlag kalkulátor.
- Legutóbbi jegyek: A legfrissebb érdemjegyek listája.
- Órarend: Dinamikus, táblázatos nézet az e heti és jövő heti órákról.
- Mulasztások: Igazolt és igazolatlan hiányzások.
- Tantárgyi átlagok: Színkódolt oszlopdiagram.
- Számonkérések & Házi feladatok: Vizsgák és beadandók határidőkkel.
- Üzenetek: A Kréta üzenőfal elérése.
- Keresés: Globális kereső a napló teljes tartalmában.

## 3. Haladó Funkciók
- Naptár exportálása (.ics): Az elkövetkező két hét órarendjének és vizsgáinak kimentése importálható naptárfájlba.
- Adatok exportálása (CSV): Jegyek és mulasztások táblázatos kimentése.
- Beállítások:
  - Profilváltás: Váltás a mentett fiókok között.
  - Téma beállítása: Világos és sötét terminál témák.
  - Háttér-értesítések: Windows Feladatütemező integráció. A háttérben futva óránként és bejelentkezéskor ellenőrzi az új jegyeket, majd értesítést küld.

## 4. Hibaelhárítás
- Hálózati vagy API hibák: A Kréta szervereinek túlterheltsége vagy az API módosulása okozhatja. A program beépített védelemmel rendelkezik a leggyakoribb hibák (pl. V3 végpontok) ellen.
- Megjelenítési hibák: Ékezet- és táblázatproblémák esetén javasolt a terminál (PowerShell/CMD) frissítése és a Folio legújabb verziójának használata.
- Lefagyás: Windows terminál esetén előfordulhat eseménykezelési hiba. Ilyenkor a `Ctrl+C` vagy az ablak bezárása, majd újraindítás jelent megoldást.
