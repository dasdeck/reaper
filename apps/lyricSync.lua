package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."../?.lua;".. package.path


require 'Util'
local rea = require 'rea'
local TextButton = require 'TextButton'


local project = 40021

reaper.Main_OnCommand(project,0)

local notes = reaper.GetSetProjectNotes(0, false, '')

parts = notes:split('lyrics:')

local lyrics = parts[2]
rea.setLyrics(lyrics)
