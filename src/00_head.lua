--[[
	Rage Hub  |  Roblox UI library
	Modern, lightweight, mobile + PC.  165 built-in vector icons (no emoji, no asset ids).

	loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

	Docs: README.md   Icons: ICONS.md   Example: examples/Example.lua
]]

local RageHub = {
	Version = "1.0.0",
	Flags = {},
	Options = {},
	Themes = {},
	Windows = {},
	ReduceMotion = false,
	Notifications = true,
}

local genv = (getgenv and getgenv()) or _G
if type(genv.RageHub) == "table" and type(genv.RageHub.Unload) == "function" then
	pcall(function() genv.RageHub:Unload() end)
end
genv.RageHub = RageHub

--// services ------------------------------------------------------------------
local cloneref = cloneref or function(o) return o end
local function svc(n)
	local ok, s = pcall(function() return cloneref(game:GetService(n)) end)
	if ok and s then return s end
	return game:GetService(n)
end

local Players = svc("Players")
local UIS = svc("UserInputService")
local TweenService = svc("TweenService")
local RunService = svc("RunService")
local HttpService = svc("HttpService")
local CoreGui = svc("CoreGui")
local TeleportService = svc("TeleportService")
local GuiService = svc("GuiService")
local Lighting = svc("Lighting")

local LocalPlayer = Players.LocalPlayer
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local setclip = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
local queueTp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

--// utils ---------------------------------------------------------------------
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function round(v, inc) inc = inc or 1; return math.floor(v / inc + 0.5) * inc end
local function decimals(inc)
	local frac = tostring(inc or 1):match("%.(%d+)")
	return frac and #frac or 0
end
local function fmtNum(v, inc) return string.format("%." .. decimals(inc) .. "f", v) end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function fire(cb, ...)
	if type(cb) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(cb, table.unpack(args, 1, args.n))
		if not ok then warn("[RageHub] callback error: " .. tostring(err)) end
	end)
end

