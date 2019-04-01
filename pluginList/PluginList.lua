local Component = require 'Component'
local Directory = require 'Directory'
local Image = require 'Image'
local Watcher = require 'Watcher'
local Mem = require 'Mem'
local TextBox = require 'TextBox'
local State = require 'State'

local paths = require 'paths'
local _ = require '_'
local rea = require 'rea'

local PluginList = class(Component)


function PluginList:create(dir, ...)

    local self = Component:create(...)
    self.dir = dir
    setmetatable(self, PluginList)
    self:update()
    return self
end

function PluginList:update()

    self:deleteChildren()

    _.forEach(self.dir:findFiles(function(path)
        return path:lower():endsWith('.png')
    end), function(file)
        local child = self:addChildComponent(Image:create(file, 'fit'))

        function child.onClick(mouse)
            -- State.app:set('clicks', tostring(tonumber(State.global.get('pluginlist_clicks', 0))+1))
            State.app:set('lastclicked', file:sub(self.dir.dir:len() + 2, -5))
            Mem.app:set(1, Mem.app:get(1) + 1)
        end

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