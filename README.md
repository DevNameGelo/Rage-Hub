<p align="center"><img src="assets/logo.png" width="120" alt="Rage Hub"></p>

<h1 align="center">Rage Hub</h1>
<p align="center">A modern, clean, lag-friendly Roblox UI library for <b>mobile and PC</b>.<br>
165 built-in vector icons (no emoji, no asset ids) · 7 themes · built-in Settings tab</p>

```lua
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()
```

## Features

- **Mobile + PC**: auto scales to the screen, touch-friendly rows, draggable and resizable window, floating open button, collapsible sidebar, 1 or 2 column pages depending on width.
- **Built for low lag**: no per-frame loops, drag handlers only exist while a finger/mouse is down, popups are built lazily and reused, notification cap, and a *Reduce Animations* switch that turns every tween into an instant set.
- **165 real icons**: drawn with Frames from a 24x24 vector grid, tintable and sharp at any size. Preview in [ICONS.md](ICONS.md).
- **Elements**: Toggle, Slider (with typeable value), Dropdown (single / multi / search), Button, Input, Keybind, Color Picker, Label, Paragraph, Divider.
- **Global search**, collapsible sections, notifications, themes (live switching), transparency and scale sliders.
- **Config system** with save / load / delete / auto load.
- **Built-in Settings tab** (one line): Auto Rejoin, Rejoin Same Server, Auto Execute, Anti AFK, Server Hop (least / most / random), Rejoin, Copy / Join Job ID, UI Scale, Transparency, Theme, Toggle Key, Floating Button, Reduce Animations, FPS Cap, Low Graphics, White Screen, Config manager, Unload.

## Quick start

```lua
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/RageHub.lua"))()

local Window = RageHub:CreateWindow({
    Name = "Rage Hub",
    Subtitle = "My Game",
    Theme = "Rage",                          -- Rage, Crimson, Ocean, Emerald, Sakura, Midnight, Light
    ToggleKey = Enum.KeyCode.RightControl,   -- PC only, mobile uses the floating button
    AutoExecuteScript = 'loadstring(game:HttpGet("https://example.com/my_script.lua"))()',
})

local Tab = Window:CreateTab("Farm", "sprout")          -- any icon name from ICONS.md
local Section = Tab:CreateSection("Auto Farm", "zap")

Section:CreateToggle({
    Name = "Auto Farm", Description = "Farms for you.", Flag = "AutoFarm", Default = false,
    Callback = function(on) print(on) end,
})

Window:CreateTabLabel("System")
Window:CreateSettingsTab()      -- Auto Rejoin, Auto Execute, Anti AFK, Server Hop, FPS, Config ...
Window:AutoLoad()               -- loads the config marked "Auto Load"
```

A full example is in [`examples/Example.lua`](examples/Example.lua).

## API

### Library
| Call | Description |
|---|---|
| `RageHub:CreateWindow(cfg)` | `Name, Subtitle, Version, Theme, Size (Vector2), ToggleKey, ConfigFolder, AutoExecuteScript, FloatingButton, StartHidden` |
| `RageHub:Notify({Title, Content, Type, Duration, Icon})` | `Type`: `info`, `success`, `warning`, `error` |
| `RageHub:SetTheme(name)` / `RageHub:AddTheme(name, colors)` | Live theme switching, custom themes (keys: `Bg Panel Card Elevated Stroke Text SubText Muted Accent Accent2`) |
| `RageHub:CreateIcon(parent, name, size, color)` | Use the icons in your own UI. `color` can be a `Color3` or a theme key like `"Accent"` |
| `RageHub:GetIcons()` / `RageHub:HasIcon(name)` | List icon names |
| `RageHub.Flags` / `RageHub.Options` | Current values / element objects by `Flag` |
| `RageHub:Unload()` | Remove everything |

### Window
`Window:CreateTab(name, icon)` · `Window:CreateTabLabel(text)` · `Window:CreateSettingsTab()` · `Window:SelectTab(tabOrName)` · `Window:Toggle()` · `Window:SetVisible(bool)` · `Window:SetScale(n)` · `Window:SetTransparency(0-0.8)` · `Window:SetToggleKey(key)` · `Window:Notify(cfg)` · `Window:Rejoin()` · `Window:ServerHop("Least Players" | "Most Players" | "Random")` · `Window:JoinServer(jobId)` · `Window:SaveConfig(name)` · `Window:LoadConfig(name)` · `Window:DeleteConfig(name)` · `Window:ListConfigs()` · `Window:AutoLoad()` · `Window:Destroy()`

### Tab / Section
`Tab:CreateSection(name, icon, {Side = "Left" | "Right"})`. You can also call any element directly on a tab and it goes into a default section.

| Element | Config | Methods |
|---|---|---|
| `CreateToggle` | `Name, Description, Default, Flag, Callback(bool)` | `Set(bool)` |
| `CreateSlider` | `Name, Min, Max, Increment, Default, Suffix, Flag, Callback(number)` | `Set(n)` |
| `CreateDropdown` | `Name, Options, Default, Multi, Search, Flag, Callback(value)` | `Set(v)`, `Refresh(options, keepValue)` |
| `CreateButton` | `Name, Description, ButtonText, Icon, Danger, Callback()` | `Fire()` |
| `CreateInput` | `Name, Default, Placeholder, Numeric, Flag, Callback(text)` | `Set(v)` |
| `CreateKeybind` | `Name, Default (KeyCode), Flag, Callback(key) (on press), OnChanged(key)` | `Set(key)` |
| `CreateColorPicker` | `Name, Default (Color3), Flag, Callback(color)` | `Set(color)` |
| `CreateLabel` | `Text, Icon` | `Set(text)` |
| `CreateParagraph` | `Title, Content` | `Set(title, content)` |
| `CreateDivider` | - | - |

Every element also has `SetName`, `SetDescription`, `SetVisible`, `Destroy`, and `.Value`.
Callbacks run once on creation with the default value; pass `CallOnCreate = false` to skip that. `Save = false` keeps an element out of configs.

## Auto Execute notes

Auto Execute uses your executor's `queue_on_teleport`. It queues your script when a teleport starts (Auto Rejoin, Server Hop, Rejoin and game teleports all count). Rejoining by hand from the Roblox menu does not fire a teleport, so use the built-in Rejoin button instead. Executors without `queue_on_teleport` get a clear notification instead of a silent failure.

## Repo layout

```
RageHub.lua          <- the library (this is the file the raw URL loads)
examples/Example.lua
assets/logo.png|svg  assets/icons-preview.png
ICONS.md             all icon names
src/                 library sources (split by area)
tools/gen_icons.py   icon source of truth + preview/logo generator
tools/build.py       rebuilds RageHub.lua from src/
```

Change icons: edit `tools/gen_icons.py`, run `python3 tools/gen_icons.py && python3 tools/build.py`.

MIT licensed.
