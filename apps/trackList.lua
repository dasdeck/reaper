package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('trackList')
addScope('drumRack')
addScope('pluginList')



local TrackList = require 'TrackList'
local WindowApp = require 'WindowApp'


WindowApp:create('tracklist', TrackList:create(0,0, 200, 600)):start({
profile = false})
