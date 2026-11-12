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

local ICONS = {
	["home"] = {{"P",3,11,12,3,21,11},{"P",5,9.5,5,20,19,20,19,9.5},{"P",10,20,10,14,14,14,14,20}},
	["settings"] = {{"C",12,12,3},{"C",12,12,6.6},{"L",18.6,12,21.8,12},{"L",16.67,16.67,18.93,18.93},{"L",12,18.6,12,21.8},{"L",7.33,16.67,5.07,18.93},{"L",5.4,12,2.2,12},{"L",7.33,7.33,5.07,5.07},{"L",12,5.4,12,2.2},{"L",16.67,7.33,18.93,5.07}},
	["sliders"] = {{"L",4,6,20,6},{"L",4,12,20,12},{"L",4,18,20,18},{"D",9,6,2.4},{"D",15,12,2.4},{"D",8,18,2.4}},
	["menu"] = {{"L",4,6,20,6},{"L",4,12,20,12},{"L",4,18,20,18}},
	["more"] = {{"D",5,12,1.8},{"D",12,12,1.8},{"D",19,12,1.8}},
	["list"] = {{"L",8,6,21,6},{"L",8,12,21,12},{"L",8,18,21,18},{"D",4,6,1.2},{"D",4,12,1.2},{"D",4,18,1.2}},
	["grid"] = {{"R",3,3,7.5,7.5,2},{"R",13.5,3,7.5,7.5,2},{"R",3,13.5,7.5,7.5,2},{"R",13.5,13.5,7.5,7.5,2}},
	["layers"] = {{"P",12,3,21.5,8,12,13,2.5,8,12,3},{"P",2.5,12.5,12,17.5,21.5,12.5},{"P",2.5,16.5,12,21.5,21.5,16.5}},
	["search"] = {{"C",10.5,10.5,7},{"L",15.5,15.5,21,21}},
	["filter"] = {{"P",3,4.5,21,4.5,14,12.5,14,19.5,10,21.5,10,12.5,3,4.5}},
	["toggle"] = {{"R",2,7,20,10,5},{"D",16,12,3}},
	["check"] = {{"P",4,12.5,9.5,18,20,6.5}},
	["x"] = {{"L",5,5,19,19},{"L",19,5,5,19}},
	["plus"] = {{"L",12,5,12,19},{"L",5,12,19,12}},
	["minus"] = {{"L",5,12,19,12}},
	["chevron-up"] = {{"P",6,15,12,9,18,15}},
	["chevron-down"] = {{"P",6,9,12,15,18,9}},
	["chevron-left"] = {{"P",15,6,9,12,15,18}},
	["chevron-right"] = {{"P",9,6,15,12,9,18}},
	["chevrons-up-down"] = {{"P",8,9,12,5,16,9},{"P",8,15,12,19,16,15}},
	["arrow-up"] = {{"L",12,19,12,5},{"P",6,11,12,5,18,11}},
	["arrow-down"] = {{"L",12,5,12,19},{"P",6,13,12,19,18,13}},
	["arrow-left"] = {{"L",19,12,5,12},{"P",11,6,5,12,11,18}},
	["arrow-right"] = {{"L",5,12,19,12},{"P",13,6,19,12,13,18}},
	["expand"] = {{"P",4,9,4,4,9,4},{"P",15,4,20,4,20,9},{"P",20,15,20,20,15,20},{"P",9,20,4,20,4,15}},
	["move"] = {{"L",12,3,12,21},{"L",3,12,21,12},{"P",9,6,12,3,15,6},{"P",9,18,12,21,15,18},{"P",6,9,3,12,6,15},{"P",18,9,21,12,18,15}},
	["resize"] = {{"L",21,11,11,21},{"L",21,17,17,21}},
	["info"] = {{"C",12,12,9.5},{"L",12,11,12,16.5},{"D",12,7.6,1.2}},
	["warning"] = {{"P",12,3,22,20.5,2,20.5,12,3},{"L",12,9.5,12,14},{"D",12,17.3,1.1}},
	["help"] = {{"C",12,12,9.5},{"P",9.2,9.8,9.45,8.64,10.16,7.69,11.2,7.12,12.38,7.03,13.49,7.43,14.34,8.26,14.77,9.37,14.7,10.55,14.14,11.6},{"L",12,12.4,12,14},{"D",12,17.2,1.1}},
	["circle-check"] = {{"C",12,12,9.5},{"P",8,12,11,15,16,9}},
	["circle-x"] = {{"C",12,12,9.5},{"L",9,9,15,15},{"L",15,9,9,15}},
	["circle"] = {{"C",12,12,9}},
	["dot"] = {{"D",12,12,3}},
	["square"] = {{"R",4,4,16,16,3}},
	["hexagon"] = {{"P",12,2.5,20.5,7.25,20.5,16.75,12,21.5,3.5,16.75,3.5,7.25,12,2.5}},
	["hash"] = {{"L",8.5,3.5,6.5,20.5},{"L",17.5,3.5,15.5,20.5},{"L",4,9,20,9},{"L",3.5,15.5,19.5,15.5}},
	["external-link"] = {{"P",14,3,21,3,21,10},{"L",21,3,11,13},{"P",18,14,18,19,16,21,5,21,3,19,3,8,5,6,10,6}},
	["user"] = {{"C",12,8,4},{"P",4,21,4.61,17.94,6.34,15.34,8.94,13.61,12,13,15.06,13.61,17.66,15.34,19.39,17.94,20,21}},
	["users"] = {{"C",9,8,3.5},{"P",2.5,21,2.99,18.51,4.4,16.4,6.51,14.99,9,14.5,11.49,14.99,13.6,16.4,15.01,18.51,15.5,21},{"C",17,8.5,3},{"P",15.36,16.49,17.17,16.2,18.95,16.61,20.45,17.67,21.45,19.2,21.8,21}},
	["user-circle"] = {{"C",12,12,9.5},{"C",12,10,3},{"P",5.89,16.28,7.27,14.04,9.43,12.53,12,12,14.57,12.53,16.73,14.04,18.11,16.28}},
	["walk"] = {{"C",12,4.5,2.3},{"L",12,8,12,15},{"L",12,15,8,21},{"L",12,15,16,21},{"L",12,10,7.5,13},{"L",12,10,16.5,13}},
	["run"] = {{"C",15,4.5,2.3},{"P",13,8.5,10,11,7,11.5},{"P",13,8.5,13,13,16.5,15.5,16.5,20},{"P",13,13,9,16,8,21},{"P",13.5,10,17,10.5,19,13}},
	["jump"] = {{"C",12,5,2.3},{"L",12,8.5,12,15},{"L",12,15,8.5,20},{"L",12,15,15.5,20},{"L",12,10,7,6},{"L",12,10,17,6}},
	["fly"] = {{"P",3,16,3.5,10,8,5.5,14,5,21,8,16,9.5,13,13,9.5,17,3,16},{"L",6.5,13,12,8.5}},
	["teleport"] = {{"L",3,12,13,12},{"P",9,8,13,12,9,16},{"P",15.96,6.09,18.55,6.2,20.86,7.4,22.44,9.46,23,12,22.44,14.54,20.86,16.6,18.55,17.8,15.96,17.91}},
	["eye"] = {{"P",2,12,6,7.5,12,5.5,18,7.5,22,12,18,16.5,12,18.5,6,16.5,2,12},{"C",12,12,3}},
	["eye-off"] = {{"P",2,12,6,7.5,12,5.5,18,7.5,22,12,18,16.5,12,18.5,6,16.5,2,12},{"C",12,12,3},{"L",4,4,20,20}},
	["bot"] = {{"R",4,8,16,12,3.5},{"L",12,4,12,8},{"D",12,3.3,1.3},{"D",9,13.5,1.5},{"D",15,13.5,1.5},{"L",9.5,17,14.5,17}},
	["sword"] = {{"P",14.5,17.5,3,6,3,3,6,3,17.5,14.5},{"L",13,19,19,13},{"L",16,16,20,20},{"L",19,21,21,19}},
	["swords"] = {{"L",4,4,18,18},{"L",20,4,6,18},{"L",14,18,18,14},{"L",6,14,10,18}},
	["shield"] = {{"P",12,2.5,20,5.5,20,12,17.5,17.5,12,21.5,6.5,17.5,4,12,4,5.5,12,2.5}},
	["shield-check"] = {{"P",12,2.5,20,5.5,20,12,17.5,17.5,12,21.5,6.5,17.5,4,12,4,5.5,12,2.5},{"P",8.5,12,11,14.5,15.5,9.5}},
	["target"] = {{"C",12,12,9},{"C",12,12,5},{"D",12,12,1.4}},
	["crosshair"] = {{"C",12,12,7},{"L",12,2,12,7},{"L",12,17,12,22},{"L",2,12,7,12},{"L",17,12,22,12}},
	["radar"] = {{"C",12,12,9.5},{"C",12,12,5.5},{"L",12,12,18,6},{"D",12,12,1.3}},
	["skull"] = {{"P",4.5,10,6,5,12,3,18,5,19.5,10,17,13.5,17,18.5,7,18.5,7,13.5,4.5,10},{"C",9,11,1.8},{"C",15,11,1.8},{"L",10,15.5,10,18.5},{"L",14,15.5,14,18.5}},
	["ghost"] = {{"P",5,21,5,10,7,5,12,3,17,5,19,10,19,21,16,18,13.5,21,10.5,21,8,18,5,21},{"D",9.5,10,1.2},{"D",14.5,10,1.2}},
	["bomb"] = {{"C",11,14,7},{"L",15.5,9,19,5.5},{"L",17,3.5,20.5,7},{"D",20.5,3.5,1}},
	["trophy"] = {{"P",7,3.5,17,3.5,17,9.5,14.5,13.5,9.5,13.5,7,9.5,7,3.5},{"P",7,5.5,4,5.5,4,8,7,10},{"P",17,5.5,20,5.5,20,8,17,10},{"L",12,13.5,12,20.5},{"L",8,20.5,16,20.5}},
	["crown"] = {{"P",3,18,3,7,8,12,12,5,16,12,21,7,21,18,3,18},{"L",5,21,19,21}},
	["gem"] = {{"P",6,3.5,18,3.5,22,9.5,12,21,2,9.5,6,3.5},{"L",2,9.5,22,9.5},{"P",9,9.5,12,21,15,9.5},{"P",9,9.5,10.5,3.5},{"P",15,9.5,13.5,3.5}},
	["star"] = {{"P",12,2.5,14.9,8.7,21.7,9.5,16.6,14.1,18,20.8,12,17.5,6,20.8,7.4,14.1,2.3,9.5,9.1,8.7,12,2.5}},
	["heart"] = {{"P",12,20,5,13,3.5,9,5,5.5,8.5,4.5,12,7.5,15.5,4.5,19,5.5,20.5,9,19,13,12,20}},
	["zap"] = {{"P",13,2,4.5,13.5,11.5,13.5,10.5,22,19.5,10,12.5,10,13,2}},
	["flame"] = {{"P",12,2.5,16.5,8,18,13,16,18.5,12,21.5,8,18.5,6,13,8.5,9.5,10.5,11.5,12,2.5}},
	["rocket"] = {{"P",12,2.5,16.5,6.5,17,12.5,14.5,16.5,9.5,16.5,7,12.5,7.5,6.5,12,2.5},{"C",12,9.5,1.8},{"P",7.5,12.5,4.5,15,5,19,9,17},{"P",16.5,12.5,19.5,15,19,19,15,17},{"L",12,18.5,12,21.5}},
	["gamepad"] = {{"R",2.5,7,19,11,5.5},{"L",7,10.5,7,14.5},{"L",5,12.5,9,12.5},{"D",15.5,11,1.1},{"D",18,13.5,1.1}},
	["wand"] = {{"L",4,20,15,9},{"L",18,3,18,8},{"L",15.5,5.5,20.5,5.5},{"L",20,12,20,15},{"L",18.5,13.5,21.5,13.5}},
	["sparkles"] = {{"P",12,2.5,14,10,21.5,12,14,14,12,21.5,10,14,2.5,12,10,10,12,2.5},{"L",19,3,19,7},{"L",17,5,21,5}},
	["magnet"] = {{"P",19.5,12,18.93,14.87,17.3,17.3,14.87,18.93,12,19.5,9.13,18.93,6.7,17.3,5.07,14.87,4.5,12},{"P",15.5,12,15.23,13.34,14.47,14.47,13.34,15.23,12,15.5,10.66,15.23,9.53,14.47,8.77,13.34,8.5,12},{"L",4.5,12,4.5,4},{"L",19.5,12,19.5,4},{"L",8.5,12,8.5,4},{"L",15.5,12,15.5,4},{"L",4.5,4,8.5,4},{"L",15.5,4,19.5,4}},
	["egg"] = {{"P",12,2.9,13.56,3.22,15.07,4.16,16.48,5.65,17.71,7.6,18.65,9.87,19.2,12.3,19.26,14.73,18.77,17,17.7,18.95,16.13,20.44,14.17,21.38,12,21.7,9.83,21.38,7.87,20.44,6.3,18.95,5.23,17,4.74,14.73,4.8,12.3,5.35,9.87,6.29,7.6,7.52,5.65,8.93,4.16,10.44,3.22,12,2.9},{"P",8.5,13.5,10.5,11.5,12.5,13.5,14.5,11.5,15.5,12.5}},
	["paw"] = {{"D",6,10.5,1.9},{"D",10,6.5,1.9},{"D",14,6.5,1.9},{"D",18,10.5,1.9},{"P",12,12,15.5,15,16.5,18.5,14.5,20.5,12,19.5,9.5,20.5,7.5,18.5,8.5,15,12,12}},
	["sprout"] = {{"L",12,21,12,11},{"P",12,13,7,13.5,4,10.5,4,7,7.5,7.5,10.5,9.5,12,13},{"P",12,10,14,6,18,4.5,20.5,4.5,20,8.5,17,11,12,10}},
	["leaf"] = {{"P",20.5,3.5,11,4.5,5.5,10,5.5,16,8.5,18.5,14.5,18,19.5,12,20.5,3.5},{"L",3,21,11,13}},
	["tree"] = {{"P",12,2.5,18,10,15,10,19,16,5,16,9,10,6,10,12,2.5},{"L",12,16,12,21.5}},
	["fish"] = {{"P",3,12,8,7,14,6.5,18,10,21.5,7,21.5,17,18,14,14,17.5,8,17,3,12},{"D",8,11.5,1}},
	["droplet"] = {{"P",12,2.5,17,9.5,18.5,14,16.5,18.5,12,21,7.5,18.5,5.5,14,7,9.5,12,2.5}},
	["snowflake"] = {{"L",12,2.5,12,21.5},{"L",3.8,7.2,20.2,16.8},{"L",20.2,7.2,3.8,16.8}},
	["pumpkin"] = {{"R",3,7.5,18,13.5,6.5},{"R",8.5,7.5,7,13.5,3.5},{"P",12,7.5,12,4.5,14.5,3.5}},
	["mountain"] = {{"P",2,20,9,7,13,13,15.5,9.5,22,20,2,20}},
	["moon"] = {{"P",21,12,20.19,15.74,17.89,18.8,14.54,20.64,10.72,20.91,7.13,19.57,4.43,16.87,3.09,13.28,3.36,9.46,5.2,6.11,8.26,3.81,12,3},{"P",12,3,10.62,5.07,10.14,7.5,10.62,9.93,12,12,14.07,13.38,16.5,13.86,18.93,13.38,21,12}},
	["sun"] = {{"C",12,12,4.2},{"L",19.4,12,22,12},{"L",17.23,17.23,19.07,19.07},{"L",12,19.4,12,22},{"L",6.77,17.23,4.93,19.07},{"L",4.6,12,2,12},{"L",6.77,6.77,4.93,4.93},{"L",12,4.6,12,2},{"L",17.23,6.77,19.07,4.93}},
	["cloud"] = {{"L",7.5,19,17.5,19},{"P",17.5,12,18.84,12.27,19.97,13.03,20.73,14.16,21,15.5,20.73,16.84,19.97,17.97,18.84,18.73,17.5,19},{"P",7.5,19,6.16,18.73,5.03,17.97,4.27,16.84,4,15.5,4.27,14.16,5.03,13.03,6.16,12.27,7.5,12},{"P",8,12,8.37,10.16,9.41,8.61,10.96,7.57,12.8,7.2,14.64,7.57,16.19,8.61,17.23,10.16,17.6,12}},
	["box"] = {{"P",12,2.5,21,7.5,21,16.5,12,21.5,3,16.5,3,7.5,12,2.5},{"P",3,7.5,12,12.5,21,7.5},{"L",12,12.5,12,21.5}},
	["bag"] = {{"P",5,8,19,8,20,21,4,21,5,8},{"P",8,8,8.3,6.47,9.17,5.17,10.47,4.3,12,4,13.53,4.3,14.83,5.17,15.7,6.47,16,8}},
	["gift"] = {{"R",3,9,18,4,1.5},{"R",5,13,14,8,1.5},{"L",12,9,12,21},{"P",12,9,8,8,7.5,5,10,4.5,12,9},{"P",12,9,16,8,16.5,5,14,4.5,12,9}},
	["coin"] = {{"C",12,12,9.5},{"C",12,12,5.5}},
	["dollar"] = {{"L",12,3,12,21},{"P",17,7,15,5.8,10.5,5.8,8,8,8.5,10.5,12,12,15.5,13.5,16,16,13.5,18.2,9,18.2,7,17}},
	["store"] = {{"P",3.5,9,5,3.5,19,3.5,20.5,9,3.5,9},{"R",5,9,14,12,1},{"R",9.5,14,5,7,1}},
	["cart"] = {{"P",2,3.5,5,3.5,7.5,15.5,18.5,15.5,21,7,6,7},{"C",9.5,20,1.5},{"C",17,20,1.5}},
	["tag"] = {{"P",3,3,12.5,3,21,11.5,12,21,3,12,3,3},{"D",7.5,7.5,1.5}},
	["bookmark"] = {{"P",6,3,18,3,18,21.5,12,17,6,21.5,6,3}},
	["key"] = {{"C",8,15,4.5},{"L",11.5,11.5,21,2},{"L",17.5,5.5,20,8},{"L",15,8,17,10}},
	["lightbulb"] = {{"P",7.76,13.74,6.38,11.6,6.02,9.07,6.73,6.62,8.4,4.7,10.72,3.64,13.28,3.64,15.6,4.7,17.27,6.62,17.98,9.07,17.62,11.6,16.24,13.74},{"P",7.8,13.7,9.5,16,9.5,18.5,14.5,18.5,14.5,16,16.2,13.7},{"L",10,21.5,14,21.5}},
	["anchor"] = {{"C",12,5,2.5},{"L",12,7.5,12,21.5},{"L",8,12,16,12},{"P",19.99,15.41,18.18,18.33,15.37,20.3,12,21,8.63,20.3,5.82,18.33,4.01,15.41}},
	["hammer"] = {{"L",14,10,4.5,19.5},{"P",9,7,14,2.5,21.5,10,17,15,9,7}},
	["wrench"] = {{"C",16.5,7.5,4.5},{"L",13.3,10.7,4,20}},
	["pickaxe"] = {{"L",4,20,14,10},{"P",5.09,8.01,8.25,7.5,11.37,8.2,14.01,9.99,15.8,12.63,16.5,15.75,15.99,18.91}},
	["coffee"] = {{"P",4,8,4,15,7,19,14,19,17,15,17,8,4,8},{"P",17,9.5,20,9.5,20,14,17,14},{"L",7,3.5,7,5.5},{"L",10.5,3,10.5,5.5},{"L",14,3.5,14,5.5}},
	["map"] = {{"P",3,6,9,3.5,15,6,21,3.5,21,18,15,20.5,9,18,3,20.5,3,6},{"L",9,3.5,9,18},{"L",15,6,15,20.5}},
	["compass"] = {{"C",12,12,9.5},{"P",15.5,8.5,13.5,13.5,8.5,15.5,10.5,10.5,15.5,8.5}},
	["pin"] = {{"P",12,21.5,6.5,14,5.5,10,7,6,10,4,14,4,17,6,18.5,10,17.5,14,12,21.5},{"C",12,10,2.3}},
	["flag"] = {{"L",5,3,5,22},{"P",5,4,19,4,16,8.5,19,13,5,13}},
	["globe"] = {{"C",12,12,9.5},{"L",2.5,12,21.5,12},{"R",7.5,2.5,9,19,4.5}},
	["plane"] = {{"P",21,3,3,10.5,10.5,13.5,13.5,21,21,3}},
	["car"] = {{"P",2.5,16,2.5,11.5,5.5,10.5,8,6.5,16,6.5,18.5,10.5,21.5,11.5,21.5,16,2.5,16},{"C",7,17.5,2},{"C",17,17.5,2}},
	["terminal"] = {{"R",2.5,4,19,16,3},{"P",7,9.5,10.5,12.5,7,15.5},{"L",12.5,16,17,16}},
	["code"] = {{"P",8,7,3,12,8,17},{"P",16,7,21,12,16,17},{"L",14,4.5,10,19.5}},
	["cpu"] = {{"R",6,6,12,12,2},{"R",9.5,9.5,5,5,1},{"L",9,2.5,9,6},{"L",15,2.5,15,6},{"L",9,18,9,21.5},{"L",15,18,15,21.5},{"L",2.5,9,6,9},{"L",2.5,15,6,15},{"L",18,9,21.5,9},{"L",18,15,21.5,15}},
	["database"] = {{"R",4,3,16,6,3},{"R",4,9,16,6,3},{"R",4,15,16,6,3}},
	["server"] = {{"R",3,3.5,18,7,2},{"R",3,13.5,18,7,2},{"D",7,7,1.1},{"D",7,17,1.1}},
	["bug"] = {{"R",7.5,8,9,12.5,4.5},{"L",12,8,12,20.5},{"L",9,4,10.5,6.5},{"L",15,4,13.5,6.5},{"L",7.5,12.5,3.5,11},{"L",16.5,12.5,20.5,11},{"L",7.5,17,3.5,19},{"L",16.5,17,20.5,19}},
	["activity"] = {{"P",2,12,6,12,9,4,15,20,18,12,22,12}},
	["chart"] = {{"F",4,12,3,9,1},{"F",10.5,4,3,17,1},{"F",17,8,3,13,1}},
	["trending"] = {{"P",3,17,9,11,13,15,21,7},{"P",15,7,21,7,21,13}},
	["gauge"] = {{"P",3,15,3.69,11.56,5.64,8.64,8.56,6.69,12,6,15.44,6.69,18.36,8.64,20.31,11.56,21,15},{"L",12,15,16,9.5},{"D",12,15,1.3}},
	["battery"] = {{"R",2.5,7,17,10,2.5},{"L",21.5,10.5,21.5,13.5},{"F",5,9.5,6,5,1}},
	["monitor"] = {{"R",2.5,3.5,19,13,2.5},{"L",8,21,16,21},{"L",12,16.5,12,21}},
	["phone"] = {{"R",6.5,2.5,11,19,2.5},{"D",12,18.5,0.9}},
	["keyboard"] = {{"R",2.5,6,19,12,2.5},{"D",6.5,10,0.9},{"D",10,10,0.9},{"D",14,10,0.9},{"D",17.5,10,0.9},{"L",7,15,17,15}},
	["mouse"] = {{"R",6.5,2.5,11,19,5.5},{"L",12,2.5,12,9.5}},
	["pointer"] = {{"P",5,3,19,11,12,13,9.5,20,5,3}},
	["wifi"] = {{"P",9.03,16.03,10.39,15.12,12,14.8,13.61,15.12,14.97,16.03},{"P",6.06,13.06,8.79,11.24,12,10.6,15.21,11.24,17.94,13.06},{"P",3.09,10.09,7.18,7.36,12,6.4,16.82,7.36,20.91,10.09},{"D",12,19,1.3}},
	["link"] = {{"R",2.5,8.5,11,7,3.5},{"R",10.5,8.5,11,7,3.5}},
	["lock"] = {{"R",4.5,10.5,15,11,2.5},{"P",7.5,10.5,7.84,8.78,8.82,7.32,10.28,6.34,12,6,13.72,6.34,15.18,7.32,16.16,8.78,16.5,10.5},{"D",12,16,1.2}},
	["unlock"] = {{"R",4.5,10.5,15,11,2.5},{"L",7.5,10.5,7.5,7},{"P",7.5,7,7.84,5.28,8.82,3.82,10.28,2.84,12,2.5,13.72,2.84,15.18,3.82,16.16,5.28,16.5,7},{"D",12,16,1.2}},
	["power"] = {{"P",16,6.07,18.55,8.41,19.88,11.61,19.73,15.07,18.13,18.14,15.38,20.25,12,21,8.62,20.25,5.87,18.14,4.27,15.07,4.12,11.61,5.45,8.41,8,6.07},{"L",12,3,12,12}},
	["refresh"] = {{"P",16,5.07,18.52,7.36,19.86,10.49,19.77,13.89,18.29,16.95,15.67,19.11,12.38,19.99,9.03,19.43,6.21,17.52,4.44,14.62,4.04,11.24,5.07,8},{"P",5,3.5,5,8.5,10,8.5}},
	["repeat"] = {{"P",17,3,20,6,17,9},{"P",4,11,4,8,7,6,20,6},{"P",7,21,4,18,7,15},{"P",20,13,20,16,17,18,4,18}},
	["shuffle"] = {{"P",3,7,8,7,16,17,21,17},{"P",18,14,21,17,18,20},{"P",3,17,8,17,10.5,14},{"P",13.5,10,16,7,21,7},{"P",18,4,21,7,18,10}},
	["login"] = {{"P",10,17,15,12,10,7},{"L",15,12,3,12},{"P",14,3,19,3,21,5,21,19,19,21,14,21}},
	["logout"] = {{"P",16,17,21,12,16,7},{"L",21,12,9,12},{"P",9,3,5,3,3,5,3,19,5,21,9,21}},
	["play"] = {{"P",7,4.5,19,12,7,19.5,7,4.5}},
	["play-circle"] = {{"C",12,12,9.5},{"P",10,8.5,15.5,12,10,15.5,10,8.5}},
	["pause"] = {{"F",6,4.5,4,15,1.2},{"F",14,4.5,4,15,1.2}},
	["stop"] = {{"F",5,5,14,14,2}},
	["skip"] = {{"P",5,5,15,12,5,19,5,5},{"L",19,5,19,19}},
	["download"] = {{"L",12,3,12,15},{"P",7,10.5,12,15.5,17,10.5},{"P",4,16,4,20,20,20,20,16}},
	["upload"] = {{"L",12,15.5,12,3.5},{"P",7,8,12,3,17,8},{"P",4,16,4,20,20,20,20,16}},
	["copy"] = {{"R",8.5,8.5,12,12,2.5},{"P",5.5,15.5,4.5,15.5,3.5,14.5,3.5,5.5,5.5,3.5,14.5,3.5,15.5,4.5,15.5,5.5}},
	["trash"] = {{"L",3.5,6.5,20.5,6.5},{"P",6,6.5,7,19.5,8.5,21,15.5,21,17,19.5,18,6.5},{"P",9.5,6.5,9.5,3.5,14.5,3.5,14.5,6.5},{"L",10,10.5,10,17},{"L",14,10.5,14,17}},
	["edit"] = {{"P",16.5,3.5,20.5,7.5,8,20,3.5,20.5,4,16,16.5,3.5},{"L",14,6,18,10}},
	["save"] = {{"R",3.5,3.5,17,17,2.5},{"R",7,3.5,9,5.5,1},{"R",6.5,12.5,11,8,1.5}},
	["folder"] = {{"P",3,6.5,3,19,21,19,21,8.5,11.5,8.5,9.5,5.5,4.5,5.5,3,6.5}},
	["file"] = {{"P",5.5,3,14,3,19,8,19,21,5.5,21,5.5,3},{"P",14,3,14,8,19,8},{"L",8.5,13,16,13},{"L",8.5,17,16,17}},
	["clipboard"] = {{"R",5,4,14,17,2.5},{"R",9,2.5,6,3.5,1.5},{"L",8.5,11,15.5,11},{"L",8.5,15,13,15}},
	["book"] = {{"P",3,5,9,4.5,12,6.5,15,4.5,21,5,21,18.5,15,18,12,20,9,18,3,18.5,3,5},{"L",12,6.5,12,20}},
	["inbox"] = {{"P",3,13,7,13,8.5,16,15.5,16,17,13,21,13},{"P",5.5,4,18.5,4,21,13,21,19,3,19,3,13,5.5,4}},
	["mail"] = {{"R",2.5,4.5,19,15,2.5},{"P",3,7,12,13.5,21,7}},
	["chat"] = {{"P",4,5,20,5,20,16,11,16,6.5,20,6.5,16,4,16,4,5}},
	["send"] = {{"P",21.5,2.5,2.5,10,10.5,13.5,14,21.5,21.5,2.5},{"L",21.5,2.5,10.5,13.5}},
	["bell"] = {{"P",6,17,6,10,8,6,12,5,16,6,18,10,18,17,20,18.5,4,18.5,6,17},{"P",14.2,19,14.03,19.84,13.56,20.56,12.84,21.03,12,21.2,11.16,21.03,10.44,20.56,9.97,19.84,9.8,19},{"L",12,2.5,12,5}},
	["calendar"] = {{"R",3,5,18,16,2.5},{"L",3,10,21,10},{"L",8,2.5,8,7},{"L",16,2.5,16,7}},
	["clock"] = {{"C",12,12,9.5},{"P",12,6.5,12,12,15.5,14}},
	["timer"] = {{"C",12,13.5,7.5},{"L",12,13.5,12,9.5},{"L",9.5,2.5,14.5,2.5},{"L",12,2.5,12,6},{"L",18,7.5,19.5,6}},
	["hourglass"] = {{"P",6,3,18,3,18,7,12,12,6,7,6,3},{"P",6,21,18,21,18,17,12,12,6,17,6,21}},
	["volume"] = {{"P",4,9.5,8,9.5,13,5,13,19,8,14.5,4,14.5,4,9.5},{"P",16.21,8.17,17.53,9.89,18,12,17.53,14.11,16.21,15.83},{"P",18.79,5.11,21.16,8.2,22,12,21.16,15.8,18.79,18.89}},
	["mic"] = {{"R",9,2.5,6,11.5,3},{"P",19,11,18.47,13.68,16.95,15.95,14.68,17.47,12,18,9.32,17.47,7.05,15.95,5.53,13.68,5,11},{"L",12,18,12,21.5},{"L",8.5,21.5,15.5,21.5}},
	["music"] = {{"P",9,18,9,5,20,3,20,16},{"C",6.5,18,2.7},{"C",17.5,16,2.7}},
	["camera"] = {{"P",3,8,7,8,9,5,15,5,17,8,21,8,21,19,3,19,3,8},{"C",12,13,3.5}},
	["image"] = {{"R",3,3.5,18,17,2.5},{"D",8.5,9,1.6},{"P",3.5,17,9,12,14,17,17,14,20.5,17.5}},
	["palette"] = {{"C",12,12,9.5},{"D",8,10,1.3},{"D",12,7.5,1.3},{"D",16,10,1.3},{"D",8.5,15,1.3}},
	["brush"] = {{"P",18.5,3,21,5.5,12,14.5,9.5,12,18.5,3},{"P",9.5,12,6,13,5,16.5,4,20,7.5,19,11,18,12,14.5}},
	["rage"] = {{"P",12,2.5,20.5,7.25,20.5,16.75,12,21.5,3.5,16.75,3.5,7.25,12,2.5},{"P",13,7,9,12.5,12.5,12.5,11,17,15.5,11,12,11,13,7}},
}
local ICON_ALIASES = {
	["gear"] = "settings",
	["cog"] = "settings",
	["misc"] = "grid",
	["farm"] = "sprout",
	["plant"] = "sprout",
	["visuals"] = "eye",
	["esp"] = "eye",
	["player"] = "user",
	["avatar"] = "user",
	["combat"] = "sword",
	["pvp"] = "swords",
	["aimbot"] = "crosshair",
	["teleports"] = "teleport",
	["tp"] = "teleport",
	["movement"] = "run",
	["speed"] = "run",
	["fling"] = "zap",
	["bolt"] = "zap",
	["lightning"] = "zap",
	["eggs"] = "egg",
	["pets"] = "paw",
	["pet"] = "paw",
	["shop"] = "store",
	["buy"] = "cart",
	["money"] = "coin",
	["cash"] = "dollar",
	["premium"] = "crown",
	["vip"] = "crown",
	["event"] = "calendar",
	["events"] = "calendar",
	["webhook"] = "link",
	["server-hop"] = "shuffle",
	["hop"] = "shuffle",
	["rejoin"] = "refresh",
	["reconnect"] = "refresh",
	["afk"] = "coffee",
	["anti-afk"] = "coffee",
	["script"] = "code",
	["executor"] = "terminal",
	["console"] = "terminal",
	["stats"] = "chart",
	["info-circle"] = "info",
	["alert"] = "warning",
	["error"] = "circle-x",
	["success"] = "circle-check",
	["close"] = "x",
	["back"] = "chevron-left",
	["next"] = "chevron-right",
	["up"] = "chevron-up",
	["down"] = "chevron-down",
	["world"] = "globe",
	["map-pin"] = "pin",
	["location"] = "pin",
	["performance"] = "gauge",
	["fps"] = "gauge",
	["config"] = "save",
	["profile"] = "user-circle",
	["account"] = "user-circle",
	["discord"] = "chat",
	["fly-mode"] = "fly",
	["noclip"] = "ghost",
	["godmode"] = "shield",
	["auto"] = "bot",
	["automation"] = "bot",
	["farm-bot"] = "bot",
	["unload"] = "power",
	["exit"] = "logout",
	["join"] = "login",
	["logo"] = "rage",
	["ragehub"] = "rage",
	["dark"] = "moon",
	["light"] = "sun",
	["theme"] = "palette",
	["ui"] = "monitor",
	["mobile"] = "phone",
	["pc"] = "monitor",
	["halloween"] = "pumpkin",
	["winter"] = "snowflake",
	["water"] = "droplet",
	["forest"] = "tree",
	["boss"] = "skull",
	["quest"] = "flag",
	["tasks"] = "clipboard",
	["logs"] = "file",
	["update"] = "download",
	["notification"] = "bell",
}


