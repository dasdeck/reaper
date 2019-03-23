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