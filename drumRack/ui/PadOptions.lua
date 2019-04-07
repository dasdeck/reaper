local colors = require 'colors'
local Menu = require 'Menu'
local Slider = require 'Slider'
local rea = require 'rea'
local Mouse = require 'Mouse'
local FXButton = require 'FXButton'

return function(pad)
    return {
        -- {
        --     proto = function()
        --         return FXButton:create(pad)
        --     end
        -- },
        -- {
        --     args = 'hold',
        --     getToggleState = function()
        --         return pad.rack:getMapper():getParam(8)
        --     end,
        --     getText = function (self)
        --         local val = self:getToggleState()
        --         return val == 1 and 'hold:time' or val == 2 and 'hold:inf' or 'release'
        --     end,
        --     isDisabled = function()
        --         return pad.rack:isSplitMode()
        --     end,
        --     onClick = function(self)
        --         local val = self:getToggleState()
        --         :show()
        --     end
        -- },
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
        -- {
        --     args = 'choke',
        --     getToggleState = function()
        --         return pad.rack:getMapper():getParam(10) > 0
        --     end,
        --     isDisabled = function()
        --         return pad.rack:isSplitMode()
        --     end,
        --     getText = function (self)
        --         local val = self:getToggleState()
        --         return val == 0 and 'choke:--' or 'choke:' .. tostring(val)
        --     end,
        --     onClick = function(self)

        --         menu:show()
        --     end
        -- },
    }
end