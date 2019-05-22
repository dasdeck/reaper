
function findTempo(measures, oneMeasure, length, originalTempo)
    local measuresNow = length / oneMeasure
    local factor = measuresNow / measures
    local tempo = originalTempo / factor + 0.5
    tempo = math.floor(tempo)
    return tempo
end

function looper()
  local loopstart, loopend = reaper.GetSet_LoopTimeRange(false, false, 0 , 0, false)
  local length = loopend - loopstart

  if length <= 0 then
    reaper.ShowConsoleMsg("this tool needs a loop selection")
    return
  end

  if reaper.CountSelectedTracks(0) ~= 1 or reaper.CountSelectedMediaItems(0) ~= 1 then
    reaper.ShowConsoleMsg("please select one media item and one track")
    return
  end
  

  local clip = reaper.GetSelectedMediaItem(0,0)
  local track = reaper.GetSelectedTrack(0,0)
  local trash = clip
  local originalTempo = reaper.Master_GetTempo()
  local oneMeasure = 60 / originalTempo * 4

  local suggestions = ""
  local suggestedTempo = 0
  local measures = 1
  while suggestedTempo < 200 do
    suggestedTempo = findTempo(measures, oneMeasure, length, originalTempo)
    if suggestedTempo > 40 then
      suggestions = suggestions .. "(" .. tostring(measures) .. " measures@ " .. tostring(suggestedTempo) .. " bpm\n"
    end
    measures = measures * 2
  end

  local vals = ""

  reaper.ShowConsoleMsg(suggestions)

  local suc, res = reaper.GetUserInputs("input", 1, "number of measures", vals, 20)

  if suc then

      measures = math.floor(res)

      local tempo = findTempo(measures, oneMeasure, length, originalTempo)

      local targetLength = oneMeasure * measures

      clip = reaper.SplitMediaItem(trash,loopstart)
      if clip and clip ~= trash then
        reaper.DeleteTrackMediaItem(track,trash)
      end

      trash = reaper.SplitMediaItem(clip,loopend)
      reaper.DeleteTrackMediaItem(track,trash)

      isFirstLoop = reaper.CountTempoTimeSigMarkers(0) == 0

      if isFirstLoop then
          reaper.SetMediaItemInfo_Value(clip,"D_POSITION",0)
      end

      clipLength = reaper.GetMediaItemInfo_Value(clip,"D_LENGTH")
      strech = clipLength / targetLength
      reaper.SetMediaItemInfo_Value(clip,"D_LENGTH",targetLength)
      take = reaper.GetActiveTake(clip)
      reaper.SetMediaItemTakeInfo_Value(take,"D_PLAYRATE",strech)

      --reaper.SetCurrentBPM(0, tempo , True)
      --set loop start to zero if this is the first loop
      if isFirstLoop then
          loopstart = 0
      end

      reaper.AddTempoTimeSigMarker(0, loopstart, tempo, 4, 4, 1)


      reaper.ShowConsoleMsg( "\ntempo:\n")
      reaper.ShowConsoleMsg( tempo)
      reaper.ShowConsoleMsg( type(tempo))

      reaper.ShowConsoleMsg( "\nmeasures\n")
      reaper.ShowConsoleMsg( measures)


      local oneMeasure = 60 / tempo * 4
      local newLength = oneMeasure * measures

      reaper.ShowConsoleMsg( "newLength")
      reaper.ShowConsoleMsg( newLength)

      reaper.GetSet_LoopTimeRange(true, true, loopstart , loopstart + newLength, false)
      reaper.GetSetRepeat(1);

      reaper.Main_OnCommand(40362, 0) --glue to improve handlability
    end
end
looper()
