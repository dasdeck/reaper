local Instrument = class()
local Track = require 'Track'
local DrumRack = require 'DrumRack'
local paths = require 'paths'
local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'


function Instrument.createInstrument(instrName)

    local track = Track.insert()
    track:setName(instrName)
    Instrument.init(track)
    if instrName then
        local instrument = track:addFx(instrName)
        if not instrument then
            track:remove()
            return nil
        end

        track:iconize()

        local res = instrument:getOutputs()
        if _.size(res) > 0 then
            res[1]:createConnection()
        end
    end

    return track
end

function Instrument.init(track)
    track:setType(Track.typeMap.instrument)
    track:setVisibility(false,false)
    track:setColor(colors.instrument)
    track:setValue('toParent', 0)
end

function Instrument.bang()

    rea.transaction('add instrument(s)', function()

        local input = rea.prompt('instrument')

        if not input then return false end


        local zones = _.map(input:split('|'), function(zone)
            local layers = _.map(zone:split('&'), function(layer)
                local splits = layer:trim():split(' ')
                local track = Track.insert()
                track:setColor(colors.instrument)
                local name = splits[1]

                track:addFx(name)
                local inst = track:getInstrument()
                if inst then
                    track:setName(splits[2] or name)
                    track:setType('instrument')
                    track:iconize()
                    track:getInstrument():open()
                    return track
                else
                    track:remove()
                    reaper.ShowMessageBox('could not find instrument named:' .. name, 'error', 0)
                    return nil
                end
            end)

            return #layers > 0 and layers or nil
        end)

        local numZones = #zones

        if numZones > 0 then
            if numZones > 1 or #zones[1] > 1 then
                local rack = DrumRack.init(Track.insert():setName(input))
                rack:setSplitMode()

                range = math.floor(128 / numZones)
                local low = 0
                local hi = range
                local i = 1
                _.forEach(zones, function(zone)
                    local pad = rack.pads[i]
                    rack:getMapper():setParamForPad(pad, 1, low)
                    rack:getMapper():setParamForPad(pad, 2, hi)
                    low = low + range
                    hi = hi + range
                    i = i + 1
                    _.forEach(zone, function(layer)
                        pad:addTrack(layer)
                    end)
                end)

            end
        else  -- no instruments found
            return false
        end

    end)

end

return Instrument