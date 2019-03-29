-- dep header --
local _dep_cache = {} 
local _deps = { 
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

} 
require = function(name) 
    if not _dep_cache[name] then 
        _dep_cache[name] = _deps[name]() 
        end
    return _dep_cache[name] 
end 
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."../?.lua;".. package.path


require 'Util'
local rea = require 'rea'
local TextButton = require 'TextButton'


local project = 40021

reaper.Main_OnCommand(project,0)

local notes = reaper.GetSetProjectNotes(0, false, '')

parts = notes:split('lyrics:')

local lyrics = parts[2]
rea.setLyrics(lyrics)
