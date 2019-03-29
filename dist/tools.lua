-- dep header --
local _dep_cache = {} 
local _deps = { 
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
LayerList = function()
local Component = require 'Component'
local Layer = require 'Layer'
local Project = require 'Project'
local rea = require 'rea'
local _ = require '_'

local LayerList = class(Component)

function LayerList:create(pad)
    self = Component:create()
    self.pad = pad
    setmetatable(self, LayerList)

    self.watchers:watch(Project.watch.project, function()
        self:update()
    end)

    self:update()
    return self
end


function LayerList:update()

    local layers = self.pad:getLayers()

    -- if _.equal(layers, self.layers) then return end

    -- self.layers = layers


    self:deleteChildren()

   _.forEach(layers, function(layer)
        self:addChildComponent(Layer:create(layer, self.pad))
   end)
end

function LayerList:resized()

    local size = 20
    for i, child in pairs(self.children) do
        child:setBounds(0, (i - 1) * size,self.w, size)
    end
end

return LayerList
end
,
PadUI = function()
local TextButton = require 'TextButton'
local Component = require 'Component'
local Track = require 'Track'
local Layer = require 'Layer'
local Menu = require 'Menu'
local Pad = require 'Pad'
local Mem = require 'Mem'
local Watcher = require 'Watcher'
local Image = require 'Image'
local PadUI = class(Component)
local DrumRack = require 'DrumRack'
local Collection = require 'Collection'

local _ = require '_'
local rea = require 'rea'
local icons = require 'icons'
local colors = require 'colors'

function PadUI.showMenu(pad)

    local menu = Menu:create()

    menu:addItem('save', {
        disabled = not pad:hasContent(),
        callback = function()
            local file = DrumRack.padPresetDir:saveDialog('.RTrackTemplate', pad:getName())
            if file then
                writeFile(file, pad:savePad())
            end
        end,
    })
    menu:addItem('load', function()
        local file = DrumRack.padPresetDir:browseForFile('RTrackTemplate')
        if file then
            rea.transaction('load pad', function()
                pad:loadPad(file)
            end)
        end
    end)

    menu:addSeperator()

    local low, high = pad.rack:getMapper():getKeyRange(pad)

    local learnMenu = Menu:create()
    learnMenu:addItem(tostring(low) .. '-' .. tostring((high)), {
        disabled = true
    })

    learnMenu:addItem('low', function() pad:learnLow() end)
    learnMenu:addItem('high', function() pad:learnHi() end)
    learnMenu:addItem('both', function() pad:learn() end)

    menu:addItem('learn', learnMenu)

    local addMenu = Menu:create()
    if _.size(pad.rack:getSelectedTracks()) > 0 then
        addMenu:addItem('selected tracks as layers', function() pad:addSelectedTracks() end, 'add empty track')
    end
    addMenu:addItem('empty track', function() pad:addLayer() end, 'add empty track')
    addMenu:addItem('instrument', function()
        local success, name = reaper.GetUserInputs("name", 1, "name", "")
        if success then
            pad:addLayer(name)
        end
    end, 'add instrument pad')

    menu:addItem('add', addMenu)
    menu:addSeperator()
    menu:addItem('clear', function() pad:clear() end, 'clear pad')
    menu:addItem('test', function()
        local a = Collection:create({Track.get(0).track})
        local b = Collection:create({Track.get(1).track})
    end, 'clear pad')
    menu:show()

end

function PadUI:onDelete()
    self.watcher:close()
end

function PadUI:create(pad)

    local self = Component:create()
    setmetatable(self, PadUI)
    self.pad = pad
    self.rack = pad.rack


    self.watcher = Watcher:create(function() return self.pad:getVelocity() end)
    self.watcher:onChange(function() self:repaint() end)

    self.padButton = self:addChildComponent(TextButton:create(''))

    self.lock = self:addChildComponent(Image:create(icons.lock))
    self.lock.getAlpha = function()
        local states = {
            1,
            0.5,
        }
        return states[pad:getLocked()] or 0
    end

    self.padButton.getText = function()
        return self.pad:getName()
    end

    self.padButton.onMouseDown = function(s, mouse)
        if not s:isVisible() then return end

        if mouse:isRightButtonDown() then

        else
            local key = self.mouse.x / self.w * 127
            local velo = 127 - self.mouse.y / self.h * 127
            Mem.write('drumrack', DrumRack.maxNumPads + self.pad:getIndex() - 1, velo)
            Mem.write('drumrack', DrumRack.maxNumPads * 2 + self.pad:getIndex() - 1, key)
        end
    end

    self.padButton.canClickThrough = function()
        return true
    end

    self.padButton.getToggleState = function (s, mouse)
        return self.pad:isSelected()
    end

    self.padButton.onClick = function (s, mouse)
        local wasSelected = pad:setSelected()

        if wasSelected then
            rea.transaction('select pad', function()
                if pad:getFx() then
                    pad:getFx():focus()
                elseif _.first(pad:getLayers()) then
                    _.first(pad:getLayers()):focus()
                end
            end)
        end

        pad:noteOff()

        if mouse:wasRightButtonDown() then
            PadUI.showMenu(self.pad)
        end
    end

    self.padButton.isDisabled = function()
        return not self.pad:hasContent()
    end

    return self
end


function PadUI:onFilesDrop(files)

    rea.transaction('add layer', function()
        for v, k in pairs(files) do
            self.pad:addLayer(k)
        end
    end)

end

function PadUI:onDrag()
    Component.dragging = self
    self.pad:noteOff()
end

function PadUI:onDrop(mouse)

    if Component.dragging ~= self then

        self.pad:setSelected()

        if Component.dragging.pad and getmetatable(Component.dragging.pad) == Pad then

            local pad = Component.dragging.pad

            if mouse:wasRightButtonDown() then
                local menu = Menu:create()
                menu:addItem('flip pads', function() self.pad:flipPad(pad) end, 'flip pad')
                menu:addItem('copy pad', function() self.pad:copyPad(pad) end, 'copy pad')
                menu:show()
            else
                rea.transaction('flip pads', function()
                    self.pad:flipPad(pad)
                end)
            end

        elseif getmetatable(Component.dragging) == Layer then
            rea.transaction('move layer', function()
                Component.dragging.send:setMidiBusIO(self.pad:getIndex(), 1)
            end)
        end
    end
end

function PadUI:paintOverChildren(g)
    local padding = 5

    if self.pad:getVelocity() > 0 then
        g:setColor(colors.fx:with_alpha(self.pad:getVelocity() / 127))
        g:rect(padding, padding, self.w - padding * 2, self.h - padding * 2, true, true)
    end
end

function PadUI:resized()

    local padding = 2
    self.padButton:setBounds(padding, padding, self.w - 2 * padding, self.h - 2 * padding)

end

return PadUI
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
PadOptions = function()
local colors = require 'colors'
local Menu = require 'Menu'
local Slider = require 'Slider'
local rea = require 'rea'
local Mouse = require 'Mouse'
local FXButton = require 'FXButton'

return function(pad)
    return {
        {
            proto = function()
                return FXButton:create(pad)
            end
        },
        {
            args = 'hold',
            getToggleState = function()
                return pad.rack:getMapper():getParam(8)
            end,
            getText = function (self)
                local val = self:getToggleState()
                return val == 1 and 'hold:time' or val == 2 and 'hold:inf' or 'release'
            end,
            isDisabled = function()
                return pad.rack:isSplitMode()
            end,
            onClick = function(self)
                local val = self:getToggleState()
                Menu:create({
                    {
                        name = 'release',
                        callback = function() pad.rack:getMapper():setParam(8, 0) end,
                        checked = val == 0
                    },
                    {
                        name = 'hold:time',
                        callback = function() pad.rack:getMapper():setParam(8, 1) end,
                        checked = val == 1
                    },
                    {
                        name = 'hold:inf',
                        callback = function() pad.rack:getMapper():setParam(8, 2) end,
                        checked = val == 2
                    }
                }):show()
            end
        },
        {
            proto = function()
                local slider = Slider:create()
                slider.getValue = function()
                    return pad.rack:getMapper():getParam(9)
                end
                function slider:setValue(val)
                    return pad.rack:getMapper():setParam(9,val)
                end
                slider.isDisabled = function()
                    return pad.rack:getMapper():getParam(8) ~= 1 or pad.rack:isSplitMode()
                end
                return slider
            end
        },
        {
            args = 'choke',
            getToggleState = function()
                return pad.rack:getMapper():getParam(10) > 0
            end,
            isDisabled = function()
                return pad.rack:isSplitMode()
            end,
            getText = function (self)
                local val = self:getToggleState()
                return val == 0 and 'choke:--' or 'choke:' .. tostring(val)
            end,
            onClick = function(self)
                local val = math.floor(pad.rack:getMapper():getParam(10))
                local menu = Menu:create()

                for i=0, 16 do
                    menu:addItem(i == 0 and '--' or tostring(i), {
                        callback = function()
                            pad.rack:getMapper():setParam(10, i)
                        end,
                        checked = val == i
                    })
                end
                menu:show()
            end
        },
    }
end
end
,
Split = function()
local PadUI = require 'PadUI'
local colors = require 'colors'
local Mouse = require 'Mouse'
local rea = 'Reaper'

local Split = class(PadUI)

function Split:create(pad)
    local self = PadUI:create(pad)

    setmetatable(self, Split)

    return self
end

function Split:paintOverChildren(g)

    if self.pad:hasContent() then
        local low, high = self.rack:getMapper():getKeyRange(self.pad)

        local x1 = low / 127 * self.w
        local x2 = (high+1) / 127 * self.w

        g:setColor(colors.fx:with_alpha(0.5))
        g:rect(x1, 0, x2 - x1, self.h, true)
    end

    PadUI.paintOverChildren(self, g)

end

return Split
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
PadEditor = function()
local Component = require 'Component'
local LayerList = require 'LayerList'
local ButtonList = require 'ButtonList'
local PadOptions = require 'PadOptions'
local Split = require 'Split'
local rea = require 'rea'

local PadEditor = class(Component)

function PadEditor:create(pad)
    self = Component:create()
    self.pad = pad
    self.options =  self:addChildComponent(ButtonList:create(PadOptions(pad), true))

    self.options.isVisible = function( )
        return pad:hasContent()
    end

    self.range = self:addChildComponent(Split:create(pad))
    self.range.padButton:setVisible(false)

    self.range.isVisible = function()
        return self.pad.rack:isSplitMode()
    end
    self.range.onDrag = function(mouse)
        local key = self.mouse.x / self.w * 127
        local index = pad:getIndex()
        if not pad:getPrev() then
            pad.rack:getMapper():setParamForPad(pad, 1, 0)
        end

        local nextPad = pad:getNext()
        if nextPad and nextPad:hasContent() then
            pad.rack:getMapper():setParamForPad(pad, 2, key)
            pad.rack:getMapper():setParamForPad(nextPad, 1, key + 1)

            local nextNextPad = nextPad:getNext()
            if not nextNextPad or not nextNextPad:hasContent() then
                pad.rack:getMapper():setParamForPad(nextPad, 2, 127)
            end

        else

            local prevPad = pad:getPrev()
            if prevPad and prevPad:hasContent() then
                pad.rack:getMapper():setParamForPad(pad, 1, key)
                pad.rack:getMapper():setParamForPad(prevPad, 2, key)
            else
                pad.rack:getMapper():setParamForPad(pad, 2, 127)

            end

        end

    end

    self.layers = self:addChildComponent(LayerList:create(pad))
    setmetatable(self, PadEditor)
    return self
end

function PadEditor:isVisible()
    return self.pad:isSelected()
end

function PadEditor:onFilesDrop(files)
    self.pad:onFilesDrop(files)
end

function PadEditor:resized()
    local h = 20

    self.range:setBounds(0,0,self.w, h)

    local y = self.range:isVisible() and self.range:getBottom() or 0


    self.options:setBounds(0, y, self.w, h)


    self.layers:setBounds(0, self.options:getBottom(), self.w, self.h - self.options:getBottom())

end

return PadEditor
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
,
Layer = function()
local Component = require 'Component'
local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Image = require 'Image'
local TrackStateButton = require 'TrackStateButton'
local Menu = require 'Menu'
local _ = require '_'
local colors = require 'colors'
local icons = require 'icons'

local rea = require 'rea'

local Layer = class(Component)

function Layer:create(track, pad)
    local self = Component:create()
    self.pad = pad
    self.rack = pad.rack
    self.track = track

    self.icon = self:addChildComponent(Image:create(track:getIcon(), 'fit'))

    self.mute = self:addChildComponent(TrackStateButton:create(self.track, 'mute', 'M'))
    self.mute.color = colors.mute

    self.lock = self:addChildComponent(IconButton:create(icons.lock))
    self.lock.onButtonClick = function()
        track:setLocked(not track:isLocked())
    end
    self.lock.getToggleState = function()
        return track:isLocked()
    end

    self.solo = self:addChildComponent(TrackStateButton:create(self.track, 'solo', 'S'))
    self.solo.color = colors.solo

    self.name = self:addChildComponent(TextButton:create('layer'))

    self.name.getText = function()
        return self.track:getInstrument() and self.track:getInstrument():getName() or self.track:getName()
    end

    self.name.getToggleState = function()
        return self.track:isFocused()
    end

    self.name.onClick = function(s, mouse)
        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            menu:addItem('layer -> track', function()
                track:setVisibility(true, true)
                local recs = self.track:getReceives()
                local con = _.find(recs, function(rec)
                    local src = rec:getSourceTrack()
                    return src == self.rack:getTrack()
                end)
                assert(con, 'layer should have a rack connection')
                con:remove()
            end, 'layer -> track')

            menu:show()
        elseif mouse:isAltKeyDown() then
            rea.transaction('delete layer', function()
                self.track:remove()
            end)
        else
            rea.transaction('focus layer', function()
                self.track:focus()
            end)
        end
    end

    self.name.onDblClick = function()
        self.track:getInstrument():open()
    end

    self.name.onDrag = function()
        Component.dragging = self
    end

    setmetatable(self, Layer)
    return self
end

function Layer:isSampler()
    return self.track:getInstrument():getParam('FILE0') ~= nil
end

function Layer:paint(g)
    self.name.drawBackground(self, g, self.name:getColor())
end

function Layer:resized()

    local h = self.h
    self.icon:setSize(h,h)

    self.mute:setBounds(self.icon:getRight(), 0, h, h)

    self.solo:setBounds(self.mute:getRight(), 0, h, h)

    self.lock:setBounds(self.solo:getRight(), 0, h, h)

    self.name:setBounds(self.lock:getRight(), 0, self.w - self.lock:getRight(), h)

end

return Layer
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
paths = function()
local Directory = require 'Directory'

return {
    effectsDir = Directory:create(reaper.GetResourcePath() .. '/Effects/D3CK'):mkdir(),
    scriptDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK'):mkdir(),
    binDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/apps'):mkdir(),
    distDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/dist'):mkdir(),
    imageDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/images'):mkdir()
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
icons = function()
local rea = require 'rea'

return {
    lock = rea.findIcon('lock.png')
}
end
,
Mapper = function()
local Plugin = require 'Plugin'
local Pad = require 'Pad'

local Mapper = class(Plugin)

function Mapper:create(plugin)
    local self = Plugin:create(plugin.track, plugin.index)
    setmetatable(self, Mapper)
    return self
end

function Mapper:getKeyRange(index)

    if getmetatable(index) == Pad then
        return self:getKeyRange(index:getIndex())
    end

    local pad = self:getParam(0)
    self:setParam(0, index)
    local low = self:getParam(1)
    local high = self:getParam(2)

    self:setParam(0, pad)

    return math.floor(low), math.floor(high)
end

function Mapper:setParamForPad(index, param, value)

    assert(param > 0, 'can not set param 0 (selected pad)')

    if getmetatable(index) == Pad then
        return self:setParamForPad(index:getIndex(), param, value)
    end

    local pad = self:getParam(0)
    self:setParam(0, index)

    self:setParam(param, value)

    self:setParam(0, pad)

end


return Mapper
end
,
Tools = function()


local Track = require 'Track'
local rea = require 'rea'
local DrumRackUI = require 'DrumRackUI'
local RandomSound = require 'RandomSound'
local Menu = require 'Menu'
local Mouse = require 'Mouse'
local Instrument = require 'Instrument'
local _ = require '_'

return {
    {
        args = '+inst',
        onClick = function()
            Instrument.bang()
        end
    },
    {
        args = '+drm',
        onClick = function(self, mouse)
            DrumRackUI.drumRackButton(mouse)
        end
    },
    {
        args = '?',
        proto = RandomSound.Button
    },
}
end
,
PadGrid = function()



local Component = require 'Component'
local PadUI = require 'PadUI'
local _ = require '_'
local PadGrid = class(Component)
local rea = require 'rea'

local defaults = {
    cols = 4,
    rows = 4
}

function PadGrid:create(options, ...)

    local self = Component:create(...)
    _.assign(self, defaults)
    _.assign(self, options)

    setmetatable(self, PadGrid)
    self:createPads()
    return self

end

function PadGrid:createPads()

    local i = 1
    for row = 1, self.rows do
        for col = 1, self.cols do
            self:addChildComponent(PadUI:create(self.rack.pads[i]))
            i = i + 1
        end
    end

end

function PadGrid:resized()

    local i = 1
    local w = self.w / self.cols
    local h = self.h / self.rows
    for row = 1, self.rows do
        for col = 1, self.cols do
            local pad = self.children[i]
            i = i + 1
            pad:setBounds((col-1) * w, (self.rows - row) * h, w, h)
        end
    end

end

return PadGrid
end
,
Instrument = function()
local Instrument = class()
local Track = require 'Track'
local DrumRack = require 'DrumRack'
local paths = require 'paths'
local rea = require 'rea'
local colors = require 'colors'
local _ = require '_'


function Instrument.aux()
    rea.transaction('add aux bus(es)', function()

        local input = rea.prompt('aux')

        if not input then return false end


    end)
end

function Instrument.bang()

    rea.transaction('add instrument(s)', function()

        local input = rea.prompt('instrument')

        if not input then return false end

        local zones = _.map(input:split('|'), function(zone)
            local layers = _.map(zone:split('&'), function(layer)
                local splits = layer:trim():split(' ')
                local track = Track.insert()
                track:setColor(colors.instrument)
                local name = splits[1]

                track:getFx(name, true)
                local inst = track:getInstrument()
                if inst then
                    track:setName(splits[2] or name)
                    track:setType('instrument')
                    track:choose()
                    icon = rea.findIcon(name) or paths.imageDir:findFile(name)
                    if icon then track:setIcon(icon) end
                    track:getInstrument():open()
                    return track
                else
                    track:remove()
                    reaper.ShowMessageBox('could not find instrument named:' .. name, 'error', 0)
                    return nil
                end
            end)

            return #layers > 0 and layers or nil
        end)

        local numZones = #zones

        if numZones > 0 then
            if numZones > 1 or #zones[1] > 1 then
                local rack = DrumRack.init(Track.insert():setName(input))
                rack:setSplitMode()

                range = math.floor(128 / numZones)
                local low = 0
                local hi = range
                local i = 1
                _.forEach(zones, function(zone)
                    local pad = rack.pads[i]
                    rack:getMapper():setParamForPad(pad, 1, low)
                    rack:getMapper():setParamForPad(pad, 2, hi)
                    low = low + range
                    hi = hi + range
                    i = i + 1
                    _.forEach(zone, function(layer)
                        pad:addTrack(layer)
                    end)
                end)

            end
        else  -- no instruments found
            return false
        end


    end)

end

return Instrument
end
,
DrumRackUI = function()
local PadGrid = require 'PadGrid'
local Component = require 'Component'
local PadEditor = require 'PadEditor'
local ButtonList = require 'ButtonList'
local Split = require 'Split'
local DrumRackOptions = require 'DrumRackOptions'
local Project = require 'Project'
local DrumRack = require 'DrumRack'
local Menu = require 'Menu'
local Track = require 'Track'

local colors = require 'colors'
local _ = require '_'

local rea = require 'rea'

local DrumRackUI = class(Component)

function DrumRackUI.drumRackButton(mouse)
    local addRack = function()
        local name = rea.prompt('name')
        if name then
            local track = Track.insert()
            track:setName(name:len() > 0 and name or 'drumrack'):choose()
            return DrumRack.init(track)
        end
    end
    local addSplit = function()
        return addRack():setSplitMode()
    end

    if mouse:wasRightButtonDown() then

        local tracks = Track.getSelectedTracks()

        local menu = Menu:create()
        menu:addItem('new drumrack', addRack, 'add empty drumrack')
        menu:addItem('new splitrack', addSplit, 'add empty splitrack')

        if _.size(tracks) > 0 then
            menu:addSeperator()
            menu:addItem('pad-layers from selected tracks', function()

                local rack = addRack()
                if rack then
                    _.forEach(tracks, function(track)
                        rack.pads[1]:addTrack(track)
                    end)
                end
            end, 'add drum rack')
            menu:addItem('pads from selected tracks', function()
                local tracks = Track.getSelectedTracks()
                local rack = addRack()
                if rack then
                    local i = 1
                    _.forEach(tracks, function(track)
                        if rack.pads[i] then
                            rack.pads[i]:addTrack(track)
                        end

                        i = i + 1
                    end)
                end
            end, 'add drum rack')
            menu:addSeperator()

            menu:addItem('split-layers from selected tracks', function()
                local tracks = Track.getSelectedTracks()
                local rack = addSplit()
                rack.pads[1]:setKeyRange(0,127)
                if rack then
                    _.forEach(tracks, function(track)
                        rack.pads[1]:addTrack(track)
                    end)
                end
            end, 'add drum rack')
        end
        menu:show()
    else
        rea.transaction('add drum rack',addRack)
    end
end

-- methods

function DrumRackUI:create(rack)

    local self = Component:create()

    setmetatable(self, DrumRackUI)

    self.rack = rack

    self.opts = self:addChildComponent(ButtonList:create(DrumRackOptions(rack), true))
    self.padgrid = self:addChildComponent(PadGrid:create({rack = rack}))

    local splits = _.map(rack.pads, function(pad) return {args = pad} end)
    self.layers = self:addChildComponent(ButtonList:create(splits, false, Split))

    local change = function()
        self.layers:setVisible(rack:isSplitMode())
        self.padgrid:setVisible(not rack:isSplitMode())
        self:update()
    end
    self.watchers:watch(Project.watch.project, change)
    change()

    return self

end

function DrumRackUI:isVisible()
    return self.rack:getTrack():exists()
end

function DrumRackUI:update()
    local currentPad = self.padEditor and self.padEditor.pad

    if self.rack:getSelectedPad() and self.rack:getSelectedPad() ~= currentPad then
        if self.padEditor then self.padEditor:delete() end
        self.padEditor = self:addChildComponent(PadEditor:create(self.rack:getSelectedPad()))
    end
end

function DrumRackUI:resized()

    self.opts:setBounds(0, 0, self.w, 20)

    local padgrid = self.w
    self.padgrid:setBounds(0, self.opts:getBottom(), padgrid, padgrid)
    self.layers:setBounds(0, self.opts:getBottom(), padgrid, padgrid)

    local y = self.padgrid:getBottom()
    if self.padEditor then
        self.padEditor:setBounds(0, y, self.w)
    end

end

return DrumRackUI
end
,
DrumRack = function()
local Pad = require 'Pad'
local Mapper = require 'Mapper'
local _ = require '_'
local Directory = require 'Directory'

local Track = require 'Track'

local colors = require 'colors'
local rea = require 'rea'

local DrumRack = class()

DrumRack.presetDir = Directory:create(reaper.GetResourcePath() .. '/TrackTemplates/DrumRack'):mkdir()
DrumRack.padPresetDir = Directory:create(reaper.GetResourcePath() .. '/TrackTemplates/DrumRack/Pads'):mkdir()
DrumRack.fxName = 'DrumRack'
DrumRack.maxNumPads = 16

function DrumRack.launch()

    local id = reaper.NamedCommandLookup('drumRack.lua')
    if not id then
        id = reaper.AddRemoveReaScript(true, 0, 'path', true)
    end
    if id then reaper.Main_OnCommand(id, 0) end

end

function DrumRack.getAllRacks()
    local tracks = Track.getAllTracks()
    return _.filter(tracks, function(track) return track:getFx(DrumRack.fxName) end)
end

function DrumRack.getAssociatedDrumRack(selected)
    return _.some(DrumRack.getAllRacks(), function(track)
        local rack = DrumRack:create(track)
        return _.find(rack:getAllTracks(true), selected) and rack
    end)
end

function DrumRack.init(track)

    if not track then track = Track.insert()end

    track:setType('drumrack')
    track:setIcon(track:getIcon() or 'drumbox.png')
    track:setVisibility(true, false)
    track:setName(track:getName() or 'drumrack')
    track:setValue('toParent', false)
    track:getFx(DrumRack.fxName, true)
    track:setColor(colors.instrument)

    local rack = DrumRack:create(track)
    rack:setSelectedPad(1)
    return rack

end

-- methods

function DrumRack:create(track)

    reaper.gmem_attach('drumrack')

    local self = {}

    setmetatable(self, DrumRack)

    self.track = track

    self.pads = {}
    for i=1, DrumRack.maxNumPads do
        table.insert(self.pads, Pad:create(self))
    end

    return self

end

function DrumRack:getLocked()
    local pads = _.filter(self.pads, function(pad) return pad:hasContent() end)

    local locks = _.reduce(pads, function(carry, pad)
        local lock = pad:getLocked()
        return math.max(carry, lock)
    end, 0)

    if self:getFx()then
        local l = self:getFx():isLocked()
        if _.size(pads) == 0 then return l
        elseif locks == 1 then
            locks = l and 1 or 2
        elseif locks == 0 then
            locks = l and 2 or locks
        end
    end

    return locks
end

function DrumRack:getSelectedTracks()
    local own = self:getAllTracks()
    local tracks = _.filter(Track.getSelectedTracks(), function(track)
        return not _.find(own, track)
    end)
    return tracks
end

function DrumRack:setLocked(locked)
    if self:getFx() then self:getFx():setLocked(locked) end
    _.forEach(self.pads, function(pad)
        pad:setLocked(locked)
    end)
end

function DrumRack:__eq(o)
    return self.track == o.track
end

function DrumRack:clear()
    _.forEach(self.pads, function(pad)
        pad:clear()
    end)
    return self
end

function DrumRack:getTrack()
    return self.track
end

function DrumRack:getAllTracks(includeMidi)

    local tracks = {
        [self.track.guid] = self.track
    }

    local fx = self:getFx()
    if fx then tracks[fx.guid] = fx end

    _.forEach(self.pads, function(pad, i)
        pad:getAllTracks(tracks)
    end)

    if includeMidi then
        _.forEach(self.track:getMidiSlaves(), function(track)
            tracks[track.guid] = track
        end)
    end

    return tracks
end

function DrumRack:setSelectedPad(index)
    if self:getMapper() then
        local current = self:getMapper():getParam(0)
        if index == current then return false end
        self:getMapper():setParam(0, index)
        return true
    end
    return self
end

function DrumRack:hasContent()
    return _.some(self.pads, function(pad)
        return pad:hasContent()
    end)
end

function DrumRack:getSelectedPad()
    return self.pads[self:getMapper() and self:getMapper():getParam(0)]
end

function DrumRack:saveKit()
    local tracks = self:getAllTracks()
    local data = TrackState.fromTracks(track)
    return _.join(data, '\n')
end

function DrumRack:loadKit(file)
    local selection = Track.getSelectedTracks()

    reaper.Main_openProject(file)

    Track.deferAll()

    local loadedTracks = Track.getSelectedTracks()

    local drumRackToLoad = _.some(loadedTracks, function(track)
        return DrumRack.getAssociatedDrumRack(track)
    end)

    if drumRackToLoad then
        self:clear()

        self:setFx(drumRackToLoad:getFx())

        _.forEach(drumRackToLoad.pads, function(padToLoad)
            local pad = self.pads[padToLoad:getIndex()]
            pad:setFx(padToLoad:getFx())
            _.forEach(padToLoad:getLayers(), function(layer)
                pad:addTrack(layer)
            end)
        end)

        drumRackToLoad:getTrack():remove()
    end

    Track.setSelectedTracks(selection)
    return self
end

function DrumRack:refreshConnections()
    _.forEach(self.pads, function(pad)
        pad:refreshConnections()
    end)
    return self
end

function DrumRack:isSplitMode()
    return self:getMapper():getParam(11) > 0
end

local icons = {
    'drumbox.png',
    'fx.png'
}

function DrumRack:setSplitMode(enable)

    local val = enable == nil and 1 or (enable and 1 or 0)
    icon = self:getTrack():getIcon()

    defIcon = _.some(icons, function(i) return icon:includes(i) end)
    if defIcon then
        self:getTrack():setIcon(icons[val + 1])
    end

    self:getMapper():setParam(11, val)
    return self
end

function DrumRack:removeFx()
    if self:getFx() then
        self:getFx():remove()
        self:refreshConnections()
    end
    return self
end

function DrumRack:setFx(track)
    if track then
        self:removeFx()

        local send = self:getTrack():createSend(track)
        send:setMidiBusIO(-1, -1):setMuted()

        self:refreshConnections()

    end
    return self
end

function DrumRack:createFx()
    local fxTrack = self:getTrack():createSlave('fx', -1)
    fxTrack:setIcon(fxTrack:getIcon() or 'beats.png')
    fxTrack:setColor(colors.fx)
    :setVisibility(false, true)
    if self:getLocked() == 1 then fxTrack:setLocked(true) end
    return fxTrack
end

function DrumRack:getFx(create)

    local fxTrack = _.some(self:getTrack():getSends(), function(send)
        if send:isMuted() and send:getMidiSourceBus() == -1 then
            return send:getTargetTrack()
        end
    end)

    if create and not fxTrack then
        fxTrack = self:createFx()
        self:setFx(fxTrack)
    end

    return fxTrack

end

function DrumRack:isActive()
    return self:getMapper()
end

function DrumRack:getMapper()
    if not self.mapper then
        local fx = self:getTrack():getFx(DrumRack.fxName)
        local mapper = Mapper:create(fx)
        self.mapper = fx and mapper or nil
    end
    return self.mapper
end

return DrumRack
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
IconButton = function()
local Component = require 'Component'
local Label = require 'Label'
local TextButton = require 'TextButton'
local Image = require 'Image'
local color = require 'color'
local rea = require 'rea'

local IconButton = class(TextButton)

function IconButton:create(icon)

    local self = TextButton:create()

    self.icon = self:addChildComponent(Image:create(icon, 'fit'))
    self.icon.getAlpha = function()
        return self:getToggleStateInt() == 2 and 0.5 or 1
    end

    setmetatable(self, IconButton)
    return self

end

function IconButton:paint(g)
    self:drawBackground(g)
end

function IconButton:resized()
    self.icon:setSize(self.w - 2, self.h - 4)
end




return IconButton
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
TrackStateButton = function()
local TextButton = require 'TextButton'
local Track = require 'Track'
local Component = require 'Component'
local Project = require 'Project'
local rea = require 'rea'

local TrackStateButton = class(TextButton)

function TrackStateButton:create(track, key, content)
    local self = TextButton:create(content or key)
    self.track = track
    self.key = key
    -- self.watchers:watch(Project.watch.project, function() self:repaint() end)
    setmetatable(self, TrackStateButton)
    return self
end

function TrackStateButton:getToggleState()
    return self.track and self.track:getValue(self.key) > 0
end

function TrackStateButton:onClick()
    rea.transaction('toggle: ' .. (self:getText()), function()
        local state = self.track:getValue(self.key) == 0 and 1 or 0
        --== 0 and 1 or 0
        self.track:setValue(self.key, state)
        rea.refreshUI()
    end)
end

function TrackStateButton:getText()
    return self.content.text or self.key
end



return TrackStateButton

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
Image = function()
local Component = require 'Component'
local _ = require '_'
local rea = require 'rea'

local Image = class(Component)

Image.images = {}

function Image:create(file, scale, alpha)

    local self = Component:create()
    setmetatable(self, Image)
    self.scale = scale or 1
    if alpha ~= nil then
        self:setAlpha(alpha)
    end


    if not Image.images[file] then
        Image.images[file] = 0
    end

    Image.images[file] = Image.images[file] + 1

    self.file = file
    self.imgSlot = self:getSlot(file, gfx.loadimg)
    self.uislots[file] = nil

    local w, h = gfx.getimgdim(self.imgSlot)


    self.w = w
    self.h = h

    return self

end

function Image:onDelete()
    local file = self.file

    Image.images[file] = Image.images[file] - 1

    if Image.images[file] == 0 then
        Component.slots[self.imgSlot] = false
    end

    -- assert(Image.images[file] >= 0, 'image tracking failed')
end

function Image:paint(g)

    if self.scale == 'fit' then
        local padding = 4
        local w, h = gfx.getimgdim(self.imgSlot)
        local scale = math.min((self.w-padding) / w, (self.h-padding) / h)

        w = w * scale
        h = h * scale

        g:drawImage(self.imgSlot, (self.w - w) / 2, (self.h - h) / 2, scale)

    else
        g:drawImage(self.imgSlot, 0, 0, self.scale)
    end



end

return Image
end
,
DrumRackOptions = function()
local DrumRack = require 'DrumRack'
local IconButton = require 'IconButton'
local FXButton = require 'FXButton'
local icons = require 'icons'
local rea = require 'rea'

local _ = require '_'

return function(rack)
    return {
        {
            args = 'follow',
            onClick = function(self)
                local value = self:getToggleState() and 0 or 1
                rack:getMapper():setParam(6, value)
            end,
            getToggleState = function ()
                return rack:getMapper() and rack:getMapper():getParam(6) > 0
            end,
            isDisabled = function()
                return not rack:isActive()
            end,
        },
        {
            -- mode
            args = '',
            onClick = function()
                rea.transaction('set drumrack mode', function()
                    rack:setSplitMode(not rack:isSplitMode() and true or false)
                end)
            end,
            getText = function()
                return rack:isSplitMode() and 'pads' or 'splits'
            end
        },
        {
            proto = function()
                return FXButton:create(rack)
            end
        },
        {
            args = 'load',
            onClick = function()
                local file = DrumRack.presetDir:browseForFile('RTrackTemplate')
                if file then
                    rea.transaction('load kit', function()
                        rack:loadKit(file)
                    end)
                end
            end
        },
        {
            args = 'save',
            isDisabled = function()
                return not rack:hasContent()
            end,
            onClick = function()
                local file = DrumRack.presetDir:saveDialog('.RTrackTemplate', rack:getTrack():getName())
                if file then
                    writeFile(file, rack:saveKit())
                end

            end,
        },

        {

            proto = IconButton,
            args = icons.lock,
            onClick = function()
                rea.transaction('toggle locking', function()
                    local lock = rack:getLocked() ~= 1
                    rack:setLocked(lock)
                end)
            end,
            getToggleState = function()
                return rack:getLocked()
            end
        },

        {
            args = '+pat',
            onClick = function()
                rea.transaction('add midi track', function()
                    rack:getTrack()
                        :createMidiSlave()
                        :setSelected(1)
                end)
            end,
            isDisabled = function()
                return not rack:isActive()
            end

        }
    }
end


end
,
FXButton = function()
local TextButton = require 'TextButton'
local IconButton = require 'IconButton'
local Component = require 'Component'
local Mouse = require 'Mouse'
local rea = require 'rea'
local colors = require 'colors'
local icons = require 'icons'

local FXButton = class(Component)

function FXButton:create(fxSource)
    local self = Component:create()
    setmetatable(self, FXButton)

    self.fxSource = fxSource

    self.text = self:addChildComponent(TextButton:create('fx'))
    self.text.getToggleState = function()
        return fxSource:getFx()
    end
    self.text.onButtonClick = function()
        if Mouse.capture():isAltKeyDown() then
            if fxSource:getFx() then
                rea.transaction('remove fx', function()
                    fxSource:removeFx()
                end)
            end
        else
            -- rea.log('click')
            -- rea.log(self.text.mouse.down)
            local fx = fxSource:getFx()
            if not fx then
                rea.transaction('add fx', function()
                    fx = fxSource:getFx(true)
                end)
            end

            if fx then fx:focus() end
        end
    end

    self.lock = self:addChildComponent(IconButton:create(icons.lock))
    -- self.lock.isDisabled = function()
    --     return not fxSource:getFx()
    -- end
    self.lock.onButtonClick = function()
        self.text.onClick()
        if fxSource:getFx() then
            fxSource:getFx():setLocked(not fxSource:getFx():isLocked())
        end
    end
    self.lock.getToggleState = function()
        return fxSource:getFx() and fxSource:getFx():isLocked()
    end
    self.text.color = colors.fx
    self.lock.color = colors.fx
    return self
end

function FXButton:paint(g)
    self.text.drawBackground(self, g, self.text:getColor())
end

function FXButton:resized()
    local h = self.h
    self.text:setBounds(0,0, self.w - h, h)
    self.lock:setBounds(self.text:getRight(), 0, h, h)
end

return FXButton
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
File = function()
local File = class()

function File:create(path)
    local self = {
        path = path
    }

    setmetatable(self, File)

    return self
end

function File:__tostring()
    return self.path
end

function File:exists()
    return reaper.file_exists(self.path)
end

function File:setContent(data)
    writeFile(self.path, data)
    return file
end

function File:getContent()
    return readFile(self.path)
end


return File
end
,
Directory = function()
local Menu = require 'Menu'
local _ = require '_'
local rea = require 'rea'
local File = require 'File'
local Directory = class()

function Directory:create(dir, filter)

    assert(type(dir) == 'string')

    local self = {}
    setmetatable(self, Directory)

    self.dir = dir
    self.filter = filter

    return self
end

function Directory:mkdir()
    reaper.RecursiveCreateDirectory(self.dir, 0)
    return self
end

function Directory:childDir(path, filter)
    return Directory:create(self.dir .. '/' .. path, filter)
end

function Directory:childFile(path)
    return File:create(self.dir .. '/' .. path)
end

function Directory:findFile(pattern)
    return _.first(self:findFiles(pattern))
end

function Directory:findFiles(pattern)
    local filter = type(pattern) == 'function' and pattern or function(file)
        return (file:lower() == pattern:lower()) or file:lower():match(pattern:lower())
    end
    return rea.findFiles(self.dir, {}, filter)
end

function Directory:listAsMenu(selected)

    local menu = Menu:create()
    _.forEach(self:getFiles(), function(file, index)
        menu:addItem(_.last(file:split(':')), {
            callback = function()
                return index
            end,
            checked = index == selected
        })
    end)
    return menu:show()

end

function Directory:browseForFile(ext, text)
    local suc, file = reaper.GetUserFileNameForRead(self.dir .. '/', text or 'load file', ext or '')
    return suc and file or nil
end

function Directory:saveDialog(suffix, initial, override)

    suffix = suffix or ''
    local val = rea.prompt('save', initial)

    if val then
        local file = self.dir .. '/' .. val .. suffix
        if not reaper.file_exists(file) or override then
            return file
        else
            local res = reaper.MB('file already exists. override?', 'override?', 3)
            if res == 6 then return file
            elseif res == 2 then return nil
            elseif res == 7 then return self:saveDialog(suffix, val, override)
            end
        end
    end
end

function Directory:indexOf(needle)
    return _.some(self:getFiles(), function(file, index)
        return file:match(needle) and (index+1)
    end)
end



function Directory:getFiles()
    return rea.getFiles(self.dir, self.filter)
end

return Directory
end
,
ini = function()
--[[
	Copyright (c) 2012 Carreras Nicolas

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]
--- Lua INI Parser.
-- It has never been that simple to use INI files with Lua.
--@author Dynodzzo

local LIP = {};

--- Returns a table containing all the data from the INI file.
--@param fileName The name of the INI file to parse. [string]
--@return The table containing all data from the INI file. [table]
function LIP.load(fileName)
	assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
	local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName);
	local data = {};
	local section;
	for line in file:lines() do
		local tempSection = line:match('^%[([^%[%]]+)%]$');
		if(tempSection)then
			section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
			data[section] = data[section] or {};
		end
		local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
		if(param and value ~= nil)then
			if(tonumber(value))then
				value = tonumber(value);
			elseif(value == 'true')then
				value = true;
			elseif(value == 'false')then
				value = false;
			end
			if(tonumber(param))then
				param = tonumber(param);
			end
			data[section][param] = value;
		end
	end
	file:close();
	return data;
end

--- Saves all the data from a table to an INI file.
--@param fileName The name of the INI file to fill. [string]
--@param data The table containing all the data to store. [table]
function LIP.save(fileName, data)
	assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
	assert(type(data) == 'table', 'Parameter "data" must be a table.');
	local file = assert(io.open(fileName, 'w+b'), 'Error loading file :' .. fileName);
	local contents = '';
	for section, param in pairs(data) do
		contents = contents .. ('[%s]\n'):format(section);
		for key, value in pairs(param) do
			contents = contents .. ('%s=%s\n'):format(key, tostring(value));
		end
		contents = contents .. '\n';
	end
	file:write(contents);
	file:close();
end

return LIP;
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
Pad = function()
local Track = require 'Track'
local Mem = require 'Mem'
local TrackState = require 'TrackState'

local colors = require 'colors'
local _ = require '_'
local rea = require 'rea'

local Pad = class()

function Pad:create(rack)

    local self = {}
    setmetatable(self, Pad)

    self.rack = rack

    return self
end

function Pad:setKeyRange(low, hi)
    self.rack:getMapper():setParamForPad(self, 1, low)
    self.rack:getMapper():setParamForPad(self, 2, hi)
    return self
end

function Pad:getAllTracks(tracks)
    tracks = tracks or {}

    local fx = pad:getFx()
    if fx then tracks[fx.guid] = fx end

    _.forEach(pad:getLayers(), function(track)
        tracks[track.guid] = track
    end)

    return tracks
end

function Pad:savePad()
    local tracks = self:getAllTracks()

    local data = TrackState.fromTracks(tracks)
    return _.join(data, '\n')
end

function Pad:loadPad(file)
    local selection = Track.getSelectedTracks()

    Track.setSelectedTracks({})

    reaper.Main_openProject(file)

    Track.deferAll()

    local loadedTracks = Track.getSelectedTracks()

    fx = _.find(loadedTracks, function(track)
        return _.size(track:getReceives()) > 0
    end)

    if not self:getFx() or not self:getFx():isLocked() then
        self:setFx(fx)
    end

    self:removeLayers()

    _.forEach(loadedTracks, function(layerToLoad)
        if layerToLoad ~= fx then
            self:addTrack(layerToLoad)
        end
    end)

    Track.setSelectedTracks(selection)
    return self
end

function Pad:refreshConnections()
    local fxBus = self.rack:getFx()
    local fx = self:getFx()
    local layers = self:getLayers()

    if fx then fx:routeTo(fxBus) end

    _.forEach(layers, function(layer)
        if fx and fxBus then
            layer:removeSend(fxBus)
        end
        layer:routeTo(fx or fxBus)
    end)
    return self
end

function Pad:getNext()
    return self.rack.pads[self:getIndex() + 1]
end

function Pad:getPrev()
    return self.rack.pads[self:getIndex() - 1]
end

function Pad:getAllTracks(res)
    res = res or {}
    local fx = self:getFx()
    if fx then res[fx.guid] = fx end
    _.forEach(self:getLayers(), function(layer)
        res[layer.guid] = layer
    end)
    return res
end

function Pad:setLocked(lock)
    _.forEach(self:getAllTracks(), function(track)
        track:setLocked(lock)
    end)
end

function Pad:getLocked()
    local tracks = self:getAllTracks()
    if _.size(tracks) > 0 then
        local hasLocked = false
        local hasUnlocked = false

        _.forEach(tracks, function(track)
            local locked = track:isLocked()
            hasUnlocked = hasUnlocked or not locked
            hasLocked = hasLocked or locked
        end)

        local state = (hasLocked and 1 or 0) + (hasLocked and hasUnlocked and 1 or 0)
        return state, hasLocked, hasUnlocked
    end
    return 0

end

function Pad:setSelected()
    return self.rack:setSelectedPad(self:getIndex())
end

function Pad:learn()
    self:learnLow()
    self:learnHi()
end

function Pad:learnLow()
    self.rack:getMapper():setParam(3, 1)
end

function Pad:addSelectedTracks()
    _.forEach(Track.getSelectedTracks(), function(track)
        self:addTrack(track)
    end)
end

function Pad:learnHi()
    self.rack:getMapper():setParam(4, 1)
end

function Pad:isSelected()
    return self.rack:getSelectedPad() == self
end

function Pad:hasContent()
    local layers = self:getLayers()
    return layers and _.size(layers) > 0
end

function Pad:removeFx()
    local fx = self:getFx()
    local rackFx = self.rack:getFx()
    local layers = self:getLayers()

    if fx then
        fx:remove()
        self:refreshConnections()
    end

end

function Pad:getFx(create)

    local track = _.some(self.rack:getTrack():getSends(), function(send)
        return send:getMidiSourceBus() == self:getIndex() and send:isMuted() and send:getTargetTrack()
    end)

    if create and not track and (_.size(self:getLayers()) > 0) then

        track = Track.insert(_.first(self:getLayers()):getIndex())
        track:setIcon('pads.png')
        track:setName(self.rack:getTrack():getName() .. ':' .. self:getName() ..':'.. 'fx')
        track:setVisibility(false, true)
        track:setColor(colors.fx)
        track:setType('pad')
        self:setFx(track)

    end
    return track
end

function Pad:setFx(track)
    self:removeFx()
    if track then
        local send = self.rack:getTrack():createSend(track)
        send:setMuted()
        send:setMidiBusIO(self:getIndex(), 0)
        self:refreshConnections()
    end
    return pad
end

function Pad:hasPadFx()
    return self:getFx(false)
end

function Pad:addTrack(newTrack)
    if newTrack then
        local send = self.rack:getTrack():createSend(newTrack)
        send:setMidiBusIO(self:getIndex(), 1)
        send:setAudioIO(-1, -1)
        newTrack:setParent(self:getFx() or self.rack:getTrack():getParent())
        newTrack:setIcon(newTrack:getIcon() or 'fx.png')
        newTrack:setVisibility(false, true)
        newTrack:focus()
        newTrack:setType('layer')
        newTrack:autoName()

        self:refreshConnections()
    end
end

function Pad:addLayer(path)

    local track = self.rack:getTrack()

    local layers = self:getLayers()
    local rackChildren = track:getChildren()

    local index =
        _.size(layers) > 0 and _.last(layers):getIndex()
        or _.size(rackChildren) > 0 and _.last(rackChildren):getIndex()
        or track:getIndex()

    local newTrack
    if path and type(path) == 'string' then

        if path:endsWith('.RTrackTemplate') then
            reaper.Main_openProject(path)
            newTrack = Track.getSelectedTrack()
        else
            reaper.InsertTrackAtIndex(index, true)
            newTrack = Track:create(reaper.GetTrack(0, index))

            local fx
            if reaper.file_exists(path) then
                fx = newTrack:getFx('ReaSamplomatic5000', true)
                fx:setParam('FILE0', path)
                fx:setParam('DONE', '')
                newTrack:setIcon(rea.findIcon('wave decrease'))
            else
                fx = newTrack:getFx(path, true)
            end

        end
    else
        reaper.InsertTrackAtIndex(index, true)
        newTrack = Track:create(reaper.GetTrack(0, index))
    end

    track:setSelected(1)

    self:addTrack(newTrack)

end

function Pad:removeLayers(keepLocked)
    while _.size(self:getLayers()) > 0 do
        _.first(self:getLayers()):remove()
    end
end

function Pad:clear()

    self:removeLayers()

    self:removeFx()

end

function Pad:getLayers()
    return _.map(self:getLayerConnections(), function(send) return send:getTargetTrack() end)
end

function Pad:getLayerConnections()

    local layers = {}

    _.forEach(self.rack:getTrack():getSends(), function(send)
        if send:getMidiSourceBus() == self:getIndex() and not send:isMuted() then
            table.insert(layers, send)
        end
    end)

    return layers
end

function Pad:getName()
    return tostring(self:getIndex())
end

function Pad:getIndex()
    return _.indexOf(self.rack.pads, self)
end

function Pad:flipPad(otherPad)
    local layersA = otherPad:getLayerConnections()
    local layersB = self:getLayerConnections()

    for k,v in pairs(layersA) do
        v:setMidiBusIO(self:getIndex(), 1)
    end

    for k,v in pairs(layersB) do
        v:setMidiBusIO(otherPad:getIndex(), 1)
    end
end

function Pad:copyPad(otherPad)
    _.forEach(otherPad:getLayers(), function(layer)
        self:addTrack(layer:clone():removeReceives())
    end)
end

function Pad:noteOff()
    if self:getVelocity() > 0 then
        Mem.write('drumrack', self.rack.maxNumPads + self:getIndex() - 1, -1)
    end
end

function Pad:getVelocity()
    return Mem.read('drumrack', self:getIndex() - 1)
end

return Pad
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
Mem = function()

local Mem = class()
local Watcher = require 'Watcher'
Mem.current = nil

function Mem.refreshConnection(name)

    if Mem.current ~= name then
        reaper.gmem_attach(name)
        Mem.current = name
    end
end

function Mem.write(name, index, value)
    Mem.refreshConnection(name)
    reaper.gmem_write(index, value)
end

function Mem.read(name, index)
    Mem.refreshConnection(name)
    return reaper.gmem_read(index or 0)
end

function Mem:create(name)
    local self = {name = name}
    setmetatable(self, Mem)
    return self
end

function Mem:get(index)
    return Mem.read(self.name, index)
end

function Mem:set(index, value)
    return Mem.write(self.name, index, value)
end

return Mem
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
RandomSound = function()

local ini = require 'ini'
local _ = require '_'
local Menu = require 'Menu'
local rea = require 'rea'
local TextButton = require 'TextButton'
local Component = require 'Component'

local RandomSound = class()

function RandomSound.getDataBases()
    local reaperIni = ini.load(reaper.get_ini_file())

    local basepath = reaper.GetResourcePath() .. '/MediaDB/'
    local favorite = 'ShortcutT'
    local res = {}

    _.forEach(reaperIni.reaper_sexplorer, function(value, key)
        if key:startsWith(favorite) then

            local index = key:sub(1 + favorite:len())
            filenameKey = 'Shortcut' .. index
            local filename = reaperIni.reaper_sexplorer[filenameKey]

            table.insert(res, {name = value, filename = basepath .. filename})
        end
    end)

    return res
end

function RandomSound.chooseDatabase()

    local menu = Menu:create()
    _.forEach(RandomSound.getDataBases(), function(value)
        menu:addItem(value.name, function() return value.filename, value.name end )
    end)

    return RandomSound.readDBFile(menu:show())

end

function RandomSound.readDBFile(fileName)

    if not fileName then return end

    local file = io.open(fileName, 'r')
    local res = {}
    local entry = nil
    if file then
        for line in file:lines() do

            if line:startsWith('FILE') then
                local path = line:sub(tostring('FILE'):len() + 2):split(' ', '"')[1]:unquote()
                entry = {
                    path = path,
                }
                table.insert(res, entry)
            elseif line:startsWith('DATA') then
                entry.data = {}
                local dataString = line:sub(tostring('DATA'):len() + 2 ):trim()
                local data = dataString:split(' ', '"')
                _.forEach(data, function(val, key)
                    local keyVal = val:unquote():split(':')
                    local key = keyVal[1]:trim()
                    local val = keyVal[2] and keyVal[2]:trim() or ''

                    entry.data[key] = val
                end)
            end
        end
    end

    return res

end

RandomSound.Button = class(TextButton)

function RandomSound.Button:create(text)

    local self = TextButton:create(text or '?')
    setmetatable(self, RandomSound.Button)
    return self

end

function RandomSound.Button:onButtonClick(mouse)

    if not self.db or mouse:wasRightButtonDown() then
        self.db = RandomSound.chooseDatabase()
    end

    if self.db then
        local index = math.random(1, _.size(self.db))
        local entry = self.db[index]
        reaper.OpenMediaExplorer(entry.path, true)
    end

end

return RandomSound
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

} 
require = function(name) 
    if not _dep_cache[name] then 
        _dep_cache[name] = _deps[name]() 
        end
    return _dep_cache[name] 
end 
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. "../?.lua;".. package.path

require 'boot'
addScope('tools')
addScope('drumRack')
addScope('drumRack/ui')

local Tools = require 'Tools'
local ButtonList = require 'ButtonList'
local WindowApp = require 'WindowApp'

WindowApp:create('tools', ButtonList:create(Tools, nil, nil, 0,0, 200, 600)):start()
