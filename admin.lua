--[[ RealRP - Headtag rendszer | Admin tag integráció (szerver oldal)
     
     Automatikusan felismeri az adminokat és beállítja az admin tag-et.
     
     Támogatott rendszerek:
     - ACE permissions (txAdmin, vMenu, stb.)
     - ESX group rendszer (superadmin, admin, mod)
     - Egyedi function
]]--

if not Config.Admin or not Config.Admin.enabled then return end

local ESX = nil
if Config.Admin.method == "esx" and Config.ESX and Config.ESX.enabled then
    ESX = exports[Config.ESX.sharedObject]:getSharedObject()
end

-- ============ ADMIN FELISMERÉS ============

local function getAdminTag(source)
    local method = Config.Admin.method
    
    if method == "ace" then
        -- ACE permissions alapján
        if IsPlayerAceAllowed(source, Config.Admin.acePermission) then
            return {
                label = "ADMIN",
                color = "#FF0000"  -- piros
            }
        end
        
    elseif method == "esx" then
        -- ESX group alapján
        if not ESX then return nil end
        
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end
        
        local group = xPlayer.getGroup()
        if group and Config.Admin.esxGroups[group] then
            return Config.Admin.esxGroups[group]
        end
        
    elseif method == "custom" then
        -- Egyedi function
        if Config.Admin.customCheck and Config.Admin.customCheck(source) then
            return {
                label = "ADMIN",
                color = "#FF0000"
            }
        end
    end
    
    return nil
end

-- ============ ADMIN TAG BEÁLLÍTÁSA ============

local function updateAdminTag(source)
    local adminTag = getAdminTag(source)
    Player(source).state:set(Config.States.admin, adminTag, true)
end

-- ============ ESEMÉNYEK ============

-- Játékos csatlakozásakor
AddEventHandler('playerJoining', function()
    local src = source
    Citizen.SetTimeout(1000, function()  -- Kis késleltetés, hogy az ESX betöltődjön
        updateAdminTag(src)
    end)
end)

-- ESX betöltéskor
if ESX then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        Citizen.SetTimeout(500, function()
            updateAdminTag(playerId)
        end)
    end)
    
    -- ESX group változáskor
    AddEventHandler('esx:setGroup', function(playerId, group)
        Citizen.SetTimeout(100, function()
            updateAdminTag(playerId)
        end)
    end)
end

-- Szkript (re)startjakor frissítés
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Citizen.SetTimeout(2000, function()  -- Várunk, hogy az ESX/ACE betöltődjön
        for _, playerId in ipairs(GetPlayers()) do
            updateAdminTag(tonumber(playerId))
        end
    end)
end)

-- ============ EXPORT (más szkriptekből hívható) ============

-- Manuális admin tag beállítása
-- exports['tag-system']:SetAdminTag(source, { label = "VIP ADMIN", color = "#FFD700" })
exports('SetAdminTag', function(source, adminTag)
    Player(source).state:set(Config.States.admin, adminTag, true)
end)

-- Admin tag eltávolítása
-- exports['tag-system']:ClearAdminTag(source)
exports('ClearAdminTag', function(source)
    Player(source).state:set(Config.States.admin, nil, true)
end)

-- Admin tag frissítése (újraellenőrzés)
-- exports['tag-system']:RefreshAdminTag(source)
exports('RefreshAdminTag', updateAdminTag)

-- ============ PARANCSOK (csak adminoknak) ============

-- DEBUG: Teszteléshez - szerver oldalon állítja be az admin tag-et
RegisterCommand('setadmin', function(source, args)
    if source == 0 then return end
    
    local label = args[1] or "ADMIN"
    local color = args[2] or "#FF0000"
    
    local adminTag = {
        label = label,
        color = color
    }
    
    Player(source).state:set(Config.States.admin, adminTag, true)
    
    print(('[tag-system] [DEBUG] Set admin tag for %s: %s (%s)'):format(source, label, color))
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"Tag System", "Admin tag beállítva: " .. label}
    })
end, false)

-- /admintag on/off - Admin tag be/kikapcsolása (személyes kapcsoló)
local adminTagEnabled = {}

RegisterCommand('admintag', function(source, args)
    if source == 0 then return end
    
    local adminTag = getAdminTag(source)
    if not adminTag then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Tag System", "Nem vagy admin!"}
        })
        return
    end
    
    local toggle = args[1]
    if toggle == 'off' or toggle == 'hide' then
        adminTagEnabled[source] = false
        Player(source).state:set(Config.States.admin, nil, true)
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Tag System", "Admin tag elrejtve."}
        })
    else
        adminTagEnabled[source] = true
        updateAdminTag(source)
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Tag System", "Admin tag megjelenítve."}
        })
    end
end, false)

-- Cleanup kilépéskor
AddEventHandler('playerDropped', function()
    local src = source
    adminTagEnabled[src] = nil
end)
