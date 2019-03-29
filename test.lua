require 'boot'
local color = require 'color'
local Collection = require 'Collection'
local _ = require '_'

local unquoteTest = '"test"'
assert(unquoteTest:sub(1,1) == '"', 'firstChar')
assert(unquoteTest:sub(-1,-1) == '"', 'lastChar')
assert(unquoteTest:unquote() == 'test', 'unquote:' .. unquoteTest:unquote())


local splitQuote = '"test 1" two "three four"'

local res1 = splitQuote:split(' ')
assert(#res1 == 5, 'split:' .. dump(res1))

local res = splitQuote:split(' ', '"')
assert(#res == 3, 'quted split:' .. tostring(#res))

local quuteSplit2 = '"u:holy grail"'
local res2 = quuteSplit2:split(' ', '"')
assert(#res2 == 1 and res2[1] == quuteSplit2, 'quted split2:' .. tostring(#res2))


local baseKey = 'window'
local subKey = 'window.x'
local res = subKey:sub(baseKey:len() + 2)
assert(res == 'x', 'split to point:' .. res)

local c = color.rgb(1,0,0)
-- print(c:rgba())

assert(getNoteName(0) == 'c-1', 'noteNames')
assert(getNoteName(24) == 'c1', 'noteNames')

local str = 'abcd'
assert(str:includes('bc') == true, 'includes bc')
assert(str:includes('be') == false, 'not includes be')

local data = {
    'a',
    'b'
}
local data2 = {
    a = 'a',
    b = 'b'
}

local coll = Collection:create(data)
-- print(_.size(data))
-- print(_.size(data2))
-- print(_.size(coll))

coll['test'] = 'test'
-- coll:set('test', 'test')
-- local test = coll:get('test')

print(tostring(coll['type']))
print(tostring(coll['test']))
print(tostring(coll))

local coll2 = Collection:create('{"test" : "test"}')



-- assert(, 'test')
local Class1 = class()

function Class1:create()
    local self = {}
    setmetatable(self, Class1)
    return self
end

function Class1:test()
    return 'test'
end

function Class1:test1()
    return 'test1'
end


local Class2 = class(Class1)

function Class2:create()
    local self = Class1:create()
    setmetatable(self, Class2)
    return self
end

function Class2:test2()
    return 'test2'
end


local Class3 = class(Class2)

function Class3:create()
    local self = Class2:create()
    setmetatable(self, Class3)
    return self
end

function Class3:test()
    return 'test-in-3'
end

function Class3:test3()
    return 'test3'
end

local obj = Class3:create()


assert(obj, 'creates')
assert(obj:test1() == 'test1', 'simple class')
assert(obj:test2() == 'test2', 'simple class')
assert(obj:test3() == 'test3', 'simple class')


local trackState = readFile('./TrackState')

local chainContent = trackState:match('(<FXCHAIN.-\n>)\n>')
local pluginsText = chainContent:match('<FXCHAIN.-(<.*)>'):trim():sub(1, -2)
local plugins = pluginsText:gmatchall('<(.-\n)(.-)>([^<]*)')

function getName(val)
    local i = 1
    local scope = 2
    while true do
        while true do
            local name, value = debug.getlocal(scope, i)
            if val == value then return name end
            i = i + 1
            if not name then break end
        end
        scope = scope + 1
        if not debug.getinfo(scope) then break end
    end
end

function wrap()
    local n = getName(Class1)
    return n
end

wrap()
local obj2 = Class2:create()

local a = obj:__instanceOf(Class3)
local b = obj2:__instanceOf(Class3)
local c = obj2:__instanceOf(Class2)
local d = obj2:__instanceOf(Class1)
-- print(dump(plugins))
-- print(dump(plugins))

