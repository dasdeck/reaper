package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path
require 'boot'
local Builder = require 'Builder'
local paths = require 'paths'
local rea = require 'rea'
local _ = require '_'

_.forEach(paths.scriptDir:childDir('apps'):getFiles(), function(file)
    if not file:endsWith('build.lua') then
        local res = Builder.build(file)
        paths.distDir:childFile(_.last(file:split(package.config:sub(1,1)))):setContent(res)
    end
end)
