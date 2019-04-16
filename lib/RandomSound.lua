

local _ = require '_'
local Menu = require 'Menu'
local rea = require 'rea'
local TextButton = require 'TextButton'
local ButtonList = require 'ButtonList'
local Label = require 'Label'
local Component = require 'Component'
local DataBase = require 'DataBase'
local State = require 'State'
local DataBaseEntryUI = require 'DataBaseEntryUI'
local RandomSound = class()

RandomSound = class(Component)

function RandomSound:create(text)

    local self = Component:create()
    self.next = self:addChildComponent(TextButton:create('>'))
    self.next.onButtonClick = function(s, mouse)
        self:randomize()
    end

    self.filter = self:addChildComponent(Label:create(State.global.get('randomsound_filter', '(all)')))
    self.filter.onClick = function(s, mouse)

        if mouse:wasRightButtonDown() then
            local menu = Menu:create()
            menu:addItem('db', self:chooseDatabase())
            menu:show()
        elseif mouse:isAltKeyDown() then
            self.filter.content.text = ''
        else
            local newFilter = rea.prompt('filter', self.filter.content.text)
            if newFilter then
                self.filter.content.text = newFilter
                self:randomize()
            end
        end
        self.filter:repaint()
        State.global.set('randomsound_filter', self.filter.content.text)
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
                    local b = TextButton:create(_.last(entry.path:split('/')))
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
                        -- rea.log('drag outside' .. entry.path)
                        Component.draggingOutside = entry.path
                        -- State.global.set('dragging', entry.path)
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

function RandomSound:chooseDatabase(menu)

    menu = menu or Menu:create()
    _.forEach(DataBase.getDataBases(), function(value)
        menu:addItem(value.name, {
            checked = self.db and self.db.path,
            callback = function()
                DataBase.setDefaultDataBase(value.filename)
                self.db = DataBase:create(value.filename)
            end})
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