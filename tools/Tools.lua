

local Track = require 'Track'
local rea = require 'Reaper'
local DrumRack = require 'DrumRack'
local RandomSound = require 'RandomSound'
local Menu = require 'Menu'
local Mouse = require 'Mouse'
local Instrument = require 'Instrument'
local _ = require '_'

return {
    {
        args = '+inst',
        onClick = function()
            Instrument.bang()
        end
    },
    {
        args = '+drm',
        onClick = function(self, mouse)

            local addRack = function()
                local name = rea.prompt('name')
                if name then
                    local track = Track.insert()
                    track:setName(name:len() and name or 'drumrack')
                    return DrumRack.init(track):getTrack():choose()
                end
            end

            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('new drumrack', addRack, 'add drum rack')
                menu:addItem('from selected tracks (layers)', function()
                    local tracks = Track.getSelectedTracks()
                    local rack = addRack()
                    if rack then
                        _.forEach(tracks, function(track)
                            rack.pads[1]:addTrack(track)
                        end)
                    end
                end, 'add drum rack')
                menu:addItem('from selected tracks (pads)', addRack, 'add drum rack')
                menu:show()
            else
                rea.transaction('add drum rack',addRack)
            end
        end
    },
    {
        args = '?',
        proto = RandomSound.Button
    },
}