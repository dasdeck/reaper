local Plugin = require 'Plugin'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Track = require 'Track'
local rea = require 'rea'

local ms = Track.master:getFx('ms', false, true)

local param = 0
local labels = {
  {0, args = 'L/R'},
  {1, args = 'M'},
  {2, args = 'S'},
  {3, args = 'L'},
  {4, args = 'R'}
}

local MS = class(ButtonList)

function MS:isSelected(i, preset)
    local selected = preset[1]
    return fequal(selected, ms:getParam(param))
end

function MS:onItemClick(i, preset)
    rea.transaction('set monitoring channel', function()
        local selected = preset[1]
        ms:setParam(param, selected)
    end)
end

function MS:create()
    local obj = ButtonList:create(labels, true)
    setmetatable(obj, MS)
    return obj
end

return MS