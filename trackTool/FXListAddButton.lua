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

function FXlistAddButton:create(track, name)

    local self = TextButton:create(name or '+fx')
    setmetatable(self, FXlistAddButton)

    self.track = track

    return self

end

function FXlistAddButton:onButtonClick(mouse)

    local add = function()
        PluginListApp.pick(PluginListApp.cats.effects, function(name)
            rea.transaction('add effect', function()
                self.track:addFx(name)
            end)
        end)
    end

    add()

end

function FXlistAddButton:onDrop()
    if instanceOf(Component.dragging, Component) and Component.dragging.fx then
            rea.transaction('move fx', function()
                Component.dragging.fx:setIndex(9999, self.track)
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