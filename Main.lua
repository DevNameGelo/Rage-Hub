-- Rage Hub: Dashboard + Settings (Anti AFK, Auto Reconnect, Server Hop, Config ... appear automatically)
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
	Name = "Rage Hub",
	Subtitle = "My Game",
	Version = "v1.0.0",
	ToggleKey = Enum.KeyCode.RightControl,   -- PC. On mobile use the floating button
	ConfigFolder = "RageHub",
})

local Dash = Window:CreateDashboard()        -- Home: profile, session, game, executor, logs

Window:CreateTabLabel("System")
local Settings = Window:CreateSettingsTab()  -- all built-in features appear by themselves

-- optional: Auto Execute (YOU set the URL of this script)
-- Settings:AddAutoExecute({ URL = "https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/Main.lua" })

-- optional: add your own settings
-- Settings:CreateSection("My Options", "star"):CreateToggle({ Name = "Auto Collect", Flag = "AutoCollect" })

RageHub:Notify({ Title = "Rage Hub", Content = "Loaded successfully", Type = "success" })
