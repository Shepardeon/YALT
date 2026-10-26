local Camera = {}
Camera.__index = Camera

function Camera.new(w, h)
    return setmetatable({
        x = 0, y = 0, w = w, h = h, smooth = 8, bounds = nil,
        trauma = 0, maxShake = 6, decay = 1.5, time = 0,
        shakeX = 0, shakeY = 0
    }, Camera)
end

function Camera:follow(tx, ty, dt)
    local k = 1 - math.exp(-self.smooth * dt)
    self.x = self.x + (tx - self.w / 2 - self.x) * k
    self.y = self.y + (ty - self.h / 2 - self.y) * k

    local b = self.bounds
    if b then
        self.x = math.max(b.x, math.min(self.x, b.x + b.w - self.w))
        self.y = math.max(b.y, math.min(self.y, b.y + b.h - self.h))
    end
end

function Camera:shake(amount)
    self.trauma = math.min(1, self.trauma + amount)
end

function Camera:update(dt)
    if self.trauma <= 0 then
        self.time = 0
        self.shakeX = 0
        self.shakeY = 0
        return
    end

    self.time = self.time + dt
    self.trauma = math.max(0, self.trauma - self.decay * dt)

    local power = self.trauma * self.trauma
    self.shakeX = self.maxShake * power * (love.math.noise(self.time * 25, 0) * 2 - 1)
    self.shakeY = self.maxShake * power * (love.math.noise(0, self.time * 25) * 2 - 1)
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-math.floor(self.x + self.shakeX), -math.floor(self.y + self.shakeY))
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:toWorld(x, y)
    return x + math.floor(self.x), y + math.floor(self.y)
end

return Camera
