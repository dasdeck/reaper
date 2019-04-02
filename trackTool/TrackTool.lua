local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TrackStateButton = require 'TrackStateButton'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Project = require 'Project'
local FXList = require 'FXList'
local Menu = require 'Menu'
local Aux = require 'Aux'
local Bus = require 'Bus'
local La = require 'La'
local AuxUI = require 'AuxUI'

local colors = require 'colors'
local rea = require 'rea'
local _ = require '_'

local TrackTool = class(Component)

function TrackTool:create(track)
    local self = Component:create()
    setmetatable(self, TrackTool)

    self.track = track

    self.watchers:watch(Project.watch.project, function()
        self:update()
    end)

    -- self:update()

    return self
end

function TrackTool:update()
    self:deleteChildren()

    local track = self.track

    self.outout = self:addChildComponent(TextButton:create('output'))
    self.currentOutput = track:getOutput()
    self.outout.color = self.currentOutput and self.currentOutput:getColor() or self.outout.color
    self.outout.onClick = function(s, mouse)

        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            local busMenu = Menu:create()
            _.forEach(Track.getAllTracks(), function(otherTrack)
                -- local checked = false
                if otherTrack ~= track and otherTrack:isBus() then
                    busMenu:addItem(otherTrack:getName() or otherTrack:getDefaultName(), {
                        callback = function()
                            track:setOutput(otherTrack)
                        end,
                        checked = self.currentOutput == otherTrack,
                        transaction = 'change routing'

                    })
                end

            end)
            busMenu:addSeperator()
            busMenu:addItem('new bus', function()
                track:setOutput(Bus.createBus(), true)
            end, 'add bus')
            menu:addItem('bus', busMenu)
            menu:addItem('master', {
                checked = not self.currentOutput and track:getValue('toParent') > 0,
                callback = function()
                    track:setOutput(nil)
                end
            }, 'change routing')
            menu:show()
        elseif self.currentOutput then
            self.currentOutput :focus()
        end
    end
    self.outout.getText = function(s, mouse)
        local output = track:getOutput()
        if not output then
            if track:getValue('toParent') > 0 then
                return 'master'
            else
                return '--'
            end
        else
            return output:getName()
        end
    end
    self.outout.isDisabled = function()
        return not track:getOutput() and track:getValue('toParent') == 0
    end

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

        b = buttons

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
        a = buttons
        return buttons

    end
    self.aux:updateList()

    self.type = self:addChildComponent(TextButton:create(''))
    self.type.getText = function()
        return track:getType() or '--'
    end
    self.type.onButtonClick = function()
        local currentType = track:getType()
        local menu = Menu:create()
        _.forEach(Track.types, function(type)
            menu:addItem(type, {
                checked = type == currentType,
                callback = function()
                    track:setType(type)
                end,
                transaction = 'set track type'
            })
        end)
        menu:show()
    end

    self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
    self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

    self.fx = self:addChildComponent(FXList:create(track))

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
    self.controlls:setBounds(0, 0, self.w, 60)
    self.outout:setBounds(0,self.controlls:getBottom(), self.w, h)
    self.la:setBounds(0,self.outout:getBottom(), self.w, self.la.h)
    self.aux:setBounds(0,self.la:getBottom(), self.w, self.aux.h)

    self.type:setBounds(0,self.aux:getBottom(), self.w, h)

    self.mute:setBounds(0,self.type:getBottom(), self.w/2, h)
    self.solo:setBounds(self.mute:getRight(),self.type:getBottom(), self.w/2, h)

    self.fx:setBounds(0,self.mute:getBottom(),self.w, self.fx.h)
end

return TrackTool

