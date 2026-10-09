-- Rage Hub v1 · Remote Inspector (opt-in module)
-- Nothing from the inspector exists until it is enabled. It only OBSERVES (passive OnClientEvent).
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
    Name = "Remote Inspector",
    Subtitle = "developer tool",
    Splash = false,
    Features = { RemoteInspector = true },        -- or: Window:EnableModule("RemoteInspector", { Roots = { game.ReplicatedStorage } })
})

local inspector = Window:GetModuleInstance("RemoteInspector")

-- Your own wrappers can feed outgoing calls into the same traffic table:
local function fire(remote, ...)
    inspector:Record(remote, "Out", ...)
    remote:FireServer(...)
end

-- The data layer is reusable without the UI:
--   inspector.Data.Remotes / inspector.Data.Traffic / RageHub.RemoteData.Snippet(entry)

Window:CreateSettingsTab()     -- shows "Remote Inspector Settings" only while the module is enabled
Window:EnableCommandPalette()  -- Ctrl+K -> "Open Remote Inspector", "Clear Remote Traffic", ...
