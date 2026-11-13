
--// dashboard ----------------------------------------------------------------------
-- Window:CreateDashboard() builds a Home tab with: Profile, Overview (session time, FPS, ping,
-- players), Game (name, place id, job id, executor), Quick Actions and an Activity log.
-- Everything can be removed, and you can add your own stats, buttons, update notes, logs and cards.
local Dashboard = {}
Dashboard.__index = Dashboard

local LOG_HEX = { info = "#9AA4FF", success = "#34D399", warning = "#FBBF24", error = "#F87171" }

local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function executorName()
	local ok, n, v = pcall(function()
		if identifyexecutor then return identifyexecutor() end
		if getexecutorname then return getexecutorname() end
	end)
	if ok and n then return tostring(n) .. (v and (" " .. tostring(v)) or "") end
	return "Unknown"
end

local function kvRow(sec, key, value, copyText)
	local f = new("TextButton", { Name = key, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = "@Elevated", BackgroundTransparency = 1 }, sec.Body)
	corner(f, 7)
	pad(f, 10, 0, 10, 0)
	new("TextLabel", { Text = key, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = "@SubText", Size = UDim2.fromScale(0.38, 1), TextXAlignment = Enum.TextXAlignment.Left }, f)
	local v = new("TextLabel", {
		Text = tostring(value), TextSize = 12, TextColor3 = "@Text", Position = UDim2.fromScale(0.38, 0), Size = UDim2.fromScale(0.62, 1),
		TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
	}, f)
	if copyText then
		f.MouseEnter:Connect(function() tw(f, 0.1, { BackgroundTransparency = 0.9 }) end)
		f.MouseLeave:Connect(function() tw(f, 0.1, { BackgroundTransparency = 1 }) end)
		f.Activated:Connect(function() copy(tostring(copyText), key) end)
	end
	sec.Est = sec.Est + 30
	return v
end

function Dashboard:_card(name, icon, opts)
	return self.Tab:CreateSection(name, icon, opts)
end

