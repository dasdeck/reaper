local TextButton = require 'TextButton'
local Component = require 'Component'
local ButtonList = require 'ButtonList'
local Output = require 'Output'
local FXButton = require 'FXButton'
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

    self.outputs = self:addChildComponent(ButtonList:create())
    self.outputs.getData = function()
        local rows = _.map(self.fx:getOutputs(), function(output)
            return {
                proto = function()
                    return OutputListComp:create(output, self.fx)
                end,
                size = 20
            }
        end)

        return rows
    end
    self.outputs:updateList()

    return self

end


function Outputs:resized()
    local h = 20
    local y = 0

    if self.outputs then
        self.outputs:setBounds(0,y,self.w)
        y = self.outputs:getBottom()
    end
    self.output:setBounds(0,y,self.w)
    self.h = self.output:getBottom()
end


return Outputs