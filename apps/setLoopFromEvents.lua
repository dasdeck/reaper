
function setLoopFromEvents()
    local editor = reaper.MIDIEditor_GetActive()
    if not editor then
        reaper.ShowConsoleMsg("can only use this in a midi editor")
        return
    end

    local take =  reaper.MIDIEditor_GetTake(editor)
    if not take then
        reaper.ShowConsoleMsg("no take selected")
        return
    end

    local retval, numNotes = reaper.MIDI_CountEvts(take)


    local maxPos = 0
    for noteIndex=0, numNotes-1 do
        local retval, selected, mute, pos = reaper.MIDI_GetNote(take, noteIndex)
        if selected then
            maxPos = math.max(maxPos, pos)
        end
    end

  --find min pos

    local minPos = maxPos
    for noteIndex=0, numNotes-1 do
        local retval, selected, mute, pos = reaper.MIDI_GetNote(take, noteIndex)
        if selected then
            minPos = math.min(minPos, pos)
        end
    end

    minPos = reaper.MIDI_GetProjTimeFromPPQPos(take,minPos)
    maxPos = reaper.MIDI_GetProjTimeFromPPQPos(take,maxPos)
    startPos = 0
    endPos = 0
    reaper.GetSet_LoopTimeRange(1, 1, minPos, maxPos, true)
end

setLoopFromEvents()


