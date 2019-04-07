local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Component = require 'Component'
local Mouse = require 'Mouse'
local Menu = require 'Menu'
local Bus = require 'Bus'

local _ = require '_'
local rea = require 'rea'
local colors = require 'colors'
local icons = require 'icons'

local FXButton = class(Component)

function FXButton:create(fxSource, name)
    local self = Component:create()
    setmetatable(self, FXButton)

    self.fxSource = fxSource

    self.text = self:addChildComponent(TextButton:create(name or 'fx'))
    self.text.getToggleState = function()
        return fxSource:getFx()
    end
    self.text.onButtonClick = function(s, mouse)
        if Mouse.capture():isAltKeyDown() then
            if fxSource:getFx() then
                rea.transaction('remove fx', function()
                    fxSource:removeFx()
                end)
            end
        elseif mouse:wasRightButtonDown() then
            local menu = Menu:create()
            local current = fxSource:getFx()
            local busses = Bus.getAllBusses()
            if _.size(busses) > 0 then
                local bussesMenu =  Menu:create()
                _.forEach(busses, function(bus)
                    bussesMenu:addItem(bus:getName(), {
                        callback = function()
                            fxSource:setFx(bus)
                        end,
                        checked = bus == current
                    }, 'set bus')
                end)
                menu:addItem('bus', bussesMenu)
            end

            menu:addItem('create new bus', function()
                fxSource:getFx(true)
            end, 'create bus')
            menu:show()

        else
            local fx = fxSource:getFx()
            if not fx then
                rea.transaction('add fx', function()
                    fx = fxSource:getFx(true)
                end)
            end

            -- if fx then fx:focus() end
        end
    end

    self.lock = self:addChildComponent(IconButton:create(icons.lock))
    -- self.lock.isDisabled = function()
    --     return not fxSource:getFx()
    -- end
    self.lock.onButtonClick = function(s, mouse)
        self.text.onButtonClick(s, mouse)
        if fxSource:getFx() then
            fxSource:getFx():setLocked(not fxSource:getFx():isLocked())
        end
    end
    self.lock.getToggleState = function()
        return fxSource:getFx() and fxSource:getFx():isLocked()
    end
    self.text.color = colors.bus
    self.lock.color = colors.bus
    return self
end

function FXButton:getDefaultName()
    return 'bus'
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