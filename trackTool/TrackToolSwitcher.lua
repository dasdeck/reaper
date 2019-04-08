local Component = require 'Component'
local Track = require 'Track'
local TrackTool = require 'TrackTool'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'
local Project = require 'Project'
local Mouse = require 'Mouse'

local rea = require 'rea'
local _ = require '_'

local TrackToolSwitcher = class(Component)

function TrackToolSwitcher:create(...)
    local self = Component:create(...)
    setmetatable(self, TrackToolSwitcher)

    self.indexInHistory = 1

    self.history = {track = Track.getSelectedTrack()}
    self.watchers:watch(Track.watch.selectedTrack,
    function(track)

        rea.logCount('Track.watch.selectedTrack')

        -- rea.logCount('update')
        if self.history.track ~= track then
            self.history.next = {prev = self.history, track = track}
            self.history = self.history.next
            -- self:update()
        end
        if track then
            track:focus()
            track:touch()
        end

    end)
    -- -- self.watchers:watch(Track.watch.selectedTrack, function(track)
    --     Track.mem:set(0, track and track:getIndex() or -1)
    -- end)
    self.watchers:watch(Project.watch.project, function()
        rea.logCount('Project.watch.project')
        if not Mouse.capture():isButtonDown()then
            self:update()
        end
    end)


    self:update()

    return self
end

function TrackToolSwitcher:getTrack()
    return self.history.track
end

function TrackToolSwitcher:update()

    self:deleteChildren()

    self.nav = self:addChildComponent(ButtonList:create({
        {
            proto = function()
                local enabled = self.history.prev and self.history.prev.track and self.history.prev.track:exists()
                local button = TextButton:create('<')
                button.disabled = not enabled
                if enabled then
                    local track = self.history.prev.track
                    local name = (track:getName() or track:getDefaultName()) or ''
                    button.getText = function() return name  .. ' <' end
                    button.color = track:getColor() or button.color
                    button.onClick = function()
                        self.history = self.history.prev
                        self:update()
                        self.history.track:setSelected(1)
                        self:repaint(true)
                    end
                end
                return button
            end
        },
        {
            proto = function()
                local enabled = self.history.next and self.history.next.track and self.history.next.track:exists()
                local button = TextButton:create('>')
                button.disabled = not enabled
                if enabled then
                    local track = self.history.next.track
                    local name = (track:getName() or track:getDefaultName()) or ''
                    button.getText = function() return '> ' .. name end
                    button.color = track:getColor() or button.color
                    button.onClick = function()
                        self.history = self.history.next
                        self:update()
                        self.history.track:setSelected(1)
                        self:repaint(true)
                    end
                end
                return button
            end

        }
    }, true))


    if self:getTrack() and self:getTrack():exists() then
        rea.logCount('updateSwitcher')
        self.currentTrack = self:getTrack()
        local comp = self:getTrack():createUI()-- or TrackTool:create(self:getTrack())
        if comp then
            self.trackTool = self:addChildComponent(comp)
        end
    end

    self:resized()
    self:repaint()

end

function TrackToolSwitcher:resized()
    self.nav:setBounds(0,0,self.w, 20)
    if self.trackTool then
        self.trackTool:setBounds(0,self.nav:getBottom(),self.w, self.h - self.nav:getBottom())
    end
end


return TrackToolSwitcher

