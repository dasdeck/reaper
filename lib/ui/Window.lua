local Mouse = require 'Mouse'
local Component = require 'Component'
local _ = require '_'
local State = require 'State'
local Track = require 'Track'
local Plugin = require 'Plugin'
local Project = require 'Project'
local Watcher = require 'Watcher'
local Profiler = require 'Profiler'
local rea = require 'Reaper'

gfx.setfont(1, "arial", 0.2, 'bi')

local Window = class()

Window.currentWindow = nil


Project.watch.project:onChange(function()
    if Window.currentWindow then
        Window.currentWindow.repaint = true
    end
    Track.onStateChange()
end)


function Window.openComponent(component, options)

    local win = Window:create(component)
    win:show(options)
    return win

end

function Window:create(component)
    local self = {
        mouse = Mouse.capture(),
        state = {},
        repaint = true
    }
    setmetatable(self, Window)
    component.window = self
    self.component = component

    self.time = reaper.time_precise()
    return self
end

function Window:isOpen()
    return gfx.getchar() ~= -1
end

function Window:render()


    -- if self.repaint or self.component.mouse.over then
    if self.repaint or Component.dragging then

        gfx.update()
        gfx.r = 0
        gfx.g = 0
        gfx.b = 0
        gfx.a = 1
        gfx.rect(0, 0, gfx.w, gfx.h, true)

        self.component.w = gfx.w
        self.component.h = gfx.h

        self.component:evaluate()

        self.repaint = false

        if Component.dragging then
            gfx.circle(gfx.mouse_x, gfx.mouse_y, 10, true, true)
        end

    end



end

function Window:updateState()
    local dock = gfx.dock(-1)
    if self.h ~= gfx.h or self.w ~= gfx.w or dock ~= self.dock then
    -- if dock ~= self.dock then

        self.repaint = true
        self.h = gfx.h
        self.w = gfx.w
        self.dock = dock


        State.global.set('window_' .. self.name, _.pick(self, {'h','w', 'dock'}))
        -- rea.log('store')
    end
end

function Window:unfocus(options)
    reaper.SetCursorContext(1, 0)
end

function Window:show(options)

    Window.currentWindow = self
    _.assign(self, options)


    local stored = State.global.get('window_' ..self.name, options, {'h','w', 'dock'})
    _.assign(self, stored)

    gfx.init(self.name, self.w, self.h, self.dock)

    if not options.focus then self:unfocus() end

    if options.profile then

        local def = self.defer
        profiler = Profiler:create({'gfx', 'reaper'})

        self.defer = function()

            local log = profiler:run(function() def(self) end, 1)
            rea.logOnly(log)

        end
    end
    self:defer()

end

function Window:close()
    gfx.quit()
    if self.onClose then self:onClose() end
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

function Window:evalKeyboard()
    if self:isOpen() then
        local key = true
        while key do
            key = gfx.getchar()
            if key ~= 0 then
                _.forEach(self.component:getAllChildren(), function(comp)
                    -- if comp.onKeyPress
                end)
            end
        end
    end
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

    if mouseMoved or capChanged or isFileDrop or wheelMove then

        local consumed = false

        for k,comp in pairs(self.component:getAllChildren()) do

            comp:updateMousePos(mouse)

            local isOver = comp:isMouseOver()
            local mouseLeave = comp.mouse.over and not isOver
            if mouseLeave then
                if comp.onMouseLeave then
                    comp:onMouseLeave()
                end
                if comp == self.component then
                    self.repaint = true
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
                    if comp.mouse.down and comp.onClick then comp:onClick(mouse) end
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
        end

    end

    self.mouse = mouse

    if not self.mouse:isButtonDown() then
        for k,v in pairs(self.component:getAllChildren()) do
            v.mouse.down = false
        end
        Component.dragging = nil
    end

end

function Window:defer()

    local res, err = xpcall(function()

        self:evalMouse()

        Track.deferAll()
        Plugin.deferAll()
        Watcher.deferAll()

        self:render()

        rea.refreshUI(true)

        self:updateState()

    end, debug.traceback)

    if not res then rea.logOnly(err) end

    if self:isOpen() then
        reaper.defer(function()
            self:defer()
        end)
    end

end

return Window