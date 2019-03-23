local Component = require 'Component'
local Directory = require 'Directory'
local Image = require 'Image'
local paths = require 'paths'
local _ = require '_'

local PluginList = class(Component)

function PluginList:create()

    local dir = paths.scriptDir:childDir('images', function(path)
        return path:endsWith('.png')
    end)

    local self = Component:create()

    _.forEach(dir:getFiles(), function(file)
        self:addChildComponent(Image:create(file))
    end)
    setmetatable(self, PluginList)
    return self
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
        -- self.h = y
    end
end

return PluginList