local ButtonList = require 'ButtonList'
local TrackListComp = require 'TrackListComp'
local Project = require 'Project'
local Track = require 'Track'
local _ = require '_'

local TrackList = class(ButtonList)

function TrackList:create()

    local self = ButtonList:create({})
    setmetatable(self, TrackList)

    Project.watch.project:onChange(function(tracks)
        self:updateList()
    end)

    self:updateList()

    return self

end

function TrackList:getData()
    return _.map(Track.getAllTracks(), function(track)
        return {
            proto = TrackListComp,
            args = track,
            size = 40
        }
    end)
end

return TrackList