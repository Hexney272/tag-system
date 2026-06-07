Config = {}

-- Branding (a rendszámtáblán jelenik meg)
Config.Brand = "RealRP"
Config.ServerName = "RealRP szerepjáték szerver"

-- Távolságok (méterben)
Config.PlayerDistance = 30.0   -- meddig látszanak a játékos-tagek
Config.VehicleDistance = 40.0  -- meddig látszanak a rendszámtáblák

-- Láthatóság
Config.RequireLineOfSight = true   -- HasEntityClearLosToEntity ellenőrzés
Config.HeadOffset = 1.05           -- tag magassága a fej fölött
Config.VehicleOffset = 1.5         -- rendszámtábla magassága a jármű fölött

-- Halott időzítő (másodperc) - EMS respawn timer alapérték
Config.DeathTimer = 600 -- 10 perc

-- ============ RENDSZÁMTÁBLA LÁTHATÓSÁG ============
-- Csak a játékosok által BIRTOKOLT autók felett jelenjen meg a rendszám.
-- "occupied": minden olyan jármű, amelyben épp valódi játékos ül (vezető vagy utas)
-- "owned":    csak az Entity(veh).state.ownedVehicle == true jelzéssel ellátott járművek
--             (ezt a saját garázs/ownership szkripted állítja be a parkoló autókon is)
-- A kettő kombinálható: ha PlateShowOccupied = true ÉS PlateShowOwned = true,
-- akkor mindkét feltétel külön-külön elég a megjelenéshez.
Config.PlateShowOccupied = true   -- játékos által vezetett/utazott autók
Config.PlateShowOwned    = true   -- ownedVehicle statebaggel jelölt (parkoló) autók
Config.PlateShowOwnVehicle = false -- a SAJÁT autód rendszáma is látszódjon-e

-- Statebag kulcsok (más szkriptek ezeket állítják be)
Config.States = {
    name   = "charName",       -- Player(id).state.charName -> "Brian Doung" (karakternév)
    cuffed = "isCuffed",       -- Player(id).state.isCuffed
    job    = "tagJob",         -- { label, badge, grade, onDuty }
    dead   = "deathTime",      -- unix timestamp (mp), amikor a respawn lejár; 0 = él
    owned  = "ownedVehicle",   -- Entity(veh).state.ownedVehicle == true (játékos tulajdona)
}

-- Ha nincs beállítva karakternév statebag, essünk vissza a FiveM-fiók nevére?
-- false esetén ilyenkor egyáltalán nem írunk nevet (csak a karakternevet fogadjuk el).
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

    -- oxmysql lekérdezés, ha BadgeSource = "query".
    -- A ? helyére az identifier kerül; az első oszlop értéke lesz a jelvényszám.
    BadgeQuery = "SELECT badge FROM users WHERE identifier = ?",

    -- A /duty parancs engedélyezése a duty-köteles job-oknál
    EnableDutyCommand = true,
}

-- Színek (a CSS-ben is ezek vannak, itt referenciaként)
Config.Colors = {
    name  = "#FFFFFF",
    id    = "#BDBDBD",
    voice = "#4CAF50",
    dead  = "#FF4444",
    rank  = "#D4AF37",
}
