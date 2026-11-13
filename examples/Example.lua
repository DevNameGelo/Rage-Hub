-- Rage Hub example (Steal an Egg style hub)
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
	Name = "Rage Hub",
	Subtitle = "Steal an Egg",
	Version = "v1.0.0",
	ToggleKey = Enum.KeyCode.RightControl,   -- PC. On mobile use the floating button
	ConfigFolder = "RageHub",                -- config files go to <executor workspace>/RageHub/configs

	-- AUTO EXECUTE: put the link of YOUR script here (the script that loads this hub).
	-- Rage Hub re-runs it after reconnect / rejoin / server hop.
	-- Leave it out and the Auto Execute option shows "URL is not configured yet".
	AutoExecuteURL = "https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/examples/Example.lua",
})

---------------------------------------------------------------- Dashboard (fully customizable)
local Dash = Window:CreateDashboard({
	-- turn default widgets off if you don't want them:
	-- Widgets = { Profile = false, Overview = true, Game = true, Actions = true, Activity = true },
})

-- your own stat tiles
local eggs = Dash:AddStat({ Id = "Eggs", Name = "Eggs Stolen", Value = 0, Icon = "egg" })
local income = Dash:AddStat({ Id = "Income", Name = "Income", Value = "$0/s", Icon = "coin" })

-- your own log (the default Activity log is also there)
local EggLog = Dash:CreateLog({ Name = "Egg Steals", Icon = "egg", Empty = "No eggs stolen yet." })

-- update notes
Dash:AddUpdate({ Version = "v1.0.0", Title = "Release", Text = "First release of the hub.", Date = "Nov 2026" })

-- extra buttons (the default dashboard has NO Discord button, add it if you want one)
Dash:AddButton({
	Name = "Discord", Description = "Copy the invite link.", ButtonText = "Copy", Icon = "chat",
	Callback = function()
		if setclipboard then setclipboard("https://discord.gg/yourinvite") end
		RageHub:Notify({ Title = "Copied", Content = "Discord invite copied.", Type = "success" })
	end,
})

-- remove a default widget:
-- Dash:RemoveWidget("Profile")

-- later in your farm loop:
local stolen = 0
local function onEggStolen(name)
	stolen = stolen + 1
	eggs:Set(stolen)
	EggLog:Add("Stole " .. name, "success")
end

---------------------------------------------------------------- Eggs
local Eggs = Window:CreateTab("Eggs", "egg")

local Steal = Eggs:CreateSection("Auto Steal", "zap")
Steal:CreateToggle({
	Name = "Auto Steal", Description = "Steals eggs automatically.", Flag = "AutoSteal",
	Callback = function(on) print("Auto steal:", on) end,
})
Steal:CreateDropdown({
	Name = "Delivery Method", Options = { "Fast Tween", "Teleport", "Walk" }, Default = "Fast Tween", Flag = "Delivery",
	Callback = function(v) print("Delivery:", v) end,
})
Steal:CreateDropdown({
	Name = "Zones", Options = { "Alien", "Cherry Blossom", "Lagoon", "Hollow", "Candy" }, Multi = true, Default = { "Alien" }, Flag = "Zones",
	Callback = function(list) print("Zones:", table.concat(list, ", ")) end,
})
Steal:CreateSlider({ Name = "Min $/s", Min = 0, Max = 1000, Increment = 10, Default = 0, Flag = "MinIncome" })

local Filter = Eggs:CreateSection("Filter", "filter")
Filter:CreateDropdown({ Name = "Rarities", Options = { "Common", "Rare", "Epic", "Legendary", "Divine" }, Multi = true, Flag = "Rarities" })
Filter:CreateToggle({ Name = "Sell Cheapest Egg", Description = "Makes room when the egg bag is full.", Flag = "SellCheapest" })

---------------------------------------------------------------- Farm / Player / Visuals
local Farm = Window:CreateTab("Farm", "sprout")
Farm:CreateSection("Collect", "coin"):CreateToggle({ Name = "Auto Collect Cash", Flag = "AutoCash" })

local Player = Window:CreateTab("Player", "user")
local Move = Player:CreateSection("Movement", "run")
Move:CreateSlider({ Name = "Walk Speed", Min = 16, Max = 200, Default = 16, Flag = "WalkSpeed", CallOnCreate = false,
	Callback = function(v)
		local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end })
Move:CreateKeybind({ Name = "Fly Key", Default = Enum.KeyCode.F, Flag = "FlyKey", Callback = function() print("fly!") end })

local Visuals = Window:CreateTab("Visuals", "eye")
Visuals:CreateSection("ESP", "target"):CreateColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(139, 92, 246), Flag = "EspColor",
	Callback = function(c) print("ESP color", c) end })

---------------------------------------------------------------- built-in settings
-- Auto Reconnect, Anti AFK, Auto Execute, Server Hop, FPS, Config ... (Anti AFK + Auto Reconnect are ON by default)
-- Configs are saved and loaded automatically, nothing else to call.
Window:CreateTabLabel("System")
Window:CreateSettingsTab()

RageHub:Notify({ Title = "Rage Hub", Content = "Loaded successfully", Type = "success" })
