local Save = { file = "save.lua", version = 1 }

-- Table lua -> texte
local function serialize(val, indent)
    indent = indent or ""
    local t = type(val)

    if t == "number" or t == "boolean" then return tostring(val) end
    if t == "string" then return string.format("%q", val) end
    if t == "table" then
        local parts, nextIndent = {}, indent.."    "
        for k, v in pairs(val) do
            local key = type(k) == "string" and string.format("[%q]", k) or "["..k.."]"
            table.insert(parts, nextIndent..key.." = "..serialize(val, nextIndent))
        end
        return "{\n"..table.concat(parts, ",\n").."\n"..indent.."}"
    end

    error("type non sauvegardable : "..t)
end

local function fillDefaults(data, defaults)
    for k, v in pairs(defaults) do
        if data[k] == nil then
            data[k] = v
        elseif type(v) == "table" and type(data[k]) == "table" then
            fillDefaults(data[k], v)
        end
    end
end

local function migrate(data)
    data.version = Save.version
    return data
end

function Save.write(data)
    data.version = Save.version
    return love.filesystem.write(Save.file, "return "..serialize(data))
end

function Save.read(defaults)
    if not love.filesystem.getInfo(Save.file) then return defaults end

    local ok, chunk = pcall(love.filesystem.load, Save.file)
    if not ok or not chunk then return defaults end

    setfenv(chunk, {}) -- évite les appels dangereux
    local ok2, data = pcall(chunk)
    if not ok2 or type(data) ~= "table" then return defaults end

    return fillDefaults(migrate(data), defaults)
end

return Save
