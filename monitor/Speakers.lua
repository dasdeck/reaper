package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."lua/?.lua;".. package.path

local Component = require 'Component'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local JSON = require 'json'
local rea = require 'rea'

local sets = JSON.decode(readFile(__dirname(debug.getinfo(1,'S'))..'/'..'monitors.json'))

local Speakers = class(ButtonList)


function getPreset()
  local master = reaper.GetMasterTrack()
  local isone_index = rea.getFxByName(master, "Isone", true)
  local isone_tSizeI = rea.getParamByName(master, isone_index, "Spk size")

  local value = reaper.TrackFX_GetParam(master, isone_index, isone_tSizeI)

  local fir_fx = rea.getFxByName(master, "FIR", true)
  local _,preset = reaper.TrackFX_GetPreset(master, fir_fx, 1)
  return value, preset
end


function Speakers:create()
    local proto = ButtonList:create(sets, 1)
    setmetatable(proto, Speakers)
    return proto
end

function Speakers:isSelected(i)
  local value, preset = getPreset()
  local set = sets[i]
  value = tonumber(string.format("%.2f", value * 9 + 1))
  return set['size'] == value and set['preset'] == preset
end

function Speakers:onItemClick(i, preset)

  local master = reaper.GetMasterTrack()
  local isone_index = rea.getFxByName(master, "Isone", true)
  local isone_tSizeI = rea.getParamByName(master, isone_index, "Spk size")
  local size = preset['size']

  reaper.TrackFX_SetParam(master, isone_index, isone_tSizeI, (preset['size']-1) / 9)

  local fir_fx = rea.getFxByName(master, "FIR", true)
  reaper.TrackFX_SetPreset(master, fir_fx, preset['preset'])
end

return Speakers