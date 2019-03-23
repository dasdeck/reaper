local Component = require 'Component'
local TextButton = require 'TextButton'
local Menu = require 'Menu'
local Directory = require 'Directory'

local _ = require '_'
local rea = require 'rea'

local DirFlipper = class(Component)

function DirFlipper:create(dir, initialFile, filter)
    local self = Component:create()
    setmetatable(self, DirFlipper)

    self.directory = Directory:create(dir, filter)

    self.file = self:addChildComponent(TextButton:create('test'), 'file')
    self.file.getText = function()
        return _.last(self:getCurrentFile():split('/'))
    end

    self.file.onButtonClick = function()
        local res = self.directory:listAsMenu(self.index)
        if res then self.index = res end
    end

    self.prev = self:addChildComponent(TextButton:create('<'), 'prev')
    self.prev.onClick = function()
        local newIndex = self.index - 1
        self.index = newIndex >= 1 and newIndex or #self:getFiles()

    end

    self.next = self:addChildComponent(TextButton:create('>'), 'next')
    self.next.onClick = function()
        local newIndex = self.index + 1
        self.index = newIndex <= #self:getFiles() and newIndex or 1
    end

    self.index = initialFile and self.directory:indexOf(initialFile) or 1
    return self
end

function DirFlipper:getCurrentFile()
    return self:getFiles()[self.index]
end

function DirFlipper:getFiles()
    return self.directory:getFiles()
end

function DirFlipper:resized()
    local size = self.h
    self.prev:setBounds(0, 0, size, size)
    self.file:setBounds(self.prev:getRight(), 0, self.w - size * 2, size)
    self.next:setBounds(self.file:getRight(), 0, size, size)
end

return DirFlipper