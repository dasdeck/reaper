local Component = require 'Component'
local TrackToolControlls = require 'TrackToolControlls'
local TrackStateButton = require 'TrackStateButton'
local TextButton = require 'TextButton'
local FXlistAddButton = require 'FXlistAddButton'
local DelaySlider = require 'DelaySlider'
local ButtonList = require 'ButtonList'
local FXList = require 'FXList'
local La = require 'La'
local AuxUI = require 'AuxUI'
local Output = require 'Output'
local Type = require 'Type'
local Slider = require 'Slider'
local Track = require 'Track'
local GainSlider = require 'GainSlider'
local PanSlider = require 'PanSlider'
local PluginListApp = require 'PluginListApp'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local AudioTrackUI = class(Component)

function AudioTrackUI:create(track, isOutput)
    local self = Component:create()
    setmetatable(self, AudioTrackUI)

    self.track = track

    self:update()

    return self
end

function AudioTrackUI:update()
    self:deleteChildren()

    local track = self.track

    self.laAdd = self:addChildComponent(TextButton:create('+la'))
    self.laAdd.color = colors.la:fade(0.8)
    self.laAdd.onButtonClick = function(s, mouse)
        rea.transaction('create LA track', function()
            PluginListApp.pick(PluginListApp.cats.effects, function(res)

                local track = La.createLa(self.track):focus()

                -- track:setParent(self.track:getParent())
                track:setIndex(self.track:getIndex()-1)
                track:addFx(res):open()

            end)
        end)
    end

    self.la = self:addChildComponent(ButtonList:create())
    self.la.getData = function()
        return _.map(self.track:getLATracks(), function(track)
            return {
                size = 20,
                color = colors.la,
                args = track:getName(),
                onClick = function()
                    track:focus()
                end
            }
        end)
    end
    self.la:updateList()

    self.auxAdd = self:addChildComponent(TextButton:create('+aux'))
    self.auxAdd.onButtonClick = function(s, mouse)
        if mouse:wasRightButtonDown() then
            AuxUI.pickAndCreate(track)
        else
            AuxUI.pickOrCreateMenu(track)
        end
    end
    self.auxAdd.color = colors.aux:fade(0.8)

    self.aux = self:addChildComponent(ButtonList:create({}))
    self.aux.getData = function()
        return _.map(self.track:getSends(), function(send)
            return send:getTargetTrack():isAux() and {
                proto = AuxUI,
                args = send,
                size = 20
            } or nil
        end)

    end
    self.aux:updateList()

    self.type = self:addChildComponent(Type:create(track))

    self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
    self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

    self.fx = self:addChildComponent(FXList:create(track:getFxList()))
    self.fxAdd = self:addChildComponent(FXlistAddButton:create(track, '+fx'))

    if track:getTrackTool() then
        self.delay = self:addChildComponent(DelaySlider:create(track))
    end

    self.gain = self:addChildComponent(GainSlider:create(track))
    self.gain.colorValue = colors[track:getType()] or colors.default


    self.pan = self:addChildComponent(PanSlider:create(track))
    self.pan.colorValue = colors[track:getType()] or colors.default


    self.output = self:addChildComponent(Output:create(track))

    -- local output = track:getOutput() or (self.track ~= Track.master and Track.master)
    -- if output then
    --     local ui = output:createUI()
    --     if ui then
    --         self.next = self:addChildComponent(ui)
    --     end
    -- end



    if self.track:getTrackTool() then
        self.controlls = self:addChildComponent(TrackToolControlls:create(self.track))
    else
        -- self.controlls = self:addChildComponent(TextButton:create('+tracktools'))
        -- self.controlls.onButtonClick = function()
        --     rea.transaction('init tracktool', function()
        --         self.track:getTrackTool(true)
        --     end)
        -- end
    end
end

function AudioTrackUI:onMouseEnter()
    self.track:focus()
end

function AudioTrackUI:resized()

    local h = 20
    local y = 0

    -- if self.controlls then
    --     self.controlls:setBounds(0,0,self.w)
    --     y = self.controlls:getBottom() + h*5
    -- end

    self.fx:setBounds(0,y,self.w)
    y = self.fx:getBottom()

    if self.delay then
        self.fxAdd:setBounds(0,y,self.w/2, h)
        self.delay:setBounds(self.w/2,y,self.w/2, h)
    else
        self.fxAdd:setBounds(0,y,self.w, h)
    end

    y = self.fxAdd:getBottom()


    self.la:setBounds(0, y, self.w)
    y = self.la:getBottom()

    self.pan:setBounds(0, y, self.w, h)
    y = self.pan:getBottom()

    self.gain:setBounds(0, y, self.w/2, h*3)

    local w2 = self.w/2
    local w4 = self.w/4
    self.mute:setBounds(w2,y, w4, h)
    -- y = self.mute:getBottom()
    self.solo:setBounds(w2 + w4,y, w4, h)
    y = self.solo:getBottom()
    self.laAdd:setBounds(self.w/2,y, self.w/2, h)

    self.auxAdd:setBounds(self.w/2,self.laAdd:getBottom(), self.w/2, h)
    y = self.auxAdd:getBottom()

    y = self.gain:getBottom()

    self.aux:setBounds(0, y, self.w)
    y = self.aux:getBottom()

    self.output:setBounds(0,y, self.w)
    y = self.output:getBottom()

    -- if self.next then
    --     self.next:setBounds(0,y,self.w)
    --     y = self.next:getBottom()
    -- end

    self.h = y

end

return AudioTrackUI

