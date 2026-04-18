local working = false
local currentMode = nil
local currentPoint = nil
local jobVehicle = nil
local currentOrder = nil
local activeBlip = nil

local function notify(msg)
    TriggerEvent('Notify', 'sucesso', msg, 5000)
end

local function notifyError(msg)
    TriggerEvent('Notify', 'negado', msg, 5000)
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawMarkerAt(coords)
    DrawMarker(21, coords.x, coords.y, coords.z - 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 0, 180, 255, 160, false, true, 2, nil, nil, false)
end

local function removeBlip()
    if activeBlip and DoesBlipExist(activeBlip) then
        RemoveBlip(activeBlip)
        activeBlip = nil
    end
end

local function setRouteBlip(coords, title)
    removeBlip()
    activeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(activeBlip, Config.RouteBlipSprite)
    SetBlipColour(activeBlip, Config.RouteBlipColor)
    SetBlipScale(activeBlip, 0.9)
    SetBlipRoute(activeBlip, true)
    SetBlipRouteColour(activeBlip, Config.RouteBlipColor)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(title)
    EndTextCommandSetBlipName(activeBlip)
    DebugPrint('Blip de rota atualizado')
end

local function createStartBlip()
    if not Config.StartBlip.enabled then return end
    local blip = AddBlipForCoord(Config.StartPoint.x, Config.StartPoint.y, Config.StartPoint.z)
    SetBlipSprite(blip, Config.StartBlip.sprite)
    SetBlipColour(blip, Config.StartBlip.color)
    SetBlipScale(blip, Config.StartBlip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.StartBlip.name)
    EndTextCommandSetBlipName(blip)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

local function spawnJobVehicle()
    if jobVehicle and DoesEntityExist(jobVehicle) then
        return jobVehicle
    end

    local coords = Config.VehicleSpawn.coords
    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, Config.VehicleSpawnRadius) then
        notifyError(Config.Text.vehicleBlocked)
        return nil
    end

    local hash = loadModel(Config.VehicleModel)
    jobVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(jobVehicle, Config.VehiclePlatePrefix)
    SetEntityAsMissionEntity(jobVehicle, true, true)
    SetVehicleOnGroundProperly(jobVehicle)
    SetVehRadioStation(jobVehicle, 'OFF')
    SetVehicleFuelLevel(jobVehicle, 100.0)
    SetModelAsNoLongerNeeded(hash)

    DebugPrint('Veículo de trabalho spawnado')
    notify(Config.Text.vehicleSpawned)
    return jobVehicle
end

local function deleteJobVehicle()
    if jobVehicle and DoesEntityExist(jobVehicle) then
        NetworkRequestControlOfEntity(jobVehicle)
        DeleteEntity(jobVehicle)
        jobVehicle = nil
        DebugPrint('Veículo de trabalho removido')
    end
end

RegisterNetEvent('vrp_ifood_job:client:updateRoute', function(mode, coords, orderCode)
    currentMode = mode
    currentPoint = coords
    currentOrder = orderCode

    if mode == 'collect' then
        setRouteBlip(coords, 'Retirar encomenda')
    elseif mode == 'deliver' then
        setRouteBlip(coords, 'Entregar pedido')
    end

    notify(Config.Text.routeUpdated)
end)

RegisterNetEvent('vrp_ifood_job:client:clearRoute', function()
    currentMode = nil
    currentPoint = nil
    currentOrder = nil
    removeBlip()
end)

RegisterNetEvent('vrp_ifood_job:client:clearJob', function()
    working = false
    currentMode = nil
    currentPoint = nil
    currentOrder = nil
    removeBlip()
    if Config.ReturnVehicleOnFinish then
        deleteJobVehicle()
    end
end)

CreateThread(function()
    createStartBlip()

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local startDistance = #(pCoords - Config.StartPoint)

        if startDistance <= Config.DrawDistance then
            sleep = 0
            drawMarkerAt(Config.StartPoint)
            if startDistance <= Config.InteractDistance then
                if working then
                    drawText3D(Config.StartPoint + vec3(0.0, 0.0, 0.2), Config.Text.stop)
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('vrp_ifood_job:server:stopShift')
                    end
                else
                    drawText3D(Config.StartPoint + vec3(0.0, 0.0, 0.2), Config.Text.start)
                    if IsControlJustPressed(0, 38) then
                        local veh = spawnJobVehicle()
                        if veh then
                            working = true
                            TriggerServerEvent('vrp_ifood_job:server:startShift', VehToNet(veh))
                        end
                    end
                end
            end
        end

        if working and currentPoint then
            local dist = #(pCoords - currentPoint)
            if dist <= Config.DrawDistance then
                sleep = 0
                drawMarkerAt(currentPoint)
                if dist <= Config.InteractDistance then
                    if currentMode == 'collect' then
                        drawText3D(currentPoint + vec3(0.0, 0.0, 0.25), ('%s\nPedido: %s'):format(Config.Text.collect, currentOrder or '---'))
                        if IsControlJustPressed(0, 38) then
                            if Config.RequireOnFootToCollect and IsPedInAnyVehicle(ped, false) then
                                notifyError(Config.Text.leaveVehicle)
                            else
                                TriggerServerEvent('vrp_ifood_job:server:collectOrder')
                            end
                        end
                    elseif currentMode == 'deliver' then
                        drawText3D(currentPoint + vec3(0.0, 0.0, 0.25), ('%s\nPedido: %s'):format(Config.Text.deliver, currentOrder or '---'))
                        if IsControlJustPressed(0, 38) then
                            if Config.RequireVehicleToDeliver then
                                local veh = GetVehiclePedIsIn(ped, false)
                                if veh == 0 or veh ~= jobVehicle then
                                    notifyError(Config.Text.wrongVehicle)
                                    goto continue
                                end
                            end
                            TriggerServerEvent('vrp_ifood_job:server:finishDelivery')
                        end
                    end
                end
            end
        end

        ::continue::
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if working and jobVehicle and DoesEntityExist(jobVehicle) and Config.ReturnVehicleOnFinish then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local vCoords = GetEntityCoords(jobVehicle)
            if #(pCoords - vCoords) > 300.0 and not IsPedInVehicle(ped, jobVehicle, false) then
                deleteJobVehicle()
            end
        end
    end
end)

CreateThread(function()
    DebugPrint('Client carregado com sucesso')
end)
