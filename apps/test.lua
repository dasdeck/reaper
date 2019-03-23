
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Project = require 'Project'
local DrumRack = require 'DrumRack'
local Image = require 'Image'
local Track = require 'Track'
local Window = require 'Window'
local Watcher = require 'Watcher'
local rea = require 'rea'
local _ = require '_'
local Project = require 'Project'
local Track = require 'Track'
-- local p = '/Users/jms/Library/Application Support/REAPER/Data/track_icons/amp.png'

-- Window.openComponent(Image:create(p, 'fit'), {
--   name = 'test',
--   w = 600,
--   h = 300,s
--   dock = 1}
-- )


Watcher:create(function () return reaper.GetProjectStateChangeCount(0)end)
:onChange(function()
  rea.log('change')
end)

-- local tracks = Track.getAllTracks()--:map(function(t) return t.track end)

function loadProject()

  mainProj = Project.getCurrentProject()

  local command = 41929

  reaper.Main_OnCommand(command, 0)

  proj = _.last(Project.getAllProjects())

  local track = Track.insert()

  DrumRack.init(track)

  --mainProj:focus()

end

--loadProject()

--reaper.SetProjExtState(0, 'D3CK', '', 0)


local function defer()

  Watcher.deferAll()
  Track.deferAll()

  -- rea.logOnly(collectgarbage('count'))
  -- collectgarbage()

  rea.logOnly(Project.getStates())

  -- track = Track.getSelectedTrack()

  -- local fx = track:getFx('DrumRack')

  -- pad = fx:getParam(0)
  -- key = fx:getParam(1)
  -- vals = {}
  -- for i=1, 16 do
  --   fx:setParam(0, i)
  --   local p = fx:getParam(1)
  --   table.insert(vals, p)
  -- end
  -- fx:setParam(0,pad)


  -- local noop = function()end
  -- local profile = function()rea.profile(noop, 1)end
  -- local track = reaper.GetTrack(0,0)
  -- local guid = function()reaper.TrackFX_GetFXGUID(track, 0) end
  -- local param = function()reaper.TrackFX_GetParam(track, 0,0) end
  -- local state = function()reaper.GetTrackStateChunk(track, '', true) end
  -- local guidT = function()reaper.GetTrackGUID(track) end

  -- local loop = 100
  -- _ref = rea.profile(noop, loop).time
  -- a = rea.profile(guid, loop).time
  -- b = rea.profile(param, loop).time
  -- c = rea.profile(state, loop).time
  -- d = rea.profile(guidT, loop).time

  reaper.defer(defer)

end


defer()


