
function readFile(path)
    local file, err = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    else
        reaper.ShowConsoleMsg(err)
    end
end


local entry = readFile('./apps/drumRack.lua')

local res = {}
for match in entry:gmatch("require '(.-)'") do
    table.insert(res, match)
end

print(res)