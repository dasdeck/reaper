local color = require 'color'

return {
    default = color.rgb(1,1,1),
    bus  = color.rgb(color.parse('#b8e5ff', 'rgb')),
    mute = color.rgb(color.parse('#f24429', 'rgb')),
    arm = color.rgb(color.parse('#f24429', 'rgb')),
    solo = color.rgb(color.parse('#faef1b', 'rgb')),
    la = color.rgb(color.parse('#f4a442', 'rgb')),
    aux = color.rgb(color.parse('#f46241', 'rgb')),
    midi = color.rgb(color.parse('#9496f7', 'rgb')),
    instrument = color.rgb(color.parse('#527710', 'rgb')),
    layer = color.rgb(color.parse('#88a850', 'rgb'))
}