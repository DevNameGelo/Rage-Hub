-- Rage Hub v2 · full showcase
-- After uploading RageHub.lua to your repo, point this URL at it.
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/rgcmainhub/Rage-Hub/main/RageHub.lua"))()

local Players = game:GetService("Players")
local function humanoid()
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Window = RageHub:CreateWindow({
    Name = "Rage Hub",
    Subtitle = "Showcase · v2.0.0",
    Theme = "Midnight",              -- Midnight, Crimson, Ocean, Emerald, Sakura, Sunset, Dracula, Nord, Void, Light
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "RageHub/Showcase",
    AutoSave = "autosave",           -- saves on every change (call Window:LoadConfig() at the end)
    Splash = { Title = "Rage Hub", Subtitle = "Loading showcase...", Duration = 1.2 },
    Watermark = { Text = "Rage Hub", ShowFPS = true, ShowPing = true },
})

----------------------------------------------------------------- PLAYER
local Player = Window:CreateTab("Player", "⚡")

local Move = Player:CreateSection("Movement")
Move:CreateToggle({
    Name = "Speed Boost",
    Description = "Faster walk speed",
    Flag = "SpeedOn",
    Keybind = Enum.KeyCode.V,        -- optional hotkey chip on the toggle
    Tooltip = "Toggle with the V key",
    Callback = function(on)
        local h = humanoid()
        if h then h.WalkSpeed = on and (Window.Flags.Speed or 32) or 16 end
    end,
})
Move:CreateSlider({
    Name = "Walk Speed", Flag = "Speed", Range = { 16, 150 }, Increment = 1, Suffix = " sp", Default = 32,
    Callback = function(v)
        local h = humanoid()
        if h and Window.Flags.SpeedOn then h.WalkSpeed = v end
    end,
})
Move:CreateRangeSlider({
    Name = "Jump Power Range", Flag = "JumpRange", Range = { 30, 200 }, Default = { 50, 120 },
    Callback = function(lo, hi) print("jump range", lo, hi) end,
})
Move:CreateSegmented({
    Name = "Movement Mode", Flag = "Mode", Options = { "Walk", "Fly", "Noclip" }, Default = "Walk",
    Callback = function(v) print("mode:", v) end,
})

local Targets = Player:CreateSection("Targeting")
Targets:CreatePlayerDropdown({
    Name = "Target Player", Flag = "Target", Tooltip = "Auto-updates as players join / leave",
    Callback = function(name) print("target:", name) end,
})
Targets:CreateDropdown({
    Name = "Teleport To", Flag = "Place", Search = true,
    Options = { "Spawn", "Shop", "Arena", "Lobby", "Bank", "Cave", "Island", "Tower", "Dock", "Castle" },
    Callback = function(v) print("tp:", v) end,
})
Targets:CreateDropdown({
    Name = "Filters", Flag = "Filters", Multi = true, Options = { "Players", "NPCs", "Items", "Chests" }, Default = { "Players" },
    Callback = function(list) print("filters:", table.concat(list, ", ")) end,
})
Targets:CreateKeybind({
    Name = "Hold to Aim", Flag = "AimKey", Mode = "Hold", Default = Enum.KeyCode.E,
    Callback = function(held) print("aim held:", held) end,
})

local Actions = Player:CreateSection("Actions")
Actions:CreateButton({
    Name = "Reset Character", ButtonText = "Reset", Confirm = "Reset your character?", Cooldown = 3,
    Callback = function()
        local h = humanoid()
        if h then h.Health = 0 end
        Window:Notify({ Title = "Character reset", Type = "warning" })
    end,
})

----------------------------------------------------------------- VISUALS
local Visuals = Window:CreateTab("Visuals", "◉")
local Colors = Visuals:CreateSection("Colors")
Colors:CreateColorPicker({
    Name = "ESP Color", Flag = "EspColor", Default = Color3.fromRGB(255, 80, 120),
    Callback = function(c) print("esp color", c) end,
})
Colors:CreateInput({ Name = "Label Text", Flag = "LabelText", Default = "Rage", Placeholder = "ESP label..." })
Colors:CreateInput({ Name = "Max Distance", Flag = "MaxDist", Numeric = true, Default = 500 })

local Stats = Visuals:CreateSection("Live Stats")
local fuel = Stats:CreateProgressBar({ Name = "Boost Fuel", Default = 100, Suffix = "%" })
task.spawn(function()
    while Window.Gui and Window.Gui.Parent do   -- stops when the window is destroyed
        for v = 100, 0, -10 do fuel:Set(v); task.wait(0.4) end
        for v = 0, 100, 10 do fuel:Set(v); task.wait(0.2) end
    end
end)

----------------------------------------------------------------- CONSOLE
local Console = Window:CreateTab("Console", "▶")
local log = Console:CreateLog({ Name = "Output", Height = 170 })
log:Add("Rage Hub ready.")
Window:OnChanged(function(flag, value)                -- every flagged element reports here
    log:Add(("%s = %s"):format(flag, tostring(typeof(value) == "table" and table.concat(value, ", ") or value)))
end)
Console:CreateButton({ Name = "Clear Log", ButtonText = "Clear", Callback = function() log:Clear() end })

----------------------------------------------------------------- ABOUT
local About = Window:CreateTab("About", "ℹ")
About:CreateParagraph({ Title = "Rage Hub", Content = "A modern, mobile-friendly UI library for Roblox. One file, no dependencies. Themes, configs, search, tooltips and more." })
About:CreateLink({ Name = "GitHub", Url = "https://github.com/rgcmainhub/Rage-Hub" })
About:CreateDivider("Tips")
About:CreateLabel("Tap a section title to collapse it")
About:CreateLabel("Drag the ◢ corner to resize the window")
About:CreateButton({
    Name = "Test Notification", ButtonText = "Show",
    Callback = function()
        Window:Notify({
            Title = "Hello!", Content = "Notifications can have buttons.", Type = "success", Duration = 6,
            Buttons = { { Text = "Nice", Callback = function() print("clicked") end } },
        })
    end,
})

-- Built-in Settings: themes, accent, scale, transparency, toggle key, sounds,
-- watermark, config save/load/export/import, reset position, unload.
Window:CreateSettingsTab()

Window:LoadConfig()   -- restore previous session (call AFTER all elements exist)
Window:Notify({ Title = "Rage Hub loaded", Content = "Press RightShift to hide / show.", Type = "success" })
