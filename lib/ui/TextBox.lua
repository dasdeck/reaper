local Label = require 'Label'
local rea = require 'rea'
local _ = require '_'

local TextBox = class(Label)

function TextBox:create(initText, ...)
    local self = Label:create('', ...)

    self.text = initText or ''

    self.selStart = #self.text
    self.selEnd = self.selStart

    self.content.getText = function()
        return self.text
    end

    setmetatable(self, TextBox)

    return self
end

function TextBox:getText()
    return self.text
end

function TextBox:removeSelection()
    self.text = self.text:sub(0, self.selStart) .. self.text:sub(self.selEnd, -1)
end

function TextBox:onKeyPress(keycode)

    local oldText = self.text
    if keycode == 8 then --backspace

        self.text = self.text:sub(1,-2)

        local start = self.selStart - 1
        self:setSelection(start, start)

    elseif keycode == 1818584692 then --left
        local start = self.selStart - 1
        self:setSelection(start, start)
    elseif keycode == 1919379572 then --right
        local e = self.selEnd + 1
        self:setSelection(e, e)

    else
        pcall(function()
            local char = string.char(keycode)
            self.text = self.text .. char
            local sel = self.selStart + 1
            self:setSelection(sel, sel)
        end)
    end


    if self.onChange and oldText ~= self.text then
        self:onChange(self.text)
    end

    self:repaint()

end

-- function TextBox:onMouseDown(mouse)

--     x = self:getTextStartX()
--     self.text:forEachChar(function(c, i)

--         self.selStart = i - 1
--         self.selEnd = self.selStart
--         sel = i

--         if x >= self.mouse.x then
--             return false
--         else
--             x = x + gfx.measurechar(c)
--         end

--     end)

--     self:repaint()

-- end

-- function TextBox:onDrag(mouse)

--     local x = self.mouse.x

-- end

function TextBox:getTextStartX()
    local len = gfx.measurestr(self.text)
    local left = (self.w - len) / 2
    return left
end

-- function TextBox:onMouseUp(mouse)

--     local x = self.mouse.x

-- end

function TextBox:onDblClick(mouse)
    self.selStart = 1
    self.selEnd = #self.text
    self:repaint()
end

function TextBox:setSelection(start, e)
    self.selStart = math.min(#self.text, math.max(0, math.min(start, e)))
    self.selEnd = math.min(#self.text, math.max(0, math.max(start, e)))
end

function TextBox:__tostring()
    return dump(
        _.pick(self, {'selStart', 'selEnd', 'text'})
    )
end

function TextBox:getSelection()
    -- if self.hasSelection then
end

function TextBox:hasSelection()
    return self.selStart ~= self.selEnd
end

function TextBox:paint(g)

    Label.paint(self, g)

    if self.selStart and self.selEnd then
        g:setColor(0,0,0,0.3)

        if self.selStart == self.selEnd then
            local nonSel = self.text:sub(1, self.selStart)
            local selLeft = self:getTextStartX() + gfx.measurestr(nonSel)
            -- local selLen = 0--gfx.measurestr(self.text:sub(start, start))
            g:rect(selLeft, 0, 1, self.h, true)

        else

            local start = math.min(self.selStart, self.selEnd)
            local en = math.max(self.selStart, self.selEnd)

            local nonSel = self.text:sub(2, start)
            local selLeft = self:getTextStartX() + gfx.measurestr(nonSel)
            local selLen = gfx.measurestr(self.text:sub(start, en))

            g:rect(selLeft, 0, selLen, self.h, true)


        end
    end


end

return TextBox