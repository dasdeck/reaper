

local Track = require 'Track'
local rea = require 'Reaper'
local DrumRackUI = require 'DrumRackUI'
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
            DrumRackUI.drumRackButton(mouse)
        end
    },
    {
        args = '?',
        proto = RandomSound.Button
    },
}