local State = require 'State'

local _ = require '_'
local colors = require 'colors'

local TrackListFilters = {
    onChange = function() end
}

local options = {
    {
        color = colors.instrument,
        args = 'i',
        key = 'inst'
    },
    {
        color = colors.aux,
        args = 'a',
        key = 'aux'
    },
    {
        color = colors.la,
        args = 'l',
        key = 'la'
    },
    {
        color = colors.fx,
        args = 'b',
        key = 'bus'
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
        local state = not option.getToggleState()
        if not mouse:isCommandKeyDown() then
            _.forEach(options, function(opt)
                State.global.set('tracklist_filter_' .. opt.key, '')
            end)
        end
        State.global.set('tracklist_filter_' .. option.key, tostring(state))
        TrackListFilters.onChange()
    end
    TrackListFilters[option.key] = option
end)

TrackListFilters.options = options

return TrackListFilters