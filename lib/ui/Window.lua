local Mouse = require 'Mouse'
local Component = require 'Component'
local State = require 'State'
local Track = require 'Track'
local Plugin = require 'Plugin'
local Project = require 'Project'
local Watcher = require 'Watcher'
local Graphics = require 'Graphics'

local _ = require '_'
local rea = require 'rea'

gfx.setfont(1, "arial", 0.2, 'bi')

local Window = class()

Window.currentWindow = nil

Project.watch.project:onChange(function()
    if Window.currentWindow then
        Window.currentWindow.repaint = 'all'
    end
    Track.onStateChange()
end)

function Window.openComponent(name, component, options)

    local win = Window:create(name, component)
    win:show(options)
    return win

end

function Window:create(name, component)
    local self = {
        name = name,
        mouse = Mouse.capture(),
        state = {},
        repaint = true,
        g = Graphics:create(),
        options = {debug = true},
        paints = 0
    }
    setmetatable(self, Window)
    component.window = self
    self.component = component

    self.time = reaper.time_precise()
    return self
end

function Window:isOpen()
    return self.open ~= false
end

function Window:render()

    if self.repaint or Component.dragging then

        gfx.update()
        gfx.clear = 0

        self.component:evaluate(self.g)

        if Component.dragging then
            if Component.dragging.isComponent then

                gfx.setimgdim(0, -1,-1)
                gfx.setimgdim(0, Component.dragging.w, Component.dragging.h)

                Component.dragging:evaluate(self.g, 0)

                gfx.dest = -1
                gfx.x = gfx.mouse_x - Component.dragging.w/2
                gfx.y = gfx.mouse_y - Component.dragging.h/2
                gfx.a = 0.5
                gfx.blit(0, 1, 0)

            else
                self.g:setColor(1,1,1,0.5)
                self.g:circle(gfx.mouse_x, gfx.mouse_y, 10, true, true)
            end
        end

        self.repaint = false

        self.paints = self.paints + 1

    end

end

function Window:unfocus(options)
    -- reaper.SetCursorContext(1, 0)
end

function Window:show(options)

    options = options or {}
    options.persist = options.persist == nil and true or options.persist

    Window.currentWindow = self
    _.assign(self, options)

    local stored = State.global.get('window_' ..self.name, options, {'h','w', 'dock'})
    _.assign(self, stored)

    gfx.init(self.name, self.w, self.h, self.dock)

    if not options.focus then self:unfocus() end

end

function Window:close()
    self.open = false
    gfx.quit()
    if self.onClose then self:onClose() end
end

function Window:restoreState()

    if self.options.persist then

        self.docked = State.global.get('window_' .. self.name .. '_docked')

        if docked then
            self.docked = true
            self.dock = State.global.get('window_' .. self.name .. '_dock')
            gfx.dock(self.dock)
        else
            gfx.dock(0)
        end

        self.component.h = State.global.get('window_' .. self.name .. '_h')
        self.component.w = State.global.get('window_' .. self.name .. '_w')

    end

end

function Window:updateWindow()

    if  self.component.h ~= gfx.h or self.component.w ~= gfx.w then
        self.component:setSize(gfx.w, gfx.h)
    end

    local dock = gfx.dock(-1)

    if dock ~= self.dock then
        self.docked = dock > 0
        self.dock = self.docked and dock or self.dock
    end

    if self.options.persist then

        State.global.set('window_' .. self.name, _.pick(self, {'dock', 'docked'}))
        State.global.set('window_' .. self.name .. '_h', gfx.h)
        State.global.set('window_' .. self.name .. '_w', gfx.w)

    end

end

function Window:toggleDock()

    local dock = gfx.dock(-1)
    if dock > 0 then
        gfx.dock(0)
    else
        gfx.dock(self.dock)
    end

    self:updateWindow()

end

