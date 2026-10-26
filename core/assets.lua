local Assets = { images = {}, sounds = {}, musics = {}, shaders = {} }

function Assets.image(name)
    if not Assets.images[name] then
        Assets.images[name] = love.graphics.newImage("assets/images"..name..".png")
    end
    return Assets.images[name]
end

function Assets.sound(name)
    if not Assets.sounds[name] then
        Assets.sounds[name] = love.audio.newSource("assets/sounds/"..name..".wav", "static")
    end
    return Assets.sounds[name]
end

function Assets.music(name)
    if not Assets.musics[name] then
        Assets.musics[name] = love.audio.newSource("assets/musics/"..name..".ogg", "stream")
    end
    return Assets.musics[name]
end

function Assets.shader(name)
    if not Assets.shaders[name] then
        Assets.shaders[name] = love.graphics.newShader("assets/shaders/"..name..".glsl")
    end
    return Assets.shaders[name]
end

return Assets
