--[[ RealRP - Headtag rendszer (szerver oldal)
     Keretrendszer-független statebag kezelés.
     Más szkriptek az alábbi exportokkal állíthatják be az állapotokat. ]]--

-- Bilincs állapot (replikált statebag)
-- pl. exports['tag-system']:SetCuffed(source, true)
local function SetCuffed(playerId, value)
    Player(playerId).state:set(Config.States.cuffed, value and true or false, true)
end

-- Munka / rang kijelzés a név alatt
-- pl. exports['tag-system']:SetJob(source, { label = "Sheriff's Office", badge = 1022, grade = "Trainee" })
local function SetJob(playerId, jobData)
    Player(playerId).state:set(Config.States.job, jobData, true)
end

-- Halott állapot + EMS respawn időzítő indítása
-- duration = másodperc (nil esetén Config.DeathTimer)
local function SetDead(playerId, duration)
    local secs = duration or Config.DeathTimer
    local until_ts = os.time() + secs
    Player(playerId).state:set(Config.States.dead, until_ts, true)
end

-- Feltámasztás / időzítő törlése
local function ClearDead(playerId)
    Player(playerId).state:set(Config.States.dead, 0, true)
end

exports('SetCuffed', SetCuffed)
exports('SetJob', SetJob)
exports('SetDead', SetDead)
exports('ClearDead', ClearDead)

-- Alapértékek beállítása csatlakozáskor
AddEventHandler('playerJoining', function()
    local src = source
    Player(src).state:set(Config.States.cuffed, false, true)
    Player(src).state:set(Config.States.dead, 0, true)
end)

-- Hálózati esemény, ha kliens oldalról szeretnéd vezérelni (opcionális)
RegisterNetEvent('tag-system:setDead', function(duration)
    SetDead(source, duration)
end)

RegisterNetEvent('tag-system:clearDead', function()
    ClearDead(source)
end)
