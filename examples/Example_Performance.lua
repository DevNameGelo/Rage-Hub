-- Rage Hub v1 · Performance + Console, toggled at runtime
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({ Name = "Monitor", Splash = false })
local Tools = Window:CreateTab("Tools", "◔")
local Sec = Tools:CreateSection("Optional modules")

-- Enabling creates the tab, workers and listeners. Disabling removes ALL of it again.
Sec:CreateToggle({
    Name = "Performance monitor", Description = "FPS, ping, memory, framework counters",
    Callback = function(on) Window:ToggleModule("Performance", on) end,
})
Sec:CreateToggle({
    Name = "Developer console", Description = "Filterable live log",
    Callback = function(on) Window:ToggleModule("Console", on) end,
})

Window.Events:On("ModuleEnabled", function(name) Window.Logger:Info("Demo", name .. " enabled") end)
Window.Events:On("ModuleDisabled", function(name) Window.Logger:Info("Demo", name .. " disabled") end)
print(#Window:GetEnabledModules(), "modules enabled")   -- 0: nothing is enabled by default
