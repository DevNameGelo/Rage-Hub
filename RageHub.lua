--!nocheck
--[[
    ╔══════════════════════════════════════════════╗
    ║   RAGE HUB  ·  UI Library  ·  v2.0.0         ║
    ║   by DevNameGelo · RGC  ·  MIT License       ║
    ╚══════════════════════════════════════════════╝
    Single file · no dependencies · mobile + PC
    Docs: README.md   ·   Showcase: Example.lua
]]

local function Svc(name)
    local s = game:GetService(name)
    if cloneref then
        local ok, c = pcall(cloneref, s)
        if ok and c then return c end
    end
    return s
end

local Players          = Svc("Players")
local TweenService     = Svc("TweenService")
local UserInputService = Svc("UserInputService")
local HttpService      = Svc("HttpService")
local RunService       = Svc("RunService")
local GuiService       = Svc("GuiService")
local CoreGui          = Svc("CoreGui")
local Workspace        = Svc("Workspace")
local Stats            = Svc("Stats")

local RageHub = { Version = "2.0.0" }
local Window, Tab, Elements = {}, {}, {}
Window.__index = Window

local FONT, FONT_MED, FONT_BOLD = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold
local WHITE = Color3.new(1, 1, 1)
local env = (getgenv and getgenv()) or _G
env.__RageHubActive = env.__RageHubActive or {}

local FS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    and type(isfolder) == "function" and type(makefolder) == "function"

local Listening = false -- true while any keybind is capturing a key

local function Clip(text)
    local fn = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if fn then return (pcall(fn, text)) end
    return false
end

local function Copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

------------------------------------------------------------------ THEMES
local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local function MakeTheme(t)
    t.Success = t.Success or RGB(52, 211, 153)
    t.Warning = t.Warning or RGB(251, 191, 36)
    t.Danger  = t.Danger  or RGB(248, 95, 115)
    return t
end

local Themes = {
    Midnight = MakeTheme({ Background = RGB(13, 14, 21),  Surface = RGB(22, 24, 35),  SurfaceHover = RGB(32, 35, 50),  Stroke = RGB(50, 54, 76),  Text = RGB(236, 239, 250), SubText = RGB(138, 145, 171), Accent = RGB(124, 92, 255),  Accent2 = RGB(64, 170, 255) }),
    Crimson  = MakeTheme({ Background = RGB(16, 11, 13),  Surface = RGB(27, 19, 22),  SurfaceHover = RGB(40, 27, 32),  Stroke = RGB(70, 46, 54),  Text = RGB(246, 237, 239), SubText = RGB(162, 138, 145), Accent = RGB(244, 63, 94),   Accent2 = RGB(251, 146, 60) }),
    Ocean    = MakeTheme({ Background = RGB(9, 17, 26),   Surface = RGB(15, 28, 42),  SurfaceHover = RGB(22, 40, 59),  Stroke = RGB(37, 62, 88),  Text = RGB(230, 242, 252), SubText = RGB(127, 154, 178), Accent = RGB(34, 178, 238),  Accent2 = RGB(45, 212, 191) }),
    Emerald  = MakeTheme({ Background = RGB(10, 17, 14),  Surface = RGB(17, 29, 24),  SurfaceHover = RGB(25, 42, 35),  Stroke = RGB(40, 66, 55),  Text = RGB(231, 247, 240), SubText = RGB(130, 160, 146), Accent = RGB(16, 185, 129),  Accent2 = RGB(132, 204, 22) }),
    Sakura   = MakeTheme({ Background = RGB(20, 13, 19),  Surface = RGB(32, 21, 30),  SurfaceHover = RGB(46, 30, 43),  Stroke = RGB(78, 52, 72),  Text = RGB(250, 238, 247), SubText = RGB(170, 140, 163), Accent = RGB(236, 72, 153),  Accent2 = RGB(168, 85, 247) }),
    Sunset   = MakeTheme({ Background = RGB(20, 12, 16),  Surface = RGB(32, 20, 24),  SurfaceHover = RGB(46, 29, 34),  Stroke = RGB(80, 52, 58),  Text = RGB(252, 240, 235), SubText = RGB(176, 146, 148), Accent = RGB(255, 94, 77),   Accent2 = RGB(255, 195, 0) }),
    Dracula  = MakeTheme({ Background = RGB(24, 25, 33),  Surface = RGB(33, 34, 46),  SurfaceHover = RGB(45, 47, 62),  Stroke = RGB(68, 71, 90),  Text = RGB(248, 248, 242), SubText = RGB(150, 155, 185), Accent = RGB(189, 147, 249), Accent2 = RGB(255, 121, 198) }),
    Nord     = MakeTheme({ Background = RGB(36, 41, 51),  Surface = RGB(46, 52, 64),  SurfaceHover = RGB(59, 66, 82),  Stroke = RGB(76, 86, 106), Text = RGB(236, 239, 244), SubText = RGB(153, 166, 189), Accent = RGB(136, 192, 208), Accent2 = RGB(163, 190, 140) }),
    Void     = MakeTheme({ Background = RGB(0, 0, 0),     Surface = RGB(12, 12, 14),  SurfaceHover = RGB(22, 22, 26),  Stroke = RGB(42, 42, 50),  Text = RGB(240, 240, 245), SubText = RGB(125, 125, 140), Accent = RGB(0, 229, 160),   Accent2 = RGB(0, 170, 255) }),
    Light    = MakeTheme({ Background = RGB(243, 245, 250), Surface = RGB(255, 255, 255), SurfaceHover = RGB(236, 239, 247), Stroke = RGB(214, 219, 232), Text = RGB(28, 31, 45), SubText = RGB(108, 115, 140), Accent = RGB(99, 102, 241),  Accent2 = RGB(14, 165, 233) }),
}

local ThemeName = "Midnight"
local Theme = Copy(Themes.Midnight)
local Bound = setmetatable({}, { __mode = "k" }) -- instance -> { {prop, themeKey}, ... }
local Rerender = {}

local function Refresh()
    for inst, list in pairs(Bound) do
        for _, b in ipairs(list) do pcall(function() inst[b[1]] = Theme[b[2]] end) end
    end
    for _, r in ipairs(Rerender) do pcall(r.fn) end
end

local function ApplyTheme(name)
    local t = Themes[name]
    if not t then return false end
    ThemeName, Theme = name, Copy(t)
    Refresh()
    return true
end

local function OnTheme(win, fn) Rerender[#Rerender + 1] = { fn = fn, win = win } end

function RageHub:SetTheme(name) return ApplyTheme(name) end
function RageHub:GetTheme() return ThemeName end
function RageHub:SetAccent(c1, c2)
    Theme.Accent = c1
    Theme.Accent2 = c2 or c1
    Refresh()
end
function RageHub:AddTheme(name, tbl)
    local merged = Copy(Themes.Midnight)
    for k, v in pairs(tbl) do merged[k] = v end
    Themes[name] = merged
end
function RageHub:GetThemes()
    local list = {}
    for k in pairs(Themes) do list[#list + 1] = k end
    table.sort(list)
    return list
end

------------------------------------------------------------------ HELPERS
-- Any Color property given as "$Key" is bound to the live theme.
local function New(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        elseif type(v) == "string" and v:sub(1, 1) == "$" and k:find("Color") then
            local key = v:sub(2)
            inst[k] = Theme[key]
            Bound[inst] = Bound[inst] or {}
            table.insert(Bound[inst], { k, key })
        else
            inst[k] = v
        end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    inst.Parent = parent
    return inst
end

local function Text(props, children)
    local p = {
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = FONT_MED, TextSize = 13,
        TextColor3 = "$Text", TextXAlignment = Enum.TextXAlignment.Left,
    }
    for k, v in pairs(props) do p[k] = v end
    return New("TextLabel", p, children)
end

local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Stroke(color, thick, trans)
    return New("UIStroke", { Color = color or "$Stroke", Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function Pad(l, t, r, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) })
end
local function List(pad)
    return New("UIListLayout", { Padding = UDim.new(0, pad or 6), SortOrder = Enum.SortOrder.LayoutOrder })
end

local function Tween(inst, props, t, style, dir)
    local tw = TweenService:Create(inst, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[RageHub] callback error: " .. tostring(err)) end
end

local function NextOrder(self)
    self._o = (self._o or 0) + 1
    return self._o
end

local function Round(n, d)
    local m = 10 ^ (d or 0)
    return math.floor(n * m + 0.5) / m
end

local function Hover(frame)
    frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.SurfaceHover }, 0.12) end)
    frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Surface }, 0.12) end)
end

local function Gradient(win, parent, rotation)
    local g = New("UIGradient", { Rotation = rotation or 0, Parent = parent })
    local function paint() g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end
    paint()
    OnTheme(win, paint)
    return g
end

local function IsPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function Inside(gui, pos)
    local a, s = gui.AbsolutePosition, gui.AbsoluteSize
    return pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
end

local function Mount(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    local ok = pcall(function()
        if gethui then gui.Parent = gethui() else gui.Parent = CoreGui end
    end)
    if not ok or not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function ToKey(v)
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" then
        local ok, k = pcall(function() return Enum.KeyCode[v] end)
        if ok then return k end
    end
    return nil
end

local SOUNDS = {
    click  = "rbxasset://sounds/button.wav",
    toggle = "rbxasset://sounds/switch.mp3",
    notify = "rbxasset://sounds/electronicpingshort.wav",
}
local function Play(win, kind)
    if not win.Sounds then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = SOUNDS[kind] or SOUNDS.click
        s.Volume = 0.35
        s.Parent = win.Gui
        s:Play()
        task.delay(2, function() s:Destroy() end)
    end)
end

