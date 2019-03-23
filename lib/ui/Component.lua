require 'Util'
local Mouse = require 'Mouse'
local Graphics = require 'Graphics'

local _ = require '_'
local color = require 'color'
local rea = require 'rea'

local Component = class()

function Component:create(x, y, w, h)
    local obj = {
        x = x or 0,
        y = y or 0,
        w = w or 0,
        h = h or 0,
        alpha = 1,
        isComponent = true,
        visible = true,
        children = {},
        mouse = Mouse.capture()
    }

    setmetatable(obj, Component)
    return obj
end

function Component:getAllChildren(results)
    results = results or {}

    for k, child in rpairs(self.children) do
        child:getAllChildren(results)
    end

    table.insert(results, self)

    return results
end

function Component:getComponentsUnderMouse()
    local results = {}
    for k, child in pairs(self:getAllChildren()) do
        if self:interceptsMouse() and self:isMouseOver() then
            table.insert(results, self)
        end
    end
    return results
end

function Component:deleteChildren()
    _.forEach(self.children, function(comp)
        comp:delete()
    end)
end

function Component:triggerDeletion()
    if self.onDelete then self:onDelete() end
    _.forEach(self.children, function(comp)
        comp:triggerDeletion()
    end)
end

function Component:delete(doNotRemote)
    self:triggerDeletion()
    if not doNotRemote then
        self:remove()
        collectgarbage()
    end
end

function Component:interceptsMouse()
    return true
end

function Component:scaleToFit(w, h)

    local scale = math.min(self.w  / w, self.h / h)

    self.w = self.w / scale
    self.h = self.h / scale

    return self

end

function Component:setAlpha(alpha)
    self.alpha = alpha
end

function Component:getAlpha()
    return self.alpha * (self.parent and self.parent:getAlpha() or 1)
end

function Component:fitToWidth(wToFit)

    local scale = wToFit / self.w
    self.w = wToFit
    self.h = self.h * scale

    return scale
end

function Component:fitToHeight(hToFit)

    local scale = hToFit / self.h
    self.h = hToFit
    self.w = self.w * scale

    return scale
end

function Component:clone()
    local comp = _.assign(Component:create(), self)
    setmetatable(comp, getmetatable(self))
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
    return self:isVisible() and (not self.parent or self.parent:wantsMouse())
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
    self.w = w == nil and self.w or w
    self.h = h == nil and self.h or h
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

function Component:repaint()
    if self:isVisible() then
        local win = self:getWindow()
        if win then
            win.repaint = true
        end
    end
end

function Component:resized()
    _.forEach(self.children, function(child)
        child:setSize(self.w, self.h)
    end)
end

function Component:evaluate(g)

    g = g or Graphics:create()

    if not self:isVisible() then return end

    if self.resized then
        self:resized()
    end

    if self.paint then
        g:setFromComponent(self)
        self:paint(g)
    end

    self:evaluateChildren()

    if self.paintOverChildren then
        g:setFromComponent(self)
        self:paintOverChildren(g)
    end
end

function Component:addChildComponent(comp, key)
    comp.parent = self
    if key then
        self.children[key] = comp
    else
        table.insert(self.children, comp)
    end
    return comp
end

function Component:remove()
    if self.parent then
        _.removeValue(self.parent.children, self)
        self.parent = nil
    end
end

function Component:evaluateChildren(g)
    for i, comp in pairs(self.children) do
        comp.parent = self
        comp:evaluate(g)
    end
end

return Component