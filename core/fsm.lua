local Fsm = {}
Fsm.__index = Fsm

function Fsm.new(owner, states, initial)
    local fsm = setmetatable({ owner = owner, states = states, time = 0 }, Fsm)
    fsm:change(initial)
    return fsm
end

function Fsm:change(name, ...)
    local nextState = self.states[name]
    assert(nextState, "état inconnu : "..tostring(name))

    local cur = self.states[self.current]
    if cur and cur.exit then cur.exit(self.owner, self) end

    self.previous = self.current
    self.current = name
    self.time = 0

    if nextState.enter then nextState.enter(self.owner, self, ...) end
end

function Fsm:update(dt, ctx)
    self.time = self.time + dt
    local state = self.states[self.current]
    if state.update then
        local nextName = state.update(self.owner, dt, ctx, self)
        if nextName and nextName ~= self.current then self:change(nextName) end
    end
end

function Fsm:is(name)
    return self.current == name
end

return Fsm
