local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TrackStateButton = require 'TrackStateButton'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Project = require 'Project'
local FXList = require 'FXList'
local Menu = require 'Menu'
local Bus = require 'Bus'
local La = require 'La'
local AuxUI = require 'AuxUI'
local Mouse = require 'Mouse'
local DrumRack = require 'DrumRack'
local PadGrid = require 'PadGrid'
local Output = require 'Output'
local Outputs = require 'Outputs'
local Type = require 'Type'
local Slider = require 'Slider'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local TrackTool = class(Component)

function TrackTool:create(track)
    local self = Component:create()
    setmetatable(self, TrackTool)

    self.track = track
    self:update()

    return self
end

function TrackTool:update()
    self:deleteChildren()

    local track = self.track

    local inlineUI = track:getInlineUI()
    if inlineUI then
        self.inline = self:addChildComponent(inlineUI)
    end

    self.output = self:addChildComponent(Output:create(track))

    self.la = self:addChildComponent(ButtonList:create({}))
    self.la.getData = function()
        local buttons = _.map(self.track:getLATracks(), function(track)
            return {
                color = colors.la,
                args = track:getName(),
                onClick = function()
                    track:focus()
                end
            }
        end)

        table.insert(buttons, {
            args = '+la',
            size = 15,
            color = colors.la:fade(0.8),
            onClick = function()
                rea.transaction('create LA track', function()
                    La.createLa(self.track):focus()
                end)
            end
        })

        return buttons

    end
    self.la:updateList()

    self.aux = self:addChildComponent(ButtonList:create({}))
    self.aux.getData = function()
        local buttons = _.map(self.track:getSends(), function(send)
            return send:getTargetTrack():isAux() and {
                proto = AuxUI,
                args = send,
                size = 20
            } or nil
        end)

        table.insert(buttons, {
            args = '+aux',
            size = 15,
            color = colors.aux:fade(0.8),
            onClick = function(s, mouse)
                if mouse:wasRightButtonDown() then
                    AuxUI.pickAndCreate(track)
                else
                    AuxUI.pickOrCreateMenu(track)
                end

            end
        })
        return buttons

    end
    self.aux:updateList()

    self.type = self:addChildComponent(Type:create(track))


    self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
    self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

    self.fx = self:addChildComponent(FXList:create(track:getFxList()))

    self.gain = self:addChildComponent(Slider:create())
    self.watchers:watch(function()
        return self.track:getVolume()
    end, function()
        self.gain:repaint(true)
    end)
    self.gain.pixelsPerValue = 10
    self.gain.getValue = function()
        return round(self.track:getVolume(),10)
    end
    self.gain.setValue = function(s, volume)
        self.track:setVolume(volume)
    end
    self.gain.getMin = function()
        return -60
    end
    self.gain.getMax = function()
        return 10
    end

    self.pan = self:addChildComponent(Slider:create())
    self.watchers:watch(function()
        return self.track:getPan()
    end, function()
        self.pan:repaint(true)
    end)
    self.pan.pixelsPerValue = 100
    self.pan.bipolar = 0
    self.pan.wheelscale = 0.01
    self.pan.getText = function()
        return tostring(round(self.pan:getValue() * 100)) .. ' %'
    end
    self.pan.getValue = function()
        return self.track:getPan()
    end
    self.pan.setValue = function(s, volume)
        self.track:setPan(volume)
    end
    self.pan.getMin = function()
        return -1
    end
    self.pan.getMax = function()
        return 1
    end

    self.outputs = self:addChildComponent(Outputs:create(track))

    if self.track:getTrackTool() then
        self.controlls = self:addChildComponent(TrackToolControlls:create(self.track))
    else
        self.controlls = self:addChildComponent(TextButton:create('+tracktools'))
        self.controlls.onButtonClick = function()
            rea.transaction('init tracktool', function()
                self.track:getTrackTool(true)
            end)
        end

    end

end

function TrackTool:resized()

    local h = 20
    local y = 0

    if self.inline then
        self.inline:fitToWidth(self.w)
        y = self.inline:getBottom()
    end

    self.controlls:setBounds(0, y, self.w, 60)
    y = self.controlls:getBottom()

    if self.track:wantsAudioControlls() then
        self.output:setBounds(0,self.controlls:getBottom(), self.w, h)
        self.la:setBounds(0,self.output:getBottom(), self.w, self.la.h)
        self.aux:setBounds(0,self.la:getBottom(), self.w, self.aux.h)
        y = self.aux:getBottom()
    end

    self.type:setBounds(0,y, self.w, h)
    y = self.type:getBottom()

    self.mute:setBounds(0,y, self.w/2, h)
    self.solo:setBounds(self.mute:getRight(),y, self.w/2, h)

    y = self.solo:getBottom()

    if self.track:wantsAudioControlls() then
        self.fx:setBounds(0,self.mute:getBottom(),self.w)
        self.fx:resized()
        y = self.fx:getBottom()
    end

    self.outputs:setBounds(0,y, self.w)
    y = self.outputs:getBottom()

    self.pan:setBounds(0, self.h - 230, self.w, 30)
    self.gain:setBounds(0, self.h - 200, 50, 200)
end

return TrackTool

