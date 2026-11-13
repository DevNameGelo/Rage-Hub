
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

local function safeName(n)
	local s = tostring(n or "default"):gsub("[^%w%-_ ]", "")
	if s == "" then s = "default" end
	return s
end

-- creates <ConfigFolder>/ and <ConfigFolder>/configs/ (works on every executor with file support)
function Window:_dir()
	local base = self.ConfigFolder
	pcall(function()
		if not isfolder(base) then makefolder(base) end
		if not isfolder(base .. "/configs") then makefolder(base .. "/configs") end
	end)
	return base .. "/configs"
end

function Window:_metaPath() return self.ConfigFolder .. "/meta.json" end

function Window:_loadMeta()
	local ok, raw = pcall(readfile, self:_metaPath())
	if not ok then return end
	local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(d) == "table" then
		if type(d.AutoSave) == "boolean" then self.Config.AutoSave = d.AutoSave end
		if type(d.AutoLoad) == "boolean" then self.Config.AutoLoad = d.AutoLoad end
		if type(d.Name) == "string" and d.Name ~= "" then self.Config.Name = safeName(d.Name) end
	end
end

function Window:SaveMeta()
	if not self.FilesOk then return end
	self:_dir()
	pcall(function() writefile(self:_metaPath(), HttpService:JSONEncode(self.Config)) end)
end

