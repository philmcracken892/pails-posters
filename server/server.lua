local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local PropsLoaded = false

---------------------------------------------
-- use notebook
---------------------------------------------
RSGCore.Functions.CreateUseableItem(Config.NoteBookItem, function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    TriggerClientEvent('phils-posters:client:createnote', src, Config.NoteBookItem, Config.NoteProp)
end)

---------------------------------------------
-- use note (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RSGCore.Functions.CreateUseableItem(Config.NoteItem, function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    if item.info and item.info.noteid then
        TriggerClientEvent('phils-posters:client:readcopiednote', src, item.info.noteid, item.info.title, item.info.content, item.info.imageUrl)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('notify_poster_empty'), description = locale('notify_poster_empty_desc'), type = 'inform', duration = 7000 })
    end
end)

---------------------------------------------
-- get all prop data
---------------------------------------------
RSGCore.Functions.CreateCallback('phils-posters:server:getallpropdata', function(source, cb, propid)
    MySQL.query('SELECT * FROM phils_posters WHERE propid = ?', {propid}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- check if player is admin
---------------------------------------------
RSGCore.Functions.CreateCallback('phils-posters:server:isAdmin', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        -- Check if player has admin permissions
        -- You can modify this condition based on your permission system
        local isAdmin = RSGCore.Functions.HasPermission(src, 'admin') or
                        Player.PlayerData.job.name == 'admin' or
                        Player.PlayerData.group == 'admin'
        cb(isAdmin)
    else
        cb(false)
    end
end)

---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('phils-posters:server:countprop', function(source, cb, proptype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM phils_posters WHERE citizenid = ? AND proptype = ?", { citizenid, proptype })
    if result then
        cb(result)
    else
        cb(nil)
    end
end)

---------------------------------------------
-- update prop data
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if PropsLoaded then
            TriggerClientEvent('phils-posters:client:updatePropData', -1, Config.PlayerProps)
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
CreateThread(function()
    TriggerEvent('phils-posters:server:getProps')
    PropsLoaded = true
end)

---------------------------------------------
-- save props (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RegisterServerEvent('phils-posters:server:saveProp')
AddEventHandler('phils-posters:server:saveProp', function(data, propId, citizenid, proptype, title, note, imageUrl)
    local datas = json.encode(data)
    MySQL.Async.execute('INSERT INTO phils_posters (properties, propid, citizenid, proptype, title, note, image_url) VALUES (@properties, @propid, @citizenid, @proptype, @title, @note, @image_url)',
    {
        ['@properties'] = datas,
        ['@propid'] = propId,
        ['@citizenid'] = citizenid,
        ['@proptype'] = proptype,
        ['@title'] = title,
        ['@note'] = note,
        ['@image_url'] = imageUrl or nil,
    })
end)

---------------------------------------------
-- new prop (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RegisterServerEvent('phils-posters:server:newProp')
AddEventHandler('phils-posters:server:newProp', function(proptype, location, rotation, hash, title, note, imageUrl)
    local src = source
    local propId = CreateNoteNumber()
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local PropData = {
        id = propId,
        proptype = proptype,
        x = location.x,
        y = location.y,
        z = location.z,
        rx = rotation.x, -- Add rotation data
        ry = rotation.y,
        rz = rotation.z,
        hash = hash,
        builder = Player.PlayerData.citizenid,
        buildttime = os.time()
    }
    table.insert(Config.PlayerProps, PropData)
    TriggerEvent('phils-posters:server:saveProp', PropData, propId, citizenid, proptype, title, note, imageUrl)
    TriggerEvent('phils-posters:server:updateProps')
end)

---------------------------------------------
-- copy note (UPDATED WITH IMAGE URL SUPPORT)
---------------------------------------------
RegisterServerEvent('phils-posters:server:copynote')
AddEventHandler('phils-posters:server:copynote', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    -- Fetch the note content from the database including image URL
    MySQL.Async.fetchAll('SELECT title, note, image_url FROM phils_posters WHERE propid = ?', { data.noteid }, function(result)
        if result and #result > 0 then
            local title = result[1].title
            local content = result[1].note
            local imageUrl = result[1].image_url
            -- Add the note item with metadata including image URL
            Player.Functions.AddItem('poster', 1, false, {
                noteid = data.noteid,
                title = title,
                content = content,
                imageUrl = imageUrl
            })
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['poster'], 'add')
        else
            TriggerClientEvent('ox_lib:notify', src, {title = locale('notify_not_found'), description = locale('notify_not_found_desc'), type = 'inform', duration = 7000 })
        end
    end)
end)

---------------------------------------------
-- distory note (ADMIN ONLY)
---------------------------------------------
RegisterServerEvent('phils-posters:server:distroynote')
AddEventHandler('phils-posters:server:distroynote', function(propid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    -- Check if player has admin permissions
    local isAdmin = RSGCore.Functions.HasPermission(src, 'admin') or
                    Player.PlayerData.job.name == 'admin' or
                    Player.PlayerData.group == 'admin'
    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('notify_access_denied'),
            description = locale('notify_access_denied_admin'),
            type = 'error',
            duration = 7000
        })
        return
    end
    for k, v in pairs(Config.PlayerProps) do
        if v.id == propid then
            table.remove(Config.PlayerProps, k)
        end
    end
    TriggerClientEvent('phils-posters:client:removePropObject', src, propid)
    TriggerEvent('phils-posters:server:PropRemoved', propid)
    TriggerEvent('phils-posters:server:updateProps')
    -- Log the admin action
    print(string.format("[phils-posters] Admin %s (%s) destroyed note with ID: %s",
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        propid))
end)

RegisterServerEvent('phils-posters:server:editnote')
AddEventHandler('phils-posters:server:editnote', function(noteid, newTitle, newContent, newImageUrl)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    -- Optional: Check if this player owns the note OR is admin
    local result = MySQL.prepare.await("SELECT citizenid FROM phils_posters WHERE propid = ?", { noteid })
    if not result then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('notify_error'),
            description = locale('notify_poster_not_found'),
            type = 'error',
            duration = 5000
        })
        return
    end
    -- Allow editing if admin OR owner
    local isAdmin = RSGCore.Functions.HasPermission(src, 'admin') or Player.PlayerData.group == 'admin'
    if not isAdmin and result ~= Player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('notify_access_denied'),
            description = locale('notify_access_denied_edit'),
            type = 'error',
            duration = 5000
        })
        return
    end
    -- Update the note in DB
    MySQL.Async.execute(
        "UPDATE phils_posters SET title = @title, note = @note, image_url = @image_url WHERE propid = @propid",
        {
            ['@title'] = newTitle,
            ['@note'] = newContent,
            ['@image_url'] = newImageUrl or nil,
            ['@propid'] = noteid
        }
    )
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('notify_poster_updated'),
        description = locale('notify_poster_updated_desc'),
        type = 'success',
        duration = 5000
    })
    -- Send updated prop data to all clients
    TriggerEvent('phils-posters:server:updateProps')
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterServerEvent('phils-posters:server:updateProps')
AddEventHandler('phils-posters:server:updateProps', function()
    local src = source
    TriggerClientEvent('phils-posters:client:updatePropData', src, Config.PlayerProps)
end)

---------------------------------------------
-- remove props
---------------------------------------------
RegisterServerEvent('phils-posters:server:PropRemoved')
AddEventHandler('phils-posters:server:PropRemoved', function(propId)
    local result = MySQL.query.await('SELECT * FROM phils_posters')
    if not result then return end
    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        if propData.id == propId then
            MySQL.Async.execute('DELETE FROM phils_posters WHERE id = @id', { ['@id'] = result[i].id })
            for k, v in pairs(Config.PlayerProps) do
                if v.id == propId then
                    table.remove(Config.PlayerProps, k)
                end
            end
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('phils-posters:server:getProps')
AddEventHandler('phils-posters:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM phils_posters')
    if not result[1] then return end
    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        print('loading '..propData.proptype..' prop with ID: '..propData.id)
        table.insert(Config.PlayerProps, propData)
    end
end)

---------------------------------------------
-- create note unique number
--------------------------------------------
function CreateNoteNumber()
    local UniqueFound = false
    local NoteNumber = nil
    while not UniqueFound do
        NoteNumber = math.random(11111111, 99999999)
        local query = "%" .. NoteNumber .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM phils_posters WHERE propid LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return NoteNumber
end
