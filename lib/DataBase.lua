local State = require 'State'
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
    local self = {
        path = path
    }
    setmetatable(self, DataBase)
    self.db = self:readDBFile(path)
    return self
end

function DataBase:getRandomEntry(filter)
    local entries = self.db
    if filter and filter:len() > 0 then
        entries = _.filter(entries, function(entry)
            return entry.path:includes(filter)
        end, true)
        -- rea.log(entries)
    end
    local numEntries = _.size(entries)
    -- rea.log(numEntries)
    if numEntries > 0 then
        local index = math.random(1, _.size(entries))
        return entries[index]
    end
end

function DataBase:getTags()
    local tags = {}
    _.forEach(self.db, function(entry)
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

            if line:startsWith('FILE') then
                local path = line:sub(tostring('FILE'):len() + 2):split(' ', '"')[1]:trim():unquote()
                entry = {
                    db = self,
                    path = path,
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