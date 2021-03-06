local State = require 'State'
local Track = require 'Track'
local PluginListApp = require 'PluginListApp'
local Instrument = require 'Instrument'

local Menu = require 'Menu'
local Bus = require 'Bus'
local AuxUI = require 'AuxUI'
local _ = require '_'
local colors = require 'colors'
local rea = require 'rea'

local TrackListFilters = {
    onChange = function() end
}

local options = {

    {
        color = colors.midi,
        args = 'm',
        key = 'midi'
    },
    {
        color = colors.instrument,
        args = 'i',
        key = 'inst',
        onDblClick = function()
            local parent = Track.getSelectedTrack()

            PluginListApp.pick(PluginListApp.cats.instruments,function(res)
                rea.transaction('add instrument', function()
                    local track = Instrument.createInstrument(res)
                    if track then

                        if parent and parent:isFolder() then
                            track:setParent(parent)
                        end
                        -- track = track:createMidiSlave()
                        track:getTrackTool(true)
                        track:setSelected(1)
                        track:setArmed(1)
                        track:focus()
                        if track:getInstrument() and not track:getInstrument().track:getFx('DrumRack') then
                            track:getInstrument():initSettings()
                            track:getInstrument():open(true)
                        else
                            track:getTrackTool(true):setParam(3, 0)
                        end
                    else
                        -- rea.log('notrack')
                        return false
                    end
                end)
            end)
        end
    },
    {
        color = colors.aux,
        args = 'a',
        key = 'aux',
        onDblClick = function()
            AuxUI.pickAndCreate()
        end
    },
    -- {
    --     color = colors.la,
    --     args = 'l',
    --     key = 'la'
    -- },
    {
        color = colors.bus,
        args = 'b',
        key = 'bus',
        onRightClick = function()
            Bus.getCreateMenu():show()
        end
    },
    {
        args = '*',
        key = 'all'
    }
}

_.forEach(options, function(option)
    option.getToggleState = function(self)
        return State.global.get('tracklist_filter_' .. option.key, false) == 'true'
    end

    option.onClick = function(self, mouse)
        local state = true --not option.getToggleState()
        if option.onRightClick and mouse:wasRightButtonDown() then
            option.onRightClick()
        else
        if not mouse:isCommandKeyDown() then
            _.forEach(options, function(opt)
                State.global.set('tracklist_filter_' .. opt.key, '')
            end)
        end
            State.global.set('tracklist_filter_' .. option.key, tostring(state))
            TrackListFilters.onChange()
        end
    end
    TrackListFilters[option.key] = option
end)

TrackListFilters.options = options

return TrackListFilters