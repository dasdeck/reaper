
function addScope(name)
    package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. name .. "/?.lua;".. package.path
end


addScope('lib')
addScope('lib/ui')

require 'Util'

