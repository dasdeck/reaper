local Component = require 'Component'
local TextButton = require 'TextButton'
local Track = require 'Track'
local Menu = require 'Menu'
local Bus = require 'Bus'
local colors = require 'colors'
local _ = require '_'
local rea = require 'rea'

local Output = class(Component)

function Output:create(track)
    local self = Component:create()
    setmetatable(self, Output)
    self.track = track

    self.currentOutput = self.track:getOutput()
    self.output = self:addChildComponent(TextButton:create('output'))
    self.output.color = self.currentOutput and self.currentOutput:getColor() or colors.default
    self.output.getText = function()
        local output = self.track:getOutput()
        local res
            -- return output:getName()

        if not output then
            if self.track:getValue('toParent') > 0 then
                res = 'master'
            else
                res = '--'
            end
        else
            res = output:getName()
        end

        if self.track:isMultioutRouting() and _.some(track:getInstrument():getOutputs(), function(out)
            return out.getConnection() and
            out.getConnection():getTargetTrack():getType() == 'output' and
            out.getConnection():getTargetTrack():getOutput() ~= output
        end) then
            res = res .. '*'
        end

        return res
    end

    self.expand = self:addChildComponent(TextButton:create('+'))
    self.expand.getToggleState = function()
        return track:getMeta().outputExpanded
    end
    self.expand.onButtonClick = function(s, mouse)
        rea.transaction('expand output', function()
            local next = not self.expand.getToggleState()
            track:setMeta('outputExpanded', next)

        end)
    end


    if self.expand.getToggleState() then

        local output = track:getOutput() or (self.track ~= Track.master and Track.master)
        if output then
            local ui = output:createUI()
            if ui then
                self.next = self:addChildComponent(ui)
            end
        end
    end


    return self

end

function Output:isDisabled()
    return not self.track:getOutput() and self.track:getValue('toParent') == 0
end


function Output:onClick(mouse)

    if mouse:wasRightButtonDown() then
        local menu = Menu:create()

        local busMenu = Menu:create()
        _.forEach(Track.getAllTracks(), function(otherTrack)
            -- local checked = false
            if otherTrack ~= self.track and otherTrack:isBus() then
                busMenu:addItem(otherTrack:getName() or otherTrack:getDefaultName(), {
                    callback = function()
                        self.track:setOutput(otherTrack)
                    end,
                    checked = self.currentOutput == otherTrack,
                    transaction = 'change routing'

                })
            end

        end)
        busMenu:addSeperator()
        busMenu:addItem('new bus', function()
            self.track:setOutput(Bus.createBus(), true)
        end, 'add bus')
        menu:addItem('bus', busMenu)

        menu:addItem('master', {
            checked = not self.currentOutput and self.track:getValue('toParent') > 0,
            callback = function()
                self.track:setOutput(nil)
            end
        }, 'change routing')
        menu:show()
    elseif self.currentOutput then
        self.currentOutput:focus()
    end
end

function Output:resized()

    local h = 20

    self.output:setBounds(0,0,self.w-h, h)
    self.expand:setBounds(self.w-h,0, h, h)

    local y = self.output:getBottom()

    if self.next then
        self.next:setBounds(0,y,self.w)
        y = self.next:getBottom()
    end
    self.h = y
end

return Output