-- Tooltip (desktop hover)
local function Tip(win, frame, text)
    local timer
    frame.MouseEnter:Connect(function()
        timer = task.delay(0.35, function()
            win._tip.Label.Text = text
            win._tip.Frame.Visible = true
        end)
    end)
    frame.MouseMoved:Connect(function()
        local m = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
        local vp = Workspace.CurrentCamera.ViewportSize
        local w = win._tip.Frame.AbsoluteSize.X
        win._tip.Frame.Position = UDim2.fromOffset(math.min(m.X + 16, vp.X - w - 8), m.Y + 20)
    end)
    frame.MouseLeave:Connect(function()
        if timer then pcall(task.cancel, timer) end
        win._tip.Frame.Visible = false
    end)
end

------------------------------------------------------------------ ELEMENT BASE
local Refs = setmetatable({}, { __mode = "k" })

local function Obj(kind) return { Type = kind, _l = {} } end

local function Base(self, o, rightW, height)
    local win = self.Window
    local desc = o.Description
    local hasDesc = type(desc) == "string" and desc ~= ""
    local H = height or (hasDesc and 52 or 40)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0,
        ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { Corner(8), Stroke("$Stroke", 1, 0.55) })
    local ty = (hasDesc or height) and 8 or (H - 18) / 2
    local tw = UDim2.new(1, -(rightW or 0) - 24, 0, 18)
    local titleL = Text({ Text = o.Name or "Element", Position = UDim2.fromOffset(12, ty), Size = tw, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    local descL
    if hasDesc then
        descL = Text({ Text = desc, TextSize = 11, TextColor3 = "$SubText", Font = FONT, Position = UDim2.fromOffset(12, 27), Size = UDim2.new(1, -(rightW or 0) - 24, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    end
    f:SetAttribute("RHName", ((o.Name or "") .. (hasDesc and (" " .. desc) or "")):lower())
    Refs[f] = { title = titleL, desc = descL }
    if o.Tooltip then Tip(win, f, o.Tooltip) end
    return f, H
end

local function Commit(win, o, obj, value, silent)
    if o.Flag then win.Flags[o.Flag] = value end
    if not silent then
        for _, fn in ipairs(obj._l) do Safe(fn, value) end
        if o.Flag then
            for _, fn in ipairs(win._flagListeners) do Safe(fn, o.Flag, value) end
        end
    end
    win:_changed()
end

local function Register(win, o, obj, frame)
    obj.Frame = frame
    obj.Flag = o.Flag
    local shield
    function obj:SetVisible(v)
        frame:SetAttribute("RHHidden", (not v) or nil)
        frame.Visible = v and true or false
    end
    function obj:SetLocked(v)
        obj.Locked = v and true or false
        if v and not shield then
            shield = New("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundColor3 = "$Background", BackgroundTransparency = 0.5, Text = "",
                AutoButtonColor = false, ZIndex = 30, BorderSizePixel = 0, Parent = frame,
            }, { Corner(8) })
        end
        if shield then shield.Visible = obj.Locked end
    end
    function obj:SetName(t)
        local r = Refs[frame]
        if r and r.title then r.title.Text = tostring(t) end
        frame:SetAttribute("RHName", tostring(t):lower())
    end
    function obj:SetDescription(t)
        local r = Refs[frame]
        if r and r.desc then r.desc.Text = tostring(t) end
    end
    function obj:OnChanged(fn) obj._l[#obj._l + 1] = fn end
    function obj:Destroy()
        frame:Destroy()
        if o.Flag then win.Options[o.Flag] = nil; win.Flags[o.Flag] = nil end
    end
    if o.Flag then
        win.Options[o.Flag] = obj
        local v = obj:Get()
        if obj.Type == "Keybind" then v = v and v.Name or "None" end
        win.Flags[o.Flag] = v
    end
    if o.Locked then obj:SetLocked(true) end
    if o.Visible == false then obj:SetVisible(false) end
    return obj
end

local function Overlay(parent, h)
    return New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, h), ZIndex = 3, Parent = parent })
end

-- drag inside an element (sliders / color pickers); locks page scrolling meanwhile
local function Dragger(win, area, page, fn, onBegin)
    area.InputBegan:Connect(function(i)
        if not IsPointer(i) then return end
        local started = win:_beginDrag(i, fn, function() page.ScrollingEnabled = true end)
        if started then
            page.ScrollingEnabled = false
            if onBegin then onBegin(i.Position) end
            fn(i.Position)
        end
    end)
end

-- shared key capture logic (Keybind element + Toggle hotkey chip)
local function KeyBinder(win, btn, initial, cb)
    local key = ToKey(initial)
    local listening = false
    local ctl = {}
    local function render() btn.Text = listening and "..." or (key and key.Name or "None") end
    render()
    function ctl.Get() return key end
    function ctl.Set(v, silent)
        key = ToKey(v)
        render()
        if cb.Changed then cb.Changed(key, silent) end
    end
    btn.Activated:Connect(function()
        listening = not listening
        Listening = listening
        render()
    end)
    win:_conn(UserInputService.InputBegan:Connect(function(i, gp)
        if listening then
            if i.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                task.defer(function() Listening = false end)
                ctl.Set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil)
            elseif IsPointer(i) and not Inside(btn, i.Position) then
                listening = false
                Listening = false
                render()
            end
            return
        end
        if gp or Listening then return end
        if key and i.KeyCode == key and cb.Press then cb.Press() end
    end))
    win:_conn(UserInputService.InputEnded:Connect(function(i)
        if key and i.KeyCode == key and cb.Release then cb.Release() end
    end))
    return ctl
end

------------------------------------------------------------------ LAYOUT ELEMENTS
function Elements:CreateSection(name, opts)
    opts = opts or {}
    local holder = New("Frame", {
        Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { List(6) })
    holder:SetAttribute("RHSec", true)
    local head = New("TextButton", { Name = "Head", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0, Parent = holder })
    Text({ Text = string.upper(name or "SECTION"), Font = FONT_BOLD, TextSize = 11, TextColor3 = "$Accent", Size = UDim2.new(1, -20, 1, 0), Parent = head })
    local arrow = Text({ Text = "▼", TextSize = 8, TextColor3 = "$SubText", TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -4, .5, 0), Size = UDim2.fromOffset(14, 14), Parent = head })
    local content = New("Frame", { Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = holder }, { List(6) })
    local sec = setmetatable({ Window = self.Window, Page = self.Page, Container = content, Holder = holder }, { __index = Elements })
    function sec:SetCollapsed(v)
        content.Visible = not v
        Tween(arrow, { Rotation = v and -90 or 0 }, 0.18)
    end
    function sec:SetVisible(v) holder:SetAttribute("RHHidden", (not v) or nil); holder.Visible = v and true or false end
    head.Activated:Connect(function() sec:SetCollapsed(content.Visible) end)
    if opts.Collapsed then sec:SetCollapsed(true) end
    return sec
end

function Elements:CreateDivider(text)
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, text and 20 or 1), BackgroundTransparency = 1, LayoutOrder = NextOrder(self), Parent = self.Container })
    if text then
        Text({ Text = text, TextSize = 11, TextColor3 = "$SubText", Size = UDim2.new(1, 0, 0, 16), Parent = f })
        New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "$Stroke", BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = f })
    else
        f.BackgroundColor3 = Theme.Stroke
        f.BackgroundTransparency = 0.4
        Bound[f] = { { "BackgroundColor3", "Stroke" } }
    end
    return f
end

function Elements:CreateLabel(text)
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "$Surface", BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8) })
    local l = Text({ Text = text or "", TextColor3 = "$SubText", TextSize = 12, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Parent = f })
    f:SetAttribute("RHName", tostring(text or ""):lower())
    local obj = {}
    function obj:Set(t, color) l.Text = tostring(t); if color then l.TextColor3 = color end end
    function obj:Get() return l.Text end
    function obj:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v end
    function obj:Destroy() f:Destroy() end
    return obj
end

function Elements:CreateParagraph(o)
    o = o or {}
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "$Surface",
        BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { Corner(8), Stroke("$Stroke", 1, 0.55), Pad(12, 10, 12, 10), List(4) })
    local title = Text({ Text = o.Title or "", Font = FONT_BOLD, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = f })
    local body = Text({
        Text = o.Content or "", Font = FONT, TextSize = 12, TextColor3 = "$SubText", TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = f,
    })
    f:SetAttribute("RHName", ((o.Title or "") .. " " .. (o.Content or "")):lower())
    local obj = {}
    function obj:Set(t, c) if t then title.Text = t end if c then body.Text = c end end
    function obj:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v end
    function obj:Destroy() f:Destroy() end
    return obj
end

function Elements:CreateImage(o)
    local H = o.Height or 120
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Stroke", 1, 0.55) })
    local img = New("ImageLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = o.Image or "",
        ScaleType = o.Crop and Enum.ScaleType.Crop or Enum.ScaleType.Fit, Parent = f,
    })
    f:SetAttribute("RHName", "image")
    local obj = {}
    function obj:Set(i) img.Image = i end
    function obj:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v end
    function obj:Destroy() f:Destroy() end
    return obj
end

