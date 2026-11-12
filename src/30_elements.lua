
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

