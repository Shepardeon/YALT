G = {
    Save        = require("core.save"),
    Scenes      = require("core.scenes"),
    Events      = require("core.events"),
    Assets      = require("core.assets"),
    Input       = require("core.input"),
    Screen      = require("core.screen"),
    Animations  = require("core.animations"),
    Camera      = require("core.camera"),
    Audio       = require("core.audio"),
    Fsm         = require("core.fsm"),
    UI          = require("core.ui")
}

setmetatable(_G, {
    __newindex = function (_, k)
        error("globale interdite : "..tostring(k).." (oubli de 'local' ?)", 2)
    end
})

local crtShader

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    G.Screen.init(320, 180)
    crtShader = G.Assets.shader("crt")
    crtShader:send("strength", 0.3)
end

function love.update(dt)
    G.Audio.update(dt)
    G.Scenes.update(dt)
    G.Input.endFrame()
end

function love.draw()
    G.Screen.begin()
    G.Scenes.draw()
    G.Screen.finish(crtShader)
end

function love.resize(w, h)
    G.Screen.resize(w, h)
end

function love.keypressed(key)
    G.Input.keypressed(key)
end

function love.mousepressed(x, y, button)
    G.Input.mousepressed(x, y, button)
end