------------------------------------------------------------------ INTERACTIVE ELEMENTS
function Elements:CreateButton(o)
    local win = self.Window
    local f, H = Base(self, o, 78)
    local label = o.ButtonText or "Run"
    local pill = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(66, 24), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f }, { Corner(12) })
    Gradient(win, pill, 0)
    local pl = Text({ Text = label, Font = FONT_BOLD, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = pill })
    Hover(f)
    local busy = false
    local function run()
        if busy then return end
        Play(win, "click")
        Tween(pill, { Size = UDim2.fromOffset(60, 22) }, 0.08)
        task.delay(0.09, function() Tween(pill, { Size = UDim2.fromOffset(66, 24) }, 0.15, Enum.EasingStyle.Back) end)
        Safe(o.Callback)
        if o.Cooldown and o.Cooldown > 0 then
            busy = true
            pill.BackgroundTransparency = 0.55
            task.spawn(function()
                local t0 = os.clock()
                while true do
                    local left = o.Cooldown - (os.clock() - t0)
                    if left <= 0 then break end
                    pl.Text = string.format("%.1fs", left)
                    task.wait(0.1)
                end
                pl.Text = label
                pill.BackgroundTransparency = 0
                busy = false
            end)
        end
    end
    Overlay(f, H).Activated:Connect(function()
        if o.Confirm then
            win:Dialog({
                Title = o.Name or "Confirm",
                Content = type(o.Confirm) == "string" and o.Confirm or "Are you sure?",
                Buttons = { { Text = "Cancel" }, { Text = "Confirm", Primary = true, Callback = run } },
            })
        else
            run()
        end
    end)
    local obj = Obj("Button")
    function obj:Get() return nil end
    function obj:Fire() run() end
    function obj:SetText(t) label = t; pl.Text = t end
    return Register(win, { Name = o.Name, Locked = o.Locked, Visible = o.Visible }, obj, f)
end

function Elements:CreateLink(o)
    local win = self.Window
    return self:CreateButton({
        Name = o.Name or "Link", Description = o.Description or o.Url, ButtonText = "Copy", Tooltip = o.Tooltip,
        Callback = function()
            local ok = Clip(o.Url or "")
            win:Notify({ Title = ok and "Link copied" or "Copy not supported", Content = ok and (o.Url or "") or "Your executor has no clipboard function.", Type = ok and "success" or "warning", Duration = 3 })
        end,
    })
end

function Elements:CreateToggle(o)
    local win = self.Window
    local hasBind = o.Keybind ~= nil and o.Keybind ~= false
    local f, H = Base(self, o, 52 + (hasBind and 66 or 0))
    local state = o.Default == true
    local obj = Obj("Toggle")
    local track = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0, Parent = f }, { Corner(11) })
    local knob = New("Frame", { AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { Corner(8) })
    local function render(anim)
        local c = state and Theme.Accent or Theme.Stroke
        local p = state and UDim2.new(1, -19, .5, 0) or UDim2.new(0, 3, .5, 0)
        if anim then
            Tween(track, { BackgroundColor3 = c }, 0.18)
            Tween(knob, { Position = p }, 0.18)
        else
            track.BackgroundColor3 = c
            knob.Position = p
        end
    end
    render(false)
    OnTheme(win, function() render(false) end)
    Hover(f)
    function obj:Get() return state end
    function obj:Set(v, silent)
        state = v and true or false
        render(true)
        Commit(win, o, obj, state, silent)
        if not silent then Safe(o.Callback, state) end
    end
    Overlay(f, H).Activated:Connect(function() Play(win, "toggle"); obj:Set(not state) end)
    if hasBind then
        local chip = New("TextButton", {
            AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -62, 0, H / 2), Size = UDim2.fromOffset(54, 22), BackgroundColor3 = "$SurfaceHover",
            Text = "", AutoButtonColor = false, Font = FONT_MED, TextSize = 11, TextColor3 = "$SubText", BorderSizePixel = 0, ZIndex = 5, Parent = f,
        }, { Corner(6), Stroke("$Stroke", 1, 0.4) })
        obj.Binder = KeyBinder(win, chip, o.Keybind, {
            Press = function() if not obj.Locked then obj:Set(not state) end end,
            Changed = function() win:_changed() end,
        })
    end
    return Register(win, o, obj, f)
end

