ESX = {}
Core = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false
Core.Input = {}
ESX.UI = {}

ESX.Game = {}
ESX.Game.Utils = {}

ESX.Scaleform = {}
ESX.Scaleform.Utils = {}

ESX.Streaming = {}

function ESX.IsPlayerLoaded()
    return ESX.PlayerLoaded
end

function ESX.GetPlayerData()
    return ESX.PlayerData
end

function ESX.SearchInventory(items, count)
    if type(items) == 'string' then
        items = {items}
    end

    local returnData = {}
    local itemCount = #items

    for i = 1, itemCount do
        local itemName = items[i]
        returnData[itemName] = count and 0

        for _, item in pairs(ESX.PlayerData.inventory) do
            if item.name == itemName then
                if count then
                    returnData[itemName] = returnData[itemName] + item.count
                else
                    returnData[itemName] = item
                end
            end
        end
    end

    if next(returnData) then
        return itemCount == 1 and returnData[items[1]] or returnData
    end
end

function ESX.SetPlayerData(key, val)
    local current = ESX.PlayerData[key]
    ESX.PlayerData[key] = val
    if key ~= 'inventory' and key ~= 'loadout' then
        if type(val) == 'table' or val ~= current then
            TriggerEvent('esx:setPlayerData', key, val, current)
        end
    end
end

function ESX.Progressbar(progressText, progressDuration, progressOptions)
    local progressType = progressOptions?.type or Config.DefaultProgressBarType
    local animation = progressOptions?.anim or progressOptions?.animation

    if lib[progressType == "bar" and "progressBar" or progressType == "circle" and "progressCircle"]({
        label = progressText,
        duration = progressDuration,
        position = progressOptions?.position or Config.DefaultProgressBarPosition,
        useWhileDead = progressOptions?.useWhileDead or false,
        allowRagdoll = progressOptions?.allowRagdoll or false,
        allowCuffed = progressOptions?.allowCuffed or false,
        allowFalling = progressOptions?.allowFalling or false,
        canCancel = progressOptions?.canCancel or (progressOptions?.onCancel ~= nil and true),
        anim = {
            dict = animation?.dict,
            clip = animation?.clip or animation?.lib,
            flag = animation?.flag,
            blendIn = animation?.blendIn,
            blendOut = animation?.blendOut,
            duration = animation?.duration,
            playbackRate = animation?.playbackRate,
            lockX = animation?.lockX,
            lockY = animation?.lockY,
            lockZ = animation?.lockZ,
            scenario = animation?.scenario or animation?.Scenario,
            playEnter = animation?.playEnter,
        },
        prop = progressOptions?.prop,
        disable = progressOptions?.disable or {
            move = progressOptions?.FreezePlayer,
            car = progressOptions?.FreezePlayer,
            combat = progressOptions?.FreezePlayer,
            mouse = false
        }
    }) then
        return progressOptions?.onFinish and progressOptions.onFinish() or true
    else
        return progressOptions?.onCancel and progressOptions.onCancel() or false
    end
end

function ESX.TextUI(text, textType, textExtra)
    lib.showTextUI(text, {
        position = textExtra?.position or Config.DefaultTextUIPosition,
        icon = textExtra?.icon or textType == "success" and "fa-circle-check" or textType == "error" and "fa-circle-exclamation" or "fa-circle-info",
        iconColor = textExtra?.iconColor or textType == "success" and "#2ecc71" or textType == "error" and "#c0392b" or "#2980b9",
        style = textExtra?.style
    })
end

function ESX.HideUI()
    lib.hideTextUI()
end

function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then
        saveToBrief = true
    end
    AddTextEntry('esxAdvancedNotification', msg)
    BeginTextCommandThefeedPost('esxAdvancedNotification')
    if hudColorIndex then
        ThefeedSetNextPostBackgroundColor(hudColorIndex)
    end
    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    AddTextEntry('esxHelpNotification', msg)

    if thisFrame then
        DisplayHelpTextThisFrame('esxHelpNotification', false)
    else
        if beep == nil then
            beep = true
        end
        BeginTextCommandDisplayHelp('esxHelpNotification')
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

