--[[ RealRP - Headtag rendszer (szerver oldal)
     Keretrendszer-független statebag kezelés.
     Más szkriptek az alábbi exportokkal állíthatják be az állapotokat. ]]--

-- Karakternév beállítása (ez jelenik meg a fej fölött a CFX/fiók név helyett)
-- pl. exports['tag-system']:SetName(source, "Brian Doung")
local function SetName(playerId, charName)
    Player(playerId).state:set(Config.States.name, charName, true)
end

-- Bilincs állapot (replikált statebag)
-- pl. exports['tag-system']:SetCuffed(source, true)
local function SetCuffed(playerId, value)
    Player(playerId).state:set(Config.States.cuffed, value and true or false, true)
end

-- Munka / rang kijelzés a név alatt.
-- FONTOS: a frakció + rang CSAK akkor jelenik meg, ha onDuty = true.
-- pl. exports['tag-system']:SetJob(source, {
--        label = "Sheriff's Office", badge = 1022, grade = "Trainee", onDuty = true })
local function SetJob(playerId, jobData)
    Player(playerId).state:set(Config.States.job, jobData, true)
end

-- Duty állapot gyors váltása a meglévő job adat megtartásával
-- pl. exports['tag-system']:SetOnDuty(source, true)
local function SetOnDuty(playerId, onDuty)
    local job = Player(playerId).state[Config.States.job]
    if type(job) == 'table' then
        job.onDuty = onDuty and true or false
        Player(playerId).state:set(Config.States.job, job, true)
    end
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

exports('SetName', SetName)
exports('SetCuffed', SetCuffed)
exports('SetJob', SetJob)
exports('SetOnDuty', SetOnDuty)
exports('SetDead', SetDead)
exports('ClearDead', ClearDead)

-- Jármű "játékos tulajdona" jelölése (parkoló autók rendszáma is megjelenik)
-- pl. exports['tag-system']:SetVehicleOwned(vehicleNetId, true)
local function SetVehicleOwned(vehNetId, value)
    local ent = NetworkGetEntityFromNetworkId(vehNetId)
    if ent and ent ~= 0 then
        Entity(ent).state:set(Config.States.owned, value and true or false, true)
    end
end
exports('SetVehicleOwned', SetVehicleOwned)

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
