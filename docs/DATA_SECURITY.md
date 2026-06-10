# Adatkezelés és Biztonság (Data & Security)

A Folio CLI fejlesztése során a legmagasabb prioritásként kezeljük a felhasználóink (diákok, tanárok, szülők) oktatási adatainak és hitelesítő információinak biztonságát. Mivel a Folio CLI egy nyílt forráskódú parancssoros eszköz, az adatkezelés teljes mértékben transzparens, és kizárólag a te számítógépeden történik.

Ebben a dokumentumban áttekintjük, hogy az alkalmazás pontosan milyen adatokat kezel, hogyan védi azokat, és hogyan tudod őket maradéktalanul eltávolítani.

## 1. Milyen adatokat tárol a Folio CLI?

A működés érdekében a program a következő információkat menti el a számítógépeden:

*   **Hitelesítő tokenek:** A sikeres bejelentkezést követően a Kréta rendszertől kapott Access (hozzáférési) és Refresh (frissítési) tokenek. **A jelszavadat a program soha nem tárolja el tartósan a lemezen!** A jelszót csak a memóriában tartja addig a néhány másodpercig, amíg a bejelentkezési folyamat a Kréta rendszerével (idp.e-kreta.hu) le nem zajlik, majd az azonnal törlődik a memóriából.
*   **Profil adatok:** A diák neve és az intézmény azonosítója (kódja), hogy egyszerre több profilt is kényelmesen lehessen kezelni (pl. több gyerek esetén).
*   **Gyorsítótár (Cache):** Az utoljára letöltött jegyek, órarend, mulasztások és házi feladatok mentésre kerülnek. Ez teszi lehetővé, hogy a CLI villámgyors legyen, és akkor is lásd a korábbi adataidat, ha a Kréta szerverei éppen elérhetetlenek (Offline mód).

## 2. Hogyan és hol tároljuk az adatokat?

Az adatok a számítógépeden, az operációs rendszered felhasználói mappájában, egy dedikált (általában rejtett) könyvtárban találhatóak:
*   **Windows:** `%USERPROFILE%\.folio` (Pl. `C:\Users\Neved\.folio`)
*   **Linux / macOS:** `~/.folio` (A home könyvtárban)

### Titkosítás (Encryption at Rest)
A tokeneket és profiladatokat tartalmazó konfigurációs fájl (`auth.json`) egy erős, iparági szabványnak megfelelő **AES-256-GCM** titkosítással van levédve. 
A titkosítási kulcsot a Folio CLI automatikusan generálja a számítógéped egyedi hardver- és szoftverjellemzőiből (gépnév, OS, felhasználónév).
*A gyakorlatban ez azt jelenti, hogy ha egy kártékony program vagy egy hacker lemásolná a gépedről a `.folio` mappát, egy másik gépen vagy felhasználói fiókban teljesen esélytelen lesz visszafejtenie és kiolvasnia a Kréta tokenjeidet.*

### Hálózati Biztonság
A Folio CLI **kizárólag** a Kréta hivatalos szervereivel kommunikál, szigorúan titkosított HTTPS/TLS csatornán keresztül. A program nem használ semmilyen saját vagy külső (third-party) analitikai szervert, adatbázist vagy felhőt. Az adataid soha nem hagyják el a gépedet más irányba, csak a Kréta felé.

## 3. Hogyan törölheted (semmisítheted meg) az adataidat?

Mivel a Folio CLI semmilyen felhős infrastruktúrával nem rendelkezik, az adataid felett 100%-os kontrollal rendelkezel. 

Ha ki szeretnél jelentkezni, vagy teljesen meg akarod semmisíteni a program által tárolt adataidat, egyszerűen csak le kell törölnöd a `.folio` mappát a számítógépedről.

### Törlés lépései parancssorból:

**Windows rendszeren:**
```cmd
rmdir /s /q "%USERPROFILE%\.folio"
```

**Linux / macOS rendszeren:**
```bash
rm -rf ~/.folio
```

A mappa törlésével minden tárolt profilod, titkosított tokened és offline gyorsítótárad (cache) azonnal és véglegesen törlődik. A program következő indításakor úgy fog viselkedni, mintha most telepítetted volna először.
