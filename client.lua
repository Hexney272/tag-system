--[[ RealRP - Headtag rendszer (NUI / world-to-screen) ]]--

local function isUnarmed(ped)
    return GetSelectedPedWeapon(ped) == `WEAPON_UNARMED`
end

-- ============ JÁTÉKOS TAGEK ============
CreateThread(function()
    while true do
        local players = {}
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)

        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)

            if ped ~= myPed and DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local dist = #(coords - myCoords)

                if dist <= Config.PlayerDistance then
                    local visible = true
                    if Config.RequireLineOfSight then
                        visible = HasEntityClearLosToEntity(myPed, ped, 17)
                    end

                    if visible then
                        local headCoords = vector3(coords.x, coords.y, coords.z + Config.HeadOffset)
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)

                        if onScreen then
                            local serverId = GetPlayerServerId(player)
                            local st = Player(serverId).state

                            -- távolság alapú skála (közelebb = nagyobb)
                            local scale = 1.0 - (dist / Config.PlayerDistance) * 0.55
                            if scale < 0.45 then scale = 0.45 end

                            local job = st[Config.States.job] -- { label, badge, grade }
                            local deathTime = st[Config.States.dead] or 0

                            players[#players+1] = {
                                serverId = serverId,
                                name     = GetPlayerName(player),
                                talking  = NetworkIsPlayerTalking(player),
                                armour   = GetPedArmour(ped) > 0,
                                weapon   = not isUnarmed(ped),
                                cuffed   = st[Config.States.cuffed] or false,
                                dead     = IsPedDeadOrDying(ped, true) or (deathTime > 0),
                                deathRemaining = deathTime > 0 and math.max(0, deathTime - GetCloudTimeAsInt()) or 0,
                                job      = job,
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

-- ============ JÁRMŰ RENDSZÁMTÁBLÁK ============
CreateThread(function()
    while true do
        local vehicles = {}
        local myCoords = GetEntityCoords(PlayerPedId())
        local handle, veh = FindFirstVehicle()
        local success = true

        repeat
            if DoesEntityExist(veh) then
                local coords = GetEntityCoords(veh)
                local dist = #(coords - myCoords)

                if dist <= Config.VehicleDistance then
                    -- a jármű teteje fölé pozícionálunk
                    local min, max = GetModelDimensions(GetEntityModel(veh))
                    local topZ = (max.z) + Config.VehicleOffset
                    local plateCoords = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, topZ)
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(plateCoords.x, plateCoords.y, plateCoords.z)

                    if onScreen then
                        local scale = 1.0 - (dist / Config.VehicleDistance) * 0.5
                        if scale < 0.5 then scale = 0.5 end

                        vehicles[#vehicles+1] = {
                            netId = VehToNet(veh),
                            plate = (GetVehicleNumberPlateText(veh) or ""):gsub("%s+$", ""),
                            x = sx, y = sy, scale = scale
                        }
                    end
                end
            end
            success, veh = FindNextVehicle(handle)
        until not success

        EndFindVehicle(handle)

        SendNUIMessage({
            action = "vehicles",
            vehicles = vehicles,
            brand = Config.Brand,
            server = Config.ServerName
        })

        Wait(0)
    end
end)
