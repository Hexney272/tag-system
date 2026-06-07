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
    radio    = false,   -- /tagradio
    phone    = false,   -- /tagphone
    seatbelt = nil,     -- /tagseat  (nil = nincs felülírás)
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

        Wait(150)
    end
end)

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
                    local visible = isSelf or (not Config.RequireLineOfSight)
                        or HasEntityClearLosToEntity(myPed, ped, 17)

                    if visible then
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

                            -- debug felülírások a saját karakterre
                            if isSelf then
                                if debugState.name then charName = debugState.name end
                                if debugState.cuffed then cuffed = true end
                                if debugState.job then job = debugState.job end
                                if debugState.deathTime > 0 then deathTime = debugState.deathTime end
                            end

                            if not charName then
                                if Config.FallbackToCfxName then
                                    charName = GetPlayerName(player)
                                else
                                    charName = nil
                                end
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
                                -- mikrofon CSAK beszéd közben (mindig zölden)
                                mic      = Config.Icons.mic and talking or false,
                                radio    = Config.Icons.radio and radio or false,
                                phone    = Config.Icons.phone and phone or false,
                                armour   = Config.Icons.armour and (GetPedArmour(ped) > 0) or false,
                                -- fegyver ikon NEM látszik járműben (csak gyalog)
                                weapon   = Config.Icons.weapon and (not isUnarmed(ped)) and (not inVehicle) or false,
                                cuffed   = Config.Icons.cuffed and cuffed or false,
                                -- öv csak járműben jelenik meg
                                seatbeltShow = Config.Icons.seatbelt and inVehicle or false,
                                seatbelt = seatbelt,
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

        if not overlayHidden then
            SendNUIMessage({ action = "players", players = players })
        end
        Wait(overlayHidden and 250 or 0)
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

RegisterCommand('tagdead', function(_, args)
    local secs = tonumber(args[1]) or Config.DeathTimer
    debugState.deathTime = GetCloudTimeAsInt() + secs
    print(('[tag-system] Halott-idozito (teszt): %d mp'):format(secs))
end, false)

RegisterCommand('tagclear', function()
    debugState.name = nil
    debugState.cuffed = false
    debugState.job = nil
    debugState.deathTime = 0
    debugState.radio = false
    debugState.phone = false
    debugState.seatbelt = nil
    print('[tag-system] Teszt allapotok torolve')
end, false)

RegisterCommand('tagradio', function()
    debugState.radio = not debugState.radio
    print(('[tag-system] Radio ikon (teszt): %s'):format(debugState.radio and 'BE' or 'KI'))
end, false)

RegisterCommand('tagphone', function()
    debugState.phone = not debugState.phone
    print(('[tag-system] Telefon ikon (teszt): %s'):format(debugState.phone and 'BE' or 'KI'))
end, false)

-- /tagseat | /tagseat off | /tagseat clear
RegisterCommand('tagseat', function(_, args)
    local a = args[1]
    if a == 'clear' then
        debugState.seatbelt = nil
        print('[tag-system] Ov feluliras torolve')
    elseif a == 'off' then
        debugState.seatbelt = false
        print('[tag-system] Ov (teszt): KICSATOLVA (feher)')
    else
        debugState.seatbelt = true
        print('[tag-system] Ov (teszt): BECSATOLVA (zold)')
    end
end, false)

RegisterCommand('taggear', function()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, `WEAPON_PISTOL`, 250, false, true)
    SetPedArmour(ped, 100)
    print('[tag-system] Pisztoly + pancel kiosztva')
end, false)

RegisterCommand('tagplate', function()
    debugState.showOwnVehicle = not debugState.showOwnVehicle
    print(('[tag-system] Sajat auto rendszam (teszt): %s'):format(debugState.showOwnVehicle and 'BE' or 'KI'))
end, false)

-- ============ JÁRMŰ RENDSZÁMTÁBLÁK ============
local function gatherOwnedVehicles(myVeh)
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

        if not overlayHidden then
            SendNUIMessage({
                action = "vehicles",
                vehicles = vehicles,
                region = Config.Plate and Config.Plate.Region or "RealCity"
            })
        end

        Wait(overlayHidden and 250 or 0)
    end
end)

-- ============ INTEGRÁCIÓK (saját karakter -> replikált statebag) ============

-- PMA-voice: rádió ikon, amikor rádión beszélsz
AddEventHandler('pma-voice:radioActive', function(talking)
    LocalPlayer.state:set(Config.States.radio, talking and true or false, true)
end)

-- Kliens exportok más szkripteknek (öv/telefon rendszerek bekötéséhez)
exports('SetSeatbelt', function(value)
    LocalPlayer.state:set(Config.States.seatbelt, value and true or false, true)
end)

exports('SetUsingPhone', function(value)
    LocalPlayer.state:set(Config.States.phone, value and true or false, true)
end)

-- Opcionális: telefon automatikus felismerése a saját karakteren (prop alapján)
if Config.AutoDetectPhone then
    local phoneProps = {
        [`prop_amb_phone`] = true,
        [`prop_npc_phone`] = true,
        [`prop_npc_phone_02`] = true,
        [`p_amb_phone_01`] = true,
    }
    CreateThread(function()
        local last = false
        while true do
            local ped = PlayerPedId()
            local using = false
            for model, _ in pairs(phoneProps) do
                local obj = GetClosestObjectOfType(GetEntityCoords(ped), 1.0, model, false, false, false)
                if obj ~= 0 and IsEntityAttachedToEntity(obj, ped) then
                    using = true
                    break
                end
            end
            if using ~= last then
                last = using
                LocalPlayer.state:set(Config.States.phone, using, true)
            end
            Wait(500)
        end
    end)
end

-- ============ BEÉPÍTETT BIZTONSÁGI ÖV (B gomb) ============
-- Az ikont vezérli: bekötve = zöld. Ha saját öv-szkripted van, állítsd
-- Config.Seatbelt.builtIn = false-ra, és hívd a SetSeatbelt exportot.
if Config.Seatbelt and Config.Seatbelt.builtIn then
    local belted = false

    local function setBelt(state)
        belted = state and true or false
        LocalPlayer.state:set(Config.States.seatbelt, belted, true)
    end

    RegisterCommand('+rrp_seatbelt', function()
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then return end
        setBelt(not belted)
        PlaySoundFrontend(-1, belted and 'SELECT' or 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end, false)

    RegisterKeyMapping('+rrp_seatbelt', 'Biztonsági öv be/ki', 'keyboard', Config.Seatbelt.key or 'B')

    -- öv visszaállítása kiszálláskor + opcionális kirepülés-védelem
    CreateThread(function()
        local lastSpeed = 0.0
        while true do
            local ped = PlayerPedId()
            local sleep = 500

            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                sleep = 0
                local speed = GetEntitySpeed(veh)

                if Config.Seatbelt.antiEject and not belted then
                    -- ha NINCS bekötve és nagy a lassulás -> kirepülés
                    if (lastSpeed - speed) > (Config.Seatbelt.ejectThreshold or 18.0) then
                        local coords = GetEntityCoords(ped)
                        SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.47, true, true, true, false)
                        SetEntityVelocity(ped, GetEntityVelocity(veh))
                        TaskOpenVehicleDoor(ped, veh, 9999, -1, 0.0)
                        SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
                    end
                end
                lastSpeed = speed
            else
                if belted then setBelt(false) end
                lastSpeed = 0.0
            end

            Wait(sleep)
        end
    end)
end
