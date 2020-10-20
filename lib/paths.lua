local Directory = require 'Directory'

return {
    reaDir = Directory:create(reaper.GetResourcePath()),
    iconsDir = Directory:create(reaper.GetResourcePath() .. '/Data/track_icons'):mkdir(),
    effectsDir = Directory:create(reaper.GetResourcePath() .. '/Effects/D3CK'):mkdir(),
    scriptDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK'):mkdir(),
    binDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/apps'):mkdir(),
    distDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/dist'):mkdir(),
    imageDir = Directory:create(reaper.GetResourcePath() .. '/Scripts/D3CK/images'):mkdir(),
    pluginDir = Directory:create('/Library/Audio/Plug-Ins'),
    vstDir = Directory:create('/Library/Audio/Plug-Ins/VST')

}