local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({ _t = {} }, Maid) end
function Maid:Add(x) self._t[#self._t + 1] = x return x end
function Maid:Clean()
	for i = #self._t, 1, -1 do
		local x = self._t[i]
		self._t[i] = nil
		local t = typeof(x)
		if t == "RBXScriptConnection" then x:Disconnect()
		elseif t == "Instance" then pcall(function() x:Destroy() end)
		elseif type(x) == "function" then pcall(x)
		elseif type(x) == "table" and x.Destroy then pcall(function() x:Destroy() end) end
	end
end
local RootMaid = Maid.new()

--// themes --------------------------------------------------------------------
local function theme(bg, panel, card, elev, stroke, text, sub, muted, a1, a2, light)
	return {
		Bg = bg, Panel = panel, Card = card, Elevated = elev, Stroke = stroke,
		Text = text, SubText = sub, Muted = muted, Accent = a1, Accent2 = a2,
		OnAccent = rgb(255, 255, 255),
		Success = rgb(52, 211, 153), Warning = rgb(251, 191, 36), Danger = rgb(248, 113, 113),
		Light = light or false,
	}
end

RageHub.Themes.Rage = theme(rgb(18, 15, 30), rgb(12, 10, 21), rgb(26, 22, 44), rgb(37, 32, 62), rgb(58, 51, 92),
	rgb(242, 240, 255), rgb(166, 160, 200), rgb(110, 104, 148), rgb(139, 92, 246), rgb(217, 70, 239))
RageHub.Themes.Crimson = theme(rgb(20, 13, 15), rgb(14, 9, 11), rgb(32, 20, 24), rgb(46, 28, 34), rgb(78, 44, 54),
	rgb(255, 241, 243), rgb(206, 156, 164), rgb(140, 100, 108), rgb(244, 63, 94), rgb(249, 115, 22))
RageHub.Themes.Ocean = theme(rgb(12, 18, 30), rgb(8, 13, 23), rgb(18, 28, 46), rgb(26, 40, 64), rgb(40, 60, 94),
	rgb(236, 245, 255), rgb(150, 176, 210), rgb(98, 122, 158), rgb(56, 189, 248), rgb(99, 102, 241))
RageHub.Themes.Emerald = theme(rgb(11, 20, 17), rgb(7, 14, 12), rgb(18, 31, 27), rgb(26, 44, 38), rgb(40, 70, 60),
	rgb(236, 253, 245), rgb(150, 200, 180), rgb(98, 140, 124), rgb(16, 185, 129), rgb(132, 204, 22))
RageHub.Themes.Sakura = theme(rgb(24, 15, 22), rgb(17, 10, 16), rgb(36, 23, 34), rgb(52, 33, 49), rgb(84, 52, 78),
	rgb(255, 240, 248), rgb(208, 160, 190), rgb(144, 104, 130), rgb(244, 114, 182), rgb(168, 85, 247))
RageHub.Themes.Midnight = theme(rgb(14, 14, 16), rgb(9, 9, 11), rgb(24, 24, 28), rgb(36, 36, 42), rgb(58, 58, 68),
	rgb(244, 244, 248), rgb(160, 160, 172), rgb(106, 106, 118), rgb(250, 250, 250), rgb(161, 161, 170))
RageHub.Themes.Midnight.OnAccent = rgb(20, 20, 24)
RageHub.Themes.Light = theme(rgb(244, 245, 250), rgb(233, 235, 244), rgb(255, 255, 255), rgb(238, 240, 248), rgb(214, 218, 232),
	rgb(24, 24, 38), rgb(96, 100, 126), rgb(150, 154, 176), rgb(124, 58, 237), rgb(192, 38, 211), true)

local Theme = {}
for k, v in pairs(RageHub.Themes.Rage) do Theme[k] = v end
RageHub.Theme = Theme

local themed = setmetatable({}, { __mode = "k" })     -- inst -> { prop = themeKey }
local themedIcons = setmetatable({}, { __mode = "k" }) -- icon -> themeKey
local themedGrad = setmetatable({}, { __mode = "k" })  -- UIGradient -> true

local function bind(inst, prop, key)
	local m = themed[inst]
	if not m then m = {}; themed[inst] = m end
	m[prop] = key
	inst[prop] = Theme[key]
	return inst
end

--// instance helpers ----------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
		o.Font = Enum.Font.GothamMedium
		o.TextSize = 13
		o.BackgroundTransparency = 1
		o.AutoLocalize = false
		if o:IsA("TextButton") then o.AutoButtonColor = false; o.Text = "" end
	elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
		o.BackgroundTransparency = 1
	end
	if props then
		for k, v in pairs(props) do
			if type(v) == "string" and v:byte(1) == 64 and (k == "Color" or k:sub(-6) == "Color3") then
				bind(o, k, v:sub(2))
			else
				o[k] = v
			end
		end
	end
	if parent then o.Parent = parent end
	return o
end

local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function stroke(p, key, th, tr)
	return new("UIStroke", { Color = "@" .. (key or "Stroke"), Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function pad(p, l, t, r, b)
	return new("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0) }, p)
end
local function list(p, gap, dir, ha, va)
	return new("UIListLayout", {
		Padding = UDim.new(0, gap or 0),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
		VerticalAlignment = va or Enum.VerticalAlignment.Top,
	}, p)
end
local function accentGradient(p, rot)
	local g = new("UIGradient", { Rotation = rot or 0,
		Color = ColorSequence.new(Theme.Accent, Theme.Accent2) }, p)
	themedGrad[g] = true
	return g
end

local function tw(o, t, props, style)
	if RageHub.ReduceMotion or not t or t <= 0 then
		for k, v in pairs(props) do o[k] = v end
		return
	end
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- re-point a themed property at another theme key (optionally tweened)
local function setKey(inst, prop, key, t)
	local m = themed[inst]
	if not m then m = {}; themed[inst] = m end
	m[prop] = key
	if t and t > 0 then tw(inst, t, { [prop] = Theme[key] }) else inst[prop] = Theme[key] end
end

-- drag tracking: only listens while a pointer is actually down (zero idle cost)
local function trackInput(input, onMove, onEnd)
	local c1, c2
	c1 = UIS.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			onMove(i)
		end
	end)
	c2 = input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			c1:Disconnect(); c2:Disconnect()
			if onEnd then onEnd() end
		end
	end)
end

local function isPointer(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function guiPos(i)
	return Vector2.new(i.Position.X, i.Position.Y) + GuiService:GetGuiInset()
end

local function guiParent()
	local ok, ui = pcall(function() return gethui and gethui() end)
	if ok and ui then return ui end
	local probe = Instance.new("Folder")
	local ok2 = pcall(function() probe.Parent = CoreGui end)
	probe:Destroy()
	if ok2 then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

