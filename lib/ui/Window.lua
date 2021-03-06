local Profiler = require 'Profiler'
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
        Window.currentWindow:repaint('all')
    end
    Track.onStateChange()
end)

function Window.openComponent(name, component, options)

    local win = Window:create(name, component)
    win:show(options)
    return win

end

function Window:create(name, component, options)
    local self = {
        name = name,
        mouse = Mouse.capture(),
        state = {},
        g = Graphics:create(),
        options = options or {},
        paints = 0,
        frame = 1
    }

    self.options.debug = true
    setmetatable(self, Window)
    component:setWindow(self)
    self.component = component

    self:repaint(true)
    return self
end

function Window:isOpen()
    return self.open ~= false
end

function Window:render(allComps)

    local rendered = false
    local comp = _.some(allComps, function(comp)return not comp.overlayPaint and comp.needsPaint and comp.isCurrentlyVisible and comp end)


    if self.doPaint or comp then
        -- rea.log({win = doPaint, comp = comp and comp:__getName()})
        self.g:clear()
        self.component:evaluate(self.g)
        self.paints = self.paints + 1
        rendered = true
    end

    self.g:applyBuffer(1, 0, 0, 1, -1)

    _.some(allComps, function(comp)
        if comp.overlayPaint then
            comp:evaluate(self.g, -1, comp:getAbsoluteX(), comp:getAbsoluteY(), true)
            rendered = true
        end
        comp.drawn = false
    end)

    if Component.dragging then
        if Component.dragging and instanceOf(Component.dragging, Component) then

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

    self.doPaint = false

    return rendered

end

function Window:unfocus(options)
    -- reaper.SetCursorContext(1, 0)
end

function Window:show(options)

    self.open = true
    options = options or {}
    options.persist = options.persist == nil and true or options.persist

    Window.currentWindow = self
    _.assign(self.options, options)

    local stored = State.global.get('window_' ..self.name, options, {'x','y', 'h','w', 'dock', 'docked'})
    _.assign(self, stored)

    gfx.quit()
    gfx.init(self.name, self.w, self.h, self.dock, self.x, self.y)

    if self.onShow then self:onShow() end

    if options.unfocus then self:unfocus() end

end

function Window:close()
    if self.open then
        self.open = false
        gfx.quit()
        if self.onClose then self:onClose() end
    end
end

function Window:restoreState()

    self.docked = State.global.get('window_' .. self.name .. '_docked')
    self.dock = State.global.get('window_' .. self.name .. '_dock')

    if self.docked then
        gfx.dock(self.dock)
    else
        gfx.dock(0)
    end

    self.component:setSize(State.global.get('window_' .. self.name .. '_w'), State.global.get('window_' .. self.name .. '_h'))
end

function Window:updateWindow()

    local dock, x, y, w, h = gfx.dock(-1, 0 ,0 ,0 ,0)

    local dockChanged = dock ~= self.dock
    if dockChanged then
        self.docked = dock > 0
        self.dock = self.docked and dock or self.dock
    end

    local heightChanged = self.component.h ~= gfx.h
    local widthChanged = self.component.w ~= gfx.w
    local sizeChanged = heightChanged or widthChanged

    if sizeChanged then

        local h = gfx.h
        local w = gfx.w

        local reinit = false
        if self.options.hFromComponent or self.options.wFromComponent then
            if self.options.hFromComponent and heightChanged then
                self.component.h = math.max(100, self.component.h)
                h = self.component.h
                reinit = true
            end
            if self.options.wFromComponent and widthChanged then
                self.component.w = math.max(100, self.component.w)
                w = self.component.w
                reinit = true
            end
        end

        if reinit then
            gfx.quit()
            gfx.init(self.name, w, h, self.dock, self.x, self.y)
            self:repaint('all')
        else
            self.component:setSize(gfx.w, gfx.h)
        end
    end

    local posChanged = self.x ~= x or self.y ~= y
    if posChanged then
        self.x = x
        self.y = y
    end

    if self.options.persist and (dockChanged or sizeChanged or posChanged) then
        local docks = _.pick(self, {'dock', 'docked'})
        State.global.set('window_' .. self.name, docks)
        State.global.set('window_' .. self.name .. '_h', gfx.h)
        State.global.set('window_' .. self.name .. '_w', gfx.w)
        State.global.set('window_' .. self.name .. '_x', x)
        State.global.set('window_' .. self.name .. '_y', y)

    end

end

function Window:toggleDock()

    local dock = gfx.dock(-1)
    if dock > 0 then
        gfx.dock(0)
    else
        -- rea.log('dock' .. tostring(self.dock))
        gfx.dock(self.dock or 1)
    end

    self:updateWindow()

end

