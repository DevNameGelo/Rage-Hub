-- Rage Hub example  (Steal an Egg style hub)
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
	Name = "Rage Hub",
	Subtitle = "Steal an Egg",
	Version = "v1.0.0",
	Theme = "Rage",                 -- Rage, Crimson, Ocean, Emerald, Sakura, Midnight, Light
	ToggleKey = Enum.KeyCode.RightControl,
	ConfigFolder = "RageHub",
	-- script that Auto Execute re-runs after rejoin / server hop:
	AutoExecuteScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/examples/Example.lua"))()',
})

---------------------------------------------------------------- Home
local Home = Window:CreateTab("Home", "home")
local Info = Home:CreateSection("Session", "activity")
local stolen = Info:CreateLabel({ Text = "Stolen: 0", Icon = "egg" })
Info:CreateParagraph({ Title = "Welcome", Content = "Rage Hub is lightweight, mobile friendly and themeable. Use the search box to find any option." })

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
Steal:CreateSlider({ Name = "Min $/s", Min = 0, Max = 1000, Increment = 10, Default = 0, Suffix = "", Flag = "MinIncome" })

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

---------------------------------------------------------------- built-in settings (Auto Rejoin, Auto Execute, Anti AFK, Server Hop, FPS, Config...)
Window:CreateTabLabel("System")
Window:CreateSettingsTab()

Window:AutoLoad()
RageHub:Notify({ Title = "Rage Hub", Content = "Loaded successfully", Type = "success" })