function Elements:CreateSlider(o)
    local win = self.Window
    local min = (o.Range and o.Range[1]) or 0
    local max = (o.Range and o.Range[2]) or 100
    local inc = (o.Increment and o.Increment > 0) and o.Increment or 1
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 96, hasDesc and 70 or 54)
    local value = math.clamp(o.Default or min, min, max)
    local obj = Obj("Slider")

    local valB = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(84, 22), BackgroundTransparency = 1, Text = "",
        TextColor3 = "$SubText", Font = FONT_MED, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = true, BorderSizePixel = 0, ZIndex = 4, Parent = f,
    })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 20), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Stroke", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    Gradient(win, fill, 0)
    local knob = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(7), Stroke("$Accent", 2, 0) })

    local function render()
        local rel = (max == min) and 0 or (value - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.fromScale(rel, .5)
        valB.Text = tostring(Round(value, 3)) .. suffix
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return math.clamp(Round(v, 4), min, max)
    end
    function obj:Get() return value end
    function obj:Set(v, silent)
        v = snap(tonumber(v) or value)
        local changed = v ~= value
        value = v
        render()
        Commit(win, o, obj, value, silent)
        if changed and not silent then Safe(o.Callback, value) end
    end
    render()
    valB.FocusLost:Connect(function()
        local n = tonumber((valB.Text:gsub("[^%d%.%-]", "")))
        if n then obj:Set(n) else render() end
    end)
    local hit = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, H - 34), Size = UDim2.new(1, -12, 0, 30), Parent = f })
    Dragger(win, hit, self.Page, function(pos)
        local rel = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        obj:Set(min + (max - min) * rel)
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateRangeSlider(o)
    local win = self.Window
    local min = (o.Range and o.Range[1]) or 0
    local max = (o.Range and o.Range[2]) or 100
    local inc = (o.Increment and o.Increment > 0) and o.Increment or 1
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 110, hasDesc and 70 or 54)
    local lo = math.clamp((o.Default and o.Default[1]) or min, min, max)
    local hi = math.clamp((o.Default and o.Default[2]) or max, min, max)
    local obj = Obj("RangeSlider")

    local valL = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$SubText", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(100, 18), Parent = f })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 20), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Stroke", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    Gradient(win, fill, 0)
    local function mkKnob() return New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(7), Stroke("$Accent", 2, 0) }) end
    local k1, k2 = mkKnob(), mkKnob()

    local function rel(v) return (max == min) and 0 or (v - min) / (max - min) end
    local function render()
        local a, b = rel(lo), rel(hi)
        fill.Position = UDim2.fromScale(a, 0)
        fill.Size = UDim2.fromScale(b - a, 1)
        k1.Position = UDim2.fromScale(a, .5)
        k2.Position = UDim2.fromScale(b, .5)
        valL.Text = tostring(Round(lo, 3)) .. suffix .. " – " .. tostring(Round(hi, 3)) .. suffix
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return math.clamp(Round(v, 4), min, max)
    end
    local function posToValue(pos)
        local r = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        return min + (max - min) * r
    end
    function obj:Get() return { lo, hi } end
    function obj:Set(v, silent)
        if type(v) ~= "table" then return end
        local a, b = snap(tonumber(v[1]) or lo), snap(tonumber(v[2]) or hi)
        if a > b then a, b = b, a end
        local changed = a ~= lo or b ~= hi
        lo, hi = a, b
        render()
        Commit(win, o, obj, { lo, hi }, silent)
        if changed and not silent then Safe(o.Callback, lo, hi) end
    end
    render()
    local active = 1
    local hit = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, H - 34), Size = UDim2.new(1, -12, 0, 30), Parent = f })
    Dragger(win, hit, self.Page, function(pos)
        local v = snap(posToValue(pos))
        if active == 1 then obj:Set({ math.min(v, hi), hi }) else obj:Set({ lo, math.max(v, lo) }) end
    end, function(pos)
        local v = posToValue(pos)
        if lo == hi then active = (v >= hi) and 2 or 1
        else active = (math.abs(v - lo) <= math.abs(v - hi)) and 1 or 2 end
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateDropdown(o)
    local win = self.Window
    local multi = o.Multi == true
    local options = {}
    for _, v in ipairs(o.Options or {}) do options[#options + 1] = tostring(v) end
    local searchable = o.Search == true or (o.Search == nil and #options > 8)
    local selected, single = {}, nil
    if multi then
        for _, v in ipairs(o.Default or {}) do selected[tostring(v)] = true end
    else
        single = o.Default ~= nil and tostring(o.Default) or nil
    end

    local f, H = Base(self, o, 170)
    local obj = Obj("Dropdown")
    local current = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$SubText", TextSize = 12, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -30, 0, H / 2), Size = UDim2.fromOffset(130, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    local arrow = Text({ Text = "▼", TextSize = 9, TextColor3 = "$SubText", TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(14, 14), Parent = f })

    local topY = H + 4
    local searchBox
    if searchable then
        searchBox = New("TextBox", {
            Position = UDim2.fromOffset(8, topY), Size = UDim2.new(1, -16, 0, 26), BackgroundColor3 = "$SurfaceHover", Text = "",
            PlaceholderText = "Search...", PlaceholderColor3 = "$SubText", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
            ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, Parent = f,
        }, { Corner(6), Pad(8, 0, 8, 0) })
        topY = topY + 32
    end
    local list = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, topY), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
    }, { List(3) })

    local buttons, open, visibleCount = {}, false, #options
    local maxH = o.MaxHeight or 150
    local function listH() return math.min(math.max(visibleCount, 1) * 33, maxH) end
    local function resize()
        list.Size = UDim2.new(1, -16, 0, listH())
        Tween(f, { Size = UDim2.new(1, 0, 0, open and (topY + listH() + 10) or H) }, 0.2)
        Tween(arrow, { Rotation = open and 180 or 0 }, 0.2)
    end
    local function isSel(n) if multi then return selected[n] == true end return single == n end
    local function refreshText()
        if multi then
            local t = {}
            for _, n in ipairs(options) do if selected[n] then t[#t + 1] = n end end
            current.Text = #t > 0 and table.concat(t, ", ") or "None"
        else
            current.Text = single or "Select"
        end
    end
    local function paint()
        for n, b in pairs(buttons) do
            local s = isSel(n)
            b.TextColor3 = s and Theme.Accent or Theme.Text
            b.BackgroundTransparency = s and 0 or 1
        end
    end
    local function filter()
        local q = searchBox and searchBox.Text:lower() or ""
        visibleCount = 0
        for n, b in pairs(buttons) do
            local show = q == "" or n:lower():find(q, 1, true) ~= nil
            b.Visible = show
            if show then visibleCount = visibleCount + 1 end
        end
        if open then resize() end
    end
    function obj:Get()
        if multi then
            local t = {}
            for _, n in ipairs(options) do if selected[n] then t[#t + 1] = n end end
            return t
        end
        return single
    end
    local function changed(silent)
        refreshText(); paint()
        Commit(win, o, obj, obj:Get(), silent)
        if not silent then Safe(o.Callback, obj:Get()) end
    end
    local function build()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for i, n in ipairs(options) do
            local b = New("TextButton", {
                LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1,
                Text = n, Font = FONT_MED, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
                BorderSizePixel = 0, Parent = list,
            }, { Corner(6), Pad(10, 0, 10, 0) })
            b.Activated:Connect(function()
                Play(win, "click")
                if multi then
                    selected[n] = (not selected[n]) or nil
                else
                    single = n
                    open = false
                    resize()
                end
                changed(false)
            end)
            buttons[n] = b
        end
        visibleCount = #options
        paint()
    end
    function obj:Set(v, silent)
        if multi then
            selected = {}
            for _, n in ipairs(type(v) == "table" and v or {}) do selected[tostring(n)] = true end
        else
            single = v ~= nil and tostring(v) or nil
        end
        changed(silent)
    end
    function obj:Refresh(newOptions, keep)
        options = {}
        for _, v in ipairs(newOptions or {}) do options[#options + 1] = tostring(v) end
        if not keep then
            selected, single = {}, nil
        else
            local valid = {}
            for _, n in ipairs(options) do valid[n] = true end
            for n in pairs(selected) do if not valid[n] then selected[n] = nil end end
            if single and not valid[single] then single = nil end
        end
        build(); filter(); refreshText(); resize()
    end
    function obj:Open(v) open = v and true or false; resize() end
    build(); refreshText()
    if searchBox then searchBox:GetPropertyChangedSignal("Text"):Connect(filter) end
    OnTheme(win, paint)
    Hover(f)
    Overlay(f, H).Activated:Connect(function() open = not open; resize() end)
    return Register(win, o, obj, f)
end

function Elements:CreatePlayerDropdown(o)
    local win = self.Window
    local opts = Copy(o)
    local function names()
        local out = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if o.IncludeSelf or p ~= Players.LocalPlayer then out[#out + 1] = p.Name end
        end
        table.sort(out)
        return out
    end
    opts.Options = names()
    local dd = self:CreateDropdown(opts)
    local function upd() dd:Refresh(names(), true) end
    win:_conn(Players.PlayerAdded:Connect(upd))
    win:_conn(Players.PlayerRemoving:Connect(function() task.delay(0.1, upd) end))
    return dd
end

function Elements:CreateSegmented(o)
    local win = self.Window
    local options = {}
    for _, v in ipairs(o.Options or {}) do options[#options + 1] = tostring(v) end
    local n = math.max(#options, 1)
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 0, hasDesc and 78 or 66)
    local obj = Obj("Segmented")
    local index = 1
    for i, v in ipairs(options) do if o.Default ~= nil and v == tostring(o.Default) then index = i end end

    local track = New("Frame", { Position = UDim2.new(0, 12, 0, H - 36), Size = UDim2.new(1, -24, 0, 28), BackgroundColor3 = "$SurfaceHover", BorderSizePixel = 0, Parent = f }, { Corner(8) })
    local ind = New("Frame", { Size = UDim2.new(1 / n, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { Corner(6) })
    Gradient(win, ind, 0)
    local btns = {}
    local function paint(anim)
        local p = UDim2.new((index - 1) / n, 2, 0, 2)
        if anim then Tween(ind, { Position = p }, 0.2) else ind.Position = p end
        for i, b in ipairs(btns) do b.TextColor3 = (i == index) and WHITE or Theme.SubText end
    end
    for i, name in ipairs(options) do
        local b = New("TextButton", {
            Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0), BackgroundTransparency = 1, Text = name,
            Font = FONT_BOLD, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = track,
        })
        b.Activated:Connect(function() Play(win, "click"); obj:Set(name) end)
        btns[i] = b
    end
    paint(false)
    OnTheme(win, function() paint(false) end)
    function obj:Get() return options[index] end
    function obj:Set(v, silent)
        for i, name in ipairs(options) do if name == tostring(v) then index = i end end
        paint(true)
        Commit(win, o, obj, options[index], silent)
        if not silent then Safe(o.Callback, options[index]) end
    end
    return Register(win, o, obj, f)
end

function Elements:CreateInput(o)
    local win = self.Window
    local f, H = Base(self, o, (o.Width or 140) + 10)
    local value = o.Default ~= nil and tostring(o.Default) or ""
    local obj = Obj("Input")
    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(o.Width or 140, 26),
        BackgroundColor3 = "$SurfaceHover", TextColor3 = "$Text", PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = "$SubText",
        Text = value, ClearTextOnFocus = false, Font = FONT_MED, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, ZIndex = 4, Parent = f,
    }, { Corner(6), Stroke("$Stroke", 1, 0.4), Pad(8, 0, 8, 0) })
    local stroke = box:FindFirstChildOfClass("UIStroke")
    function obj:Get() if o.Numeric then return tonumber(value) or 0 end return value end
    function obj:Set(v, silent)
        value = tostring(v == nil and "" or v)
        box.Text = value
        Commit(win, o, obj, obj:Get(), silent)
        if not silent then Safe(o.Callback, obj:Get()) end
    end
    box.Focused:Connect(function() Tween(stroke, { Color = Theme.Accent, Transparency = 0 }, 0.15) end)
    box.FocusLost:Connect(function(enter)
        Tween(stroke, { Color = Theme.Stroke, Transparency = 0.4 }, 0.15)
        if o.Numeric and not tonumber(box.Text) then box.Text = value; return end
        if o.OnlyOnEnter and not enter then box.Text = value; return end
        value = box.Text
        Commit(win, o, obj, obj:Get(), false)
        Safe(o.Callback, obj:Get(), enter)
        if o.ClearOnEnter and enter then box.Text = ""; value = "" end
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateKeybind(o)
    local win = self.Window
    local mode = o.Mode or "Press" -- Press | Hold | Toggle
    local f, H = Base(self, o, 100)
    local obj = Obj("Keybind")
    local state = false
    local btn = New("TextButton", {
        AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(84, 26), BackgroundColor3 = "$SurfaceHover",
        Text = "", AutoButtonColor = false, Font = FONT_MED, TextSize = 12, TextColor3 = "$Text", BorderSizePixel = 0, ZIndex = 4, Parent = f,
    }, { Corner(6), Stroke("$Stroke", 1, 0.4) })
    obj.Binder = KeyBinder(win, btn, o.Default, {
        Press = function()
            if obj.Locked then return end
            if mode == "Hold" then state = true; Safe(o.Callback, true)
            elseif mode == "Toggle" then state = not state; Safe(o.Callback, state)
            else Safe(o.Callback, obj.Binder.Get()) end
        end,
        Release = function()
            if mode == "Hold" and state then state = false; Safe(o.Callback, false) end
        end,
        Changed = function(k, silent)
            Commit(win, o, obj, k and k.Name or "None", silent)
            if not silent then Safe(o.OnChange, k) end
        end,
    })
    function obj:Get() return obj.Binder.Get() end
    function obj:Set(v, silent) obj.Binder.Set(v, silent) end
    function obj:GetState() return state end
    return Register(win, o, obj, f)
end

function Elements:CreateColorPicker(o)
    local win = self.Window
    local color = o.Default or Color3.fromRGB(124, 92, 255)
    local h, s, v = color:ToHSV()
    local f, H = Base(self, o, 60)
    local obj = Obj("ColorPicker")
    local PH = 96
    local swatch = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(36, 20), BackgroundColor3 = color, BorderSizePixel = 0, Parent = f }, { Corner(6), Stroke("$Stroke", 1, 0.2) })

    local sv = New("Frame", { Position = UDim2.fromOffset(10, H + 8), Size = UDim2.new(1, -52, 0, PH), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = f }, { Corner(6) })
    New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
    New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
    local svCur = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sv }, { Corner(6), Stroke(Color3.new(0, 0, 0), 1.5, 0.2) })

    local hue = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, H + 8), Size = UDim2.fromOffset(22, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f }, { Corner(6) })
    local keys = {}
    for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0.999 or i / 6, 1, 1)) end
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = hue })
    local hueCur = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.new(1, 4, 0, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hue }, { Corner(2), Stroke(Color3.new(0, 0, 0), 1, 0.3) })

    local hexBox = New("TextBox", {
        Position = UDim2.fromOffset(10, H + PH + 16), Size = UDim2.new(1, -20, 0, 24), BackgroundColor3 = "$SurfaceHover", Text = "",
        PlaceholderText = "#RRGGBB", PlaceholderColor3 = "$SubText", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
        ClearTextOnFocus = false, BorderSizePixel = 0, Parent = f,
    }, { Corner(6), Stroke("$Stroke", 1, 0.4), Pad(8, 0, 8, 0) })

    local function render()
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCur.Position = UDim2.fromScale(s, 1 - v)
        hueCur.Position = UDim2.fromScale(.5, h)
        hexBox.Text = string.format("#%02X%02X%02X", Round(color.R * 255), Round(color.G * 255), Round(color.B * 255))
    end
    render()
    function obj:Get() return color end
    function obj:Set(c, silent)
        if typeof(c) ~= "Color3" then return end
        h, s, v = c:ToHSV()
        render()
        Commit(win, o, obj, color, silent)
        if not silent then Safe(o.Callback, color) end
    end
    local function push() render(); Commit(win, o, obj, color, false); Safe(o.Callback, color) end
    Dragger(win, sv, self.Page, function(pos)
        s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        push()
    end)
    Dragger(win, hue, self.Page, function(pos)
        h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 0.999)
        push()
    end)
    hexBox.FocusLost:Connect(function()
        local hx = (hexBox.Text:gsub("[^%x]", ""))
        local n = (#hx == 6) and tonumber(hx, 16) or nil
        if n then obj:Set(Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)) else render() end
    end)
    local open = false
    Hover(f)
    Overlay(f, H).Activated:Connect(function()
        open = not open
        Tween(f, { Size = UDim2.new(1, 0, 0, open and (H + PH + 50) or H) }, 0.2)
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateProgressBar(o)
    local win = self.Window
    local max = o.Max or 100
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 90, hasDesc and 64 or 48)
    local obj = Obj("ProgressBar")
    obj.NoSave = true
    local value = math.clamp(o.Default or 0, 0, max)
    local valL = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$SubText", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(80, 18), Parent = f })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 16), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Stroke", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    Gradient(win, fill, 0)
    local function render(anim)
        local r = max == 0 and 0 or value / max
        if anim then Tween(fill, { Size = UDim2.fromScale(r, 1) }, 0.25) else fill.Size = UDim2.fromScale(r, 1) end
        valL.Text = tostring(Round(value, 1)) .. suffix
    end
    render(false)
    function obj:Get() return value end
    function obj:Set(v)
        value = math.clamp(tonumber(v) or value, 0, max)
        render(true)
        Commit(win, o, obj, value, true)
    end
    return Register(win, o, obj, f)
