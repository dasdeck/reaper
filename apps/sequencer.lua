package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local KeySequencer = require 'KeySequencer'
local MediaItem = require 'MediaItem'

local rea = require 'rea'
local s_ = require '_'

local seq = KeySequencer:create()
local app = WindowApp:create('sequencer', seq)
app:start(
{
  profile = false
})
  
