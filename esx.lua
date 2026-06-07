--[[ RealRP - Headtag rendszer | ESX Legacy + oxmysql integráció (szerver oldal)

     Beállítja a karakternevet, a frakció/rang sort és a duty állapotot
     a tag-system statebagjein keresztül.

     Duty-köteles job-ok (config.lua -> Config.ESX.TaggedJobs):
       police    -> Rendőrség
       ambulance -> Mentőszolgálat
       mechanic  -> Szerelő
     Ezeknél a frakció CSAK dutyban (onDuty = true) jelenik meg.
]]--

if not Config.ESX or not Config.ESX.enabled then return end

local ESX = exports[Config.ESX.sharedObject]:getSharedObject()

-- forrásonkénti duty állapot (alapból leszállva)
local dutyState = {}

-- ============ JELVÉNYSZÁM LEKÉRÉSE ============
local function getBadge(xPlayer, cb)
    local source = Config.ESX.BadgeSource

    if source == "meta" then
        local badge = nil
        if xPlayer.getMeta then
            badge = xPlayer.getMeta(Config.ESX.BadgeMetaKey)
        end
        cb(badge)
    elseif source == "query" then
        MySQL.scalar(Config.ESX.BadgeQuery, { xPlayer.identifier }, function(result)
            cb(result)
        end)
    else
        cb(nil)
    end
end

-- ============ NÉV ============
local function updateName(xPlayer)
    -- ESX Legacy: getName() = "Keresztnév Vezetéknév"
    exports['tag-system']:SetName(xPlayer.source, xPlayer.getName())
end

-- ============ JOB / FRAKCIÓ ============
local function updateJob(xPlayer)
    local jobName = xPlayer.job and xPlayer.job.name or nil
    local label = jobName and Config.ESX.TaggedJobs[jobName] or nil

    if not label then
        -- nem duty-köteles (civil) job -> nincs frakció-sor
        exports['tag-system']:SetJob(xPlayer.source, nil)
        return
    end

    getBadge(xPlayer, function(badge)
        exports['tag-system']:SetJob(xPlayer.source, {
            label  = label,
            badge  = badge and tonumber(badge) or badge,
            grade  = xPlayer.job.grade_label,
            onDuty = dutyState[xPlayer.source] or false,
        })
    end)
end

-- ============ DUTY VÁLTÁS ============
local function setDuty(source, value)
    dutyState[source] = value and true or false
    -- a meglévő job adat megtartásával frissítjük a duty flaget
    exports['tag-system']:SetOnDuty(source, dutyState[source])
end

-- ============ ESX ESEMÉNYEK ============
RegisterNetEvent('esx:playerLoaded')
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    dutyState[playerId] = false
    updateName(xPlayer)
    updateJob(xPlayer)
end)

AddEventHandler('esx:setJob', function(playerId, job)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        updateJob(xPlayer)
    end
end)

AddEventHandler('esx:playerDropped', function(playerId)
    dutyState[playerId] = nil
end)

-- ============ /duty PARANCS ============
if Config.ESX.EnableDutyCommand then
    RegisterCommand('duty', function(source)
        if source == 0 then return end -- konzolból nem
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        local jobName = xPlayer.job and xPlayer.job.name or nil
        if not (jobName and Config.ESX.TaggedJobs[jobName]) then
            TriggerClientEvent('esx:showNotification', source, 'Nincs duty-köteles munkád.')
            return
        end

        -- ha még nincs job statebag (pl. friss belépés), állítsuk be előbb
        if type(Player(source).state[Config.States.job]) ~= 'table' then
            updateJob(xPlayer)
        end

        local newDuty = not (dutyState[source] or false)
        setDuty(source, newDuty)

        TriggerClientEvent('esx:showNotification', source,
            newDuty and 'Szolgálatba léptél (~g~DUTY~s~).' or 'Leszálltál a szolgálatból.')
    end, false)
end

-- ============ EXPORTOK (más szkriptekből hívható) ============
-- pl. egy gomb/zóna alapú duty rendszerből:
--   exports['tag-system']:SetESXDuty(source, true)
exports('SetESXDuty', function(source, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(Player(source).state[Config.States.job]) ~= 'table' then
        updateJob(xPlayer)
    end
    setDuty(source, value)
end)

-- a szkript (re)startjakor a már bent lévő játékosok frissítése
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        if xPlayer then
            dutyState[xPlayer.source] = dutyState[xPlayer.source] or false
            updateName(xPlayer)
            updateJob(xPlayer)
        end
    end
end)
