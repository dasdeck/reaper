local State = require 'State'
local File = require 'File'
local _ = require '_'
local ini = require 'ini'
local rea = require 'rea'

local DataBase = class()

function DataBase.getDataBases()
    local reaperIni = ini.load(reaper.get_ini_file())

    local basepath = reaper.GetResourcePath() .. '/MediaDB/'
    local favorite = 'ShortcutT'
    local res = {}

    _.forEach(reaperIni.reaper_sexplorer, function(value, key)
        if key:startsWith(favorite) then

            local index = key:sub(1 + favorite:len())
            filenameKey = 'Shortcut' .. index
            local filename = reaperIni.reaper_sexplorer[filenameKey]

            table.insert(res, {name = value, filename = basepath .. filename})
        end
    end)

    return res
end

function DataBase.getDefaultDataBase()
    local databases = DataBase.getDataBases()
    return _.size(databases) > 0 and DataBase:create(State.global.get('database_default', _.first(databases).filename))
end

function DataBase.setDefaultDataBase(path)
    State.global.set('database_default', path)
end

function DataBase:create(path)

    local rand = tostring(reaper.time_precise()):reverse():sub(1,6)

    rea.log(rand)

    math.randomseed(tonumber(rand))

    local self = {
        paths = {},
        path = path
    }
    self.file = File:create(path)

    setmetatable(self, DataBase)
    self.entries = self:readDBFile(path)
    return self
end

function DataBase:getRandomEntry(filter)
    local entries = self.entries
    if filter and filter:len() > 0 then
        entries = _.filter(entries, function(entry)
            return entry.path:lower():includes(filter)
        end, true)
    end
    local numEntries = _.size(entries)

    if numEntries > 0 then

        local size = _.size(entries)
        local index = math.random(1, size)
        return entries[index]
    end
end

function DataBase:store()
    local paths = _.join(_.map(self.paths, function(path)
        return 'PATH "' .. path .. '"'
    end), '\n')

    local entries = _.join(_.map(self.entries, function(entry)
        local file = 'FILE "' .. entry.path .. '" ' .. _.join(entry.sizes, ' ')
        if entry.data then
            file = file .. '\nDATA ' .. _.join(_.map(entry.data, function(data, key)
                if key == 'u' and entry.rating then
                    local tags = table.clone(data)
                    table.insert(tags, 1, entry.rating)
                    data = tags
                end
                local res = key .. ':' .. _.join(data, ' ')
                if _.size(data) > 1 then
                    -- assert(false, dump(data))
                    return res:quote()
                else
                    return res
                end
            end), ' ')
        end
        return file
    end), '\n')

    self.file:setContent(paths .. '\n' .. entries)
end

function DataBase:getTags()
    local tags = {}
    _.forEach(self.entries, function(entry)
        if entry.data and entry.data.u then
            _.forEach(entry.data.u, function(tag, i)
                if not tag:isNumeric() then
                    tags[tag] = tag
                end
            end)
        end
    end)
    return tags
end

function DataBase:readDBFile(fileName)

    if not fileName then return end

    local file = io.open(fileName, 'r')
    local res = {}
    local entry = nil
    if file then
        for line in file:lines() do

            if line:startsWith('PATH') then
                table.insert(self.paths, line:sub(tostring('PATH'):len() + 2):trim():unquote())
            elseif line:startsWith('FILE') then
                local parts = line:sub(tostring('FILE'):len() + 2):split(' ', '"')
                local path = parts[1]:trim():unquote()
                local sizes = {parts[2],parts[3],parts[4]}
                entry = {
                    db = self,
                    path = path,
                    sizes = sizes
                }
                table.insert(res, entry)
            elseif line:startsWith('DATA') then
                entry.data = {}
                local dataString = line:sub(tostring('DATA'):len() + 2 ):trim()
                local data = dataString:split(' ', '"')
                _.forEach(data, function(val, key)
                    local keyVal = val:unquote():split(':')
                    local key = keyVal[1]:trim()
                    local val = keyVal[2] and keyVal[2]:trim() or ''


                    entry.data[key] = val:split(' ')
                end)
            end
        end
    end

    return res

end

return DataBase