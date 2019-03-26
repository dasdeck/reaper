
local dirname = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]
package.path = dirname .. "../?.lua;".. package.path
require 'boot'

local rea = require 'rea'
local lib_path = dirname .. '../../ReaTeam Scripts/Development/Lokasenna_GUI v2/Library/'

loadfile(lib_path .. "Set Lokasenna_GUI v2 library path.lua")()

loadfile(lib_path .. "Core.lua")()

loadfile(lib_path .. "Classes/Class - TextEditor.lua")()

if missing_lib then return 0 end



GUI.name = "Example - Script template"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 400
GUI.anchor, GUI.corner = "mouse", "C"


local code = "return 'type your code'"

local ed = GUI.New("code_editor", "TextEditor", 0, 0,  0, 400, 200, code)
local res = GUI.New("result", "TextEditor", 0, 0,  200, 400, 200, load(code)())

GUI.onresize = function()

    GUI.elms.code_editor.h = GUI.h / 2
    GUI.elms.code_editor.w = gfx.w
    GUI.elms.code_editor:wnd_recalc()


end

GUI.func = function()
    if code ~= GUI.Val('code_editor') then
        code = GUI.Val('code_editor')
        local res = load(code)
        GUI.Val('result', res and res() or 'error')
    end
end

GUI.Init()
GUI.Main()
