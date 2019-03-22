package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('trackList')

local TrackList = require 'TrackList'
local Window = require 'Window'

Window.openComponent(TrackList:create(), {
name = 'tracklist',
w = 200,
h = 600,
dock = 1}
)
