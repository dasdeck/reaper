package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/lua/?.lua;".. package.path
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/?.lua;".. package.path

local Window = require 'Window'

local Component = require 'Component'
local Track = require 'Track'
local Speakers = require 'Speakers'
local Distances = require 'Distances'
local Rooms = require 'Rooms'
local MS = require 'MidSide'
local TextButton = require 'TextButton'
local rea = require 'rea'
local JSON = require 'json'

local MonitorPresets = class(Component)

function MonitorPresets:create(...)
  local self = Component:create(...)

  setmetatable(self, MonitorPresets)

  self.analyser = self:addChildComponent(TextButton:create('fft'))
  self.analyser.onButtonClick = function()
    Track.master:getFx('MAnalyzer',false, true):toggleOpen()
  end
  self.analyser.getToggleState = function()
    return Track.master:getFx('MAnalyzer',false, true):isOpen()
  end
  self.spkers = self:addChildComponent(Speakers:create())
  self.distances = self:addChildComponent(Distances:create())
  self.rooms = self:addChildComponent(Rooms:create())

  self.ms = self:addChildComponent(MS:create())

  return self

end

function MonitorPresets:resized()

  local h = 20
  self.analyser:setBounds(0,0, self.w, h)

  self.spkers:setBounds(0, self.analyser:getBottom(),self.w, h)
  self.distances:setBounds(0, self.spkers:getBottom(), self.w, h)
  self.rooms:setBounds(0, self.distances:getBottom(), self.w, h)
  self.ms:setBounds(0, self.rooms:getBottom(), self.w, h)

  self.h = self.ms:getBottom()

end

return MonitorPresets



