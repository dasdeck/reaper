package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local _ = require '_'
local MediaItem = require 'MediaItem'


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

      _.forEach(MediaItem.getAllItems(), function(item)
        item:setSelected()
      end)

      reaper.Main_OnCommand(40061, 0)

    _.forEach(MediaItem.getAllItems(), function(item)
      if not item:isSelected() then
        item:remove()
      end
    end)

    local clipLength = _.first(MediaItem.getSelectedItems()):getLength()
    strech = clipLength / targetLength

      _.forEach(MediaItem.getSelectedItems(), function(item)

          item:setPos(0)
          item:setLength(targetLength)
          item:getActiveTake():setPlayRate(strech)

      end)

      loopstart = 0


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
