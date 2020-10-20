local Menu = require 'Menu'
local _ = require '_'
local rea = require 'rea'
local File = require 'File'
local Directory = class()
local seperator = rea.seperator
function Directory:create(dir, filter)

    if instanceOf(dir, Directory)then
        dir = dir.dir
        filter = dir.filter
    end

    local type = type(dir)
    assert(type == 'string', type .. ':' .. dir)

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

function Directory:childDir(path, filter)
    return Directory:create(self.dir .. seperator .. path, filter)
end

function Directory:childFile(path)
    return File:create(self.dir .. seperator .. path)
end

function Directory:findFile(pattern)
    return _.first(self:findFiles(pattern))
end

function Directory:findFiles(pattern)
    local filter = type(pattern) == 'function' and pattern or function(file)
        return (file:lower() == pattern:lower()) or file:lower():match(pattern:lower())
    end
    return rea.findFiles(self.dir, {}, filter)
end

function Directory:getNextFile(file)
    local current = self:indexOf(file)
    return self:getFiles()[current + 1]
end

function Directory:getPrevFile(file)
    local current = self:indexOf(file)
    return self:getFiles()[current - 1]
end

function Directory:indexOf(needle)
    return _.some(self:getFiles(), function(file, index)
        return file:match(needle) and (index+1)
    end)
end

function Directory:indexOfDirectory(needle)
    return _.some(self:getDirectories(), function(file, index)
        return file:lower() == needle:lower() or file:lower():match(needle:lower()) and (index+1)
    end)
end

function Directory:getFiles()
    return rea.getFiles(self.dir, self.filter)
end

function Directory:getDirectories()
    return rea.getDirectories(self.dir, self.filter)
end

function Directory:__tostring()
    return self.dir
end

function Directory:__eq(b)
    return self.dir == b.dir
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
    local suc, file = reaper.GetUserFileNameForRead(self.dir .. seperator, text or 'load file', ext or '')
    return suc and file or nil
end

function Directory:saveDialog(suffix, initial, override)

    suffix = suffix or ''
    local val = rea.prompt('save', initial)

    if val then
        local file = self.dir .. seperator .. val .. suffix
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

return Directory