-- dep header --
local _dep_cache = {} 
local _deps = { 
boot = function()

function addScope(name)
    package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. name .. "/?.lua;".. package.path
end

math.randomseed(os.time())

addScope('lib')
addScope('lib/ui')

require 'Util'


end
,
Util = function()

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
            table.insert(lines, indent .. indent ..k..': ' .. dump(v, deep, depth + 1, references))
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

    assertDebug(_.some(parents, function(p)
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

    return class
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

    local keys = {}
	for k, v in pairs(arr) do
		table.insert(keys, k)
    end

    local res = {}
    local i = #keys
    while i >= 1 do
        local key = keys[i]
        i = i - 1
        res[key] = arr[key]
    end

    return res
end

function rpairs(t)
    return pairs(reversed(t))
end

function assertDebug(cond, text)
    if cond then assert(false, (text or '') .. debug.traceback()) end
end


function toboolean(val)
    if type(val) == 'number' then return val ~= 0 end
    return val
end
end
,
rea = function()
require 'Util'
local _ = require '_'

local ENSURE_MIDI_ITEMS,IMPORT_LYRICS,EXPORT_LYRICS=42069,42070,42071

local function getFxByName(track, name, recFX)
    local offset = recFX and 0x1000000 or 0
    for index = reaper.TrackFX_GetRecCount(track)-1, 0, -1 do
        local success, fxName = reaper.TrackFX_GetFXName(track, offset + index, 1)
        if string.match(fxName, name) then return index + offset end
    end
end

local function getParamByName(track, fx, name)
    for index = reaper.TrackFX_GetNumParams(track, fx)-1, 0, -1 do
      local success, paramName = reaper.TrackFX_GetParamName(track, fx, index, 1)
      if string.match(paramName, name) then return index end
    end
end

local function log(msg, deep)
    if 'table' == type(msg) then
        msg = dump(msg, deep)
    elseif 'string' ~= type(msg) then
        msg = tostring(msg)
    end
    if msg and type(msg) == 'string' then
        reaper.ShowConsoleMsg(msg .. '\n')
    end
end

local logCounts = {}
local logPins = {}
local error = nil

local function showLogs()
    reaper.ClearConsole()

    if error then
        log(error)
    end
    if _.size(logCounts) > 0 then
        log(logCounts)
    end
    if _.size(logPins) > 0 then
        log(logPins)
    end
end

local function logCount(key, mnt)
    key = tostring(key)
    logCounts[key] = (logCounts[key] or 0) + (mnt or 1)
    showLogs()
end


local function logPin(key, ...)
    key = tostring(key)
    logPins[key] = dump({...})
    showLogs()
end

local function logError(key)
    error = key
    showLogs()
end





local function logOnly(msg, deep)
    showLogs()
    log(msg, deep)
end

local function findRegionOrMarkers(needle)
    local success, markers, regions = reaper.CountProjectMarkers()
    local total = markers + regions
    local result = {}
    for i=0, total do
        local success, region, pos, rgnend, name = reaper.EnumProjectMarkers(i)
        if name:find(needle) then
            table.insert(result, i)
        end
    end
    return result
end

local function getAllTracks()
    local tracks = {}
    local num = reaper.GetNumTracks()
    for i=0, num-1 do
        local track = reaper.GetTrack(0, i)
        table.insert(tracks, track)
    end
    return tracks
end

local function findTrack(needle, collection)
    collection = collection or getAllTracks()
    for k, track in pairs(collection) do
        local success, name = reaper.GetTrackName(track, '')
        if name:find(needle) then
            return track
        end
    end
end

local function getChildTracks(needle)
    local num = reaper.GetNumTracks()
    local tracks = {}
    for i=0, num-1 do
        local track = reaper.GetTrack(0, i)
        local parent = reaper.GetParentTrack(track, '')
        if needle == parent then
            table.insert(tracks, track)
        end
    end
    return tracks
end

local function prompt(name, value)
    local suc, res = reaper.GetUserInputs(name, 1, name, value or '')
    return suc and res or nil
end

local function getFiles(dir, filter)
    local files = {}

    local i = 0
    local file = true
    while file do
        file = reaper.EnumerateFiles(dir, i)
        i = i + 1

        if file then
            if not filter or filter(file) then
                table.insert(files, dir .. '/' .. file)
            end
        end
    end

    return files
end

local function getDir(dir, filter)

    local files = {}

    local i = 0
    local folder = true
    while folder do
        folder = reaper.EnumerateSubdirectories(dir, i)
        i = i + 1
        if folder then
            if not filter or filter(folder) then
                table.insert(files, dir .. '/' .. folder)
            end
        end
    end

    return files
end

local function findFiles(dir, files, filter)
    files = files or {}

    local i = 0
    local file = true
    while file do
        file = reaper.EnumerateFiles(dir, i)
        i = i + 1

        if file then
            if not filter or filter(file) then
                table.insert(files, dir .. '/' .. file)
            end
        end
    end

    local i = 0
    local folder = true
    while folder do
        folder = reaper.EnumerateSubdirectories(dir, i)
        i = i + 1
        if folder then findFiles(dir .. '/' .. folder, files, filter) end
    end

    return files
end

local function findIcon(name)
    local name = name:lower()
    local path = reaper.GetResourcePath() .. '/Data/track_icons'
    local files = findFiles(path, {}, function(path)
        return path:lower():includes(name)
    end)

    return _.first(files)
end


local function setTrackAttrib(track, name, value)
    local success, state = reaper.GetTrackStateChunk(track, '', 0 , false)
    local settings = state:split('\r\n')
    for row, line in pairs(settings) do
        if line:startsWith(name) then
            settings[row] = name .. ' ' .. value
        end
    end
    state = _.join(settings, '\n')
    reaper.SetTrackStateChunk(track, state, false)
end

local function setTrackVisible(track, tcp, mcp)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', tcp == true and 1 or 0)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', mcp == true and 1 or 0)
end

local function transaction(name, action)
    reaper.Undo_BeginBlock()
    local res = action()
    if res ~= false then reaper.Undo_EndBlock(name, -1) end
end

local function ensureTrack(name, options)
    if typeof(options) ~= 'table' then options.hide = options end

    local index = options.index or 0
    local existing = findTrack(name)
    if not existing then
        reaper.InsertTrackAtIndex(0, false)
        log(existing)
        existing = reaper.GetTrack(0, 0)
        log(existing)
        setTrackAttrib(existing, 'NAME', name)
        if options.hide then
            log(existing)
            setTrackVisible(existing, 0, 0)
        end
    end
    return existing
end

local function ensureContentLength(track, ending, start)
    local st = reaper.TimeMap2_beatsToTime(0,0.0, start or 0)
    local et = reaper.TimeMap2_beatsToTime(0,0.0, ending)
    local ost,oet = reaper.GetSet_LoopTimeRange2(0,false,false,0.0,0.0,false)
    reaper.GetSet_LoopTimeRange2(0,true,false,st,et,false)
    reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",1)
    reaper.Main_OnCommandEx(ENSURE_MIDI_ITEMS,0,0)
    reaper.GetSet_LoopTimeRange2(0,true,false,ost,oet,false) -- restore
end

local function setLyrics(text, track)
    track = track or ensureTrack('lyrics', true)
    local lines = text:split('\r\n')
    local map = {}
    local blockData

    for i, line in pairs(lines) do
        local trimmed = line:trim()
        if trimmed:startsWith('[') then

            local block = trimmed:sub(2, trimmed:len() - 1):split('|')
            local blockName = block[1]
            local rgns = findRegionOrMarkers(blockName)

            blockData = {
                positions = _.map(rgns, function(rgn, key)
                    local success, isRegion, pos = reaper.EnumProjectMarkers(rgn)
                    local success, measures = reaper.TimeMap2_timeToBeats(0, pos)
                    return measures + 1
                end),
                lines = {}
            }
            map[blockName] = blockData
        elseif trimmed:len() > 0 then
            table.insert(blockData.lines, trimmed)
        end
    end

    local lyricsLines = {}
    local keys = {}
    for name,data in pairs(map) do
        for k, pos in pairs(data.positions) do
            for i, line in pairs(data.lines) do
                local index = pos + i - 1
                lyricsLines[index] = line
                table.insert(keys, index)
            end
        end
    end

    table.sort(keys)

    local lyrics = ''

    local maxPos = 0
    for k, position in pairs(keys) do
        lyrics = lyrics .. position .. '.1.1' .. '\t' .. lyricsLines[position] .. '\t'
        maxPos = math.max(position, maxPos)
    end

    ensureContentLength(track, maxPos + 2)

    local success, existingLyrics = reaper.GetTrackMIDILyrics(track, 2, '')

    reaper.SetTrackMIDILyrics(track, 2, lyrics)
end

local refresh = false

local function refreshUI(now)
    if now then
        if refresh then
            reaper.TrackList_AdjustWindows(false)
            reaper.UpdateTimeline()
            refresh = false
            return true
        end
    else
        refresh = true
    end
end



local rea = {
    logPin = logPin,
    logError = logError,
    logCount = logCount,
    getFiles = getFiles,
    profile = profile,
    logOnly = logOnly,
    refreshUI = refreshUI,
    setTrackVisible = setTrackVisible,
    prompt = prompt,
    findIcon = findIcon,
    transaction = transaction,
    findFiles = findFiles,
    getAllTracks = getAllTracks,
    getChildTracks = getChildTracks,
    setLyrics = setLyrics,
    findTrack = findTrack,
    findRegionOrMarkers = findRegionOrMarkers,
    log = log,
    getParamByName = getParamByName,
    getFxByName = getFxByName
}

return rea
end
,
String = function()
local _ = require '_'

function string:unquote()
    return self:sub(1,1) == '"' and self:sub(-1,-1) == '"' and self:sub(2,-2) or self
end

function string:startsWith(start)
    return self:sub(1, #start) == start
end

function string:endsWith(ending)
    return ending == "" or self:sub(-#ending) == ending
end

function string:isNumeric()
    return self:match('[0-9]+.[0-9]*')
end

function string:escaped()
    return self:gsub("([^%w])", "%%%1")
end

function string:forEachChar(callback)
    for i=1, #self do
        if callback(self:byte(i), i) == false then return end
    end
end

function string:forEach(callback)
    local i = 1
    for c in str:gmatch ('.') do
        if callback(c, i) == false then return end
        i = i + 1
    end
end

function string:includes(needle)
    return _.size(self:split(needle)) > 1
end

function string:equal(other)
    local len = self:len()
    if other:len() ~= len then return false end
    local rea = require 'rea'

    for i = 1, len do
        if self:sub(i,i) ~= other:sub(i, i) then
            return false
        end
    end

    return true
end

function string:gmatchall(pattern)

    local result = {}

    local iterator = self:gmatch(pattern)

    local wrapper = function()
        return function(...)
            local res = {iterator(...)}
            return #res > 0 and res or nil
        end
    end

    for v in wrapper() do
        table.insert(result, v)
    end
    return result
end

function string:split(sep, quote)
    local result = {}

    for match in (self..sep):gmatch("(.-)"..sep) do
        table.insert(result, match)
    end

    if quote then
        local grouped = {}
        local block = ''
        _.forEach(result, function(val)
            local qStart = val:startsWith(quote)
            local qEnd = val:endsWith(quote)
            if qStart or qEnd then
                if qEnd then
                    table.insert(grouped, block .. sep .. val)
                    block = ''
                elseif qStart then
                    block = val
                end
            else
                if block:len() > 0 then
                    block = block .. sep .. val
                else
                    table.insert(grouped, val)
                end
            end
        end)
        return grouped
    else
        return result
    end
end

function string:trim(s)
    return (self:gsub("^%s*(.-)%s*$", "%1"))
 end
end
,
_ = function()

local function map(data, callback)
    local res = {}
    for k,v in pairs(data or {}) do
        local value, key = callback(v, k)
        if key then
            res[key] = value
        else
            table.insert(res, value)
        end
    end
    return res
end

local function assign(target, source)
    for k,v in pairs(source or {}) do
        target[k] = v
    end
    return target
end

local function forEach(data, callback)
    for k,v in pairs(data or {}) do
        callback(v, k)
    end
end

local function size(collection)
    local i = 0
    for k,v in pairs(collection or {}) do i = i + 1 end
    return i
end

local function some(data, callback)
    for k,v in pairs(data or {}) do
        local res = callback(v, k)
        if res then return res end
    end
    return nil
end

local function equal(a, b)
    if (not a or not b) and a ~= b then return false end
    if type(a) ~= type(b) then return false end
    if type(a) == 'table' then
        if size(a) ~= size(b) then return false end
        if some(a, function(val, key) return not equal(val, b[key]) end) then return false end
    else
        return a == b
    end

    return true
end

local function last(array)
    return array and array[#array]
end

local function first(array)
    return array and array[1] or nil
end

local function reverse(arr)

    local keys = {}
	for k, v in pairs(arr) do
		table.insert(keys, k)
    end

    local res = {}
    local i = #keys
    while i >= 1 do
        local key = keys[i]
        i = i - 1
        res[key] = arr[key]
    end

    return res
end

local function find(data, needle)
    local callback = type(needle) ~= 'function' and function(subj) return subj == needle end or needle
    for k,v in pairs(data or {}) do
        local res = callback(v, k)
        if res then return v end
    end
    return nil
end

local function indexOf(data, needle)
    local i = 1
    return some(data, function(v)
        if v == needle then return i end
        i = i + 1
    end)
end

local function filter(data, callback)
    local res = {}
    for k,v in pairs(data or {}) do
        if callback(v, k) then res[k] = v end
    end
    return res
end

local function pick(data, list)
    local res = {}

    for k,v in pairs(list or {}) do
        local val = data[v]
        if val ~= nil then res[v] = val end
    end

    return res
end

local function reduce(data, callback, carry)
    for k,v in pairs(data or {}) do
        carry = callback(carry, v, k)
    end
    return carry
end

local function join(t, glue)
    -- local res = ''

    -- local i = 1
    -- for key, row in pairs(table or {}) do
    --     res = res .. tostring(row) .. (i < #table and glue or '')
    --     i = i + 1
    -- end
    -- return res
    return table.concat(t, glue)
end

local function empty(table)
    return size(table) == 0
end

local function removeValue(table, needle)
    forEach(table, function(value, key)
        if value == needle then
            table[key] = nil
        end
    end)
end

return {
    indexOf = indexOf,
    reverse = reverse,
    removeValue = removeValue,
    empty = empty,
    join = join,
    filter = filter,
    reduce = reduce,
    pick = pick,
    some = some,
    first = first,
    find = find,
    last = last,
    equal = equal,
    size = size,
    assign = assign,
    map = map,
    forEach = forEach,
    mapKeyValue = mapKeyValue
}
end

} 
require = function(name) 
    if not _dep_cache[name] then 
        _dep_cache[name] = _deps[name]() 
        end
    return _dep_cache[name] 
end 

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
