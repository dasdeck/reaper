local Directory = require 'Directory'

return {
    effectsDir = Directory:create(reaper.GetResourcePath() .. '/Effects/D3CK'):mkdir(),
    scriptDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK'):mkdir(),
    binDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/apps'):mkdir(),
    distDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/dist'):mkdir(),
    imageDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/images'):mkdir()
}