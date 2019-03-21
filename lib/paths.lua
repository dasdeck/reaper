local Directory = require 'Directory'

return {
    effectsDir = Directory:create(reaper.GetResourcePath() .. '/Effects/D3CK'):mkdir(),
    scriptDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK'):mkdir()
}