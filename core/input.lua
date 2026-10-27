local Input = {
    bindings = {
        left = { "left", "q", "a" },
        right = { "right", "d" },
        up = { "up", "z", "w" },
        down = { "down", "s" },

        ui_up = { "up", "z", "w" },
        ui_down = { "down", "s" },
        ui_left = { "left", "q", "a" },
        ui_right = { "right", "d" },
        ui_confirm = { "return", "space" },
        ui_back = { "escape", "backspace" }
    },
    pressedThisFrame = {}
}

function Input.isDown(action)
    for _, key in ipairs(Input.bindings[action]) do
        if love.keyboard.isDown(key) then return true end
    end
    return false
end

function Input.isPressed(action)
    return Input.pressedThisFrame[action] == true
end

function Input.keypressed(key)
    for action, keys in pairs(Input.bindings) do
        for _, k in ipairs(keys) do
            if k == key then Input.pressedThisFrame[action] = true end
        end
    end
end

function Input.mousepressed(x, y, button)
    if button == 1 then
        Input.pressedThisFrame.click = true
    end
end

function Input.endFrame()
    Input.pressedThisFrame = {}
end

return Input
