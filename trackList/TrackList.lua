local ButtonList = require 'ButtonList'
local TrackListComp = require 'TrackListComp'
local Component = require 'Component'
local Project = require 'Project'
local Menu = require 'Menu'
local Mem = require 'Mem'
local Track = require 'Track'
local _ = require '_'
local rea = require 'rea'
local colors = require 'colors'
local Builder = require 'Builder'
local paths = require 'paths'
local TrackListFilter =  require 'TrackListFilter'
local Instrument = require 'Instrument'

local TrackList = class(Component)

function TrackList:create(...)

    local self = Component:create( ...)
    setmetatable(self, TrackList)

    self.tracklist = self:addChildComponent(ButtonList:create())
    self.tracklist.getData = function()

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
                proto = function()
                    return TrackListComp:create(track, TrackListFilter.all.getToggleState())
                end,
                size = true
            }

            local type = track:getType()

            if TrackListFilter.all.getToggleState() then
                table.insert(tracks, opt)
            elseif TrackListFilter.inst.getToggleState() and track:getType() == Track.typeMap.instrument then
                if not track:getManager() then
                    table.insert(tracks, opt)
                end
            elseif TrackListFilter[type] and TrackListFilter[type].getToggleState()then
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

    local updater = function(tracks)
        -- rea.logCount('updateTrackListisManager')
        self.tracklist:updateList()
    end

    self.watchers:watch(Project.watch.project, updater)

    TrackListFilter.onChange = updater

    self.tracklist:updateList()

    return self

end

function TrackList:onClick(mouse)
    if mouse:wasRightButtonDown() then
        local menu = Menu:create()
        menu:addItem('autocolor', function()
            _.forEach(Track.getAllTracks(), function(track)
                track:setColor(colors[track:getType()] or colors.default)
            end)
        end, 'autocolor')
        menu:addItem('cleanup mixer', function()
            _.forEach(Track.getAllTracks(), function(track)
                local tcp, mcp = track:getVisibility()
                if not tcp then
                    local pk = track:getPeakHoldInfo()
                    track:setVisibility(tcp, pk > -1.5)
                end
            end)
        end, 'cleanup mixer')
        menu:show()
    else
        Track.setSelectedTracks({})
    end
end


return TrackList