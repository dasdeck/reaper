local Component = require 'Component'
local ButtonList = require 'ButtonList'
local SequenceEditor = require 'SequenceEditor'
local Project = require 'Project'
local MediaItem = require 'MediaItem'

local rea = require 'rea'
local _ = require '_'

local Sequencer = class(Component)

function Sequencer:create()
    local self = Component:create()
    setmetatable(self, Sequencer)

    self.buttons = self:addChildComponent(ButtonList:create({}, true))
    self.buttons.isDisabled = function()
        return not self.sequence
    end
    self.buttons.getData = function()
        local taks = self.item and _.map(self.item:getTakes(), function(take, i)
            return {
                args = tostring(i),
                getToggleState = function()
                    return take:isActive()
                end,
                onClick = function(s, mouse)
                    if mouse:isAltKeyDown() then
                        take:remove()
                    else
                        rea.transaction('set active take', function()
                            take:setActive()
                        end)
                    end
                end
            }
        end)
        local btn = _.concat(taks, {
            {
                args = '+',
                onClick = function()
                    rea.transaction('copy active take', function()
                        reaper.Main_OnCommand(40639, 0)
                    end)
                end
            }
        },_.map({3,6,4,8,16,32}, function(num)
            return {
                onClick = function()
                    self.sequence.numSteps = num
                    self:repaint(true)
                end,
                args = tostring(num) .. '/4',
                getToggleState = function()
                    return self.sequence and self.sequence.numSteps == num
                end
            }
        end))
        -- rea.log(btn)
        return btn
    end

    self.watchers:watch(Project.watch.project, function()
        local all = MediaItem.getSelectedItems()
        local item = _.first(all)
        self:setMediaItem(item)
    end)

    return self
end

function Sequencer:setMediaItem(item)
    self.item = item
    self:setTake(item and item:getActiveTake())
    self.buttons:updateList()
    self:resized()
end

function Sequencer:setTake(take)

    if self.sequence and self.sequence.take == take then return end

    if self.sequence then
        self.sequence:delete()
    end

    if take then
        self.sequence = self:addChildComponent(SequenceEditor:create(take))
    end
    self:resized()
    self:repaint(true)

end

function Sequencer:resized()
    local h = 20
    self.buttons:setBounds(0,0,self.w, h)
    if self.sequence then
        self.sequence:setBounds(0,h, self.w, self.h - h)
    end
end

return Sequencer