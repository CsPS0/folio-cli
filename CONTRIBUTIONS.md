# Hozzájárulás a Folio CLI-hez (CONTRIBUTIONS) 🤝

Először is köszönjük, hogy érdeklődsz a **Folio CLI** projekt iránt! A nyílt forráskódú közösség ereje abban rejlik, hogy közösen fejlesztünk és segítünk egymásnak. Minden segítséget, legyen az hibajelentés, új funkció kódolása vagy a dokumentáció javítása, örömmel fogadunk!

## Hogyan tudsz segíteni?

### 1. Hibák (Bugok) jelentése 🐛
Ha valami nem úgy működik, ahogy kellene, nyiss egy új **Issue**-t a GitHub repóban.
- Használj beszédes címet!
- Írd le, hogy mi történt, és hogy miként tudjuk reprodukálni a hibát.
- Csatolj képernyőképet vagy terminál kimenetet, de **vigyázz, hogy semmilyen személyes adat (pl. név, oktatási azonosító, jelszó) ne kerüljön a képre**!

### 2. Új funkciók javaslata 💡
Lenne egy jó ötleted, amivel még hasznosabb lehetne a Folio CLI? Nyiss egy Issue-t az ötleteddel! Vázold fel, miért lenne hasznos a diákok számára, és hogyan képzeled el a működését.

### 3. Kódolás (Pull Requestek) 💻
Ha programozó vagy (vagy éppen azzá válsz), és szívesen fejlesztenél a kódon, kövesd ezt a folyamatot:

1. **Forkold** a repository-t a saját GitHub fiókodba.
2. Klónozd a lokális gépedre:
   ```bash
   git clone https://github.com/te-felhasznaloneved/folio-cli.git
   ```
3. Hozz létre egy új branch-et az új funkciónak vagy hibajavításnak:
   ```bash
   git checkout -b feature/uj-fantasztikus-funkcio
   ```
4. Készítsd el a fejlesztést. (Kérjük, kövesd a projekt eddigi kódolási stílusát, és figyelj a Dart nyelv konvencióira!)
5. Futtass egy teszt buildet a saját gépeden:
   ```bash
   dart compile exe bin/folio_cli.dart
   ```
6. Commitold a változtatásokat beszédes, egyértelmű üzenetekkel.
7. Pushold a saját forkodba, majd nyiss egy **Pull Request (PR)**-t az eredeti repó felé!

## Kódolási és Fejlesztési Irányelvek

- **A nyelv:** A Folio CLI hivatalos kommunikációs és UI nyelve a **magyar** (a hazai diákok miatt), a forráskód metódusai, változói viszont szigorúan angol nyelvűek! (pl. `_showSettings()`, de a terminálba kiírva: `"Beállítások"`).
- **Hardkódolt adatok:** **SZIGORÚAN TILOS** bármilyen saját azonosítót, jelszót, tokent vagy konkrét iskola kódját beégetni a forráskódba! Minden hitelesítési adat a felhasználó gépén generálódik és a saját home könyvtárába (`~/.folio_auth.json`) kerül mentésre.
- **Kréta API:** Ha a hivatalos Kréta API-hoz (Ellenőrző V3) nyúlsz, kérlek kezeld le a lehetséges kivételeket. Az API hajlamos megváltoztatni az adatszerkezeteket (pl. Object helyett String-et küld vissza), ezért mindig használj biztonságos típusellenőrzést (`is Map`, null check-ek, opcionális paraméterek)!
- **UI:** A UI elemek generálásához az `interact` csomagot használjuk, kérjük, maradj a meglévő design patternnél (Sötét/Világos téma integráció).

Várjuk a Pull Requesteidet, és építsünk együtt egy villámgyors e-naplót a diákoknak! 🚀
