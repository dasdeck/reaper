
local Mouse = class()

function Mouse.capture(opts, prev)
    local self = {
        frame = opts and opts.frame,
        time = opts and opts.time,
        prev = prev,
        cap = gfx.mouse_cap,
        x = gfx.mouse_x,
        y = gfx.mouse_y,
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