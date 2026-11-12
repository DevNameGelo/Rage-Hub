
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

