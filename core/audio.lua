local Assets = require("core.assets")

local Audio = {
    channels = { master = 1, music = 0.5, sfx = 1, ui = 1 },
    defs = nil,
    pools = {},
    music = nil,
    fading = {}
}

local function volumeFor(channel, base)
    return Audio.channels.master * (Audio.channels[channel] or 1) * (base or 1)
end

function Audio.init(defs)
    Audio.defs = defs
end

local function getPool(name)
    if Audio.pools[name] then return Audio.pools[name] end

    local def = Audio.defs.sfx[name]
    assert(def, "son inconnu : "..tostring(name))

    local base = Assets.sound(def.name)
    local pool = { def = def, sources = { base }, next = 1 }
    for i = 2, def.voices or 3 do pool.sources[i] = base:clone() end

    Audio.pools[name] = pool
    return pool
end

function Audio.play(name)
    local pool = getPool(name)
    local def = pool.def

    local src
    for _, source in pairs(pool.sources) do
        if not source:isPlaying() then
            src = source
            break
        end
    end

    if not src then
        src = pool.sources[pool.next]
        pool.next = pool.next % #pool.sources + 1
        src:stop()
    end

    local variation = def.pitch or 0
    src:setPitch(1 + (love.math.random() * 2 - 1) * variation)
    src:setVolume(volumeFor(def.channel or "sfx", def.volume))
    src:play()

    return src
end

function Audio.playMusic(name, fadeTime)
    if Audio.music and Audio.music.name == name then return end
    local speed = 1 / math.max(fadeTime or 1, 1, 0.001)

    if Audio.music then
        Audio.music.target, Audio.music.speed = 0, speed
        table.insert(Audio.fading, Audio.music)
    end

    local def = Audio.defs.music[name]
    assert(def, "musique inconnue : "..tostring(name))

    local src = Assets.music(def.name)
    src:setLooping(def.loop ~= false)
    src:setVolume(0)
    src:play()

    Audio.music = {
        name = name,
        source = src,
        base = def.volume or 1,
        level = 0,
        target = 1,
        speed = speed
    }
end

function Audio.stopMusic(fadeTime)
    if not Audio.music then return end

    Audio.music.target = 0
    Audio.music.speed = 1 / math.max(fadeTime or 1, 0.001)
    table.insert(Audio.fading, Audio.music)
    Audio.music = nil
end

function Audio.duck(level)
    if Audio.music then Audio.music.target = level or 1 end
end

local function step(music, dt)
    if music.level < music.target then
        music.level = math.min(music.target, music.level + music.speed * dt)
    elseif music.level > music.target then
        music.level = math.max(music.target, music.level - music.speed * dt)
    end
    music.source:setVolume(volumeFor("music", music.base) * music.level)
end

function Audio.update(dt)
    if Audio.music then step(Audio.music, dt) end

    for i = #Audio.fading, 1, -1 do
        local music = Audio.fading[i]
        step(music, dt)

        if music.level <= 0 then
            music.source:stop()
            table.remove(Audio.fading, i)
        end
    end
end

function Audio.setVolume(channel, v)
    Audio.channels[channel] = math.max(0, math.min(1, v))
    for _, pool in pairs(Audio.pools) do
        local vol = volumeFor(pool.def.channel or "sfx", pool.def.volume)
        for _, src in ipairs(pool.sources) do src:setVolume(vol) end
    end
end

function Audio.getVolume(channel)
    return Audio.channels[channel]
end

function Audio.loadVolumes(saved)
    for k, v in pairs(saved or {}) do
        Audio.channels[k] = v
    end
end

return Audio
