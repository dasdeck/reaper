
local rea = require 'rea'
local _ = require '_'

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

function TrackState.fromTracks(tracks)

    local Track = require 'Track'

    local states = {}
    _.forEach(tracks, function(track, i)
        local state = track:getState()
        local sourceTracks = _.map(state:getAuxRecs(), Track.get)
        _.forEach(sourceTracks, function(sourceTrack)
            local currentIndex = sourceTrack:getIndex() - 1
            local indexInTemplate = _.indexOf(tracks, sourceTrack)

            if indexInTemplate then
                state = state:withAuxRec(currentIndex, indexInTemplate - 1)
            else
                local sourceTrackIndex = sourceTrack:getIndex() - 1
                state = state:withoutAuxRec(sourceTrackIndex)
            end
        end)

        table.insert(states, state)

    end)

    return states

end

function TrackState:getPlugins()
    local chainContent = self.text:match('(<FXCHAIN.-\n>)\n>')
    local pluginsText = chainContent:match('<FXCHAIN.-(<.*)>'):trim():sub(1, -2)
    local plugins = pluginsText:gmatchall('<(.-\n)(.-)>([^<]*)')
    return plugins
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
    local recs = {}
    for index in self.text:gmatch('AUXRECV (%d) (.-)\n') do
        table.insert(recs, math.floor(tonumber(index)))
    end
    return recs
end

function TrackState:__tostring()
    return self.text
end

function TrackState:withAutoRecArm(enabled)
    local value = tostring(enabled and 1 or 0)
    return TrackState:create(self.text:gsub('AUTO_RECARM %d', 'AUTO_RECARM ' .. value))
end

function TrackState:withoutAuxRec(index)
    local rec = index and tostring(index) or '%d'
    return TrackState:create(self.text:gsub('AUXRECV '..rec..' (.-)\n', ''))
end

function TrackState:withAuxRec(from, to)
    from = tostring(math.floor(tonumber(from)))
    to = tostring(math.floor(tonumber(to)))
    local a = 'AUXRECV '..from..' (.-)\n'
    local b = 'AUXRECV '..to..' %1\n'
    return TrackState:create(self.text:gsub(a, b))
end

return TrackState

