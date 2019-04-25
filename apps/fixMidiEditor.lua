package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local _ = require '_'

local MidiEditor = require 'MidiEditor'
local Track = require 'Track'
local WindowApp = require 'WindowApp'
local Mouse = require 'Mouse'

local track = Track.getSelectedTrack()

if not Mouse.capture():isAltKeyDown() and track:getInstrument() and track:getInstrument().track:getFx('DrumRack') then
    WindowApp:create('sequencer'):show()
else

    reaper.Main_OnCommand(40153,0)

    if track and _.some(track:getNoteNames(), function(name) return name:trim():len() > 0 end) then
        MidiEditor.setDrumMode()
    else
        MidiEditor.setPianoMode()
    end

    MidiEditor.zoomContent()

end