function ESX.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry('esxFloatingHelpNotification', msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

ESX.HashString = function(str)
    local format = string.format
    local upper = string.upper
    local gsub = string.gsub
    local hash = joaat(str)
    local input_map = format("~INPUT_%s~", upper(format("%x", hash)))
    input_map = gsub(input_map, "FFFFFFFF", "")

    return input_map
end

ESX.RegisterInput = function(command_name, label, input_group, key, on_press, on_release)
    RegisterCommand(on_release ~= nil and "+" .. command_name or command_name, on_press, false)
    Core.Input[command_name] = on_release ~= nil and ESX.HashString("+" .. command_name) or ESX.HashString(command_name)
    if on_release then
        RegisterCommand("-" .. command_name, on_release, false)
    end
    RegisterKeyMapping(on_release ~= nil and "+" .. command_name or command_name, label, input_group, key)
end

function ESX.UI.ShowInventoryItemNotification(add, item, count)
    SendNUIMessage({
        action = 'inventoryNotification',
        add = add,
        item = item,
        count = count
    })
end

function ESX.Game.GetPedMugshot(ped, transparent)
    if not DoesEntityExist(ped) then return end
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end

function ESX.Game.Teleport(entity, coords, cb)
    local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or vec(coords.x, coords.y, coords.z, coords.heading or 0.0)

    if DoesEntityExist(entity) then
        RequestCollisionAtCoord(vector.x, vector.y, vector.z)
        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(0)
        end

        SetEntityCoords(entity, vector.x, vector.y, vector.z, false, false, false, false)
        SetEntityHeading(entity, vector.w)
    end

    if cb then
        cb()
    end
end

function ESX.Game.SpawnObject(object, coords, cb, networked)
    networked = networked == nil and true or networked
    if networked then
        ESX.TriggerServerCallback('esx:Onesync:SpawnObject', function(NetworkID)
            if cb then
                local obj = NetworkGetEntityFromNetworkId(NetworkID)
                local Tries = 0
                while not DoesEntityExist(obj) do
                    obj = NetworkGetEntityFromNetworkId(NetworkID)
                    Wait(0)
                    Tries += 1
                    if Tries > 250 then
                        break
                    end
                end
                cb(obj)
            end
        end, object, coords, 0.0)
    else
        local model = type(object) == 'number' and object or joaat(object)
        local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
        CreateThread(function()
            ESX.Streaming.RequestModel(model)

            local obj = CreateObject(model, vector.x, vector.y, vector.z, networked, false, true)
            if cb then
                cb(obj)
            end
        end)
    end
end

function ESX.Game.SpawnLocalObject(object, coords, cb)
    ESX.Game.SpawnObject(object, coords, cb, false)
end

function ESX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function ESX.Game.DeleteObject(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

function ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, networked)
    local model = type(vehicle) == 'number' and vehicle or joaat(vehicle)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked

    local playerCoords = GetEntityCoords(ESX.PlayerData.ped)

    if not vector or not playerCoords then return end

    local dist = #(playerCoords - vector)
    if dist > 424 then -- Onesync infinity Range (https://docs.fivem.net/docs/scripting-reference/onesync/)
        local executingResource = GetInvokingResource() or "Unknown"
        return print(("[^1ERROR^7] Resource ^5%s^7 Tried to spawn vehicle on the client but the position is too far away (Out of onesync range)."):format(executingResource))
    end

    CreateThread(function()
        ESX.Streaming.RequestModel(model)

        local vehicleEntity = CreateVehicle(model, vector.x, vector.y, vector.z, heading, networked, true)

        if networked then
            local id = NetworkGetNetworkIdFromEntity(vehicleEntity)
            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicleEntity, true, true)
        end
        SetVehicleHasBeenOwnedByPlayer(vehicleEntity, true)
        SetVehicleNeedsToBeHotwired(vehicleEntity, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicleEntity, 'OFF')

        RequestCollisionAtCoord(vector.x, vector.y, vector.z)
        while not HasCollisionLoadedAroundEntity(vehicleEntity) do
            Wait(0)
        end

        if cb then
            cb(vehicleEntity)
        end
    end)
end

function ESX.Game.SpawnLocalVehicle(vehicle, coords, heading, cb)
    ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

function ESX.Game.IsVehicleEmpty(vehicle)
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end

function ESX.Game.GetObjects() -- Leave the function for compatibility
    return GetGamePool('CObject')
end

function ESX.Game.GetPeds(onlyOtherPeds)
    local myPed, pool = ESX.PlayerData.ped, GetGamePool('CPed')

    if not onlyOtherPeds then
        return pool
    end

    local peds = {}
    for i = 1, #pool do
        if pool[i] ~= myPed then
            peds[#peds + 1] = pool[i]
        end
    end

    return peds
end

function ESX.Game.GetVehicles() -- Leave the function for compatibility
    return GetGamePool('CVehicle')
end

function ESX.Game.GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players, myPlayer = {}, PlayerId()

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[player] = ped
            else
                players[#players + 1] = returnPeds and ped or player
            end
        end
    end

    return players
end


function ESX.Game.GetClosestObject(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetObjects(), false, coords, modelFilter)
end

function ESX.Game.GetClosestPed(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPeds(true), false, coords, modelFilter)
end

function ESX.Game.GetClosestPlayer(coords)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPlayers(true, true), true, coords, nil)
end

function ESX.Game.GetClosestVehicle(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetVehicles(), false, coords, modelFilter)
end

local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end

    return nearbyEntities
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetPlayers(true, true), true, coords, maxDistance)
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetVehicles(), false, coords, maxDistance)
end

