local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local SpawnedProps = {}
local isBusy = false
local fx_group = "scr_dm_ftb"
local fx_name = "scr_mp_chest_spawn_smoke"
local fx_scale = 1.3

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(0, 255, 0, 215)
        local str = CreateVarString(10, "LITERAL_STRING", text)
        SetTextCentre(1)
        DisplayText(str, _x, _y)
    end
end

-- Function to validate if a URL is a valid image URL
function IsValidImageURL(url)
    if not url or url == "" then
        return false
    end
    -- Check if it's a valid URL format
    if not string.match(url, "^https?://") then
        return false
    end
    -- Check for common image file extensions or Discord CDN
    local imageExtensions = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"}
    local isDiscordCDN = string.match(url, "cdn%.discordapp%.com") or string.match(url, "media%.discordapp%.net")
    if isDiscordCDN then
        return true
    end
    for _, ext in ipairs(imageExtensions) do
        if string.match(string.lower(url), ext) then
            return true
        end
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerPos = GetEntityCoords(cache.ped)
        for i = 1, #SpawnedProps do
            local prop = SpawnedProps[i]
            if prop and prop.obj and DoesEntityExist(prop.obj) then
                local propPos = GetEntityCoords(prop.obj)
                local distance = #(playerPos - propPos)
                if distance <= (Config.TextDisplayDistance or 10.0) then
                    DrawText3D(propPos.x, propPos.y, propPos.z + 0.3, locale('ui_notice'))
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(150)
        local pos = GetEntityCoords(cache.ped)
        local InRange = false
        for i = 1, #Config.PlayerProps do
            local prop = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
            local dist = #(pos - prop)
            if dist >= 50.0 then goto continue end
            local hasSpawned = false
            InRange = true
            for z = 1, #SpawnedProps do
                local p = SpawnedProps[z]
                if p.id == Config.PlayerProps[i].id then
                    hasSpawned = true
                end
            end
            if hasSpawned then goto continue end
            local modelHash = Config.PlayerProps[i].hash
            local data = {}
            if not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(1)
                end
            end
            data.id = Config.PlayerProps[i].id
            -- Check if this prop has new rotation data or uses legacy heading
            if Config.PlayerProps[i].rx and Config.PlayerProps[i].ry and Config.PlayerProps[i].rz then
                -- New rotation system - use exact coordinates and rotation from surface sticking
                data.obj = CreateObject(modelHash, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z, false, false, false)
                SetEntityRotation(data.obj, Config.PlayerProps[i].rx, Config.PlayerProps[i].ry, Config.PlayerProps[i].rz, 2, false)
            else
                -- Legacy heading system for backward compatibility
                data.obj = CreateObject(modelHash, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z - 1.2, false, false, false)
                SetEntityHeading(data.obj, Config.PlayerProps[i].h or 0.0)
                -- Use ground placement for legacy props
                SetEntityAsMissionEntity(data.obj, true)
                PlaceObjectOnGroundProperly(data.obj)
                Wait(100) -- Shorter wait since we're not placing on ground for new system
            end
            -- Common setup for both systems
            SetEntityAsMissionEntity(data.obj, true)
            -- Only use PlaceObjectOnGroundProperly for legacy system (floor placement)
            if not (Config.PlayerProps[i].rx and Config.PlayerProps[i].ry and Config.PlayerProps[i].rz) then
                Wait(1000)
            else
                Wait(100) -- Shorter wait for surface-stuck props
            end
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(modelHash)
            if Config.EnableVegModifier then
                -- veg modify
                local veg_modifier_sphere = 0
                if veg_modifier_sphere == nil or veg_modifier_sphere == 0 then
                    local veg_radius = 3.0
                    local veg_Flags = 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256
                    local veg_ModType = 1
                    veg_modifier_sphere = AddVegModifierSphere(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z, veg_radius, veg_ModType, veg_Flags, 0)
                else
                    RemoveVegModifierSphere(Citizen.PointerValueIntInitialized(veg_modifier_sphere), 0)
                    veg_modifier_sphere = 0
                end
            end
            SpawnedProps[#SpawnedProps + 1] = data
            hasSpawned = false
            -- create target for the entity
            exports['rsg-target']:AddTargetEntity(data.obj, {
                options = {
                    {
                        type = 'client',
                        icon = 'far fa-eye',
                        label = locale('target_label'),
                        action = function()
                            TriggerEvent('phils-posters:client:opennotes', data.id, data.obj)
                        end
                    },
                },
                distance = 3
            })
            -- end of target
            ::continue::
        end
        if not InRange then
            Wait(5000)
        end
    end
end)

