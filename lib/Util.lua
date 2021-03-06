
require 'String'

local _ = require '_'
function dump(o, deep, depth, references)
    depth = depth or 0
    deep = deep == nil and true or deep
    references = references or {}

    local indent = string.rep('  ', depth)
    if type(o) == 'table' then

        if includes(references, o) then
            return '=>'
        end

        if o.__tostring then return indent .. o.__tostring(o) end

        table.insert(references, o)

        local lines = {}
        for k,v in pairs(o) do
            -- if type(k) ~= 'number' then k = '"'..k..'"' end
            local val = dump(v, deep, depth + 1, references)
            -- table.insert(lines, indent .. indent ..'[\''..k..'\']'..': ' .. val)
            table.insert(lines, indent .. indent ..'"'..k..'"'..': ' .. '"' .. val .. '"')
            -- table.insert(lines, indent .. indent ..k..': ' .. dump(v, deep, depth + 1, references))
        end
        return '{ \n' .. _.join(lines, ',\n') .. '\n' .. indent ..  '} '
    else
        return tostring(o)
    end
end

function includes(table, value)
    return find(table, value)
end

function find(table, value)
    for i, comp in pairs(table) do
        if comp == value then
            return i
        end
    end
end

function showMixer()
    local WindowApp = require 'WindowApp'
    WindowApp:create('mixer'):show()
end

local noteNames = {
    'c',
    'c#',
    'd',
    'd#',
    'e',
    'f',
    'f#',
     'g',
    'g#',
     'a',
     'a#',
     'b'
}

function getNoteName(number)
    local octave = math.ceil(number / 12) - 1
    local note = number % 12
    return noteNames[note+1] .. tostring(octave)
end

function removeValue(heystack, value)
    local i = find(heystack, value)
    if i then
        table.remove(heystack, i)
    end
end

function class(...)
    local class = {}
    local parents = {...}

    assert(not _.some(parents, function(p)
        return not p.__index
    end), 'base class needs __index:' .. tostring(#parents))

    class.__extends = parents
    class.__parentIndex = function(key)
        return _.some(parents, function(c)
            return c:__index(key)
        end)
    end

    function class:__index(key)
        return class[key] or class.__parentIndex(key)
    end

    function class:__gc()
        return _.some(parents, function(c)
            return c.__gc and c.__gc()
        end)
    end

    function class:__instanceOf(needle)
        return class == needle or _.some(parents, function(parent)
            return needle == parent or parent:__instanceOf(needle)
        end)
    end

    function class:__getName()
        return _.last(debug.getinfo(self.create).source:split('/')):sub(1,-4)
    end

    return class
end

function instanceOf(obj, Class)
    assert(Class, 'instanceOf(obj, Class): Class is nil or false')
    return type(obj) == 'table' and obj.__instanceOf and obj:__instanceOf(Class)
end

local log2 = math.log(2)
local log10 = math.log(10)

function linToDB(x)
    return math.log(x) * 20 / log10
end

function dbToLin(x)
    return 10 ^ (x / 20)
end

function writeFile(path, content)
    local file, err = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    else
        reaper.ShowConsoleMsg(err)
    end
end

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

function readLines(file)
    lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
    end
    return lines
  end

function __dirname(debugInfo)

    local info = debugInfo or debug.getinfo(1,'S')
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
    return script_path
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function fequal(a, b, prec)
    prec = prec or 5
    return round(a, prec) == round(b, prec)
end

function reversed (arr)

    local res = {}
	for k = #arr, 1, -1  do
		table.insert(res, arr[k])
    end
    return res

end

function rpairs(t)
    return pairs(reversed(t))
end

local _assert = assert

function assert(cond, text)
    if not cond then
        return _assert(false, text .. '\n\n' .. debug.traceback())
    else
        return cond
    end
end

function table.clone(org)
    return {table.unpack(org)}
  end


function toboolean(val)
    if type(val) == 'number' then return val ~= 0 end
    return val
end