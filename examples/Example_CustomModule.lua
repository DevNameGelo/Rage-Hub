-- Rage Hub v1 · writing your own module
-- A module gets a context with theme, state, logger, cleanup, tasks, input, config, notifications and UI builders.
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()
local Window = RageHub:CreateWindow({ Name = "Custom Module", Splash = false })

Window:RegisterModule({
    Name = "AutoCollect",
    DisplayName = "Auto Collect",
    Version = "1.0.0",
    Category = "Game",
    Dependencies = { "Tables" },                 -- core components or other modules; resolved automatically

    Init = function(self, ctx)                   -- once per enable (fresh instance every time)
        self.collected = ctx.Config:Get("collected", 0)
    end,

    Enable = function(self, ctx)
        local tab = ctx:CreateTab("Auto Collect", "★")   -- the module's UI; removed automatically on disable
        local sec = tab:CreateSection("Collector")
        local stat = sec:CreateStat({ Name = "Collected", Value = self.collected })

        sec:CreateSlider({ Name = "Interval", Flag = "interval", Range = { 1, 10 }, Default = 2 })   -- flag becomes "AutoCollect.interval"

        -- Workers are cancellable and owned by the module (stopped on disable).
        ctx.Tasks:Every(2, function(token)
            self.collected += 1
            stat:Set(self.collected)
            ctx.Config:Set("collected", self.collected)      -- persisted, survives disable/enable and config saves
            ctx.Logger:Info("collected one")
        end, "collector")

        -- Anything registered with Cleanup is released when the module is disabled.
        ctx.Cleanup:Add(game:GetService("RunService").Heartbeat:Connect(function() end))
        ctx.Input:Bind({ Key = "C", Callback = function() ctx:Notify({ Title = "Collect!", Duration = 1 }) end })
        ctx:RegisterCommand({ Name = "Auto Collect: reset", Callback = function() self.collected = 0; stat:Set(0) end })
        ctx:AddSettings(function(section) section:CreateToggle({ Name = "Notify on collect" }) end)
        ctx.State:Set("running", true)
    end,

    Disable = function(self, ctx) ctx.State:Set("running", false) end,
})

Window:CreateSettingsTab()
Window:EnableModule("AutoCollect")      -- later: Window:DisableModule("AutoCollect"), Window:ReloadModule(...)
