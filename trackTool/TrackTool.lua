local Component = require 'Component'
local Track = require 'Track'
local TrackToolControlls = require 'TrackToolControlls'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Project = require 'Project'
local FXList = require 'FXList'
local Menu = require 'Menu'
local Aux = require 'Aux'

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

    self.outout = self:addChildComponent(TextButton:create('output'))
    self.outout.onButtonClick = function(s, mouse)
        local menu = Menu:create()
        local busMenu = Menu:create()
        _.forEach(Track.getAllTracks(), function(otherTrack)
            -- local checked = false
            if otherTrack:isBusTrack() then
                busMenu:addItem(otherTrack:getName() or otherTrack:getDefaultName(), {
                    callback = function()
                    end,
                    checked = track:getOutput() == otherTrack

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
            size = 25,
            color = colors.la,
            onClick = function()
                rea.transaction('create LA track', function()
                    self.track:createLATrack():focus()
                end)
            end
        })

        return buttons

    end

    self.aux = self:addChildComponent(ButtonList:create({}))
    self.aux.getData = function()
        local buttons = _.map(self.track:getSends(), function(send)
            local track = send:getTargetTrack()

            return track:isAux() and {
                color = colors.aux:fade(0.8),
                args = track:getName():sub(5),
                onClick = function()
                    track:focus()
                end
            } or nil
        end)

        table.insert(buttons, {
            args = '+aux',
            size = 25,
            color = colors.aux,
            onClick = function()
                local menu = Menu:create()
                menu:addItem('create aux', function()

                    track:createSend(Aux.createAux('new'))

                end, 'create aux')

                local auxs = Aux.getAuxTracks()

                if _.size(auxs) then
                    menu:addSeperator()
                    _.forEach(auxs, function(aux)
                        menu:addItem(aux:getName():sub(5), {

                        })
                    end)
                end

                menu:show()
            end
        })

        return buttons

    end

    self:update()

    return self
end

function TrackTool:update()
    -- self:deleteChildren()
    self.la:updateList()
    self.aux:updateList()

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
    self.la:setBounds(0,self.outout:getBottom(), self.w, self.la.h)
    self.aux:setBounds(0,self.la:getBottom(), self.w, self.aux.h)
end

return TrackTool

