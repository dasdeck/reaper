local Image = require 'Image'
local Component = require 'Component'
local TrackStateButton = require 'TrackStateButton'
local TrackToolControlls = require 'TrackToolControlls'
local Menu = require 'Menu'
local InstrumentUI = require 'InstrumentUI'
local TextButton = require 'TextButton'
local _ = require '_'
local rea = require 'rea'
local paths = require 'paths'
local colors = require 'colors'

local MidiTrackUI = class(Component)

local icon = paths.iconsDir:findFile('midi.png')
function MidiTrackUI:create(track)

    local self = Component:create()
    setmetatable(self, MidiTrackUI)
    self.track = track
    self.image = self:addChildComponent(Image:create(icon, 'fit'))
    self.image.onClick = function(s, mouse)
        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            menu:addItem('show track', function()
                track:setOpen()
            end)
            menu:addItem('add midi track', function()
                local slave = track:getManager():createMidiSlave()
                slave:setArmed(1)
                slave:setSelected(1)
            end, 'add midi track')

            local utils = Menu:create()
            utils:addItem('arp', function()
                track:addFx('midi_arp'):open()
            end, 'add arp')
            utils:addItem('tools', function()
                track:addFx('MIDI_Tool II'):open()
            end)
            utils:addItem('fixed velo', function()
                track:addFx('fixed velo'):open()
            end)
            menu:addItem('midi utils', utils)
            menu:show()
        else
            rea.transaction('toggle track arm', function()
                self.track:setArmed(not self.track:isArmed())
            end)
        end
    end
    self.controlls = self:addChildComponent(TrackToolControlls:create(track))
    self.mute = self:addChildComponent(TrackStateButton:create(track, 'mute', 'M'))
    self.solo = self:addChildComponent(TrackStateButton:create(track, 'solo', 'S'))

    self.midiOutputs = self:addChildComponent(TextButton:create('out'))

    local sends = track:getSends()

    local targetTrack = _.some(sends, function(send) return send:getTargetTrack() end)

    if targetTrack then
        self.midiOutputs.content.text = targetTrack:getName()
        local ui = targetTrack:createUI()
        if ui then
            self.targetTrack = self:addChildComponent(ui)
        end
    end

    return self
end

function MidiTrackUI:paint(g)
    if self.track:isArmed() then
        g:setColor(colors.arm:with_alpha(0.6))
    else
        g:setColor(colors.default:with_alpha(0.6))
    end
    g:circle(self.w / 2, self.image.h/2, self.image.h/2, true )
    g:rect(0,0, self.w, self.solo:getBottom(), true )
end

function MidiTrackUI:resized()
    local h = 20
    local y = 0
    self.image:setBounds(0,y, self.w, h * 2)
    y  = self.image:getBottom()

    self.controlls:setBounds(0, y, self.w, 40)
    y = self.controlls:getBottom()

    self.mute:setBounds(0,y, self.w/2, h)
    self.solo:setBounds(self.mute:getRight(),y, self.w/2, h)

    y = self.solo:getBottom()

    self.midiOutputs:setBounds(0,y,self.w, h)
    y = self.midiOutputs:getBottom()

    if self.targetTrack then
        self.targetTrack:setBounds(0, y, self.w)
    end
end

return MidiTrackUI