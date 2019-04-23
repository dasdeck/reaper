
local MidiEditor = class()

function MidiEditor.setDrumMode()
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40043, 0, 0)
end

function MidiEditor.setPianoMode()
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40042, 0, 0)
end

function MidiEditor.zoomContent()
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40466, 0, 0)
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), reaper.NamedCommandLookup('_FNG_ME_SHOW_USED_CC_LANES'), 0, 0)
end

return MidiEditor