package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local _ = require '_'
local rea = require 'rea'

local MidiEditor = require 'MidiEditor'
local Track = require 'Track'
local WindowApp = require 'WindowApp'
local Mouse = require 'Mouse'
local MediaItem = require 'MediaItem'


local track = Track.getSelectedTrack()

local item = _.first(MediaItem.getSelectedItems())
local customNotes = item and _.some(item:getActiveTake():getNotes(), function(note)
    return note.endppqpos - note.startppqpos ~= 1
end)


local useSequencer = not customNotes and track:getInstrument() and track:getInstrument().track:getFx('DrumRack') ~= nil

local alter = Mouse.capture():isAltKeyDown()


if (useSequencer and not alter) or alter then
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