--// icon engine ---------------------------------------------------------------
-- Draws the vector shapes from ICONS with plain Frames (lines are rotated pills,
-- rings/rects use one UIStroke). Everything is scale based, so one icon = a handful
-- of instances and it recolors without any asset loading.
local Icon = {}
Icon.__index = Icon

function Icon:SetColor(c)
	self.Color = c
	if self._img then self._img.ImageColor3 = c return end
	for _, p in ipairs(self._p) do
		if p[2] then p[1].Color = c else p[1].BackgroundColor3 = c end
	end
end

function Icon:SetTransparency(t)
	if self._img then self._img.ImageTransparency = t return end
	for _, p in ipairs(self._p) do
		if p[2] then p[1].Transparency = t else p[1].BackgroundTransparency = t end
	end
end

function Icon:SetThemeColor(key)
	themedIcons[self] = key
	self:SetColor(Theme[key])
end

function Icon:Destroy()
	themedIcons[self] = nil
	self.Instance:Destroy()
end

local function iLine(f, p, x1, y1, x2, y2, tu, col)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	local l = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale((x1 + x2) / 48, (y1 + y2) / 48),
		Size = UDim2.fromScale((len + tu) / 24, tu / 24),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = col,
	}, f)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, l)
	p[#p + 1] = { l, false }
end

local function iFillCircle(f, p, cx, cy, r, col)
	local d = (2 * r) / 24
	local c = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx / 24, cy / 24),
		Size = UDim2.fromScale(d, d), BackgroundColor3 = col,
	}, f)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
	p[#p + 1] = { c, false }
end

local function iRing(f, p, cx, cy, r, tu, thPx, col)
	local d = math.max(0.01, (2 * r - tu)) / 24
	local c = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(cx / 24, cy / 24),
		Size = UDim2.fromScale(d, d), BackgroundTransparency = 1,
	}, f)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
	local s = new("UIStroke", { Thickness = thPx, Color = col, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, c)
	p[#p + 1] = { s, true }
end

local function iRect(f, p, x, y, w, h, rad, tu, thPx, u, col)
	local c = new("Frame", {
		Position = UDim2.fromScale((x + tu / 2) / 24, (y + tu / 2) / 24),
		Size = UDim2.fromScale(math.max(0.01, w - tu) / 24, math.max(0.01, h - tu) / 24),
		BackgroundTransparency = 1,
	}, f)
	new("UICorner", { CornerRadius = UDim.new(0, math.max(0, (rad - tu / 2) * u)) }, c)
	local s = new("UIStroke", { Thickness = thPx, Color = col, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, c)
	p[#p + 1] = { s, true }
end

local function iFillRect(f, p, x, y, w, h, rad, u, col)
	local c = new("Frame", {
		Position = UDim2.fromScale(x / 24, y / 24), Size = UDim2.fromScale(w / 24, h / 24), BackgroundColor3 = col,
	}, f)
	new("UICorner", { CornerRadius = UDim.new(0, rad * u) }, c)
	p[#p + 1] = { c, false }
end

local function makeIcon(parent, name, size, color)
	size = size or 18
	local self = setmetatable({}, Icon)
	local f = new("Frame", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) })
	self.Instance = f
	local key
	if type(color) == "string" then key = color; color = Theme[key] end
	color = color or Theme.Text
	self.Color = color

	local isImage = type(name) == "number" or (type(name) == "string" and (name:find("rbx") or name:find("^%d+$")))
	if isImage then
		local id = tostring(name)
		if not id:find("rbx") then id = "rbxassetid://" .. id end
		self._img = new("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = id, ImageColor3 = color }, f)
	else
		name = ICON_ALIASES[name] or name
		local def = ICONS[name] or ICONS.circle
		local u = size / 24
		local thPx = math.max(1, 2 * u)
		local tu = thPx / u
		local p = {}
		self._p = p
		for i = 1, #def do
			local s = def[i]
			local t = s[1]
			if t == "P" then
				for j = 2, #s - 3, 2 do iLine(f, p, s[j], s[j + 1], s[j + 2], s[j + 3], tu, color) end
			elseif t == "L" then iLine(f, p, s[2], s[3], s[4], s[5], tu, color)
			elseif t == "C" then iRing(f, p, s[2], s[3], s[4], tu, thPx, color)
			elseif t == "D" then iFillCircle(f, p, s[2], s[3], s[4], color)
			elseif t == "R" then iRect(f, p, s[2], s[3], s[4], s[5], s[6], tu, thPx, u, color)
			elseif t == "F" then iFillRect(f, p, s[2], s[3], s[4], s[5], s[6], u, color)
			end
		end
	end
	if key then themedIcons[self] = key end
	if parent then f.Parent = parent end
	return self
end

-- brand mark: gradient squircle + hex-bolt icon
local function makeLogo(parent, size)
	local f = new("Frame", { Name = "Logo", Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.new(1, 1, 1) }, parent)
	corner(f, math.floor(size * 0.28))
	accentGradient(f, 45)
	local ic = makeIcon(f, "rage", math.floor(size * 0.66), Color3.new(1, 1, 1))
	ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
	return f
end

function RageHub:CreateIcon(parent, name, size, color) return makeIcon(parent, name, size, color) end
function RageHub:CreateLogo(parent, size) return makeLogo(parent, size or 32) end
function RageHub:GetIcons()
	local out = {}
	for k in pairs(ICONS) do out[#out + 1] = k end
	table.sort(out)
	return out
end
function RageHub:HasIcon(name) return (ICONS[ICON_ALIASES[name] or name]) ~= nil end

--// theme switching ---------------------------------------------------------------
function RageHub:AddTheme(name, t)
	local base = RageHub.Themes.Rage
	local out = {}
	for k, v in pairs(base) do out[k] = (t and t[k]) or v end
	RageHub.Themes[name] = out
end

function RageHub:SetTheme(name)
	local t = RageHub.Themes[name]
	if not t then return end
	RageHub.CurrentTheme = name
	for k, v in pairs(t) do Theme[k] = v end
	for inst, map in pairs(themed) do
		for prop, key in pairs(map) do pcall(function() inst[prop] = Theme[key] end) end
	end
	for ic, key in pairs(themedIcons) do ic:SetColor(Theme[key]) end
	for g in pairs(themedGrad) do g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end
	for _, w in ipairs(RageHub.Windows) do
		if w._onTheme then w:_onTheme() end
	end
end
RageHub.CurrentTheme = "Rage"

--// gui root + notifications --------------------------------------------------
local function ensureGui()
	if RageHub.Gui and RageHub.Gui.Parent then return RageHub.Gui end
	local g = Instance.new("ScreenGui")
	g.Name = (HttpService:GenerateGUID(false):gsub("%-", "")):sub(1, 12)
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = 1000
	g.IgnoreGuiInset = true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)
	g.Parent = guiParent()
	RageHub.Gui = g
	return g
end

local NOTE_COLORS = { info = "Accent", success = "Success", warning = "Warning", error = "Danger" }
local NOTE_ICONS = { info = "info", success = "circle-check", warning = "warning", error = "circle-x" }

local function ensureNotes()
	local g = ensureGui()
	if RageHub._notes and RageHub._notes.Parent then return RageHub._notes end
	local holder = new("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.new(0, 280, 1, -28), BackgroundTransparency = 1,
	}, g)
	list(holder, 8, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
	RageHub._notes = holder
	RageHub._noteList = {}
	return holder
end

function RageHub:Notify(cfg)
	if not RageHub.Notifications then return end
	cfg = type(cfg) == "table" and cfg or { Content = tostring(cfg) }
	local holder = ensureNotes()
	local kind = cfg.Type or "info"
	local colorKey = NOTE_COLORS[kind] or "Accent"
	local dur = cfg.Duration or 4

	local active = RageHub._noteList
	if #active >= 5 then
		local old = table.remove(active, 1)
		if old and old.Parent then old:Destroy() end
	end

	local slot = new("Frame", { Name = "Note", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, holder)
	active[#active + 1] = slot
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 40, 0, 0),
		BackgroundColor3 = "@Card",
	}, slot)
	corner(card, 10)
	stroke(card, "Stroke", 1, 0.2)
	pad(card, 12, 10, 12, 12)
	local ic = makeIcon(card, cfg.Icon or NOTE_ICONS[kind], 18, colorKey)
	ic.Instance.Position = UDim2.fromOffset(0, 1)
	local body = new("Frame", { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, card)
	list(body, 2)
	new("TextLabel", {
		Text = cfg.Title or "Rage Hub", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = "@Text",
		Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
	}, body)
	if cfg.Content and cfg.Content ~= "" then
		new("TextLabel", {
			Text = cfg.Content, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = "@SubText", TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
		}, body)
	end
	local bar = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 8), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = "@Stroke" }, card)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@" .. colorKey }, bar)

	tw(card, 0.25, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	if not RageHub.ReduceMotion then tw(fill, dur, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear) end
	task.delay(dur, function()
		if not slot.Parent then return end
		tw(card, 0.2, { Position = UDim2.new(1, 40, 0, 0) })
		task.wait(RageHub.ReduceMotion and 0 or 0.22)
		for i, v in ipairs(active) do if v == slot then table.remove(active, i) break end end
		if slot.Parent then slot:Destroy() end
	end)
	return slot
end


--// window / tab / section ----------------------------------------------------
local Window, Tab, Section = {}, {}, {}
Window.__index = Window
Tab.__index = Tab
Section.__index = Section

local SB_OPEN, SB_SHUT = 176, 62
local ELEMENTS = { "CreateToggle", "CreateSlider", "CreateDropdown", "CreateButton", "CreateInput",
	"CreateKeybind", "CreateColorPicker", "CreateLabel", "CreateParagraph", "CreateDivider" }

function Window:_a(inst, factor)
	self._alpha[#self._alpha + 1] = { inst, factor or 1 }
	if self.Alpha > 0 then inst.BackgroundTransparency = self.Alpha * (factor or 1) end
end

function Window:SetTransparency(t)
	self.Alpha = clamp(t or 0, 0, 0.8)
	local live = {}
	for _, e in ipairs(self._alpha) do
		if e[1].Parent then
			e[1].BackgroundTransparency = self.Alpha * e[2]
			live[#live + 1] = e
		end
	end
	self._alpha = live
end

function Window:_applyScale()
	local vp = RageHub.Gui.AbsoluteSize
	local w, h = self.Main.Size.X.Offset, self.Main.Size.Y.Offset
	local auto = clamp(math.min(1, (vp.X - 20) / w, (vp.Y - 20) / h), 0.5, 1)
	self._target = auto * self.UserScale
	self.UIScale.Scale = self._target
end

function Window:SetScale(s)
	self.UserScale = clamp(s or 1, 0.6, 1.5)
	self:_applyScale()
end

function Window:SetToggleKey(k) self.ToggleKey = k end

function Window:SetTitle(text, sub)
	self.Name = text or self.Name
	self._tTitle.Text = self.Name
	if sub then self._tSub.Text = sub end
end

function Window:Notify(cfg) return RageHub:Notify(cfg) end

function Window:SetVisible(v)
	if v == self.Visible then return end
	self.Visible = v
	self:_hidePopup()
	if v then
		self.Main.Visible = true
		if not RageHub.ReduceMotion then
			self.UIScale.Scale = self._target * 0.94
			tw(self.UIScale, 0.18, { Scale = self._target }, Enum.EasingStyle.Back)
		end
	else
		self.Main.Visible = false
	end
end

function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:SetCollapsed(c, instant)
	self.Collapsed = c
	local w = c and SB_SHUT or SB_OPEN
	local t = instant and 0 or 0.2
	tw(self.Sidebar, t, { Size = UDim2.new(0, w, 1, 0) })
	tw(self.Content, t, { Position = UDim2.new(0, w, 0, 8), Size = UDim2.new(1, -w - 8, 1, -16) })
	for _, o in ipairs(self._sbText) do o.Visible = not c end
	self._collapseIcon.Instance.Rotation = c and 180 or 0
	if self.Active then
		task.delay(t + 0.02, function() if self.Active then self.Active:_layout() end end)
	end
end

function Window:_place(anchor, w, h, alignRight)
	local s = self.UIScale.Scale
	local mp, ms = self.Main.AbsolutePosition, self.Main.AbsoluteSize
	local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
	local x = (ap.X - mp.X) / s
	local y = (ap.Y + as.Y - mp.Y) / s + 4
	if alignRight then x = x + as.X / s - w end
	local mw, mh = ms.X / s, ms.Y / s
	x = clamp(x, 8, math.max(8, mw - w - 8))
	if y + h > mh - 8 then
		y = (ap.Y - mp.Y) / s - h - 4
		if y < 8 then y = math.max(8, mh - h - 8) end
	end
	return UDim2.fromOffset(x, y)
end

function Window:_showPopup(pop, anchor, w, h, alignRight, onClose)
	self:_hidePopup()
	local ov = self.Overlay
	ov.Visible = true
	local back = new("TextButton", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), ZIndex = 1 }, ov)
	back.Activated:Connect(function() self:_hidePopup() end)
	pop.ZIndex = 2
	pop.Size = UDim2.fromOffset(w, h)
	pop.Position = self:_place(anchor, w, h, alignRight)
	pop.Parent = ov
	self._pop = { pop = pop, back = back, onClose = onClose }
end

function Window:_hidePopup()
	local p = self._pop
	if not p then return end
	self._pop = nil
	p.back:Destroy()
	p.pop.Parent = nil
	self.Overlay.Visible = false
	if p.onClose then p.onClose() end
end

--// search ----------------------------------------------------------------------
function Window:_reg(el, cfg, sec)
	if not cfg.Name then return end
	self.Search[#self.Search + 1] = {
		name = cfg.Name, key = (cfg.Name .. " " .. (cfg.Description or "")):lower(),
		row = el.Row, tab = sec.Tab, sec = sec,
	}
end

function Window:_doSearch(q)
	q = (q or ""):lower():match("^%s*(.-)%s*$")
	local sp = self.SearchPage
	if q == "" then
		sp.Visible = false
		if self.Active then self.Active.Page.Visible = true; self.Title.Text = self.Active.Name end
		return
	end
	if self.Active then self.Active.Page.Visible = false end
	self.Title.Text = "Search"
	sp.Visible = true
	for _, c in ipairs(sp:GetChildren()) do if c:IsA("GuiButton") or c:IsA("TextLabel") then c:Destroy() end end
	local n = 0
	for _, e in ipairs(self.Search) do
		if e.key:find(q, 1, true) then
			n = n + 1
			if n > 40 then break end
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = "@Card", BackgroundTransparency = 0, LayoutOrder = n }, sp)
			corner(b, 8)
			new("TextLabel", { Text = e.name, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 16),
				TextColor3 = "@Text", TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, b)
			new("TextLabel", { Text = e.tab.Name .. "  /  " .. (e.sec.Name or "General"), Font = Enum.Font.Gotham, TextSize = 11,
				Position = UDim2.fromOffset(12, 23), Size = UDim2.new(1, -24, 0, 13), TextColor3 = "@Muted",
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, b)
			b.Activated:Connect(function() self:_goto(e) end)
		end
	end
	if n == 0 then
		new("TextLabel", { Text = "No results for \"" .. q .. "\"", Size = UDim2.new(1, 0, 0, 40), TextColor3 = "@Muted" }, sp)
	end
end

function Window:_goto(e)
	self.SearchBox.Text = ""
	self.SearchPage.Visible = false
	self:SelectTab(e.tab)
	if e.sec.Collapsed then e.sec:SetCollapsed(false) end
	task.defer(function()
		task.wait(0.05)
		local page = e.tab.Page
		local s = self.UIScale.Scale
		local y = (e.row.AbsolutePosition.Y - page.AbsolutePosition.Y) / s + page.CanvasPosition.Y - 8
		page.CanvasPosition = Vector2.new(0, math.max(0, y))
		if e.row:IsA("GuiObject") then
			tw(e.row, 0.12, { BackgroundTransparency = 0.35 })
			task.delay(0.7, function() if e.row.Parent then tw(e.row, 0.3, { BackgroundTransparency = 1 }) end end)
		end
	end)
end

--// tabs --------------------------------------------------------------------------
function Window:CreateTabLabel(text)
	self._order = self._order + 1
	local l = new("TextLabel", {
		Text = string.upper(text), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = "@Muted",
		Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = self._order,
	}, self.TabList)
	pad(l, 12, 6, 0, 0)
	l.Visible = not self.Collapsed
	self._sbText[#self._sbText + 1] = l
	return l
end

function Tab:_cols()
	local w = self.Window.Main.Size.X.Offset - (self.Window.Collapsed and SB_SHUT or SB_OPEN) - 40
	return w >= 550 and 2 or 1
end

function Tab:_layout()
	local n = self:_cols()
	self.NCols = n
	self.Col2.Visible = n == 2
	self.Col1.Size = n == 2 and UDim2.new(0.5, -5, 0, 0) or UDim2.new(1, 0, 0, 0)
	local h = { 0, 0 }
	for i, s in ipairs(self.Sections) do
		local c = 1
		if n == 2 then
			if s.Side == "Right" then c = 2
			elseif s.Side == "Left" then c = 1
			else c = (h[1] <= h[2]) and 1 or 2 end
		end
		s.Frame.LayoutOrder = i
		s.Frame.Parent = (c == 1) and self.Col1 or self.Col2
		h[c] = h[c] + s.Est
	end
end

function Tab:_queueLayout()
	if self._lq then return end
	self._lq = true
	task.defer(function() self._lq = false; self:_layout() end)
end

function Tab:_set(on)
	tw(self.Button, 0.15, { BackgroundTransparency = on and 0.85 or 1 })
	self.IconObj:SetThemeColor(on and "Accent" or "SubText")
	setKey(self.Label, "TextColor3", on and "Text" or "SubText")
	self.Bar.BackgroundTransparency = on and 0 or 1
	self.Page.Visible = on
	self.IsActive = on
end

function Window:SelectTab(t)
	if type(t) == "string" then
		for _, x in ipairs(self.Tabs) do if x.Name == t then t = x break end end
	end
	if type(t) ~= "table" then return end
	self:_hidePopup()
	self.SearchPage.Visible = false
	if self.Active and self.Active ~= t then self.Active:_set(false) end
	self.Active = t
	t:_set(true)
	self.Title.Text = t.Name
	if t.NCols ~= t:_cols() then t:_layout() end
end

function Window:CreateTab(name, icon, opts)
	opts = opts or {}
	self._order = self._order + 1
	local tab = setmetatable({ Window = self, Name = name, Sections = {}, IconName = icon }, Tab)

	local btn = new("TextButton", {
		Name = name, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = "@Accent", BackgroundTransparency = 1,
		LayoutOrder = self._order,
	}, self.TabList)
	corner(btn, 9)
	tab.Button = btn
	tab.IconObj = makeIcon(btn, icon or "dot", 16, "SubText")
	tab.IconObj.Instance.Position = UDim2.fromOffset(12, 10)
	tab.Label = new("TextLabel", {
		Text = name, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0), TextColor3 = "@SubText",
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, btn)
	tab.Label.Visible = not self.Collapsed
	self._sbText[#self._sbText + 1] = tab.Label
	tab.Bar = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -8, 0.5, 0), Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = "@Accent", BackgroundTransparency = 1,
	}, btn)
	corner(tab.Bar, 2)
	btn.MouseEnter:Connect(function() if not tab.IsActive then tw(btn, 0.12, { BackgroundTransparency = 0.93 }) end end)
	btn.MouseLeave:Connect(function() if not tab.IsActive then tw(btn, 0.12, { BackgroundTransparency = 1 }) end end)
	btn.Activated:Connect(function() self:SelectTab(tab) end)

	local page = new("ScrollingFrame", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = "@Stroke", CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never, VerticalScrollBarInset = Enum.ScrollBarInset.None,
	}, self.Pages)
	tab.Page = page
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, page)
	pad(holder, 0, 0, 8, 12)
	list(holder, 10, Enum.FillDirection.Horizontal)
	tab.Col1 = new("Frame", { Name = "Col1", Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, holder)
	tab.Col2 = new("Frame", { Name = "Col2", Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, holder)
	list(tab.Col1, 10)
	list(tab.Col2, 10)

	self.Tabs[#self.Tabs + 1] = tab
	if not self.Active then self:SelectTab(tab) end
	return tab
end

function Tab:CreateSection(name, icon, opts)
	if type(icon) == "table" then opts = icon; icon = nil end
	opts = opts or {}
	local win = self.Window
	local sec = setmetatable({ Tab = self, Name = name, Est = 44, Side = opts.Side, Collapsed = false }, Section)
	local frame = new("Frame", {
		Name = name or "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "@Card", LayoutOrder = #self.Sections + 1,
	}, self.Col1)
	corner(frame, 10)
	stroke(frame, "Stroke", 1, 0.45)
	win:_a(frame, 0.8)
	pad(frame, 6, 6, 6, 6)
	list(frame, 2)
	sec.Frame = frame

	if name and name ~= "" then
		local head = new("TextButton", { Name = "Header", Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 1 }, frame)
		local x = 6
		if icon then
			local ic = makeIcon(head, icon, 14, "Accent")
			ic.Instance.Position = UDim2.fromOffset(6, 7)
			x = 26
		end
		new("TextLabel", {
			Text = string.upper(name), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = "@SubText",
			Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x - 26, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, head)
		local chev = makeIcon(head, "chevron-down", 12, "Muted")
		chev.Instance.AnchorPoint = Vector2.new(1, 0.5)
		chev.Instance.Position = UDim2.new(1, -8, 0.5, 0)
		sec.Chevron = chev.Instance
		head.Activated:Connect(function() sec:SetCollapsed(not sec.Collapsed) end)
	end
	sec.Body = new("Frame", { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, frame)
	list(sec.Body, 2)

	self.Sections[#self.Sections + 1] = sec
	self:_queueLayout()
	return sec
end

function Section:SetCollapsed(c)
	self.Collapsed = c
	self.Body.Visible = not c
	if self.Chevron then tw(self.Chevron, 0.15, { Rotation = c and -90 or 0 }) end
end

function Tab:_default()
	if not self._def then self._def = self:CreateSection(nil) end
	return self._def
end

for _, n in ipairs(ELEMENTS) do
	Tab[n] = function(self, cfg)
		local s = self:_default()
		return s[n](s, cfg)
	end
end

--// window ------------------------------------------------------------------------
function RageHub:CreateWindow(cfg)
	cfg = cfg or {}
	local Gui = ensureGui()
	local self = setmetatable({}, Window)
	self.Name = cfg.Name or "Rage Hub"
	self.Subtitle = cfg.Subtitle or ""
	self.Version = cfg.Version or ("v" .. RageHub.Version)
	self.Tabs, self.Elements, self.Search, self.Keybinds = {}, {}, {}, {}
	self.Maid = Maid.new()
	self.ConfigFolder = cfg.ConfigFolder or "RageHub"
	self.ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
	self.UserScale = 1
	self.Alpha = 0
	self._alpha, self._sbText, self._onDestroy = {}, {}, {}
	self._order = 0
	self.Visible = true
	self.Collapsed = IsMobile
	self.AutoExecuteScript = cfg.AutoExecuteScript
	if cfg.Theme and RageHub.Themes[cfg.Theme] then RageHub:SetTheme(cfg.Theme) end

	local size = cfg.Size or Vector2.new(660, 400)
	local main = new("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = "@Panel",
	}, Gui)
	self.Main = main
	self.UIScale = new("UIScale", {}, main)
	corner(main, 14)
	stroke(main, "Stroke", 1, 0.2)
	self:_a(main, 1)

	--// sidebar
	local sidebar = new("Frame", { Name = "Sidebar", BackgroundTransparency = 1, Size = UDim2.new(0, SB_OPEN, 1, 0) }, main)
	self.Sidebar = sidebar
	local brand = new("TextButton", { Name = "Brand", Size = UDim2.new(1, 0, 0, 58) }, sidebar)
	local logo = makeLogo(brand, 30)
	logo.Position = UDim2.fromOffset(15, 14)
	self._tTitle = new("TextLabel", {
		Text = self.Name, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = "@Text", Position = UDim2.fromOffset(54, 12),
		Size = UDim2.new(1, -62, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, brand)
	self._tSub = new("TextLabel", {
		Text = self.Subtitle ~= "" and self.Subtitle or self.Version, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText",
		Position = UDim2.fromOffset(54, 30), Size = UDim2.new(1, -62, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, brand)
	self._sbText[#self._sbText + 1] = self._tTitle
	self._sbText[#self._sbText + 1] = self._tSub

	local sb = new("Frame", { Name = "Search", Position = UDim2.fromOffset(10, 60), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = "@Elevated" }, sidebar)
	corner(sb, 8)
	local sIc = makeIcon(sb, "search", 14, "Muted")
	sIc.Instance.Position = UDim2.fromOffset(9, 8)
	self.SearchBox = new("TextBox", {
		Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -36, 1, 0), PlaceholderText = "Search", PlaceholderColor3 = "@Muted",
		TextColor3 = "@Text", TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	}, sb)
	self._sbText[#self._sbText + 1] = sb

	self.TabList = new("ScrollingFrame", {
		Name = "Tabs", Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 1, -154), BackgroundTransparency = 1,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, sidebar)
	pad(self.TabList, 10, 0, 10, 0)
	list(self.TabList, 2)

	local foot = new("Frame", { Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1 }, sidebar)
	local av = new("ImageLabel", {
		Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0,
		Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(LocalPlayer.UserId),
	}, foot)
	corner(av, 15)
	local fn = new("TextLabel", {
		Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = "@Text", Position = UDim2.fromOffset(54, 10),
		Size = UDim2.new(1, -62, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, foot)
	local fu = new("TextLabel", {
		Text = "@" .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = "@Muted", Position = UDim2.fromOffset(54, 27),
		Size = UDim2.new(1, -62, 0, 13), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, foot)
	self._sbText[#self._sbText + 1] = fn
	self._sbText[#self._sbText + 1] = fu

	--// content
	local content = new("Frame", {
		Name = "Content", Position = UDim2.new(0, SB_OPEN, 0, 8), Size = UDim2.new(1, -SB_OPEN - 8, 1, -16), BackgroundColor3 = "@Bg",
	}, main)
	corner(content, 10)
	self:_a(content, 1)
	self.Content = content

	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, content)
	local drag = new("TextButton", { Name = "Drag", Size = UDim2.fromScale(1, 1) }, header)
	self.Title = new("TextLabel", {
		Text = "", Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = "@Text", Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	new("Frame", { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "@Stroke", BackgroundTransparency = 0.5 }, header)

	local function hbtn(iconName, x, cb)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -x, 0, 23),
			BackgroundColor3 = "@Elevated", BackgroundTransparency = 1,
		}, header)
		corner(b, 8)
		local ic = makeIcon(b, iconName, 16, "SubText")
		ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
		b.MouseEnter:Connect(function() tw(b, 0.1, { BackgroundTransparency = 0.3 }) end)
		b.MouseLeave:Connect(function() tw(b, 0.1, { BackgroundTransparency = 1 }) end)
		b.Activated:Connect(cb)
		return ic
	end
	hbtn("x", 10, function() self:SetVisible(false) end)
	self._collapseIcon = hbtn("chevron-left", 46, function() self:SetCollapsed(not self.Collapsed) end)
	self._collapseIcon.Instance.Rotation = 0

	self.Pages = new("Frame", { Name = "Pages", Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 1, -47), BackgroundTransparency = 1, ClipsDescendants = true }, content)
	pad(self.Pages, 10, 10, 4, 0)
	self.SearchPage = new("ScrollingFrame", {
		Name = "SearchResults", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 3,
		ScrollBarImageColor3 = "@Stroke", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, self.Pages)
	pad(self.SearchPage, 0, 0, 8, 10)
	list(self.SearchPage, 6)

	self.Overlay = new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, main)

	--// dragging + resizing
	local function draggable(handle)
		handle.InputBegan:Connect(function(i)
			if not isPointer(i) then return end
			local start, sp = i.Position, main.Position
			trackInput(i, function(m)
				local d = m.Position - start
				main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end)
		end)
	end
	draggable(drag)
	draggable(brand)

	local rz = new("TextButton", { Name = "Resize", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(24, 24), ZIndex = 5 }, main)
	local rzi = makeIcon(rz, "resize", 12, "Muted")
	rzi.Instance.Position = UDim2.fromOffset(8, 8)
	rz.InputBegan:Connect(function(i)
		if not isPointer(i) then return end
		local start = i.Position
		local w0, h0 = main.Size.X.Offset, main.Size.Y.Offset
		self:_hidePopup()
		trackInput(i, function(m)
			local s = self.UIScale.Scale
			main.Size = UDim2.fromOffset(clamp(w0 + (m.Position.X - start.X) / s, 470, 1100), clamp(h0 + (m.Position.Y - start.Y) / s, 290, 800))
		end, function()
			if self.Active then self.Active:_layout() end
		end)
	end)

	--// scale
	self:_applyScale()
	self.Maid:Add(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_applyScale() end))
	self:SetCollapsed(self.Collapsed, true)

	--// search box
	self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self._sq = (self._sq or 0) + 1
		local id, q = self._sq, self.SearchBox.Text
		task.delay(0.15, function() if id == self._sq then self:_doSearch(q) end end)
	end)

	--// floating toggle button (always handy on mobile)
	local showFloat = cfg.FloatingButton
	if showFloat == nil then showFloat = IsMobile end
	local fb = new("TextButton", {
		Name = "RageFloat", Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 14, 0.5, -23),
		BackgroundColor3 = Color3.new(1, 1, 1), Visible = showFloat,
	}, Gui)
	corner(fb, 14)
	accentGradient(fb, 45)
	new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.75, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, fb)
	local fbi = makeIcon(fb, "rage", 28, Color3.new(1, 1, 1))
	fbi.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
	fbi.Instance.Position = UDim2.fromScale(0.5, 0.5)
	local moved = false
	fb.InputBegan:Connect(function(i)
		if not isPointer(i) then return end
		moved = false
		local start, sp = i.Position, fb.Position
		trackInput(i, function(m)
			local d = m.Position - start
			if d.Magnitude > 6 then moved = true end
			if moved then fb.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
		end)
	end)
	fb.Activated:Connect(function() if not moved then self:Toggle() end end)
	self.Float = fb
	function self:SetFloatingButton(v) fb.Visible = v and true or false end

	--// keyboard: toggle key, keybind elements, key capture
	self.Maid:Add(UIS.InputBegan:Connect(function(i, gp)
		if self._binding then
			local el = self._binding
			if i.UserInputType == Enum.UserInputType.Keyboard then
				self._binding = nil
				if i.KeyCode == Enum.KeyCode.Escape then el:_stopListen()
				elseif i.KeyCode == Enum.KeyCode.Backspace then el:Set(nil)
				else el:Set(i.KeyCode) end
			end
			return
		end
		if gp or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if i.KeyCode == self.ToggleKey then self:Toggle() return end
		for _, kb in ipairs(self.Keybinds) do
			if kb.Value and i.KeyCode == kb.Value then fire(kb.Callback, kb.Value) end
		end
	end))

	function self:Destroy()
		self.Maid:Clean()
		for _, f in ipairs(self._onDestroy) do pcall(f) end
		pcall(function() fb:Destroy() end)
		pcall(function() main:Destroy() end)
		for i, w in ipairs(RageHub.Windows) do if w == self then table.remove(RageHub.Windows, i) break end end
	end

	RageHub.Windows[#RageHub.Windows + 1] = self
	if cfg.StartHidden then self.Visible = true; self:SetVisible(false) end
	return self
end

function RageHub:Unload()
	for i = #RageHub.Windows, 1, -1 do pcall(function() RageHub.Windows[i]:Destroy() end) end
	RootMaid:Clean()
	if RageHub.Gui then pcall(function() RageHub.Gui:Destroy() end) end
	RageHub.Gui = nil
	RageHub.Flags, RageHub.Options = {}, {}
	if genv.RageHub == RageHub then genv.RageHub = nil end
end


--// elements ------------------------------------------------------------------
local ROW_H = 38

local function makeRow(sec, cfg, o)
	o = o or {}
	local row = new(o.click and "TextButton" or "Frame", {
		Name = cfg.Name or "Row", Size = UDim2.new(1, 0, 0, ROW_H), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "@Elevated", BackgroundTransparency = 1, LayoutOrder = o.order or 0,
	}, sec.Body)
	corner(row, 8)
	pad(row, 10, 0, 10, 0)
	local inner = new("Frame", { Name = "Inner", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, row)
	list(inner, 0)
	if o.bottom then pad(inner, 0, 0, 0, o.bottom) end
	local tf = new("Frame", {
		Name = "Text", Size = UDim2.new(1, -((o.right or 0) + 8), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = 1,
	}, inner)
	pad(tf, 0, o.padTop or 12, 0, o.padBottom or 12)
	list(tf, 2)
	local title = new("TextLabel", {
		Name = "Title", Text = cfg.Name or "", TextColor3 = "@Text", TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
	}, tf)
	local desc
	if cfg.Description and cfg.Description ~= "" then
		desc = new("TextLabel", {
			Name = "Desc", Text = cfg.Description, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText",
			TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
		}, tf)
	end
	row.MouseEnter:Connect(function() tw(row, 0.12, { BackgroundTransparency = 0.65 }) end)
	row.MouseLeave:Connect(function() tw(row, 0.12, { BackgroundTransparency = 1 }) end)
	return { Row = row, Inner = inner, Title = title, Desc = desc, est = o.est or 40 }
end

local function register(el, cfg, sec, R)
	el.Row, el.Section, el.Flag, el.Name = R.Row, sec, cfg.Flag, cfg.Name
	el.Callback = cfg.Callback
	el.Save = cfg.Save
	function el:SetName(t) R.Title.Text = t end
	function el:SetDescription(t)
		if R.Desc then R.Desc.Text = t end
	end
	function el:SetVisible(v) R.Row.Visible = v and true or false end
	function el:Destroy()
		if self.Flag then RageHub.Options[self.Flag] = nil; RageHub.Flags[self.Flag] = nil end
		R.Row:Destroy()
	end
	if cfg.Flag then
		RageHub.Options[cfg.Flag] = el
		RageHub.Flags[cfg.Flag] = el.Value
	end
	local win = sec.Tab.Window
	win.Elements[#win.Elements + 1] = el
	win:_reg(el, cfg, sec)
	sec.Est = sec.Est + R.est
	sec.Tab:_queueLayout()
end

local function changed(el, silent)
	if el.Flag then RageHub.Flags[el.Flag] = el.Value end
	if not silent then fire(el.Callback, el.Value) end
end

local function initFire(el, cfg)
	if cfg.CallOnCreate ~= false and el.Callback then
		task.defer(function() fire(el.Callback, el.Value) end)
	end
end

local function ctlPos() return UDim2.new(1, 0, 0, 19) end

--// toggle
function Section:CreateToggle(cfg)
	cfg = cfg or {}
	local R = makeRow(self, cfg, { click = true, right = 44 })
	local el = { Type = "Toggle", Value = cfg.Default == true }
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = "@Stroke" }, R.Row)
	corner(track, 10)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1) }, track)
	corner(knob, 7)
	local function paint(t)
		local on = el.Value
		setKey(track, "BackgroundColor3", on and "Accent" or "Stroke", t)
		tw(knob, t, { Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
	end
	function el:Set(v, silent)
		self.Value = v and true or false
		paint(0.15)
		changed(self, silent)
	end
	R.Row.Activated:Connect(function() el:Set(not el.Value) end)
	paint(0)
	register(el, cfg, self, R)
	initFire(el, cfg)
	return el
end

--// slider
function Section:CreateSlider(cfg)
	cfg = cfg or {}
	local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
	local suffix = cfg.Suffix or ""
	local R = makeRow(self, cfg, { right = 64, padBottom = 2, bottom = 6, est = 56 })
	local el = { Type = "Slider", Min = min, Max = max }
	local function snap(v) return tonumber(fmtNum(clamp(round(v, inc), min, max), inc)) end
	el.Value = snap(cfg.Default or min)

	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(58, 22), BackgroundColor3 = "@Elevated",
		BackgroundTransparency = 0, TextColor3 = "@Text", TextSize = 12, ClearTextOnFocus = false, Text = "",
	}, R.Row)
	corner(box, 6)
	local hit = new("TextButton", { Name = "Hit", Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 2 }, R.Inner)
	local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = "@Stroke" }, hit)
	corner(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, track)
	corner(fill, 3)
	accentGradient(fill, 0)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 }, track)
	corner(knob, 7)

	local function render()
		local rel = max == min and 0 or clamp((el.Value - min) / (max - min), 0, 1)
		fill.Size = UDim2.fromScale(rel, 1)
		knob.Position = UDim2.fromScale(rel, 0.5)
		box.Text = fmtNum(el.Value, inc) .. suffix
	end
	function el:Set(v, silent)
		self.Value = snap(tonumber(v) or self.Value)
		render()
		changed(self, silent)
	end
	local function update(x)
		local ax, aw = track.AbsolutePosition.X, math.max(1, track.AbsoluteSize.X)
		local v = snap(min + (max - min) * clamp((x - ax) / aw, 0, 1))
		if v ~= el.Value then
			el.Value = v
			render()
			changed(el)
		end
	end
	hit.InputBegan:Connect(function(i)
		if not isPointer(i) then return end
		local page = self.Tab.Page
		page.ScrollingEnabled = false
		update(i.Position.X)
		trackInput(i, function(m) update(m.Position.X) end, function() page.ScrollingEnabled = true end)
	end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text:match("-?%d+%.?%d*"))
		if n then el:Set(n) else render() end
	end)
	render()
	register(el, cfg, self, R)
	initFire(el, cfg)
	return el
end

--// dropdown
function Section:CreateDropdown(cfg)
	cfg = cfg or {}
	local win = self.Tab.Window
	local R = makeRow(self, cfg, { right = 126 })
	local multi = cfg.Multi == true
	local el = { Type = "Dropdown", Options = cfg.Options or {}, Multi = multi }
	if multi then
		el.Value = {}
		for _, v in ipairs(cfg.Default or {}) do el.Value[#el.Value + 1] = v end
	else
		el.Value = cfg.Default
	end

	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(120, 26), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0 }, R.Row)
	corner(btn, 7)
	stroke(btn, "Stroke", 1, 0.5)
	local txt = new("TextLabel", {
		Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -28, 1, 0), TextSize = 12, TextColor3 = "@Text",
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, btn)
	local chev = makeIcon(btn, "chevron-down", 12, "Muted")
	chev.Instance.AnchorPoint = Vector2.new(1, 0.5)
	chev.Instance.Position = UDim2.new(1, -7, 0.5, 0)

	local function isSel(opt)
		if multi then return table.find(el.Value, opt) ~= nil end
		return el.Value == opt
	end
	local function display()
		if multi then
			local n = #el.Value
			if n == 0 then txt.Text = cfg.Placeholder or "None"
			elseif n <= 2 then txt.Text = table.concat(el.Value, ", ")
			else txt.Text = el.Value[1] .. ", " .. el.Value[2] .. " +" .. (n - 2) end
		else
			txt.Text = el.Value ~= nil and tostring(el.Value) or (cfg.Placeholder or "Select")
		end
	end

	local pop, scroll, items, searchBox
	local searchable = cfg.Search == true or #el.Options > 8
	local function paintItems()
		for _, it in ipairs(items or {}) do
			local s = isSel(it.opt)
			it.btn.BackgroundTransparency = s and 0.82 or 1
			setKey(it.lbl, "TextColor3", s and "Accent" or "Text")
		end
	end
	local function choose(opt)
		if multi then
			local idx = table.find(el.Value, opt)
			if idx then table.remove(el.Value, idx) else el.Value[#el.Value + 1] = opt end
			paintItems(); display(); changed(el)
		else
			el.Value = opt
			paintItems(); display(); changed(el)
			win:_hidePopup()
		end
	end
	local function filter()
		local q = searchBox and searchBox.Text:lower() or ""
		for _, it in ipairs(items or {}) do
			it.btn.Visible = q == "" or tostring(it.opt):lower():find(q, 1, true) ~= nil
		end
	end
	local function refreshItems()
		for _, it in ipairs(items or {}) do it.btn:Destroy() end
		items = {}
		for i, opt in ipairs(el.Options) do
			local b = new("TextButton", { Name = tostring(opt), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = "@Accent", BackgroundTransparency = 1, LayoutOrder = i }, scroll)
			corner(b, 6)
			local l = new("TextLabel", {
				Text = tostring(opt), Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -16, 1, 0), TextSize = 12, TextColor3 = "@Text",
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, b)
			b.Activated:Connect(function() choose(opt) end)
			items[#items + 1] = { btn = b, lbl = l, opt = opt }
		end
		paintItems()
		filter()
	end
	local function build()
		pop = new("Frame", { BackgroundColor3 = "@Card", ClipsDescendants = true })
		corner(pop, 10)
		stroke(pop, "Stroke", 1, 0)
		pad(pop, 6, 6, 6, 6)
		local top = 0
		if searchable then
			searchBox = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0, PlaceholderText = "Search...",
				PlaceholderColor3 = "@Muted", TextColor3 = "@Text", TextSize = 12, ClearTextOnFocus = false, Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
			}, pop)
			corner(searchBox, 6)
			pad(searchBox, 8, 0, 8, 0)
			searchBox:GetPropertyChangedSignal("Text"):Connect(filter)
			top = 34
		end
		scroll = new("ScrollingFrame", {
			Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), BackgroundTransparency = 1, ScrollBarThickness = 3,
			ScrollBarImageColor3 = "@Stroke", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, pop)
		list(scroll, 2)
		refreshItems()
	end
	btn.Activated:Connect(function()
		if not pop then build() end
		local h = math.min(#el.Options * 30 + 12 + (searchable and 34 or 0), 214)
		local w = math.max(150, btn.AbsoluteSize.X / win.UIScale.Scale)
		win:_showPopup(pop, btn, w, math.max(h, 50), true)
	end)

	function el:Set(v, silent)
		if multi then
			self.Value = {}
			if type(v) == "table" then for _, x in ipairs(v) do self.Value[#self.Value + 1] = x end end
		else
			self.Value = v
		end
		display(); paintItems()
		changed(self, silent)
	end
	function el:Refresh(options, keep)
		self.Options = options or {}
		if not keep then self.Value = multi and {} or nil end
		display()
		if pop then refreshItems() end
		changed(self, true)
	end
	display()
	register(el, cfg, self, R)
	if cfg.Default ~= nil then initFire(el, cfg) end
	return el
end

--// button
function Section:CreateButton(cfg)
	cfg = cfg or {}
	local label = cfg.ButtonText
	local iconName = cfg.Icon or (label == nil and "play" or nil)
	local R = makeRow(self, cfg, { click = true, right = label and (#label * 7 + 44) or 40 })
	local el = { Type = "Button" }
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = "@Elevated", BackgroundTransparency = 0,
	}, R.Row)
	corner(pill, 7)
	stroke(pill, "Stroke", 1, 0.5)
	pad(pill, 9, 0, 9, 0)
	list(pill, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local colorKey = cfg.Danger and "Danger" or "Accent"
	if iconName then
		local ic = makeIcon(pill, iconName, 14, colorKey)
		ic.Instance.LayoutOrder = 1
	end
	if label then
		new("TextLabel", { Text = label, TextSize = 12, TextColor3 = "@" .. colorKey, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 }, pill)
	end
	function el:Fire() fire(cfg.Callback) end
	R.Row.Activated:Connect(function()
		tw(pill, 0.08, { BackgroundTransparency = 0.5 })
		task.delay(0.12, function() if pill.Parent then tw(pill, 0.15, { BackgroundTransparency = 0 }) end end)
		fire(cfg.Callback)
	end)
	register(el, cfg, self, R)
	return el
end

--// input
function Section:CreateInput(cfg)
	cfg = cfg or {}
	local R = makeRow(self, cfg, { right = 134 })
	local el = { Type = "Input", Value = cfg.Default or "" }
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(128, 26), BackgroundColor3 = "@Elevated",
		BackgroundTransparency = 0, PlaceholderText = cfg.Placeholder or "Type here...", PlaceholderColor3 = "@Muted",
		TextColor3 = "@Text", TextSize = 12, ClearTextOnFocus = false, Text = tostring(el.Value), TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, R.Row)
	corner(box, 7)
	stroke(box, "Stroke", 1, 0.5)
	pad(box, 8, 0, 8, 0)
	function el:Set(v, silent)
		self.Value = v
		box.Text = tostring(v)
		changed(self, silent)
	end
	box.FocusLost:Connect(function()
		local t = box.Text
		if cfg.Numeric then
			local n = tonumber(t)
			if not n then box.Text = tostring(el.Value) return end
			t = n
		end
		el:Set(t)
	end)
	register(el, cfg, self, R)
	if cfg.Default ~= nil then initFire(el, cfg) end
	return el
end

--// keybind
local KEY_SHORT = { LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift", LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Back", Escape = "Esc" }

function Section:CreateKeybind(cfg)
	cfg = cfg or {}
	local win = self.Tab.Window
	local R = makeRow(self, cfg, { right = 90 })
	local el = { Type = "Keybind", Value = cfg.Default }
	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(84, 26), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0 }, R.Row)
	corner(btn, 7)
	stroke(btn, "Stroke", 1, 0.5)
	local lbl = new("TextLabel", { Size = UDim2.fromScale(1, 1), TextSize = 12, TextColor3 = "@Text" }, btn)
	local function show()
		lbl.Text = el.Value and (KEY_SHORT[el.Value.Name] or el.Value.Name) or "None"
		setKey(lbl, "TextColor3", "Text")
	end
	function el:_stopListen()
		if win._binding == self then win._binding = nil end
		show()
	end
	function el:Set(k, silent)
		self.Value = k
		if self.Flag then RageHub.Flags[self.Flag] = k end
		show()
		if not silent then fire(cfg.OnChanged, k) end
	end
	btn.Activated:Connect(function()
		if win._binding == el then el:_stopListen() return end
		if win._binding then win._binding:_stopListen() end
		win._binding = el
		lbl.Text = "..."
		setKey(lbl, "TextColor3", "Accent")
	end)
	show()
	win.Keybinds[#win.Keybinds + 1] = el
	register(el, cfg, self, R)
	return el
end

--// color picker
function Section:CreateColorPicker(cfg)
	cfg = cfg or {}
	local win = self.Tab.Window
	local R = makeRow(self, cfg, { right = 46 })
	local el = { Type = "ColorPicker", Value = cfg.Default or Theme.Accent }
	local sw = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = ctlPos(), Size = UDim2.fromOffset(38, 22), BackgroundColor3 = el.Value, BackgroundTransparency = 0 }, R.Row)
	corner(sw, 6)
	stroke(sw, "Stroke", 1, 0.2)
	local h, s, v = el.Value:ToHSV()
	local pop, sv, svCur, hueCur, hex

	local function apply(silent)
		el.Value = Color3.fromHSV(h, s, v)
		sw.BackgroundColor3 = el.Value
		if pop then
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCur.Position = UDim2.fromScale(s, 1 - v)
			hueCur.Position = UDim2.fromScale(h, 0.5)
			hex.Text = string.format("#%02X%02X%02X", math.floor(el.Value.R * 255 + 0.5), math.floor(el.Value.G * 255 + 0.5), math.floor(el.Value.B * 255 + 0.5))
		end
		changed(el, silent)
	end
	local function build()
		pop = new("Frame", { BackgroundColor3 = "@Card" })
		corner(pop, 10)
		stroke(pop, "Stroke", 1, 0)
		pad(pop, 8, 8, 8, 8)
		sv = new("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromHSV(h, 1, 1) }, pop)
		corner(sv, 6)
		local wh = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, sv)
		corner(wh, 6)
		new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, wh)
		local bk = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0) }, sv)
		corner(bk, 6)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, bk)
		svCur = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 3 }, sv)
		corner(svCur, 6)
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, svCur)

		local hue = new("Frame", { Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Color3.new(1, 1, 1) }, pop)
		corner(hue, 7)
		local keys = {}
		for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 == 1 and 0.999 or i / 6, 1, 1)) end
		new("UIGradient", { Color = ColorSequence.new(keys) }, hue)
		hueCur = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 3 }, hue)
		corner(hueCur, 7)
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, hueCur)

		hex = new("TextBox", {
			Position = UDim2.fromOffset(0, 142), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0,
			TextColor3 = "@Text", TextSize = 12, ClearTextOnFocus = false, Text = "",
		}, pop)
		corner(hex, 7)
		hex.FocusLost:Connect(function()
			local r, g, b = hex.Text:match("#?(%x%x)(%x%x)(%x%x)")
			if r then
				h, s, v = Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)):ToHSV()
			end
			apply()
		end)

		local function pointer(i)
			if i.UserInputType == Enum.UserInputType.Touch then return guiPos(i) end
			return UIS:GetMouseLocation()
		end
		local function svUpdate(i)
			local p = pointer(i)
			local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
			s = clamp((p.X - ap.X) / math.max(1, as.X), 0, 1)
			v = 1 - clamp((p.Y - ap.Y) / math.max(1, as.Y), 0, 1)
			apply()
		end
		local function hueUpdate(i)
			local ap, as = hue.AbsolutePosition, hue.AbsoluteSize
			h = clamp((i.Position.X - ap.X) / math.max(1, as.X), 0, 0.999)
			apply()
		end
		sv.InputBegan:Connect(function(i) if isPointer(i) then svUpdate(i); trackInput(i, svUpdate) end end)
		hue.InputBegan:Connect(function(i) if isPointer(i) then hueUpdate(i); trackInput(i, hueUpdate) end end)
		apply(true)
	end
	sw.Activated:Connect(function()
		if not pop then build() end
		win:_showPopup(pop, sw, 210, 192, true)
	end)
	function el:Set(c, silent)
		if typeof(c) ~= "Color3" then return end
		h, s, v = c:ToHSV()
		apply(silent)
	end
	register(el, cfg, self, R)
	initFire(el, cfg)
	return el
