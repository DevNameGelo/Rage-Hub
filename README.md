<div align="center">
<img src="assets/ragehub-icon.png" width="120" alt="Rage Hub">

# Rage Hub v1
**RGC UI Framework** · by DevNameGelo

A modular, mobile-first UI framework for Roblox scripts. One file, no UI dependencies.
Use only the parts you need; everything else costs nothing.
</div>

## Why a framework?

```
Core (always)                         Optional modules (opt-in, zero cost until enabled)
├─ windows · tabs · sections          ├─ Remote Inspector
├─ 30+ elements · tables · trees      ├─ Instance Explorer
├─ themes · state · events            ├─ Player Monitor
├─ tasks · cleanup · config           ├─ Performance Monitor
├─ logger · notifications · dialogs   ├─ Developer Console
└─ input · diagnostics · assets       └─ your own modules
```

A script that never enables the Remote Inspector never creates a single inspector object, connection or worker.

## Install

```lua
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()
```

## Quick start

```lua
local Window = RageHub:CreateWindow({ Name = "My Script", Subtitle = "v1" })

local Main = Window:CreateTab("Main", "⚡")
Main:CreateToggle({ Name = "Enabled", Callback = function(on) print(on) end })

Window:CreateSettingsTab()   -- theme, scale, toggle key, config save/load
Window:LoadConfig()          -- after all elements exist
```

More: [`Example.lua`](Example.lua) (tour) and [`examples/`](examples) — Basic, RemoteInspector, Performance, CustomModule.

## CreateWindow options

| Option | Default | Notes |
|---|---|---|
| `Name`, `Subtitle`, `Id` | `"Rage Hub"` | `Id` identifies the window (re-creating the same Id replaces it) |
| `Theme` | `"Rage"` | name or token table |
| `ToggleKey` | `RightShift` | |
| `Features` | – | `{ Logs = true, RemoteInspector = false, Notifications = true, CommandPalette = true, Settings = true }` |
| `Splash` | on | `false`, or `{ Title, Subtitle, Duration, Image = false }` (uses the theme image; tap to skip) |
| `Launcher` | touch devices | `false`, `true` or `{ Size, Position, Snap }` — floating circular icon button |
| `Branding` | official | `{ Icon, ThemeImage, Name, Tagline, Developer, Header }` |
| `Density` | `"Comfortable"` | `Compact`, `Comfortable`, `Spacious` |
| `Animation` | `"normal"` | `off`, `fast`, `normal`, `slow` |
| `Width`, `Height`, `Scale`, `Resizable` | 620×400, 1, true | size shrinks to fit the screen |
| `Sounds`, `Watermark`, `Search` | off, off, on | |
| `ConfigFolder`, `AutoSave`, `PersistWindow` | `RageHub/<Name>` | |
| `AllowMultiple` | false | otherwise a duplicate `Id` replaces the old window |
| `DebugMode`, `RandomName`, `ShowModuleEntries`, `OnUnload` | | |

## Elements

`CreateSection` · `CreateDivider` · `CreateLabel` · `CreateParagraph` · `CreateImage` · `CreateButton` · `CreateLink` · `CreateToggle` · `CreateSlider` · `CreateRangeSlider` · `CreateDropdown` · `CreatePlayerDropdown` · `CreateSegmented` · `CreateInput` · `CreateKeybind` · `CreateColorPicker` · `CreateProgressBar` · `CreateLog`

Components (created only when called): `CreateSearchBox` · `CreateIconButton` · `CreateCard` · `CreateBadge` · `CreateStatus` · `CreateStat` · `CreateMeter` · `CreateTimeline` · `CreateAccordion` · `CreateEmptyState` · `CreateSpinner` · `CreateTable` · `CreateList` · `CreateTree` · `CreateJsonViewer` · `CreateCodeViewer` · `CreateNotificationCenter` · `CreateBrand`

Every options table accepts `Name`, `Description`, `Tooltip`, `Flag`, `State`, `Locked`, `Visible`, `Callback`.
Every element returns an object: `Get` · `Set(value, silent)` · `SetName` · `SetDescription` · `SetLocked(bool, reason)` · `SetVisible` · `OnChanged` · `OnActivated` · `OnFocused` · `OnBlurred` · `OnDestroyed` · `Destroy` · `Id`.

```lua
Section:CreateToggle({ Name = "Auto Steal", State = "AutoSteal" })      -- two-way bound to Window.State
Window.State:Watch("AutoSteal", function(on) ... end)                   -- a module reacts, UI untouched
```

### Table / Tree / viewers

