-- dep header --
local _dep_cache = {} 
local _deps = { 
MonitorPresets = function()
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/lua/?.lua;".. package.path
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."D3CK/?.lua;".. package.path

local Window = require 'Window'

local Component = require 'Component'
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

  self.spkers = self:addChildComponent(Speakers:create())
  self.distances = self:addChildComponent(Distances:create())
  self.rooms = self:addChildComponent(Rooms:create())

  self.ms = self:addChildComponent(MS:create())

  return self

end

function MonitorPresets:resized()

  local h = 20
  self.spkers:setSize(self.w, h)
  self.distances:setBounds(0, self.spkers:getBottom(), self.w, h)
  self.rooms:setBounds(0, self.distances:getBottom(), self.w, h)
  self.ms:setBounds(0, self.rooms:getBottom(), self.w, h)

end

return MonitorPresets




end
,
Slider = function()
local Component = require 'Component'
local Label = require 'Label'
local color = require 'color'

local rea = require 'rea'
local Slider = class(Label)

function Slider:create(...)

    local self = Label:create('', ...)
    setmetatable(self, Slider)
    return self

end

function Slider:canClickThrough()
    return false
end

function Slider:onMouseDown()
    self.valueDown = self:getValue()
    self.yDown = gfx.mouse_y
end

function Slider:onDrag()
    self:setValue(self.valueDown + (self.yDown - gfx.mouse_y)    / 100)
end

function Slider:onMouseWheel(mouse)
    if mouse.mouse_wheel > 0 then
        self:setValue(self:getValue() + 1)
    else
        self:setValue(self:getValue() - 1)
    end
end

function Slider:onClick(mouse)
    if mouse:isCommandKeyDown() then
        self:setValue(self:getDefaultValue())
    end
end

function Slider:getColor(full)
    local c = Label.getColor(self)
    if not full then c = c:fade_by(0.8) end
    return c
end

function Slider:paint(g)

    Label.paint(self, g)

    g:setColor(self:getColor(true))

    local padding = 0
    g:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, 5, false)

end

function Slider:onDblClick()
    local success, value = reaper.GetUserInputs("value", 1, "value", self:getValue())
    local val = tonumber(value)
    if success and tostring(val) == value then
        self:setValue(val)
    end
end

function Slider:setValue(val)
end

function Slider:getValue()
    return 0
end

function Slider:getText()
    return tostring(self:getValue())
end

function Slider:getDefaultValue()
    return 0
end

return Slider
end
,
PartialPresets = function()
require 'Util'
local Plugin = require 'Plugin'

local PartialPresets = class()

function PartialPresets:create(config)
    local preset = {}
    setmetatable(preset, PartialPresets)
    preset.config = config
    return preset
end

function PartialPresets:store()
end

function PartialPresets:getCurrentSettings()
    local preset = {}
    for i, value in ipairs(self.config.params) do
        preset[value] = self.config.plugin:getParam(value)
    end
    return preset;
end

function PartialPresets:load(preset)
    for i, value in ipairs(self.config.params) do
        self.config.plugin:setParam(value, preset[value])
    end
end

function PartialPresets:matches(preset)
    for i, value in ipairs(self.config.params) do
        if not fequal(preset[value], self.config.plugin:getParam(value), 2) then
            return false
        end
    end
    return true
end

return PartialPresets
end
,
boot = function()

function addScope(name)
    package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. name .. "/?.lua;".. package.path
end

math.randomseed(os.time())

addScope('lib')
addScope('lib/ui')

require 'Util'


end
,
TextButton = function()
local Label = require 'Label'
local Mouse = require 'Mouse'

local color = require 'color'
local rea = require 'rea'

local TextButton = class(Label)

function TextButton:create(content, ...)

    local self = Label:create(content, ...)
    setmetatable(self, TextButton)
    return self

end

function TextButton:getToggleStateInt()
    local state = self:getToggleState()
    if type(state) ~= 'number' then
       state = state and 1 or 0
    end
    return state
end

function TextButton:onMouseEnter()
    self:repaint()
end

function TextButton:onMouseLeave()
    self:repaint()
end

function TextButton:getColor()

    local state = self:getToggleStateInt()
    local c = ((self:isMouseDown() or state > 0) and self.color)
                or (self:isMouseOver() and self.color:fade(0.8))
                or self.color:fade(0.5)

    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function TextButton:onClick(mouse)
    if self.onButtonClick and self:isVisible() and not self:isDisabled() then
        self:onButtonClick(mouse)
    end
    self:repaint()
end

function TextButton:canClickThrough()
    return false
end

function TextButton:getToggleState()
    return false
end

function TextButton:getMenuEntry(tansaction)
    assert(self.getText)
    return {
        name = self:getText(),
        callback = function()
            self:onClick(Mouse.capture())
        end,
        checked = self:getToggleState(),
        disabled = self:isDisabled(),
        tansaction = tansaction
    }
end


return TextButton
end
,
Speakers = function()
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."lua/?.lua;".. package.path

local Component = require 'Component'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local JSON = require 'json'
local rea = require 'rea'

local sets = JSON.decode(readFile(__dirname(debug.getinfo(1,'S'))..'/'..'monitors.json'))

local Speakers = class(ButtonList)


function getPreset()
  local master = reaper.GetMasterTrack()
  local isone_index = rea.getFxByName(master, "Isone", true)
  local isone_tSizeI = rea.getParamByName(master, isone_index, "Spk size")

  local value = reaper.TrackFX_GetParam(master, isone_index, isone_tSizeI)

  local fir_fx = rea.getFxByName(master, "FIR", true)
  local _,preset = reaper.TrackFX_GetPreset(master, fir_fx, 1)
  return value, preset
end


function Speakers:create()
    local proto = ButtonList:create(sets, 1)
    setmetatable(proto, Speakers)
    return proto
end

function Speakers:isSelected(i)
  local value, preset = getPreset()
  local set = sets[i]
  value = tonumber(string.format("%.2f", value * 9 + 1))
  return set['size'] == value and set['preset'] == preset
end

function Speakers:onItemClick(i, preset)

  local master = reaper.GetMasterTrack()
  local isone_index = rea.getFxByName(master, "Isone", true)
  local isone_tSizeI = rea.getParamByName(master, isone_index, "Spk size")
  local size = preset['size']

  reaper.TrackFX_SetParam(master, isone_index, isone_tSizeI, (preset['size']-1) / 9)

  local fir_fx = rea.getFxByName(master, "FIR", true)
  reaper.TrackFX_SetPreset(master, fir_fx, preset['preset'])
end

return Speakers
end
,
Mouse = function()

local Mouse = class()

function Mouse.capture(time, prev)
    local self = {
        prev = prev,
        cap = gfx.mouse_cap,
        x = gfx.mouse_x,
        y = gfx.mouse_y,
        time = time,
        mouse_wheel = gfx.mouse_wheel
    }

    if prev then
        prev.prev = nil
    end

    gfx.mouse_wheel = 0
    setmetatable(self, Mouse)
    return self
end

function Mouse:isLeftButtonDown()
    return toboolean(self.cap & 1)
end

function Mouse:isRightButtonDown()
    return toboolean(self.cap & 2)
end

function Mouse:wasLeftButtonDown()
    return self.prev and self.prev:wasLeftButtonDown()
end

function Mouse:wasRightButtonDown()
    return self.prev and self.prev:isRightButtonDown()
end

function Mouse:isButtonDown()
    return self:isLeftButtonDown() or self:isRightButtonDown()
end

function Mouse:isCommandKeyDown()
    return toboolean(self.cap & 4)
end

function Mouse:isAltKeyDown()
    return toboolean(self.cap & 16)
end

function Mouse:isShiftKeyDown()
    return toboolean(self.cap & 8)
end

function Mouse:__tostring()
    return dump(self)
end

return Mouse
end
,
ButtonList = function()
local Component = require 'Component'
local TextButton = require 'TextButton'
local _ = require '_'
local Menu = require 'Menu'

local rea = require 'rea'

local ButtonList = class(Component)

function ButtonList:create(data, layout, proto, ...)

    local self = Component:create(...)
    self.layout = layout
    self.data = data
    self.proto = proto or TextButton
    setmetatable(self, ButtonList)
    self:updateList()
    return self

end

function ButtonList:updateList()

    self:deleteChildren()
    -- _.forEach(self.children, function(child) child:delete() end)
    -- self.children = {}
    local size = self.layout == true and 'w' or 'h'
    self[size] = 0
    for i, value in pairs(self:getData()) do

        local proto = value.proto or self.proto

        local args = value.args or tostring(i)
        local comp = type(proto) == 'function' and proto() or proto:create(args)

        comp.color = value.color or comp.color

        comp.onButtonClick = comp.onButtonClick or function(s, mouse)
            if value.onClick then
                value.onClick(value, mouse)
            else
                self:onItemClick(i, value)
            end

        end

        if self.layout == 1 then
            comp.onClick = function() end
            comp.canClickThrough = function() return true end
            comp.isVisible = function() return comp:getToggleState() end
        end

        comp.getToggleState = comp.getToggleState ~= TextButton.getToggleState and comp.getToggleState or function()
            if value.getToggleState then
                return value:getToggleState(value)
            else
                return self:isSelected(i, value)
            end
        end

        if value.getText then
            function comp:getText()
                return value:getText()
            end
        end

        if value.isDisabled then
            comp.isDisabled = function()
                return value:isDisabled(value)
            end
        end

        self:addChildComponent(comp)
        local CompSize = value.size or (comp[size] > 0 and comp[size]) or self.getDefaultCompSize()
        self[size] = self[size] + CompSize
    end

    if self.layout == 1 and _.size(self.children) then
        self[size] = _.first(self.children)[size]
    end

    self:repaint()
end

function ButtonList:getDefaultCompSize()
    return 20
end

function ButtonList:onClick()
    if self.layout == 1 then
        self:showAsMenu()
    end
end

function ButtonList:getData()
    return self.data
end

function ButtonList:resized()

    if self.layout == 1 then
        for k, child in pairs(self.children) do

            child:setBounds(0,0,self.w, self.h)
        end
    else
        local len = _.size(self:getData())
        local dim = self.layout == true and 'w' or 'h'
        local p = self.layout == true and 'x' or 'y'
        local size = self[dim] / len

        local i = 1
        local off = 0
        for index, child in pairs(self.children) do
            local data = self:getData()[i]
            child.w = self.w
            child.h = self.h
            child.x = 0
            child.y = 0

            child[p] = off
            child[dim] = data and data.size or size
            off = off + child[dim]
            i = i + 1
            child:relayout()
        end
    end

end

function ButtonList:onItemClick(i, entry)
end

function ButtonList:isSelected(i, entry)
end

function ButtonList:showAsMenu()
    local menu = Menu:create()

    _.forEach(self:getData(), function(opt, i)
        local child = self.children[i]
        menu:addItem(opt.args, {
            callback = function() return child:onButtonClick(true) end,
            checked = child:getToggleState()
        })
    end)


    menu:show()

end

return ButtonList
end
,
Project = function()
local Track = require 'Track'
local Watcher = require 'Watcher'
local _ = require '_'


local Project = class()

Project.watch = {
    project = Watcher:create(function () return reaper.GetProjectStateChangeCount(0) end)
}

function Project.getStates()

    local state = true
    local i = 0
    local res = {}
    while state do
        local success, key, value = reaper.EnumProjExtState(0, 'D3CK', i)
        i = i + 1
        state = success
        if state then
            res[key] = value
        end
    end

    res._wised = _.filter(res, function(val, key)
        local trackId = key:match(Track.metaMatch)
        local track = Track.getTrackMap()[trackId]
        return not track or not track:exists()
    end)
    return res
end


function Project.getCurrentProject()
    return Project:create(reaper.EnumProjects(-1, ''))
end

function Project.getAllProjects()
    local proj = true
    local res = {}
    local i = 0
    while proj do
        proj = reaper.EnumProjects(i, '')
        i = i + 1
        if proj then
            table.insert(res,Project:create(proj))
        end
    end
    return res
end

function Project:create(proj)
    local self = {proj = proj}
    setmetatable(self, Project)
    return self
end

function Project:focus()
    reaper.SelectProjectInstance(self.proj)
    return self
end

return Project
end
,
Distances = function()
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
end
,
json = function()
-- Module options:
local register_global_module_table = false
local global_module_name = 'json'

