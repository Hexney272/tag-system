--[[
    RealRPG Tag System - járműtípusonkénti rendszámtáblák

    Automatikus felismerés:
      - hajó: GTA járműosztály 14
      - helikopter / repülő: GTA járműosztály 15 vagy 16
      - rendőrség / mentő / elektromos: modelllista vagy statebag felülbírálás

    Egy másik kliens script felülbírálhatja a típust:
      Entity(vehicle).state:set('plateType', 'police', true)

    Elfogadott típusok:
      civil, police, ambulance, boat, aircraft, electric
]]

Config.Plate = Config.Plate or {}

Config.Plate.TypeSystem = {
    Enabled = true,
    StateKey = 'plateType',
    ScanInterval = 750,
    ScanDistance = (Config.VehicleDistance or 40.0) + 10.0,

    -- Ha egy 18-as (emergency) osztályú addon jármű nincs a listákban,
    -- ezt a típust kapja. false esetén civil marad.
    -- 'police' = rendőrségi, 'ambulance' = mentő, 'civil' = civil, false = civil
    EmergencyFallback = false,  -- Addon emergency járművek alapértelmezetten civil rendszámot kapnak

    Labels = {
        civil     = Config.Plate.Region or 'RealCity',
        police    = 'RENDŐRSÉG',
        ambulance = 'MENTŐSZOLGÁLAT',
        boat      = 'VÍZI JÁRMŰ',
        aircraft  = 'LÉGI JÁRMŰ',
        electric  = 'E-REALCITY',
    },

    -- Addon járművek modellnevét ide kell felvenni.
    Models = {
        police = {
            'police', 'police2', 'police3', 'police4', 'policeb', 'policet',
            'sheriff', 'sheriff2', 'fbi', 'fbi2', 'pranger', 'riot', 'riot2',
            -- 'sajat_rendor_auto',
        },

        ambulance = {
            'ambulance',
            -- 'sajat_mento_auto',
        },

        electric = {
            'voltic', 'voltic2', 'raiden', 'neon', 'cyclone', 'cyclone2',
            'iwagen', 'omnisegt', 'tezeract', 'virtue', 'khamelion', 'surge',
            -- 'sajat_elektromos_auto',
        },
    },
}