function ESX.Game.IsSpawnPointClear(coords, maxDistance)
    return #ESX.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

function ESX.Game.GetClosestEntity(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    if modelFilter then
        filteredEntities = {}

        for _, entity in pairs(entities) do
            if modelFilter[GetEntityModel(entity)] then
                filteredEntities[#filteredEntities + 1] = entity
            end
        end
    end

    for k, entity in pairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
        end
    end

    return closestEntity, closestEntityDistance
end

function ESX.Game.GetVehicleInDirection()
    local playerPed = ESX.PlayerData.ped
    local playerCoords = GetEntityCoords(playerPed)
    local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(playerCoords.x, playerCoords.y, playerCoords.z, inDirection.x, inDirection.y, inDirection.z, 10, playerPed, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and GetEntityType(entityHit) == 2 then
        local entityCoords = GetEntityCoords(entityHit)
        return entityHit, entityCoords
    end

    return nil
end

function ESX.Game.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
    local dashboardColor = GetVehicleDashboardColor(vehicle)
    local interiorColor = GetVehicleInteriorColour(vehicle)
    local customPrimaryColor = nil
    if hasCustomPrimaryColor then
        customPrimaryColor = {GetVehicleCustomPrimaryColour(vehicle)}
    end

    local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = nil
    if hasCustomXenonColor then
        customXenonColor = {customXenonColorR, customXenonColorG, customXenonColorB}
    end

    local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
    local customSecondaryColor = nil
    if hasCustomSecondaryColor then
        customSecondaryColor = {GetVehicleCustomSecondaryColour(vehicle)}
    end

    local extras = {}
    for extraId = 0, 12 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
    local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))

    local TyresIndex = { -- Wheel index list according to the number of vehicle wheels.
        ['2'] = {0, 4}, -- Bike and cycle.
        ['3'] = {0, 1, 4, 5}, -- Vehicle with 3 wheels (get for wheels because some 3 wheels vehicles have 2 wheels on front and one rear or the reverse).
        ['4'] = {0, 1, 4, 5}, -- Vehicle with 4 wheels.
        ['6'] = {0, 1, 2, 3, 4, 5} -- Vehicle with 6 wheels.
    }

    if TyresIndex[numWheels] then
        for _, idx in pairs(TyresIndex[numWheels]) do
            tyreBurst[tostring(idx)] = IsVehicleTyreBurst(vehicle, idx, false)
        end
    end

    for windowId = 0, 7 do -- 13
        windowsBroken[tostring(windowId)] = not IsVehicleWindowIntact(vehicle, windowId)
    end

    local numDoors = GetNumberOfVehicleDoors(vehicle)
    if numDoors and numDoors > 0 then
        for doorsId = 0, numDoors do
            doorsBroken[tostring(doorsId)] = IsVehicleDoorDamaged(vehicle, doorsId)
        end
    end

    return {
        model = GetEntityModel(vehicle),
        doorsBroken = doorsBroken,
        windowsBroken = windowsBroken,
        tyreBurst = tyreBurst,
        plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = ESX.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),

        fuelLevel = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        customPrimaryColor = customPrimaryColor,
        customSecondaryColor = customSecondaryColor,

        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,

        dashboardColor = dashboardColor,
        interiorColor = interiorColor,

        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        customXenonColor = customXenonColor,

        neonEnabled = {IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1), IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3)},

        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),

        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),

        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modDoorR = GetVehicleMod(vehicle, 47),
        modLivery = GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
        modLightbar = GetVehicleMod(vehicle, 49)
    }