--[==[

David Kolf's JSON module for Lua 5.1/5.2

Version 2.5


For the documentation see the corresponding readme.txt or visit
<http://dkolf.de/src/dkjson-lua.fsl/>.

You can contact the author by sending an e-mail to 'david' at the
domain 'dkolf.de'.


Copyright (C) 2010-2013 David Heiko Kolf

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat

local json = { version = "dkjson 2.5" }

if register_global_module_table then
  _G[global_module_name] = json
end

local _ENV = nil -- blocking globals in Lua 5.2


json.null = setmetatable ({}, {
  __tojson = function () return "null" end
})

local function isarray (tbl)
  local max, n, arraylen = 0, 0, 0
  for k,v in pairs (tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end
      if k > max then
        max = k
      end
      n = n + 1
    end
  end
  if max > 10 and max > arraylen and max > n * 2 then
    return false -- don't create an array with too many holes
  end
  return true, max
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

local function escapeutf8 (uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176-\191]", escapeutf8)
  end
  return "\"" .. value .. "\""
end
json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind (str, o, 1, true)
  if i then
    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
  else
    return str
  end
end

-- locale independent num2str and str2num functions
local decpoint, numfilter

local function updatedecpoint ()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  -- build a filter that can be used to remove group separators
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str (num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num (str)
  local num = tonumber(replace(str, ".", decpoint))
  if not num then
    updatedecpoint()
    num = tonumber(replace(str, ".", decpoint))
  end
  return num
end

local function addnewline2 (level, buffer, buflen)
  buffer[buflen+1] = "\n"
  buffer[buflen+2] = strrep ("  ", level)
  buflen = buflen + 2
  return buflen
end

function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type (key)
  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end
  if prev then
    buflen = buflen + 1
    buffer[buflen] = ","
  end
  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ":"
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen
  if type (res) == 'string' then
    buflen = buflen + 1
    buffer[buflen] = res
  end
  return buflen
end

local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason
  local handler = state.exception
  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen
    local ret, msg = handler (reason, value, state, defaultmessage)
    if not ret then return nil, msg or defaultmessage end
    return appendcustom(ret, buffer, state)
  end
end

function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson
  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    state.bufferlen = buflen
    local ret, msg = valtojson (value, state)
    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
    tables[value] = nil
    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray (value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            prev = true -- add a seperator before the next element
          end
        end
        for k,v in pairs (value) do
          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception ('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end

function json.encode (value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                   buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error (msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat (buffer)
  end
end

local function loc (str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind (str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end
  return "line " .. line .. ", column " .. (where - linepos)
end

local function unterminated (str, what, where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

local function scanwhite (str, pos)
  while true do
    pos = strfind (str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub (str, pos, pos + 1)
    if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind (str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind (str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated (str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end
    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar (value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end
      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat (buffer), lastpos
  else
    return "", lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local len = strlen (str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable (tbl, objectmeta)
  else
    setmetatable (tbl, arraymeta)
  end
  while true do
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    local char = strsub (str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    char = strsub (str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end
      pos = scanwhite (str, pos + 1)
      if not pos then return unterminated (str, what, startpos) end
      local val2
      val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite (str, pos)
      if not pos then return unterminated (str, what, startpos) end
      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite (str, pos)
  if not pos then
    return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub (str, pos, pos)
  if char == "{" then
    return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring (str, pos)
  else
    local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num (strsub (str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind (str, "^%a%w*", pos)
    if pstart then
      local name = strsub (str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc (str, pos)
  end
end

local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return {__jsontype = 'object'}, {__jsontype = 'array'}
  end
end

function json.decode (str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end


return json


end
,
colors = function()
local color = require 'color'

return {
    fx = color.rgb(color.parse('#b8e5ff', 'rgb')),
    mute = color.rgb(color.parse('#f24429', 'rgb')),
    solo = color.rgb(color.parse('#faef1b', 'rgb')),
    la = color.rgb(color.parse('#f4a442', 'rgb')),
    aux = color.rgb(color.parse('#f46241', 'rgb')),
    instrument = color.rgb(color.parse('#527710', 'rgb')),
    layer = color.rgb(color.parse('#88a850', 'rgb'))
}
end
,
String = function()
local _ = require '_'

function string:unquote()
    return self:sub(1,1) == '"' and self:sub(-1,-1) == '"' and self:sub(2,-2) or self
end

function string:startsWith(start)
    return self:sub(1, #start) == start
end

function string:endsWith(ending)
    return ending == "" or self:sub(-#ending) == ending
end

function string:isNumeric()
    return self:match('[0-9]+.[0-9]*')
end

function string:escaped()
    return self:gsub("([^%w])", "%%%1")
end

function string:forEachChar(callback)
    for i=1, #self do
        if callback(self:byte(i), i) == false then return end
    end
end

function string:forEach(callback)
    local i = 1
    for c in str:gmatch ('.') do
        if callback(c, i) == false then return end
        i = i + 1
    end
end

function string:includes(needle)
    return _.size(self:split(needle)) > 1
end

function string:equal(other)
    local len = self:len()
    if other:len() ~= len then return false end
    local rea = require 'rea'

    for i = 1, len do
        if self:sub(i,i) ~= other:sub(i, i) then
            return false
        end
    end

    return true
end

function string:gmatchall(pattern)

    local result = {}

    local iterator = self:gmatch(pattern)

    local wrapper = function()
        return function(...)
            local res = {iterator(...)}
            return #res > 0 and res or nil
        end
    end

    for v in wrapper() do
        table.insert(result, v)
    end
    return result
end

function string:split(sep, quote)
    local result = {}

    for match in (self..sep):gmatch("(.-)"..sep) do
        table.insert(result, match)
    end

    if quote then
        local grouped = {}
        local block = ''
        _.forEach(result, function(val)
            local qStart = val:startsWith(quote)
            local qEnd = val:endsWith(quote)
            if qStart or qEnd then
                if qEnd then
                    table.insert(grouped, block .. sep .. val)
                    block = ''
                elseif qStart then
                    block = val
                end
            else
                if block:len() > 0 then
                    block = block .. sep .. val
                else
                    table.insert(grouped, val)
                end
            end
        end)
        return grouped
    else
        return result
    end
end

function string:trim(s)
    return (self:gsub("^%s*(.-)%s*$", "%1"))
 end
end
,
Label = function()
local Component = require 'Component'
local Text = require 'Text'
local color = require 'color'

local rea = require 'rea'
local Label = class(Component)

function Label:create(content, ...)

    local self = Component:create(...)
    self.r = 6
    if content then
        if type(content) == 'string' then
            self.content = self:addChildComponent(Text:create(content))
            self.content.getText = function()
                return self.getText and self:getText() or self.content.text
            end
        else
            self.content = self:addChildComponent(content)
        end
    end

    self.color = color.rgb(1,1,1)
    setmetatable(self, Label)
    return self

end

function Label:getColor()
    local c = self.color
    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function Label:drawBackground(g, c)
    c = c or self:getColor()
    local padding = 0

    g:setColor(c);
    g:roundrect(padding ,padding , self.w - 2 * padding, self.h - 2*padding, self.r or 5, true)

end

function Label:paint(g)

    local c = self:getColor()
    self:drawBackground(g, c)

end

return Label
end
,
Profiler = function()
local _ = require '_'

local timer = reaper.time_precise

local Profiler = class()

function Profiler:create(libs)
    local self = {
        libs = libs
    }
    setmetatable(self, Profiler)

    self.unwrappedLibs = _.map(libs, function(name)
        return _G[name], name
    end)

    self.wrappedLibs = _.map(self.unwrappedLibs, function(lib, key)
        return _.map(lib, function(member, name)
            name = key .. '.' .. name
            if type(member) == 'function' then
                return function(...)


                    self.profile.totalCalls = self.profile.totalCalls + 1

                    local meth = self.profile.methods[name]
                    if not meth then
                        meth = {
                            time = 0,
                            calls = 0
                        }
                        self.profile.methods[name] = meth
                    end

                    local pre = timer()
                    local res = {member(...)}

                    meth.calls = meth.calls + 1
                    meth.time = meth.time + timer() - pre

                    meth.__tostring = function(self)
                        return tostring(self.calls) .. ', ' .. tostring(self.time)
                    end

                    return table.unpack(res)
                end

            end
        end), key
    end)

    return self
end

function Profiler:unWrap()
    _.forEach(self.unwrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            _G[libName][name] = func
        end)
    end)
end

function Profiler:wrap()
    _.forEach(self.wrappedLibs, function(lib, libName)
        _.forEach(lib, function(func, name)
            _G[libName][name] = func
        end)
    end)
end

function Profiler:run(func, loop)

    loop = loop or 100000

    self.profile = {
        totalCalls = 0,
        methods = {}
    }

    self:wrap()

    local pre = timer()
    for i = 1, loop do
        func()
    end
    local time = timer() - pre

    self:unWrap()

    return {
        mem = collectgarbage('count'),
        time = time * 1000,
        calls = self.profile
    }


end

return Profiler
end
,
Window = function()
local Mouse = require 'Mouse'
local Component = require 'Component'
local State = require 'State'
local Track = require 'Track'
local Plugin = require 'Plugin'
local Project = require 'Project'
local Watcher = require 'Watcher'
local Graphics = require 'Graphics'

local _ = require '_'
local rea = require 'rea'

gfx.setfont(1, "arial", 0.2, 'bi')

local Window = class()

Window.currentWindow = nil

Project.watch.project:onChange(function()
    if Window.currentWindow then
        Window.currentWindow.repaint = 'all'
    end
    Track.onStateChange()
end)

function Window.openComponent(name, component, options)

    local win = Window:create(name, component)
    win:show(options)
    return win

end

function Window:create(name, component)
    local self = {
        name = name,
        mouse = Mouse.capture(),
        state = {},
        repaint = true,
        g = Graphics:create(),
        options = {debug = true},
        paints = 0
    }
    setmetatable(self, Window)
    component.window = self
    self.component = component

    self.time = reaper.time_precise()
    return self
end

function Window:isOpen()
    return self.open ~= false
end

function Window:render()

    if self.repaint or Component.dragging then

        gfx.update()
        gfx.clear = 0

        self.component:evaluate(self.g)

        if Component.dragging then
            if Component.dragging.isComponent then

                gfx.setimgdim(0, -1,-1)
                gfx.setimgdim(0, Component.dragging.w, Component.dragging.h)

                Component.dragging:evaluate(self.g, 0)

                gfx.dest = -1
                gfx.x = gfx.mouse_x - Component.dragging.w/2
                gfx.y = gfx.mouse_y - Component.dragging.h/2
                gfx.a = 0.5
                gfx.blit(0, 1, 0)

            else
                self.g:setColor(1,1,1,0.5)
                self.g:circle(gfx.mouse_x, gfx.mouse_y, 10, true, true)
            end
        end

        self.repaint = false

        self.paints = self.paints + 1

    end

end

function Window:unfocus(options)
    -- reaper.SetCursorContext(1, 0)
end

function Window:show(options)

    options = options or {}
    options.persist = options.persist == nil and true or options.persist

    Window.currentWindow = self
    _.assign(self, options)

    local stored = State.global.get('window_' ..self.name, options, {'h','w', 'dock'})
    _.assign(self, stored)

    gfx.init(self.name, self.w, self.h, self.dock)

    if not options.focus then self:unfocus() end

end

function Window:close()
    self.open = false
    gfx.quit()
    if self.onClose then self:onClose() end
end

function Window:restoreState()

    if self.options.persist then

        self.docked = State.global.get('window_' .. self.name .. '_docked')

        if docked then
            self.docked = true
            self.dock = State.global.get('window_' .. self.name .. '_dock')
            gfx.dock(self.dock)
        else
            gfx.dock(0)
        end

        self.component.h = State.global.get('window_' .. self.name .. '_h')
        self.component.w = State.global.get('window_' .. self.name .. '_w')

    end

end

function Window:updateWindow()

    if  self.component.h ~= gfx.h or self.component.w ~= gfx.w then
        self.component:setSize(gfx.w, gfx.h)
    end

    local dock = gfx.dock(-1)

    if dock ~= self.dock then
        self.docked = dock > 0
        self.dock = self.docked and dock or self.dock
    end

    if self.options.persist then

        State.global.set('window_' .. self.name, _.pick(self, {'dock', 'docked'}))
        State.global.set('window_' .. self.name .. '_h', gfx.h)
        State.global.set('window_' .. self.name .. '_w', gfx.w)

    end

end

function Window:toggleDock()

    local dock = gfx.dock(-1)
    if dock > 0 then
        gfx.dock(0)
    else
        gfx.dock(self.dock)
    end

    self:updateWindow()

end

function Window:evalKeyboard()

    local key = gfx.getchar()

    if key == -1 then
        self:close()
    else
        while key > 0 do
            if self.options.debug then
                rea.log('keycode:' .. tostring(key))
            end

            if key == 324 and self.mouse:isShiftKeyDown() then
                self:toggleDock()
            end

            _.forEach(self.component:getAllChildren(), function(comp)
                if comp.onKeyPress then
                    comp:onKeyPress(key)
                end
            end)
            key = gfx.getchar()

        end
    end
end

function getDroppedFiles()
    local files = {}
    local i = 0
    local success, file = gfx.getdropfile(i)
    while success >= 1 do
        table.insert(files, file)
        i = i + 1
        success, file = gfx.getdropfile(i)
    end

    gfx.getdropfile(-1)

    return files
end

function Window:evalMouse()

    local files = getDroppedFiles()
    local isFileDrop = _.size(files) > 0

    local mouse = Mouse.capture(reaper.time_precise(), self.mouse)

    local mouseMoved = self.mouse.x ~= mouse.x or self.mouse.y ~= mouse.y
    local capChanged = self.mouse.cap ~= mouse.cap
    local mouseDragged = mouseMoved and self.mouse:isButtonDown() and mouse:isButtonDown()

    local wheelMove = mouse.mouse_wheel ~= 0

    local mouseDown = (not self.mouse:isButtonDown()) and mouse:isButtonDown()
    local mouseUp = self.mouse:isButtonDown() and (not mouse:isButtonDown())

    if mouseUp and self.component:isMouseOver() then self:unfocus() end

    local allComps = self.component:getAllChildren()

    if mouseMoved or capChanged or isFileDrop or wheelMove then

        local consumed = false

        _.forEach(allComps, function(comp)

            comp:updateMousePos(mouse)

            local isOver = comp:isMouseOver()
            local mouseLeave = comp.mouse.over and not isOver
            if mouseLeave then
                if comp.onMouseLeave then
                    comp:onMouseLeave()
                end
                if comp == self.component then
                    self.repaint = self.repaint or true
                end
            end

            local mouseEnter = not comp.mouse.over and isOver
            if mouseEnter and comp.onMouseEnter then comp:onMouseEnter() end

            comp.mouse.over = isOver

            local useComp = comp:wantsMouse() and (isOver or (mouseDragged and comp.mouse.down))
            if not consumed and useComp then

                if wheelMove and comp.onMouseWheel then comp:onMouseWheel(mouse) end

                if mouseDown then
                    comp.mouse.down = mouse.time
                    if comp.onDblClick and comp.mouse.up and (mouse.time - comp.mouse.up < 0.1) then
                        comp:onDblClick(mouse)
                    end
                    if comp.onMouseDown then comp:onMouseDown(mouse) end
                end

                if mouseUp then

                    if comp.onMouseUp then comp:onMouseUp(mouse) end
                    if comp.mouse.down and comp.onClick then
                        -- rea.log('click')
                        comp:onClick(mouse)
                    end
                    if comp.onDrop and Component.dragging then comp:onDrop(mouse) end

                    comp.mouse.up = mouse.time
                    comp.mouse.down = false
                end

                if comp.onFilesDrop then
                    if isFileDrop then
                        comp:onFilesDrop(files)
                        files = {}
                    end
                end

                if comp.mouse.down and mouseDragged and comp.onDrag then
                    comp:onDrag(mouse)
                end

                consumed = consumed or not comp:canClickThrough()

            end
        end)

    end

    self.mouse = mouse

    if not self.mouse:isButtonDown() then
        _.forEach(allComps, function(child)
            if child.mouse.down then rea.log('up') end
            child.mouse.down = false
        end)
        if Component.dragging then
            self.repaint = self.repaint or true
            Component.dragging = nil
        end
    end

end

function Window:defer()

    self:updateWindow()
    self:render()
    self:evalMouse()
    self:evalKeyboard()

    if rea.refreshUI(true) then
        self.paint = true
    end

end

return Window
end
,
Plugin = function()
local Slider = require 'Slider'

local rea = require 'rea'

local Plugin = class()

Plugin.plugins = {}

function Plugin.exists(name)

    local track = reaper.GetMasterTrack(0)
    local plugin = reaper.TrackFX_AddByName(track, name, false, -1)
    if plugin >= 0 then
        reaper.TrackFX_Delete(track, plugin)
        return true
    end
    return false
end

function Plugin.deferAll()
    Plugin.plugins = {}
end

function Plugin.getByGUID(track, guid)
    for i=0, reaper.TrackFX_GetCount(track)-1 do
        if reaper.TrackFX_GetFXGUID(track, i) == guid then return i end
    end
end

--

function Plugin:create(track, index)
    local guid = reaper.TrackFX_GetFXGUID(track.track, index)

    if not Plugin.plugins[guid] then
        local p = {}
        setmetatable(p, Plugin)
        p.track = track
        p.rec = rec
        p.guid = guid
        Plugin.plugins[guid] = p
    end

    Plugin.plugins[guid].index = index

    return Plugin.plugins[guid]
end

function Plugin:resolveIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getFxByName(self.track.track, nameOrIndex, self.rec)
    else
        return nameOrIndex
    end
end

function Plugin:resolveParamIndex(nameOrIndex)
    if type(nameOrIndex) == 'string' then
        return rea.getParamByName(self.track.track, self.index, nameOrIndex)
    else
        return nameOrIndex
    end
end

function Plugin:getIndex()
    return self.index
end


function Plugin:getState()
    return self.track:getState():getPlugins()[self.index + 1]
end

function Plugin:getModule()
    local res, name =  reaper.BR_TrackFX_GetFXModuleName(self.track.track, self.index, '', 10000)
    return name
end

function Plugin:isValid()
    return self.guid == reaper.TrackFX_GetFXGUID(self.track.track, self.index)
end

function Plugin:reconnect()
    self.index = Plugin.getByGUID(self.track.track, self.guid)
end

function Plugin:getEnabled()
    return reaper.TrackFX_GetEnabled(self.track.track, self.index)

end

function Plugin:setEnabled(enabled)
    reaper.TrackFX_SetEnabled(self.track.track, self.index, enabled)
end

function Plugin:refresh()
    if not self:isValid() then self:reconnect() end
    return self:isValid()
end

function Plugin:setIndex(index)
    if self.index ~= index then
        reaper.TrackFX_CopyToTrack(self.track.track, self.index, self.track.track, index, true)
        self.index = index
    end
    return self
end

function Plugin:isOpen()
    return reaper.TrackFX_GetOpen(self.track.track, self.index)
end

function Plugin:getName()
    local success, name = reaper.TrackFX_GetFXName(self.track.track, self.index, '')
    return success and name
end

function Plugin:getCleanName()
    return self:getName():gsub('%(.-%)', ''):gsub('.-: ', ''):trim()
end

function Plugin:setName()

end

function Plugin:setPreset(nameOrIndex)
    reaper.TrackFX_SetPreset(self.track.track, self.index, nameOrIndex)
end

function Plugin:getPreset()
    local s, name = reaper.TrackFX_GetPreset(self.track.track, self.index, 1)
    return name
end

function Plugin:remove()
    reaper.TrackFX_Delete(self.track.track, self.index)
    Plugin.plugins[self.guid] = nil
end

function Plugin:open(show)
    reaper.TrackFX_SetOpen(self.track.track, self.index, show == nil and true or show)
end

function Plugin:setParam(nameOrIndex, value)

    if not self:refresh() then return end

    if type(nameOrIndex) == 'string' then
        local res = reaper.TrackFX_SetNamedConfigParm(self.track.track, self.index, nameOrIndex, value)
        if not res then self:setParam(self:resolveParamIndex(nameOrIndex), value) end
    else
        return reaper.TrackFX_SetParam(self.track.track, self.index, nameOrIndex, value)
    end

end

function Plugin:getParam(nameOrIndex)

    if type(nameOrIndex) == 'string' then
        local res, val = reaper.TrackFX_GetNamedConfigParm(self.track.track, self.index, nameOrIndex)
        if res then
            return val
        else
            return self:getParam(self:resolveParamIndex(nameOrIndex))
        end
    elseif type(nameOrIndex) == 'number' then
        return reaper.TrackFX_GetParam(self.track.track, self.index, nameOrIndex)
    end

end

function Plugin:createSlider(index)
    local slider = Slider:create()
    local plugin = self
    slider.getValue = function()
        return plugin:getParam(index)
    end
    function slider:setValue(value)
        plugin:setParam(index, value)
    end
    return slider
end

return Plugin
end
,
color = function()

--color parsing, formatting and computation.
--Written by Cosmin Apreutesei. Public Domain.
--HSL-RGB conversions from Sputnik by Yuri Takhteyev (MIT/X License).

local function clamp01(x)
	return math.min(math.max(x, 0), 1)
end

local function round(x)
	return math.floor(x + 0.5)
end

--clamping -------------------------------------------------------------------

local clamps = {} --{space -> func(x, y, z, a)}

local function clamp_hsx(h, s, x, a)
	return h % 360, clamp01(s), clamp01(x)
end
clamps.hsl = clamp_hsx
clamps.hsv = clamp_hsx

function clamps.rgb(r, g, b)
	return clamp01(r), clamp01(g), clamp01(b)
end

local function clamp(space, x, y, z, a)
	x, y, z = clamps[space](x, y, z)
	if a then return x, y, z, clamp01(a) end
	return x, y, z
end

--conversion -----------------------------------------------------------------

--HSL <-> RGB

--hsl is in (0..360, 0..1, 0..1); rgb is (0..1, 0..1, 0..1)
local function h2rgb(m1, m2, h)
	if h<0 then h = h+1 end
	if h>1 then h = h-1 end
	if h*6<1 then
		return m1+(m2-m1)*h*6
	elseif h*2<1 then
		return m2
	elseif h*3<2 then
		return m1+(m2-m1)*(2/3-h)*6
	else
		return m1
	end
end
local function hsl_to_rgb(h, s, L)
	h = h / 360
	local m2 = L <= .5 and L*(s+1) or L+s-L*s
	local m1 = L*2-m2
	return
		h2rgb(m1, m2, h+1/3),
		h2rgb(m1, m2, h),
		h2rgb(m1, m2, h-1/3)
end

--rgb is in (0..1, 0..1, 0..1); hsl is (0..360, 0..1, 0..1)
local function rgb_to_hsl(r, g, b)
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local h, s, l = 0, 0, (min + max) / 2

	if l > 0 and l < 0.5 then s = delta / (max + min) end
	if l >= 0.5 and l < 1 then s = delta / (2 - max - min) end

	if delta > 0 then
		if max == r and max ~= g then h = h + (g-b) / delta end
		if max == g and max ~= b then h = h + 2 + (b-r) / delta end
		if max == b and max ~= r then h = h + 4 + (r-g) / delta end
		h = h / 6
	end

	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end

	return h * 360, s, l
end

--HSV <-> RGB

local function rgb_to_hsv(r, g, b)
	local K = 0
	if g < b then
		g, b = b, g
		K = -1
	end
	if r < g then
		r, g = g, r
		K = -2 / 6 - K
	end
	local chroma = r - math.min(g, b)
	local h = math.abs(K + (g - b) / (6 * chroma + 1e-20))
	local s = chroma / (r + 1e-20)
	local v = r
	return h * 360, s, v
end

local function hsv_to_rgb(h, s, v)
	if s == 0 then --gray
		return v, v, v
	end
	local H = h / 60
	local i = math.floor(H) --which 1/6 part of hue circle
	local f = H - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	else
		return v, p, q
	end
end

function hsv_to_hsl(h, s, v) --TODO: direct conversion
	return rgb_to_hsl(hsv_to_rgb(h, s, v))
end

function hsl_to_hsv(h, s, l) --TODO: direct conversion
	return rgb_to_hsv(hsl_to_rgb(h, s, l))
end

local converters = {
	rgb = {hsl = rgb_to_hsl, hsv = rgb_to_hsv},
	hsl = {rgb = hsl_to_rgb, hsv = hsl_to_hsv},
	hsv = {rgb = hsv_to_rgb, hsl = hsv_to_hsl},
}
local function convert(dest_space, space, x, y, z, ...)
	if space ~= dest_space then
		x, y, z = converters[space][dest_space](x, y, z)
	end
	return x, y, z, ...
end

--parsing --------------------------------------------------------------------

local hex = {
	[2] = {'#g',        'rgb'},
	[3] = {'#gg',       'rgb'},
	[4] = {'#rgb',      'rgb'},
	[5] = {'#rgba',     'rgb'},
	[7] = {'#rrggbb',   'rgb'},
	[9] = {'#rrggbbaa', 'rgb'},
}
local s3 = {
	hsl = {'hsl', 'hsl'},
	hsv = {'hsv', 'hsv'},
	rgb = {'rgb', 'rgb'},
}
local s4 = {
	hsla = {'hsla', 'hsl'},
	hsva = {'hsva', 'hsv'},
	rgba = {'rgba', 'rgb'},
}
local function string_format(s)
	local t
	if s:sub(1, 1) == '#' then
		t = hex[#s]
	else
		t = s4[s:sub(1, 4)] or s3[s:sub(1, 3)]
	end
	if t then
		return t[1], t[2] --format, colorspace
	end
end

local parsers = {}

local function parse(s)
	local g = tonumber(s:sub(2, 2), 16)
	if not g then return end
	g = (g * 16 + g) / 255
	return g, g, g
end
parsers['#g']  = parse

local function parse(s)
	local r = tonumber(s:sub(2, 2), 16)
	local g = tonumber(s:sub(3, 3), 16)
	local b = tonumber(s:sub(4, 4), 16)
	if not (r and g and b) then return end
	r = (r * 16 + r) / 255
	g = (g * 16 + g) / 255
	b = (b * 16 + b) / 255
	if #s == 5 then
		local a = tonumber(s:sub(5, 5), 16)
		if not a then return end
		return r, g, b, (a * 16 + a) / 255
	else
		return r, g, b
	end
end
parsers['#rgb']  = parse
parsers['#rgba'] = parse

local function parse(s)
	local g = tonumber(s:sub(2, 3), 16)
	if not g then return end
	g = g / 255
	return g, g, g
end
parsers['#gg'] = parse

local function parse(s)
	local r = tonumber(s:sub(2, 3), 16)
	local g = tonumber(s:sub(4, 5), 16)
	local b = tonumber(s:sub(6, 7), 16)
	if not (r and g and b) then return end
	r = r / 255
	g = g / 255
	b = b / 255
	if #s == 9 then
		local a = tonumber(s:sub(8, 9), 16)
		if not a then return end
		return r, g, b, a / 255
	else
		return r, g, b
	end
end
parsers['#rrggbb']  = parse
parsers['#rrggbbaa'] = parse

local rgb_patt = '^rgb%s*%(([^,]+),([^,]+),([^,]+)%)$'
local rgba_patt = '^rgba%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local function np(s)
	local p = s and tonumber((s:match'^([^%%]+)%%%s*$'))
	return p and p * .01
end

local function n255(s)
	local n = tonumber(s)
	return n and n / 255
end

local function parse(s)
	local r, g, b, a = s:match(rgba_patt)
	r = np(r) or n255(r)
	g = np(g) or n255(g)
	b = np(b) or n255(b)
	a = np(a) or tonumber(a)
	if not (r and g and b and a) then return end
	return r, g, b, a
end
parsers.rgba = parse

local function parse(s)
	local r, g, b = s:match(rgb_patt)
	r = np(r) or n255(r)
	g = np(g) or n255(g)
	b = np(b) or n255(b)
	if not (r and g and b) then return end
	return r, g, b
end
parsers.rgb = parse

local hsl_patt = '^hsl%s*%(([^,]+),([^,]+),([^,]+)%)$'
local hsla_patt = '^hsla%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local hsv_patt = hsl_patt:gsub('hsl', 'hsv')
local hsva_patt = hsla_patt:gsub('hsla', 'hsva')

local function parser(patt)
	return function(s)
		local h, s, x, a = s:match(patt)
		h = tonumber(h)
		s = np(s) or tonumber(s)
		x = np(x) or tonumber(x)
		a = np(a) or tonumber(a)
		if not (h and s and x and a) then return end
		return h, s, x, a
	end
end
parsers.hsla = parser(hsla_patt)
parsers.hsva = parser(hsva_patt)

local function parser(patt)
	return function(s)
		local h, s, x = s:match(patt)
		h = tonumber(h)
		s = np(s) or tonumber(s)
		x = np(x) or tonumber(x)
		if not (h and s and x) then return end
		return h, s, x
	end
end
parsers.hsl = parser(hsl_patt)
parsers.hsv = parser(hsv_patt)

local function parse(s, dest_space)
	local fmt, space = string_format(s)
	if not fmt then return end
	local parse = parsers[fmt]
	if not parse then return end
	if dest_space then
		return convert(dest_space, space, parse(s))
	else
		return space, parse(s)
	end
end

--formatting -----------------------------------------------------------------

local format_spaces = {
	['#'] = 'rgb',
	['#rrggbbaa'] = 'rgb', ['#rrggbb'] = 'rgb',
	['#rgba'] = 'rgb', ['#rgb'] = 'rgb', rgba = 'rgb', rgb = 'rgb',
	hsla = 'hsl', hsl = 'hsl', ['hsla%'] = 'hsl', ['hsl%'] = 'hsl',
	hsva = 'hsv', hsv = 'hsv', ['hsva%'] = 'hsv', ['hsv%'] = 'hsv',
}

local function loss(x) --...of precision when converting to #rgb
	return math.abs(x * 15 - round(x * 15))
end
local threshold = math.abs(loss(0x89 / 255))
local function short(x)
	return loss(x) < threshold
end

local function format(fmt, space, x, y, z, a)
	fmt = fmt or space --the names match
	local dest_space = format_spaces[fmt]
	if not dest_space then
		error('invalid format '..tostring(fmt))
	end
	x, y, z, a = convert(dest_space, space, x, y, z, a)
	if fmt == '#' then --shortest hex
		if short(x) and short(y) and short(z) and short(a or 1) then
			fmt = a and '#rgba' or '#rgb'
		else
			fmt = a and '#rrggbbaa' or '#rrggbb'
		end
	end
	a = a or 1
	if fmt == '#rrggbbaa' or fmt == '#rrggbb' then
		return string.format(
			fmt == '#rrggbbaa' and '#%02x%02x%02x%02x' or '#%02x%02x%02x',
				round(x * 255),
				round(y * 255),
				round(z * 255),
				round(a * 255))
	elseif fmt == '#rgba' or fmt == '#rgb' then
		return string.format(
			fmt == '#rgba' and '#%1x%1x%1x%1x' or '#%1x%1x%1x',
				round(x * 15),
				round(y * 15),
				round(z * 15),
				round(a * 15))
	elseif fmt == 'rgba' or fmt == 'rgb' then
		return string.format(
			fmt == 'rgba' and 'rgba(%d,%d,%d,%.2g)' or 'rgb(%d,%d,%g)',
				round(x * 255),
				round(y * 255),
				round(z * 255),
				a)
	elseif fmt:sub(-1) == '%' then --hsl|v(a)%
		return string.format(
			#fmt == 5 and '%s(%d,%d%%,%d%%,%.2g)' or '%s(%d,%d%%,%d%%)',
				fmt:sub(1, -2),
				round(x),
				round(y * 100),
				round(z * 100),
				a)
	else --hsl|v(a)
		return string.format(
			#fmt == 4 and '%s(%d,%.2g,%.2g,%.2g)' or '%s(%d,%.2g,%.2g)',
				fmt, round(x), y, z, a)
	end
end

--color object ---------------------------------------------------------------

local color = {}

--new([space, ]x, y, z[, a])
--new([space, ]'str')
--new([space, ]{x, y, z[, a]})
local function new(space, x, y, z, a)
	if not (type(space) == 'string' and x) then --shift args
		space, x, y, z, a = 'hsl', space, x, y, z
	end
	local h, s, L
	if type(x) == 'string' then
		h, s, L, a = parse(x, 'hsl')
	else
		if type(x) == 'table' then
			x, y, z, a = x[1], x[2], x[3], x[4]
		end
		h, s, L, a = convert('hsl', space, clamp(space, x, y, z, a))
	end
	local c = {
		h = h, s = s, L = L, a = a,
		__index = color,
		__tostring = color.__tostring,
		__call = color.__call,
	}
	return setmetatable(c, c)
end

local function new_with(space)
	return function(...)
		return new(space, ...)
	end
end

function color:__call() return self.h, self.s, self.L, self.a end
function color:hsl() return self.h, self.s, self.L end
function color:hsla() return self.h, self.s, self.L, self.a or 1 end
function color:hsv() return convert('hsv', 'hsl', self:hsl()) end
function color:hsva() return convert('hsv', 'hsl', self:hsla()) end
function color:rgb() return convert('rgb', 'hsl', self:hsl()) end
function color:rgba() return convert('rgb', 'hsl', self:hsla()) end
function color:convert(space) return convert(space, 'hsl', self:hsla()) end
function color:format(fmt) return format(fmt, 'hsl', self()) end

function color:__tostring()
	return self:format'#'
end

function color:hue_offset(delta)
	return new(self.h + delta, self.s, self.L)
end

function color:complementary()
	return self:hue_offset(180)
end

function color:neighbors(angle)
	local angle = angle or 30
	return self:hue_offset(angle), self:hue_offset(360-angle)
end

function color:triadic()
	return self:neighbors(120)
end

function color:split_complementary(angle)
	return self:neighbors(180-(angle or 30))
end

function color:desaturate_to(saturation)
	return new(self.h, saturation, self.L)
end

function color:desaturate_by(r)
	return new(self.h, self.s*r, self.L)
end

function color:lighten_to(lightness)
	return new(self.h, self.s, lightness)
end

function color:lighten_by(r)
	return new(self.h, self.s, self.L*r)
end

function color:bw(whiteL)
	return new(self.h, self.s, self.L >= (whiteL or .5) and 0 or 1)
end

function color:variations(f, n)
	n = n or 5
	local results = {}
	for i=1,n do
	  table.insert(results, f(self, i, n))
	end
	return results
end

function color:tints(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L + (1-color.L)/n*i)
	end, n)
end

function color:shades(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L - (color.L)/n*i)
	end, n)
end

function color:tint(r)
	return self:lighten_to(self.L + (1-self.L)*r)
end

function color:shade(r)
	return self:lighten_to(self.L - self.L*r)
end

function color:fade(mnt)
    return self:lighten_to(mnt):desaturate_by((mnt * mnt))
end

function color:fade_by(mnt)
    return self:lighten_by(mnt):desaturate_by((mnt * mnt))
end

function color:with_alpha(a)
    return new(self.h, self.s, self.L, a)
end

function color:native()
	local r,g,b = self:rgb()
	return reaper.ColorToNative(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

--module ---------------------------------------------------------------------

local color_module = {
	clamp = clamp,
	convert = convert,
	parse = parse,
	format = format,
	hsl = new_with'hsl',
	hsv = new_with'hsv',
	rgb = new_with'rgb',
}

function color_module:__call(...)
	return new(...)
end

setmetatable(color_module, color_module)

--demo -----------------------------------------------------------------------

return color_module
end
,
Graphics = function()
local color = require 'color'
local rea = require 'rea'

local Graphics = class()

function Graphics:create()
    local self = {
        alphaOffset = 1,
        x = 0,
        y = 0,
    }
    setmetatable(self, Graphics)
    self:setColor(0,0,0,1)
    return self
end

function Graphics:setFromComponent(comp, slot)

    -- if self.usebuffers then

        self.dest = slot
        self.a = 1
        gfx.mode = 0
        gfx.setimgdim(self.dest, -1, -1)
        gfx.setimgdim(self.dest, comp.w, comp.h)
        -- self.x = 0
        -- self.y = 0
        gfx.dest = self.dest

    -- end

    -- comp:paint(self)

    -- self.x = comp:getAbsoluteX()
    -- self.y = comp:getAbsoluteY()
    -- self.alphaOffset = comp:getAlpha()

end



function Graphics:loadColors()
    gfx.r = self.r
    gfx.g = self.g
    gfx.b = self.b
    gfx.a = self.a
end



function Graphics:setColor(r, g, b, a)

    if type(r) == 'table' then
        self:setColor(r:rgba())
    else
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    end

end

function Graphics:circle(x, y, r, fill, aa)
    self:loadColors()
    gfx.circle(self.x + x, self.y + y, r, fill, aa)
end

function Graphics:drawImage(slot, x, y, scale)

    self:loadColors()
    gfx.x = x
    gfx.y = y

    gfx.blit(slot, scale or 1, 0)

end

function Graphics:drawText(text, x, y, w, h)
    self:loadColors()
    gfx.x = self.x + x
    gfx.y = self.y + y

    gfx.drawstr(text, 1 | 4 | 256, gfx.x + w , gfx.y + h)
end

function Graphics:drawFittedText(text, x, y, w, h, ellipes)
    ellipes = ellipes or '...'

    local elLen = gfx.measurestr(ellipes)
    local finalLen = gfx.measurestr(text)

    if finalLen > w then
        while text:len() > 0 and ((finalLen + elLen) > w) do
            text = text:sub(0, -2)
            finalLen = gfx.measurestr(text)
        end

        text = text .. ellipes
    end

    self:drawText(text, x, y, w, h)

end

function Graphics:roundrect(x, y, w, h, r, fill, aa)

    self:loadColors()


    r = math.ceil(math.min(math.min(w,h)/2, r))

    if fill then

        self:rect(x, y + r, w, h - 2 * r, fill)

        self:rect(x+r, y , w- 2*r, r, fill)
        self:rect(x+r, y + h - r , w- 2*r, r, fill)

        gfx.dest = 0

        gfx.setimgdim(0, -1, -1)
        gfx.setimgdim(0, r * 2, r * 2)
        gfx.circle(r, r, r, fill, aa)
        gfx.dest = self.dest

        gfx.blit(0, 1, 0, 0, 0, r, r, self.x, self.y)
        gfx.blit(0, 1, 0, r, 0, r, r, self.x + w - r, self.y)
        gfx.blit(0, 1, 0, 0, r, r, r, self.x, self.y + h - r)

        gfx.blit(0, 1, 0, r, r, r, r, self.x + w - r, self.y + h - r)

    else
        gfx.roundrect(self.x + x, self.y + y, w, h, r*2, aa)
    end
end

function Graphics:rect(x, y, w, h, fill)
    self:loadColors()
    gfx.rect(self.x + x, self.y + y, w, h, fill)
end


return Graphics
end
,
Track = function()
local rea = require 'rea'
local Send = require 'Send'
local Plugin = require 'Plugin'
local Watcher = require 'Watcher'
local Collection = require 'Collection'
local TrackState = require 'TrackState'

local color = require 'color'
local colors = require 'colors'
local _ = require '_'

local Track = class()

-- static --

Track.metaMatch = 'TRACK:({.*})'

function Track.getSelectedTrack()
    if nil == Track.selectedTrack then
        local track = reaper.GetSelectedTrack(0,0)
        Track.selectedTrack = track and Track:create(track)
    end

    return Track.selectedTrack
end

function Track.onStateChange()
    _.forEach(Track.getAllTracks(), function(track)
        track:defer()
    end)
end

function Track.deferAll()

    Track.selectedTrack = nil
    Track.selectedTracks = nil
    Track.focusedTrack = nil
    local current = Track.getAllTracks(true)
    if Track.tracks ~= current then
        Track.tracks = current
    end

end

Track.trackMap = {}

function Track.getTrackMap()
    Track.getAllTracks()
    return Track.trackMap
end

function Track.getFocusedTrack()
    if nil == Track.focusedTrack then
        local track = reaper.GetMixerScroll()
        Track.focusedTrack = track and Track:create(track)
    end

    return Track.focusedTrack
end

function Track.getSelectedTracks(live)
    if nil == Track.selectedTracks or live then
        Track.selectedTracks = {}
        for i=0, reaper.CountSelectedTracks(0)-1 do
            local track = Track:create(reaper.GetSelectedTrack(0,i))
            table.insert(Track.selectedTracks, track)
        end
        Track.selectedTracks = Collection:create(Track.selectedTracks)
    end

    return Track.selectedTracks
end

function Track.setSelectedTracks(tracks)
    _.forEach(Track.getAllTracks(), function(track) track:setSelected(false) end)
    _.forEach(tracks, function(track)
        if track:exists() then
            track:setSelected(true)
        end
    end)

    Track.deferAll()
end

function Track.getAllTracks(live)
    if live then
        local tracks = _.map(rea.getAllTracks(), function(t) return Track:create(t) end)
        return Collection:create(tracks)
    elseif nil == Track.tracks then
        Track.tracks = Track.getAllTracks(true)
    end
    return Track.tracks
end

--function Track.getUniqueName()

function Track.get(index)
    local track = (index >= 0) and reaper.GetTrack(0, index);
    return track and Track:create(track)
end

function Track.insert(index)
    index = index == nil and reaper.CountTracks(0) or index
    reaper.InsertTrackAtIndex(index, true)
    return Track.get(index)
end

Track.watch = {
    selectedTrack = Watcher:create(Track.getSelectedTrack),
    selectedTracks = Watcher:create(Track.getSelectedTracks),
    tracks = Watcher:create(Track.getAllTracks),
    focusedTrack = Watcher:create(Track.getFocusedTrack)
}

-- obj --

function Track:create(track)

    assertDebug(not track, 'cant create empty track wrapper')

    local wrapper = _.find(Track.tracks, function(t) return t.track == track end)

    if not wrapper then
        local guid = reaper.GetTrackGUID(track)
        local self = {}
        setmetatable(self, Track)
        self.track = track
        self.guid = guid

        Track.trackMap[guid] = self

        self.listeners = {}
        wrapper = self

    end

    return wrapper
end

function Track:createSlave(name, indexOffset)
    local t = Track.insert(self:getIndex() + indexOffset)
    self:setName(self:getName() or self:getDefaultName())

    return t:setName(self:getName() .. ':' .. name)
end

function Track:onChange(listener)
    table.insert(self.listeners, listener)
end

function Track:triggerChange(message)
    _.forEach(self.listeners, function(listener)
        listener(message)
    end)
    return self
end

-- get

function Track:defer()
    self.state = nil
end

function Track:isAux()
    return self:getName() and self:getName():startsWith('aux:')
end

function Track:exists()

    return _.find(Track.getAllTracks(true), self)
    -- body
end

function Track:isLA()
    return self:getName() and self:getName():endsWith(':la')
end

function Track:isMidiTrack()
    local instrument = self:getInstrument()
    return not instrument
end

function Track:getMetaKey(extra)
    return 'TRACK:'..self.guid..':META:' .. extra
end

function Track:setMeta(name, value)

    reaper.SetProjExtState(0, 'D3CK', self:getMetaKey(name), value)
    return self

end

function Track:getMeta(name, value)
    local suc, res = reaper.GetProjExtState(0, 'D3CK', self:getMetaKey(name))
    return suc > 0 and res or nil
end

function Track:isAudioTrack()
    local instrument = self:getInstrument()
    return instrument
end

function Track:focus()
    reaper.SetMixerScroll(self.track)
    rea.refreshUI()

    return self
end

function Track:isFocused()
    return reaper.GetMixerScroll() == self.track
end

function Track:isSelected()
    return _.some(Track.getSelectedTracks(), function(track)
        return track == self and true or false
    end)
end

function Track:choose()
    self:focus()
    self:setSelected(1)
    return self
end

function Track:setSelected(select)
    if select == 1 then
        reaper.SetOnlyTrackSelected(self.track)
    else
        reaper.SetTrackSelected(self.track, select == nil and true or select)
    end
    return self
end

function Track:getPrev()
    return Track.get(self:getIndex()-2)
end

Track.stringMap = {
    name = 'P_NAME',
    icon = 'P_ICON'
}

Track.valMap = {
    arm = 'I_RECARM',
    toParent = 'B_MAINSEND',
    lock = 'C_LOCK',
    tcp = 'B_SHOWINTCP',
    mcp = 'B_SHOWINMIXER',
    mute = 'B_MUTE',
    solo = 'I_SOLO'
}

function Track:getDefaultName()
    return 'Track ' .. tostring(self:getIndex())
end

function Track:getName()
    local res, name = reaper.GetTrackName(self.track, '')
    -- return res and name ~= self:getDefaultName() and name or nil
    return res and name or nil
end

function Track:setLocked(locked)

    self:setState(self:getState():withLocking(locked))

    return self
end

function Track:isLocked()
    return self:getState():isLocked()
end

function Track:getValue(key)
    if Track.stringMap[key] then
        local res, val = reaper.GetSetMediaTrackInfo_String(self.track, Track.stringMap[key], '', false)
        return res and val or nil
    elseif Track.valMap[key] then
        return reaper.GetMediaTrackInfo_Value(self.track, Track.valMap[key])
    end
end

function Track:setValue(key, value)
    self:setValues({[key] = value})
    return self
end

function Track:setValues(vals)

    for k, v in pairs(vals or {}) do
        if Track.stringMap[k] then
            reaper.GetSetMediaTrackInfo_String(self.track, Track.stringMap[k], v, true)
        elseif Track.valMap[k] then
            reaper.SetMediaTrackInfo_Value(self.track, Track.valMap[k], v == true and 1 or (v == false and 0) or v)
        end
    end

    return self

end

function Track:getInstrument()
    local inst = reaper.TrackFX_GetInstrument(self.track)
    return inst >= 0 and Plugin:create(self, inst) or nil
end

function Track:remove()
    reaper.DeleteTrack(self.track)
    Track.trackMap[self.guid] = nil
    Track.deferAll()
end

function Track:getFxList()

    local ignored = {
        'DrumRack',
        'TrackTool'
    }
    local inst = self:getInstrument()
    local res = {}
    for i = inst and inst:getIndex() or 0, reaper.TrackFX_GetCount(self.track) - 1 do
        table.insert(res, Plugin:create(self, i))
    end
    return res
end

function Track:getState(live)
    if live or not self.state then
        local success, state = reaper.GetTrackStateChunk(self.track, '', false)
        self.state = TrackState:create(state)
    end
    return self.state
end

function Track:__tostring()
    return self:getName() .. ' :: ' .. tostring(self.track)
end

function Track:setState(state)
    self.state = state
    reaper.SetTrackStateChunk(self.track, tostring(state), false)
    return self
end

function Track:removeReceives()
    for i=0,reaper.GetTrackNumSends(self.track, -1) do
        reaper.RemoveTrackSend(self.track, -1, i)
    end
    return self
end

function Track:clone()
    local index = self:getIndex()
    reaper.InsertTrackAtIndex(index, false)
    local track = Track:create(reaper.GetTrack(0, index))
    track:setState(self:getState())
    return track
end

function Track:hasMedia()
    return reaper.CountTrackMediaItems(self.track) > 0
end

function Track:getOutput()
    local toParent = self:getValue('toParent') > 0
    return not toParent and _.some(self:getSends(), function(send)
        return send:getMode() == 0 and send:getTargetTrack()
    end)
end

function Track:isBusTrack()

    local isDrumRack = self:getFx('DrumRack')
    local isContentTrack = self:getInstrument() or self:hasMedia()
    local recs = self:getReceives()
    local hasBusRecs = (_.size(recs) == 0 or _.some(recs, function(rec)
        return rec:isBusSend()
    end))
    local sends = self:getSends()
    -- local hasMidiSends = _.some(sends, function(send)
    --     return send:isMidi() and not send:isAudio()
    -- end)
    return hasBusRecs and not isContentTrack and not isDrumRack

end

function Track:getLATracks()
    return _.map(self:getSends(), function(send)
        return send:getMode() == 3 and send:getTargetTrack() or nil
    end)
end

function Track:createLATrack()

    if not self:getName() then
        self:setName(self:getDefaultName())
    end

    local la = Track.insert(self:getIndex())

    la:setVisibility(false, true)
            :routeTo(self:getOutput())
            :setColor(colors.la)
            :setIcon(self:getIcon() or 'fx.png')
            :setName(self:getName() .. ':la')

    self:createSend(la)
                :setMidiBusIO(-1, -1)
                :setMode(3)

    return la
end

function Track:isSlave()
    return self:getName():includes(':')
end

function Track:getSlaves()
end

function Track:getMaster()
end


function Track:createMidiSlave()

    local slave = Track.insert(self:getIndex())

        slave:setVisibility(true, false)
            :setIcon(self:getIcon() or 'midi.png')
            :setName(self:getName() .. ':midi')
            :createSend(self, true)
                :setAudioIO(-1, -1)

    return slave
end

function Track:getMidiSlaves()
    return _.map(self:getReceives(), function(rec)
        if rec:isMidi() then
            return rec:getSourceTrack()
        end
    end)
end

function Track:getColor()
    local c = reaper.GetTrackColor(self.track)

    local r, g, b = reaper.ColorFromNative(c)

    return c > 0 and color.rgb(r / 255, g / 255, b / 255) or nil
end

function Track:setColor(c)
    reaper.SetTrackColor(self.track, c:native())
    return self
end

function Track:isRoutedTo(target)

end

function Track:routeTo(target)
    if not target then
        self:setValue('toParent', true)
    else
        if not self:sendsTo(target) then
            self:createSend(target, true)
        end
    end
    return self
end

function Track:removeSend(target)
    _.forEach(self:getSends(), function(send)
        if send:getTargetTrack() == target then
            send:remove()
        end
    end)
    return self
end

function Track:sendsTo(track)
    return _.some(self:getSends(), function(send)
        return send:getTargetTrack() == track
    end)
end


function Track:getSends()
    local sends = {}

    for i = 0, reaper.GetTrackNumSends(self.track, 0)-1 do
        table.insert(sends, Send:create(self.track, i))
    end

    return sends
end

function Track:getReceives()
    local recs = {}
    for i = 0, reaper.GetTrackNumSends(self.track, -1)-1 do
        table.insert(recs, Send:create(self.track, i, -1))
    end
    return recs
end

function Track:receivesFrom(otherTrack)
    return _.some(self:getReceives(), function(rec)
        return rec:getSourceTrack().track == otherTrack.track
    end)
end

function Track:isParentOf(track)
    return track:getParent() and track:getParent().track == self.track
end

function Track:getParent()
    local parent = reaper.GetParentTrack(self.track)
    return parent and Track:create(parent)
end

function Track:getChildren()
    return _.map(rea.getChildTracks(self.track), function(track) return Track:create(track) end)
end

function Track:getIcon(name)
    local p = self:getValue('icon')
    return p and p:len() > 0 and p or nil
end

function Track:setIcon(name)
    self:setValue('icon', name)
    return self
end

function Track:setType(type)
    return self:setMeta('type', type)
end

function Track:getType()
    return self:getMeta('type')
end

function Track:autoName()
    if not self:getName() then
        local inst = self:getInstrument()
        if inst then
            self:setName(inst:getName())
        end
    end
    return self
end

function Track:setName(name)
    self:setValue('name', name)
    return self
end

function Track:validatePlugins()

    local current = self:getPlugins(true)
    if not _.equal(current, self.pluginCache) then
        self.pluginCache = current
        _.forEach(current, function(plugin)
            plugin:reconnect()
        end)
    end
    return self
end

function Track:getPlugins(live)

    if live then
        local res = {}

        for i = 0, reaper.TrackFX_GetCount()-1 do
            table.insert(res, Plugin:create(self, i))
        end

        return res
    else
        return self.pluginCache or {}
    end
end

function Track:getFx(name, force, rec)
    if name == false then
        local success, input = reaper.GetUserInputs("name", 1, "name", "")
        if success then
            name = input
        end
    end
    if not name then return nil end

    local index = reaper.TrackFX_AddByName(self.track, name, rec or false, force and 1 or 0)

    return index >= 0 and Plugin:create(self, index + (rec and 0x1000000 or 0)) or nil
end

function Track:addFx(name, input)
    return reaper.TrackFX_AddByName(self.track, name, input or false, 1)
end

function Track:createSend(target, sendOnly)
    local cindex = reaper.CreateTrackSend(self.track, target.track or target)
    if sendOnly then self:setValue('toParent', false) end
    return Send:create(self.track, cindex)
end

function Track:getFirstChild()
    return _.first(self:getChildren())
end

function Track:getIndex()
    local tracks = rea.getAllTracks()
    for k, v in pairs(tracks) do
        if v == self.track then return k end
    end
end

function Track:setVisibility(tcp, mcp)
    reaper.SetMediaTrackInfo_Value(self.track, 'B_SHOWINTCP', tcp and 1 or 0)
    reaper.SetMediaTrackInfo_Value(self.track, 'B_SHOWINMIXER', mcp and 1 or 0)
    rea.refreshUI()
    return self
end

function Track:findChild(needle)
    return rea.findTrack(needle, _.map(self:getChildren(), function(track) return track.track end))
end

function Track:setFolderState(val)
    reaper.SetMediaTrackInfo_Value(self.track, 'I_FOLDERDEPTH', val or 0)
    return self
end

function Track:getFolderState()
    return reaper.GetMediaTrackInfo_Value(self.track, 'I_FOLDERDEPTH')
end

function Track:isFolder()
    return self:getFolderState() == 1
end

function Track:setParent(newParent)

    if not newParent then return end

    local prevSelection = Track.getSelectedTracks()

    local lastChild = newParent:isFolder() and _.last(newParent:getChildren())
    Track.setSelectedTracks({self})
    if lastChild then
        reaper.ReorderSelectedTracks(lastChild:getIndex(), 2)
    else
        reaper.ReorderSelectedTracks(newParent:getIndex(), 1)
    end

    Track.setSelectedTracks(prevSelection)

    return self

end

function Track:addChild(options)
    self:setFolderState(1)

    local lastChild = _.last(self:getChildren())
    lastChild = lastChild and Track:create(lastChild)
    local index = (lastChild or self):getIndex()

    reaper.InsertTrackAtIndex(index, true)
    local track = reaper.GetTrack(0, index)
    track = Track:create(track)

    track:setValues(options)
    return track
end

function Track:getTrackTool(force)
    -- local plugin = self:getFx('../Scripts/D3CK/test.jsfx', force or false)
    local plugin = self:getFx('TrackTool', force or false)
    if plugin then plugin:setIndex(0) end
    return plugin
end

function Track:__lt(other)
    return self.getIndex() > other.getIndex()
end

function Track:__eq(other)
    return (other and self.track == other.track)
end

Track.master = Track:create(reaper.GetMasterTrack())

return Track

end
,
Send = function()

local Send = class()

function Send:create(track, index, cat)
    local self = {
        track = track,
        index = index,
        cat = cat == nil and 0 or cat
    }
    setmetatable(self, Send)
    return self
end

function Send:remove()
    reaper.RemoveTrackSend(self.track, self.cat, self.index)
end

function Send:getSourceTrack()
    local Track = require 'Track'
    local source = reaper.BR_GetMediaTrackSendInfo_Track(self.track, self.cat, self.index, 0)
    return Track:create(source)
end

function Send:getMidiSourceChannel()
    return reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, 'I_MIDIFLAGS') & 0xff;
end

function Send:getMidiSourceBus()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_SRCBUS', false, 0)
end

function Send:getMidiTargetBus()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_DSTBUS', false, 0)
end

function Send:getMidiBusses()
    return self:getMidiSourceBus(), self:getMidiTargetBus()
end

function Send:setAudioIO(i, o)

    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_SRCCHAN", i or -1)
    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_DSTCHAN", o or -1)
    return self
end

function Send:getAudioIO()

    local src = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, "I_SRCCHAN", i or -1)
    local dest = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, "I_DSTCHAN", o or -1)
    return src, dest
end

function Send:setMuted(muted)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'B_MUTE', true, (muted == nil and 1) or (muted and 1 or 0))
    return self
end

function Send:isMuted()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'B_MUTE', false, 0) > 0
end

function Send:isAudio()
    return self:getAudioIO() ~= -1
end

function Send:setMode(mode)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', true, mode)
    return self
end

function Send:getMode()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', false, 0)
end

function Send:isBusSend()
    local i , o = self:getAudioIO()
    return i == 0 and o == 0 and self:getMode() == 0
end

function Send:isPreFaderSend()
    return reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_SENDMODE', false, 0) == 3
end

function Send:isMidi()
    return self:getMidiBusses() ~= -1
end

function Send:setMidiBusIO(i, o)

    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_SRCBUS', true, i)
    reaper.BR_GetSetTrackSendInfo(self.track, self.cat, self.index, 'I_MIDI_DSTBUS', true, o)
    return self
end

function Send:setSourceMidiChannel(channel)

    local MIDIflags = reaper.GetTrackSendInfo_Value(self.track, self.cat, self.index, 'I_MIDIFLAGS') & 0xFFFFFF00 | channel
    reaper.SetTrackSendInfo_Value(self.track, self.cat, self.index, "I_MIDIFLAGS", MIDIflags)
    return self
end

function Send:getTargetTrack()
    local Track = require 'Track'
    local target = reaper.BR_GetMediaTrackSendInfo_Track(self.track, self.cat, self.index, 1)
    return Track:create(target)
end

return Send
end
,
Rooms = function()
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
end
,
WatcherManager = function()
local Watcher = require 'Watcher'
local _ = require '_'

local WatcherManager = class()

function WatcherManager:create()
    local self = {
        offs = {},
        watchers = {}
    }
    setmetatable(self, WatcherManager)
    return self
end

function WatcherManager:watch(watcher, callback)
    if getmetatable(watcher) ~= Watcher then
        watcher = Watcher:create(watcher)
        table.insert(self.watchers, watcher)
    else

        table.insert(self.offs, watcher:onChange(callback))
    end
end

function WatcherManager:clear()
    _.forEach(self.offs, function(off) off() end)
    _.forEach(self.watchers, function(watcher) watcher:close() end)
end


function WatcherManager:__gc()
    self:clear()
end

return WatcherManager
end
,
Collection = function()
local _ = require '_'
local Collection = class()

function Collection:create(data)
    local self = {
        data = data
    }
    setmetatable(self, Collection)
    return self
end

function Collection:__eq(other)
    return _.equal(self.data, other.data)
end

function Collection:__len()
    return #self.data
end

function Collection:__pairs()
    return pairs(self.data)
end

function Collection:__ipairs()
    return ipairs(self.data)
end

function Collection:map(call)
    return Collection:create(_.map(self.data, call))
end

function Collection:__index(key)
    return self.data[key]
end


return Collection
end
,
Component = function()
require 'Util'
local Mouse = require 'Mouse'
local Graphics = require 'Graphics'
local WatcherManager = require 'WatcherManager'

local _ = require '_'
local color = require 'color'
local rea = require 'rea'


local Component = class()

Component.componentIds = 1

Component.slots = {}
for i = 1, 1023 do
    Component.slots[i] = false
end



function Component:create(x, y, w, h)

    local self = {
        x = x or 0,
        y = y or 0,
        w = w or 0,
        h = h or 0,
        uislots = {},
        watchers = WatcherManager:create(),
        id = Component.componentIds,
        alpha = 1,
        isComponent = true,
        visible = true,
        children = {},
        mouse = Mouse.capture()
    }

    Component.componentIds = Component.componentIds + 1

    setmetatable(self, Component)

    self:relayout()

    return self
end

function Component:getSlot(name, create)

    if not self.uislots[name] then

        local slot = _.indexOf(Component.slots, name)

        if not slot then

            slot = _.some(Component.slots, function(used, i)
                if not used then
                    Component.slots[i] = name
                    if create then
                        create(i, name)
                    end
                    return i
                end
            end)

            assert(slot, 'out of image slots')
        end

        self.uislots[name] = slot
    end

    assert(self.uislots[name], 'has no slot?')

    return self.uislots[name]
end


function Component:delete(doNotRemote)

    self:triggerDeletion()
    if not doNotRemote then
        self:remove()
    end
end

function Component:triggerDeletion()

    self.watchers:clear()

    self:freeSlot()
    if self.onDelete then self:onDelete() end
    _.forEach(self.children, function(comp)
        comp:triggerDeletion()
    end)
end


function Component:freeSlot()
    _.forEach(self.uislots, function(slot)
        Component.slots[slot] = false
    end)
end

function Component:getAllChildren(results)
    results = results or {}

    for k, child in rpairs(self.children) do
        child:getAllChildren(results)
    end

    table.insert(results, self)

    return results
end

function Component:deleteChildren()
    _.forEach(self.children, function(comp)
        comp:delete()
    end)
end

function Component:interceptsMouse()
    return true
end

function Component:scaleToFit(w, h)

    local scale = math.min(self.w  / w, self.h / h)

    self:setSize(self.w / scale, self.h / scale)

    return self

end

function Component:setAlpha(alpha)
    self.alpha = alpha
end

function Component:getAlpha()
    return self.alpha * (self.parent and self.parent:getAlpha() or 1)
end

function Component:fitToWidth(wToFit)

    self:setSize(wToFit, self.h * wToFit / self.w)
    return self
end

function Component:fitToHeight(hToFit)

    self:setSize(self.w * hToFit / self.h, hToFit)
    return self
end

function Component:clone()

    local comp = _.assign(Component:create(), self)
    setmetatable(comp, getmetatable(self))

    comp.children = _.map(self.children, function(child)
        local clone = child:clone()
        clone.parent = comp
        return clone
    end)
    return comp
end

function Component:canClickThrough()
    return true
end

function Component:isMouseDown()
    return self:isMouseOver() and self.mouse:isButtonDown()
end

function Component:isMouseOver()
    local window
    return
        gfx.mouse_x <= self:getAbsoluteRight() and
        gfx.mouse_x >= self:getAbsoluteX() and
        gfx.mouse_y >= self:getAbsoluteY() and
        gfx.mouse_y <= self:getAbsoluteBottom()
end

function Component:wantsMouse()
    return self.isCurrentlyVisible and (not self.parent or self.parent:wantsMouse())
end

function Component:getAbsoluteX()
    local parentOffset = self.parent and self.parent:getAbsoluteX() or 0
    return self.x + parentOffset
end

function Component:getAbsoluteY()
    local parentOffset = self.parent and self.parent:getAbsoluteY() or 0
    return self.y + parentOffset
end

function Component:getBottom()
    return self.y + self.h
end

function Component:getRight()
    return self.x + self.w
end

function Component:canBeDragged()
    return false
end

function Component:getAbsoluteBottom()
    return self:getAbsoluteY() + self.h
end

function Component:getAbsoluteRight()
    return self:getAbsoluteX() + self.w
end

function Component:getIndexInParent()
    if self.parent then
        for k, v in pairs(self.parent.children) do
            if v == self then return k end
        end
    end
end

function Component:isDisabled()
    return self.disabled or (self.parent and self.parent:isDisabled())
end

function Component:setVisible(vis)
    if self.visible ~= vis then
        self.visible = vis
        self:repaint()
    end
end

function Component:isVisible()
    return self.visible and (not self.parent or self.parent:isVisible()) and self:getAlpha() > 0
end

function Component:updateMousePos(mouse)
    self.mouse.cap = gfx.mouse_cap
    self.mouse.mouse_wheel = mouse.mouse_wheel
    self.mouse.x = mouse.x - self:getAbsoluteX()
    self.mouse.y = mouse.y - self:getAbsoluteY()
end

function Component:setSize(w,h)

    w = w == nil and self.w or w
    h = h == nil and self.h or h

    if self.w ~= w or self.h ~= h then

        self.w = w
        self.h = h

        self:relayout()
    end

end

function Component:relayout()
    self.needsLayout = true
    self:repaint()
end

function Component:setPosition(x,y)
    self.x = x
    self.y = y
end

function Component:setBounds(x,y,w,h)
    self:setPosition(x,y)
    self:setSize(w, h)
end

function Component:getWindow()
    if self.window then return self.window
    elseif self.parent then return self.parent:getWindow()
    end
end

function Component:repaint(children)
    self.needsPaint = true

    if children then
        _.forEach(self.children, function(child)
            child:repaint(children)
        end)
    end

    if self:isVisible() then
        local win = self:getWindow()
        if win then
            win.repaint = win.repaint or true
        end
    end
end

function Component:resized()
    _.forEach(self.children, function(child)
        child:setSize(self.w, self.h)
    end)
end


function Component:evaluate(g, dest, x, y)

    x = x or 0
    y = y or 0

    dest = dest or -1
    g = g or Graphics:create()

    self.isCurrentlyVisible = self:isVisible()
    if not self.isCurrentlyVisible then return end

    if self.needsLayout and self.resized then
        self:resized()
        self.needsLayout = false
    end

    local doPaint = (self.paint or self.paintOverChildren) and (self.needsPaint or self:getWindow().repaint == 'all')

    if self.paint then
        local pslot = self:getSlot('component:' .. tostring(self.id) .. ':paint')
        if doPaint then
            g:setFromComponent(self, pslot)
            self:paint(g)
        end

        gfx.dest = dest
        gfx.x = x
        gfx.y = y
        gfx.a = self:getAlpha()
        gfx.blit(pslot, 1, 0)

    end

    self:evaluateChildren(g, dest, x, y)

    if self.paintOverChildren then

        local poslot = self:getSlot('component:' .. tostring(self.id) .. ':paintOverChildren')
        if doPaint then
            g:setFromComponent(self, poslot)
            self:paintOverChildren(g)
        end

        gfx.dest = dest
        gfx.a = self:getAlpha()
        gfx.x = x
        gfx.y = y
        gfx.blit(poslot, 1, 0)
    end

    self.needsPaint = false
end

function Component:evaluateChildren(g, dest, x, y)
    _.forEach(self.children,function(comp)
        assert(comp.parent == self, 'comp has different parent')
        comp:evaluate(g, dest, x + comp.x, y + comp.y)
    end)
end

function Component:addChildComponent(comp, key, doNotLayout)
    comp.parent = self
    if key then
        self.children[key] = comp
    else
        table.insert(self.children, comp)
    end
    self:relayout()

    return comp
end

function Component:remove()
    if self.parent then
        _.removeValue(self.parent.children, self)
        self.parent = nil
    end
    return self
end



return Component
end
,
WindowApp = function()
local App = require 'App'
local Window = require 'Window'
local Component = require 'Component'
local Watcher = require 'Watcher'
local _ = require '_'

local WindowApp = class(App)

function WindowApp:create(name, component)

    local self = App:create(name)
    self.component = component
    setmetatable(self, WindowApp)

    return self

end

function WindowApp:getProfileData()
    return {
        watchers = {
            num = #_.filter(Watcher.watchers, function(w)
                return (#w.listeners) > 0
            end)
        },
        window = {
            numComps = #self.window.component:getAllChildren(),
            paints = self.window.paints
        },
        component = {
            numComps = Component.numInstances,
            numCompsInMem = Component.numInMem,
            noSlots = #_.filter(Component.slots, function(slot) return slot end),
            -- slots = _.filter(Component.slots, function(slot) return slot end)
        }
    }
end

function WindowApp:onStart()
    self.window = Window.openComponent(self.name, self.component)
    self.window.onClose = function()
        self:stop()
    end
end

return WindowApp
end
,
MidSide = function()
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
end
,
State = function()
local _ = require '_'
local rea = require 'rea'

local State = {}
local cat = 'D3CK'


State.global = {

    set = function(key, value)
        if type(value) == 'table' then
            _.forEach(value, function (value, subkey)
                reaper.SetExtState(cat, key .. '_' .. subkey, value, true)
            end)
        else
            reaper.SetExtState(cat, key, value, true)
        end
    end,

    get = function(key, default, multi)
        default = default or {}
        if multi then
            _.forEach(multi, function(subkey)
                local k = key .. '_' .. subkey
                default[subkey] = State.global.get(k, default[subkey])
            end)
            return default
        else
            return reaper.HasExtState(cat, key) and reaper.GetExtState(cat, key) or default
        end
    end
}

return State
end
,
Text = function()
local Component = require 'Component'
local color = require 'color'

local rea = require 'rea'

local Text = class(Component)

function Text:create(text, ...)

    local self = Component:create(...)
    self.text = text or ''
    self.color = color.rgb(1,1,1)
    setmetatable(self, Text)
    return self

end

function Text:getColor()
    local c = self.color
    if self:isDisabled() then c = c:fade(0.2) end
    return c
end

function Text:paint(g)

    local c = self:getColor()
    local text = self:getText()
    if text and text:len() then
        local padding = 5
        g:setColor(c:lighten_to(1-round(c.L)):desaturate_to(0))
        g:drawFittedText(text, padding ,0 , self.w - padding * 2, self.h)
    end

end

function Text:getText()
    return self.text
end

return Text
end
,
Menu = function()

local rea = require 'rea'
local Menu = class()
local _ = require '_'

function Menu:create(options)
    local self = {
        items = {}
    }

    setmetatable(self, Menu)

    _.forEach(options, function(opt, key)
        if type(opt) == 'function' then opt = {callback = opt} end
        self:addItem(opt.name or key, opt)
    end)

    return self
end

function Menu:__gc()

    -- assert(self.wasShown)

end

function Menu:show()

    self.wasShown = true
    local map = {}
    local menu = self:renderItems(self.items, map)

    gfx.x = gfx.mouse_x
    gfx.y = gfx.mouse_y
    local res = gfx.showmenu(menu)

    if res > 0 and map[res] then
        return map[res]()
    end

end

function Menu:renderItems(items, map)

    local isSubMenu = map ~= nil
    map = map or {}
    items = items or self.items

    local flat = {}

    for key, item in pairs(items) do
        if item == false then --seperator
            table.insert(flat, '')
        elseif type(item.children) == 'table' then
            local menu = '>' .. item.name .. '|' .. self:renderItems(item.children, map)
            table.insert(flat, menu)
        else
            local name = item.name
            if item.getToggleState and item:getToggleState() or item.checked then
                name = '!' .. name
            end

            if item.isDisabled and item:isDisabled() or item.disabled then
                name = '#' .. name
            end

            table.insert(flat, name)
            if type(item.callback) == 'function' then
                if item.transaction then
                    table.insert(map, function()
                        rea.transaction(item.transaction, item.callback)
                    end)
                else
                    table.insert(map, item.callback)
                end
            else
                table.insert(map, function()end)
            end
        end
    end

    if isSubMenu then
        flat[#flat] = '<' .. flat[#flat]
    end

    return _.join(flat, '|')

end

function Menu:addItem(name, data, transaction)

    if type(name) == 'table' then data = name end

    local item = {
        name =  name,
        callback = type(data) == 'function' and data,
        children = getmetatable(data) == Menu and data.items,
        transaction = transaction
    }

    if type(data) == 'table' then
        _.assign(item, data)
    end

    table.insert(self.items, item)
end

function Menu:addSeperator()
    table.insert(self.items, false)
end

return Menu
end
,
App = function()
local Window = require 'Window'
local Track = require 'Track'
local Plugin = require 'Plugin'
local Watcher = require 'Watcher'
local Profiler = require 'Profiler'
local rea = require 'rea'

local App = class()

function App:create(name)
    local self = {}
    assert(type(name) == 'string', 'app must have a name')

    self.name = name

    setmetatable(self, App)

    return self
end

function App:defer()

    local res, err = xpcall(function()

        Track.deferAll()
        Plugin.deferAll()
        Watcher.deferAll()

        if Window.currentWindow then
            Window.currentWindow:defer()
        end

    end, debug.traceback)

    if not res and self.options.debug then
        local context = {reaper.get_action_context()}
        rea.logPin('context', context)
        rea.logPin('error', err)
    else
        if self.running then
            reaper.defer(function()
                self:defer()
            end)
        end

    end

end

function App:stop()
    self.running = false
end

function App:start(options)

    options = options or {}
    options.debug = true
    self.running = true
    self.options = options
    App.current = self

    if self.onStart then self:onStart() end

    if options.profile then

        options.debug = true
        local def = self.defer
        profiler = Profiler:create({'gfx', 'reaper'})

        self.defer = function()

            local log = profiler:run(function() def(self) end, 1)

            if self.getProfileData then
                log.data = self:getProfileData()
            end

            rea.logPin('profile', log)

        end
    end

    if options.debug then
        reaper.atexit(function()
            rea.log('exited')
        end)

    end

    self:defer()

end


return App
end
,
rea = function()
require 'Util'
local _ = require '_'

local ENSURE_MIDI_ITEMS,IMPORT_LYRICS,EXPORT_LYRICS=42069,42070,42071

local function getFxByName(track, name, recFX)
    local offset = recFX and 0x1000000 or 0
    for index = reaper.TrackFX_GetRecCount(track)-1, 0, -1 do
        local success, fxName = reaper.TrackFX_GetFXName(track, offset + index, 1)
        if string.match(fxName, name) then return index + offset end
    end
end

local function getParamByName(track, fx, name)
    for index = reaper.TrackFX_GetNumParams(track, fx)-1, 0, -1 do
      local success, paramName = reaper.TrackFX_GetParamName(track, fx, index, 1)
      if string.match(paramName, name) then return index end
    end
end

local function log(msg, deep)
    if 'table' == type(msg) then
        msg = dump(msg, deep)
    elseif 'string' ~= type(msg) then
        msg = tostring(msg)
    end
    if msg and type(msg) == 'string' then
        reaper.ShowConsoleMsg(msg .. '\n')
    end
end

local logCounts = {}
local logPins = {}
local error = nil

local function showLogs()
    reaper.ClearConsole()

    if error then
        log(error)
    end
    if _.size(logCounts) > 0 then
        log(logCounts)
    end
    if _.size(logPins) > 0 then
        log(logPins)
    end
end

local function logCount(key, mnt)
    key = tostring(key)
    logCounts[key] = (logCounts[key] or 0) + (mnt or 1)
    showLogs()
end


local function logPin(key, ...)
    key = tostring(key)
    logPins[key] = dump({...})
    showLogs()
end

local function logError(key)
    error = key
    showLogs()
end





local function logOnly(msg, deep)
    showLogs()
    log(msg, deep)
end

local function findRegionOrMarkers(needle)
    local success, markers, regions = reaper.CountProjectMarkers()
    local total = markers + regions
    local result = {}
    for i=0, total do
        local success, region, pos, rgnend, name = reaper.EnumProjectMarkers(i)
        if name:find(needle) then
            table.insert(result, i)
        end
    end
    return result
end

local function getAllTracks()
    local tracks = {}
    local num = reaper.GetNumTracks()
    for i=0, num-1 do
        local track = reaper.GetTrack(0, i)
        table.insert(tracks, track)
    end
    return tracks
end

local function findTrack(needle, collection)
    collection = collection or getAllTracks()
    for k, track in pairs(collection) do
        local success, name = reaper.GetTrackName(track, '')
        if name:find(needle) then
            return track
        end
    end
end

local function getChildTracks(needle)
    local num = reaper.GetNumTracks()
    local tracks = {}
    for i=0, num-1 do
        local track = reaper.GetTrack(0, i)
        local parent = reaper.GetParentTrack(track, '')
        if needle == parent then
            table.insert(tracks, track)
        end
    end
    return tracks
end

local function prompt(name, value)
    local suc, res = reaper.GetUserInputs(name, 1, name, value or '')
    return suc and res or nil
end

local function getFiles(dir, filter)
    local files = {}

    local i = 0
    local file = true
    while file do
        file = reaper.EnumerateFiles(dir, i)
        i = i + 1

        if file then
            if not filter or filter(file) then
                table.insert(files, dir .. '/' .. file)
            end
        end
    end

    return files
end

local function getDir(dir, filter)

    local files = {}

    local i = 0
    local folder = true
    while folder do
        folder = reaper.EnumerateSubdirectories(dir, i)
        i = i + 1
        if folder then
            if not filter or filter(folder) then
                table.insert(files, dir .. '/' .. folder)
            end
        end
    end

    return files
end

local function findFiles(dir, files, filter)
    files = files or {}

    local i = 0
    local file = true
    while file do
        file = reaper.EnumerateFiles(dir, i)
        i = i + 1

        if file then
            if not filter or filter(file) then
                table.insert(files, dir .. '/' .. file)
            end
        end
    end

    local i = 0
    local folder = true
    while folder do
        folder = reaper.EnumerateSubdirectories(dir, i)
        i = i + 1
        if folder then findFiles(dir .. '/' .. folder, files, filter) end
    end

    return files
end

local function findIcon(name)
    local name = name:lower()
    local path = reaper.GetResourcePath() .. '/Data/track_icons'
    local files = findFiles(path, {}, function(path)
        return path:lower():includes(name)
    end)

    return _.first(files)
end


local function setTrackAttrib(track, name, value)
    local success, state = reaper.GetTrackStateChunk(track, '', 0 , false)
    local settings = state:split('\r\n')
    for row, line in pairs(settings) do
        if line:startsWith(name) then
            settings[row] = name .. ' ' .. value
        end
    end
    state = _.join(settings, '\n')
    reaper.SetTrackStateChunk(track, state, false)
end

local function setTrackVisible(track, tcp, mcp)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', tcp == true and 1 or 0)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', mcp == true and 1 or 0)
end

local function transaction(name, action)
    reaper.Undo_BeginBlock()
    local res = action()
    if res ~= false then reaper.Undo_EndBlock(name, -1) end
end

local function ensureTrack(name, options)
    if typeof(options) ~= 'table' then options.hide = options end

    local index = options.index or 0
    local existing = findTrack(name)
    if not existing then
        reaper.InsertTrackAtIndex(0, false)
        log(existing)
        existing = reaper.GetTrack(0, 0)
        log(existing)
        setTrackAttrib(existing, 'NAME', name)
        if options.hide then
            log(existing)
            setTrackVisible(existing, 0, 0)
        end
    end
    return existing
end

local function ensureContentLength(track, ending, start)
    local st = reaper.TimeMap2_beatsToTime(0,0.0, start or 0)
    local et = reaper.TimeMap2_beatsToTime(0,0.0, ending)
    local ost,oet = reaper.GetSet_LoopTimeRange2(0,false,false,0.0,0.0,false)
    reaper.GetSet_LoopTimeRange2(0,true,false,st,et,false)
    reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",1)
    reaper.Main_OnCommandEx(ENSURE_MIDI_ITEMS,0,0)
    reaper.GetSet_LoopTimeRange2(0,true,false,ost,oet,false) -- restore
end

local function setLyrics(text, track)
    track = track or ensureTrack('lyrics', true)
    local lines = text:split('\r\n')
    local map = {}
    local blockData

    for i, line in pairs(lines) do
        local trimmed = line:trim()
        if trimmed:startsWith('[') then

            local block = trimmed:sub(2, trimmed:len() - 1):split('|')
            local blockName = block[1]
            local rgns = findRegionOrMarkers(blockName)

            blockData = {
                positions = _.map(rgns, function(rgn, key)
                    local success, isRegion, pos = reaper.EnumProjectMarkers(rgn)
                    local success, measures = reaper.TimeMap2_timeToBeats(0, pos)
                    return measures + 1
                end),
                lines = {}
            }
            map[blockName] = blockData
        elseif trimmed:len() > 0 then
            table.insert(blockData.lines, trimmed)
        end
    end

    local lyricsLines = {}
    local keys = {}
    for name,data in pairs(map) do
        for k, pos in pairs(data.positions) do
            for i, line in pairs(data.lines) do
                local index = pos + i - 1
                lyricsLines[index] = line
                table.insert(keys, index)
            end
        end
    end

    table.sort(keys)

    local lyrics = ''

    local maxPos = 0
    for k, position in pairs(keys) do
        lyrics = lyrics .. position .. '.1.1' .. '\t' .. lyricsLines[position] .. '\t'
        maxPos = math.max(position, maxPos)
    end

    ensureContentLength(track, maxPos + 2)

    local success, existingLyrics = reaper.GetTrackMIDILyrics(track, 2, '')

    reaper.SetTrackMIDILyrics(track, 2, lyrics)
end

local refresh = false

local function refreshUI(now)
    if now then
        if refresh then
            reaper.TrackList_AdjustWindows(false)
            reaper.UpdateTimeline()
            refresh = false
            return true
        end
    else
        refresh = true
    end
end



local rea = {
    logPin = logPin,
    logError = logError,
    logCount = logCount,
    getFiles = getFiles,
    profile = profile,
    logOnly = logOnly,
    refreshUI = refreshUI,
    setTrackVisible = setTrackVisible,
    prompt = prompt,
    findIcon = findIcon,
    transaction = transaction,
    findFiles = findFiles,
    getAllTracks = getAllTracks,
    getChildTracks = getChildTracks,
    setLyrics = setLyrics,
    findTrack = findTrack,
    findRegionOrMarkers = findRegionOrMarkers,
    log = log,
    getParamByName = getParamByName,
    getFxByName = getFxByName
}

return rea
end
,
Util = function()

require 'String'

local _ = require '_'
function dump(o, deep, depth, references)
    depth = depth or 0
    deep = deep == nil and true or deep
    references = references or {}

    local indent = string.rep('  ', depth)
    if type(o) == 'table' then

        if includes(references, o) then
            return '=>'
        end

        if o.__tostring then return indent .. o.__tostring(o) end

        table.insert(references, o)

        local lines = {}
        for k,v in pairs(o) do
            -- if type(k) ~= 'number' then k = '"'..k..'"' end
            table.insert(lines, indent .. indent ..k..': ' .. dump(v, deep, depth + 1, references))
        end
        return '{ \n' .. _.join(lines, ',\n') .. '\n' .. indent ..  '} '
    else
        return tostring(o)
    end
end

function includes(table, value)
    return find(table, value)
end

function find(table, value)
    for i, comp in pairs(table) do
        if comp == value then
            return i
        end
    end
end

local noteNames = {
    'c',
    'c#',
    'd',
    'd#',
    'e',
    'f',
    'f#',
     'g',
    'g#',
     'a',
     'a#',
     'b'
}

function getNoteName(number)
    local octave = math.ceil(number / 12) - 1
    local note = number % 12
    return noteNames[note+1] .. tostring(octave)
end

function removeValue(heystack, value)
    local i = find(heystack, value)
    if i then
        table.remove(heystack, i)
    end
end

function class(...)
    local class = {}
    local parents = {...}

    assertDebug(_.some(parents, function(p)
        return not p.__index
    end), 'base class needs __index:' .. tostring(#parents))

    class.__extends = parents
    class.__parentIndex = function(key)
        return _.some(parents, function(c)
            return c:__index(key)
        end)
    end

    function class:__index(key)
        return class[key] or class.__parentIndex(key)
    end

    function class:__gc()
        return _.some(parents, function(c)
            return c.__gc and c.__gc()
        end)
    end

    function class:__instanceOf(needle)
        return class == needle or _.some(parents, function(parent)
            return needle == parent or parent:__instanceOf(needle)
        end)
    end

    return class
end



function writeFile(path, content)
    local file, err = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    else
        reaper.ShowConsoleMsg(err)
    end
end

function readFile(path)
    local file, err = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    else
        reaper.ShowConsoleMsg(err)
    end
end

function readLines(file)
    lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
    end
    return lines
  end

function __dirname(debugInfo)

    local info = debugInfo or debug.getinfo(1,'S')
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
    return script_path
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function fequal(a, b, prec)
    prec = prec or 5
    return round(a, prec) == round(b, prec)
end

function reversed (arr)

    local keys = {}
	for k, v in pairs(arr) do
		table.insert(keys, k)
    end

    local res = {}
    local i = #keys
    while i >= 1 do
        local key = keys[i]
        i = i - 1
        res[key] = arr[key]
    end

    return res
end

function rpairs(t)
    return pairs(reversed(t))
end

function assertDebug(cond, text)
    if cond then assert(false, (text or '') .. debug.traceback()) end
end


function toboolean(val)
    if type(val) == 'number' then return val ~= 0 end
    return val
end
end
,
Watcher = function()
local _ = require '_'

local Watcher = class()
local rea = require 'rea'

Watcher.watchers = {}

function Watcher.deferAll()
    _.forEach(Watcher.watchers, function(watcher)
        watcher:defer()
    end)
end

function Watcher:create(callback)
    local self = {
        listeners = {},
        lastValue = nil,
        callback = callback
    }
    setmetatable(self, Watcher)
    table.insert(Watcher.watchers, self)

    return self
end

function Watcher:close()

    _.removeValue(Watcher.watchers, self)
    self.listeners = {}
end

function Watcher:onChange(listener)
    table.insert(self.listeners, listener)
    return function()
        self:removeListener(listener)
    end
end

function Watcher:removeListener(listener)
    _.removeValue(self.listeners, listener)
end

function Watcher:defer()
    if #self.listeners > 0 then
        local newValue = self.callback()

        if self.lastValue ~= newValue then
            self.lastValue = newValue
            _.forEach(self.listeners, function(listener)
                listener(newValue)
            end)
        end
    end
end





return Watcher
end
,
_ = function()

local function map(data, callback)
    local res = {}
    for k,v in pairs(data or {}) do
        local value, key = callback(v, k)
        if key then
            res[key] = value
        else
            table.insert(res, value)
        end
    end
    return res
end

local function assign(target, source)
    for k,v in pairs(source or {}) do
        target[k] = v
    end
    return target
end

local function forEach(data, callback)
    for k,v in pairs(data or {}) do
        callback(v, k)
    end
end

local function size(collection)
    local i = 0
    for k,v in pairs(collection or {}) do i = i + 1 end
    return i
end

local function some(data, callback)
    for k,v in pairs(data or {}) do
        local res = callback(v, k)
        if res then return res end
    end
    return nil
end

local function equal(a, b)
    if (not a or not b) and a ~= b then return false end
    if type(a) ~= type(b) then return false end
    if type(a) == 'table' then
        if size(a) ~= size(b) then return false end
        if some(a, function(val, key) return not equal(val, b[key]) end) then return false end
    else
        return a == b
    end

    return true
end

local function last(array)
    return array and array[#array]
end

local function first(array)
    return array and array[1] or nil
end

local function reverse(arr)

    local keys = {}
	for k, v in pairs(arr) do
		table.insert(keys, k)
    end

    local res = {}
    local i = #keys
    while i >= 1 do
        local key = keys[i]
        i = i - 1
        res[key] = arr[key]
    end

    return res
end

local function find(data, needle)
    local callback = type(needle) ~= 'function' and function(subj) return subj == needle end or needle
    for k,v in pairs(data or {}) do
        local res = callback(v, k)
        if res then return v end
    end
    return nil
end

local function indexOf(data, needle)
    local i = 1
    return some(data, function(v)
        if v == needle then return i end
        i = i + 1
    end)
end

local function filter(data, callback)
    local res = {}
    for k,v in pairs(data or {}) do
        if callback(v, k) then res[k] = v end
    end
    return res
end

local function pick(data, list)
    local res = {}

    for k,v in pairs(list or {}) do
        local val = data[v]
        if val ~= nil then res[v] = val end
    end

    return res
end

local function reduce(data, callback, carry)
    for k,v in pairs(data or {}) do
        carry = callback(carry, v, k)
    end
    return carry
end

local function join(t, glue)
    -- local res = ''

    -- local i = 1
    -- for key, row in pairs(table or {}) do
    --     res = res .. tostring(row) .. (i < #table and glue or '')
    --     i = i + 1
    -- end
    -- return res
    return table.concat(t, glue)
end

local function empty(table)
    return size(table) == 0
end

local function removeValue(table, needle)
    forEach(table, function(value, key)
        if value == needle then
            table[key] = nil
        end
    end)
end

return {
    indexOf = indexOf,
    reverse = reverse,
    removeValue = removeValue,
    empty = empty,
    join = join,
    filter = filter,
    reduce = reduce,
    pick = pick,
    some = some,
    first = first,
    find = find,
    last = last,
    equal = equal,
    size = size,
    assign = assign,
    map = map,
    forEach = forEach,
    mapKeyValue = mapKeyValue
}
end
,
TrackState = function()

local rea = require 'rea'
local _ = require '_'

local TrackState = class()

function TrackState.fromTemplate(templateData)

    local res = {}
    for match in  templateData:gmatch('(<TRACK.->)') do
        state = TrackState:create(match)
        aux = state:getAuxRecs()
        table.insert(res, state)
    end

    return res
end

function TrackState.fromTracks(tracks)

    local Track = require 'Track'

    local states = {}
    _.forEach(tracks, function(track, i)
        local state = track:getState()
        local sourceTracks = _.map(state:getAuxRecs(), Track.get)
        _.forEach(sourceTracks, function(sourceTrack)
            local currentIndex = sourceTrack:getIndex() - 1
            local indexInTemplate = _.indexOf(tracks, sourceTrack)

            if indexInTemplate then
                state = state:withAuxRec(currentIndex, indexInTemplate - 1)
            else
                local sourceTrackIndex = sourceTrack:getIndex() - 1
                state = state:withoutAuxRec(sourceTrackIndex)
            end
        end)

        table.insert(states, state)

    end)

    return states

end

function TrackState:getPlugins()
    local chainContent = self.text:match('(<FXCHAIN.-\n>)\n>')
    local pluginsText = chainContent:match('<FXCHAIN.-(<.*)>'):trim():sub(1, -2)
    local plugins = pluginsText:gmatchall('<(.-\n)(.-)>([^<]*)')
    return plugins
end

function TrackState:withLocking(locked)
    local text = self.text
    if locked ~= self:isLocked() then
        if locked then
            text = self.text:gsub('<TRACK', '<TRACK \n LOCK 1\n')
        else
            text = self.text:gsub('(LOCK %d)', '')
        end
    end

    return TrackState:create(text)
end

function TrackState:isLocked()
    local locker = tonumber(self.text:match('LOCK (%d)'))
    return locker and (locker & 1 > 0) or false
end

function TrackState:create(text)
    local self = {
        text = text
    }
    setmetatable(self, TrackState)
    return self
end

function TrackState:getAuxRecs()
    local recs = {}
    for index in self.text:gmatch('AUXRECV (%d) (.-)\n') do
        table.insert(recs, math.floor(tonumber(index)))
    end
    return recs
end

function TrackState:__tostring()
    return self.text
end

function TrackState:withoutAuxRec(index)
    local rec = index and tostring(index) or '%d'
    return TrackState:create(self.text:gsub('AUXRECV '..rec..' (.-)\n', ''))
end

function TrackState:withAuxRec(from, to)
    from = tostring(math.floor(tonumber(from)))
    to = tostring(math.floor(tonumber(to)))
    local a = 'AUXRECV '..from..' (.-)\n'
    local b = 'AUXRECV '..to..' %1\n'
    return TrackState:create(self.text:gsub(a, b))
end

return TrackState


end

} 
require = function(name) 
    if not _dep_cache[name] then 
        _dep_cache[name] = _deps[name]() 
        end
    return _dep_cache[name] 
end 
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('monitor')

local WindowApp = require 'WindowApp'
local MonitorPresets = require 'MonitorPresets'

WindowApp:create('monitor', MonitorPresets:create(0,0,170, 100)):start()




