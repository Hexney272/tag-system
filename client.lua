--[[ RealRP - Headtag rendszer (NUI / world-to-screen) ]]--

local function isUnarmed(ped)
    return GetSelectedPedWeapon(ped) == `WEAPON_UNARMED`
end

-- ============ TESZT / DEBUG ÁLLAPOT ============
-- Localhoston (egyedül) ezzel láthatod a saját tagedet és szimulálhatsz állapotokat.
local debugState = {
    showSelf = false,   -- /tagself  -> saját tag megjelenítése
    name     = nil,     -- /tagname  -> karakternév szimuláció
    cuffed   = false,   -- /tagcuff  -> bilincs szimuláció
    job      = nil,     -- /tagjob   -> frakció/rang sor (onDuty-val)
    deathTime = 0,      -- /tagdead  -> halott-időzítő
    showOwnVehicle = false, -- /tagplate -> saját autó rendszáma
}

-- ============ JÁTÉKOS TAGEK ============
CreateThread(function()
    while true do
        local players = {}
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)

        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            local isSelf = (ped == myPed)

            -- a saját karaktert csak debug-módban mutatjuk
            if DoesEntityExist(ped) and (not isSelf or debugState.showSelf) then
                local coords = GetEntityCoords(ped)
                local dist = #(coords - myCoords)

                if dist <= Config.PlayerDistance then
                    -- saját magunkra nincs értelme fal-ellenőrzést futtatni
                    local visible = isSelf or (not Config.RequireLineOfSight)
                        or HasEntityClearLosToEntity(myPed, ped, 17)

                    if visible then
                        local headCoords = vector3(coords.x, coords.y, coords.z + Config.HeadOffset)
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)

                        if onScreen then
                            local serverId = GetPlayerServerId(player)
                            local st = Player(serverId).state

                            -- távolság alapú skála (közelebb = nagyobb)
                            local scale = 1.0 - (dist / Config.PlayerDistance) * 0.55
                            if scale < 0.45 then scale = 0.45 end

                            local job = st[Config.States.job]
                            local cuffed = st[Config.States.cuffed] or false
                            local deathTime = st[Config.States.dead] or 0

                            -- KARAKTERNÉV a statebag-ből (nem a CFX/fiók név)
                            local charName = st[Config.States.name]

                            -- debug felülírások a saját karakterre
                            if isSelf then
                                if debugState.name then charName = debugState.name end
                                if debugState.cuffed then cuffed = true end
                                if debugState.job then job = debugState.job end
                                if debugState.deathTime > 0 then deathTime = debugState.deathTime end
                            end

                            -- ha nincs karakternév statebag, opcionálisan a CFX név
                            if not charName then
                                if Config.FallbackToCfxName then
                                    charName = GetPlayerName(player)
                                else
                                    charName = nil
                                end
                            end

                            -- frakció + rang CSAK ha a játékos dutyban van
                            local showJob = job and job.label and job.onDuty == true

                            players[#players+1] = {
                                serverId = serverId,
                                name     = charName,
                                talking  = NetworkIsPlayerTalking(player),
                                armour   = GetPedArmour(ped) > 0,
                                weapon   = not isUnarmed(ped),
                                cuffed   = cuffed,
                                dead     = IsPedDeadOrDying(ped, true) or (deathTime > 0),
                                deathRemaining = deathTime > 0 and math.max(0, deathTime - GetCloudTimeAsInt()) or 0,
                                job      = showJob and job or nil,
                                x = sx, y = sy, scale = scale
                            }
                        end
                    end
                end
            end
        end

        SendNUIMessage({ action = "players", players = players })
        Wait(0)
    end
end)

-- ============ TESZT PARANCSOK (kliens oldal, localhost) ============
RegisterCommand('tagself', function()
    debugState.showSelf = not debugState.showSelf
    print(('[tag-system] Sajat tag: %s'):format(debugState.showSelf and 'BE' or 'KI'))
end, false)

