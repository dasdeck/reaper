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

function AuxUI:create(send)
    local self = Component:create()
    setmetatable(self, AuxUI)

    local track = send:getTargetTrack()
    local icon = track:getImage()
    self.name = self:addChildComponent(TextButton:create(icon and Image:create(icon, 'fit', 1) or track:getName()))
    self.name.color = colors.aux
    self.name.onButtonClick = function(s, mouse)

        if mouse:isAltKeyDown() then
            rea.transaction('remove send', function()
                send:remove()
            end)
        else
            track:focus()
        end
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

    local w = self.w / 3

    self.name:setBounds(0, 0, h , h)
    self.gain:setBounds(self.name:getRight(), 0,self.w - h*2, h)

    self.mute:setBounds(self.gain:getRight(), 0,h, h)
end

function AuxUI.pickOrCreateMenu(track)
    local menu = Menu:create()

    menu:addItem('create aux', function()
        -- TODO
        track:createSend(Aux.createAux('new'))
    end, 'create aux')

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