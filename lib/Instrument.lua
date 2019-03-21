local Instrument = class()
local Track = require 'Track'
local DrumRack = require 'DrumRack'
local rea = require 'Reaper'
local _ = require '_'

function Instrument.bang()

    rea.transaction('add instrument(s)', function()

        local input = rea.prompt('instrument')

        if not input then return false end

        local zones = _.map(input:split('|'), function(zone)
            local layers = _.map(zone:split('&'), function(layer)
                local splits = layer:trim():split(' ')
                local track = Track.insert()
                local name = splits[1]

                track:getFx(name, true)
                local inst = track:getInstrument()
                if inst then
                    track:setName(splits[2] or name)
                    track:setType('instrument')
                    track:choose()
                    icon = rea.findIcon(name)
                    if icon then track:setIcon(icon) end
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
                local rack = DrumRack.init(Track.insert())
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