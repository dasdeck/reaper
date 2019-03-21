local Menu = require 'Menu'
local _ = require '_'
local rea = require 'Reaper'
local File = require 'File'
local Directory = class()

function Directory:create(dir, filter)

    assert(type(dir) == 'string')

    local self = {}
    setmetatable(self, Directory)

    self.dir = dir
    self.filter = filter

    return self
end

function Directory:mkdir()
    reaper.RecursiveCreateDirectory(self.dir, 0)
    return self
end

function Directory:file(path)
    return File:create(self.dir .. '/' .. path)
end

function Directory:listAsMenu(selected)

    local menu = Menu:create()
    _.forEach(self:getFiles(), function(file, index)
        menu:addItem(_.last(file:split(':')), {
            callback = function()
                return index
            end,
            checked = index == selected
        })
    end)
    return menu:show()

end

function Directory:browseForFile(ext, text)
    local suc, file = reaper.GetUserFileNameForRead(self.dir .. '/', text or 'load file', ext or '')
    return suc and file or nil
end

function Directory:saveDialog(suffix, initial, override)

    suffix = suffix or ''
    local val = rea.prompt('save', initial)

    if val then
        local file = self.dir .. '/' .. val .. suffix
        if not reaper.file_exists(file) or override then
            return file
        else
            local res = reaper.MB('file already exists. override?', 'override?', 3)
            if res == 6 then return file
            elseif res == 2 then return nil
            elseif res == 7 then return self:saveDialog(suffix, val, override)
            end
        end
    end
end

function Directory:indexOf(needle)
    return _.some(self:getFiles(), function(file, index)
        return file:match(needle) and (index+1)
    end)
end

function Directory:getFiles()
    return rea.getFiles(self.dir, self.filter)
end

return Directory