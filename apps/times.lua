package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
local rea = require 'rea'

local tempo = reaper.Master_GetTempo()

local msPerMeasure = 60 / tempo * 1000 * 4

local times = ''

for i=0,8 do
  local div = 2^i
  times = times .. tostring(div) .. ' -> ' .. tostring(msPerMeasure / div):gsub('[.]', ' : ') .. '\n'
end

rea.logOnly(times)
