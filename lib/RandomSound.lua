
local ini = require 'ini'
local _ = require '_'
local Menu = require 'Menu'
local rea = require 'rea'
local TextButton = require 'TextButton'
local Component = require 'Component'

local RandomSound = class()

function RandomSound.getDataBases()
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

function RandomSound.chooseDatabase()

    local menu = Menu:create()
    _.forEach(RandomSound.getDataBases(), function(value)
        menu:addItem(value.name, function() return value.filename, value.name end )
    end)

    return RandomSound.readDBFile(menu:show())

end

function RandomSound.readDBFile(fileName)

    if not fileName then return end

    local file = io.open(fileName, 'r')
    local res = {}
    local entry = nil
    if file then
        for line in file:lines() do

            if line:startsWith('FILE') then
                local path = line:sub(tostring('FILE'):len() + 2):split(' ', '"')[1]:unquote()
                entry = {
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

                    entry.data[key] = val
                end)
            end
        end
    end

    return res

end

RandomSound.Button = class(TextButton)

function RandomSound.Button:create(text)

    local self = TextButton:create(text or '?')
    setmetatable(self, RandomSound.Button)
    return self

end

function RandomSound.Button:onButtonClick(mouse)

    if not self.db or mouse:wasRightButtonDown() then
        self.db = RandomSound.chooseDatabase()
    end

    if self.db then
        local index = math.random(1, _.size(self.db))
        local entry = self.db[index]
        reaper.OpenMediaExplorer(entry.path, true)
    end

end

return RandomSound