end

--// label / paragraph / divider
function Section:CreateLabel(cfg)
	if type(cfg) == "string" then cfg = { Text = cfg } end
	cfg = cfg or {}
	local f = new("Frame", { Name = "Label", Size = UDim2.new(1, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, self.Body)
	pad(f, 10, 6, 10, 6)
	local x = 0
	if cfg.Icon then
		local ic = makeIcon(f, cfg.Icon, 14, cfg.IconColor or "Accent")
		ic.Instance.Position = UDim2.fromOffset(0, 0)
		x = 22
	end
	local lbl = new("TextLabel", {
		Text = cfg.Text or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = "@SubText", TextWrapped = true, RichText = cfg.RichText == true,
		Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x, 0, 14), AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, f)
	local el = { Type = "Label", Row = f, Value = cfg.Text or "" }
	function el:Set(t) self.Value = t; lbl.Text = t end
	function el:SetVisible(v) f.Visible = v and true or false end
	function el:Destroy() f:Destroy() end
	self.Est = self.Est + 28
	self.Tab:_queueLayout()
	return el
end

function Section:CreateParagraph(cfg)
	cfg = cfg or {}
	local f = new("Frame", { Name = "Paragraph", Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "@Elevated", BackgroundTransparency = 0.45 }, self.Body)
	corner(f, 8)
	pad(f, 10, 9, 10, 10)
	list(f, 3)
	local t = new("TextLabel", { Text = cfg.Title or "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = "@Text", Size = UDim2.new(1, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, f)
	local c = new("TextLabel", { Text = cfg.Content or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText", Size = UDim2.new(1, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 }, f)
	local el = { Type = "Paragraph", Row = f }
	function el:Set(title, content) t.Text = title or t.Text; c.Text = content or c.Text end
	function el:Destroy() f:Destroy() end
	self.Est = self.Est + 54
	self.Tab:_queueLayout()
	return el
end

function Section:CreateDivider()
	local f = new("Frame", { Name = "Divider", Size = UDim2.new(1, 0, 0, 9), BackgroundTransparency = 1 }, self.Body)
	new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(1, -16, 0, 1), BackgroundColor3 = "@Stroke", BackgroundTransparency = 0.5 }, f)
	self.Est = self.Est + 10
	return { Type = "Divider", Row = f, Destroy = function() f:Destroy() end }
end


--// config -------------------------------------------------------------------------
local function encode(v)
	local t = typeof(v)
	if t == "Color3" then return { __t = "c", r = v.R, g = v.G, b = v.B }
	elseif t == "EnumItem" then return { __t = "k", n = v.Name }
	elseif t == "table" then
		local o = {}
		for i, x in ipairs(v) do o[i] = x end
		return o
	end
	return v
end

local function decode(v)
	if type(v) == "table" then
		if v.__t == "c" then return Color3.new(v.r, v.g, v.b) end
		if v.__t == "k" then return Enum.KeyCode[v.n] end
	end
	return v
end

local function safeName(n) return (tostring(n or "default"):gsub("[^%w%-_ ]", "")) end

function Window:_dir()
	local base = self.ConfigFolder
	pcall(function()
		if not isfolder(base) then makefolder(base) end
		if not isfolder(base .. "/configs") then makefolder(base .. "/configs") end
	end)
	return base .. "/configs"
end

function Window:SaveConfig(name)
	if not writefile then return false, "writefile is not supported by this executor" end
	name = safeName(name)
	local data = {}
	for flag, el in pairs(RageHub.Options) do
		if el.Save ~= false and el.Value ~= nil then data[flag] = encode(el.Value) end
	end
	local ok, err = pcall(function() writefile(self:_dir() .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
	return ok, err
end

function Window:LoadConfig(name)
	if not readfile then return false, "readfile is not supported by this executor" end
	name = safeName(name)
	local path = self:_dir() .. "/" .. name .. ".json"
	local ok, raw = pcall(readfile, path)
	if not ok then return false, "config not found" end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false, "config is corrupted" end
	for flag, val in pairs(data) do
		local el = RageHub.Options[flag]
		if el and el.Set and el.Save ~= false then pcall(el.Set, el, decode(val)) end
	end
	return true
end

function Window:DeleteConfig(name)
	if not delfile then return false end
	return pcall(delfile, self:_dir() .. "/" .. safeName(name) .. ".json")
end

function Window:ListConfigs()
	local out = {}
	if not listfiles then return out end
	local ok, files = pcall(listfiles, self:_dir())
	if not ok then return out end
	for _, f in ipairs(files) do
		local n = tostring(f):match("([^/\\]+)%.json$")
		if n then out[#out + 1] = n end
	end
	table.sort(out)
	return out
end

function Window:SetAutoLoad(name)
	if not writefile then return end
	self:_dir()
	pcall(writefile, self.ConfigFolder .. "/autoload.txt", name and safeName(name) or "")
end

function Window:GetAutoLoad()
	if not readfile then return nil end
	local ok, n = pcall(readfile, self.ConfigFolder .. "/autoload.txt")
	if ok and n and n ~= "" then return n end
end

function Window:AutoLoad()
	local n = self:GetAutoLoad()
	if n then
		local ok = self:LoadConfig(n)
		if ok then self:Notify({ Title = "Config loaded", Content = n, Type = "success", Duration = 3 }) end
		return ok
	end
	return false
end

--// server utilities ---------------------------------------------------------------
function Window:Rejoin()
	local ok = pcall(function()
		if #Players:GetPlayers() > 1 and game.JobId ~= "" then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		else
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end
	end)
	return ok
end

function Window:ServerHop(mode)
	mode = mode or "Least Players"
	RageHub:Notify({ Title = "Server Hop", Content = "Searching for a " .. string.lower(mode) .. " server...", Type = "info", Duration = 3 })
	task.spawn(function()
		local cands, cursor, pages = {}, nil, 0
		repeat
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(game.PlaceId, cursor and ("&cursor=" .. cursor) or "")
			local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
			if not ok or type(res) ~= "table" or type(res.data) ~= "table" then break end
			for _, s in ipairs(res.data) do
				if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then cands[#cands + 1] = s end
			end
			cursor = res.nextPageCursor
			pages = pages + 1
		until not cursor or pages >= 3 or #cands >= 100
		if #cands == 0 then
			RageHub:Notify({ Title = "Server Hop", Content = "No other server found, rejoining instead.", Type = "warning" })
			pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
			return
		end
		local pick = cands[1]
		if mode == "Random" then
			pick = cands[math.random(1, #cands)]
		else
			for _, s in ipairs(cands) do
				if mode == "Most Players" then
					if s.playing > pick.playing then pick = s end
				else
					if s.playing < pick.playing then pick = s end
				end
			end
		end
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer) end)
	end)
end

function Window:JoinServer(jobId)
	jobId = tostring(jobId or ""):gsub("%s", "")
	if jobId == "" then
		RageHub:Notify({ Title = "Join Server", Content = "Paste a Job ID first.", Type = "warning" })
		return
	end
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer) end)
end

local function copy(text, what)
	if setclip then
		setclip(text)
		RageHub:Notify({ Title = "Copied", Content = what or text, Type = "success", Duration = 2.5 })
	else
		RageHub:Notify({ Title = "Copy failed", Content = "Your executor has no clipboard support.", Type = "error" })
	end
end

local function fmtTime(s)
	s = math.floor(s)
	if s >= 3600 then return string.format("%dh %02dm %02ds", s // 3600, (s % 3600) // 60, s % 60) end
	return string.format("%dm %02ds", s // 60, s % 60)
end

--// built-in settings tab ------------------------------------------------------------
function Window:CreateSettingsTab(opts)
	opts = opts or {}
	local win = self
	local tab = self:CreateTab(opts.Name or "Settings", opts.Icon or "settings")
	local started = os.clock()

	--// features ---------------------------------------------------------------
	local afkConn, afkDisabled = nil, {}
	local function setAntiAfk(on)
		if afkConn then afkConn:Disconnect(); afkConn = nil end
		for _, c in ipairs(afkDisabled) do pcall(function() c:Enable() end) end
		afkDisabled = {}
		if not on then return end
		pcall(function()
			if getconnections then
				for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
					c:Disable()
					afkDisabled[#afkDisabled + 1] = c
				end
			end
		end)
		afkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				local vu = svc("VirtualUser")
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end)
	end

	local rejoinConns, rejoining = {}, false
	local function clearRejoin()
		for _, c in ipairs(rejoinConns) do pcall(function() c:Disconnect() end) end
		rejoinConns = {}
	end
	local function doRejoin()
		if rejoining or not RageHub.Flags.RH_AutoRejoin then return end
		rejoining = true
		RageHub:Notify({ Title = "Auto Rejoin", Content = "Connection lost, rejoining...", Type = "warning", Duration = 5 })
		task.spawn(function()
			for attempt = 1, 8 do
				if not RageHub.Flags.RH_AutoRejoin then break end
				pcall(function()
					if RageHub.Flags.RH_RejoinSame and attempt <= 3 and game.JobId ~= "" then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
					else
						TeleportService:Teleport(game.PlaceId, LocalPlayer)
					end
				end)
				task.wait(7)
			end
			rejoining = false
		end)
	end
	local function setAutoRejoin(on)
		clearRejoin()
		if not on then return end
		rejoinConns[#rejoinConns + 1] = GuiService.ErrorMessageChanged:Connect(function()
			local ok, msg = pcall(function() return GuiService:GetErrorMessage() end)
			if ok and msg and msg ~= "" then doRejoin() end
		end)
		task.spawn(function()
			local ok, overlay = pcall(function()
				return CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
			end)
			if ok and overlay and RageHub.Flags.RH_AutoRejoin then
				rejoinConns[#rejoinConns + 1] = overlay.ChildAdded:Connect(function(c)
					if c.Name == "ErrorPrompt" then doRejoin() end
				end)
			end
		end)
	end

	local queued = false
	local function autoExecScript()
		local s = RageHub.Flags.RH_AutoExecScript
		if not s or s == "" then s = win.AutoExecuteScript end
		return s
	end
	local function queueScript()
		if queued or not RageHub.Flags.RH_AutoExecute or not queueTp then return end
		local s = autoExecScript()
		if s and s ~= "" then
			queued = pcall(queueTp, s)
		end
	end
	self.Maid:Add(LocalPlayer.OnTeleport:Connect(queueScript))

	local lowGfx = { on = false }
	local function setLowGfx(on)
		if on == lowGfx.on then return end
		lowGfx.on = on
		if on then
			lowGfx.shadows = Lighting.GlobalShadows
			pcall(function() lowGfx.quality = settings().Rendering.QualityLevel end)
			lowGfx.fx = {}
			Lighting.GlobalShadows = false
			pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
			for _, c in ipairs(Lighting:GetChildren()) do
				if c:IsA("PostEffect") or c:IsA("Atmosphere") then
					lowGfx.fx[#lowGfx.fx + 1] = { c, c.Enabled }
					pcall(function() c.Enabled = false end)
				end
			end
		else
			Lighting.GlobalShadows = lowGfx.shadows ~= false
			pcall(function() if lowGfx.quality then settings().Rendering.QualityLevel = lowGfx.quality end end)
			for _, e in ipairs(lowGfx.fx or {}) do pcall(function() e[1].Enabled = e[2] end) end
		end
	end

	self._onDestroy[#self._onDestroy + 1] = function()
		setAntiAfk(false)
		clearRejoin()
		setLowGfx(false)
		pcall(function() RunService:Set3dRenderingEnabled(true) end)
	end

	--// Join & Stay ------------------------------------------------------------
	local js = tab:CreateSection("Join & Stay", "refresh")
	js:CreateToggle({
		Name = "Auto Rejoin", Description = "Rejoin automatically when you get kicked or disconnected.",
		Flag = "RH_AutoRejoin", Default = false, Callback = function(v) setAutoRejoin(v) end,
	})
	js:CreateToggle({
		Name = "Rejoin Same Server", Description = "Try to come back to this server first.",
		Flag = "RH_RejoinSame", Default = false,
	})
	js:CreateToggle({
		Name = "Auto Execute", Description = "Run your script again after rejoin or server hop.",
		Flag = "RH_AutoExecute", Default = false, CallOnCreate = false,
		Callback = function(v)
			queued = false
			if v and not queueTp then
				RageHub:Notify({ Title = "Auto Execute", Content = "queue_on_teleport is not supported by your executor.", Type = "error" })
			elseif v and (not autoExecScript() or autoExecScript() == "") then
				RageHub:Notify({ Title = "Auto Execute", Content = "Paste the script to re-run below.", Type = "warning" })
			end
		end,
	})
	js:CreateInput({
		Name = "Auto Execute Script", Description = "Example: loadstring(game:HttpGet(\"https://...\"))()",
		Flag = "RH_AutoExecScript", Default = self.AutoExecuteScript or "", Placeholder = "script to run", CallOnCreate = false,
	})
	js:CreateToggle({
		Name = "Anti AFK", Description = "Never get kicked for being idle.",
		Flag = "RH_AntiAfk", Default = true, Callback = function(v) setAntiAfk(v) end,
	})

	--// Server -----------------------------------------------------------------
	local sv = tab:CreateSection("Server", "server")
	local lblPlayers = sv:CreateLabel({ Text = "Players: -", Icon = "users" })
	local lblPing = sv:CreateLabel({ Text = "Ping: -", Icon = "wifi" })
	local lblSession = sv:CreateLabel({ Text = "Session: 0m 00s", Icon = "clock" })
	sv:CreateDivider()
	sv:CreateButton({ Name = "Rejoin Server", Description = "Reconnect to this exact server.", ButtonText = "Rejoin", Icon = "refresh",
		Callback = function() queueScript(); win:Rejoin() end })
	sv:CreateDropdown({ Name = "Hop Mode", Options = { "Least Players", "Most Players", "Random" }, Default = "Least Players", Flag = "RH_HopMode" })
	sv:CreateButton({ Name = "Server Hop", Description = "Jump to another public server.", ButtonText = "Hop", Icon = "shuffle",
		Callback = function() queueScript(); win:ServerHop(RageHub.Flags.RH_HopMode) end })
	sv:CreateButton({ Name = "Copy Job ID", ButtonText = "Copy", Icon = "copy", Callback = function() copy(game.JobId, game.JobId) end })
	sv:CreateInput({ Name = "Join Job ID", Placeholder = "paste Job ID", Flag = "RH_JoinId", Save = false, CallOnCreate = false })
	sv:CreateButton({ Name = "Join Server", ButtonText = "Join", Icon = "login",
		Callback = function() queueScript(); win:JoinServer(RageHub.Flags.RH_JoinId) end })

	task.spawn(function()
		while win.Main.Parent do
			if win.Visible and tab.IsActive then
				lblPlayers:Set(("Players: %d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers))
				local ping
				pcall(function() ping = svc("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
				if not ping then pcall(function() ping = LocalPlayer:GetNetworkPing() * 2000 end) end
				lblPing:Set(ping and ("Ping: %d ms"):format(math.floor(ping + 0.5)) or "Ping: -")
				lblSession:Set("Session: " .. fmtTime(os.clock() - started))
			end
			task.wait(1)
		end
	end)

	--// Interface --------------------------------------------------------------
	local ui = tab:CreateSection("Interface", "monitor")
	ui:CreateSlider({ Name = "UI Scale", Min = 60, Max = 140, Increment = 5, Default = 100, Suffix = "%", Flag = "RH_Scale",
		Callback = function(v) win:SetScale(v / 100) end })
	ui:CreateSlider({ Name = "Transparency", Min = 0, Max = 60, Increment = 5, Default = 0, Suffix = "%", Flag = "RH_Alpha",
		Callback = function(v) win:SetTransparency(v / 100) end })
	local names = {}
	for n in pairs(RageHub.Themes) do names[#names + 1] = n end
	table.sort(names)
	ui:CreateDropdown({ Name = "Theme", Options = names, Default = RageHub.CurrentTheme, Flag = "RH_Theme",
		Callback = function(v) if v then RageHub:SetTheme(v) end end })
	ui:CreateKeybind({ Name = "Toggle Key", Description = "Show / hide the window (PC).", Default = self.ToggleKey, Flag = "RH_ToggleKey",
		OnChanged = function(k) win:SetToggleKey(k or Enum.KeyCode.Unknown) end })
	ui:CreateToggle({ Name = "Floating Button", Description = "Draggable button to open the menu.", Default = self.Float.Visible, Flag = "RH_Float",
		Callback = function(v) win:SetFloatingButton(v) end })
	ui:CreateToggle({ Name = "Compact Sidebar", Default = self.Collapsed, Flag = "RH_Compact",
		Callback = function(v) win:SetCollapsed(v) end })
	ui:CreateToggle({ Name = "Notifications", Default = true, Flag = "RH_Notify",
		Callback = function(v) RageHub.Notifications = v end })

	--// Performance ------------------------------------------------------------
	local pf = tab:CreateSection("Performance", "gauge")
	pf:CreateToggle({ Name = "Reduce Animations", Description = "Disables UI tweens for the smoothest FPS.", Default = false, Flag = "RH_ReduceMotion",
		Callback = function(v) RageHub.ReduceMotion = v end })
	pf:CreateSlider({ Name = "FPS Cap", Min = 20, Max = 360, Increment = 5, Default = 60, Suffix = " fps", Flag = "RH_FpsCap", CallOnCreate = false,
		Callback = function(v) if setfpscap then pcall(setfpscap, v) end end })
	pf:CreateToggle({ Name = "Low Graphics", Description = "Turns off shadows and post effects.", Default = false, Flag = "RH_LowGfx",
		Callback = function(v) setLowGfx(v) end })
	pf:CreateToggle({ Name = "White Screen", Description = "Stops 3D rendering. Great for AFK farming.", Default = false, Flag = "RH_NoRender",
		Callback = function(v) pcall(function() RunService:Set3dRenderingEnabled(not v) end) end })

	--// Config -----------------------------------------------------------------
	local cf = tab:CreateSection("Config", "save")
	local dd
	cf:CreateInput({ Name = "Config Name", Default = "default", Flag = "RH_ConfigName", Save = false, CallOnCreate = false })
	dd = cf:CreateDropdown({ Name = "Saved Configs", Options = win:ListConfigs(), Search = true, Placeholder = "none", Flag = "RH_ConfigSel", Save = false })
	cf:CreateButton({ Name = "Save Config", ButtonText = "Save", Icon = "save", Callback = function()
		local n = RageHub.Flags.RH_ConfigName
		local ok, err = win:SaveConfig(n)
		if ok then
			dd:Refresh(win:ListConfigs(), true)
			win:Notify({ Title = "Config saved", Content = safeName(n), Type = "success", Duration = 3 })
		else
			win:Notify({ Title = "Save failed", Content = tostring(err), Type = "error" })
		end
	end })
	cf:CreateButton({ Name = "Load Config", ButtonText = "Load", Icon = "download", Callback = function()
		local n = RageHub.Flags.RH_ConfigSel or RageHub.Flags.RH_ConfigName
		local ok, err = win:LoadConfig(n)
		if ok then win:Notify({ Title = "Config loaded", Content = safeName(n), Type = "success", Duration = 3 })
		else win:Notify({ Title = "Load failed", Content = tostring(err), Type = "error" }) end
	end })
	cf:CreateButton({ Name = "Delete Config", ButtonText = "Delete", Icon = "trash", Danger = true, Callback = function()
		local n = RageHub.Flags.RH_ConfigSel
		if n then
			win:DeleteConfig(n)
			dd:Refresh(win:ListConfigs())
			win:Notify({ Title = "Config deleted", Content = tostring(n), Type = "warning", Duration = 3 })
		end
	end })
	cf:CreateToggle({ Name = "Auto Load", Description = "Load the selected config on startup.", Default = win:GetAutoLoad() ~= nil, Flag = "RH_AutoLoad", Save = false,
		CallOnCreate = false, Callback = function(v)
			local n = RageHub.Flags.RH_ConfigSel or RageHub.Flags.RH_ConfigName
			win:SetAutoLoad(v and n or nil)
		end })

	--// System -----------------------------------------------------------------
	local sy = tab:CreateSection("System", "power")
	sy:CreateLabel({ Text = "Rage Hub v" .. RageHub.Version, Icon = "rage" })
	sy:CreateButton({ Name = "Unload Rage Hub", Description = "Closes the UI and stops every built-in feature.", ButtonText = "Unload", Icon = "power", Danger = true,
		Callback = function() RageHub:Unload() end })

	return tab
end

return RageHub
