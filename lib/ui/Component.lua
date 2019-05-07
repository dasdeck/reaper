require 'Util'
local Mouse = require 'Mouse'
local Graphics = require 'Graphics'
local WatcherManager = require 'WatcherManager'

local _ = require '_'
local color = require 'color'
local rea = require 'rea'


local Component = class()

Component.componentIds = 1

Component.slots = {[1] = true}
for i = 2, 1023 do
    Component.slots[i] = false
end

function Component:create(x, y, w, h)

    local self = {
        x = x or 0,
        y = y or 0,
        w = w or 0,
        h = h or 0,
        bufferToImage = true,
        repaintOnMouseEnterOrLeave,
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

    self:repaint()

    return self
end

function Component:__guessName()
    local metatable = getmetatable(self)
    local test = debug.getinfo(metatable.create)
    return test
end

function Component:getSlot(name, create, error)

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

            if not slot and error then
                error()
                return self:getSlot(name, create)
            else
                assert(slot, 'out of image slots')
            end
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

    self:freeSlots()
    if self.onDelete then self:onDelete() end
    _.forEach(self.children, function(comp)
        comp:triggerDeletion()
    end)

end

function Component:freeSlots()

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

function Component:canClickThrough()
    return true
end

function Component:isMouseDown()
    return self:isMouseOver() and self.mouse:isButtonDown()
end

function Component:updateMousePos(mouse, x, y)
    x = x or mouse.x
    y = y or mouse.y
    self.mouse.cap = mouse.cap
    self.mouse.mouse_wheel = mouse.mouse_wheel
    self.mouse.x = x
    self.mouse.y = y
    _.forEach(self.children, function(child)
        child:updateMousePos(mouse, x - child.x, y - child.y)
    end)
end

-- function Component:updateMousePos(mouse)
--     self.mouse.cap = gfx.mouse_cap
--     self.mouse.mouse_wheel = mouse.mouse_wheel
--     self.mouse.x = mouse.x - self:getAbsoluteX()
--     self.mouse.y = mouse.y - self:getAbsoluteY()
-- end

function Component:isMouseOver()
    local window
    return self.mouse.x >= 0 and self.mouse.y >= 0 and self.mouse.x <= self.w and self.mouse.y <= self.h
    -- return
    --     gfx.mouse_x <= self:getAbsoluteRight() and
    --     gfx.mouse_x >= self:getAbsoluteX() and
    --     gfx.mouse_y >= self:getAbsoluteY() and
    --     gfx.mouse_y <= self:getAbsoluteBottom()
end

function Component:wantsMouse()
    return self.isCurrentlyVisible-- and (not self.parent or self.parent:wantsMouse())
end

function Component:getAbsoluteX()
    local parentOffset = self.parent and self.parent:getAbsoluteX() or 0
    if type(self.x) ~= 'number' then
        rea.logPin('x', self.x)
    end
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
    return self.visible --and (self.w > 0 or self.h > 0) and (not self.parent or self.parent:isVisible()) and self:getAlpha() > 0
end


function Component:setSize(w,h)

    w = w == nil and self.w or w
    h = h == nil and self.h or h

    if self.w ~= w or self.h ~= h then

        self.w = w
        self.h = h

        self:resized()
        self:repaint(true)
    end

end

function Component:setPosition(x,y)

    x = x == nil and self.x or x
    y = y == nil and self.y or y

    self.x = x
    self.y = y
end

function Component:repaintOnMouse()
    return self.repaintOnMouseEnterOrLeave
end

function Component:setBounds(x,y,w,h)
    self:setPosition(x,y)
    self:setSize(w, h)
end

function Component:getWindow()
    if self.window then return self.window
    elseif self.parent then
        local window = self.parent:getWindow()
        assert(window, 'has no window?')
        return window
    else
        assert(false, 'no parent no window?')
    end
end

function Component:repaint(children)
    self.needsPaint = true

    if children == true then
        _.forEach(self.children, function(child)
            child:repaint(children)
        end)
    end

end

function Component:resized()
    _.forEach(self.children, function(child)
        child:setSize(self.w, self.h)
    end)
end

function Component:paintInline(g)

    local x = g.x
    local y = g.y

    g.y = g.y + self.y
    g.x = g.x + self.x

    self:paint(g)
    self.needsPaint = false

    g.y = y
    g.x = x

    self.drawn = true

end

function Component:evaluate(g, dest, x, y, overlay)

    if self.drawn then return end

    x = x or 0
    y = y or 0

    dest = dest or 1
    g = g or Graphics:create()

    self.isCurrentlyVisible = self:isVisible()
    if not self.isCurrentlyVisible or (self.overlayPaint and not overlay) then
        return
    end

    local alpha = self:getAlpha()
    local area = self.w * self.h * alpha
    local hasVisibleArea = area > 0

    local doRePaint = (self.needsPaint or (self:getWindow() or {}).doRePaint == 'all')

    if self.paint and hasVisibleArea then
        local pslot = self:getSlot('component:' .. tostring(self.id) .. ':paint')
        if doRePaint then
            g:startBuffering(self, pslot)
            self:paint(g)
        end

        g:applyBuffer(pslot, x, y, alpha, dest)

    end

    self:evaluateChildren(g, dest, x, y)

    if self.paintOverChildren and hasVisibleArea then
        local poslot = self:getSlot('component:' .. tostring(self.id) .. ':paintOverChildren')
        if doRePaint then
            g:startBuffering(self, poslot)
            self:paintOverChildren(g)
        end

        g:applyBuffer(poslot, x, y, alpha, dest)

    end

    self.needsPaint = false
end

function Component:evaluateChildren(g, dest, x, y)
    _.forEach(self.children,function(comp)
        assert(comp.parent == self, 'comp has different parent')
        comp:evaluate(g, dest, x + comp.x, y + comp.y)
    end)
end

function Component:setWindow(window)
    self.window = window
    _.forEach(self.children, function(child)
        child:setWindow(window)
    end)
end

function Component:addChildComponent(comp, key)

    assert(key == nil, 'key usage is deprecated')

    if comp then
        comp.parent = self
        if self.window then
            comp:setWindow(self:getWindow())
        end
        table.insert(self.children, comp)
    end

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