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

-- Statebag kulcsok (más szkriptek ezeket állítják be a játékosokon)
Config.States = {
    cuffed = "isCuffed",   -- Player(id).state.isCuffed
    job    = "tagJob",     -- { label = "Sheriff's Office", badge = 1022, grade = "Trainee" }
    dead   = "deathTime",  -- unix timestamp (mp), amikor a respawn lejár; 0 = él
}

-- Színek (a CSS-ben is ezek vannak, itt referenciaként)
Config.Colors = {
    name  = "#FFFFFF",
    id    = "#BDBDBD",
    voice = "#4CAF50",
    dead  = "#FF4444",
    rank  = "#D4AF37",
}
