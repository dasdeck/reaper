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

local FXlistAddButton = class(Component)

function FXlistAddButton:create(track, name, index)
    local self = Component:create()
    setmetatable(self, FXlistAddButton)
    self.name = self:addChildComponent(TextButton:create(name or '+fx'))
    self.enabled = self:addChildComponent(TextButton:create('b'))
    self.enabled.onButtonClick = function()
        rea.transaction('toggle fx', function()
            self.track:setValue('fx', self.track:getValue('fx') ~= 1 and 1 or 0)
        end)
    end
    self.enabled.getToggleState = function()
        return self.track:getValue('fx') == 0
    end

    self.track = track
    self.index = index

    return self

end

function FXlistAddButton:repaintOnMouse()
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

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem('show channel', function()
            self.track:setOpen()
        end)
        -- menu:addItem('')
        menu:show()
    elseif mouse:isShiftKeyDown() then
        rea.transaction('toggle fx', function()
            self.track:setValue('fx', self.track:getValue('fx') ~= 1 and 1 or 0)
        end)
    elseif mouse:isAltKeyDown() then
        local name = rea.prompt('name')
        if name then
            self.track:addFx(name)
        end
    else
        add()
    end
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

    if self.track:getValue('fx') == 0 then
        g:setColor(colors.mute:with_alpha(0.5))
        g:rect(0, 0 ,self.w, self.h, true)
    end
    if instanceOf(Component.dragging, Component) and Component.dragging.fx  and self:isMouseOver() then
        g:setColor(colors.mute:with_alpha(0.5))
        g:rect(0, 0 ,self.w, self.h, true)
    end
end

function FXlistAddButton:resized()
    local h = 20
    self.name:setBounds(0,0,self.w - h, h)
    self.enabled:setBounds(self.w - h,0,h, h)
end

return FXlistAddButton