end

function Elements:CreateLog(o)
    o = o or {}
    local win = self.Window
    local H = o.Height or 140
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H + 28), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Stroke", 1, 0.55) })
    Text({ Text = o.Name or "Log", Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 18), Parent = f })
    f:SetAttribute("RHName", (o.Name or "log"):lower())
    local scroll = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 28), Size = UDim2.new(1, -16, 1, -36), BackgroundColor3 = "$Background", BackgroundTransparency = 0.3, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
    }, { Corner(6), Pad(8, 6, 8, 6), List(2) })
    local count, maxLines = 0, o.MaxLines or 100
    local obj = Obj("Log")
    obj.NoSave = true
    function obj:Get() return nil end
    function obj:Add(text, color)
        count = count + 1
        local stamp = o.Timestamps == false and "" or ("[" .. os.date("%H:%M:%S") .. "] ")
        Text({
            Text = stamp .. tostring(text), Font = Enum.Font.Code, TextSize = 11, TextColor3 = color or "$Text", TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = count, Parent = scroll,
        })
        local kids = scroll:GetChildren()
        local lines = {}
        for _, c in ipairs(kids) do if c:IsA("TextLabel") then lines[#lines + 1] = c end end
        if #lines > maxLines then lines[1]:Destroy() end
        task.defer(function() scroll.CanvasPosition = Vector2.new(0, 1e6) end)
    end
    function obj:Clear()
        for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    end
    return Register(win, { Name = o.Name, Visible = o.Visible }, obj, f)
end

------------------------------------------------------------------ TAB
function Tab:Select() self.Window:SelectTab(self) end
function Tab:SetVisible(v) self.Button.Visible = v end
function Tab:Destroy()
    local win = self.Window
    for i, t in ipairs(win.Tabs) do if t == self then table.remove(win.Tabs, i) break end end
    self.Button:Destroy()
    self.Page:Destroy()
    if win._activeTab == self and win.Tabs[1] then win:SelectTab(win.Tabs[1]) end
end
setmetatable(Tab, { __index = Elements })

------------------------------------------------------------------ WINDOW INTERNALS
function Window:_conn(c) self.Connections[#self.Connections + 1] = c; return c end

function Window:_initInput()
    self:_conn(UserInputService.InputChanged:Connect(function(m)
        local d = self._drag
        if d then d(m) end
    end))
end

-- one active drag per window; onMove gets the pointer position
function Window:_beginDrag(i, onMove, onEnd)
    if self._drag then return false end
    local touch = i.UserInputType == Enum.UserInputType.Touch
    self._drag = function(m)
        if touch then
            if m ~= i then return end
        elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        onMove(m.Position)
    end
    local c
    c = i.Changed:Connect(function()
        if i.UserInputState == Enum.UserInputState.End then
            c:Disconnect()
            self._drag = nil
            if onEnd then onEnd() end
        end
    end)
    return true
end

local function MakeDraggable(win, handle, target, onClick)
    handle.InputBegan:Connect(function(i)
        if not IsPointer(i) then return end
        local startPos, startUI, moved = i.Position, target.Position, 0
        win:_beginDrag(i, function(p)
            local d = p - startPos
            moved = math.max(moved, d.Magnitude)
            target.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
        end, function()
            if onClick and moved < 6 then onClick() end
        end)
    end)
end

function Window:_buildTip()
    local frame = New("Frame", {
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = "$Surface", BorderSizePixel = 0,
        Visible = false, ZIndex = 100, Parent = self.Gui,
    }, { Corner(6), Stroke("$Accent", 1, 0.3), Pad(8, 5, 8, 5), New("UISizeConstraint", { MaxSize = Vector2.new(240, 200) }) })
    local label = Text({ Text = "", TextSize = 12, TextWrapped = true, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, ZIndex = 101, Parent = frame })
    self._tip = { Frame = frame, Label = label }
end

function Window:_buildNotifs()
    self._nclose, self._nOrder = {}, 0
    self._notifs = New("Frame", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 290, 1, -32), BackgroundTransparency = 1, ZIndex = 50, Parent = self.Gui,
    }, { New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
end

------------------------------------------------------------------ CONFIG
function Window:_path(name) return self.ConfigFolder .. "/" .. (name:gsub("[^%w_%- ]", "")) .. ".json" end

function Window:_ensureFolder()
    local path
    for p in self.ConfigFolder:gmatch("[^/]+") do
        path = path and (path .. "/" .. p) or p
        if not isfolder(path) then makefolder(path) end
    end
end

function Window:_changed()
    if self._loading or not self.AutoSaveName or not FS then return end
    if self._saveTask then pcall(task.cancel, self._saveTask) end
    self._saveTask = task.delay(1.2, function()
        self._saveTask = nil
        self:SaveConfig(self.AutoSaveName)
    end)
end

function Window:_collect()
    local data = {}
    for flag, opt in pairs(self.Options) do
        if opt.Type ~= "Button" and not opt.NoSave then
            local val = opt:Get()
            if opt.Type == "Keybind" then
                val = val and val.Name or false
            elseif opt.Type == "ColorPicker" then
                val = { Round(val.R * 255), Round(val.G * 255), Round(val.B * 255) }
            end
            data[flag] = val
            if opt.Binder and opt.Type ~= "Keybind" then
                local k = opt.Binder.Get()
                data[flag .. "::key"] = k and k.Name or false
            end
        end
    end
    local p = self.Main.Position
    data.__window = { x = p.X.Offset, y = p.Y.Offset, w = self._userSize and self._size.X or nil, h = self._userSize and self._size.Y or nil }
    return data
end

function Window:_apply(data)
    self._loading = true
    for flag, val in pairs(data) do
        if flag ~= "__window" then
            local base = flag:match("^(.-)::key$")
            if base then
                local opt = self.Options[base]
                if opt and opt.Binder then pcall(opt.Binder.Set, val or nil) end
            else
                local opt = self.Options[flag]
                if opt then
                    if opt.Type == "ColorPicker" and type(val) == "table" then val = Color3.fromRGB(val[1], val[2], val[3]) end
                    pcall(function() opt:Set(val) end)
                end
            end
        end
    end
    local w = data.__window
    if type(w) == "table" and type(w.x) == "number" and type(w.y) == "number" then
        local vp = Workspace.CurrentCamera.ViewportSize
        local x = math.clamp(w.x, -vp.X / 2 + 60, vp.X / 2 - 60)
        local y = math.clamp(w.y, -vp.Y / 2 + 40, vp.Y / 2 - 40)
        self.Main.Position = UDim2.new(0.5, x, 0.5, y)
        if type(w.w) == "number" and type(w.h) == "number" then self:SetSize(w.w, w.h) end
    end
    self._loading = false
end

function Window:SaveConfig(name)
    if not FS then return false, "Executor has no file system" end
    name = name or self.AutoSaveName or "default"
    local ok, err = pcall(function()
        self:_ensureFolder()
        writefile(self:_path(name), HttpService:JSONEncode(self:_collect()))
    end)
    return ok, err
end

function Window:LoadConfig(name)
    if not FS then return false, "Executor has no file system" end
    name = name or self.AutoSaveName or "default"
    local path = self:_path(name)
    if not isfile(path) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false, "Config is corrupted" end
    self:_apply(data)
    return true
end

function Window:DeleteConfig(name)
    if not (FS and type(delfile) == "function") then return false end
    local path = self:_path(name)
    if isfile(path) then delfile(path); return true end
    return false
end

function Window:ListConfigs()
    local out = {}
    if FS and type(listfiles) == "function" then
        pcall(function()
            self:_ensureFolder()
            for _, p in ipairs(listfiles(self.ConfigFolder)) do
                local n = p:match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end)
        table.sort(out)
    end
    return out
end

function Window:ExportConfig() return HttpService:JSONEncode(self:_collect()) end

function Window:ImportConfig(json)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false, "Invalid JSON" end
    data.__window = nil -- never move the window from an imported string
    self:_apply(data)
    return true
end

function Window:OnChanged(fn) self._flagListeners[#self._flagListeners + 1] = fn end
function Window:GetFlag(flag) return self.Flags[flag] end
function Window:Copy(text) return Clip(text) end

------------------------------------------------------------------ NOTIFY / DIALOG
function Window:Notify(o)
    o = o or {}
    local colors = { info = Theme.Accent, success = Theme.Success, warning = Theme.Warning, error = Theme.Danger }
    local color = colors[o.Type or "info"] or Theme.Accent
    local dur = o.Duration or 4
    self._nOrder = self._nOrder + 1
    self.NotificationLog = self.NotificationLog or {}
    table.insert(self.NotificationLog, { Title = o.Title, Content = o.Content, Type = o.Type or "info", Time = os.time() })
    if #self.NotificationLog > 50 then table.remove(self.NotificationLog, 1) end
    Play(self, "notify")

    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self._nOrder, Parent = self._notifs })
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 60, 0, 0),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = wrap,
    }, { Corner(10), Stroke(Theme.Stroke, 1, 0.2) })
    New("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card }, { Corner(2) })
    local content = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card }, { Pad(16, 10, 12, 10), List(4) })
    Text({ Text = o.Title or "Rage Hub", Font = FONT_BOLD, TextSize = 14, TextColor3 = Theme.Text, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content })
    if o.Content and o.Content ~= "" then
        Text({ Text = o.Content, Font = FONT, TextSize = 12, TextColor3 = Theme.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = content })
    end

    local closeFns = self._nclose
    local closed = false
    local function close()
        if closed then return end
        closed = true
        for i, fn in ipairs(closeFns) do if fn == close then table.remove(closeFns, i) break end end
        Tween(card, { Position = UDim2.new(1, 60, 0, 0) }, 0.25)
        task.delay(0.3, function() wrap:Destroy() end)
    end

    if type(o.Buttons) == "table" and #o.Buttons > 0 then
        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 3, Parent = content }, {
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        })
        for i, b in ipairs(o.Buttons) do
            local btn = New("TextButton", {
                LayoutOrder = i, Size = UDim2.fromOffset(b.Width or 74, 26), BackgroundColor3 = "$SurfaceHover", Text = b.Text or "OK",
                Font = FONT_BOLD, TextSize = 11, TextColor3 = color, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6, Parent = row,
            }, { Corner(6) })
            btn.Activated:Connect(function() Safe(b.Callback); close() end)
        end
    end
    local prog = New("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0, LayoutOrder = 4, Parent = content }, { Corner(1) })

    closeFns[#closeFns + 1] = close
    while #closeFns > 5 do closeFns[1]() end
    New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = card }).Activated:Connect(close)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35)
    Tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
    task.delay(dur, close)
    return { Close = close }
