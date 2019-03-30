
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

function test()
  local context = {reaper.get_action_context()}
  
  
  rea.logPin('context', context)
  reaper.defer(test)
end
reaper.defer(test)
