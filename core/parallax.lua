local Assets = require("core.assets")
local Screen = require("core.screen")

local lg = love.graphics

local Parallax = {}
Parallax.__index = Parallax

function Parallax.new(def)
    local p = setmetatable({ back = {}, front = {} }, Parallax)

    for _, d in ipairs(def) do
        local layer = {
            image = Assets.image(d.image),
            fx = d.fx or 0,
            fy = d.fy or d.fx or 0,
            y = d.y or 0,
            repeatX = d.repeatX,
            speed = d.speed or 0, -- défilement auto
            tint = d.tint or { 1, 1, 1, 1 },
            scroll = 0
        }

        table.insert(d.front and p.front or p.back, layer)
    end

    return p
end

function Parallax:update(dt)
    for _, list in ipairs({ self.back, self.front }) do
        for _, layer in ipairs(list) do
            layer.scroll = layer.scroll + layer.speed * dt
        end
    end
end

local function drawLayer(layer, cam)
    local img = layer.image
    local y = math.floor(layer.y - cam.y * layer.fy - cam.shakeY)
    lg.setColor(layer.tint)

    if layer.repeatX then
        local iw = img:getWidth()
        local ox = (cam.x * layer.fx + layer.scroll + cam.shakeX) % iw
        for x = -ox, Screen.w, iw do
            lg.draw(img, math.floor(x), y)
        end
    else
        lg.draw(img, math.floor(-cam.x * layer.fx - cam.shakeX), y)
    end
end

function Parallax:drawBack(cam)
    for _, layer in ipairs(self.back) do
        drawLayer(layer, cam)
        lg.setColor(1, 1, 1, 1)
    end
end

function Parallax:drawFront(cam)
    for _, layer in ipairs(self.front) do
        drawLayer(layer, cam)
        lg.setColor(1, 1, 1, 1)
    end
end

return Parallax
