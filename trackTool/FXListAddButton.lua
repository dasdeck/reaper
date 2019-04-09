local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Aux = require 'Aux'
local Bus = require 'Bus'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'

local FXlistAddButton = class(TextButton)

function FXlistAddButton:create(track, name, index)

    local self = TextButton:create(name or '+fx')
    setmetatable(self, FXlistAddButton)

    self.track = track
    self.index = index

    return self

end

function TextButton:repaintOnMouse()
    return true
end

function FXlistAddButton:onButtonClick(mouse)

    local add = function()
        PluginListApp.pick(PluginListApp.cats.effects, function(name)
            rea.transaction('add effect', function()
                local fx = self.track:addFx(name)
                if fx then
                    if self.index then fx:setIndex(self.index) end
                    fx:open()
                else
                    return false
                end
            end)
        end)
    end

    add()

end

function FXlistAddButton:onDrop()
    if instanceOf(Component.dragging, Component) and Component.dragging.fx then
            rea.transaction('move fx', function()
                local from = Component.dragging.fx.index
                local to = self.index or 9999
                if to > from then
                    to = to - 1
                end

                Component.dragging.fx:setIndex(to, self.track)
            end)
    else
        self:repaint('all')
    end
end

function FXlistAddButton:paintOverChildren(g)

    if instanceOf(Component.dragging, Component) and Component.dragging.fx  and self:isMouseOver() then
        g:setColor(colors.mute:with_alpha(0.5))
        g:rect(0, 0 ,self.w, self.h, true)
    end
end

return FXlistAddButton