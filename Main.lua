-- Rage Hub: Dashboard + Settings, with Auto Execute pointing at this same script
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
Name = "Rage Hub",
Subtitle = "My Game",
Version = "v1.0.0",
ToggleKey = Enum.KeyCode.RightControl,   -- PC. On mobile use the floating button
ConfigFolder = "RageHub",

-- Auto Execute: re-runs THIS script after reconnect / rejoin / server hop
AutoExecuteURL = "https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/Main.lua",
})

local Dash = Window:CreateDashboard()        -- Home: profile, session, game, executor, logs

Window:CreateTabLabel("System")
Window:CreateSettingsTab()                   -- Auto Reconnect, Auto Execute, Anti AFK, Server Hop, Config ...

RageHub:Notify({ Title = "Rage Hub", Content = "Loaded successfully", Type = "success" })
