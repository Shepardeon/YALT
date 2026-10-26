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
| `Input`      | actions liées aux touches (`isDown`, `isPressed`)           |
| `Assets`     | chargement des ressources avec cache                        |
| `Audio`      | canaux de volume, pools de sons, musique                    |
| `Animations` | animations de spritesheets (basées sur anim8)               |
| `Fsm`        | machine à états pour les entités                            |
| `Events`     | bus d'événements (`on`, `off`, `emit`)                      |
| `Save`       | sauvegarde sérialisée en Lua dans le dossier de LÖVE        |
| `Camera`     | suivi lissé, limites et tremblement (`require("core.camera")`) |

> Les variables globales sont interdites : toute affectation globale hors de `G` lève une erreur (oubli de `local`).

## Bibliothèques

- [anim8](https://github.com/kikito/anim8) v2.3.1 : animations
- [bump.lua](https://github.com/kikito/bump.lua) v3.1.7 : collisions AABB

## Licence

[MIT](LICENSE). Les bibliothèques de `lib/` gardent leur propre licence (MIT également).
