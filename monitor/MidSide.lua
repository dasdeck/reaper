local Plugin = require 'Plugin'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Track = require 'Track'

local ms = Track.master:getFx('MSSolo', false, true)

local param = 0
local labels = {
  {0, args = 'L/R'},
  {1, args = 'M'},
  {2, args = 'S'}
}

local MS = class(ButtonList)

function MS:isSelected(i, preset)
    local selected = preset[1]
    return fequal(selected, ms:getParam(param))
end

function MS:onItemClick(i, preset)
    local selected = preset[1]
    ms:setParam(param, selected)
end

function MS:create()
    local obj = ButtonList:create(labels, true)
    setmetatable(obj, MS)
    return obj
end

return MS