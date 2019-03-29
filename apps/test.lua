
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
local paths = require 'paths'

local track = Track:getSelectedTrack()

if track then
  local state = track:getState(true)

  rea.log(state)
  local newState = paths.binDir:childFile('state'):getContent()
  track:setState(newState)
  rea.log(newState)

  local state = track:getState(true)

  rea.log(state)
end
