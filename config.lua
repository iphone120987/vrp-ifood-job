Config = {}

Config.Debug = true
Config.ScriptSignature = 'Sistema editado por Gaby.silva'
Config.Framework = 'auto' -- auto | vrp | vrpex
Config.Language = 'pt-BR'
Config.Currency = '$'
Config.Permission = '' -- deixe vazio para liberar a todos, ex: "ifood.permissao"

Config.JobName = 'iFood'
Config.VehicleModel = 'faggio3'
Config.VehiclePlatePrefix = 'IFOOD'
Config.ReturnVehicleOnFinish = true
Config.DeleteVehicleDistance = 30.0
Config.MaxRunsPerSession = 999
Config.RequireOnFootToCollect = true
Config.RequireVehicleToDeliver = false
Config.VehicleSpawnRadius = 5.0
Config.DrawDistance = 15.0
Config.MarkerDistance = 10.0
Config.InteractDistance = 1.5
Config.RouteBlipColor = 5
Config.RouteBlipSprite = 280
Config.StartBlip = { enabled = true, sprite = 478, color = 2, scale = 0.8, name = 'Emprego iFood' }

Config.Payment = {
    min = 450,
    max = 700,
    bonusPerLevel = 25,
    payType = 'money' -- money | bank
}

Config.Cooldowns = {
    startJobSeconds = 5,
    collectSeconds = 4,
    deliverSeconds = 6
}

Config.Reputation = {
    enabled = true,
    sqlEnabled = true,
    levelStep = 15,
    pointsPerDelivery = 1,
    maxLevel = 20
}

Config.StartPoint = vec3(-1178.89, -891.52, 13.89)
Config.VehicleSpawn = {
    coords = vec4(-1183.62, -885.71, 13.76, 303.31)
}

Config.CollectionPoints = {
    vec3(-1193.44, -894.31, 13.99),
    vec3(-1198.97, -892.09, 13.99),
    vec3(-1190.67, -899.42, 13.99)
}

Config.DeliveryPoints = {
    vec3(-1031.67, -902.92, 3.69),
    vec3(-948.21, -1077.84, 2.17),
    vec3(-762.18, -1043.58, 12.98),
    vec3(-697.77, -917.51, 19.21),
    vec3(-822.67, -636.82, 27.90),
    vec3(-592.48, -891.74, 25.94),
    vec3(-1308.01, -930.13, 13.36),
    vec3(-1496.94, -671.48, 29.04),
    vec3(-1580.58, -34.03, 57.57),
    vec3(-1453.11, -540.27, 34.74),
    vec3(-1224.94, -1240.63, 11.02),
    vec3(-1063.02, -1210.99, 2.16)
}

Config.Text = {
    start = 'Pressione ~g~E~w~ para iniciar o expediente do iFood',
    stop = 'Pressione ~r~E~w~ para encerrar o expediente do iFood',
    collect = 'Pressione ~g~E~w~ para coletar a encomenda',
    deliver = 'Pressione ~g~E~w~ para entregar a encomenda',
    needVehicle = 'Você precisa estar no veículo de trabalho.',
    started = 'Expediente iniciado. Vá coletar a próxima encomenda.',
    collected = 'Encomenda coletada. Siga até o cliente.',
    delivered = 'Entrega concluída com sucesso.',
    finished = 'Expediente encerrado.',
    vehicleSpawned = 'Veículo de trabalho liberado na vaga.',
    vehicleBlocked = 'Há algo bloqueando o spawn do veículo.',
    alreadyWorking = 'Você já está em expediente.',
    notWorking = 'Você não está em expediente.',
    notAllowed = 'Você não possui permissão para este emprego.',
    waitCooldown = 'Aguarde alguns segundos para usar novamente.',
    routeUpdated = 'Rota atualizada no GPS.',
    noMoreDeliveries = 'Você atingiu o limite desta sessão.',
    getCloser = 'Chegue mais perto do ponto.',
    leaveVehicle = 'Saia do veículo para coletar a encomenda.',
    wrongVehicle = 'Esse não é o veículo do trabalho.',
    debugPrefix = '[vrp_ifood_job]'
}

function DebugPrint(...)
    if not Config.Debug then return end
    local args = { ... }
    local msg = ''
    for i = 1, #args do
        msg = msg .. tostring(args[i]) .. (i < #args and ' ' or '')
    end
    print(('%s %s | %s'):format(Config.Text.debugPrefix, msg, Config.ScriptSignature))
end
