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

-- ============ JELVÉNYSZÁM TÁBLA (oxmysql, auto) ============
-- Egyedi, sorszámozott jelvényszámok tárolása. A tábla automatikusan létrejön.
local badgeTableReady = false

local function ensureBadgeTable()
    if badgeTableReady or not Config.ESX.AutoBadge then return end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tag_system_badges` (
            `badge` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `job` VARCHAR(32) DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`badge`),
            UNIQUE KEY `uniq_identifier` (`identifier`)
        ) AUTO_INCREMENT = ]] .. tostring(Config.ESX.BadgeStart) .. [[;
    ]], {}, function()
        badgeTableReady = true
    end)
end

-- meglévő jelvény lekérése, vagy új kiosztása (identifier alapján)
local function getOrCreateBadge(xPlayer, cb)
    local identifier = xPlayer.identifier
    MySQL.scalar('SELECT badge FROM tag_system_badges WHERE identifier = ?', { identifier }, function(existing)
        if existing then
            cb(existing)
            return
        end
        MySQL.insert('INSERT INTO tag_system_badges (identifier, job) VALUES (?, ?)',
            { identifier, xPlayer.job and xPlayer.job.name or nil }, function(insertId)
                -- cache az ESX metadatába a gyors eléréshez
                if xPlayer.setMeta then
                    xPlayer.setMeta(Config.ESX.BadgeMetaKey, insertId)
                end
                cb(insertId)
            end)
    end)
end

-- ============ JELVÉNYSZÁM LEKÉRÉSE ============
local function maybeAutoBadge(xPlayer, jobName, currentBadge, cb)
    -- ha már van jelvény, vagy nincs auto, vagy a job nem jogosult -> ahogy van
    if currentBadge or not Config.ESX.AutoBadge then
        cb(currentBadge)
        return
    end
    if not (jobName and Config.ESX.AutoBadgeJobs[jobName]) then
        cb(currentBadge)
        return
    end
    ensureBadgeTable()
    getOrCreateBadge(xPlayer, cb)
end

local function getBadge(xPlayer, cb)
    local source = Config.ESX.BadgeSource
    local jobName = xPlayer.job and xPlayer.job.name or nil

    if source == "meta" then
        local badge = xPlayer.getMeta and xPlayer.getMeta(Config.ESX.BadgeMetaKey) or nil
        maybeAutoBadge(xPlayer, jobName, badge, cb)
    elseif source == "query" then
        MySQL.scalar(Config.ESX.BadgeQuery, { xPlayer.identifier }, function(result)
            maybeAutoBadge(xPlayer, jobName, result, cb)
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
            name   = jobName,  -- hozzáadva a munka kulcsa (pl. "police", "ambulance")
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
    ensureBadgeTable()
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        if xPlayer then
            dutyState[xPlayer.source] = dutyState[xPlayer.source] or false
            updateName(xPlayer)
            updateJob(xPlayer)
        end
    end
end)
