--[[ RealRP - Headtag rendszer (NUI / world-to-screen) ]]--

local function isUnarmed(ped)
    return GetSelectedPedWeapon(ped) == `WEAPON_UNARMED`
end

-- Küldjük el a munka színeket az NUI-nak inicializáláskor
CreateThread(function()
    Wait(500) -- kis késleltetés, hogy az NUI biztosan betöltődjön
    SendNUIMessage({
        action = "setJobColors",
        colors = Config.JobColors or {}
    })
end)

-- ============ TESZT / DEBUG ÁLLAPOT ============
local debugState = {
    showSelf = false,
    name     = nil,
    cuffed   = false,
    job      = nil,
    deathTime = 0,
    showOwnVehicle = false,
    radio    = false,
    phone    = false,
    seatbelt = nil,
}

-- ============ ELREJTÉS (ESC / inventory / bármilyen NUI fókusz) ============
local overlayHidden = false

CreateThread(function()
    local lastHidden = nil
    while true do
        overlayHidden = IsPauseMenuActive() or IsNuiFocused()
        if overlayHidden ~= lastHidden then
            lastHidden = overlayHidden
            SendNUIMessage({ action = "visibility", visible = not overlayHidden })
            if overlayHidden then
                SendNUIMessage({ action = "players", players = {} })
                SendNUIMessage({ action = "vehicles", vehicles = {} })
            end
        end
        Wait(200)
    end
end)

-- ============ LÁTHATÓSÁG (LOS) GYORSÍTÓTÁR ============
-- A HasEntityClearLosToEntity drága, ezért csak ~300 ms-onként frissítjük játékosonként.
local losCache = {}  -- [player] = { visible = bool, t = ms }

local function isVisible(myPed, ped, player)
    if not Config.RequireLineOfSight then return true end
    local now = GetGameTimer()
    local c = losCache[player]
    if c and (now - c.t) < 300 then
        return c.visible
    end
    local vis = HasEntityClearLosToEntity(myPed, ped, 17)
    losCache[player] = { visible = vis, t = now }
    return vis
end

-- ============ JÁTÉKOS TAGEK ============
CreateThread(function()
    while true do
        local sleep = 0

        if overlayHidden then
            sleep = 250
        else
            local players = {}
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                local isSelf = (ped == myPed)

                if DoesEntityExist(ped) and (not isSelf or debugState.showSelf) then
                    local coords = GetEntityCoords(ped)
                    local dist = #(coords - myCoords)

                    if dist <= Config.PlayerDistance and (isSelf or isVisible(myPed, ped, player)) then
                        local headCoords = vector3(coords.x, coords.y, coords.z + Config.HeadOffset)
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)

                        if onScreen then
                            local serverId = GetPlayerServerId(player)
                            local st = Player(serverId).state

                            local scale = 1.0 - (dist / Config.PlayerDistance) * 0.55
                            if scale < 0.45 then scale = 0.45 end

                            local job = st[Config.States.job]
                            local cuffed = st[Config.States.cuffed] or false
                            local deathTime = st[Config.States.dead] or 0
                            local charName = st[Config.States.name]

                            if isSelf then
                                if debugState.name then charName = debugState.name end
                                if debugState.cuffed then cuffed = true end
                                if debugState.job then job = debugState.job end
                                if debugState.deathTime > 0 then deathTime = debugState.deathTime end
                            end

                            if not charName and Config.FallbackToCfxName then
                                charName = GetPlayerName(player)
                            end

                            local showJob = job and job.label and job.onDuty == true
                            local inVehicle = IsPedInAnyVehicle(ped, false)
                            local talking = NetworkIsPlayerTalking(player)

                            local radio    = st[Config.States.radio] or false
                            local phone    = st[Config.States.phone] or false
                            local seatbelt = st[Config.States.seatbelt] or false

                            if isSelf then
                                if debugState.radio then radio = true end
                                if debugState.phone then phone = true end
                                if debugState.seatbelt ~= nil then seatbelt = debugState.seatbelt end
                            end

                            players[#players+1] = {
                                serverId = serverId,
                                name     = charName,
                                mic      = Config.Icons.mic and talking or false,
                                radio    = Config.Icons.radio and radio or false,
                                phone    = Config.Icons.phone and phone or false,
                                armour   = Config.Icons.armour and (GetPedArmour(ped) > 0) or false,
                                weapon   = Config.Icons.weapon and (not isUnarmed(ped)) and (not inVehicle) or false,
                                cuffed   = Config.Icons.cuffed and cuffed or false,
                                seatbeltShow = Config.Icons.seatbelt and inVehicle or false,
                                seatbelt = seatbelt,
                                dead     = IsPedDeadOrDying(ped, true) or (deathTime > 0),
                                deathRemaining = deathTime > 0 and math.max(0, deathTime - GetCloudTimeAsInt()) or 0,
                                job      = showJob and job or nil,
                                jobName  = showJob and job.name or nil,
                                x = sx, y = sy, scale = scale
                            }
                        end
                    end
                end
            end

            SendNUIMessage({ action = "players", players = players })
            -- ha senki sincs a közelben, lassíthatunk
            sleep = (#players > 0) and 0 or 200
        end

        Wait(sleep)
    end
end)

