# LÖVE Template

Template de départ pour des jeux en pixel art avec [LÖVE](https://love2d.org/) (Lua / LuaJIT).

Rendu en 320×180, mis à l'échelle par un facteur entier dans une fenêtre de 640×360, avec un shader CRT en post-traitement.

## Lancer le projet

Installer LÖVE 11.x, puis depuis la racine du projet :

```sh
love .
```

### Depuis VS Code

Installer les extensions recommandées (`sumneko.lua`, `tomblind.local-lua-debugger-vscode`), puis lancer l'une des configurations (F5) :

- **Debug** : console activée, points d'arrêt via `lldebugger`
- **Release** : lancement normal

## Contrôles par défaut

| Action  | Touches         |
|---------|-----------------|
| Gauche  | ← / Q / A       |
| Droite  | → / D           |
| Haut    | ↑ / Z / W       |
| Bas     | ↓ / S           |

Navigation dans l'interface :

| Action     | Touches                    |
|------------|----------------------------|
| Naviguer   | flèches / ZQSD / WASD      |
| Valider    | Entrée / Espace / clic gauche |
| Retour     | Échap / Retour arrière     |

Les touches sont configurables dans [core/input.lua](core/input.lua).

## Structure

```
assets/     images (.png), sons (.wav), musiques (.ogg), shaders (.glsl)
core/       modules moteur génériques, exposés via la table globale G
game/       code propre à chaque jeu (vide) : scènes, entités, systèmes, données
lib/        bibliothèques tierces
main.lua    point d'entrée
conf.lua    configuration de la fenêtre et du mode debug
```

### Modules `core/`

| Module       | Rôle                                                        |
|--------------|-------------------------------------------------------------|
| `Scenes`     | pile de scènes (`push`, `pop`, `switch`)                    |
| `Screen`     | canvas basse résolution et mise à l'échelle pixel-perfect   |
| `Input`      | actions liées aux touches et au clic (`isDown`, `isPressed`) |
| `UI`         | interface déclarative : mise en page, focus, clavier/souris |
| `Assets`     | chargement des ressources avec cache                        |
| `Audio`      | canaux de volume, pools de sons, musique                    |
| `Animations` | animations de spritesheets (basées sur anim8)               |
| `Fsm`        | machine à états pour les entités                            |
| `Events`     | bus d'événements (`on`, `off`, `emit`)                      |
| `Save`       | sauvegarde sérialisée en Lua dans le dossier de LÖVE        |
| `Camera`     | suivi lissé, limites et tremblement (`require("core.camera")`) |

> Les variables globales sont interdites : toute affectation globale hors de `G` lève une erreur (oubli de `local`).

## Utilisation

### Scènes (`Scenes`)

Une scène est une table avec des méthodes optionnelles `enter(params)`, `exit()`, `update(dt)` et `draw()`. Seule la scène du dessus est mise à jour, mais toutes celles de la pile sont dessinées (pratique pour un menu pause par-dessus le jeu).

```lua
-- game/scenes/title.lua
local Title = {}

function Title:enter(params) end

function Title:update(dt)
    if G.Input.isPressed("ui_confirm") then
        G.Scenes.switch(require("game.scenes.level"), { level = 1 })
    end
end

function Title:draw()
    love.graphics.print("Appuyer sur Entrée", 8, 8)
end

return Title
```

```lua
-- main.lua, dans love.load
G.Scenes.switch(require("game.scenes.title"))

-- ailleurs
G.Scenes.push(require("game.scenes.pause"))  -- empile
G.Scenes.pop()                               -- revient à la scène précédente
```

### Écran (`Screen`)

Tout se dessine en coordonnées de jeu (320×180), `main.lua` s'occupe de la mise à l'échelle. Pour convertir la position de la souris :

```lua
local mx, my = G.Screen.toGame(love.mouse.getPosition())
local centerX = G.Screen.w / 2
```

### Entrées (`Input`)

```lua
if G.Input.isDown("left") then player.x = player.x - speed * dt end  -- maintenu
if G.Input.isPressed("up") then player:jump() end                   -- appuyé cette frame
if G.Input.isPressed("click") then shoot() end                      -- clic gauche

-- ajouter ou modifier une action
G.Input.bindings.dash = { "lshift", "x" }
```

`isPressed` n'est valable que pendant la frame en cours : les appuis sont remis à zéro après chaque `update`.

### Interface (`UI`)

L'interface se décrit comme un arbre de nœuds, recalculé à chaque frame. Les propriétés peuvent être des fonctions pour afficher des valeurs dynamiques.

```lua
local menu = G.UI.new(
    G.UI.panel {
        align = "center",
        G.UI.text { "Pause", font = "title" },
        G.UI.slider {
            value = function() return G.Audio.getVolume("music") end,
            onChange = function(v) G.Audio.setVolume("music", v) end,
        },
        G.UI.button { "Reprendre", onPress = function() G.Scenes.pop() end },
    },
    { anchor = "center", onBack = function() G.Scenes.pop() end }
)

-- dans la scène
menu:update(dt)
menu:draw()
```

- **Conteneurs** : `column`, `row`, `panel` (colonne avec fond), options `padding`, `gap`, `align` (`start`, `center`, `end`)
- **Éléments** : `text`, `button`, `slider`, `bar`, `image`, `spacer`
- **Communs** : `visible`, `w`, `h`, `font`, `color`, `bg` ; `disabled` pour les boutons et sliders
- **Options de `UI.new`** : `anchor` (`topLeft`, `top`, …, `center`, …, `bottomRight`), `margin`, `interactive`, `onBack`
- **Thème** : `UI.setTheme({ ... })` pour changer couleurs, polices (`fonts.normal`, `fonts.title`), `padding` et `gap`
- **Événements** émis sur `Events` : `ui_move`, `ui_confirm`, `ui_change` (pour brancher des sons, par exemple)

### Ressources (`Assets`)

Chaque ressource est chargée une seule fois puis gardée en cache. On donne le nom sans dossier ni extension :

```lua
local img    = G.Assets.image("player")      -- assets/images/player.png
local tiles  = G.Assets.image("tiles/grass") -- assets/images/tiles/grass.png
local sfx    = G.Assets.sound("jump")        -- assets/sounds/jump.wav
local music  = G.Assets.music("theme")       -- assets/musics/theme.ogg
local shader = G.Assets.shader("crt")        -- assets/shaders/crt.glsl
```

### Audio (`Audio`)

Les sons et musiques se déclarent une fois, puis s'appellent par leur clé :

```lua
G.Audio.init({
    sfx = {
        jump   = { name = "jump", volume = 0.8, pitch = 0.1, voices = 4 },
        select = { name = "ui_select", channel = "ui" },
    },
    music = {
        theme = { name = "theme", volume = 0.6 },
    },
})

G.Audio.play("jump")           -- hauteur variée de ±10 %, jusqu'à 4 lectures simultanées
G.Audio.playMusic("theme", 2)  -- fondu enchaîné de 2 s
G.Audio.duck(0.3)              -- baisse la musique (menu pause), G.Audio.duck() pour la rétablir
G.Audio.stopMusic(1)

G.Audio.setVolume("sfx", 0.5)  -- canaux : master, music, sfx, ui

-- chaque frame, pour les fondus
G.Audio.update(dt)
```

### Animations (`Animations`)

Une définition décrit une spritesheet et ses animations (format de grille d'anim8 : colonnes, lignes). Elle est construite une seule fois, et chaque appel à `new` renvoie des animations indépendantes.

```lua
-- game/data/animations/player.lua
return {
    name = "player",
    sheet = "player",  -- assets/images/player.png
    frameW = 16, frameH = 16,
    default = "idle",
    anims = {
        idle = { frames = { "1-4", 1 }, duration = 0.15 },
        run  = { frames = { "1-6", 2 }, duration = 0.08 },
        die  = { frames = { "1-5", 3 }, duration = 0.1, loop = false },
    },
}
```

```lua
local sprite = G.Animations.new(require("game.data.animations.player"))

-- update
sprite.current = "run"
sprite.anims[sprite.current]:update(dt)

-- draw
sprite.anims[sprite.current]:draw(sprite.image, x, y)
```

### Machine à états (`Fsm`)

Chaque état peut définir `enter(owner, fsm, ...)`, `update(owner, dt, ctx, fsm)` et `exit(owner, fsm)`. Si `update` renvoie le nom d'un état, la machine y passe.

```lua
local states = {
    idle = {
        enter = function(p) p.sprite.current = "idle" end,
        update = function(p, dt)
            if G.Input.isDown("left") or G.Input.isDown("right") then return "run" end
        end,
    },
    run = {
        enter = function(p) p.sprite.current = "run" end,
        update = function(p, dt)
            if not (G.Input.isDown("left") or G.Input.isDown("right")) then return "idle" end
        end,
    },
    hurt = {
        enter = function(p, fsm, damage) p.hp = p.hp - damage end,
        update = function(p, dt, ctx, fsm)
            if fsm.time > 0.5 then return fsm.previous end
        end,
    },
}

player.fsm = G.Fsm.new(player, states, "idle")

player.fsm:update(dt, ctx)    -- ctx : données libres passées aux états (monde, collisions…)
player.fsm:change("hurt", 1)  -- arguments supplémentaires transmis à enter
if player.fsm:is("run") then ... end
```

`fsm.time` donne le temps passé dans l'état courant, `fsm.previous` l'état précédent.

### Événements (`Events`)

```lua
local onDeath = G.Events.on("player_died", function(player)
    G.Scenes.push(require("game.scenes.gameover"))
end)

G.Events.emit("player_died", player)
G.Events.off("player_died", onDeath)  -- à faire dans exit() de la scène

-- sons d'interface
G.Events.on(G.UI.Events.Move, function() G.Audio.play("select") end)
```

### Sauvegarde (`Save`)

Les données sont écrites dans `save.lua` du dossier de sauvegarde de LÖVE (`love.filesystem.getSaveDirectory()`). Seuls les nombres, chaînes, booléens et tables sont acceptés. À la lecture, les clés absentes sont complétées avec les valeurs par défaut.

```lua
local defaults = { volumes = { music = 0.5, sfx = 1 }, bestScore = 0 }

local data = G.Save.read(defaults)
G.Audio.loadVolumes(data.volumes)

data.bestScore = math.max(data.bestScore, score)
G.Save.write(data)
```

### Caméra (`Camera`)

La caméra n'est pas dans `G`, elle se crée par scène :

```lua
local Camera = require("core.camera")

local cam = Camera.new(G.Screen.w, G.Screen.h)
cam.bounds = { x = 0, y = 0, w = mapW, h = mapH }  -- optionnel

-- update
cam:follow(player.x, player.y, dt)
cam:update(dt)

-- draw
cam:attach()
-- ... monde
cam:detach()
-- ... HUD, en coordonnées écran

cam:shake(0.4)  -- cumulable, plafonné à 1
local wx, wy = cam:toWorld(G.Screen.toGame(love.mouse.getPosition()))
```

Réglages : `smooth` (vitesse de suivi), `maxShake` (en pixels), `decay` (amortissement du tremblement).

## Bibliothèques

- [anim8](https://github.com/kikito/anim8) v2.3.1 : animations
- [bump.lua](https://github.com/kikito/bump.lua) v3.1.7 : collisions AABB

## Licence

[MIT](LICENSE). Les bibliothèques de `lib/` gardent leur propre licence (MIT également).
