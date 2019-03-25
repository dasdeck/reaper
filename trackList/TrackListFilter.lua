local _ = require '_'
local State = require 'State'

local TrackListFilters = {
    onChange = function() end
}

local options = {
    {
        args = 'inst',
        key = 'inst'
    },
    {
        args = 'aux',
        key = 'aux'
    }
}

_.forEach(options, function(option)
    option.getToggleState = function(self)
        return State.global.get('tracklist_filter_' .. option.key, false) == 'true'
    end
    option.onClick = function(self)
        local state = not option.getToggleState()
        State.global.set('tracklist_filter_' .. option.key, tostring(state))
        TrackListFilters.onChange()
    end
    TrackListFilters[option.key] = option
end)

TrackListFilters.options = options

return TrackListFilters