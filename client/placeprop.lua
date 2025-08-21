local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

math.randomseed(GetGameTimer())

local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local PitchUpPrompt
local PitchDownPrompt
local RollLeftPrompt
local RollRightPrompt
local confirmed
local heading
local pitch
local roll

local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)

-- Initialize prompts
CreateThread(function()
    Set()
    Del()
    RotateLeft()
    RotateRight()
    PitchUp()
    PitchDown()
    RollLeft()
    RollRight()
end)

function Del()
    CreateThread(function()
        local str = Config.PromptCancelName
        CancelPrompt = PromptRegisterBegin()
        PromptSetControlAction(CancelPrompt, 0xF84FA74F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CancelPrompt, str)
        PromptSetEnabled(CancelPrompt, true)
        PromptSetVisible(CancelPrompt, true)
        PromptSetHoldMode(CancelPrompt, true)
        PromptSetGroup(CancelPrompt, PromptPlacerGroup)
        PromptRegisterEnd(CancelPrompt)
    end)
end

function Set()
    CreateThread(function()
        local str = Config.PromptPlaceName
        SetPrompt = PromptRegisterBegin()
        PromptSetControlAction(SetPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(SetPrompt, str)
        PromptSetEnabled(SetPrompt, true)
        PromptSetVisible(SetPrompt, true)
        PromptSetHoldMode(SetPrompt, true)
        PromptSetGroup(SetPrompt, PromptPlacerGroup)
        PromptRegisterEnd(SetPrompt)
    end)
end

function RotateLeft()
    CreateThread(function()
        local str = Config.PromptRotateLeft
        RotateLeftPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateLeftPrompt, str)
        PromptSetEnabled(RotateLeftPrompt, true)
        PromptSetVisible(RotateLeftPrompt, true)
        PromptSetHoldMode(RotateLeftPrompt, true)
        PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateLeftPrompt)
    end)
end

function RotateRight()
    CreateThread(function()
        local str = Config.PromptRotateRight
        RotateRightPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateRightPrompt, 0xDEB34313)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateRightPrompt, str)
        PromptSetEnabled(RotateRightPrompt, true)
        PromptSetVisible(RotateRightPrompt, true)
        PromptSetHoldMode(RotateRightPrompt, true)
        PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateRightPrompt)
    end)
end

function PitchUp()
    CreateThread(function()
        local str = Config.PromptPitchUp or "Pitch Up"
        PitchUpPrompt = PromptRegisterBegin()
        PromptSetControlAction(PitchUpPrompt, 0x6319DB71) -- Arrow Up
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(PitchUpPrompt, str)
        PromptSetEnabled(PitchUpPrompt, true)
        PromptSetVisible(PitchUpPrompt, true)
        PromptSetHoldMode(PitchUpPrompt, true)
        PromptSetGroup(PitchUpPrompt, PromptPlacerGroup)
        PromptRegisterEnd(PitchUpPrompt)
    end)
end

function PitchDown()
    CreateThread(function()
        local str = Config.PromptPitchDown or "Pitch Down"
        PitchDownPrompt = PromptRegisterBegin()
        PromptSetControlAction(PitchDownPrompt, 0x05CA7C52) -- Arrow down
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(PitchDownPrompt, str)
        PromptSetEnabled(PitchDownPrompt, true)
        PromptSetVisible(PitchDownPrompt, true)
        PromptSetHoldMode(PitchDownPrompt, true)
        PromptSetGroup(PitchDownPrompt, PromptPlacerGroup)
        PromptRegisterEnd(PitchDownPrompt)
    end)
end

function RollLeft()
    CreateThread(function()
        local str = Config.PromptRollLeft or "Roll Left"
        RollLeftPrompt = PromptRegisterBegin()
        PromptSetControlAction(RollLeftPrompt, 0xF1E9A8D7) -- Q key
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RollLeftPrompt, str)
        PromptSetEnabled(RollLeftPrompt, true)
        PromptSetVisible(RollLeftPrompt, true)
        PromptSetHoldMode(RollLeftPrompt, true)
        PromptSetGroup(RollLeftPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RollLeftPrompt)
    end)
end

