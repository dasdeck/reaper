local Track = require 'Track'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local paths = require 'paths'
local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'

local Instrument = class()
function Instrument.createInstrument(instrName)

    local track

    if instrName then
        local instrument
        local template = paths.imageDir:findFile(instrName .. '.RTrackTemplate')
        if template then
            local state = require 'TrackState'
            reaper.OnPauseButton()
            track = _.first(state.fromTemplate(readFile(template)))
            reaper.OnPlayButton()
            assert(track)
            instrument = track:getInstrument()
            assert(instrument)
        else
            track = Track.insert()
            instrument = track:addFx(instrName)
            if not instrument then
                track:remove()
                return nil
            end
        end
        track:setName(instrName)
        Instrument.init(track)

        track:getTrackTool(true):setPreset(instrName)

        local res = instrument:getOutputs()
        if _.size(res) > 0 then
            res[1]:createConnection()
            if res[1]:getTrack() then
                -- rea.log('open first')
                res[1]:getTrack():setMeta('expanded', true)
            end
        end
    end

    return track
end

function Instrument.getAllInstruments()
    return _.filter(Track.getAllTracks(), function(track)
        return track:getType() == Track.typeMap.instrument
    end)
end

function Instrument.getMenu(callback, menu, checked)

    checked = checked or function() return false end

    if type(checked) ~= 'function' then
        local track = checked
        checked = function(instrument)
            return instrument == track or track:receivesFrom(instrument)
        end
    end

    callback = callback or function()end
    menu = menu or Menu:create()


    _.forEach(Instrument.getAllInstruments(), function(instrument)
        local outputs = instrument:getInstrument() and _.filter(instrument:getInstrument():getOutputs(), function(out)
            return out:getConnection()
        end) or {}

        menu:addItem(instrument:getName(), {
            checked = checked(instrument),
            children = _.size(outputs) > 1 and _.map(outputs, function(output)
                local track = output.getConnection():getTargetTrack()
                return {
                    name = output.name,
                    checked = checked(track),
                    callback = function()
                        callback(track)
                    end
                }
            end) or nil,
            callback = function()
                callback(_.first(outputs).getConnection():getTargetTrack())
            end
        })
    end)

    return menu
end

function Instrument.init(track)
    track:setType(Track.typeMap.instrument)
    track:setVisibility(true,true)
    track:setColor(colors.instrument)
    track:setValue('input', 6112)
    track:iconize()
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