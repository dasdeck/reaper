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
            end
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

