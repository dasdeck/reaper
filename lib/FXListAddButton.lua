local Image = require 'Image'
local Label = require 'Label'
local Component = require 'Component'
local TextButton = require 'TextButton'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Bus = require 'Bus'
local Mouse = require 'Mouse'
local Track = require 'Track'

local paths = require 'paths'
local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local FXlistAddButton = class(Component)

function FXlistAddButton:create(track, name, index)
    local self = Component:create()
    setmetatable(self, FXlistAddButton)
    self.name = self:addChildComponent(TextButton:create(name or '+fx'))
    self.name.onDrop = function(s, ...)
        self:onDrop(...)
    end
    self.name.onButtonClick = function(s, mouse)

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
            menu:addItem('move all to track',

                Track.getMenu(function(targetTrack)
                    _.forEach(track:getFxList(), function(plugin)
                        plugin:setIndex(99999, targetTrack, Mouse.capture():isAltKeyDown(), true)
                    end)
                    targetTrack:updateFxRouting()
                    track:updateFxRouting()
                end)

            , 'move all fx')
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

    if _.size(track:getFxList()) > 0 then
        self.enabled = self:addChildComponent(TextButton:create('b'))
        self.enabled.onButtonClick = function()
            rea.transaction('toggle fx', function()
                self.track:setValue('fx', self.track:getValue('fx') ~= 1 and 1 or 0)
            end)
        end
        self.enabled.getToggleState = function()
            return self.track:getValue('fx') == 0
        end
    end

    self.track = track
    self.index = index

    return self

end

function FXlistAddButton:repaintOnMouse()
    return true
end

function FXlistAddButton:onDrop()
    if instanceOf(Component.dragging, Component) and Component.dragging.setIndex then
            rea.transaction('move fx', function()
                Component.dragging:setIndex(99999, self.track)
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
    local h = self.h
    local w = self.w

    if self.enabled then
        self.enabled:setBounds(self.w - h,0,h, h)
        w = w - self.enabled.w
    end

    self.name:setBounds(0,0,w, h)

end

return FXlistAddButton