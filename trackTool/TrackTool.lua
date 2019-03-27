local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TextButton = require 'TextButton'
local Project = require 'Project'
local FXList = require 'FXList'
local Menu = require 'Menu'

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

    self:update()

    self.outout = self:addChildComponent(TextButton:create('output'))
    self.outout.onButtonClick = function(s, mouse)
        local menu = Menu:create()
        local busMenu = Menu:create()
        _.forEach(Track.getAllTracks(), function(otherTrack)
            -- local checked = false
            if otherTrack:isBusTrack() then
                busMenu:addItem(otherTrack:getName() or otherTrack:getDefaultName(), {
                    callback = function()
                    end
                })
            end
        end)
        menu:addItem('bus', busMenu)
        menu:show()
    end
    self.outout.getText = function(s, mouse)
        if track:getValue('toParent') > 0 then
            return 'master'
        else
            return _.some(track:getSends(), function(send)
                local i, o = send:getAudioIO()
                local t = send:getTargetTrack()
                return i == 0 and o == 0 and ('> ' .. (t:getName() or t:getDefaultName()))
            end)
        end
    end

    self.outout.isDisabled = function()
        return track:getValue('toParent') > 0
    end
    return self
end

function TrackTool:update()
    -- self:deleteChildren()

    if self.controlls then self.controlls:delete() end

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

    self.controlls:setBounds(0, 0, self.w, 60)
    self.outout:setBounds(0,self.controlls:getBottom(), self.w, 20)
end

return TrackTool

