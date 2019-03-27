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