end

function Window:Dialog(o)
    o = o or {}
    local dim = New("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 60, Parent = self.Gui,
    })
    Tween(dim, { BackgroundTransparency = 0.5 }, 0.2)
    local card = New("Frame", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = dim,
    }, { Corner(12), Stroke("$Stroke", 1, 0.2), Pad(16, 14, 16, 14), List(10) })
    local sc = New("UIScale", { Scale = 0.9, Parent = card })
    Tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
    Text({ Text = o.Title or "Rage Hub", Font = FONT_BOLD, TextSize = 15, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Parent = card })
    if o.Content and o.Content ~= "" then
        Text({ Text = o.Content, Font = FONT, TextSize = 12, TextColor3 = "$SubText", TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = card })
    end
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 3, Parent = card }, {
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local function close()
        Tween(dim, { BackgroundTransparency = 1 }, 0.15)
        Tween(sc, { Scale = 0.9 }, 0.15)
        task.delay(0.16, function() dim:Destroy() end)
    end
    for i, b in ipairs(o.Buttons or { { Text = "OK" } }) do
        local btn = New("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(b.Width or 90, 32), BackgroundColor3 = b.Primary and WHITE or "$SurfaceHover",
            Text = b.Primary and "" or (b.Text or "OK"), Font = FONT_BOLD, TextSize = 12, TextColor3 = "$Text", AutoButtonColor = false, BorderSizePixel = 0, Parent = row,
        }, { Corner(8) })
        if b.Primary then
            Gradient(self, btn, 0)
            Text({ Text = b.Text or "OK", Font = FONT_BOLD, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = btn })
        end
        btn.Activated:Connect(function() close(); Safe(b.Callback) end)
    end
    return { Close = close }
end