```lua
local t = Tab:CreateTable({ Name = "Players", Height = 240, MultiSelect = true,
    Columns = { { Key = "Name", Title = "Name", Width = 0.5 }, { Key = "Score", Title = "Score", Align = "Right" } },
    ContextMenu = function(row) return { { Text = "Copy", Callback = function() end } } end })
t:AddRow({ Name = "A", Score = 10 }); t:UpdateRow(id, { Score = 11 }); t:RemoveRow(id)
t:SetSort("Score", "desc"); t:SetSearch("a"); t:GetSelected()
```
Tables, lists, trees and the code viewer are **virtualized**: only visible rows exist, so 5 000 rows cost ~12 GUI objects.
`CreateTree({ LoadChildren = function(node) return {...} end })` loads children lazily. `CreateJsonViewer({ Value = anyLuaValue })` shows tables, Instances, Vector3, CFrame, Enums… with cycle detection. `CreateCodeViewer({ Code = "..." })` has line numbers, find, wrap, copy.

## Core services (per window)

| Service | API |
|---|---|
| `Window.State` | `Get Set Update Watch Unwatch Reset Exists Define Scope` |
| `Window.Events` | `On Once Emit` — `ModuleEnabled/Disabled/Failed`, `ThemeChanged`, `BreakpointChanged`, `Shown/Hidden`, `Notification`, `BrandingChanged`, `WindowDestroyed`… |
| `Window.Tasks` | `Create(name)` → worker `Start Stop Cancel Restart Timeout`, `Every`, `Delay`, `Spawn`, `NewGeneration/IsCurrent`; `Window:CreateToken()` |
| `Window.Cleanup` | `Add(connection / instance / function / table with Destroy) Child Clean Destroy` |
| `Window.Logger` | `Debug Info Success Warning Error Trace`, `Get(filter)`, `Subscribe`, `Scope(module)`, `Export` |
| `Window.Input` | `Bind{ Key, Mode = Press/Hold/Toggle/DoubleTap, Modifiers }`, `Capture`, `FindConflicts` — **one** shared dispatcher |
| `RageHub.Search` | `Match(query, text, "exact"/"contains"/"prefix"/"fuzzy")`, `Filter` |
| `RageHub.Clipboard` | `Copy(text)` — never throws when unsupported |

```lua
local worker = Window.Tasks:Create("Scanner")
worker:Start(function(token) while token:IsValid() do ...; task.wait(0.5) end end)
worker:Stop()                      -- cancels the token; Restart() bumps the generation, stale loops stop
```

Callbacks are error-isolated: a throwing callback is logged (`Callback error / Module / Element / Error`) and the UI keeps working.

## Modules

```lua
Window:EnableModule("RemoteInspector", { Roots = { game.ReplicatedStorage } })
Window:DisableModule("RemoteInspector")        -- stops workers, disconnects events, destroys UI, releases caches
Window:ReloadModule("Console")
Window:IsModuleEnabled("Console") · Window:GetEnabledModules() · Window:GetModuleInfo(name) · Window:GetModuleInstance(name)
RageHub:GetModules() · RageHub:GetModule(name) · RageHub:HasFeature("Tables")
```

**Built-in (all opt-in):** `RemoteInspector`, `InstanceExplorer`, `PlayerMonitor`, `Performance`, `Console` (alias `Logs`).
The Remote Inspector only *observes* (passive `OnClientEvent`); outgoing calls can be fed in with `inspector:Record(remote, "Out", ...)`. It has a separate data layer (`RageHub.RemoteData`). No hooks, stealth or bypass features.

### Writing a module

```lua
Window:RegisterModule({
    Name = "MyTool", DisplayName = "My Tool", Version = "1.0.0", Category = "Tools",
    Dependencies = { "Tables" },
    Init    = function(self, ctx) end,
    Enable  = function(self, ctx)
        local tab = ctx:CreateTab("My Tool")            -- or ctx:CreatePanel / ctx:CreateView (Tab, Panel, Float, Section, Window)
        ctx.Tasks:Every(1, function() end)              -- owned by the module
        ctx.Cleanup:Add(game:GetService("RunService").Heartbeat:Connect(function() end))
        ctx.Input:Bind({ Key = "G", Callback = function() end })
        ctx.State:Set("running", true) · ctx.Logger:Info("hi") · ctx.Config:Set("k", 1) · ctx:Notify{...}
        ctx:RegisterCommand({ Name = "My Tool: reset", Callback = function() end })
        ctx:AddSettings(function(section) ... end)      -- shown in Settings only while enabled
    end,
    Disable = function(self, ctx) end,                   -- everything registered above is cleaned up automatically
})
```
`ctx` = `RageHub, Window, Module, Options, Theme, State, Logger, Cleanup, Tasks, Events, Input, Config, Utils, Search, Clipboard, Assets`.
A module that throws never takes the window down; it is marked `Failed`, cleaned up and logged. Disabled modules keep their config (not their caches); re-enabling creates a fresh instance.

