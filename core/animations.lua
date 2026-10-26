local anim8 = require("lib.anim8")
local Assets = require("core.assets")

local Animations = { cache = {} }

local function build(def)
    local image = Assets.image(def.sheet)
    local grid = anim8.newGrid(def.frameW, def.frameH, image:getWidth(), image:getHeight())

    local protos = {}
    for key, anim in pairs(def.anims) do
        local onLoop = (anim.loop == false) and "pauseAtEnd" or nil
        protos[key] = anim8.newAnimation(grid(unpack(anim.frames)), anim.duration, onLoop)
    end

    return {
        def = def,
        image = image,
        protos = protos
    }
end

function Animations.new(def)
    Animations.cache[def.name] = Animations.cache[def.name] or build(def)
    local set = Animations.cache[def.name]

    local anims = {}
    for key, proto in pairs(set.protos) do
        anims[key] = proto:clone()
    end

    return {
        image = set.image,
        w = set.def.frameW,
        h = set.def.frameH,
        anims = anims,
        current = set.def.default
    }
end

return Animations