-- ============ TESZT PARANCSOK ============
RegisterCommand('tagself', function()
    debugState.showSelf = not debugState.showSelf
    print(('[tag-system] Sajat tag: %s'):format(debugState.showSelf and 'BE' or 'KI'))
end, false)

RegisterCommand('tagcuff', function()
    debugState.cuffed = not debugState.cuffed
end, false)

RegisterCommand('tagname', function(_, args)
    debugState.name = (#args > 0) and table.concat(args, ' ') or nil
end, false)

RegisterCommand('tagjob', function(_, args)
    if #args == 0 then debugState.job = nil return end
    debugState.job = {
        label = args[1] or 'Sheriff\'s Office',
        badge = tonumber(args[2]) or nil,
        grade = args[3] or nil,
        onDuty = true,
    }
end, false)

RegisterCommand('tagdead', function(_, args)
    local secs = tonumber(args[1]) or Config.DeathTimer
    debugState.deathTime = GetCloudTimeAsInt() + secs
end, false)

RegisterCommand('tagclear', function()
    debugState.name = nil
    debugState.cuffed = false
    debugState.job = nil
    debugState.deathTime = 0
    debugState.radio = false
    debugState.phone = false
    debugState.seatbelt = nil
end, false)

RegisterCommand('tagradio', function() debugState.radio = not debugState.radio end, false)
RegisterCommand('tagphone', function() debugState.phone = not debugState.phone end, false)
RegisterCommand('tagseat', function(_, args)
    local a = args[1]
    if a == 'clear' then debugState.seatbelt = nil
    elseif a == 'off' then debugState.seatbelt = false
    else debugState.seatbelt = true end
end, false)

RegisterCommand('taggear', function()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, `WEAPON_PISTOL`, 250, false, true)
    SetPedArmour(ped, 100)
end, false)

RegisterCommand('tagplate', function()
    debugState.showOwnVehicle = not debugState.showOwnVehicle
end, false)

-- ============ JÁRMŰ RENDSZÁMTÁBLÁK (optimalizált) ============
-- A teljes jármű-lista (FindFirstVehicle) drága, ezért a "birtokolt" halmazt
-- csak ~500 ms-onként frissítjük; a kivetítés viszont minden frame-ben fut.
local ownedSet = {}
local lastOwnedScan = 0

local function refreshOwnedVehicles(myVeh)
    local set = {}

    if Config.PlateShowOccupied then
        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then set[veh] = true end
            end
        end
    end

    if Config.PlateShowOwned then
        local handle, veh = FindFirstVehicle()
        local ok = true
        repeat
            if DoesEntityExist(veh) and Entity(veh).state[Config.States.owned] then
                set[veh] = true
            end
            ok, veh = FindNextVehicle(handle)
        until not ok
        EndFindVehicle(handle)
    end

    if not (Config.PlateShowOwnVehicle or debugState.showOwnVehicle) and myVeh and myVeh ~= 0 then
        set[myVeh] = nil
    end

    return set
end

CreateThread(function()
    while true do
        local sleep = 0

        if overlayHidden then
            sleep = 250
        else
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local myVeh = GetVehiclePedIsIn(myPed, false)

            local now = GetGameTimer()
            if (now - lastOwnedScan) > 500 then
                lastOwnedScan = now
                ownedSet = refreshOwnedVehicles(myVeh)
            end

            local vehicles = {}
            for veh, _ in pairs(ownedSet) do
                if DoesEntityExist(veh) then
                    local coords = GetEntityCoords(veh)
                    local dist = #(coords - myCoords)
                    if dist <= Config.VehicleDistance then
                        local _, max = GetModelDimensions(GetEntityModel(veh))
                        local topZ = max.z + Config.VehicleOffset
                        local pc = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, topZ)
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(pc.x, pc.y, pc.z)
                        if onScreen then
                            local scale = 1.0 - (dist / Config.VehicleDistance) * 0.5
                            if scale < 0.5 then scale = 0.5 end
                            vehicles[#vehicles+1] = {
                                netId = NetworkGetEntityIsNetworked(veh) and VehToNet(veh) or veh,
                                plate = (GetVehicleNumberPlateText(veh) or ""):gsub("%s+$", ""),
                                x = sx, y = sy, scale = scale
                            }
                        end
                    end
                end
            end

            SendNUIMessage({
                action = "vehicles",
                vehicles = vehicles,
                region = Config.Plate and Config.Plate.Region or "RealCity"
            })

            sleep = (#vehicles > 0) and 0 or 250
        end

        Wait(sleep)
    end
end)

