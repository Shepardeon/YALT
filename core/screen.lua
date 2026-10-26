local Screen = { w = 320, h = 180, scale = 1, ox = 0, oy = 0 }

function Screen.init(w, h)
    Screen.w, Screen.h = w, h
    Screen.canvas = love.graphics.newCanvas(w, h)
    Screen.canvas:setFilter("nearest", "nearest")
    Screen.resize(love.graphics.getDimensions())
end

function Screen.resize(ww, wh)
    Screen.scale = math.max(1, math.floor(math.min(ww / Screen.w, wh / Screen.h)))
    Screen.ox = math.floor((ww - Screen.w * Screen.scale) / 2)
    Screen.oy = math.floor((wh - Screen.h * Screen.scale) / 2)
end

function Screen.begin()
    love.graphics.setCanvas(Screen.canvas)
    love.graphics.clear(0, 0, 0, 1)
end

function Screen.finish(shader)
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(shader)
    love.graphics.draw(Screen.canvas, Screen.ox, Screen.oy, 0, Screen.scale, Screen.scale)
    love.graphics.setShader()
end

function Screen.toGame(x, y)
    return (x - Screen.ox) / Screen.scale, (y - Screen.oy) / Screen.scale
end

return Screen
