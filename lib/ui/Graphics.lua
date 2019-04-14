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

function Graphics:applyBuffer(slot, x, y, alpha, dest)
    gfx.dest = dest
    gfx.a = alpha
    gfx.x = x
    gfx.y = y
    gfx.blit(slot, 1, 0)
end

function Graphics:clear()
    gfx.dest = 1

    self:resetSlot(1, gfx.w, gfx.h)

    self:setColor(32/255,32/255,32/255,1)
    self:rect(0,0,gfx.w,gfx.h, true)

end

function Graphics:resetSlot(slot, w, h)
    gfx.setimgdim(slot, -1, -1)
    gfx.setimgdim(slot, w, h)
    gfx.dest = slot
end


function Graphics:startBuffering(comp, slot, paint)

    assert(comp.w > 0)
    assert(comp.h > 0)
    assert(slot >= 0)

    self.a = 1
    self:resetSlot(slot, comp.w, comp.h)
    self.x = 0
    self.y = 0
    gfx.y = 0
    gfx.x = 0

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
    gfx.x = self.x + x
    gfx.y = self.y + y

    assert(scale > 0)
    assert(scale < 50)

    gfx.blit(slot, scale or 1, 0)

end

function Graphics:drawText(text, x, y, w, h, just)
    self:loadColors()
    gfx.x = self.x + x
    gfx.y = self.y + y

    if just == nil then
        just = 0
    elseif just == 1 then
        just = 1
    elseif just == 2 then
        just = 2
    end

    gfx.drawstr(text, just | 4 | 256, gfx.x + w , gfx.y + h)
end

function Graphics:drawFittedText(text, x, y, w, h, ellipes, just)
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

    self:drawText(text, x, y, w, h, just)

end

function Graphics:roundrect(x, y, w, h, r, fill, aa)

    self:loadColors()

    r = r or 3
    r = math.ceil(math.min(math.min(w,h)/2, r))

    if fill then

        self:rect(x, y + r, w, h - 2 * r, fill)

        self:rect(x+r, y , w- 2*r, r, fill)
        self:rect(x+r, y + h - r , w- 2*r, r, fill)

        local dest = gfx.dest

        gfx.dest = 0

        gfx.setimgdim(0, -1, -1)
        gfx.setimgdim(0, r * 2, r * 2)
        gfx.circle(r, r, r, fill, aa)

        gfx.dest = dest

        gfx.blit(0, 1, 0, 0, 0, r, r, self.x + x, self.y + y)
        gfx.blit(0, 1, 0, r, 0, r, r, self.x + w - r + x, self.y + y)
        gfx.blit(0, 1, 0, 0, r, r, r, self.x + x, self.y + h - r + y)

        gfx.blit(0, 1, 0, r, r, r, r, self.x + w - r + x, self.y + h - r + y)

    else
        gfx.roundrect(self.x + x, self.y + y, w, h, r*2, aa)
    end
end

function Graphics:rect(x, y, w, h, fill)
    self:loadColors()
    gfx.rect(self.x + x, self.y + y, w, h, fill)
end


return Graphics