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
local ButtonList = require 'ButtonList'
local Slider = require 'Slider'
local rea = require 'rea'
local _ = require '_'
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

  self.watchers:watch(function()
    return reaper.GetOutputChannelName(0)
  end, function(name)
    -- local enabled = _.some({'Groove', 'Left', 'Audio Output 1'}, function(on) return name == on end) and true or false
    -- Track.master:getFx('Sonarworks', false, true):setEnabled(enabled)
    -- Track.master:getFx('stereo', false, true):setEnabled(enabled)
    -- Track.master:getFx('FIR', false, true):setEnabled(enabled)
    -- Track.master:getFx('isone', false, true):setEnabled(enabled)

  end)

  -- if Track.master:getFx('Isone',false, true):getEnabled() then
  --   self.spkers = self:addChildComponent(Speakers:create())
  --   self.distances = self:addChildComponent(Distances:create())
  --   self.rooms = self:addChildComponent(Rooms:create())
  -- else--
  --   if Track.master:getFx('Sonarworks', false, true):getEnabled() then
  self.mode = self:addChildComponent(TextButton:create('realtime'))
  self.mode.getToggleState = function()
    return Track.master:getFx('Sonarworks', false, true):getPreset() == 'precise_mp'
  end
  self.mode.onButtonClick = function()
    rea.transaction('toggle mode', function()
      Track.master:getFx('Sonarworks', false, true):setPreset(self.mode.getToggleState() and 'precise' or 'precise_mp')
    end)
  end
-- end

  self.response = self:addChildComponent(ButtonList:create(_.map({'bypass', 'NS10', 'Auratone'}, function(name)
    local fir = Track.master:getFx('FIR',false, true)

    return {
      args = name,
      getToggleState = function()
        return fir:getPreset() == name
      end,
      onClick = function()
        rea.transaction('toggle fir', function()
          fir:setPreset(name)
        end)
      end
    }
  end), true))
  -- end

  self.ms = self:addChildComponent(MS:create())

  self.outputs = self:addChildComponent(ButtonList:create(_.map({0,1,2}, function(out)
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
  end), true))

  -- self.models = self:addChildComponent(ButtonList:create({
  --     {
  --       args = 'NX',
  --       getToggleState = function()
  --         return Track.master:getFx('NX',false, true):getEnabled()
  --       end,
  --       onClick = function(s,mouse, chained)
  --         rea.transaction('toggle monitor model', function()

  --           Track.master:getFx('NX',false, true):setEnabled(true)
  --           Track.master:getFx('Isone',false, true):setEnabled(false)
  --           if mouse:isShiftKeyDown() then self.models:getData()[3]:onClick(s,mouse, true) end

  --           return not chained
  --         end)
  --       end
  --     },
  --     {
  --       args = 'IP',
  --       getToggleState = function()
  --         return Track.master:getFx('Isone',false, true):getEnabled()
  --       end,
  --       onClick = function(s,mouse, chained)
  --         rea.transaction('toggle monitor model', function()
  --           Track.master:getFx('Isone',false, true):setEnabled(true)
  --           Track.master:getFx('NX',false, true):setEnabled(false)
  --           if mouse:isShiftKeyDown() then self.models:getData()[4]:onClick(s,mouse, true) end
  --           return not chained
  --         end)
  --       end
  --     },
  --     {
  --       args = 'SW',
  --       getToggleState = function()
  --         return Track.master:getFx('Sonarworks',false, true):getEnabled()
  --       end,
  --       onClick = function(s,mouse, chained)
  --         rea.transaction('toggle target curve', function()
  --           Track.master:getFx('Sonarworks',false, true):setEnabled(true)
  --           Track.master:getFx('Morphit',false, true):setEnabled(false)
  --           return not chained
  --         end)
  --       end
  --     },
  --     {
  --       args = 'TB',
  --       getToggleState = function()
  --         return Track.master:getFx('Morphit',false, true):getEnabled()
  --       end,
  --       onClick = function(s,mouse, chained)
  --         rea.transaction('toggle target curve', function()
  --           Track.master:getFx('Morphit',false, true):setEnabled(true)
  --           Track.master:getFx('Sonarworks',false, true):setEnabled(false)
  --           return not chained
  --         end)
  --       end
  --     },

  -- }, true))

  return self

end

function MonitorPresets:resized()

  local h = 20
  self.analyser:setBounds(0,0, self.w, h)
  self.ms:setBounds(0, self.analyser:getBottom(), self.w, h)
  -- self.models:setBounds(0,self.ms:getBottom(),self.w,h)
  self.outputs:setBounds(0,self.ms:getBottom(),self.w,h)

  local y = self.outputs:getBottom()

  -- if self.spkers then
  --   self.spkers:setBounds(0, self.outputs:getBottom(),self.w, h)
  --   self.distances:setBounds(0, self.spkers:getBottom(), self.w, h)
  --   self.rooms:setBounds(0, self.distances:getBottom(), self.w, h)
  --   y = self.rooms:getBottom()
  -- else
    if self.mode then
      self.mode:setBounds(0, self.outputs:getBottom(),self.w, h)
      y = self.mode:getBottom()
    end
    if self.response then
      self.response:setBounds(0, y,self.w, h)
      y = self.response:getBottom()
    end
  -- end

  self.h = y

end

return MonitorPresets



