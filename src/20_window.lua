
--// window / tab / section ----------------------------------------------------
local Window, Tab, Section = {}, {}, {}
Window.__index = Window
Tab.__index = Tab
Section.__index = Section

local SB_OPEN, SB_SHUT = 176, 62
local FLOAT = 46
local ELEMENTS = { "CreateToggle", "CreateSlider", "CreateDropdown", "CreateButton", "CreateInput",
	"CreateKeybind", "CreateColorPicker", "CreateLabel", "CreateParagraph", "CreateDivider" }

local function viewport()
	local g = RageHub.Gui
	local v = g and g.AbsoluteSize or Vector2.new(0, 0)
	if v.X < 100 or v.Y < 100 then
		local cam = workspace.CurrentCamera
		v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	return v
end

local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end

-- base = the glass transparency of this layer. The "Transparency" setting fades all layers further.
function Window:_a(inst, base)
	base = base or 0
	self._alpha[#self._alpha + 1] = { inst, base }
	inst.BackgroundTransparency = 1 - (1 - base) * (1 - self.Alpha)
end

function Window:SetTransparency(t)
	self.Alpha = clamp(t or 0, 0, 0.8)
	local live = {}
	for _, e in ipairs(self._alpha) do
		if e[1].Parent then
			e[1].BackgroundTransparency = 1 - (1 - e[2]) * (1 - self.Alpha)
			live[#live + 1] = e
		end
	end
	self._alpha = live
end

function Window:_applyScale()
	local vp = viewport()
	local w, h = self.Main.Size.X.Offset, self.Main.Size.Y.Offset
	local auto = clamp(math.min(1, (vp.X - 20) / w, (vp.Y - 20) / h), 0.5, 1)
	self._target = auto * self.UserScale
	self.UIScale.Scale = self._target
end

-- keep the whole window on screen (acts like a wall at every edge)
function Window:_setCenter(x, y)
	local vp = viewport()
	local sz = self.Main.AbsoluteSize
	local hx, hy = sz.X / 2, sz.Y / 2
	x = clamp(x, math.min(hx, vp.X - hx), math.max(hx, vp.X - hx))
	y = clamp(y, math.min(hy, vp.Y - hy), math.max(hy, vp.Y - hy))
	self.Main.Position = UDim2.fromOffset(x, y)
end

function Window:_clamp()
	local ap, sz = self.Main.AbsolutePosition, self.Main.AbsoluteSize
	self:_setCenter(ap.X + sz.X / 2, ap.Y + sz.Y / 2)
end

function Window:SetScale(s)
	self.UserScale = clamp(s or 1, 0.6, 1.5)
	self:_applyScale()
	task.defer(function() if self.Main.Parent then self:_clamp() end end)
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

--// logs (shown on the Dashboard, filled by notifications and your own Window:Log calls)
function Window:Log(text, kind)
	self._logBuf[#self._logBuf + 1] = { text = tostring(text), kind = kind or "info", t = os.date("%H:%M:%S") }
	if #self._logBuf > 120 then table.remove(self._logBuf, 1) end
	if self.Dashboard and self.Dashboard.Activity then
		self.Dashboard.Activity:Add(text, kind)
	end
end

--// search ----------------------------------------------------------------------
function Window:_reg(el, cfg, sec)
	self._lastCreate = os.clock()
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
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = "@Card", BackgroundTransparency = GLASS.Card, LayoutOrder = n }, sp)
			corner(b, 8)
			stroke(b, "Stroke", 1, 0.92)
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
			tw(e.row, 0.12, { BackgroundTransparency = 0.8 })
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
		ScrollBarThickness = 3, ScrollBarImageColor3 = "@Stroke", ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(),
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
	win._lastCreate = os.clock()
	local sec = setmetatable({ Tab = self, Name = name, Est = 44, Side = opts.Side, Collapsed = false }, Section)
	local frame = new("Frame", {
		Name = name or "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "@Card", LayoutOrder = #self.Sections + 1,
	}, self.Col1)
	corner(frame, 12)
	stroke(frame, "Stroke", 1, 0.9)
	win:_a(frame, GLASS.Card)
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

function Tab:RemoveSection(sec)
	for i, s in ipairs(self.Sections) do
		if s == sec then table.remove(self.Sections, i) break end
	end
	if sec.Frame then sec.Frame:Destroy() end
	if self._def == sec then self._def = nil end
	self:_queueLayout()
end

function Section:SetCollapsed(c)
	self.Collapsed = c
	self.Body.Visible = not c
	if self.Chevron then tw(self.Chevron, 0.15, { Rotation = c and -90 or 0 }) end
end

function Section:Remove() self.Tab:RemoveSection(self) end

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
	self._alpha, self._sbText, self._onDestroy, self._logBuf = {}, {}, {}, {}
	self._order = 0
	self._lastCreate = os.clock()
	self.Visible = true
	self.Collapsed = cfg.CompactSidebar == true
	self.AutoExecuteScript = nil
	if cfg.AutoExecuteURL or cfg.AutoExecuteScript then self:SetAutoExecute(cfg.AutoExecuteURL or cfg.AutoExecuteScript) end

	local size = cfg.Size or Vector2.new(660, 400)
	local main = new("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = "@Bg",
	}, Gui)
	self.Main = main
	self.UIScale = new("UIScale", {}, main)
	corner(main, 16)
	self:_a(main, GLASS.Window)
	-- glass edge: bright top-left, soft bottom-right
	local edge = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, main)
	new("UIGradient", { Rotation = 45, Transparency = NumberSequence.new({ kp(0, 0.4), kp(0.5, 0.9), kp(1, 0.68) }) }, edge)
	-- glass sheen
	local sheen = new("Frame", { Name = "Sheen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, main)
	corner(sheen, 16)
	new("UIGradient", { Rotation = 35, Transparency = NumberSequence.new({ kp(0, 0.9), kp(0.45, 0.97), kp(1, 1) }) }, sheen)

	--// sidebar
	local sidebar = new("Frame", { Name = "Sidebar", BackgroundTransparency = 1, Size = UDim2.new(0, self.Collapsed and SB_SHUT or SB_OPEN, 1, 0) }, main)
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

	local sb = new("Frame", { Name = "Search", Position = UDim2.fromOffset(10, 60), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = "@Elevated", BackgroundTransparency = GLASS.Elev }, sidebar)
	corner(sb, 9)
	stroke(sb, "Stroke", 1, 0.92)
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
		Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0.85,
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

	--// content (frosted panel)
	local sw = self.Collapsed and SB_SHUT or SB_OPEN
	local content = new("Frame", {
		Name = "Content", Position = UDim2.new(0, sw, 0, 8), Size = UDim2.new(1, -sw - 8, 1, -16), BackgroundColor3 = "@Card",
	}, main)
	corner(content, 12)
	stroke(content, "Stroke", 1, GLASS.Stroke)
	self:_a(content, GLASS.Content)
	self.Content = content

	local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, content)
	local drag = new("TextButton", { Name = "Drag", Size = UDim2.fromScale(1, 1) }, header)
	self.Title = new("TextLabel", {
		Text = "", Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = "@Text", Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, header)
	new("Frame", { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "@Stroke", BackgroundTransparency = 0.92 }, header)

	local function hbtn(iconName, x, cb)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -x, 0, 23),
			BackgroundColor3 = "@Elevated", BackgroundTransparency = 1,
		}, header)
		corner(b, 8)
		local ic = makeIcon(b, iconName, 16, "SubText")
		ic.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Instance.Position = UDim2.fromScale(0.5, 0.5)
		b.MouseEnter:Connect(function() tw(b, 0.1, { BackgroundTransparency = 0.85 }) end)
		b.MouseLeave:Connect(function() tw(b, 0.1, { BackgroundTransparency = 1 }) end)
		b.Activated:Connect(cb)
		return ic
	end
	hbtn("x", 10, function() self:SetVisible(false) end)
	self._collapseIcon = hbtn("chevron-left", 46, function() self:SetCollapsed(not self.Collapsed) end)
	self._collapseIcon.Instance.Rotation = self.Collapsed and 180 or 0

	self.Pages = new("Frame", { Name = "Pages", Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 1, -47), BackgroundTransparency = 1, ClipsDescendants = true }, content)
	pad(self.Pages, 10, 10, 4, 0)
	self.SearchPage = new("ScrollingFrame", {
		Name = "SearchResults", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 3,
		ScrollBarImageColor3 = "@Stroke", ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, self.Pages)
	pad(self.SearchPage, 0, 0, 8, 10)
	list(self.SearchPage, 6)

	self.Overlay = new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, main)

	--// dragging (window can never leave the screen) + resizing
	local function draggable(handle)
		handle.InputBegan:Connect(function(i)
			if not isPointer(i) then return end
			local start = i.Position
			local ap, sz = main.AbsolutePosition, main.AbsoluteSize
			local cx, cy = ap.X + sz.X / 2, ap.Y + sz.Y / 2
			trackInput(i, function(m)
				local d = m.Position - start
				self:_setCenter(cx + d.X, cy + d.Y)
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
			self:_clamp()
			if self.Active then self.Active:_layout() end
		end)
	end)

	--// floating toggle button: a wall on every edge, it can never leave the screen
	local showFloat = cfg.FloatingButton
	if showFloat == nil then showFloat = IsMobile end
	local fb = new("TextButton", {
		Name = "RageFloat", Size = UDim2.fromOffset(FLOAT, FLOAT), BackgroundColor3 = Color3.new(1, 1, 1), Visible = showFloat,
	}, Gui)
	local function floatPos(x, y)
		local vp = viewport()
		return clamp(x, 6, math.max(6, vp.X - FLOAT - 6)), clamp(y, 6, math.max(6, vp.Y - FLOAT - 6))
	end
	do
		local x, y = floatPos(14, viewport().Y / 2 - FLOAT / 2)
		fb.Position = UDim2.fromOffset(x, y)
	end
	corner(fb, 14)
	accentGradient(fb, 45)
	new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, fb)
	local fbi = makeIcon(fb, "rage", 28, Color3.new(1, 1, 1))
	fbi.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
	fbi.Instance.Position = UDim2.fromScale(0.5, 0.5)
	local moved = false
	fb.InputBegan:Connect(function(i)
		if not isPointer(i) then return end
		moved = false
		local start, sp = i.Position, fb.AbsolutePosition
		trackInput(i, function(m)
			local d = m.Position - start
			if d.Magnitude > 6 then moved = true end
			if moved then
				local x, y = floatPos(sp.X + d.X, sp.Y + d.Y)
				fb.Position = UDim2.fromOffset(x, y)
			end
		end)
	end)
	fb.Activated:Connect(function() if not moved then self:Toggle() end end)
	self.Float = fb
	function self:SetFloatingButton(v)
		fb.Visible = v and true or false
		local x, y = floatPos(fb.AbsolutePosition.X, fb.AbsolutePosition.Y)
		fb.Position = UDim2.fromOffset(x, y)
	end

	--// scale + keep everything on screen when the viewport changes
	self:_applyScale()
	self.Maid:Add(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_applyScale()
		local x, y = floatPos(fb.AbsolutePosition.X, fb.AbsolutePosition.Y)
		fb.Position = UDim2.fromOffset(x, y)
		self:_clamp()
	end))
	self:SetCollapsed(self.Collapsed, true)

	--// search box
	self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self._sq = (self._sq or 0) + 1
		local id, q = self._sq, self.SearchBox.Text
		task.delay(0.15, function() if id == self._sq then self:_doSearch(q) end end)
	end)

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
	self:_initCore(cfg)
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