---------------------------------------------
-- open note menu (UPDATED WITH ADMIN CHECK)
---------------------------------------------
RegisterNetEvent('phils-posters:client:opennotes', function(noteid, entity)
    -- Check if player is admin before showing destroy option
    RSGCore.Functions.TriggerCallback('phils-posters:server:isAdmin', function(isAdmin)
        local menuOptions = {
            {
                title = locale('menu_read_poster'),
                icon = 'fa-solid fa-book',
                event = 'phils-posters:client:readnote',
                args = {
                    noteid = noteid
                },
                arrow = true
            },
            {
                title = locale('menu_copy_poster'),
                icon = 'fa-solid fa-hand-paper',
                serverEvent = 'phils-posters:server:copynote',
                args = {
                    noteid = noteid
                },
                arrow = true
            }
        }
        -- Only add destroy option if player is admin
        if isAdmin then
            table.insert(menuOptions, {
                title = locale('menu_edit_poster'),
                icon = 'fa-solid fa-pen-to-square',
                event = 'phils-posters:client:editnote',
                args = {
                    noteid = noteid
                },
                arrow = true
            })
            table.insert(menuOptions, {
                title = locale('menu_destroy_poster'),
                icon = 'fa-solid fa-fire',
                event = 'phils-posters:client:distroynote',
                args = {
                    noteid = noteid,
                    entity = entity,
                }
            })
        end
        lib.registerContext({
            id = 'note_menu',
            title = locale('menu_poster_menu'),
            options = menuOptions
        })
        lib.showContext('note_menu')
    end)
end)

---------------------------------------------
-- create note (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RegisterNetEvent('phils-posters:client:setupnote', function(proptype, PropHash, pPos, rotation)
    local input = lib.inputDialog(locale('dialog_create_note'), {
        {
            type = 'input',
            label = locale('input_title'),
            required = true
        },
        {
            type = 'textarea',
            label = locale('input_content'),
            autosize = true,
            required = true
        },
        {
            type = 'input',
            label = locale('input_image_url'),
            description = locale('input_image_url_desc'),
            required = false
        }
    })
    if not input then
        return
    end
    -- Validate image URL if provided
    local imageUrl = input[3]
    if imageUrl and imageUrl ~= "" then
        if not IsValidImageURL(imageUrl) then
            lib.notify({
                title = locale('notify_invalid_url_title'),
                description = locale('notify_invalid_url_desc'),
                type = 'error',
                duration = 5000
            })
            return
        end
    end
    TriggerEvent('phils-posters:client:placeNewProp', proptype, PropHash, pPos, rotation, input[1], input[2], imageUrl)
end)

RegisterNUICallback('closeNote', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

---------------------------------------------
-- read note (UPDATED WITH IMAGE DISPLAY)
---------------------------------------------
RegisterNetEvent('phils-posters:client:readnote', function(data)
    RSGCore.Functions.TriggerCallback('phils-posters:server:getallpropdata', function(result)
        if not result or not result[1] then
            lib.notify({
                title = locale('notify_error'),
                description = locale('notify_load_note_error'),
                type = 'error',
                duration = 5000
            })
            return
        end
        local noteData = result[1]
        local title = noteData.title or locale('ui_untitled_note')
        local content = noteData.note or locale('ui_no_content')
        local imageUrl = noteData.image_url
        -- Set focus and show custom UI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'showNote',
            title = title,
            content = content,
            imageUrl = imageUrl
        })
    end, data.noteid)
end)

RegisterNetEvent('phils-posters:client:readcopiednote', function(noteid, title, content, imageUrl)
    -- Set focus and show custom UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showNote',
        title = title or locale('ui_untitled_poster'),
        content = content or locale('ui_no_content'),
        imageUrl = imageUrl
    })
end)

