-- Rage Hub v1 · Basic: the smallest useful script. No modules, no extra tabs.
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
    Name = "My Script",
    Subtitle = "Basic example",
    Theme = "Rage",                      -- the default; see RageHub:GetThemes()
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main", "⚡")
local Player = Main:CreateSection("Player")

-- State binding is optional: the toggle and Window.State "AutoFarm" stay in sync both ways.
Player:CreateToggle({
    Name = "Auto Farm",
    State = "AutoFarm",
    Keybind = Enum.KeyCode.V,            -- optional hotkey chip
    Callback = function(on)
        Window:Notify({ Title = on and "Auto Farm ON" or "Auto Farm OFF", Type = on and "success" or "info", Duration = 2 })
    end,
})
Player:CreateSlider({ Name = "Walk Speed", Flag = "Speed", Range = { 16, 120 }, Default = 16, Callback = function(v) print("speed", v) end })
Player:CreateDropdown({ Name = "Mode", Flag = "Mode", Options = { "Safe", "Fast", "Turbo" }, Default = "Safe" })
Player:CreateButton({ Name = "Say hi", ButtonText = "Hi", Callback = function() Window:Notify({ Title = "Hello from Rage Hub!" }) end })

-- Something else reacts to the state, without touching the UI:
Window.State:Watch("AutoFarm", function(on) print("AutoFarm is now", on) end)

Window:CreateSettingsTab()   -- theme, scale, toggle key, config save/load
Window:LoadConfig()          -- after all elements exist (safe if no config yet)
