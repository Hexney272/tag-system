# RealCity Headtag System

NUI-alapú **headtag / player overlay** rendszer FiveM-hez (ESX Legacy). A játékosok fölött nevet, frakciót, állapot-ikonokat és a járművek fölött modern rendszámtáblát jelenít meg — `world-to-screen` technikával (nem `DrawText3D`).

> NUI overlay for FiveM (ESX Legacy): floating player nametags, faction/rank, status icons and modern license plates above vehicles.

---

## ✨ Funkciók

- **Karakternév + szerver ID** a fej fölött (nem a CFX/fiók név)
- **Frakció + rang + jelvényszám** — csak rendőr/mentő/szerelő jobnál, és **csak dutyban**
- **Állapot-ikonok** a név mellett:
  - 🎤 **Mikrofon** — csak beszéd közben, zölden (PMA-voice)
  - 📻 **Rádió** — amikor rádión beszél (PMA-voice)
  - 📱 **Telefon** — ha telefon van a kézben
  - 🛡️ **Páncél** — ha van páncél
  - 🔫 **Fegyver** — ha kint van a fegyver (gyalog)
  - 🔒 **Bilincs** — megbilincselve
  - 🔰 **Biztonsági öv** — járműben (fehér = nincs, zöld = becsatolva)
- **Halott / EMS respawn időzítő** — piros kereszt + `MM:SS` visszaszámláló
- **Modern rendszámtábla** a járművek fölött — csak a játékosok által birtokolt/vezetett autóknál
- **Automatikus elrejtés** ESC / inventory / bármilyen NUI megnyitásakor
- **Optimalizált**: throttle-olt fal-ellenőrzés és jármű-keresés, távolság-alapú méretezés

## 🖼️ Képek

> Tedd a képeket az `images/` mappába, és a hivatkozások automatikusan megjelennek.

| Játékos tagek | Rendőri duty | Rendszámtábla |
|---|---|---|
| ![Tagek](images/showcase_tags.png) | ![Duty](images/showcase_duty.png) | ![Rendszám](images/showcase_plate.png) |

## 📦 Függőségek

- [es_extended](https://github.com/esx-framework/esx_core) (ESX Legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- **Opcionális:** `esx_cruisecontrol` (biztonsági öv B-gombbal), PMA-voice (mikrofon/rádió)

## 🚀 Telepítés

1. Másold a `tag-system` mappát a `resources` közé.
2. A `server.cfg`-ben az ESX és oxmysql **után**:
   ```cfg
   ensure es_extended
   ensure oxmysql
   ensure tag-system
   ```
3. Indítsd újra a szervert. A jelvény-tábla (`tag_system_badges`) automatikusan létrejön.

## ⚙️ Konfiguráció (`config.lua`)

- `Config.PlayerDistance` / `Config.VehicleDistance` — látótávolságok
- `Config.VehicleOffset` — rendszámtábla magassága (kisebb = lejjebb)
- `Config.Plate.Region` — a táblán a régió-felirat (alap: `RealCity`)
- `Config.Icons` — egyes ikonok ki/be kapcsolása
- `Config.ESX.TaggedJobs` — mely jobok mutatnak frakciót (alap: police/ambulance/mechanic)
- `Config.ESX.AutoBadge` — automatikus, egyedi jelvényszámok (1000-től)
- `Config.Seatbelt` — öv-integráció (lásd lent)

## 🔗 Bekötés / Integráció

### Biztonsági öv
A rendszer **automatikusan** az `esx_cruisecontrol` `isSeatbeltOn()` exportját olvassa, így a meglévő **B-gomb** vezérli az ikont. Egyéb esetek:
- Saját öv-szkript eseménnyel: `esx_seatbelt:Enable` / `:Disable`, `seatbelt:toggle` — automatikusan szinkronizál.
- Saját statebag: `Config.Seatbelt.externalStateKey = "a_te_kulcsod"`.
- Nincs öv-rendszer: `Config.Seatbelt.builtIn = true` (beépített B-gomb).

### Szerver oldali exportok
```lua
exports['tag-system']:SetName(source, "Brian Doung")
exports['tag-system']:SetJob(source, { label = "Rendőrség", badge = 1022, grade = "Trainee", onDuty = true })
exports['tag-system']:SetOnDuty(source, true)
exports['tag-system']:SetCuffed(source, true)
exports['tag-system']:SetDead(source, 600)      -- EMS respawn timer (mp)
exports['tag-system']:ClearDead(source)
exports['tag-system']:SetVehicleOwned(vehNetId, true)
```

### Kliens oldali exportok
```lua
exports['tag-system']:SetSeatbelt(true)
exports['tag-system']:SetUsingPhone(true)
```

> ESX-nél a név, job és duty **automatikusan** beáll (`esx:playerLoaded`, `esx:setJob`, `/duty`).

## ⌨️ Parancsok

- `/duty` — szolgálatba lépés/leszállás (police/ambulance/mechanic)
- **Teszt (localhost):** `/tagself`, `/tagname <név>`, `/tagjob "Rendőrség" 1022 Trainee`, `/tagcuff`, `/tagdead [mp]`, `/tagradio`, `/tagphone`, `/tagseat [off|clear]`, `/taggear`, `/tagplate`, `/tagclear`

## 🧩 Statebag kulcsok

| Kulcs | Jelentés |
|---|---|
| `charName` | karakternév |
| `tagJob` | `{ label, badge, grade, onDuty }` |
| `isCuffed` | megbilincselve |
| `deathTime` | respawn lejárati unix idő (mp) |
| `onRadio` / `usingPhone` / `seatbelt` | rádió / telefon / öv |
| `ownedVehicle` (entitásra) | játékos tulajdonú jármű |

---

Készült a **RealCity** szerverhez. ✦
