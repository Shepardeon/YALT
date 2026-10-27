local Screen = require("core.screen")
local Input  = require("core.input")
local Events = require("core.events")

local lg = love.graphics
local UI = {}

UI.Events = {
    Confirm = "ui_confirm",
    Change = "ui_change",
    Move = "ui_move"
}

-- Thème

UI.theme = {
    fonts = {}, -- { normal = ..., title = ... }
    text = { 1, 1, 1, 1},
    panel = { 0.08, 0.08, 0.12, 0.85 },
    button = { 0.2, 0.2, 0.3, 1},
    focus = { 0.95, 0.75, 0.3, 1 },
    barBack = { 0.15, 0.15, 0.2, 1 },
    barFill = { 0.85, 0.25, 0.3, 1 },
    padding = 4,
    gap = 4
}

function UI.setTheme(theme)
    for k, v in pairs(theme) do
        UI.theme[k] = v
    end
end

-- Fonctions locales

local function get(val)
    if type(val) == "function" then return val() end
    return val
end

local function clamp01(val)
    return math.max(0, math.min(1, val))
end

local function fontOf(props)
    return UI.theme.fonts[get(props.font) or "normal"] or lg.getFont()
end

local function inside(n, x, y)
    return x >= n.x and x < n.x + n.w and y >= n.y and y < n.y + n.h
end

-- Constructeurs

local containers = { column = true, row = true }

local function constructor(kind)
    return function(props)
        props = props or {}
        local n = { kind = kind, props = props, children = {} }

        if containers[kind] then
            for i, child in ipairs(props) do
                n.children[i] = child
            end
        else
            props.label = props.label or props[1]
        end

        return n
    end
end

for _, kind in ipairs({ "column", "row", "text", "button", "bar", "slider", "image", "spacer" }) do
    UI[kind] = constructor(kind)
end

function UI.panel(props)
    props.bg = props.bg or true
    props.padding = props.padding or UI.theme.padding
    return UI.column(props)
end

-- Mesures

local measure = {}

function measure.text(n)
    local font = fontOf(n.props)
    return font:getWidth(tostring(get(n.props.label))), font:getHeight()
end

function measure.button(n)
    local w, h = measure.text(n)
    local p = get(n.props.padding) or UI.theme.padding
    return w + p * 2, h + p * 2
end

function measure.image(n)
    local img, scale = get(n.props.image), get(n.props.scale) or 1
    return img:getWidth() * scale, img:getHeight() * scale
end

function measure.bar(n)
    return get(n.props.width) or 40, get(n.props.height) or 4
end

function measure.slider(n)
    return get(n.props.width) or 60, get(n.props.height) or 6
end

function measure.spacer(n)
    return get(n.props.width) or 0, get(n.props.height) or 0
end

local function stack(n, vertical)
    local p = get(n.props.padding) or UI.theme.padding
    local gap = get(n.props.gap) or UI.theme.gap
    local main, cross, count = 0, 0, 0

    for _, c in ipairs(n.children) do
        if c.shown then
            count = count + 1
            if vertical then
                main, cross = main + c.h, math.max(cross, c.w)
            else
                main, cross = main + c.w, math.max(cross, c.h)
            end
        end
    end

    main = main + math.max(0, count - 1) * gap
    if vertical then return cross + p * 2, main + p * 2 end
    return main + p * 2, cross + p * 2
end

function measure.column(n)
    return stack(n, true)
end

function measure.row(n)
    return stack(n, false)
end

local function doMeasure(n)
    n.shown = get(n.props.visible) ~= false
    if not n.shown then n.w, n.h = 0, 0 return end

    for _, c in ipairs(n.children) do doMeasure(c) end

    local w, h = measure[n.kind](n)
    n.w, n.h = get(n.props.w) or w, get(n.props.h) or h
end

-- Placement

local function place(n, x, y)
    n.x, n.y = math.floor(x), math.floor(y)
    if not containers[n.kind] then return end

    local p = get(n.props.padding) or UI.theme.padding
    local gap = get(n.props.gap) or UI.theme.gap
    local align = get(n.props.align) or "start"
    local vertical = n.kind == "column"
    local cursor = vertical and (y + p) or (x + p)

    for _, c in ipairs(n.children) do
        if c.shown then
            local inner = vertical and (n.w - p * 2) or (n.h - p * 2)
            local size = vertical and c.w or c.h
            local off = 0

            if align == "center" then
                off = (inner - size) / 2
            elseif align == "end" then
                off = inner - size
            end

            if vertical then
                place(c, x + p + off, cursor)
                cursor = cursor + c.h + gap
            else
                place(c, cursor, y + p + off)
                cursor = cursor + c.w + gap
            end
        end
    end
end

-- Dessin

local draw = {}

function draw.column(n)
    local bg = get(n.props.bg)
    if bg then
        lg.setColor(bg == true and UI.theme.panel or bg)
        lg.rectangle("fill", n.x, n.y, n.w, n.h)
    end
end
draw.row = draw.column

function draw.text(n)
    lg.setFont(fontOf(n.props))
    lg.setColor(get(n.props.color) or UI.theme.text)
    lg.print(tostring(get(n.props.label)), n.x, n.y)
end

