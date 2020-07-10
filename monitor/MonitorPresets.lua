package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/lua/?.lua;".. package.path
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/?.lua;".. package.path

local Window = require 'Window'

local Component = require 'Component'
local Track = require 'Track'
local Speakers = require 'Speakers'
local Distances = require 'Distances'
local Rooms = require 'Rooms'
local MS = require 'MidSide'
local Mouse = require 'Mouse'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Slider = require 'Slider'
local rea = require 'rea'
local _ = require '_'
local JSON = require 'json'

local isoneRooms = JSON.parse(readFile(__dirname(debug.getinfo(1,'S'))..'/'..'isoneRooms.json'))

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

  self.mic = self:addChildComponent(TextButton:create('mic'))
  self.mic.onButtonClick = function()
    Track.master:getFx('mic monitor',false, true):setEnabled(not Track.master:getFx('mic monitor',false, true):getEnabled())
  end
  self.mic.getToggleState = function()
      return Track.master:getFx('mic monitor',false, true):getEnabled()
  end

  self.feed = self:addChildComponent(TextButton:create('x-feed'))
  self.feed.onButtonClick = function()
    Track.master:getFx('xfeed',false, true):setEnabled(not Track.master:getFx('xfeed',false, true):getEnabled())
  end
  self.feed.getToggleState = function()
    return Track.master:getFx('xfeed',false, true):getEnabled()
  end

  -- self.mode = self:addChildComponent(ButtonList:create(_.map({
  --   {key = 'bypass', name = 'Off'},
  --   {key = 'precise_mp', name = 'Play'},
  --   {key = 'precise', name = 'Mix'}
  -- }, function(v) return {
  --   args = v.name,
  --   onClick = function()
  --     rea.transaction('toggle SW', function()
  --       Track.master:getFx('Sonarworks', false, true):setPreset(v.key)
  --     end)
  --   end,
  --   getToggleState = function ()
  --     return Track.master:getFx('Sonarworks', false, true):getPreset() == v.key
  --   end
  -- } end), true))

  local rooms = {
    near = {
      sim = 1,
      dist = 0.75,
      er = 0.2,
    },
    max = {
      sim = 1,
      dist = 3,
      er = 1,
    },
    mid = {
      sim = 1,
      dist = 1.5,
      er = 0.5,
    },
    far = {
      sim = 1,
      dist = 2.25,
      er = 0.7,
    },
    off = {
      sim = 0,
      dist = 1.5,
      er = 0.5,
    },
  };
  local isone = Track.master:getFx('Isone', false, true)

  function setRoom(name)
    local val = rooms[name]
    isone:setParam('Spk dist', val.dist / 3)
    isone:setParam('Room ER', val.er)
    isone:setParam('Room sim', val.sim)

  end
  local orderedRooms = _.map({'off', 'near', 'mid', 'far', 'max'}, function(val)
    local room = rooms[val]
    room.name = val
    return room
  end)
  self.room = self:addChildComponent(ButtonList:create(_.map(orderedRooms, function(val)
    return {
      args = val.name,
      getToggleState = function()
        return isone:getParam('Room sim') == val.sim and isone:getParam('Spk dist') == (val.dist / 3)
      end,
      onDblClick = function()
        local values = {}
        _.forEach({
          'Spk HP',
          'Spk Mid',
          'Spk LP',
          'Spk HPF',
          'Spk HPG',
          'Spk MidF',
          'Spk MidG',
          'Spk LPF',
          'Spk LPG',
          'Spk size',
        }, function(name)
          values[name] = isone:getParam(name)
        end)
        rea.log(values)
      end,
      onClick = function()
        rea.transaction('toggle room', function()
          setRoom(val.name)
        end)
      end
    }
  end), true))

  local speakers = {
    -- {
    --   preset = 'bypass',
    --   name = 'hard',
    --   room = 'med',
    --   size = 1,
    --   ms = 0,
    -- },
    {
      preset = 'bypass',
      name = 'flat',
      room = 'mid',
      size = 2.8,
      ms = 0,
    },
    -- {
    --   preset = 'bypass',
    --   name = 'soft',
    --   room = 'mid',
    --   size = 5,
    --   ms = 0,
    -- },
    {
      preset = 'NS10',
      room = 'near',
      size = 2.5,
      ms = 0,
    },
    {
      preset = 'Auratone',
      room = 'near',
      size = 10,
      ms = 1,
    }
  }

  self.response = self:addChildComponent(ButtonList:create(_.map(speakers, function(val)
    local fir = Track.master:getFx('FIR',false, true)
    local name = val.name or val.preset
    local size = (val.size - 1) / 9
    return {
      args = name,
      getToggleState = function()
        return (fir:getPreset() == val.preset) and fequal(isone:getParam('Spk size'), size, 2)
      end,
      onClick = function()
        rea.transaction('toggle fir', function()
          fir:setPreset(val.preset)
          isone:setParam('Spk size', size)
          local mouse = Mouse.capture();
          if mouse:isCommandKeyDown() then
            setRoom(val.room)
          end
          if not mouse:isShiftKeyDown() then
            local ms = Track.master:getFx('ms', false, true)
            ms:setParam(0, val.ms)
          end
        end)

      end
    }
  end), true))

  self.isoneOnly = self:addChildComponent(ButtonList:create(_.map(_.filter(isoneRooms, function(val) return not val.disabled end), function(val, key)
    local name = val.name or key
    return {
      args = name,
      getToggleState = function()
        return not _.some(val.params, function(value, name)
          return not fequal(value, isone:getParam(name), 2)
        end)
      end,
      onClick = function()
        rea.transaction('toggle speaker', function()

          _.forEach(val.params, function(value, name)
            local index = isone:resolveParamIndex(name)
            isone:setParam(name, value)
          end)
        end)

      end
    }
  end), true))

  self.ms = self:addChildComponent(MS:create())

  local sliders = _.map({0,1,2,3}, function(out)
    local fx = out == 3 and 'verb' or 'outGains'
    local index = out == 3 and 0 or out
    return {
      proto = function()
        local slider = Slider:create()
        slider.getValue = function()
          return Track.master:getFx('outGains', false, true):getParam(out)
        end
        slider.setValue = function(s, val)
          Track.master:getFx('outGains', false, true):setParam(out, val)
        end
        slider.getText = function(self)
          return tostring( math.floor(self:getValue() * 100) ) .. '%'
        end

        return slider
      end
    }
  end)

  self.outputs = self:addChildComponent(ButtonList:create(sliders, true))

  return self

end

function MonitorPresets:resized()

  local h = 20
  local numOpts = 2;
  self.analyser:setBounds(0,0, self.w/numOpts, h)
  self.mic:setBounds(self.analyser.w,0, self.w/numOpts, h)
  -- self.feed:setBounds(self.mic:getRight(),0, self.w/numOpts, h)
  self.ms:setBounds(0, self.analyser:getBottom(), self.w, h)
  -- self.models:setBounds(0,self.ms:getBottom(),self.w,h)
  -- self.outputs:setBounds(0,self.ms:getBottom(),self.w,h)

  local y = self.ms:getBottom()

  if self.mode then
    self.mode:setBounds(0, y, self.w, h)
    y = self.mode:getBottom()
  end

  if self.response then
    self.response:setBounds(0, y, self.w, h)
    y = self.response:getBottom()
  end

  -- if self.isoneOnly then
  --   self.isoneOnly:setBounds(0, y, self.w, h)
  --   y = self.isoneOnly:getBottom()
  -- end

  self.room:setBounds(0, y, self.w, h)
  y = self.room:getBottom()

  self.h = y

end

return MonitorPresets



