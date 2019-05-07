package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local Sequencer = require 'Sequencer'
local MediaItem = require 'MediaItem'

local rea = require 'rea'
local _ = require '_'

local seq = Sequencer:create()
local app = WindowApp:create('sequencer', seq)
app:start(
{
  profile = false
})

