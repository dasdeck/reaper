
local rea = require 'rea'

local TrackState = class()

function TrackState.fromTemplate(templateData)

    local res = {}
    for match in  templateData:gmatch('(<TRACK.->)') do
        state = TrackState:create(match)
        aux = state:getAuxRecs()
        table.insert(res, state)
    end

    return res
end

function TrackState:withLocking(locked)
    local text = self.text
    if locked ~= self:isLocked() then
        if locked then
            text = self.text:gsub('<TRACK', '<TRACK \n LOCK 1\n')
        else
            text = self.text:gsub('(LOCK %d)', '')
        end
    end

    return TrackState:create(text)
end

function TrackState:isLocked()
    local locker = tonumber(self.text:match('LOCK (%d)'))
    return locker and (locker & 1 > 0) or false
end

function TrackState:create(text)
    local self = {
        text = text
    }
    setmetatable(self, TrackState)
    return self
end

function TrackState:getAuxRecs()
    local res = {}
    for index, rest in  self.text:gmatch('AUXRECV (%d) (.-)\n') do
        m, o = index, rest
    end
end

function TrackState:__tostring()
    return self.text
end

function TrackState:withoutAuxRecs()
    return TrackState:create(self.text:gsub('AUXRECV (%d) (.-)\n', ''))
end



-- rea.log(TrackState:create('test'):gsub('test', 'tested'))

return TrackState

