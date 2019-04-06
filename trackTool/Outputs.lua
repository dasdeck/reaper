local TextButton = require 'TextButton'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Output = require 'Output'
local colors = require 'colors'
local OutputListComp = require 'OutputListComp'
local rea = require 'rea'
local _ = require '_'

local Outputs = class(Component)

function Outputs:create(track)
    local self = Component:create()
    setmetatable(self, Outputs)
    self.track = track
    self.fx = track:getInstrument()

    self.output = self:addChildComponent(Output:create(track))

    if self.fx and self.fx:canDoMultiOut() then
        self.outputs = self:addChildComponent(ButtonList:create())
        self.outputs.getData = function()
            local showAll = track:getMeta('showOutputs', false)
            local rows = _.map(self.fx:getOutputs(), function(output)
                -- rea.log(output.name)
                local con = output.getConnection()
                local size = 20
                if con and con:getTargetTrack():isFocused() then
                    size = nil
                end

                return (showAll or con) and {
                    proto = OutputListComp,
                    args = output,
                    size = size
                } or nil
            end)

            table.insert(rows, {
                getText = function() return showAll and '-' or  '+' end,
                onClick = function()
                    track:setMeta('showOutputs', not showAll)
                    self.outputs:updateList()

                    if self.parent then self.parent:resized() end
                end
            })
            return rows
        end
        self.outputs:updateList()
    end

    return self

end


function Outputs:resized()
    local h = 20
    if self.outputs then
        self.outputs:setSize(self.w)
        self.h = self.outputs.h
    else
        self.output:setSize(self.w, h)
        self.h = h
    end
end


return Outputs