## Themes

`Rage` (default) · `Midnight` · `Crimson` · `Ocean` · `Emerald` · `Sakura` · `Sunset` · `Dracula` · `Nord` · `Void` · `Light`

```lua
Window:SetTheme("Ocean")            -- only this window
RageHub:SetTheme("Nord")            -- every window + default for new ones
RageHub:AddTheme("Mine", { Background = Color3.fromRGB(10,10,14), Accent = Color3.fromRGB(255,80,120) })   -- missing tokens get defaults
Window:SetAccent(c1, c2)
```
Tokens: `Background Surface Surface2 SurfaceHover SurfacePressed Border Text TextMuted TextDisabled Accent Accent2 Success Warning Danger Info Shadow Overlay`.

## Config

`Window:SaveConfig(name)` · `LoadConfig(name)` · `DeleteConfig` · `ListConfigs` · `ExportConfig()` · `ImportConfig(json)` · `ResetConfig()` · `AutoSave = "name"`.
Namespaced and versioned: `{ ConfigVersion, Core, Window, Elements, Modules = { Name = { Enabled, Config } } }`. Older flat configs migrate automatically. Settings for elements or modules that don't exist yet are kept and applied when they appear, so a disabled module never breaks loading. Password inputs are never saved.

## Layout, mobile & accessibility

- **Breakpoints** (`Window.Breakpoint`): Small < 520px, Medium < 820px, Large. On Small the sidebar collapses (≡ button) and right panels dock at the bottom.
- **Panels** (opt-in): `Window:CreatePanel({ Name, Dock = "Right" | "Bottom" | "Float", Size })` – dockable, detachable, elements work inside them.
- Touch: larger rows/controls, long-press tooltips and context menus, drag/resize/launcher work with fingers, no feature depends on hover, keyboardless devices get a key-picker menu.
- Locked controls are dimmed with a `LOCKED` label (and optional tooltip); status is never colour-only.
- `Window:SetDensity()`, `SetAnimation("off")`, `SetScale()`, `Maximize()`, `SetSize()`, `Focus()`.

## Branding & assets

The official images live in this repository:

```
assets/ragehub-icon.png    → floating launcher, splash logo, About card, header icon
assets/ragehub-theme.png   → splash banner, About card banner
```
`RageHub.Assets.Icon` / `.Theme` hold the raw URLs (`https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/assets/...`).
Images are downloaded **once**, cached on disk (`RageHub/assets`) and in memory, and applied with `getcustomasset`. If anything fails (no HTTP/filesystem, 404, bad image) the UI shows the built-in **RH** mark and keeps working.

```lua
Window:SetLauncherIcon("rbxassetid://123456")                     -- custom launcher icon
Window:SetBranding({ Icon = "rbxassetid://1", ThemeImage = false, Name = "My Tool", Tagline = "v2", Header = true })
RageHub:SetBranding({ ... })                                       -- default for every window
RageHub.Assets.Icon = "https://raw.githubusercontent.com/you/repo/main/icon.png"
Tab:CreateBrand({ Name = "About" })  ·  Tab:CreateImage({ Image = "Theme", Height = 120, FitMode = "Crop" })
```

## Diagnostics

`RageHub.Diagnostics:GetReport()` · `Window:GetDiagnostics()` (workers, handlers, cleanup items, rendered rows, modules…) · `Window:Diagnose()` · `RageHub.Debug:Enable(true)`.

## Tests

`tests/run_tests.sh` runs 399 checks on plain [Luau](https://github.com/luau-lang/luau) with a mocked Roblox environment (ON/OFF module cycles, leak checks, virtualization, config migration, assets, mobile behaviour, performance…). The mock cannot judge visuals; always look at the UI in a real game.

## Repository layout

```
RageHub.lua · Example.lua · README.md · CHANGELOG.md · LICENSE
assets/    ragehub-icon.png · ragehub-theme.png
examples/  Example_Basic · Example_RemoteInspector · Example_Performance · Example_CustomModule
tests/     mock.lua · 01_core · 02_elements_components · 03_modules_and_more · run_tests.sh
```

MIT · DevNameGelo · RGC
