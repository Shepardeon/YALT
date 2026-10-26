local Events = { handlers = {} }

function Events.on(name, fn)
    Events.handlers[name] = Events.handlers[name] or {}
    table.insert(Events.handlers[name], fn)
    return fn
end

function Events.off(name, fn)
    local list = Events.handlers[name] or {}
    for i = #list, 1, -1 do
        if list[i] == fn then table.remove(list, i) end
    end
end

function Events.emit(name, ...)
    for _, fn in ipairs(Events.handlers[name]) do
        fn(...)
    end
end

return Events