function RollRight()
    CreateThread(function()
        local str = Config.PromptRollRight or "Roll Right"
        RollRightPrompt = PromptRegisterBegin()
        PromptSetControlAction(RollRightPrompt, 0xE764D794) -- E key
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RollRightPrompt, str)
        PromptSetEnabled(RollRightPrompt, true)
        PromptSetVisible(RollRightPrompt, true)
        PromptSetHoldMode(RollRightPrompt, true)
        PromptSetGroup(RollRightPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RollRightPrompt)
    end)
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function AlignPropToSurface(prop, surfaceNormal, coords, entity)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop))
    local propHeight = math.abs(maxDim.z - minDim.z)
    local propDepth = math.max(math.abs(maxDim.x - minDim.x), math.abs(maxDim.y - minDim.y))
    local propRotation = vector3(pitch, roll, heading)
    if DoesEntityExist(entity) and entity ~= 0 then
        local entityType = GetEntityType(entity)
        if entityType == 2 or entityType == 3 then
            local forward, right, up, _ = GetEntityMatrix(entity)
            surfaceNormal = up
        end
    end
    local propThickness = 0.01
    local offsetDistance = propThickness
    local offsetCoords = vector3(
        coords.x + (surfaceNormal.x * offsetDistance),
        coords.y + (surfaceNormal.y * offsetDistance),
        coords.z + (surfaceNormal.z * offsetDistance)
    )
    SetEntityCoordsNoOffset(prop, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false, true)
    SetEntityRotation(prop, pitch, roll, heading, 2, false)
end

function GetSurfaceType(surfaceNormal)
    if surfaceNormal.z > 0.7 then
        return locale('surface_floor')
    elseif surfaceNormal.z < -0.7 then
        return locale('surface_ceiling')
    else
        return locale('surface_wall')
    end
end

function SnapPropToSurface(prop, coords, surfaceNormal, entity)
    local propPos = GetEntityCoords(prop)
    local rayStart = vector3(propPos.x, propPos.y, propPos.z + 0.1)
    local rayEnd = vector3(
        propPos.x - (surfaceNormal.x * 1.5),
        propPos.y - (surfaceNormal.y * 1.5),
        propPos.z - (surfaceNormal.z * 1.5)
    )
    local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 1 + 2 + 4 + 8 + 16, prop, 0)
    local _, hit, snapCoords, snapNormal, hitEntity = GetShapeTestResult(rayHandle)
    if hit then
        local minDim, maxDim = GetModelDimensions(GetEntityModel(prop))
        local propThickness = 0.01
        if DoesEntityExist(hitEntity) and hitEntity ~= 0 then
            local entityType = GetEntityType(hitEntity)
            if entityType == 2 or entityType == 3 then
                local forward, right, up, _ = GetEntityMatrix(hitEntity)
                snapNormal = up
            end
        end
        local finalCoords
        if math.abs(snapNormal.z) > 0.95 then
            if snapNormal.z > 0 then
                finalCoords = vector3(snapCoords.x, snapCoords.y, snapCoords.z + propThickness)
            else
                finalCoords = vector3(snapCoords.x, snapCoords.y, snapCoords.z - propThickness)
            end
        else
            finalCoords = vector3(
                snapCoords.x + (snapNormal.x * propThickness),
                snapCoords.y + (snapNormal.y * propThickness),
                snapCoords.z + (snapNormal.z * propThickness)
            )
        end
        SetEntityCoordsNoOffset(prop, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, true)
        return true
    end
    return false
end

function DrawPropAxes(prop)
    local propForward, propRight, propUp, propCoords = GetEntityMatrix(prop)
    local propXAxisEnd = propCoords + propRight * 0.20
    local propYAxisEnd = propCoords + propForward * 0.20
    local propZAxisEnd = propCoords + propUp * 0.20
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propXAxisEnd.x, propXAxisEnd.y, propXAxisEnd.z, 255, 0, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propYAxisEnd.x, propYAxisEnd.y, propYAxisEnd.z, 0, 255, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propZAxisEnd.x, propZAxisEnd.y, propZAxisEnd.z, 0, 0, 255, 255)
end

function DrawSurfaceNormal(coords, surfaceNormal)
    local normalEnd = vector3(
        coords.x + (surfaceNormal.x * 0.5),
        coords.y + (surfaceNormal.y * 0.5),
        coords.z + (surfaceNormal.z * 0.5)
    )
    DrawLine(coords.x, coords.y, coords.z, normalEnd.x, normalEnd.y, normalEnd.z, 255, 255, 255, 255)
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local rayHandle = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 1 + 2 + 4 + 8 + 16, PlayerPedId(), 0)
    local _, hit, coords, surfaceNormal, entity = GetShapeTestResult(rayHandle)
    return hit, coords, surfaceNormal, entity
