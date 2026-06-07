local showDistance = 25.0

CreateThread(function()
    while true do
        local players = {}

        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)

            if ped ~= PlayerPedId() then
                local coords = GetEntityCoords(ped)
                local myCoords = GetEntityCoords(PlayerPedId())
                local dist = #(coords - myCoords)

                if dist <= showDistance and HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then
                    players[#players+1] = {
                        serverId = GetPlayerServerId(player),
                        name = GetPlayerName(player),
                        talking = MumbleIsPlayerTalking(player),
                        armour = GetPedArmour(ped) > 0,
                        weapon = GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED`,
                        dead = IsEntityDead(ped),
                        cuffed = LocalPlayer.state.isCuffed or false,
                        coords = {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z + 1.05
                        }
                    }
                end
            end
        end

        SendNUIMessage({
            action = "players",
            players = players
        })

        Wait(150)
    end
end)
