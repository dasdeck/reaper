local Component = require 'Component'
local Directory = require 'Directory'
local Image = require 'Image'
local Watcher = require 'Watcher'
local Mem = require 'Mem'
local TextBox = require 'TextBox'

local paths = require 'paths'
local _ = require '_'
local rea = require 'rea'

local PluginList = class(Component)


function PluginList:create(...)

    Mem.write('pluginlist', 0, 1)

    local self = Component:create(...)
    setmetatable(self, PluginList)
    self:update()
    return self
end

function PluginList:update()


    local filter = self.filter and self.filter:remove()
    if not filter then
        filter = TextBox:create('vcl', 0,0, 200, 25)
        filter.onChange = function()
            self:update()
        end
    end

    self:deleteChildren()

    self.filter = self:addChildComponent(filter)


    local dir = paths.scriptDir:childDir('images', function(path)
        return path:endsWith('.png')
    end)

    _.forEach(dir:findFiles(function(path)
        return path:lower():endsWith('.png') and (self.filter:getText():len() == 0 or path:lower():match(self.filter:getText()))
    end), function(file)
        self:addChildComponent(Image:create(file, 'fit'))
    end)

    self:resized()

    self:repaint()
end

function PluginList:resized()
    local padding = 2
    if self.w > 0 then
        local y = 0
        _.forEach(self.children, function(child)
            child:setPosition(padding, y + padding)
            child:fitToWidth(self.w - padding * 2)
            y = y + child.h + 2 * padding
        end)
    end
end

return PluginList