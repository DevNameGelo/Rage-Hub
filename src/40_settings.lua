
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
