Config = {}

-- Távolságok (méterben)
Config.PlayerDistance = 30.0   -- meddig látszanak a játékos-tagek
Config.VehicleDistance = 40.0  -- meddig látszanak a rendszámtáblák

-- Láthatóság
Config.RequireLineOfSight = true   -- HasEntityClearLosToEntity ellenőrzés
Config.HeadOffset = 1.05           -- tag magassága a fej fölött
Config.VehicleOffset = 1.5         -- rendszámtábla magassága a jármű fölött

-- Halott időzítő (másodperc) - EMS respawn timer alapérték
Config.DeathTimer = 600 -- 10 perc

-- ============ RENDSZÁMTÁBLA ============
-- A táblán felül megjelenő régió/állam felirat (a kép szerinti modern kinézethez)
Config.Plate = {
    Region = "RealCity",
}

-- ============ RENDSZÁMTÁBLA LÁTHATÓSÁG ============
-- Csak a játékosok által BIRTOKOLT autók felett jelenjen meg a rendszám.
-- "occupied": minden olyan jármű, amelyben épp valódi játékos ül (vezető vagy utas)
-- "owned":    csak az Entity(veh).state.ownedVehicle == true jelzéssel ellátott járművek
Config.PlateShowOccupied = true   -- játékos által vezetett/utazott autók
Config.PlateShowOwned    = true   -- ownedVehicle statebaggel jelölt (parkoló) autók
Config.PlateShowOwnVehicle = false -- a SAJÁT autód rendszáma is látszódjon-e

-- Statebag kulcsok (más szkriptek ezeket állítják be)
Config.States = {
    name     = "charName",     -- Player(id).state.charName -> "Brian Doung" (karakternév)
    cuffed   = "isCuffed",     -- Player(id).state.isCuffed
    job      = "tagJob",       -- { label, badge, grade, onDuty }
    dead     = "deathTime",    -- unix timestamp (mp), amikor a respawn lejár; 0 = él
    owned    = "ownedVehicle", -- Entity(veh).state.ownedVehicle == true (játékos tulajdona)
    radio    = "onRadio",      -- Player(id).state.onRadio   -> rádión beszél (bool)
    phone    = "usingPhone",   -- Player(id).state.usingPhone -> telefon a kézben (bool)
    seatbelt = "seatbelt",     -- Player(id).state.seatbelt  -> bekötött öv (bool)
}

-- Ikon megjelenítési kapcsolók
Config.Icons = {
    mic      = true,   -- mikrofon (CSAK beszéd közben, zölden)
    radio    = true,   -- rádió (ha rádión beszél)
    phone    = true,   -- telefon (ha telefon van a kézben)
    armour   = true,   -- páncél (ha van)
    weapon   = true,   -- fegyver (ha kint van, gyalog)
    cuffed   = true,   -- bilincs
    seatbelt = true,   -- biztonsági öv (csak járműben)
}

-- ============ BEÉPÍTETT BIZTONSÁGI ÖV ============
-- builtIn = true  -> a B gomb be/kikapcsolja az övet, és vezérli az ikont (zöld = bekötve)
-- builtIn = false -> kapcsold ki, ha saját öv-szkripted van; hívd a SetSeatbelt exportot
Config.Seatbelt = {
    builtIn = true,
    key = 'B',
    antiEject = false,     -- true esetén bekötetlenül kirepülsz erős ütközésnél
    ejectThreshold = 18.0, -- sebesség-esés (m/s), ami fölött kirepül (ha antiEject)
}

-- A saját karakteren automatikusan felismerje-e a telefont prop alapján,
-- ha a telefon szkripted nem hívja a SetUsingPhone exportot. (true = bekapcsol)
Config.AutoDetectPhone = false

-- Ha nincs beállítva karakternév statebag, essünk vissza a FiveM-fiók nevére?
Config.FallbackToCfxName = false

-- ============ ESX LEGACY INTEGRÁCIÓ ============
Config.ESX = {
    enabled = true,
    sharedObject = 'es_extended',

    -- Csak ezeknél a job-oknál jelenik meg a frakció-sor, és CSAK dutyban.
    -- kulcs = ESX job neve (xPlayer.job.name), érték = a kijelzett label
    TaggedJobs = {
        police    = "Rendőrség",
        ambulance = "Mentőszolgálat",
        mechanic  = "Szerelő",
    },

    -- Jelvényszám forrása:
    -- "meta"  -> xPlayer.getMeta('badge')  (ESX Legacy metadata, users.metadata JSON-ban)
    -- "query" -> oxmysql lekérdezés a BadgeQuery alapján
    -- false   -> nincs jelvényszám
    BadgeSource = "meta",
    BadgeMetaKey = "badge",
    BadgeQuery = "SELECT badge FROM users WHERE identifier = ?",

    -- AUTOMATIKUS jelvényszám kiosztás (mivel jelenleg nincsenek jelvényszámok).
    AutoBadge = true,
    BadgeStart = 1000,   -- az első kiosztott jelvényszám
    AutoBadgeJobs = { police = true, ambulance = true, mechanic = true },

    -- A /duty parancs engedélyezése a duty-köteles job-oknál
    EnableDutyCommand = true,
}

-- Színek (referenciaként)
Config.Colors = {
    name  = "#FFFFFF",
    id    = "#BDBDBD",
    voice = "#4CAF50",
    dead  = "#FF4444",
    rank  = "#D4AF37",
}
