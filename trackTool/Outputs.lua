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

    -- self.multi = self:addChildComponent(TextButton:create('mult'))
    -- self.multi.onButtonClick = function(s, mouse)
    --     local enableMulti = not self.multi.getToggleState()
    --     local output = track:getOutputConnection()

    --     rea.transaction('enable multi', function()
    --         if output then
    --             output:setMuted(enableMulti)
    --         else
    --             track:setValue('toParent', (not enableMulti) and 1 or 0)
    --         end

    --         _.forEach(self.fx:getOutputs(), function(out)
    --             local con = out.getConnection()
    --             if con then con:setMuted(not enableMulti) end
    --         end)
    --     end)

    -- end
    -- self.multi.isDisabled = function()
    --     return not self.fx or not self.fx:canDoMultiOut()
    -- end

    -- self.multi.getToggleState = function()
    --     return track:isMultioutRouting()
    -- end

    -- local showAll = track:getMeta('showOutputs')

    -- self.expand = self:addChildComponent(TextButton:create('+'))
    -- self.expand.getText = function() return
    --     showAll and '-' or  '+'
    -- end
    -- self.expand.isDisabled = function()
    --     return not self.multi.getToggleState()
    -- end

    -- self.expand.onButtonClick = function()
    --     rea.transaction('show all multi', function()
    --         track:setMeta('showOutputs', not showAll)
    --         self.outputs:updateList()
    --         if self.parent then self.parent:resized() end
    --     end)
    -- end

    self.output = self:addChildComponent(Output:create(track))

    -- if self.multi.getToggleState() then

    self.outputs = self:addChildComponent(ButtonList:create())
    self.outputs.getData = function()
        local rows = _.map(self.fx:getOutputs(), function(output)
            -- local con = output.getConnection()
            local size = 20
            -- if con and con:getTargetTrack():getMeta().expanded then
            --     size = true
            -- end

            return {
                proto = OutputListComp,
                args = output,
                size = size
            }
        end)

        return rows
    end
    self.outputs:updateList()
    -- end

    return self

end


function Outputs:resized()
    local h = 20
    local y = 0
    -- self.multi:setBounds(0,0,self.w/2, h)
    -- self.expand:setBounds(self.w/2,0,self.w/2, h)
    -- local y = self.multi:getBottom()

    -- if self.mult.get
    if self.outputs then
        self.outputs:setBounds(0,y,self.w)
        y = self.outputs:getBottom()
    end
    self.output:setBounds(0,y,self.w)
    self.h = self.output:getBottom()
end


return Outputs