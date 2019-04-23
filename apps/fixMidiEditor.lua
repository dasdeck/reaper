package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local _ = require '_'

local MidiEditor = require 'MidiEditor'
local Track = require 'Track'

if Track.getSelectedTrack() and _.some(Track.getSelectedTrack():getNoteNames(), function(name) return name:trim():len() > 0 end) then
    MidiEditor.setDrumMode()
else
    MidiEditor.setPianoMode()
end

MidiEditor.zoomContent()
