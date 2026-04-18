local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')

local srcName = GetCurrentResourceName()
local sessions = {}

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if GetResourceState('vrpex') == 'started' then
        return 'vrpex'
    end

    if GetResourceState('vrp') == 'started' then
        return 'vrp'
    end

    return 'vrp'
end

local FRAMEWORK = detectFramework()

local function notify(source, msg)
    TriggerClientEvent('Notify', source, 'sucesso', msg, 5000)
end

local function notifyError(source, msg)
    TriggerClientEvent('Notify', source, 'negado', msg, 5000)
end

local function getUserId(source)
    if not vRP or not vRP.getUserId then return nil end
    return vRP.getUserId(source)
end

local function hasPermission(user_id)
    if Config.Permission == nil or Config.Permission == '' then
        return true
    end
    return vRP.hasPermission(user_id, Config.Permission)
end

local function getReputationLevel(points)
    if not Config.Reputation.enabled then return 0 end
    local level = math.floor((points or 0) / Config.Reputation.levelStep)
    if level > Config.Reputation.maxLevel then level = Config.Reputation.maxLevel end
    return level
end

local function getSession(source)
    sessions[source] = sessions[source] or {
        working = false,
        deliveryCount = 0,
        cooldowns = {},
        vehicleNet = nil,
        reputation = 0,
        currentCollect = nil,
        currentDelivery = nil,
        orderCode = nil
    }
    return sessions[source]
end

local function isOnCooldown(session, key, seconds)
    local now = os.time()
    local expires = session.cooldowns[key] or 0
    if expires > now then
        return true
    end
    session.cooldowns[key] = now + seconds
    return false
end

local function randomPoint(list, avoid)
    if #list == 0 then return nil end
    local pick = list[math.random(#list)]
    if avoid and #list > 1 then
        local tries = 0
        while #(pick - avoid) < 10.0 and tries < 10 do
            pick = list[math.random(#list)]
            tries = tries + 1
        end
    end
    return pick
end

local function randomOrderCode(user_id)
    return ('IFOOD-%s-%04d'):format(user_id, math.random(1000, 9999))
end

local function saveReputation(user_id, points)
    if not Config.Reputation.enabled or not Config.Reputation.sqlEnabled then return end
    exports.oxmysql:execute('INSERT INTO vrp_ifood_job (user_id, reputation, deliveries) VALUES (?, ?, 0) ON DUPLICATE KEY UPDATE reputation = ?', { user_id, points, points })
end

local function addDeliveryStats(user_id, points)
    if not Config.Reputation.enabled or not Config.Reputation.sqlEnabled then return end
    exports.oxmysql:execute('INSERT INTO vrp_ifood_job (user_id, reputation, deliveries) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE reputation = ?, deliveries = deliveries + 1', { user_id, points, points })
end

local function loadReputation(user_id, cb)
    if not Config.Reputation.enabled or not Config.Reputation.sqlEnabled then
        cb(0)
        return
    end

    exports.oxmysql:single('SELECT reputation FROM vrp_ifood_job WHERE user_id = ?', { user_id }, function(row)
        cb(row and row.reputation or 0)
    end)
end

RegisterNetEvent('vrp_ifood_job:server:startShift', function(vehicleNet)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local session = getSession(source)
    if session.working then
        notifyError(source, Config.Text.alreadyWorking)
        return
    end

    if isOnCooldown(session, 'start', Config.Cooldowns.startJobSeconds) then
        notifyError(source, Config.Text.waitCooldown)
        return
    end

    if not hasPermission(user_id) then
        notifyError(source, Config.Text.notAllowed)
        return
    end

    loadReputation(user_id, function(points)
        session.working = true
        session.deliveryCount = 0
        session.vehicleNet = vehicleNet
        session.reputation = points or 0
        session.currentCollect = randomPoint(Config.CollectionPoints)
        session.currentDelivery = nil
        session.orderCode = randomOrderCode(user_id)

        DebugPrint('Shift iniciado | user_id:', user_id, '| framework:', FRAMEWORK, '| order:', session.orderCode)
        notify(source, Config.Text.started)
        TriggerClientEvent('vrp_ifood_job:client:updateRoute', source, 'collect', session.currentCollect, session.orderCode)
    end)
end)

RegisterNetEvent('vrp_ifood_job:server:stopShift', function()
    local source = source
    local session = getSession(source)
    if not session.working then
        notifyError(source, Config.Text.notWorking)
        return
    end

    session.working = false
    session.currentCollect = nil
    session.currentDelivery = nil
    session.vehicleNet = nil
    session.orderCode = nil

    DebugPrint('Shift encerrado | source:', source)
    notify(source, Config.Text.finished)
    TriggerClientEvent('vrp_ifood_job:client:clearJob', source)
end)

RegisterNetEvent('vrp_ifood_job:server:collectOrder', function()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local session = getSession(source)
    if not session.working or not session.currentCollect then
        notifyError(source, Config.Text.notWorking)
        return
    end

    if isOnCooldown(session, 'collect', Config.Cooldowns.collectSeconds) then
        notifyError(source, Config.Text.waitCooldown)
        return
    end

    session.currentDelivery = randomPoint(Config.DeliveryPoints, session.currentCollect)
    session.currentCollect = nil

    DebugPrint('Encomenda coletada | user_id:', user_id, '| destino definido')
    notify(source, Config.Text.collected)
    TriggerClientEvent('vrp_ifood_job:client:updateRoute', source, 'deliver', session.currentDelivery, session.orderCode)
end)

RegisterNetEvent('vrp_ifood_job:server:finishDelivery', function()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local session = getSession(source)
    if not session.working or not session.currentDelivery then
        notifyError(source, Config.Text.notWorking)
        return
    end

    if isOnCooldown(session, 'deliver', Config.Cooldowns.deliverSeconds) then
        notifyError(source, Config.Text.waitCooldown)
        return
    end

    local level = getReputationLevel(session.reputation)
    local payment = math.random(Config.Payment.min, Config.Payment.max) + (level * Config.Payment.bonusPerLevel)

    if Config.Payment.payType == 'bank' and vRP.giveBankMoney then
        vRP.giveBankMoney(user_id, payment)
    else
        vRP.giveMoney(user_id, payment)
    end

    session.deliveryCount = session.deliveryCount + 1
    if Config.Reputation.enabled then
        session.reputation = (session.reputation or 0) + Config.Reputation.pointsPerDelivery
        addDeliveryStats(user_id, session.reputation)
    end

    DebugPrint('Entrega finalizada | user_id:', user_id, '| pagamento:', payment, '| entregas:', session.deliveryCount, '| reputação:', session.reputation)
    notify(source, ('%s Recebido: %s%d'):format(Config.Text.delivered, Config.Currency, payment))

    if session.deliveryCount >= Config.MaxRunsPerSession then
        session.currentDelivery = nil
        notify(source, Config.Text.noMoreDeliveries)
        TriggerClientEvent('vrp_ifood_job:client:clearRoute', source)
        return
    end

    session.currentDelivery = nil
    session.currentCollect = randomPoint(Config.CollectionPoints)
    session.orderCode = randomOrderCode(user_id)
    TriggerClientEvent('vrp_ifood_job:client:updateRoute', source, 'collect', session.currentCollect, session.orderCode)
end)

lib = lib or {}

RegisterNetEvent('vRP:playerLeave', function(user_id, source)
    if source and sessions[source] then
        sessions[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    sessions[source] = nil
end)

CreateThread(function()
    math.randomseed(os.time())
    DebugPrint('Resource carregado com sucesso | framework detectado:', FRAMEWORK)
end)