end

function ESX.Game.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then
        return
    end
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    SetVehicleModKit(vehicle, 0)

    if props.plate ~= nil then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end
    if props.plateIndex ~= nil then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end
    if props.bodyHealth ~= nil then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end
    if props.engineHealth ~= nil then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end
    if props.tankHealth ~= nil then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end
    if props.fuelLevel ~= nil then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end
    if props.dirtLevel ~= nil then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end
    if props.customPrimaryColor ~= nil then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end
    if props.customSecondaryColor ~= nil then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end
    if props.color1 ~= nil then
        SetVehicleColours(vehicle, props.color1, colorSecondary)
    end
    if props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
    end
    if props.pearlescentColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
    end

    if props.interiorColor ~= nil then
        SetVehicleInteriorColor(vehicle, props.interiorColor)
    end

    if props.dashboardColor ~= nil then
        SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end

    if props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
    end
    if props.wheels ~= nil then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    if props.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end

    if props.neonEnabled ~= nil then
        SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
    end

    if props.extras ~= nil then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId) --[[@as number]], enabled and 0 or 1 --[[@as boolean]])
        end
    end

    if props.neonColor ~= nil then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end
    if props.customXenonColor ~= nil then
        SetVehicleXenonLightsCustomColor(vehicle, props.customXenonColor[1], props.customXenonColor[2],
            props.customXenonColor[3])
    end
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, true)
    end
    if props.tyreSmokeColor ~= nil then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end
    if props.modSpoilers ~= nil then
        SetVehicleMod(vehicle, 0, props.modSpoilers, false)
    end
    if props.modFrontBumper ~= nil then
        SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
    end
    if props.modRearBumper ~= nil then
        SetVehicleMod(vehicle, 2, props.modRearBumper, false)
    end
    if props.modSideSkirt ~= nil then
        SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
    end
    if props.modExhaust ~= nil then
        SetVehicleMod(vehicle, 4, props.modExhaust, false)
    end
    if props.modFrame ~= nil then
        SetVehicleMod(vehicle, 5, props.modFrame, false)
    end
    if props.modGrille ~= nil then
        SetVehicleMod(vehicle, 6, props.modGrille, false)
    end
    if props.modHood ~= nil then
        SetVehicleMod(vehicle, 7, props.modHood, false)
    end
    if props.modFender ~= nil then
        SetVehicleMod(vehicle, 8, props.modFender, false)
    end
    if props.modRightFender ~= nil then
        SetVehicleMod(vehicle, 9, props.modRightFender, false)
    end
    if props.modRoof ~= nil then
        SetVehicleMod(vehicle, 10, props.modRoof, false)
    end
    if props.modEngine ~= nil then
        SetVehicleMod(vehicle, 11, props.modEngine, false)
    end
    if props.modBrakes ~= nil then
        SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end
    if props.modTransmission ~= nil then
        SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end
    if props.modHorns ~= nil then
        SetVehicleMod(vehicle, 14, props.modHorns, false)
    end
    if props.modSuspension ~= nil then
        SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end
    if props.modArmor ~= nil then
        SetVehicleMod(vehicle, 16, props.modArmor, false)
    end
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
    end
    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, false)
    end
    if props.modPlateHolder ~= nil then
        SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end
    if props.modVanityPlate ~= nil then
        SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end
    if props.modTrimA ~= nil then
        SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end
    if props.modOrnaments ~= nil then
        SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end
    if props.modDashboard ~= nil then
        SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end
    if props.modDial ~= nil then
        SetVehicleMod(vehicle, 30, props.modDial, false)
    end
    if props.modDoorSpeaker ~= nil then
        SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end
    if props.modSeats ~= nil then
        SetVehicleMod(vehicle, 32, props.modSeats, false)
    end
    if props.modSteeringWheel ~= nil then
        SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end
    if props.modShifterLeavers ~= nil then
        SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end
    if props.modAPlate ~= nil then
        SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end
    if props.modSpeakers ~= nil then
        SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end
    if props.modTrunk ~= nil then
        SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end
    if props.modHydrolic ~= nil then
        SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end
    if props.modEngineBlock ~= nil then
        SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end
    if props.modAirFilter ~= nil then
        SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end
    if props.modStruts ~= nil then
        SetVehicleMod(vehicle, 41, props.modStruts, false)
    end
    if props.modArchCover ~= nil then
        SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end
    if props.modAerials ~= nil then
        SetVehicleMod(vehicle, 43, props.modAerials, false)
    end
    if props.modTrimB ~= nil then
        SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end
    if props.modTank ~= nil then
        SetVehicleMod(vehicle, 45, props.modTank, false)
    end
    if props.modWindows ~= nil then
        SetVehicleMod(vehicle, 46, props.modWindows, false)
    end

    if props.modLivery ~= nil then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end

    if props.windowsBroken ~= nil then
        for k, v in pairs(props.windowsBroken) do
            if v then
                SmashVehicleWindow(vehicle, tonumber(k) --[[@as number]])
            end
        end
    end

    if props.doorsBroken ~= nil then
        for k, v in pairs(props.doorsBroken) do
            if v then
                SetVehicleDoorBroken(vehicle, tonumber(k) --[[@as number]], true)
            end
        end
    end

    if props.tyreBurst ~= nil then
        for k, v in pairs(props.tyreBurst) do
            if v then
                SetVehicleTyreBurst(vehicle, tonumber(k) --[[@as number]], true, 1000.0)
            end
        end
    end
