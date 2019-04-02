local Component = require 'Component'
local Track = require 'Track'
local TrackTool = require 'TrackTool'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'

local rea = require 'rea'
local _ = require '_'

local TrackToolSwitcher = class(Component)

function TrackToolSwitcher:create(...)
    local self = Component:create(...)
    setmetatable(self, TrackToolSwitcher)

    self.indexInHistory = 1

    self.history = {track = Track.getFocusedTrack(true)}

    self.watchers:watch(Track.watch.focusedTrack, function()

        local track = Track.getFocusedTrack(true)
        -- if track then
        if self.history.track ~= track then
            self.history.next = {prev = self.history, track = track}
            self.history = self.history.next
            self:update()
        end
        if track then track:touch() end
        -- end
    end)

    self.nav = self:addChildComponent(ButtonList:create({
        {
            proto = function()
                local enabled = self.history.prev and self.history.prev.track and self.history.prev.track:exists()
                local button = TextButton:create('<')
                button.disabled = not enabled
                if enabled then
                    local track = self.history.prev.track
                    button.getText = function() return (track:getName() or track:getDefaultName()) .. ' <' end
                    button.color = track:getColor() or button.color
                    button.onClick = function()
                        self.history = self.history.prev
                        self:update()
                        self.history.track:focus()
                        self:repaint(true)
                    end
                end
                return button
            end,
            size = -0.5
        },
        {
            proto = function()
                local enabled = self.history.next and self.history.next.track and self.history.next.track:exists()
                local button = TextButton:create('>')
                button.disabled = not enabled
                if enabled then
                    local track = self.history.next.track
                    button.getText = function() return '> ' .. (track:getName() or track:getDefaultName()) end
                    button.color = track:getColor() or button.color
                    button.onClick = function()
                        self.history = self.history.next
                        self:update()
                        self.history.track:focus()
                        self:repaint(true)
                    end
                end
                return button
            end,
            size = -0.5

        }
    }, true))

    self:update()

    return self
end

function TrackToolSwitcher:getTrack()
    return self.history.track
end

function TrackToolSwitcher:update()


    if self.trackTool then
        self.trackTool:delete()
    end

    if self:getTrack() then
        self.trackTool = self:addChildComponent(TrackTool:create(self:getTrack()))
    else
        self:relayout()
    end

    self.nav:updateList()
end

function TrackToolSwitcher:resized()
    self.nav:setBounds(0,0,self.w, 20)
    if self.trackTool then
        self.trackTool:setBounds(0,self.nav:getBottom(),self.w, self.h - self.nav:getBottom())
    end
end


return TrackToolSwitcher