RegisterCommand('tagcuff', function()
    debugState.cuffed = not debugState.cuffed
    print(('[tag-system] Bilincs (teszt): %s'):format(debugState.cuffed and 'BE' or 'KI'))
end, false)

-- /tagjob "Sheriff's Office" 1022 Trainee
-- /tagname Brian Doung   -> karakternév szimuláció
RegisterCommand('tagname', function(_, args)
    if #args == 0 then
        debugState.name = nil
        print('[tag-system] Karakternev (teszt) torolve')
        return
    end
    debugState.name = table.concat(args, ' ')
    print(('[tag-system] Karakternev (teszt): %s'):format(debugState.name))
end, false)

-- /tagjob "Sheriff's Office" 1022 Trainee   (a teszthez automatikusan dutyban)
RegisterCommand('tagjob', function(_, args)
    if #args == 0 then
        debugState.job = nil
        print('[tag-system] Job kijelzes torolve')
        return
    end
    debugState.job = {
        label = args[1] or 'Sheriff\'s Office',
        badge = tonumber(args[2]) or nil,
        grade = args[3] or nil,
        onDuty = true,
    }
    print('[tag-system] Job kijelzes beallitva (onDuty = true)')
end, false)

-- /tagdead [masodperc]  (alap: Config.DeathTimer)
RegisterCommand('tagdead', function(_, args)
    local secs = tonumber(args[1]) or Config.DeathTimer
    debugState.deathTime = GetCloudTimeAsInt() + secs
    print(('[tag-system] Halott-idozito (teszt): %d mp'):format(secs))
end, false)

-- minden teszt-allapot torlese
RegisterCommand('tagclear', function()
    debugState.name = nil
    debugState.cuffed = false
    debugState.job = nil
    debugState.deathTime = 0
    print('[tag-system] Teszt allapotok torolve')
end, false)

-- gyors fegyver + pancel a teszteléshez
RegisterCommand('taggear', function()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, `WEAPON_PISTOL`, 250, false, true)
    SetPedArmour(ped, 100)
    print('[tag-system] Pisztoly + pancel kiosztva (fegyver/pancel ikon teszt)')
end, false)

-- saját autó rendszámának megjelenítése (teszt)
RegisterCommand('tagplate', function()
    debugState.showOwnVehicle = not debugState.showOwnVehicle
    print(('[tag-system] Sajat auto rendszam (teszt): %s'):format(debugState.showOwnVehicle and 'BE' or 'KI'))
end, false)

-- ============ JÁRMŰ RENDSZÁMTÁBLÁK ============
-- Csak a játékosok által birtokolt / vezetett autók felett jelenik meg.
local function gatherOwnedVehicles(myVeh)
    local set = {}

    -- 1) Játékosok által elfoglalt járművek
    if Config.PlateShowOccupied then
        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then set[veh] = true end
            end
        end
    end

    -- 2) ownedVehicle statebaggel jelölt (akár parkoló) autók a közelben
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

    -- Saját autó kizárása, ha nem kérted (teszthez /tagplate-tel bekapcsolható)
    if not (Config.PlateShowOwnVehicle or debugState.showOwnVehicle) and myVeh and myVeh ~= 0 then
        set[myVeh] = nil
    end

    return set
end

CreateThread(function()
    while true do
        local vehicles = {}
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local myVeh = GetVehiclePedIsIn(myPed, false)

        for veh, _ in pairs(gatherOwnedVehicles(myVeh)) do
            if DoesEntityExist(veh) then
                local coords = GetEntityCoords(veh)
                local dist = #(coords - myCoords)

                if dist <= Config.VehicleDistance then
                    local _, max = GetModelDimensions(GetEntityModel(veh))
                    local topZ = max.z + Config.VehicleOffset
                    local plateCoords = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, topZ)
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(plateCoords.x, plateCoords.y, plateCoords.z)

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
            brand = Config.Brand,
            server = Config.ServerName
        })

        Wait(0)
    end
end)
