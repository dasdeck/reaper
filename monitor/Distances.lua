local Plugin = require 'Plugin'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Track = require 'Track'

local isone = Track.master:getFx('Isone', false, true)

local distName = 'Spk dist'

local distances = {
  {3.0, 'mid', preset = '180cm', args = '300cm'},
  {1.8, 'mid', preset = '180cm', args = '180cm'},
  {0.75, 'near', preset = '75cm', args = '75cm'}
}

local Distances = class(ButtonList)

function Distances:isSelected(i, preset)
    local selected = preset[1]
    return fequal(selected / 3, isone:getParam(distName), 2)
end

function Distances:onItemClick(i, preset)
    local selected = preset[1]
    isone:setParam(distName, selected / 3)
end

function Distances:create()
    local obj = ButtonList:create(distances, 1)
    setmetatable(obj, Distances)
    return obj
end

return Distances