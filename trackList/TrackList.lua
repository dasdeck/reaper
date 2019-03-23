local ButtonList = require 'ButtonList'
local TrackListComp = require 'TrackListComp'
local Component = require 'Component'
local Project = require 'Project'
local Menu = require 'Menu'
local Mem = require 'Mem'
local Track = require 'Track'
local _ = require '_'
local rea = require 'rea'
local Builder = require 'Builder'
local paths = require 'paths'

local TrackList = class(ButtonList)
local Instrument = require 'Instrument'

function TrackList:create()

    local self = ButtonList:create({})
    setmetatable(self, TrackList)

    Project.watch.project:onChange(function(tracks)
        self:updateList()
    end)

    self:updateList()

    return self

end

function TrackList:paintOverChildren(g)

    g:setColor(1,1,1,1)
    g:drawText(tostring(Mem.read('pluginlist', 0)), 0, 0, self.w, self.h)

end

function TrackList:onClick(mouse)
    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem('dock', function()
            gfx.dock(1)
        end)
        menu:addItem('build', function()

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
        onClick = function(s, mouse)

            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('+instrument', function()
                    command = reaper.AddRemoveReaScript(true, 0, paths.binDir:childFile('pluginList.lua').path, true)
                    -- command = reaper.NamedCommandLookup('pluginList')
                    reaper.Main_OnCommand(command, 5)
                end)
                menu:show()
            else
                Instrument.bang()
            end
            -- rea.transaction('add track', function()
            --     Track.insert()
            -- end)
        end
    })
    return tracks
end

return TrackList