-- ============ INTEGRÁCIÓK (saját karakter -> replikált statebag) ============

-- PMA-voice: rádió ikon, amikor rádión beszélsz
AddEventHandler('pma-voice:radioActive', function(talking)
    LocalPlayer.state:set(Config.States.radio, talking and true or false, true)
end)

-- Telefon: a saját telefon-szkripted hívja
exports('SetUsingPhone', function(value)
    LocalPlayer.state:set(Config.States.phone, value and true or false, true)
end)

if Config.AutoDetectPhone then
    local phoneProps = { [`prop_amb_phone`]=true, [`prop_npc_phone`]=true, [`prop_npc_phone_02`]=true, [`p_amb_phone_01`]=true }
    CreateThread(function()
        local last = false
        while true do
            local ped = PlayerPedId()
            local using = false
            for model in pairs(phoneProps) do
                local obj = GetClosestObjectOfType(GetEntityCoords(ped), 1.0, model, false, false, false)
                if obj ~= 0 and IsEntityAttachedToEntity(obj, ped) then using = true break end
            end
            if using ~= last then
                last = using
                LocalPlayer.state:set(Config.States.phone, using, true)
            end
            Wait(700)
        end
    end)
end

-- ============ BIZTONSÁGI ÖV ============
-- A saját öv-állapotodat replikált statebagbe írjuk, hogy mások lássák az ikont.
local belted = false
local function setBelt(state)
    state = state and true or false
    if state ~= belted then
        belted = state
        LocalPlayer.state:set(Config.States.seatbelt, belted, true)
    end
end

-- export más szkripteknek
exports('SetSeatbelt', function(v) setBelt(v) end)
exports('ToggleSeatbelt', function() setBelt(not belted) end)
exports('IsSeatbelted', function() return belted end)

-- 1) ESX / közismert öv-szkriptek eseményeire rákötés (ha a szervered ilyet küld)
RegisterNetEvent('esx_seatbelt:Enable',  function() setBelt(true)  end)
RegisterNetEvent('esx_seatbelt:Disable', function() setBelt(false) end)
AddEventHandler('seatbelt:toggle',       function(s) setBelt(s) end)
AddEventHandler('seatbelt:client:toggle',function(s) setBelt(s) end)
AddEventHandler('seatbelt:state',        function(s) setBelt(s) end)

-- 2) Külső statebag tükrözése (ha az ESX/öv-szkripted SAJÁT statebagbe írja az övet,
--    add meg a kulcsát a configban: Config.Seatbelt.externalStateKey)
if Config.Seatbelt and Config.Seatbelt.externalStateKey and Config.Seatbelt.externalStateKey ~= Config.States.seatbelt then
    AddStateBagChangeHandler(Config.Seatbelt.externalStateKey, ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
        setBelt(value and true or false)
    end)
end

-- 3) Beépített B-gomb (csak ha nincs saját öv-rendszered) + kiszálláskor reset
if Config.Seatbelt and Config.Seatbelt.builtIn then
    RegisterCommand('+rrp_seatbelt', function()
        if not IsPedInAnyVehicle(PlayerPedId(), false) then return end
        setBelt(not belted)
        PlaySoundFrontend(-1, belted and 'SELECT' or 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end, false)
    RegisterKeyMapping('+rrp_seatbelt', 'Biztonsági öv be/ki', 'keyboard', Config.Seatbelt.key or 'B')
end

-- öv visszaállítása kiszálláskor (minden módban)
CreateThread(function()
    while true do
        local inVeh = IsPedInAnyVehicle(PlayerPedId(), false)
        if not inVeh and belted then setBelt(false) end
        Wait(1000)
    end
end)



-- 4) ESX_CRUISECONTROL integráció (ez az ESX Legacy alap öv-rendszere)
--    Az esx_cruisecontrol exportál egy isSeatbeltOn() függvényt; ezt olvassuk,
--    így a meglévő B-gomb (amit az ESX kezel) vezérli az ikont, ütközés nélkül.
local ccResource = (Config.Seatbelt and Config.Seatbelt.cruiseControlResource) or 'esx_cruisecontrol'
CreateThread(function()
    -- megvárjuk, míg az erőforrás elindul
    while GetResourceState(ccResource) ~= 'started' do
        Wait(2000)
    end
    -- van isSeatbeltOn export?
    local ok = pcall(function() return exports[ccResource]:isSeatbeltOn() end)
    if not ok then
        print(('[tag-system] %s nem ad isSeatbeltOn exportot - ov integracio kihagyva'):format(ccResource))
        return
    end
    print(('[tag-system] Ov integracio bekotve: %s'):format(ccResource))
    while true do
        local inVeh = IsPedInAnyVehicle(PlayerPedId(), false)
        if inVeh then
            local on = exports[ccResource]:isSeatbeltOn()
            setBelt(on and true or false)
            Wait(250)
        else
            if belted then setBelt(false) end
            Wait(1000)
        end
    end
end)