end

function ESX.Game.Utils.DrawText3D(coords, text, size, font)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    if not size then
        size = 1
    end
    if not font then
        font = 0
    end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.x, vector.y, vector.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function ESX.ShowInventory()
    if not Config.EnableDefaultInventory then
        return
    end

    local playerPed = ESX.PlayerData.ped
    local elements = {
        {unselectable = true, icon = 'fas fa-box', title = 'Player Inventory'}
    }
    local currentWeight = 0

    for i = 1, #(ESX.PlayerData.accounts) do
        if ESX.PlayerData.accounts[i].money > 0 then
            local formattedMoney = _U('locale_currency', ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money))
            local canDrop = ESX.PlayerData.accounts[i].name ~= 'bank'

            elements[#elements+1] = {
                icon = 'fas fa-money-bill-wave',
                title = ('%s: %s'):format(ESX.PlayerData.accounts[i].label, formattedMoney),
                count = ESX.PlayerData.accounts[i].money,
                type = 'item_account',
                value = ESX.PlayerData.accounts[i].name,
                usable = false,
                rare = false,
                canRemove = canDrop
            }
        end
    end

    for _, v in ipairs(ESX.PlayerData.inventory) do
        if v.count > 0 then
            currentWeight = currentWeight + (v.weight * v.count)

            elements[#elements+1] = {
                icon = 'fas fa-box',
                title = ('%s x%s'):format(v.label, v.count),
                count = v.count,
                type = 'item_standard',
                value = v.name,
                usable = v.usable,
                rare = v.rare,
                canRemove = v.canRemove
            }
        end
    end

    for _, v in ipairs(Config.Weapons) do
        local weaponHash = joaat(v.name)

        if HasPedGotWeapon(playerPed, weaponHash, false) then
            local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
            local label = v.ammo and ('%s - %s %s'):format(v.label, ammo, v.ammo.label) or v.label

            elements[#elements+1] = {
                icon = 'fas fa-gun',
                title = label,
                count = 1,
                type = 'item_weapon',
                value = v.name,
                usable = false,
                rare = false,
                ammo = ammo,
                canGiveAmmo = (v.ammo ~= nil),
                canRemove = true
            }
        end
    end

    elements[#elements+1] = {
        unselectable = true,
        icon = "fas fa-weight",
        title = "Current Weight: "..currentWeight
    }

    ESX.CloseContext()

    ESX.OpenContext("right", elements, function(_, element)
        local player, distance = ESX.Game.GetClosestPlayer()

        local elements2 = {}

        if element.usable then
            elements2[#elements2+1] = {
                icon = "fas fa-utensils",
                title = _U('use'),
                action = 'use',
                type = element.type,
                value = element.value
            }
        end

        if element.canRemove then
            if player ~= -1 and distance <= 3.0 then
                elements2[#elements2+1] = {
                    icon = "fas fa-hands",
                    title = _U('give'),
                    action = 'give',
                    type = element.type,
                    value = element.value
                }
            end

            elements2[#elements2+1] = {
                icon = "fas fa-trash",
                title = _U('remove'),
                action = 'remove',
                type = element.type,
                value = element.value
            }
        end

        if element.type == 'item_weapon' and element.canGiveAmmo and element.ammo > 0 and player ~= -1 and distance <= 3.0 then
            elements2[#elements2+1] = {
                icon = "fas fa-gun",
                title = _U('giveammo'),
                action = 'give_ammo',
                type = element.type,
                value = element.value
            }
        end

        elements2[#elements2+1] = {
            icon = "fas fa-arrow-left",
            title = _U('return'),
            action = 'return'
        }

        ESX.OpenContext("right", elements2, function(_, element2)
            local item, type = element2.value, element2.type

            if element2.action == "give" then
                local playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

                if #playersNearby > 0 then
                    local players = {}
                    local elements3 = {
                        {unselectable = true, icon = "fas fa-users", title = "Nearby Players"}
                    }

                    for _, playerNearby in ipairs(playersNearby) do
                        players[GetPlayerServerId(playerNearby)] = true
                    end

                    ESX.TriggerServerCallback('esx:getPlayerNames', function(returnedPlayers)
                        for playerId, playerName in pairs(returnedPlayers) do
                            elements3[#elements3+1] = {
                                icon = "fas fa-user",
                                title = playerName,
                                playerId = playerId
                            }
                        end

                        ESX.OpenContext("right", elements3, function(_, element3)
                            local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(element3.playerId), element3.playerId
                            playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
                            playersNearby = ESX.Table.Set(playersNearby)

                            if playersNearby[selectedPlayer] then
                                local selectedPlayerPed = GetPlayerPed(selectedPlayer)

                                if IsPedOnFoot(selectedPlayerPed) and not IsPedFalling(selectedPlayerPed) then
                                    if type == 'item_weapon' then
                                        TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type, item, nil)
                                        ESX.CloseContext()
                                    else
                                        local elementsG = {
                                            {unselectable = true, icon = "fas fa-trash", title = element.title},
                                            {icon = "fas fa-hashtag", title = "Amount", input = true, inputType = "number", inputPlaceholder = "Amount to give...", inputMin = 1, inputMax = 1000},
                                            {icon = "fas fa-check-double", title = "Confirm", val = "confirm"}
                                        }

                                        ESX.OpenContext("right", elementsG, function(menuG, _)
                                            local quantity = tonumber(menuG.eles[2].inputValue)

                                            if quantity and quantity > 0 and element.count >= quantity then
                                                TriggerServerEvent('esx:giveInventoryItem', selectedPlayerId, type, item, quantity)
                                                ESX.CloseContext()
                                            else
                                                ESX.ShowNotification(_U('amount_invalid'))
                                            end
                                        end)
                                    end
                                else
                                    ESX.ShowNotification(_U('in_vehicle'))
                                end
                            else
                                ESX.ShowNotification(_U('players_nearby'))
                                ESX.CloseContext()
                            end
                        end)
                    end, players)
                end
            elseif element2.action == "remove" then
                if IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) then
                    local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                    ESX.Streaming.RequestAnimDict(dict)

                    if type == 'item_weapon' then
                        ESX.CloseContext()
                        TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                        RemoveAnimDict(dict)
                        Wait(1000)
                        TriggerServerEvent('esx:removeInventoryItem', type, item)
                    else
                        local elementsR = {
                            {unselectable = true, icon = "fas fa-trash", title = element.title},
                            {icon = "fas fa-hashtag", title = "Amount", input = true, inputType = "number", inputPlaceholder = "Amount to remove...", inputMin = 1, inputMax = 1000},
                            {icon = "fas fa-check-double", title = "Confirm", val = "confirm"}
                        }

                        ESX.OpenContext("right", elementsR, function(menuR, _)
                            local quantity = tonumber(menuR.eles[2].inputValue)

                            if quantity and quantity > 0 and element.count >= quantity then
                                ESX.CloseContext()
                                TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                                RemoveAnimDict(dict)
                                Wait(1000)
                                TriggerServerEvent('esx:removeInventoryItem', type, item, quantity)
                            else
                                ESX.ShowNotification(_U('amount_invalid'))
                            end
                        end)
                    end
                end
            elseif element2.action == "use" then
                ESX.CloseContext()
                TriggerServerEvent('esx:useItem', item)
            elseif element2.action == "return" then
                ESX.CloseContext()
                ESX.ShowInventory()
            elseif element2.action == "give_ammo" then
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                local closestPed = GetPlayerPed(closestPlayer)
                local pedAmmo = GetAmmoInPedWeapon(playerPed, joaat(item))

                if IsPedOnFoot(closestPed) and not IsPedFalling(closestPed) then
                    if closestPlayer ~= -1 and closestDistance < 3.0 then
                        if pedAmmo > 0 then
                            local elementsGA = {
                                {unselectable = true, icon = "fas fa-trash", title = element.title},
                                {icon = "fas fa-hashtag", title = "Amount", input = true, inputType = "number", inputPlaceholder = "Amount to give...", inputMin = 1, inputMax = 1000},
                                {icon = "fas fa-check-double", title = "Confirm", val = "confirm"}
                            }

                            ESX.OpenContext("right", elementsGA, function(menuGA, _)
                                local quantity = tonumber(menuGA.eles[2].inputValue)

                                if quantity and quantity > 0 then
                                    if pedAmmo >= quantity then
                                        TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_ammo', item, quantity)
                                        ESX.CloseContext()
                                    else
                                        ESX.ShowNotification(_U('noammo'))
                                    end
                                else
                                    ESX.ShowNotification(_U('amount_invalid'))
                                end
                            end)
                        else
                            ESX.ShowNotification(_U('noammo'))
                        end
                    else
                        ESX.ShowNotification(_U('players_nearby'))
                    end
                else
                    ESX.ShowNotification(_U('in_vehicle'))
                end
            end
        end)
    end)
end

AddEventHandler("esx:showNotification", function(notifyText, notifyType, notifyDuration, notifyExtra)
    ESX.ShowNotification(notifyText, notifyType, notifyDuration, notifyExtra)
end)

AddEventHandler("esx:showAdvancedNotification", function(sender, subject, message, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    ESX.ShowAdvancedNotification(sender, subject, message, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end)

AddEventHandler("esx:showHelpNotification", function(message, thisFrame, beep, duration)
    ESX.ShowHelpNotification(message, thisFrame, beep, duration)
end)

---@param model number | string
---@return string
---@diagnostic disable-next-line: duplicate-set-field
function ESX.GetVehicleType(model)
    model = type(model) == 'string' and joaat(model) or model

    if model == `submersible` or model == `submersible2` then
        return 'submarine'
    end

    local vehicleType = GetVehicleClassFromName(model)
    local types = {
        [8] = "bike",
        [11] = "trailer",
        [13] = "bike",
        [14] = "boat",
        [15] = "heli",
        [16] = "plane",
        [21] = "train",
    }

    return types[vehicleType] or "automobile"
end