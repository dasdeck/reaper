package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'

local WindowApp = require 'WindowApp'
local Sequencer = require 'Sequencer'
local MediaItem = require 'MediaItem'

local rea = require 'rea'


local app = WindowApp:create('sequencer', Sequencer:create())
app.onAfterDefer = function()

    local all = MediaItem.getAllItems()

    rea.logPin('seq', {
        selected = reaper.GetSelectedMediaItem(0,0),
        all = all
    })
end

app:start(
{
profile = false
})

