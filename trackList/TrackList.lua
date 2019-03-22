local ButtonList = require 'ButtonList'
local TrackListComp = require 'TrackListComp'
local Component = require 'Component'
local Project = require 'Project'
local Menu = require 'Menu'
local Track = require 'Track'
local _ = require '_'
local rea = require 'Reaper'

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

function TrackList:onClick(mouse)
    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem('dock', function()
            gfx.dock(1)
        end)
        menu:show()
    end
end

function TrackList:getData()
    local tracks =  _.map(Track.getAllTracks(), function(track)
        return {
            proto = TrackListComp,
            args = track,
            size = 20
        }
    end)

    table.insert(tracks, {
        proto = TextButton,
        args = '+',
        size = 20,
        onClick = function()
            rea.transaction('add track', function()
                Track.insert()
            end)
        end
    })
    return tracks
end

return TrackList