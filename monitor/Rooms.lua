local PartialPresets = require 'PartialPresets'
local Plugin = require 'Plugin'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Track = require 'Track'
local JSON = require 'json'

local isone = Track.master:getFx('Isone', false, true)

local config = {
  plugin = isone,
  params = {
      'Room sim',
      'Room ER',
      'Room T60',
      'Room dif',
      'Room siz'
  }
}

local rooms = JSON.decode(readFile(__dirname(debug.getinfo(1,'S'))..'/'..'rooms.json'))

local Rooms = class(ButtonList)

function Rooms:isSelected(i, preset)
    return self.presets:matches(preset.params)
end

function Rooms:isDisabled()
    return self.children[1]:getToggleState()
end

function Rooms:onItemClick(i, preset)
    self.presets:load(preset.params)
end

function Rooms:create(...)
    local obj = ButtonList:create(rooms, 1)
    setmetatable(obj, Rooms)
    obj.presets = PartialPresets:create(config)
    return obj
end


return Rooms