------------------------------------------------------------------ WATERMARK
function Window:CreateWatermark(o)
    if self._wm then self._wm:SetVisible(true); return self._wm end
    o = o or {}
    local win = self
    local text = o.Text or self.Name
    local showFps, showPing = o.ShowFPS ~= false, o.ShowPing ~= false
    local bar = New("Frame", {
        Name = "Watermark", Position = UDim2.fromOffset(16, 16), Size = UDim2.new(0, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = "$Background", BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 40, Parent = self.Gui,
    }, { Corner(8), Stroke("$Stroke", 1, 0.2), Pad(10, 0, 10, 0) })
    local lab = Text({ RichText = true, Text = "", TextSize = 12, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 41, Parent = bar })
    local frames, last, fps, ping = 0, os.clock(), 60, 0
    local function update()
        local parts = { string.format('<font color="#%s"><b>%s</b></font>', Theme.Accent:ToHex(), text) }
        if showFps then parts[#parts + 1] = fps .. " FPS" end
        if showPing then parts[#parts + 1] = ping .. " ms" end
        lab.Text = table.concat(parts, "  |  ")
    end
    self:_conn(RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last >= 0.5 then
            fps = math.floor(frames / (now - last) + 0.5)
            frames, last = 0, now
            if showPing then pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end) end
            update()
        end
    end))
    update()
    OnTheme(self, update)
    MakeDraggable(self, bar, bar)
    local obj = {}
    function obj:SetText(t) text = t; update() end
    function obj:SetVisible(v) bar.Visible = v end
    function obj:Destroy() bar:Destroy(); win._wm = nil end
    self._wm = obj
    return obj
end

------------------------------------------------------------------ WINDOW CONTROL
function Window:_ensureOnScreen()
    local m, cam = self.Main, Workspace.CurrentCamera
    if not cam then return end
    local vp, p, s = cam.ViewportSize, m.AbsolutePosition, m.AbsoluteSize
    if p.X > vp.X - 60 or p.Y > vp.Y - 40 or p.X + s.X < 60 or p.Y < -10 then
        m.Position = UDim2.fromScale(.5, .5)
    end
end

function Window:SetVisible(v)
    self.Visible = v and true or false
    if v then
        self.Main.Visible = true
        self:_ensureOnScreen()
        Tween(self._scale, { Scale = self.UIScale }, 0.28, Enum.EasingStyle.Back)
    else
        Tween(self._scale, { Scale = self.UIScale * 0.9 }, 0.15)
        task.delay(0.15, function() if not self.Visible then self.Main.Visible = false end end)
    end
end
function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:SetMinimized(v)
    self.Minimized = v and true or false
    local s = self._size
    if self.Minimized then
        self._body.Visible = false
        Tween(self.Main, { Size = UDim2.fromOffset(s.X, 46) }, 0.2)
    else
        Tween(self.Main, { Size = UDim2.fromOffset(s.X, s.Y) }, 0.25)
        task.delay(0.08, function() if not self.Minimized then self._body.Visible = true end end)
    end
end

function Window:SetSize(w, h)
    local vp = Workspace.CurrentCamera.ViewportSize
    w = math.clamp(w, 340, math.max(340, vp.X / self.UIScale - 8))
    h = math.clamp(h, 250, math.max(250, vp.Y / self.UIScale - 8))
    self._size = Vector2.new(w, h)
    self._userSize = true
    self.Main.Size = UDim2.fromOffset(w, self.Minimized and 46 or h)
end

function Window:SetScale(n)
    self.UIScale = math.clamp(tonumber(n) or 1, 0.6, 1.5)
    if self.Visible then Tween(self._scale, { Scale = self.UIScale }, 0.15) end
    self:SetSize(self._size.X, self._size.Y)
end

function Window:SetSidebarCollapsed(v, anim)
    self.SidebarCollapsed = v and true or false
    local w = self.SidebarCollapsed and 0 or 128
    local total = self.SidebarCollapsed and 0 or 144
    local sideGoal = { Size = UDim2.new(0, w, 1, -16) }
    local contentGoal = { Position = UDim2.fromOffset(total, 0), Size = UDim2.new(1, -total, 1, 0) }
    if not self.SidebarCollapsed then self._side.Visible = true end
    if anim == false then
        for k, val in pairs(sideGoal) do self._side[k] = val end
        for k, val in pairs(contentGoal) do self._content[k] = val end
        self._side.Visible = not self.SidebarCollapsed
    else
        Tween(self._side, sideGoal, 0.22)
        Tween(self._content, contentGoal, 0.22)
        if self.SidebarCollapsed then
            task.delay(0.24, function() if self.SidebarCollapsed then self._side.Visible = false end end)
        end
    end
end

function Window:SetTitle(t) self._title.Text = tostring(t) end
function Window:SetSubtitle(t) self._subtitle.Text = tostring(t) end
function Window:SetAccent(c1, c2) RageHub:SetAccent(c1, c2) end
function Window:GetTab(name) for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end end

function Window:_applySearch()
    local tab = self._activeTab
    if not tab then return end
    local q = (self._query or ""):lower()
    local all = tab.Page:GetDescendants()
    for _, d in ipairs(all) do
        local n = d:GetAttribute("RHName")
        if n then d.Visible = (not d:GetAttribute("RHHidden")) and (q == "" or n:find(q, 1, true) ~= nil) end
    end
    for _, d in ipairs(all) do
        if d:GetAttribute("RHSec") then
            local any = q == ""
            if not any then
                local c = d:FindFirstChild("Content")
                if c then
                    for _, e in ipairs(c:GetDescendants()) do
                        if e:GetAttribute("RHName") and e.Visible then any = true break end
                    end
                end
            end
            d.Visible = any and not d:GetAttribute("RHHidden")
        end
    end
end

function Window:SelectTab(t)
    if type(t) == "string" then t = self:GetTab(t) end
    if type(t) ~= "table" then return end
    self._activeTab = t
    for _, x in ipairs(self.Tabs) do
        x._active = (x == t)
        x.Page.Visible = x._active
        x._paint(true)
    end
    t.Page.Position = UDim2.fromOffset(0, 10)
    Tween(t.Page, { Position = UDim2.fromOffset(0, 0) }, 0.25)
    self:_applySearch()
end

function Window:CreateTabLabel(text)
    return Text({ Text = string.upper(text or ""), Font = FONT_BOLD, TextSize = 10, TextColor3 = "$SubText", Size = UDim2.new(1, 0, 0, 20), LayoutOrder = (function() self._tabN = self._tabN + 1 return self._tabN end)(), Parent = self._tabList })
end

function Window:CreateTab(name, icon)
    local win = self
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = (function() win._tabN = win._tabN + 1 return win._tabN end)(), Parent = win._tabList,
    }, { Corner(8) })
    local iconObj, iconProp
    local s = icon ~= nil and tostring(icon) or ""
    if s ~= "" then
        if s:match("^rbxassetid://") or s:match("^%d+$") then
            iconObj = New("ImageLabel", { BackgroundTransparency = 1, Image = s:match("^%d+$") and ("rbxassetid://" .. s) or s, Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(16, 16), ImageColor3 = "$SubText", Parent = btn })
            iconProp = "ImageColor3"
        else
            iconObj = Text({ Text = s, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = "$SubText", Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(20, 34), Parent = btn })
            iconProp = "TextColor3"
        end
    end
    local label = Text({ Text = name, Position = UDim2.fromOffset(iconObj and 38 or 16, 0), Size = UDim2.new(1, iconObj and -42 or -20, 1, 0), TextColor3 = "$SubText", TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn })
    local bar = New("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 4, .5, 0), Size = UDim2.fromOffset(3, 16), BackgroundColor3 = "$Accent", BackgroundTransparency = 1, BorderSizePixel = 0, Parent = btn }, { Corner(2) })
    local page = New("ScrollingFrame", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = win._content,
    }, { Pad(12, 12, 12, 12), List(8) })

    local tab = setmetatable({ Name = name, Window = win, Page = page, Container = page, Button = btn, _active = false }, { __index = Tab })
    tab._paint = function(anim)
        local a = tab._active
        local goals = {
            { btn, { BackgroundTransparency = a and 0.1 or 1 } },
            { label, { TextColor3 = a and Theme.Text or Theme.SubText } },
            { bar, { BackgroundTransparency = a and 0 or 1 } },
        }
        if iconObj then goals[#goals + 1] = { iconObj, { [iconProp] = a and Theme.Accent or Theme.SubText } } end
        for _, g in ipairs(goals) do
            if anim then Tween(g[1], g[2], 0.18) else for k, v in pairs(g[2]) do g[1][k] = v end end
        end
    end
    OnTheme(win, function() tab._paint(false) end)
    btn.Activated:Connect(function() Play(win, "click"); win:SelectTab(tab) end)
    win.Tabs[#win.Tabs + 1] = tab
    if #win.Tabs == 1 then win:SelectTab(tab) end
    return tab
end

------------------------------------------------------------------ SETTINGS TAB
function Window:CreateSettingsTab(name)
    local win = self
    local tab = self:CreateTab(name or "Settings", "⚙")

    local ui = tab:CreateSection("Interface")
    ui:CreateDropdown({ Name = "Theme", Flag = "rh_theme", Options = RageHub:GetThemes(), Default = ThemeName, Callback = function(v) ApplyTheme(v) end })
    ui:CreateColorPicker({
        Name = "Custom Accent", Description = "Overrides the theme accent color", Default = Theme.Accent,
        Callback = function(c)
            local h, s, v = c:ToHSV()
            RageHub:SetAccent(c, Color3.fromHSV((h + 0.08) % 1, s, v))
        end,
    })
    ui:CreateSlider({ Name = "Window Transparency", Flag = "rh_alpha", Range = { 0, 60 }, Default = 4, Suffix = "%", Callback = function(v) win.Main.BackgroundTransparency = v / 100 end })
    ui:CreateSlider({ Name = "UI Scale", Flag = "rh_scale", Range = { 70, 130 }, Increment = 5, Default = win.UIScale * 100, Suffix = "%", Callback = function(v) win:SetScale(v / 100) end })
    ui:CreateKeybind({ Name = "Toggle Key", Description = "Esc clears the key", Flag = "rh_togglekey", Default = win.ToggleKey, OnChange = function(k) if k then win.ToggleKey = k end end })
    ui:CreateToggle({ Name = "UI Sounds", Flag = "rh_sounds", Default = win.Sounds, Callback = function(v) win.Sounds = v end })
    ui:CreateToggle({
        Name = "Watermark", Description = "FPS and ping overlay", Flag = "rh_watermark", Default = win._wm ~= nil,
        Callback = function(v)
            if v then win:CreateWatermark() elseif win._wm then win._wm:Destroy() end
        end,
    })

    local cfg = tab:CreateSection("Configuration")
    local cfgName = "default"
    local picker
    cfg:CreateInput({ Name = "Config Name", Default = "default", Callback = function(v) if v ~= "" then cfgName = v end end })
    cfg:CreateButton({
        Name = "Save Config", ButtonText = "Save",
        Callback = function()
            local ok, err = win:SaveConfig(cfgName)
            win:Notify({ Title = ok and "Config saved" or "Save failed", Content = ok and cfgName or tostring(err), Type = ok and "success" or "error" })
            if picker then picker:Refresh(win:ListConfigs(), true) end
        end,
    })
    picker = cfg:CreateDropdown({ Name = "Saved Configs", Options = win:ListConfigs(), Callback = function(v) if v then cfgName = v end end })
    cfg:CreateButton({
        Name = "Load Config", ButtonText = "Load",
        Callback = function()
            local ok, err = win:LoadConfig(cfgName)
            win:Notify({ Title = ok and "Config loaded" or "Load failed", Content = ok and cfgName or tostring(err), Type = ok and "success" or "error" })
        end,
    })
    cfg:CreateButton({
        Name = "Delete Config", ButtonText = "Delete", Confirm = "Delete the selected config file?",
        Callback = function()
            local ok = win:DeleteConfig(cfgName)
            win:Notify({ Title = ok and "Config deleted" or "Nothing to delete", Content = cfgName, Type = ok and "warning" or "error" })
            picker:Refresh(win:ListConfigs())
        end,
    })
    cfg:CreateToggle({
        Name = "Auto-Save", Description = "Save automatically whenever something changes",
        Callback = function(v) win.AutoSaveName = v and cfgName or nil end,
    })
    cfg:CreateButton({
        Name = "Copy Config (JSON)", Description = "Share your settings with others", ButtonText = "Copy",
        Callback = function()
            local ok = Clip(win:ExportConfig())
            win:Notify({ Title = ok and "Copied to clipboard" or "Copy not supported", Type = ok and "success" or "warning", Duration = 3 })
        end,
    })
    local importText = ""
    cfg:CreateInput({ Name = "Import JSON", Placeholder = "Paste config...", Width = 150, Callback = function(t) importText = t end })
    cfg:CreateButton({
        Name = "Import Config", ButtonText = "Import",
        Callback = function()
            local ok, err = win:ImportConfig(importText)
            win:Notify({ Title = ok and "Config imported" or "Import failed", Content = ok and "" or tostring(err), Type = ok and "success" or "error" })
        end,
    })

    local misc = tab:CreateSection("Misc")
    misc:CreateButton({ Name = "Reset Window Position", ButtonText = "Reset", Callback = function() win.Main.Position = UDim2.fromScale(.5, .5) end })
    misc:CreateButton({ Name = "Unload Rage Hub", ButtonText = "Unload", Confirm = "This removes the UI completely.", Callback = function() win:Destroy() end })
    misc:CreateLabel("Rage Hub v" .. RageHub.Version .. "  ·  DevNameGelo · RGC")
    return tab
end

------------------------------------------------------------------ DESTROY
function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    for i = #Rerender, 1, -1 do if Rerender[i].win == self then table.remove(Rerender, i) end end
    if self._saveTask then pcall(task.cancel, self._saveTask) end
    if env.__RageHubActive[self.Name] == self then env.__RageHubActive[self.Name] = nil end
    if self.Gui then self.Gui:Destroy() end
    Safe(self.OnUnload)
end

function RageHub:DestroyAll()
    for _, w in pairs(env.__RageHubActive) do pcall(function() w:Destroy() end) end
end

------------------------------------------------------------------ SPLASH
function Window:_splash(cfg)
    cfg = type(cfg) == "table" and cfg or {}
    local dur = cfg.Duration or 1.2
    local card = New("Frame", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(300, 130),
        BackgroundColor3 = "$Background", BorderSizePixel = 0, ZIndex = 70, Parent = self.Gui,
    }, { Corner(16), Stroke("$Stroke", 1, 0.2) })
    local sc = New("UIScale", { Scale = 0.85, Parent = card })
    Tween(sc, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
    local logo = New("Frame", { Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = card }, { Corner(14) })
    Gradient(self, logo, 45)
    Text({ Text = "R", Font = FONT_BOLD, TextSize = 24, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = logo })
    Text({ Text = cfg.Title or self.Name, Font = FONT_BOLD, TextSize = 17, Position = UDim2.fromOffset(78, 20), Size = UDim2.new(1, -90, 0, 22), Parent = card })
    Text({ Text = cfg.Subtitle or "Loading interface...", Font = FONT, TextSize = 12, TextColor3 = "$SubText", Position = UDim2.fromOffset(78, 44), Size = UDim2.new(1, -90, 0, 16), Parent = card })
    local track = New("Frame", { Position = UDim2.fromOffset(18, 96), Size = UDim2.new(1, -36, 0, 4), BackgroundColor3 = "$Stroke", BorderSizePixel = 0, Parent = card }, { Corner(2) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { Corner(2) })
    Gradient(self, fill, 0)
    Tween(fill, { Size = UDim2.fromScale(1, 1) }, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    task.delay(dur + 0.1, function()
        if self._destroyed then return end
        Tween(sc, { Scale = 0.85 }, 0.2)
        task.delay(0.2, function()
            card:Destroy()
            if not self._destroyed then self:SetVisible(true) end
        end)
    end)
end

------------------------------------------------------------------ CREATE WINDOW
function RageHub:CreateWindow(o)
    o = o or {}
    local name = o.Name or "Rage Hub"
    local prev = env.__RageHubActive[name]
    if prev then pcall(function() prev:Destroy() end) end

    if type(o.Theme) == "table" then
        RageHub:AddTheme("Custom", o.Theme)
        ApplyTheme("Custom")
    elseif type(o.Theme) == "string" then
        ApplyTheme(o.Theme)
    end

    local win = setmetatable({
        Name = name, Flags = {}, Options = {}, Tabs = {}, Connections = {}, Visible = false, Minimized = false,
        SidebarCollapsed = false, _flagListeners = {}, _tabN = 0,
        ToggleKey = ToKey(o.ToggleKey) or Enum.KeyCode.RightShift,
        ConfigFolder = o.ConfigFolder or ("RageHub/" .. (name:gsub("[^%w_%- ]", ""))),
        AutoSaveName = type(o.AutoSave) == "string" and o.AutoSave or nil,
        OnUnload = o.OnUnload, Sounds = o.Sounds == true,
        UIScale = math.clamp(tonumber(o.Scale) or 1, 0.6, 1.5),
    }, Window)

    local guiName = (o.RandomName == false) and ("RageHub_" .. (name:gsub("%W", ""))) or HttpService:GenerateGUID(false)
    local gui = New("ScreenGui", { Name = guiName, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    Mount(gui)
    win.Gui = gui
    env.__RageHubActive[name] = win
    win:_initInput()
    win:_buildTip()
    win:_buildNotifs()

    local function calc()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local sc = win.UIScale
        return Vector2.new(math.clamp(vp.X / sc - 24, 340, o.Width or 620), math.clamp(vp.Y / sc - 24, 250, o.Height or 400))
    end
    win._size = calc()

    local main = New("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(win._size.X, win._size.Y),
        BackgroundColor3 = "$Background", BackgroundTransparency = 0.04, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = gui,
    }, { Corner(14), Stroke("$Stroke", 1, 0.2) })
    win.Main = main
    win._scale = New("UIScale", { Scale = win.UIScale * 0.9, Parent = main })

    -- shimmering accent line (inset so it stays inside the rounded corners)
    local line = New("Frame", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = main }, { Corner(1) })
    local lg = Gradient(win, line, 0)
    pcall(function()
        lg.Offset = Vector2.new(-0.6, 0)
        TweenService:Create(lg, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.6, 0) }):Play()
    end)

    -- top bar
    local top = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = main })
    win._title = Text({ Text = name, Font = FONT_BOLD, TextSize = 15, Position = UDim2.fromOffset(16, 7), Size = UDim2.new(1, -150, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = top })
    win._subtitle = Text({ Text = o.Subtitle or "", Font = FONT, TextSize = 11, TextColor3 = "$SubText", Position = UDim2.fromOffset(16, 25), Size = UDim2.new(1, -150, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = top })
    New("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "$Stroke", BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = main })
    MakeDraggable(win, top, main)

    local function topBtn(txt, x, hoverKey)
        local b = New("TextButton", {
            AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, x, .5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = "$Surface",
            Text = txt, Font = FONT_BOLD, TextSize = 15, TextColor3 = "$SubText", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5, Parent = top,
        }, { Corner(8) })
        b.MouseEnter:Connect(function() Tween(b, { BackgroundColor3 = Theme[hoverKey] }, 0.12); b.TextColor3 = WHITE end)
        b.MouseLeave:Connect(function() Tween(b, { BackgroundColor3 = Theme.Surface }, 0.12); b.TextColor3 = Theme.SubText end)
        return b
    end
    topBtn("×", -10, "Danger").Activated:Connect(function()
        win:SetVisible(false)
        if not win._hintShown then
            win._hintShown = true
            win:Notify({ Title = "Hidden", Content = "Press " .. win.ToggleKey.Name .. " (or the R button) to reopen.", Duration = 3 })
        end
    end)
    topBtn("–", -44, "SurfaceHover").Activated:Connect(function() win:SetMinimized(not win.Minimized) end)
    topBtn("≡", -78, "SurfaceHover").Activated:Connect(function() win:SetSidebarCollapsed(not win.SidebarCollapsed) end)

    -- body
    local body = New("Frame", { Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 1, -47), BackgroundTransparency = 1, ClipsDescendants = true, Parent = main })
    win._body = body
    local side = New("Frame", {
        Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 128, 1, -16), BackgroundColor3 = "$Surface", BackgroundTransparency = 0.35,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = body,
    }, { Corner(12), Stroke("$Stroke", 1, 0.55) })
    win._side = side

    local search = New("TextBox", {
        Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 28), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 0.2,
        Text = "", PlaceholderText = "Search...", PlaceholderColor3 = "$SubText", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, Visible = o.Search ~= false, Parent = side,
    }, { Corner(8), Pad(10, 0, 8, 0) })
    search:GetPropertyChangedSignal("Text"):Connect(function()
        win._query = search.Text
        win:_applySearch()
    end)

    win._tabList = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 44), Size = UDim2.new(1, -16, 1, -104), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = side,
    }, { List(4) })

    local prof = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 44), BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = side }, { Corner(10), Stroke("$Stroke", 1, 0.55) })
    local avatar = New("ImageLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = "$SurfaceHover", BorderSizePixel = 0, Parent = prof }, { Corner(14) })
    local lp = Players.LocalPlayer
    Text({ Text = lp and lp.DisplayName or "Player", TextSize = 12, Position = UDim2.fromOffset(42, 6), Size = UDim2.new(1, -46, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof })
    Text({ Text = "v" .. RageHub.Version, Font = FONT, TextSize = 10, TextColor3 = "$SubText", Position = UDim2.fromOffset(42, 22), Size = UDim2.new(1, -46, 0, 14), Parent = prof })
    task.spawn(function()
        if not lp then return end
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if ok and avatar.Parent then avatar.Image = img end
    end)

    win._content = New("Frame", { Position = UDim2.fromOffset(144, 0), Size = UDim2.new(1, -144, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = body })

    -- resize grip
    if o.Resizable ~= false then
        local grip = New("TextButton", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Text = "◢",
            Font = FONT_BOLD, TextSize = 11, TextColor3 = "$SubText", AutoButtonColor = false, ZIndex = 15, Parent = main,
        })
        grip.InputBegan:Connect(function(i)
            if not IsPointer(i) or win.Minimized then return end
            local startPos, startSize, startUI = i.Position, win._size, main.Position
            win:_beginDrag(i, function(p)
                local d = p - startPos
                local sc = win.UIScale
                win:SetSize(startSize.X + d.X / sc, startSize.Y + d.Y / sc)
                local dw, dh = (win._size.X - startSize.X) * sc / 2, (win._size.Y - startSize.Y) * sc / 2
                main.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + dw, startUI.Y.Scale, startUI.Y.Offset + dh)
            end)
        end)
    end

    -- toggle key
    win:_conn(UserInputService.InputBegan:Connect(function(i, gp)
        if gp or Listening then return end
        if i.KeyCode == win.ToggleKey then win:Toggle() end
    end))

    -- keep the window sized for the screen
    local cam = Workspace.CurrentCamera
    if cam then
        win:_conn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if win._userSize then
                win:SetSize(win._size.X, win._size.Y)
            else
                win._size = calc()
                main.Size = UDim2.fromOffset(win._size.X, win.Minimized and 46 or win._size.Y)
            end
            win:_ensureOnScreen()
        end))
        if cam.ViewportSize.X / win.UIScale < 480 then win:SetSidebarCollapsed(true, false) end
    end

    -- floating launcher (touch devices by default)
    if o.Launcher == true or (o.Launcher ~= false and UserInputService.TouchEnabled) then
        local btn = New("TextButton", {
            Position = UDim2.new(0, 12, 0.4, 0), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = WHITE, Text = "",
            AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 20, Parent = gui,
        }, { Corner(22), Stroke("$Accent", 2, 0.3) })
        Gradient(win, btn, 45)
        Text({ Text = "R", Font = FONT_BOLD, TextSize = 20, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 21, Parent = btn })
        MakeDraggable(win, btn, btn, function() win:Toggle() end)
        win._launcher = btn
    end

    if o.Watermark then win:CreateWatermark(type(o.Watermark) == "table" and o.Watermark or {}) end

    if o.Splash == false then win:SetVisible(true) else win:_splash(o.Splash) end
    return win
end

return RageHub
