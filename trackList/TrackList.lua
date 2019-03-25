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
local TrackListFilter =  require 'TrackListFilter'
local Instrument = require 'Instrument'

local TrackList = class(ButtonList)

function TrackList:create(...)

    local self = ButtonList:create({}, nil, nil, ...)
    setmetatable(self, TrackList)

    local updater = function(tracks)
        self:updateList()
    end

    Project.watch.project:onChange(updater)

    TrackListFilter.onChange = updater

    self:updateList()

    return self

end

function TrackList:getData()

    -- rea.log('tracklist:update')
    local tracks = {
        {
            proto = function()
                return ButtonList:create(TrackListFilter.options, true)
            end,
            size = 20
        }
    }

     _.forEach(Track.getAllTracks(), function(track)

        local opt = {
            proto = TrackListComp,
            args = track,
            size = 20
        }

        if TrackListFilter.inst.getToggleState() and (track:getInstrument() or track:getFx('DrumRack')) then
            table.insert(tracks, opt)
        elseif TrackListFilter.aux.getToggleState() then
            table.insert(tracks, opt)
        end
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
                    reaper.Main_OnCommand(command, 5)
                end)
                menu:show()
            else
                Instrument.bang()
            end
        end
    })

    return tracks
end

return TrackList