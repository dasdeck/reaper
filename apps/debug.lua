
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('drumRack')

local Project = require 'Project'
local DrumRack = require 'DrumRack'
local Image = require 'Image'
local Label = require 'Label'
local Track = require 'Track'
local Window = require 'Window'
local Watcher = require 'Watcher'
local rea = require 'rea'
local _ = require '_'
local Project = require 'Project'
local Track = require 'Track'
local paths = require 'paths'
local WindowApp = require 'WindowApp'

local label = Label:create('debug', 0,0, 600, 300)
label.content.just = 0

label.getText = function()
  return dump({
    dirty = reaper.IsProjectDirty(0),
    redo = reaper.Undo_CanRedo2(0),
    undo = reaper.Undo_CanUndo2(0),
    state = Project.getState()
  })
end


WindowApp:create('debug', label):start()
Window.currentWindow.onDefer = function(self)
  self.repaint = true
end
