local ButtonList = require 'ButtonList'
local TrackListComp = require 'TrackListComp'
local Component = require 'Component'
local Project = require 'Project'
local Track = require 'Track'
local _ = require '_'
local rea = require 'Reaper'

local TrackList = class(ButtonList)

function TrackList:create()

    local self = ButtonList:create({})
    setmetatable(self, TrackList)

    Project.watch.project:onChange(function(tracks)
        rea.log('update')
        self:updateList()
    end)

    self:updateList()

    return self

end

function TrackList:getData()
    local tracks =  _.map(Track.getAllTracks(), function(track)
        return {
            proto = TrackListComp,
            args = track,
            size = 40
        }
    end)

    table.insert(tracks, {
        proto = TextButton,
        args = '+',
        size = 30,
        onClick = function()
            rea.transaction('add track', function()
                Track.insert()
            end)
        end
    })
    return tracks
end

-- function TrackList:evaluate()
--     Component.evaluate(self)
--     if gfx.getchar('del') > 0 then
--         rea.log('del')
--     end
-- end

return TrackList