function Window:SaveConfig(name)
	if not self.FilesOk then return false, "this executor can't write files" end
	name = safeName(name or self.Config.Name)
	local data = {}
	if self._cfgData and self._cfgName == name then
		-- keep saved values of options that are not created (yet) so they are never lost
		for k, v in pairs(self._cfgData) do data[k] = v end
	end
	for flag, el in pairs(RageHub.Options) do
		if el.Save ~= false and el.Value ~= nil then data[flag] = encode(el.Value) end
	end
	local ok, err = pcall(function() writefile(self:_dir() .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
	return ok, err
end

function Window:LoadConfig(name)
	if not self.FilesOk then return false, "this executor can't read files" end
	name = safeName(name or self.Config.Name)
	local ok, raw = pcall(readfile, self:_dir() .. "/" .. name .. ".json")
	if not ok then return false, "config not found" end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false, "config is corrupted" end
	local was = self._loading
	self._loading = true
	self._cfgData, self._cfgName = data, name
	for flag, val in pairs(data) do
		local el = RageHub.Options[flag]
		if el and el.Set and el.Save ~= false then pcall(el.Set, el, decode(val)) end
	end
	task.delay(0.6, function() self._loading = was end)
	return true
end

-- options created after the startup load (slow scripts) still receive their saved value
function Window:_applySaved(el)
	local d = self._cfgData
	if not d or not el.Flag or el.Save == false or d[el.Flag] == nil then return end
	pcall(el.Set, el, decode(d[el.Flag]))
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

function Window:AutoLoad() return self:LoadConfig(self.Config.Name) end

function Window:_markDirty()
	if not self._ready or self._loading or not self.FilesOk or not self.Config.AutoSave then return end
	self._saveTick = (self._saveTick or 0) + 1
	local id = self._saveTick
	task.delay(1.5, function()
		if id == self._saveTick and self.Main.Parent then self:SaveConfig(self.Config.Name) end
	end)
end

--// auto execute ---------------------------------------------------------------------
-- The URL (or code) is set by the developer using Rage Hub, never by the player:
--   RageHub:CreateWindow({ AutoExecuteURL = "https://example.com/script.lua" })
function Window:SetAutoExecute(v)
	if type(v) ~= "string" or v == "" then
		self.AutoExecuteScript = nil
	elseif v:match("^https?://") then
		self.AutoExecuteScript = ('loadstring(game:HttpGet("%s"))()'):format(v)
	else
		self.AutoExecuteScript = v
	end
	if self._onAutoExec then self._onAutoExec() end
end

function Window:AutoExecuteReady() return self.AutoExecuteScript ~= nil end

function Window:QueueAutoExecute()
	if self._queued or not queueTp or not self.AutoExecuteScript then return end
	if RageHub.Flags.RH_AutoExecute == false then return end
	self._queued = pcall(queueTp, self.AutoExecuteScript)
end

--// teleport helpers -------------------------------------------------------------------
local lastOwnTeleport = 0

-- runs a teleport and waits to see if Roblox rejects it (full server, closed server, ...)
local function waitTeleport(fn, timeout)
	lastOwnTeleport = os.clock()
	local failed
	local c = TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
		failed = (msg and msg ~= "") and msg or tostring(result)
	end)
	local ok, err = pcall(fn)
	if not ok then failed = tostring(err) end
	local t0 = os.clock()
	while not failed and os.clock() - t0 < (timeout or 10) do task.wait(0.1) end
	c:Disconnect()
	return failed == nil, failed
end

local function httpJson(url)
	for attempt = 1, 3 do
		local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
		if ok and type(res) == "table" then return res end
		if attempt < 3 then task.wait(1.5 * attempt) end
	end
end

-- reads both ends of the server list (fewest first and most first) so the extremes are really there
local function collectServers()
	local seen, out = {}, {}
	local function pull(order, pages)
		local cursor
		for _ = 1, pages do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100%s")
				:format(game.PlaceId, order, cursor and ("&cursor=" .. cursor) or "")
			local res = httpJson(url)
			if not res or type(res.data) ~= "table" then return end
			for _, s in ipairs(res.data) do
				if type(s) == "table" and s.id and s.id ~= game.JobId and not seen[s.id]
					and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing < s.maxPlayers then
					seen[s.id] = true
					s.r = math.random()
					out[#out + 1] = s
				end
			end
			cursor = res.nextPageCursor
			if not cursor then return end
		end
	end
	pull("Asc", 2)
	pull("Desc", 2)
	return out
end

-- tries servers best-first; if one is full or refuses, it moves on to the next one
local function hopBlocking(mode)
	mode = mode or "Least Players"
	local servers = collectServers()
	if #servers == 0 then
		RageHub:Notify({ Title = "Server Hop", Content = "Couldn't read the server list. Trying a normal rejoin.", Type = "warning" })
		local ok, why = waitTeleport(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end, 12)
		if not ok then RageHub:Notify({ Title = "Server Hop", Content = "Failed: " .. tostring(why), Type = "error" }) end
		return ok
	end
	if mode == "Most Players" then
		table.sort(servers, function(a, b) if a.playing ~= b.playing then return a.playing > b.playing end return a.r < b.r end)
	elseif mode == "Random" then
		table.sort(servers, function(a, b) return a.r < b.r end)
	else
		table.sort(servers, function(a, b) if a.playing ~= b.playing then return a.playing < b.playing end return a.r < b.r end)
	end
	local tries = math.min(#servers, 12)
	for i = 1, tries do
		local s = servers[i]
		RageHub:Notify({ Title = "Server Hop", Content = ("Joining a server with %d/%d players..."):format(s.playing, s.maxPlayers), Type = "info", Duration = 3 })
		local ok, why = waitTeleport(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end, 12)
		if ok then return true end
		RageHub:Notify({ Title = "Server Hop", Content = ("%s. Trying another server (%d/%d)..."):format(tostring(why or "Teleport failed"), i, tries), Type = "warning", Duration = 3 })
		task.wait(0.5)
	end
	RageHub:Notify({ Title = "Server Hop", Content = "Couldn't join any server. Try again in a moment.", Type = "error" })
	return false
end

function Window:Rejoin()
	self:QueueAutoExecute()
	task.spawn(function()
		local ok = waitTeleport(function()
			if #Players:GetPlayers() > 1 and game.JobId ~= "" then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			else
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end
		end, 12)
		if not ok then hopBlocking("Random") end
	end)
end

function Window:ServerHop(mode)
	self:QueueAutoExecute()
	task.spawn(hopBlocking, mode)
end

function Window:JoinServer(jobId)
	jobId = (tostring(jobId or ""):gsub("%s", ""))
	if jobId == "" then
		RageHub:Notify({ Title = "Join Server", Content = "Paste a Job ID first.", Type = "warning" })
		return
	end
	self:QueueAutoExecute()
	task.spawn(function()
		local ok, why = waitTeleport(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer) end, 12)
		if not ok then RageHub:Notify({ Title = "Join Server", Content = tostring(why or "Couldn't join that server."), Type = "error" }) end
	end)
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

--// background features (work with or without the Settings tab) -----------------------
local function makeFeatures(win)
	local F = {}

	-- Anti AFK
	local afkConn, afkOff = nil, {}
	function F.AntiAfk(on)
		if afkConn then afkConn:Disconnect(); afkConn = nil end
		for _, c in ipairs(afkOff) do pcall(function() c:Enable() end) end
		afkOff = {}
		if not on then return end
		pcall(function()
			if getconnections then
				for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
					c:Disable()
					afkOff[#afkOff + 1] = c
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

	-- Auto Reconnect: kick, disconnect, error prompt, lost connection.
	-- 1) same server  2) any server of this game  3) hop to other servers (skips full ones)
	local conns, busy = {}, false
	local function clear()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		conns = {}
	end
	local function reconnect()
		if busy or not RageHub.Flags.RH_AutoReconnect then return end
		busy = true
		RageHub:Notify({ Title = "Auto Reconnect", Content = "Connection lost. Reconnecting...", Type = "warning", Duration = 5 })
		task.spawn(function()
			for attempt = 1, 16 do
				if not RageHub.Flags.RH_AutoReconnect then break end
				win:QueueAutoExecute()
				local ok
				if attempt <= 2 and RageHub.Flags.RH_RejoinSame ~= false and game.JobId ~= "" then
					ok = waitTeleport(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end, 12)
				elseif attempt <= 4 then
					ok = waitTeleport(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end, 12)
				else
					ok = hopBlocking("Random")
				end
				if ok then task.wait(20) end -- teleport accepted: if we are still here, it stalled
				RageHub:Notify({ Title = "Auto Reconnect", Content = ("Attempt %d failed. Trying %s..."):format(attempt, attempt < 4 and "again" or "another server"), Type = "warning", Duration = 4 })
				task.wait(math.min(2 * attempt, 10))
			end
			busy = false
		end)
	end
	local function guarded()
		if os.clock() - lastOwnTeleport < 30 then return end -- our own teleport / a game teleport, not a disconnect
		reconnect()
	end
	function F.Reconnect(on)
		clear()
		if not on then return end
		conns[#conns + 1] = GuiService.ErrorMessageChanged:Connect(function()
			local ok, msg = pcall(function() return GuiService:GetErrorMessage() end)
			if ok and msg and msg ~= "" then guarded() end
		end)
		pcall(function()
			conns[#conns + 1] = svc("NetworkClient").ChildRemoved:Connect(function()
				task.wait(2)
				guarded()
			end)
		end)
		task.spawn(function()
			local ok, overlay = pcall(function()
				return CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
			end)
			if ok and overlay and RageHub.Flags.RH_AutoReconnect then
				conns[#conns + 1] = overlay.ChildAdded:Connect(function(c)
					if c.Name == "ErrorPrompt" then guarded() end
				end)
				if overlay:FindFirstChild("ErrorPrompt") then guarded() end
			end
		end)
	end

	return F
end

function Window:_initCore(cfg)
	self.Config = { AutoSave = true, AutoLoad = true, Name = safeName(cfg.ConfigName or "default") }
	self.FilesOk = (writefile and readfile and makefolder and isfolder) and true or false
	if self.FilesOk then
		self:_dir()
		self:_loadMeta()
	end

	-- defaults: Anti AFK, Auto Reconnect and "same server first" are ON
	RageHub.Flags.RH_AntiAfk = true
	RageHub.Flags.RH_AutoReconnect = true
	RageHub.Flags.RH_RejoinSame = true
	self.F = makeFeatures(self)
	self.F.AntiAfk(true)
	self.F.Reconnect(true)
	self._onDestroy[#self._onDestroy + 1] = function()
		self.F.AntiAfk(false)
		self.F.Reconnect(false)
	end

	self.Maid:Add(LocalPlayer.OnTeleport:Connect(function()
		lastOwnTeleport = os.clock()
		self:QueueAutoExecute()
	end))

	-- startup: wait until the script finished building its UI, then auto load, then auto save
	task.spawn(function()
		local t0 = os.clock()
		repeat task.wait(0.25) until not self.Main.Parent or os.clock() - self._lastCreate > 0.8 or os.clock() - t0 > 15
		if not self.Main.Parent then return end
		if self.FilesOk then
			if self.Config.AutoLoad then
				local ok = self:LoadConfig(self.Config.Name)
				if ok then
					self:Log("Config loaded: " .. self.Config.Name, "success")
					self._lateLoad = true
				end
				task.wait(0.7)
			end
			self._ready = true
			if self.Config.AutoSave then self:SaveConfig(self.Config.Name) end
		else
			self._ready = true
			self:Log("This executor can't save files, so configs are disabled.", "warning")
		end
	end)
end

--// built-in settings tab ------------------------------------------------------------
function Window:CreateSettingsTab(opts)
	opts = opts or {}
	local win = self
	local tab = self:CreateTab(opts.Name or "Settings", opts.Icon or "settings")
	local started = os.clock()

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
		setLowGfx(false)
		pcall(function() RunService:Set3dRenderingEnabled(true) end)
	end

	--// Join & Stay ------------------------------------------------------------
	local js = tab:CreateSection("Join & Stay", "refresh")
	js:CreateToggle({
		Name = "Auto Reconnect", Description = "After a kick, disconnect or error it rejoins. If the server isn't responding it joins another one.",
		Flag = "RH_AutoReconnect", Default = true, CallOnCreate = false, Callback = function(v) win.F.Reconnect(v) end,
	})
	js:CreateToggle({
		Name = "Same Server First", Description = "Try to come back to this server before looking for another.",
		Flag = "RH_RejoinSame", Default = true,
	})

	local ready0 = win:AutoExecuteReady()
	local autoEl, autoHint, autoHelp
	local wasReady = ready0
	autoEl = js:CreateToggle({
		Name = "Auto Execute", Description = ready0 and "Runs your script again after reconnect or server hop." or "URL is not configured yet.",
		Flag = "RH_AutoExecute", Default = ready0, CallOnCreate = false,
		Callback = function(v)
			if v and not win:AutoExecuteReady() then
				autoEl:Set(false, true)
				RageHub:Notify({ Title = "Auto Execute", Content = "URL is not configured yet.", Type = "warning" })
				return
			end
			if v and not queueTp then
				RageHub:Notify({ Title = "Auto Execute", Content = "Your executor doesn't support queue_on_teleport.", Type = "error" })
			end
			win._queued = false
		end,
	})
	autoHint = js:CreateLabel({ Text = "Auto Execute URL is not configured yet.", Icon = "warning", IconColor = "Warning" })
	autoHelp = js:CreateParagraph({
		Title = "How to enable it",
		Content = 'In your script add AutoExecuteURL = "https://your.link/script.lua" inside RageHub:CreateWindow({ ... }), or call Window:SetAutoExecute("https://...").',
	})
	local function refreshAuto()
		local ready = win:AutoExecuteReady()
		autoHint:SetVisible(not ready)
		autoHelp.Row.Visible = not ready
		autoEl:SetDescription(ready and "Runs your script again after reconnect or server hop." or "URL is not configured yet.")
		if not ready and autoEl.Value then autoEl:Set(false, true) end
		if ready and not wasReady then autoEl:Set(true, true) end
		wasReady = ready
	end
	win._onAutoExec = refreshAuto
	refreshAuto()

	js:CreateToggle({
		Name = "Anti AFK", Description = "Never get kicked for being idle.",
		Flag = "RH_AntiAfk", Default = true, CallOnCreate = false, Callback = function(v) win.F.AntiAfk(v) end,
	})

	--// Server -----------------------------------------------------------------
	local sv = tab:CreateSection("Server", "server")
	local lblPlayers = sv:CreateLabel({ Text = "Players: -", Icon = "users" })
	local lblPing = sv:CreateLabel({ Text = "Ping: -", Icon = "wifi" })
	local lblSession = sv:CreateLabel({ Text = "Session: 0m 00s", Icon = "clock" })
	sv:CreateDivider()
	sv:CreateButton({ Name = "Rejoin Server", Description = "Reconnect to this exact server.", ButtonText = "Rejoin", Icon = "refresh",
		Callback = function() win:Rejoin() end })
	sv:CreateDropdown({ Name = "Hop Mode", Options = { "Least Players", "Most Players", "Random" }, Default = "Least Players", Flag = "RH_HopMode" })
	sv:CreateButton({ Name = "Server Hop", Description = "Jumps to another server. If it's full it tries the next one.", ButtonText = "Hop", Icon = "shuffle",
		Callback = function() win:ServerHop(RageHub.Flags.RH_HopMode) end })
	sv:CreateButton({ Name = "Copy Job ID", ButtonText = "Copy", Icon = "copy", Callback = function() copy(game.JobId, game.JobId) end })
	sv:CreateInput({ Name = "Join Job ID", Placeholder = "paste Job ID", Flag = "RH_JoinId", Save = false, CallOnCreate = false })
	sv:CreateButton({ Name = "Join Server", ButtonText = "Join", Icon = "login",
		Callback = function() win:JoinServer(RageHub.Flags.RH_JoinId) end })

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
	ui:CreateSlider({ Name = "Glass Transparency", Min = 0, Max = 60, Increment = 5, Default = 0, Suffix = "%", Flag = "RH_Alpha",
		Callback = function(v) win:SetTransparency(v / 100) end })
	ui:CreateKeybind({ Name = "Toggle Key", Description = "Show / hide the window (PC).", Default = self.ToggleKey, Flag = "RH_ToggleKey",
		OnChanged = function(k) win:SetToggleKey(k or Enum.KeyCode.Unknown) end })
	ui:CreateToggle({ Name = "Floating Button", Description = "Draggable button to open the menu.", Default = self.Float.Visible, Flag = "RH_Float",
		Callback = function(v) win:SetFloatingButton(v) end })
	ui:CreateToggle({ Name = "Compact Sidebar", Description = "Icons only.", Default = self.Collapsed, Flag = "RH_Compact",
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
	cf:CreateLabel({
		Text = win.FilesOk and ("Saved in " .. win.ConfigFolder .. "/configs") or "This executor can't save files.",
		Icon = win.FilesOk and "folder" or "warning", IconColor = win.FilesOk and "Accent" or "Warning",
	})
	local dd
	local function refreshList() if dd then dd:Refresh(win:ListConfigs(), true) end end
	cf:CreateToggle({ Name = "Auto Save", Description = "Saves every change automatically.", Default = win.Config.AutoSave, Flag = "RH_AutoSave", Save = false, CallOnCreate = false,
		Callback = function(v)
			win.Config.AutoSave = v
			win:SaveMeta()
			if v then win:SaveConfig(win.Config.Name); refreshList() end
		end })
	cf:CreateToggle({ Name = "Auto Load", Description = "Loads your config when the script starts.", Default = win.Config.AutoLoad, Flag = "RH_AutoLoadCfg", Save = false, CallOnCreate = false,
		Callback = function(v) win.Config.AutoLoad = v; win:SaveMeta() end })
	cf:CreateInput({ Name = "Config Name", Default = win.Config.Name, Flag = "RH_ConfigName", Save = false, CallOnCreate = false,
		Callback = function(v)
			win.Config.Name = safeName(v)
			win:SaveMeta()
		end })
	dd = cf:CreateDropdown({ Name = "Saved Configs", Options = win:ListConfigs(), Search = true, Placeholder = "none", Flag = "RH_ConfigSel", Save = false,
		Callback = function(v) if v then win.Config.Name = safeName(v); win:SaveMeta() end end })
	cf:CreateButton({ Name = "Save Config", ButtonText = "Save", Icon = "save", Callback = function()
		local ok, err = win:SaveConfig(win.Config.Name)
		if ok then
			refreshList()
			RageHub:Notify({ Title = "Config saved", Content = win.Config.Name, Type = "success", Duration = 3 })
		else
			RageHub:Notify({ Title = "Save failed", Content = tostring(err), Type = "error" })
		end
	end })
	cf:CreateButton({ Name = "Load Config", ButtonText = "Load", Icon = "download", Callback = function()
		local ok, err = win:LoadConfig(RageHub.Flags.RH_ConfigSel or win.Config.Name)
		if ok then RageHub:Notify({ Title = "Config loaded", Content = tostring(RageHub.Flags.RH_ConfigSel or win.Config.Name), Type = "success", Duration = 3 })
		else RageHub:Notify({ Title = "Load failed", Content = tostring(err), Type = "error" }) end
	end })
	cf:CreateButton({ Name = "Delete Config", ButtonText = "Delete", Icon = "trash", Danger = true, Callback = function()
		local n = RageHub.Flags.RH_ConfigSel
		if n then
			win:DeleteConfig(n)
			dd:Refresh(win:ListConfigs())
			RageHub:Notify({ Title = "Config deleted", Content = tostring(n), Type = "warning", Duration = 3 })
		end
	end })

	--// System -----------------------------------------------------------------
	local sy = tab:CreateSection("System", "power")
	sy:CreateLabel({ Text = "Rage Hub v" .. RageHub.Version, Icon = "rage" })
	sy:CreateButton({ Name = "Unload Rage Hub", Description = "Closes the UI and stops every built-in feature.", ButtonText = "Unload", Icon = "power", Danger = true,
		Callback = function() RageHub:Unload() end })

	return tab
end

