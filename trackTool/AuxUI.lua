local Component = require 'Component'
local TextButton = require 'TextButton'
local Slider = require 'Slider'

local rea = require 'rea'
local colors = require 'colors'

local AuxUI = class(Component)

function AuxUI:create(send)
    local self = Component:create()
    setmetatable(self, AuxUI)

    local track = send:getTargetTrack()
    self.name = self:addChildComponent(TextButton:create(track:getName():sub(5)))
    self.name.color = colors.aux
    self.name.onButtonClick = function()
        track:focus()
    end

    self.gain = self:addChildComponent(Slider:create())
    self.gain.color = colors.aux
    self.gain.getValue = function()
        return linToDB(send:getVolume())
    end
    self.gain.setValue = function(s, val)
        return send:setVolume(dbToLin(val))
    end


    self.mute = self:addChildComponent(TextButton:create('M'))
    self.mute.color = colors.mute
    self.mute.getToggleState = function()
        return send:isMuted()
    end
    self.mute.onButtonClick = function(s, mouse)
        rea.transaction('mute send', function()
            send:setMuted(not send:isMuted())
        end)
    end

    return self
end

function AuxUI:resized()
    local h = self.h

    self.name:setBounds(0, 0, self.w - h*2 , h)
    self.gain:setBounds(self.name:getRight(), 0,h, h)
    self.mute:setBounds(self.gain:getRight(), 0,h, h)
end

return AuxUI