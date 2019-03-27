local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Component = require 'Component'
local Mouse = require 'Mouse'
local rea = require 'rea'
local colors = require 'colors'
local icons = require 'icons'

local FXButton = class(Component)

function FXButton:create(fxSource)
    local self = Component:create()
    setmetatable(self, FXButton)

    self.fxSource = fxSource

    self.text = self:addChildComponent(TextButton:create('fx'))
    self.text.getToggleState = function()
        return fxSource:getFx()
    end
    self.text.onButtonClick = function()
        if Mouse.capture():isAltKeyDown() then
            if fxSource:getFx() then
                rea.transaction('remove fx', function()
                    fxSource:removeFx()
                end)
            end
        else
            -- rea.log('click')
            -- rea.log(self.text.mouse.down)
            local fx = fxSource:getFx()
            if not fx then
                rea.transaction('add fx', function()
                    fx = fxSource:getFx(true)
                end)
            end

            if fx then fx:focus() end
        end
    end

    self.lock = self:addChildComponent(IconButton:create(icons.lock))
    -- self.lock.isDisabled = function()
    --     return not fxSource:getFx()
    -- end
    self.lock.onButtonClick = function()
        self.text.onClick()
        if fxSource:getFx() then
            fxSource:getFx():setLocked(not fxSource:getFx():isLocked())
        end
    end
    self.lock.getToggleState = function()
        return fxSource:getFx() and fxSource:getFx():isLocked()
    end
    self.text.color = colors.fx
    self.lock.color = colors.fx
    return self
end

function FXButton:paint(g)
    self.text.drawBackground(self, g, self.text:getColor())
end

function FXButton:resized()
    local h = self.h
    self.text:setBounds(0,0, self.w - h, h)
    self.lock:setBounds(self.text:getRight(), 0, h, h)
end

return FXButton