---------------------------------------------
-- distroy note
---------------------------------------------
RegisterNetEvent('phils-posters:client:distroynote', function(data)
    if not isBusy then
        isBusy = true
        local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
        Wait(3000)
        ClearPedTasks(cache.ped)
        local boxcoords = GetEntityCoords(data.entity)
        local fxcoords = vector3(boxcoords.x, boxcoords.y, boxcoords.z)
        UseParticleFxAsset(fx_group)
        smoke = StartParticleFxNonLoopedAtCoord(fx_name, fxcoords, 0.0, 0.0, 0.0, fx_scale, false, false, false, true)
        TriggerServerEvent('phils-posters:server:distroynote', data.noteid)
        FreezeEntityPosition(cache.ped, false)
        isBusy = false
        return
    else
        lib.notify({ title = locale('notify_busy'), type = 'error', duration = 7000 })
    end
end)

RegisterNetEvent('phils-posters:client:editnote', function(data)
    -- First fetch current note data from the server
    RSGCore.Functions.TriggerCallback('phils-posters:server:getallpropdata', function(result)
        if not result or not result[1] then
            lib.notify({
                title = locale('notify_error'),
                description = locale('notify_load_poster_error'),
                type = 'error',
                duration = 5000
            })
            return
        end
        local currentTitle = result[1].title or ""
        local currentContent = result[1].note or ""
        local currentImageUrl = result[1].image_url or ""
        -- Show edit dialog with pre-filled values
        local input = lib.inputDialog(locale('dialog_edit_poster'), {
            { type = 'input', label = locale('input_title'), default = currentTitle, required = true },
            { type = 'textarea', label = locale('input_content'), default = currentContent, autosize = true, required = true },
            { type = 'input', label = locale('input_image_url'), default = currentImageUrl }
        })
        if not input then return end
        -- Validate image URL
        local newImageUrl = input[3]
        if newImageUrl and newImageUrl ~= "" then
            if not IsValidImageURL(newImageUrl) then
                lib.notify({
                    title = locale('notify_invalid_url_title'),
                    description = locale('notify_invalid_edit_url'),
                    type = 'error',
                    duration = 5000
                })
                return
            end
        end
        -- Send updated data to server
        TriggerServerEvent('phils-posters:server:editnote', data.noteid, input[1], input[2], newImageUrl)
    end, data.noteid)
end)

---------------------------------------------
-- remove prop object
---------------------------------------------
RegisterNetEvent('phils-posters:client:removePropObject')
AddEventHandler('phils-posters:client:removePropObject', function(prop)
    for i = 1, #SpawnedProps do
        local o = SpawnedProps[i]
        if o.id == prop then
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterNetEvent('phils-posters:client:updatePropData')
AddEventHandler('phils-posters:client:updatePropData', function(data)
    Config.PlayerProps = data
end)

---------------------------------------------
-- place prop (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RegisterNetEvent('phils-posters:client:placeNewProp')
AddEventHandler('phils-posters:client:placeNewProp', function(proptype, pHash, pos, rotation, title, note, imageUrl)
    RSGCore.Functions.TriggerCallback('phils-posters:server:countprop', function(result)
        if result > Config.MaxNotes then
            lib.notify({ title = locale('notify_max_posters'), type = 'error', duration = 7000 })
            return
        end
        if not IsPedInAnyVehicle(PlayerPedId(), false) and not isBusy then
            isBusy = true
            local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
            FreezeEntityPosition(cache.ped, true)
            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            Wait(3000)
            ClearPedTasks(cache.ped)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('phils-posters:server:newProp', proptype, pos, rotation, pHash, title, note, imageUrl)
            isBusy = false
            return
        else
            lib.notify({ title = locale('notify_cant_place'), type = 'error', duration = 7000 })
        end
    end, proptype)
end)

function CanPlacePropHere(pos)
    local canPlace = true
    for i = 1, #Config.PlayerProps do
        local checkprops = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
        local dist = #(pos - checkprops)
        if dist < 0.5 then -- reduced from 3.0 to 0.5 for closer placement
            canPlace = false
        end
    end
    return canPlace
end

---------------------------------------------
-- clean up
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #SpawnedProps do
        local props = SpawnedProps[i].obj
        SetEntityAsMissionEntity(props, false)
        FreezeEntityPosition(props, false)
        DeleteObject(props)
    end
end)
