local Component = require 'Component'
local TextButton = require 'TextButton'
local Image = require 'Image'
local Slider = require 'Slider'
local PluginListApp = require 'PluginListApp'
local Menu = require 'Menu'
local Aux = require 'Aux'

local _ = require '_'
local rea = require 'rea'
local colors = require 'colors'

local AuxUI = class(Component)

function AuxUI:create(send, source, target)
    -- assert(send)
    local self = Component:create()
    setmetatable(self, AuxUI)

    self.track = track
    self.target = target
    self.send = send


    track = target or send:getTargetTrack()
    local icon = track:getImage()
    self.name = self:addChildComponent(TextButton:create(icon and Image:create(icon, 'fit', 1) or track:getName()))
    self.name.color = colors.aux

    self.name.onButtonClick = function(s, mouse)

        if not self.send and source and target and source:canSendTo(target) then
            rea.transaction('toggle send', function()
                self.send = source:createSend(target)
            end)
        elseif self.send then
            if mouse:isAltKeyDown() then
                rea.transaction('remove send', function()
                    self.send:remove()
                end)
            else
                rea.transaction('toggle send', function()
                    self.send:setMuted(not send:isMuted())
                end)
            end
        end
    end

    self.gain = self:addChildComponent(Slider:create())
    -- self.gain.color = colors.aux
    self.gain.pixelsPerValue = 10

    self.gain.getValue = function()
        return linToDB(send and send:getVolume() or 1)
    end
    self.gain.setValue = function(s, val)
        if send then send:setVolume(dbToLin(val)) end
    end

    self.gain.getText = function()
        return nil
    end

    function self.gain:getMin()
        return -60
    end

    function self.gain:getMax()
        return 10
    end

    -- self.mute = self:addChildComponent(TextButton:create('M'))
    -- self.mute.color = colors.mute
    self.name.getToggleState = function()
        return self.send and not self.send:isMuted()
    end

    return self
end

function AuxUI:resized()
    local h = self.h

    local w = self.w / 3

    self.name:setBounds(0, 0, h , h)
    self.gain:setBounds(self.name:getRight(), 0,self.w - h, h)

    -- self.mute:setBounds(self.gain:getRight(), 0,h, h)
end

function AuxUI:getAlpha()
    return self.name:getToggleState() and 1 or 0.5
end

function AuxUI.pickOrCreateMenu(track)
    local menu = Menu:create()

    menu:addItem('create aux', function()
        AuxUI.pickAndCreate(track)
    end)

    local auxs = Aux.getAuxTracks()
    if _.size(auxs) then
        menu:addSeperator()
        _.forEach(auxs, function(aux)
            menu:addItem(aux:getName(), function()
                track:createSend(aux)
            end, 'add send')
        end)
    end

    menu:show()
end

function AuxUI.pickAndCreate(track)
    local aux
    PluginListApp.pick(PluginListApp.cats.effects, function(res)
        rea.transaction('add aux', function()
            aux = Aux.createAux(res)
            local plugin = aux:addFx(res)
            if not plugin then
                aux:remove()
                return false
            end
            aux:focus()
            aux:setSelected(1)
            plugin:open()

            if track and aux then
                track:createSend(aux)
            end
        end)
    end)
    return aux
end

return AuxUI