function Window:evalKeyboard(allComps)

    local key = gfx.getchar()

    if key == -1 then
        self:close()
    else
        while key > 0 do
            if self.options.debug then
                rea.logPin('lastkey', 'keycode:' .. tostring(key))
            end

            if key == 324 and self.mouse:isShiftKeyDown() then
                self:toggleDock()
            end

            if Profiler.instance and key == 336 and self.mouse:isShiftKeyDown() then
                Profiler.instance:reset()
            end

            if self.options.closeOnEsc and key == 27 then
                self:close()
            end

            _.forEach(allComps, function(comp)
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

    if require('App').current:drops() then
        require('App').current:setDrop(0)
        -- rea.log('drops')
        table.insert(files, State.global.get('dragging'))
    end

    return files
end

function Window:evalMouse(allComps)

    local files = getDroppedFiles()
    local isFileDrop = _.size(files) > 0

    local mouse = Mouse.capture({time = reaper.time_precise(), frame = self.frame}, self.mouse)

    local mouseMoved = self.mouse.x ~= mouse.x or self.mouse.y ~= mouse.y
    local capChanged = self.mouse.cap ~= mouse.cap
    local mouseDragged = mouseMoved and self.mouse:isButtonDown() and mouse:isButtonDown()

    local wheelMove = mouse.mouse_wheel ~= 0

    local mouseDown = (not self.mouse:isButtonDown()) and mouse:isButtonDown()
    local mouseUp = self.mouse:isButtonDown() and (not mouse:isButtonDown())

    self.component:updateMousePos(mouse)

    if mouseMoved or capChanged or isFileDrop or wheelMove then

        local consumed = false

        _.forEach(allComps, function(comp)

            -- comp:updateMousePos(mouse)

            local isOver = comp:isMouseOver()
            local mouseLeave = comp.mouse.over and not isOver
            if mouseLeave then

                if comp.onMouseLeave then
                    comp:onMouseLeave()
                end

                if instanceOf(Component.dragging, Component) and Component.dragging.onDragOutside then
                    if Component.dragging.onDragOutside() then
                        -- rea.log('set cursor')
                        -- gfx.setcursor(32649)
                    end
                end

                if comp:repaintOnMouse() then
                    comp:repaint()
                end

                if comp == self.component then
                    self:repaint()
                end
            end

            local mouseEnter = not comp.mouse.over and isOver

            if mouseEnter then

                State.global.set('current_app', require('App').current.name)
                -- rea.log(require('App').current.name)

                if comp:repaintOnMouse() then
                    comp:repaint()
                end

                if comp.onMouseEnter then
                    comp:onMouseEnter()
                end
            end

            comp.mouse.over = isOver

            local insideOnlyAction = (mouseMoved and not mouseDragged) or wheelMove
            if comp == self.component and not isOver and insideOnlyAction then
                if self.mouseIgnore then
                    return false
                end
                self.mouseIgnore = true
            else
                self.mouseIgnore = false
            end

            -- if State.global.get('dragging', ''):len() > 0 then
            --     rea.log(require('App').current.name .. ':drop:' .. State.global.get('dragging', ''))
            --     isFileDrop = true
            --     table.insert(files, State.global.get('dragging', ''))
            --     State.global.set('dragging', '')
            -- end

            local useComp = comp:wantsMouse() and (isOver or (mouseDragged and comp.mouse.down))
            if not consumed and useComp then

                if wheelMove and comp.onMouseWheel then comp:onMouseWheel(mouse) end

                if mouseDown then
                    comp.mouse.down = mouse.time
                    if comp.onDblClick and self.lastDownTime and (mouse.time - self.lastDownTime.time < 0.35 or self.frame == self.lastDownTime.frame + 1) then
                        comp:onDblClick(mouse)
                    end
                    if comp.onMouseDown then comp:onMouseDown(mouse) end
                end

                if mouseUp then

                    if comp.onMouseUp then comp:onMouseUp(mouse) end
                    if comp.mouse.down and comp.onClick then
                        comp:onClick(mouse)
                    end
                    if comp.onDrop and Component.dragging then comp:onDrop(mouse) end

                    comp.mouse.up = true
                    comp.mouse.down = false
                end

                if comp.onFilesDrop then
                    if isFileDrop then
                        comp:onFilesDrop(files)
                        files = {}
                    end
                end

                if mouseMoved and isOver then
                    if comp:repaintOnMouse() then
                        comp:repaint()
                    end
                    if comp.onMouseMove then
                        comp:onMouseMove(mouse)
                    end
                end

                if comp.mouse.down and mouseDragged and comp.onDrag then
                    Component.dragging = true
                    comp:onDrag(mouse)
                end

                if not mouseDragged then
                    consumed = consumed or not comp:canClickThrough()
                end
            end
        end)

    end

    self.mouse = mouse

    if not self.mouse:isButtonDown() then
        _.forEach(allComps, function(child)
            child.mouse.down = false
        end)
        if Component.dragging then
            local type = type (Component.draggingOutside)
            if type == 'string' then
                local app = State.global.get('current_app')
                if app then
                    State.global.set('dragging', Component.draggingOutside)
                    require('WindowApp'):create(app):setDrop()
                end
            end

            Component.dragging = nil
            self:repaint()
        end
    end

    self.lastUpTime = mouseUp and mouse.time or self.lastUpTime
    self.lastDownTime = mouseDown and {
        time = mouse.time,
        frame = self.frame
     } or self.lastDownTime

end

function Window:repaint(mode)
    mode = mode or true
    self.doPaint = self.doPaint == 'all' and all or mode
end

function Window:defer()

    if not self.open then return end

    local allComps = self.component:getAllChildren()
    self:updateWindow()
    self.wasPainted = self:render(reversed(allComps))
    self:evalMouse(allComps)
    self:evalKeyboard(allComps)

    if rea.refreshUI(true) then
        self.paint = true
    end

    if self.onDefer then
        self:onDefer()
    end

    if wasPainted then gfx.update() end
    self.frame = self.frame + 1

end

return Window