local Component = require 'Component'
local Track = require 'Track'
local TrackTool = require 'TrackTool'
local ButtonList = require 'ButtonList'
local TextButton = require 'TextButton'
local Project = require 'Project'
local Mouse = require 'Mouse'
local Menu = require 'Menu'

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

        if track then
            if self.history.track ~= track then
                self.history.next = {prev = self.history, track = track}
                self.history = self.history.next
            end
            -- track:focus()
            -- track:touch()
        end

    end)
    self.watchers:watch(Project.watch.project, function()
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

    -- self.debug = self:addChildComponent(TextButton:create('debug'))
    -- self.debug.onButtonClick = function()
    --     -- rea.logCount('debug')
    --     local menu = Menu:create()
    --     local selected = Track.getSelectedTrack()
    --     if selected then
    --         local selMenu = Menu:create()
    --         selMenu:addItem({
    --             name = selected:getType() or '--',
    --             disabled = true
    --         })
    --         selMenu:addItem({
    --             name = selected:getManager() and selected:getManager():getSafeName() or '-',
    --             disabled = true
    --         })
    --         menu:addItem('selected', selMenu)

    --     end

    --     if self:getTrack() then
    --         local track = self:getTrack()
    --         local man = track:getManager()
    --         if man then
    --             menu:addItem('manager:' .. (man:getName() or man:getDefaultName()))
    --         end
    --     end
    --     menu:show()
    -- end


    if self:getTrack() and self:getTrack():exists() then
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
    local h = 20
    self.nav:setBounds(0,0,self.w, h)
    local y = self.nav:getBottom()

    -- self.debug:setBounds(0,y,self.w, h)
    -- y = self.debug:getBottom()

    if self.trackTool then
        self.trackTool:setBounds(0,y, self.w, self.h - y)
    end
end


return TrackToolSwitcher

