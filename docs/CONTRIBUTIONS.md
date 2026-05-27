# Hozzájárulási Irányelvek

Köszönjük az érdeklődést a Folio CLI projekt iránt. A nyílt forráskódú közösség segítségét (hibajelentések, új funkciók, dokumentáció) minden esetben szívesen fogadjuk.

## Közreműködés Menete

### 1. Hibajelentés (Issue)
Hibák esetén nyiss egy új Issue-t a repository-ban.
- Használj egyértelmű címet.
- Mellékelj reprodukciós lépéseket és terminál kimenetet.
- Személyes adatokat (jelszó, oktatási azonosító) soha ne ossz meg.

### 2. Új Funkciók
Funkciókérések esetén szintén az Issue felület használatos. Írd le a javaslat működését és annak gyakorlati hasznát a felhasználók számára.

### 3. Fejlesztés (Pull Request)
Ha kóddal szeretnél hozzájárulni a projekthez:
1. Készíts egy Forkot a saját GitHub fiókodba.
2. Klónozd a tárolót lokálisan.
3. Hozz létre egy új ágat (branch) a módosításoknak.
4. Készítsd el a fejlesztést a meglévő kódolási konvenciók betartásával.
5. Futtass sikeres teszt buildet (`dart compile exe bin/folio_cli.dart`).
6. Küldj egy Pull Requestet az eredeti repository felé.

## Kódolási Szabályok
- Nyelvhasználat: Az alkalmazás felhasználói felülete magyar nyelvű, a forráskód (változók, függvények) azonban szigorúan angol nyelvű kell maradjon.
- Biztonság: Hardkódolt jelszavak, tokenek vagy intézménykódok elhelyezése a forráskódban szigorúan tilos. Minden hitelesítési adat lokálisan, a felhasználó rendszerében (`~/.folio_auth.json`) tárolódik.
- Hibakezelés: A Kréta API válaszai változatosak lehetnek. Minden adatszerkezet beolvasásánál kötelező a biztonságos típusellenőrzés és a kivételkezelés.
- UI Konvenciók: A terminál interfészekhez az `interact` csomag használandó, a projekt meglévő vizuális irányelveinek (színtémák, háttér megőrzése) tiszteletben tartásával.