function Window:evalKeyboard()

    local key = gfx.getchar()

    if key == -1 then
        self:close()
    else
        while key > 0 do
            if self.options.debug then
                rea.log('keycode:' .. tostring(key))
            end

            if key == 324 and self.mouse:isShiftKeyDown() then
                self:toggleDock()
            end

            _.forEach(self.component:getAllChildren(), function(comp)
                if comp.onKeyPress then
                    comp:onKeyPress(key)
                end
            end)
            key = gfx.getchar()

        end
    end
end

function getDroppedFiles()
    local files = {}
    local i = 0
    local success, file = gfx.getdropfile(i)
    while success >= 1 do
        table.insert(files, file)
        i = i + 1
        success, file = gfx.getdropfile(i)
    end

    gfx.getdropfile(-1)

    return files
end

function Window:evalMouse()

    local files = getDroppedFiles()
    local isFileDrop = _.size(files) > 0

    local mouse = Mouse.capture(reaper.time_precise(), self.mouse)

    local mouseMoved = self.mouse.x ~= mouse.x or self.mouse.y ~= mouse.y
    local capChanged = self.mouse.cap ~= mouse.cap
    local mouseDragged = mouseMoved and self.mouse:isButtonDown() and mouse:isButtonDown()

    local wheelMove = mouse.mouse_wheel ~= 0

    local mouseDown = (not self.mouse:isButtonDown()) and mouse:isButtonDown()
    local mouseUp = self.mouse:isButtonDown() and (not mouse:isButtonDown())

    if mouseUp and self.component:isMouseOver() then self:unfocus() end

    local allComps = self.component:getAllChildren()

    if mouseMoved or capChanged or isFileDrop or wheelMove then

        local consumed = false

        _.forEach(allComps, function(comp)

            comp:updateMousePos(mouse)

            local isOver = comp:isMouseOver()
            local mouseLeave = comp.mouse.over and not isOver
            if mouseLeave then
                if comp.onMouseLeave then
                    comp:onMouseLeave()
                end
                if comp == self.component then
                    self.repaint = self.repaint or true
                end
            end

            local mouseEnter = not comp.mouse.over and isOver
            if mouseEnter and comp.onMouseEnter then comp:onMouseEnter() end

            comp.mouse.over = isOver

            local useComp = comp:wantsMouse() and (isOver or (mouseDragged and comp.mouse.down))
            if not consumed and useComp then

                if wheelMove and comp.onMouseWheel then comp:onMouseWheel(mouse) end

                if mouseDown then
                    comp.mouse.down = mouse.time
                    if comp.onDblClick and comp.mouse.up and (mouse.time - comp.mouse.up < 0.1) then
                        comp:onDblClick(mouse)
                    end
                    if comp.onMouseDown then comp:onMouseDown(mouse) end
                end

                if mouseUp then

                    if comp.onMouseUp then comp:onMouseUp(mouse) end
                    if comp.mouse.down and comp.onClick then
                        -- rea.log('click')
                        comp:onClick(mouse)
                    end
                    if comp.onDrop and Component.dragging then comp:onDrop(mouse) end

                    comp.mouse.up = mouse.time
                    comp.mouse.down = false
                end

                if comp.onFilesDrop then
                    if isFileDrop then
                        comp:onFilesDrop(files)
                        files = {}
                    end
                end

                if comp.mouse.down and mouseDragged and comp.onDrag then
                    comp:onDrag(mouse)
                end

                consumed = consumed or not comp:canClickThrough()

            end
        end)

    end

    self.mouse = mouse

    if not self.mouse:isButtonDown() then
        _.forEach(allComps, function(child)
            if child.mouse.down then rea.log('up') end
            child.mouse.down = false
        end)
        Component.dragging = nil
    end

end

function Window:defer()

    self:updateWindow()
    self:render()
    self:evalMouse()
    self:evalKeyboard()

    if rea.refreshUI(true) then
        self.paint = true
    end

end

return Window