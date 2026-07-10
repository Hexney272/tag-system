--[[ RealRPG - járműtípusonkénti rendszámtábla felismerés ]]--

local VALID_TYPES = {
    civil = true,
    police = true,
    ambulance = true,
    boat = true,
    aircraft = true,
    electric = true,
}

local modelTypeByHash = {}
local initialized = false

local function getSettings()
    return Config.Plate and Config.Plate.TypeSystem or nil
end

local function normalizeType(value)
    if type(value) ~= 'string' then return nil end
    value = value:lower()
    return VALID_TYPES[value] and value or nil
end

local function rebuildModelLookup()
    modelTypeByHash = {}

    local settings = getSettings()
    if not settings or type(settings.Models) ~= 'table' then
        initialized = true
        return
    end

    for plateType, models in pairs(settings.Models) do
        plateType = normalizeType(plateType)
        if plateType and type(models) == 'table' then
            for _, modelName in ipairs(models) do
                if type(modelName) == 'string' and modelName ~= '' then
                    modelTypeByHash[joaat(modelName)] = plateType
                end
            end
        end
    end

    initialized = true
end

local function classifyVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return 'civil' end
    if not initialized then rebuildModelLookup() end

    local settings = getSettings()
    if not settings or settings.Enabled == false then return 'civil' end

    -- 1. Statebag felülbírálás: más scriptek számára ez a legerősebb beállítás.
    local stateKey = settings.StateKey or 'plateType'
    local stateType = normalizeType(Entity(vehicle).state[stateKey])
    if stateType then return stateType end

    -- 2. Pontos modelllista: rendőrség, mentő, elektromos és addon járművek.
    local modelType = modelTypeByHash[GetEntityModel(vehicle)]
    if modelType then return modelType end

    -- 3. GTA járműosztály alapján automatikus hajó / légi jármű.
    local vehicleClass = GetVehicleClass(vehicle)
    if vehicleClass == 14 then return 'boat' end
    if vehicleClass == 15 or vehicleClass == 16 then return 'aircraft' end

    -- 4. Ismeretlen emergency addon járművek alapértelmezett kezelése.
    if vehicleClass == 18 then
        local fallback = normalizeType(settings.EmergencyFallback)
        if fallback then return fallback end
    end

    return 'civil'
end

local function sendPlateConfig()
    local settings = getSettings() or {}
    SendNUIMessage({
        action = 'plateTypeConfig',
        labels = settings.Labels or {},
    })
end

CreateThread(function()
    Wait(600)
    rebuildModelLookup()
    sendPlateConfig()

    while true do
        local settings = getSettings()
        if not settings or settings.Enabled == false then
            Wait(2000)
        else
            local ped = PlayerPedId()
            local origin = GetEntityCoords(ped)
            local maxDistance = tonumber(settings.ScanDistance) or ((Config.VehicleDistance or 40.0) + 10.0)
            local types = {}

            for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(vehicle) then
                    local coords = GetEntityCoords(vehicle)
                    if #(coords - origin) <= maxDistance then
                        local id = NetworkGetEntityIsNetworked(vehicle) and VehToNet(vehicle) or vehicle
                        types[tostring(id)] = classifyVehicle(vehicle)
                    end
                end
            end

            SendNUIMessage({
                action = 'plateTypes',
                types = types,
            })

            Wait(tonumber(settings.ScanInterval) or 750)
        end
    end
end)

-- Más kliens scriptekhez: exports['tag-system']:GetVehiclePlateType(vehicle)
exports('GetVehiclePlateType', function(vehicle)
    return classifyVehicle(vehicle)
end)

-- Más kliens scriptekhez:
-- exports['tag-system']:SetVehiclePlateType(vehicle, 'police', true)
exports('SetVehiclePlateType', function(vehicle, plateType, replicated)
    if not DoesEntityExist(vehicle) then return false end

    local settings = getSettings() or {}
    local stateKey = settings.StateKey or 'plateType'
    local normalized = normalizeType(plateType)

    if plateType ~= nil and not normalized then
        print(('[tag-system] Érvénytelen rendszámtípus: %s'):format(tostring(plateType)))
        return false
    end

    Entity(vehicle).state:set(stateKey, normalized, replicated ~= false)
    return true
end)

RegisterNetEvent('tag-system:setVehiclePlateType', function(vehicleNetId, plateType)
    local vehicle = NetToVeh(tonumber(vehicleNetId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local settings = getSettings() or {}
    local normalized = normalizeType(plateType)
    if plateType ~= nil and not normalized then return end

    Entity(vehicle).state:set(settings.StateKey or 'plateType', normalized, true)
end)

-- Teszt: ülj egy járműbe, majd /tagplatetype police
-- Törlés / automatikus felismerés visszaállítása: /tagplatetype clear
RegisterCommand('tagplatetype', function(_, args)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        print('[tag-system] A teszthez ülj be egy járműbe.')
        return
    end

    local requested = args[1] and args[1]:lower() or nil
    if requested == 'clear' or requested == 'auto' then requested = nil end

    local settings = getSettings() or {}
    local normalized = normalizeType(requested)
    if requested ~= nil and not normalized then
        print('[tag-system] Típusok: civil, police, ambulance, boat, aircraft, electric, clear')
        return
    end

    Entity(vehicle).state:set(settings.StateKey or 'plateType', normalized, true)
    print(('[tag-system] Rendszámtípus: %s'):format(normalized or 'automatikus'))
end, false)
