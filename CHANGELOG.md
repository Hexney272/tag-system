# Tag System - Változásnapló

## Új Funkció: Munka-specifikus Színek

### Áttekintés
A tag rendszer most már támogatja a különböző munkákhoz egyedi színek beállítását. A munka neve a hozzárendelt színnel jelenik meg, míg a rang/grade és a jelvényszám (#badge) továbbra is a klasszikus arany színben marad.

### Változtatások

#### 1. Config.lua
Új `Config.JobColors` táblázat hozzáadva, ahol minden munkához egyedi hex színkódot állíthatsz be:

```lua
Config.JobColors = {
    police    = "#3B82F6",  -- kék
    ambulance = "#EF4444",  -- piros
    mechanic  = "#F59E0B",  -- narancs
    taxi      = "#EAB308",  -- sárga
    reporter  = "#8B5CF6",  -- lila
    realestate = "#10B981", -- zöld
    cardealer = "#06B6D4",  -- ciánkék
}
```

#### 2. Client.lua
- Hozzáadva a `jobName` mező a játékos adataihoz (a munka kulcsa, pl. "police", "ambulance")
- A munka színek automatikusan elküldésre kerülnek az NUI-nak a betöltéskor

#### 3. HTML/JS (app.js)
- Új `jobColors` objektum a munka színek tárolására
- A munka sor mostantól három részből áll:
  - `<span class="job-label">` - A munka neve (dinamikus szín)
  - `<span class="badge">` - Jelvényszám (arany)
  - `<span class="rank">` - Rang/grade (arany)

#### 4. CSS (style.css)
- Új CSS struktúra a `.job` osztályhoz
- A `.job-label` dinamikusan kapja a színét JavaScript-ből
- A `.rank` és `.badge` mindig arany színnel jelenik meg (`--c-rank`)

### Használat

#### Új munka szín hozzáadása:
A `config.lua` fájlban add hozzá az új munkát a `Config.JobColors` táblázathoz:

```lua
Config.JobColors = {
    -- Meglévő munkák...
    banker = "#059669",  -- Új munka hozzáadása
    lawyer = "#DC2626",
}
```

#### Szín formátum:
- Hex kód formátumban (`#RRGGBB`)
- 6 karakteres hex kód a # jellel együtt
- Példák: `#3B82F6` (kék), `#EF4444` (piros), `#10B981` (zöld)

### Vizuális Megjelenés

**Előtte:**
```
Rendőrség #1234 Hadnagy
└─ Minden sárga színnel
```

**Utána:**
```
Rendőrség #1234 Hadnagy
└─ "Rendőrség" kék, "#1234" és "Hadnagy" sárga
```

### Megjegyzések
- Ha egy munkához nincs szín beállítva a configban, a munka neve az alapértelmezett (fehér) színnel jelenik meg
- A rang és jelvényszám mindig a `--c-rank` változó szerinti színnel jelennek meg (alapértelmezetten arany: `#D4AF37`)
- A rendszer kompatibilis a meglévő ESX integráció funkcionalitásával

### Tesztelés
A `/tagjob` parancs használható teszteléshez:
```
/tagjob police 1234 Hadnagy
```