function draw.button(n, focused)
    local p = get(n.props.padding) or UI.theme.padding
    lg.setColor(focused and (get(n.props.focus) or UI.theme.focus) or (get(n.props.bg) or UI.theme.button))
    lg.rectangle("fill", n.x, n.y, n.w, n.h)
    lg.setFont(fontOf(n.props))
    lg.setColor(get(n.props.color) or UI.theme.text)
    lg.print(tostring(get(n.props.label)), n.x + p, n.y + p)
end

function draw.image(n)
    local scale = get(n.props.scale) or 1
    lg.setColor(get(n.props.color) or { 1, 1, 1, 1 })
    lg.draw(get(n.props.image), n.x, n.y, 0, scale, scale)
end

function draw.bar(n)
    local ratio = clamp01(get(n.props.value) / (get(n.props.max) or 1))
    lg.setColor(get(n.props.bg) or UI.theme.barBack)
    lg.rectangle("fill", n.x, n.y, n.w, n.h)
    lg.setColor(get(n.props.color) or UI.theme.barFill)
    lg.rectangle("fill", n.x, n.y, math.floor(n.w * ratio), n.h)
end

function draw.slider(n, focused)
    local val = clamp01(get(n.props.value))
    lg.setColor(get(n.props.bg) or UI.theme.barBack)
    lg.rectangle("fill", n.x, n.y + n.h / 2 - 1, n.w, 2)
    lg.setColor(focused and (get(n.props.focus) or UI.theme.focus) or (get(n.props.color) or UI.theme.text))
    lg.rectangle("fill", n.x + math.floor((n.w - 4) * val), n.y, 4, n.h)
end

function draw.spacer() end

-- Racine

local anchors = {
    topLeft = { 0, 0 }, top = { 0.5, 0 }, topRight = { 1, 0 },
    left = { 0, 0.5 }, center = { 0.5, 0.5 }, right = { 1, 0.5 },
    bottomLeft = { 0, 1 }, bottom = { 0.5, 1 }, bottomRight = { 1, 1}
}

local Root = {}
Root.__index = Root

function UI.new(tree, opts)
    opts = opts or {}
    local root = setmetatable({
        tree = tree,
        anchor = opts.anchor or "center",
        margin = opts.margin or 4,
        interactive = opts.interactive ~= false,
        onBack = opts.onBack,
        focusIndex = 1
    }, Root)

    root:layout()

    return root
end

local function collect(n, out)
    if not n.shown then return end
    if (n.kind == "button" or n.kind == "slider") and not get(n.props.disabled) then
        table.insert(out, n)
    end

    for _, c in ipairs(n.children) do
        collect(c, out)
    end
end

function Root:layout()
    doMeasure(self.tree)
    local a, m = anchors[self.anchor], self.margin

    place(self.tree,
        m + (Screen.w - m * 2 - self.tree.w) * a[1],
        m + (Screen.h - m * 2 - self.tree.h) * a[2])

    self.focusables = {}
    collect(self.tree, self.focusables)
    self.focusIndex = math.max(1, math.min(self.focusIndex, #self.focusables))
end

local function activate(n)
    if n.props.onPress then
        Events.emit(UI.Events.Confirm, n)
        n.props.onPress()
    end
end

local function setSlider(n, val)
    val = clamp01(val)
    if n.props.onChange then
        n.props.onChange(val)
    end
    Events.emit(UI.Events.Change, n, val)
end

function Root:moveFocus(delta)
    local count = #self.focusables

    self.focusIndex = (self.focusIndex - 1 + delta) % count + 1
    Events.emit(UI.Events.Move)
end

function Root:update(dt)
    self:layout()
    if not self.interactive then return end

    if Input.isPressed("ui_back") and self.onBack then
        self.onBack()
        return
    end

    if #self.focusables == 0 then return end

    local mx, my = Screen.toGame(love.mouse.getPosition())
    if mx ~= self.lastMx or my ~= self.lastMy then
        self.lastMx, self.lastMy = mx, my
        for i, n in ipairs(self.focusables) do
            if inside(n, mx, my) then self.focusIndex = i end
        end
    end

    local cur = self.focusables[self.focusIndex]

    if Input.isPressed("ui_up") then self:moveFocus(-1) return end
    if Input.isPressed("ui_down") then self:moveFocus(1) return end

    if cur.kind == "slider" then
        local step = get(cur.props.step) or 0.1
        if Input.isPressed("ui_left") then setSlider(cur, get(cur.props.value) - step) end
        if Input.isPressed("ui_right") then setSlider(cur, get(cur.props.value) + step) end
    else
        if Input.isPressed("ui_left") then self:moveFocus(-1) return end
        if Input.isPressed("ui_right") then self:moveFocus(1) return end
    end

    if Input.isPressed("ui_confirm") then activate(cur) end

    if Input.isPressed("click") and inside(cur, mx, my) then
        if cur.kind == "slider" then
            setSlider(cur, (mx - cur.x) / cur.w)
        else
            activate(cur)
        end
    end
end

local function drawNode(n, focused)
    if not n.shown then return end
    draw[n.kind](n , n == focused)
    for _, c in ipairs(n.children) do drawNode(c, focused) end
end

function Root:draw()
    local focused = self.interactive and self.focusables[self.focusIndex] or nil
    drawNode(self.tree, focused)
    lg.setColor(1, 1, 1, 1)
end

return UI
