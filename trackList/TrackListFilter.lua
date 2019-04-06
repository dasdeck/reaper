local State = require 'State'
local Track = require 'Track'
local PluginListApp = require 'PluginListApp'
local Instrument = require 'Instrument'

local Menu = require 'Menu'
local Bus = require 'Bus'
local Aux = require 'Aux'
local AuxUI = require 'AuxUI'
local _ = require '_'
local colors = require 'colors'
local rea = require 'rea'

local TrackListFilters = {
    onChange = function() end
}

local options = {
    {
        color = colors.instrument,
        args = 'i',
        key = 'inst',
        onDblClick = function()
            PluginListApp.pick(PluginListApp.cats.instruments,function(res)
                -- rea.log(res)
                local track = Instrument.createInstrument(res)
                if track then
                    track:setSelected(1)
                    track:setArmed(1)
                    track:focus()
                    track:getInstrument():open(true)
                end
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
    {
        color = colors.la,
        args = 'l',
        key = 'la'
    },
    {
        color = colors.bus,
        args = 'b',
        key = 'bus',
        onRightClick = function()
            local menu = Menu:create()

            local allTracks = Track.getAllTracks()
            if Bus.hasTopLevelTracks(allTracks) then
                menu:addItem('create bus from all', function()
                    local bus = Bus.fromTracks(allTracks, true)
                    if bus then bus:focus() end
                end, 'bus all')
            end
            local selectedTracks = Track.getSelectedTracks()
            if Bus.hasTopLevelTracks(selectedTracks) then
                menu:addItem('create bus from selection', function()
                    local bus = Bus.fromTracks(selectedTracks, true)
                    if bus then bus:focus() end
                end, 'bus selection')
            end
            menu:addItem('create empty bus', function()
                Bus.createBus():focus()
            end, 'create empty bus')
            menu:show()

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