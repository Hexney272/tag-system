Config = {}

-- Távolságok (méterben)
Config.PlayerDistance = 30.0   -- meddig látszanak a játékos-tagek
Config.VehicleDistance = 40.0  -- meddig látszanak a rendszámtáblák

-- Láthatóság
Config.RequireLineOfSight = true   -- HasEntityClearLosToEntity ellenőrzés
Config.HeadOffset = 1.05           -- tag magassága a fej fölött
Config.VehicleOffset = 0.65        -- rendszámtábla magassága a jármű teteje fölött
                                   -- (kisebb = lejjebb a képernyőn)

-- Halott időzítő (másodperc) - EMS respawn timer alapérték
Config.DeathTimer = 600 -- 10 perc

-- ============ RENDSZÁMTÁBLA ============
Config.Plate = {
    Region = "RealCity",   -- a tábla felső sávjában megjelenő régió-felirat
}

-- ============ RENDSZÁMTÁBLA LÁTHATÓSÁG ============
-- FONTOS: Más játékosok járművei MINDIG látszanak, függetlenül ezektől a beállításoktól!
-- Ezek csak a saját járműved és a nem vezetett járművek viselkedését befolyásolják.
Config.PlateShowOccupied = true    -- játékos által vezetett/utazott autók (más játékosoké MINDIG látszik)
Config.PlateShowOwned    = true    -- ownedVehicle statebaggel jelölt (parkoló) autók
Config.PlateShowOwnVehicle = false -- a SAJÁT autód rendszáma is látszódjon-e NEKED

-- Statebag kulcsok (más szkriptek ezeket állítják be)
Config.States = {
    name     = "charName",
    cuffed   = "isCuffed",
    job      = "tagJob",
    dead     = "deathTime",
    owned    = "ownedVehicle",
    radio    = "onRadio",
    phone    = "usingPhone",
    seatbelt = "seatbelt",
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

-- ============ BIZTONSÁGI ÖV ============
-- Háromféleképp köthető be (a kliens mindhármat figyeli):
--  A) Ha a szervered ESX öv-szkriptje eseményt küld (esx_seatbelt:Enable/Disable,
--     seatbelt:toggle, stb.) -> automatikusan szinkronizál, semmit nem kell tenned.
--  B) Ha SAJÁT statebagbe írja az övet (nem a fenti "seatbelt" kulcsba),
--     add meg itt a kulcsot, és tükrözzük: externalStateKey = "az_o_kulcsuk".
--  C) Ha nincs öv-rendszered, kapcsold be a beépített B-gombot: builtIn = true.
Config.Seatbelt = {
    builtIn = false,            -- állítsd true-ra, ha NINCS saját öv-rendszered
    key = 'B',                  -- a beépített öv gombja (RegisterKeyMapping)
    externalStateKey = nil,     -- pl. "seatbelt" vagy "seatbelton", ha más szkript írja
    -- ESX Legacy alap öv-rendszere (esx_cruisecontrol) -> isSeatbeltOn() exportot olvassuk.
    -- Ez a leggyakoribb eset; ha más a resource neve, írd át.
    cruiseControlResource = 'esx_cruisecontrol',
}

-- Telefon automatikus felismerése prop alapján (ha a telefon-szkript nem hív exportot)
Config.AutoDetectPhone = false

-- Ha nincs karakternév statebag, essünk vissza a FiveM-fiók nevére?
Config.FallbackToCfxName = false

-- ============ ESX LEGACY INTEGRÁCIÓ ============
Config.ESX = {
    enabled = true,
    sharedObject = 'es_extended',
    TaggedJobs = {
        police    = "Rendőrség",
        ambulance = "Mentőszolgálat",
        mechanic  = "Szerelő",
    },
    BadgeSource = "meta",
    BadgeMetaKey = "badge",
    BadgeQuery = "SELECT badge FROM users WHERE identifier = ?",
    AutoBadge = true,
    BadgeStart = 1000,
    AutoBadgeJobs = { police = true, ambulance = true, mechanic = true },
    EnableDutyCommand = true,
}

-- ============ MUNKA SZÍNEK ============
-- Minden munkának beállíthatsz egyedi színt (hex formátumban)
-- A rang/grade mindig marad az eredeti sárga szín
Config.JobColors = {
    police    = "#3B82F6",  -- kék
    ambulance = "#EF4444",  -- piros
    mechanic  = "#F59E0B",  -- narancs
    taxi      = "#EAB308",  -- sárga
    reporter  = "#8B5CF6",  -- lila
    realestate = "#10B981", -- zöld
    cardealer = "#06B6D4",  -- ciánkék
    -- Add hozzá további munkákat és színeket ide:
    -- banker    = "#059669",
    -- lawyer    = "#DC2626",
}

-- Színek (referenciaként)
Config.Colors = {
    name  = "#FFFFFF",
    id    = "#BDBDBD",
    voice = "#4CAF50",
    dead  = "#FF4444",
    rank  = "#D4AF37",
}
