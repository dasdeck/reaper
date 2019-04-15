
local ButtonList = require 'ButtonList'
local Aux = require 'Aux'
local AuxUI = require 'AuxUI'

local _ = require '_'
local rea = require 'rea'

local AuxSends = class(ButtonList)
function AuxSends:create(track)

    local self = ButtonList:create()
    setmetatable(self, AuxSends)
    self.track = track
    self:updateList()
    return self

end

function AuxSends:getData()
    local sends = self.track:getSends()

    return _.map(Aux.getAuxTracks(), function(aux)

        if aux == self.track then return nil end

        local send = _.find(sends, function(send)
            return send:getTargetTrack() == aux
        end)

        if not send then
            rea.log('add send')
            send = self.track:createSend(aux):setMuted(true)
            assert(send)
        end

        return {
            proto = AuxUI,
            args = send,
            size = 20
        }
    end)

end

return AuxSends