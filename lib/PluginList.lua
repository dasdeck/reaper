local Component = require 'Component'
local Directory = require 'Directory'
local Image = require 'Image'
local Watcher = require 'Watcher'
local Mem = require 'Mem'
local TextBox = require 'TextBox'
local State = require 'State'

local paths = require 'paths'
local colors = require 'colors'
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

        function child.paintOverChildren(s, g)
            if child.selected then
                g:setColor(colors.bus:with_alpha(1))
                g:rect(0,0,child.w, child.h)

                g:setColor(colors.bus:with_alpha(0.5))
                g:rect(0,0,child.w, child.h, true)
            end
        end

        function child.onClick(s, mouse)
            if mouse:isCommandKeyDown() then
                child.selected = not child.selected
                child:repaint()
            end
        end

        function child.onDblClick(mouse)
            State.app:set('lastclicked', file:sub(self.dir.dir:len() + 2, -5))
            local next = Mem.app:get(1) + 1
            Mem.app:set(1, next)
        end

    end)

    self:resized()
end

function PluginList:resized()
    if self.w > 0 then
        local padding = 2
        local y = 0
        _.forEach(self.children, function(child)
            child:setPosition(padding, y + padding)
            child:fitToWidth(self.w - padding * 2)
            y = y + child.h + 2 * padding
        end)
        self.h = y
    end
end

return PluginList