end

function PropPlacer(proptype, prop)
    local PropHash = GetHashKey(prop)
    heading = 0.0
    pitch = 0.0
    roll = 0.0
    confirmed = false
    RequestModel(PropHash)
    while not HasModelLoaded(PropHash) do
        Wait(0)
    end
    SetCurrentPedWeapon(cache.ped, -1569615261, true)
    local hit, coords, surfaceNormal, entity
    while not hit do
        hit, coords, surfaceNormal, entity = RayCastGamePlayCamera(1000.0)
        Wait(0)
    end
    local tempObj = CreateObject(PropHash, coords.x, coords.y, coords.z, true, false, true)
    EagleEyeSetCustomEntityTint(tempObj, 255, 255, 0) -- Apply yellow tint
    CreateThread(function()
        while not confirmed do
            hit, coords, surfaceNormal, entity = RayCastGamePlayCamera(1000.0)
            if hit then
                AlignPropToSurface(tempObj, surfaceNormal, coords, entity)
                SnapPropToSurface(tempObj, coords, surfaceNormal, entity)
                FreezeEntityPosition(tempObj, true)
                SetEntityCollision(tempObj, false, false)
                SetEntityAlpha(tempObj, 150, false)
                DrawPropAxes(tempObj)
                DrawSurfaceNormal(coords, surfaceNormal)
                local rotationInfo = locale('ui_rotation_info'):format(heading, pitch, roll)
                SetTextScale(0.3, 0.3)
                SetTextColor(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                DisplayText(CreateVarString(10, "LITERAL_STRING", rotationInfo), 0.5, 0.08)
                local surfaceType = GetSurfaceType(surfaceNormal)
                SetTextScale(0.35, 0.35)
                SetTextColor(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                DisplayText(CreateVarString(10, "LITERAL_STRING", locale('ui_surface'):format(surfaceType)), 0.5, 0.05)
            end
            Wait(0)
            local PropPlacerGroupName = CreateVarString(10, 'LITERAL_STRING', Config.PromptGroupName)
            PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)
            local rotationSpeed = 2.0
            if IsControlPressed(1, 0xA65EBAB4) then -- Left arrow
                heading = heading + rotationSpeed
            elseif IsControlPressed(1, 0xDEB34313) then -- Right arrow
                heading = heading - rotationSpeed
            end
            if IsControlPressed(1, 0x6319DB71) then -- Arrow Up (PitchUp)
                pitch = pitch + rotationSpeed
            elseif IsControlPressed(1, 0x8CF8F910) then -- Mouse Wheel Down (PitchDown)
                pitch = pitch - rotationSpeed
            end
            if IsControlPressed(1, 0xF1E9A8D7) then -- Q key (RollLeft)
                roll = roll + rotationSpeed
            elseif IsControlPressed(1, 0xE764D794) then -- E key (RollRight)
                roll = roll - rotationSpeed
            end
            if heading > 360.0 then heading = heading - 360.0 end
            if heading < 0.0 then heading = heading + 360.0 end
            if pitch > 360.0 then pitch = pitch - 360.0 end
            if pitch < 0.0 then pitch = pitch + 360.0 end
            if roll > 360.0 then roll = roll - 360.0 end
            if roll < 0.0 then roll = roll + 360.0 end
            if PromptHasHoldModeCompleted(SetPrompt) then
                confirmed = true
                SetEntityAlpha(tempObj, 255, false)
                SetEntityCollision(tempObj, true, true)
                local finalCoords = GetEntityCoords(tempObj)
                local finalRotation = vector3(pitch, roll, heading)
                DeleteObject(tempObj)
                SetModelAsNoLongerNeeded(PropHash)
                FreezeEntityPosition(cache.ped, true)
                TriggerEvent('phils-posters:client:setupnote', proptype, PropHash, finalCoords, finalRotation, {r = 255, g = 255, b = 0}) -- Pass tint
                FreezeEntityPosition(cache.ped, false)
                break
            end
            if PromptHasHoldModeCompleted(CancelPrompt) then
                DeleteObject(tempObj)
                SetModelAsNoLongerNeeded(PropHash)
                break
            end
        end
    end)
end

RegisterNetEvent('phils-posters:client:createnote', function(proptype, prop)
    PropPlacer(proptype, prop)
end)