--// profile card
function Dashboard:_buildProfile()
	local sec = self:_card("Profile", "user-circle")
	self.Widgets.Profile = sec
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1 }, sec.Body)
	local av = new("ImageLabel", {
		Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0.85,
		Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LocalPlayer.UserId),
	}, top)
	corner(av, 24)
	new("TextLabel", {
		Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = "@Text", Position = UDim2.fromOffset(64, 9),
		Size = UDim2.new(1, -140, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)
	new("TextLabel", {
		Text = "@" .. LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText", Position = UDim2.fromOffset(64, 29),
		Size = UDim2.new(1, -140, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		local pill = new("TextLabel", {
			Text = "PREMIUM", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = "@OnAccent", AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 10), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0,
		}, top)
		corner(pill, 9)
		pad(pill, 8, 0, 8, 0)
		accentGradient(pill, 0)
	end
	sec.Est = sec.Est + 60
	kvRow(sec, "User ID", LocalPlayer.UserId, LocalPlayer.UserId)
	kvRow(sec, "Account Age", LocalPlayer.AccountAge .. " days")
end

--// overview (stat tiles)
function Dashboard:_grid()
	if self.Grid then return self.Grid end
	local sec = self:_card("Overview", "activity")
	self.Widgets.Overview = sec
	self.Grid = new("Frame", { Name = "Stats", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sec.Body)
	new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 54), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, self.Grid)
	self._statN = 0
	return self.Grid
end

-- Dashboard:AddStat({ Id, Name, Value, Icon }) -> { Set(value), Destroy() }
function Dashboard:AddStat(cfg)
	cfg = cfg or {}
	local grid = self:_grid()
	local sec = self.Widgets.Overview
	self._statN = self._statN + 1
	local tile = new("Frame", { Name = cfg.Id or cfg.Name or "Stat", BackgroundColor3 = "@Elevated", BackgroundTransparency = 0.92, LayoutOrder = self._statN }, grid)
	corner(tile, 9)
	stroke(tile, "Stroke", 1, 0.93)
	local ic = makeIcon(tile, cfg.Icon or "activity", 14, "Accent")
	ic.Instance.Position = UDim2.fromOffset(10, 9)
	new("TextLabel", {
		Text = cfg.Name or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText", Position = UDim2.fromOffset(30, 8),
		Size = UDim2.new(1, -38, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, tile)
	local val = new("TextLabel", {
		Text = tostring(cfg.Value == nil and "-" or cfg.Value), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = "@Text",
		Position = UDim2.fromOffset(10, 27), Size = UDim2.new(1, -18, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, tile)
	local st = { Frame = tile }
	function st:Set(v) val.Text = tostring(v) end
	function st:Destroy() tile:Destroy() end
	if cfg.Id then self.Stats[cfg.Id] = st end
	if self._statN % 2 == 1 then sec.Est = sec.Est + 62 end
	sec.Tab:_queueLayout()
	return st
end

function Dashboard:_buildOverview()
	self:AddStat({ Id = "Session", Name = "Session Time", Value = "0m 00s", Icon = "clock" })
	self:AddStat({ Id = "FPS", Name = "FPS", Value = "-", Icon = "gauge" })
	self:AddStat({ Id = "Ping", Name = "Ping", Value = "-", Icon = "wifi" })
	self:AddStat({ Id = "Players", Name = "Players", Value = "-", Icon = "users" })
end

--// game card
function Dashboard:_buildGame()
	local sec = self:_card("Game", "gamepad")
	self.Widgets.Game = sec
	local nameRow = kvRow(sec, "Game", game.Name ~= "" and game.Name or "Unknown")
	kvRow(sec, "Place ID", game.PlaceId, game.PlaceId)
	kvRow(sec, "Job ID", game.JobId ~= "" and game.JobId or "Studio", game.JobId ~= "" and game.JobId or nil)
	kvRow(sec, "Executor", executorName())
	task.spawn(function()
		local ok, info = pcall(function() return svc("MarketplaceService"):GetProductInfo(game.PlaceId) end)
		if ok and info and info.Name and nameRow.Parent then nameRow.Text = tostring(info.Name) end
	end)
end

--// quick actions
function Dashboard:_actions()
	if self.ActionsSec then return self.ActionsSec end
	self.ActionsSec = self:_card("Quick Actions", "zap")
	self.Widgets.Actions = self.ActionsSec
	return self.ActionsSec
end

-- Dashboard:AddButton({ Name, Description, ButtonText, Icon, Danger, Callback })
function Dashboard:AddButton(cfg)
	return self:_actions():CreateButton(cfg)
end

function Dashboard:_buildActions()
	local win = self.Window
	self.Buttons.Rejoin = self:AddButton({ Name = "Rejoin", Description = "Reconnect to this server.", ButtonText = "Rejoin", Icon = "refresh", Callback = function() win:Rejoin() end })
	self.Buttons.CopyJobId = self:AddButton({ Name = "Copy Job ID", ButtonText = "Copy", Icon = "copy", Callback = function() copy(game.JobId, game.JobId) end })
end

--// updates ("What's New")
function Dashboard:_updatesCard()
	if self.Widgets.Updates then return self.Widgets.Updates end
	local sec = self:_card("What's New", "sparkles")
	self.Widgets.Updates = sec
	-- move it to the top of the dashboard
	local list_ = self.Tab.Sections
	table.remove(list_, #list_)
	table.insert(list_, 1, sec)
	self.Tab:_queueLayout()
	self._upd = {}
	return sec
end

-- Dashboard:AddUpdate({ Version = "v1.2", Title = "...", Text = "...", Date = "Nov 12" })
function Dashboard:AddUpdate(cfg)
	cfg = cfg or {}
	local sec = self:_updatesCard()
	self._updN = (self._updN or 0) + 1
	local f = new("Frame", {
		Name = "Update", Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "@Elevated",
		BackgroundTransparency = 0.92, LayoutOrder = -self._updN,
	}, sec.Body)
	corner(f, 9)
	stroke(f, "Stroke", 1, 0.93)
	pad(f, 10, 9, 10, 10)
	list(f, 4)
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1 }, f)
	if cfg.Version then
		local pill = new("TextLabel", {
			Text = tostring(cfg.Version), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = "@OnAccent", Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0,
		}, head)
		corner(pill, 9)
		pad(pill, 8, 0, 8, 0)
		accentGradient(pill, 0)
	end
	if cfg.Date then
		new("TextLabel", {
			Text = tostring(cfg.Date), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@Muted", AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(100, 18), TextXAlignment = Enum.TextXAlignment.Right,
		}, head)
	end
	if cfg.Title then
		new("TextLabel", {
			Text = tostring(cfg.Title), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = "@Text", Size = UDim2.new(1, 0, 0, 16),
			AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
		}, f)
	end
	if cfg.Text then
		new("TextLabel", {
			Text = tostring(cfg.Text), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@SubText", Size = UDim2.new(1, 0, 0, 12),
			AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 3,
		}, f)
	end
	self._upd[#self._upd + 1] = f
	sec.Est = sec.Est + 80
	sec.Tab:_queueLayout()
	return { Frame = f, Destroy = function() f:Destroy() end }
end

function Dashboard:ClearUpdates()
	for _, f in ipairs(self._upd or {}) do f:Destroy() end
	self._upd = {}
end

--// logs: Dashboard:CreateLog({ Name, Icon, Max, Height, Empty }) -> { Add(text, kind), Clear() }
function Dashboard:CreateLog(cfg)
	cfg = cfg or {}
	local sec = self.Tab:CreateSection(cfg.Name or "Log", cfg.Icon or "list", { Side = cfg.Side })
	sec.Est = sec.Est + (cfg.Height or 150) + 8
	local box = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, cfg.Height or 150), BackgroundColor3 = "@Elevated", BackgroundTransparency = 0.93,
		ScrollBarThickness = 3, ScrollBarImageColor3 = "@Stroke", ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, sec.Body)
	corner(box, 9)
	pad(box, 8, 6, 8, 6)
	list(box, 3)
	local empty = new("TextLabel", {
		Text = cfg.Empty or "Nothing yet.", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@Muted",
		Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1000000,
	}, box)
	local log = { Section = sec, _n = 0, _items = {}, Max = cfg.Max or 60 }
	function log:Add(text, kind, ts)
		empty.Visible = false
		self._n = self._n + 1
		local col = LOG_HEX[kind or "info"] or LOG_HEX.info
		local l = new("TextLabel", {
			Text = ('<font color="%s">%s</font>  %s'):format(col, ts or os.date("%H:%M:%S"), esc(text)), RichText = true,
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@Text", TextWrapped = true, Size = UDim2.new(1, 0, 0, 14),
			AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = -self._n,
		}, box)
		self._items[#self._items + 1] = l
		if #self._items > self.Max then table.remove(self._items, 1):Destroy() end
	end
	function log:Clear()
		for _, l in ipairs(self._items) do l:Destroy() end
		self._items = {}
		empty.Visible = true
	end
	return log
end

-- Dashboard:AddSection(name, icon) -> a normal Section (toggles, buttons, labels...) on the dashboard
function Dashboard:AddSection(name, icon, opts)
	return self.Tab:CreateSection(name, icon, opts)
end

function Dashboard:Log(text, kind) self.Window:Log(text, kind) end

function Dashboard:RemoveWidget(name)
	local sec = self.Widgets[name]
	if sec then self.Tab:RemoveSection(sec) end
	self.Widgets[name] = nil
	if name == "Overview" then self.Grid = nil; self.Stats = {} end
	if name == "Activity" then self.Activity = nil end
	if name == "Actions" then self.ActionsSec = nil; self.Buttons = {} end
	if name == "Updates" then self._upd = nil end
end

function Window:CreateDashboard(opts)
	opts = opts or {}
	local want = opts.Widgets or {}
	local tab = self:CreateTab(opts.Name or "Dashboard", opts.Icon or "home")
	local D = setmetatable({ Tab = tab, Window = self, Widgets = {}, Stats = {}, Buttons = {}, _statN = 0, _updN = 0 }, Dashboard)
	self.Dashboard = D
	local t0 = os.clock()

	if want.Profile ~= false then D:_buildProfile() end
	if want.Overview ~= false then D:_buildOverview() end
	if want.Game ~= false then D:_buildGame() end
	if want.Actions ~= false then D:_buildActions() end
	if want.Activity ~= false then
		D.Activity = D:CreateLog({ Name = "Activity", Icon = "list", Empty = "No activity yet." })
		D.Widgets.Activity = D.Activity.Section
		for _, e in ipairs(self._logBuf) do D.Activity:Add(e.text, e.kind, e.t) end
	end

	-- live stats: only runs while the dashboard is on screen (FPS counter included)
	task.spawn(function()
		local frames, last, conn, fresh = 0, os.clock(), nil, true
		while self.Main.Parent do
			local live = self.Visible and tab.IsActive
			if live then
				if not conn then
					frames, last, fresh = 0, os.clock(), true
					conn = RunService.Heartbeat:Connect(function() frames = frames + 1 end)
				end
				local now = os.clock()
				local fps = frames / math.max(0.001, now - last)
				frames, last = 0, now
				local S = D.Stats
				if S.Session then S.Session:Set(fmtTime(now - t0)) end
				if S.FPS and not fresh then S.FPS:Set(math.floor(fps + 0.5)) end
				if S.Ping then
					local ping
					pcall(function() ping = svc("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
					if not ping then pcall(function() ping = LocalPlayer:GetNetworkPing() * 2000 end) end
					S.Ping:Set(ping and (math.floor(ping + 0.5) .. " ms") or "-")
				end
				if S.Players then S.Players:Set(#Players:GetPlayers() .. " / " .. Players.MaxPlayers) end
				fresh = false
			elseif conn then
				conn:Disconnect()
				conn = nil
			end
			task.wait(1)
		end
		if conn then conn:Disconnect() end
	end)

	return D
end

