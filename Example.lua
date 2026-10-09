-- Rage Hub v1 · tour: core UI, state binding, notifications, logs, themes, config, branding,
-- a custom module and dynamic module enabling. (Focused examples live in /examples.)
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
    Name = "Rage Hub",
    Subtitle = "RGC UI Framework · v" .. RageHub.Version,
    Theme = "Rage",
    ConfigFolder = "RageHub/Tour",
    AutoSave = "autosave",
    Splash = { Subtitle = "Loading tour..." },        -- uses the official theme image
    Features = { Notifications = true },              -- everything else is opt-in
})

---------------------------------------------------------------- core UI + state
local Main = Window:CreateTab("Main", "⚡")
local Core = Main:CreateSection("Core")
Core:CreateToggle({ Name = "Auto Steal", State = "AutoSteal", Description = "Bound to Window.State.AutoSteal", Keybind = Enum.KeyCode.V })
Core:CreateSlider({ Name = "Range", Flag = "Range", Range = { 5, 100 }, Default = 25, Suffix = " studs" })
Core:CreateSegmented({ Name = "Priority", Flag = "Priority", Options = { "Nearest", "Rarest", "Richest" }, Default = "Nearest" })
Core:CreatePlayerDropdown({ Name = "Target", Flag = "Target" })
Window.State:Watch("AutoSteal", function(on) Window.Logger:Info("Tour", "AutoSteal = " .. tostring(on)) end)

local Stats = Main:CreateSection("Live")
local progress = Stats:CreateProgressBar({ Name = "Cooldown", Max = 100, Suffix = "%" })
Window.Tasks:Every(0.5, function() progress:Set((os.clock() * 10) % 100) end, "demo-progress")   -- owned + cancelled with the window

---------------------------------------------------------------- notifications / dialogs
local Msg = Main:CreateSection("Feedback")
Msg:CreateButton({ Name = "Notification", ButtonText = "Show", Callback = function()
    Window:Notify({ Title = "Hello!", Content = "Notifications queue, stack and can have buttons.", Type = "success",
        Buttons = { { Text = "Nice", Callback = function() print("clicked") end } } })
end })
Msg:CreateButton({ Name = "Progress notification", ButtonText = "Run", Callback = function()
    local n = Window:Notify({ Title = "Working...", Type = "progress" })
    local t = 0
    Window.Tasks:Every(0.3, function(token) t += 0.1; n:SetProgress(t); if t >= 1 then token:Cancel() end end)
end })
Msg:CreateButton({ Name = "Destructive dialog", ButtonText = "Open", Callback = function()
    Window:Dialog({ Type = "Destructive", Title = "Wipe data?", Content = "This cannot be undone.", Callback = function() Window:Notify({ Title = "Wiped" }) end })
end })

---------------------------------------------------------------- dynamic modules (opt-in)
local Mods = Window:CreateTab("Modules", "▣")
local Opt = Mods:CreateSection("Enable only what you need")
Opt:CreateToggle({ Name = "Developer console", Description = "Live logs, filters, search, export", Callback = function(on) Window:ToggleModule("Console", on) end })
Opt:CreateToggle({ Name = "Performance monitor", Callback = function(on) Window:ToggleModule("Performance", on) end })

---------------------------------------------------------------- a custom module
Window:RegisterModule({
    Name = "Greeter", DisplayName = "Greeter",
    Enable = function(self, ctx)
        local tab = ctx:CreateTab("Greeter", "☺")
        tab:CreateButton({ Name = "Greet", ButtonText = "Hi", Callback = function() ctx:Notify({ Title = "Hello from a custom module" }) end })
        ctx.Logger:Success("Greeter ready")
    end,
})
Opt:CreateToggle({ Name = "Custom module (Greeter)", Callback = function(on) Window:ToggleModule("Greeter", on) end })

---------------------------------------------------------------- about / branding / settings / config
local About = Window:CreateTab("About", "ℹ")
About:CreateBrand({ Name = "About" })               -- official icon + theme image, name, developer, version
About:CreateLink({ Name = "GitHub", Url = "https://github.com/devnamegelo/Rage-Hub" })
-- Custom branding for YOUR script (launcher icon + banner):
--   Window:SetBranding({ Icon = "rbxassetid://123456", ThemeImage = false, Name = "My Tool" })

Window:EnableCommandPalette()                        -- Ctrl+K
Window:CreateSettingsTab()
Window:LoadConfig()
Window:Notify({ Title = "Rage Hub v" .. RageHub.Version, Content = "Press RightShift to hide / show.", Type = "success" })
