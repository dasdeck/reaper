

local Menu = require 'Menu'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Label = require 'Label'
local Component = require 'Component'
local DataBase = require 'DataBase'
local State = require 'State'
local DataBaseEntryUI = require 'DataBaseEntryUI'
local json = require 'json'
local rea = require 'rea'
local _ = require '_'

local RandomSound = class()

RandomSound = class(Component)

function RandomSound:create(text)

    local self = Component:create()
    self.next = self:addChildComponent(TextButton:create('>'))
    self.next.onButtonClick = function(s, mouse)
        self:randomize()
    end

    self.rescentFilter = json.parse(State.global.get('randomsound_history', '')) or {}

    self.filter = self:addChildComponent(Label:create(State.global.get('randomsound_filter', '(all)')))
    self.filter.onClick = function(s, mouse)

        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            menu:addItem('db', self:chooseDatabase())
            if _.size(self.rescentFilter) > 0 then
                menu:addSeperator()
                _.forEach(self.rescentFilter, function(name)
                    menu:addItem(name, function()

                        self.filter.content.text = name
                        self:randomize()
                        self.filter:repaint(true)
                        State.global.set('randomsound_filter', self.filter.content.text)

                    end, 'change filter')
                end)
            end

            menu:show()
        elseif mouse:isAltKeyDown() then
            self.filter.content.text = ''
        else
            local newFilter = rea.prompt('filter', self.filter.content.text)
            if newFilter then
                self:setFilter(newFilter)
            end
        end

    end

    self.historyList = self:addChildComponent(ButtonList:create())
    self.historyList.getData = function()
        local history = self.history
        local entries = {}
        while history and #entries < 10 do
            table.insert(entries, history.entry)
            history = history.prev
        end
        return _.map(entries, function(entry)
            return {
                proto = function()
                    local b = TextButton:create(_.last(entry.path:split(rea.seperator)))
                    b.getToggleState = function()
                        return entry == self.current
                    end
                    b.onClick = function()
                        self:setCurrent(entry)
                    end
                    b.onDrag = function(s)
                        Component.dragging = s
                    end
                    b.onDragOutside = function()
                        Component.draggingOutside = entry.path
                        return true
                    end
                    return b
                end,

                size = 20,
            }
        end)
    end

    self.db = DataBase.getDefaultDataBase()
    setmetatable(self, RandomSound)
    return self

end

function RandomSound:resized()
    local h = 20
    self.filter:setBounds(0, 0, self.w - h, h)
    self.next:setBounds(self.filter:getRight(),0,h, h)
    self.historyList:setBounds(0,self.next:getBottom(), self.w, self.historyList.h)

    if self.editor then
        self.editor:setBounds(0, self.h - h*4, self.w, h*4)
    end
end

function RandomSound:setFilter(newFilter)

    if not _.find(self.rescentFilter, newFilter) then
        table.insert(self.rescentFilter, newFilter)

        while(_.size(self.rescentFilter) > 20) do
            table.remove(self.rescentFilter, 1)
        end

       State.global.set('randomsound_history', json.encode(self.rescentFilter))

    end

    self.filter.content.text = newFilter
    self:randomize()
    self.filter:repaint(true)
    State.global.set('randomsound_filter', self.filter.content.text)
end

function RandomSound:chooseDatabase(menu)

    menu = menu or Menu:create()
    _.forEach(DataBase.getDataBases(), function(value)
        menu:addItem(value.name, {
            checked = self.db and self.db.path == value.filename,
            callback = function()
                DataBase.setDefaultDataBase(value.filename)
                self.db = DataBase:create(value.filename)
            end
        })
    end)

    return menu

end

function RandomSound:setCurrent(entry, play)
    play = play == nil and true or play
    self.current = entry
    self.historyList:updateList()
    reaper.OpenMediaExplorer(entry.path, play)
    if self.current then
        if self.editor then self.editor:delete() end
        self.editor = self:addChildComponent(DataBaseEntryUI:create(self.current))
    end
    self:resized()
end

function RandomSound:randomize()

    if self.db then
        local entry = self.db:getRandomEntry(self.filter.content.text)
        if entry then
            self.history = {prev = self.history, entry = entry}
            self:setCurrent(entry, true)
        end
    end

end

return RandomSound