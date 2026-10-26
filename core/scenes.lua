local Scenes = { stack = {} }
local function top() return Scenes.stack[#Scenes.stack] end

function Scenes.push(scene, params)
    table.insert(Scenes.stack, scene)
    if scene.enter then scene:enter(params) end
end

function Scenes.pop()
    local scene = table.remove(Scenes.stack)
    if scene and scene.exit then scene:exit() end
end

function Scenes.switch(scene, params)
    while #Scenes.stack > 0 do
        Scenes.pop()
    end

    Scenes.push(scene, params)
end

function Scenes.update(dt)
    local scene = top()
    if scene and scene.update then scene:update(dt) end
end

function Scenes.draw()
    for _, scene in ipairs(Scenes.stack) do
        if scene.draw then scene:draw() end
    end
end

return Scenes
