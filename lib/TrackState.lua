
local rea = require 'rea'
local _ = require '_'
local ReaState = require 'ReaState'

local TrackState = class()

function TrackState.fromTemplate(templateData)
    local Track = require 'Track'

    local states = _.map(_.map(templateData:split('\n\n'), string.trim), TrackState.create)
    local firstIndex = reaper.CountTracks(0)

    local tracks = {}
    _.forEach(states, function(state, i)

        local track = Track.insert()
        table.insert(tracks, track)

        _.forEach(state:getAuxRecs(), function(index)
            states[i] = state:withAuxRec(index, index + firstIndex)
        end)
    end)

    _.forEach(states, function(state, i)
        local track = tracks[i]
        track:setState(state)
        track.guid = reaper.GetTrackGUID(track.track)
    end)

    _.forEach(tracks, function(track)

        local newId = reaper.genGuid('')
        local oldId = track.guid

        _.forEach(tracks, function(otherTrack)
            if track ~= otherTrack then
                local stateText = otherTrack:getState(true)
                local newState = TrackState.create(stateText.text:gsub(oldId:escaped(), newId))
                otherTrack:setState(newState)
            end
        end)

    end)

    return tracks
end

function TrackState.fromTracks(tracks)

    local Track = require 'Track'

    local guids = {}
    local states = {}
    _.forEach(tracks, function(track, i)
        local state = track:getState()
        guids[reaper.genGuid('')] = track.guid
        -- rea.log('test:' .. tostring(track))

        local sourceTracks = _.map(state:getAuxRecs(), Track.get)
        _.forEach(sourceTracks, function(sourceTrack)
            local currentIndex = sourceTrack:getIndex() - 1
            local indexInTemplate = _.indexOf(tracks, sourceTrack)

            -- rea.log('rec:' .. tostring(sourceTrack))
            if indexInTemplate then
                -- rea.log('remap:' .. tostring(currentIndex) .. ':' .. tostring(indexInTemplate))
                state = state:withAuxRec(currentIndex, indexInTemplate - 1)
            else
                state = state:withoutAuxRec(currentIndex)
            end
        end)

        table.insert(states, state)

    end)

    return _.map(states, function(state)
        return TrackState.create(_.reduce(guids, function(carr, guid, replace)
            return carr:gsub(guid:escaped(), replace)
        end, state.text))
    end)

end

function TrackState.create(text)
    local self = {
        text = text
    }
    setmetatable(self, TrackState)
    return self
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

    return TrackState.create(text)
end

function TrackState:isLocked()
    local locker = tonumber(self.text:match('LOCK (%d)'))
    return locker and (locker & 1 > 0) or false
end

function TrackState:getAuxRecs()
    local recs = {}
    for index in self.text:gmatch('AUXRECV (%d+) (.-)\n') do
        table.insert(recs, math.floor(tonumber(index)))
    end
    return recs
end

function TrackState:__tostring()
    return self.text
end

function TrackState:withAutoRecArm(enabled)
    local value = tostring(enabled and 1 or 0)
    return TrackState.create(self.text:gsub('AUTO_RECARM %d', 'AUTO_RECARM ' .. value))
end

function TrackState:withoutAuxRec(index)
    local rec = index and tostring(index) or '%d'
    return TrackState.create(self.text:gsub('AUXRECV '..rec..' (.-)\n', ''))
end

function TrackState:getRows()
    return self.text:split('\n')
end

function TrackState:withValue(name, values)
   return TrackState.create(_.join(_.map(self:getRows(), function(row)
        local vals = row:split(' ')
        if _.first(vals) == name then
            if type(values) == 'function' then
                return _.join((values(vals) or vals),' ')
            else
                return _.join(values, ' ')
            end
        else
            return row
        end
    end), '\n'))
end

function TrackState:getValue(name, default)
    return _.find(self:getRows(), function(row)
        local vals = row:split(' ')
        if _.first(vals) == name then
            return vals
        end
    end)
end

function TrackState:withAuxRec(from, to)
    from = tostring(math.floor(tonumber(from)))
    to = tostring(math.floor(tonumber(to)))
    local a = 'AUXRECV '..from..' (.-)\n'
    local b = 'AUXRECV '..to..' %1\n'
    return TrackState.create(self.text:gsub(a, b))
end

return TrackState

