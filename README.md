<div align="center">

# Rage Hub

**A modern, mobile-friendly UI library for Roblox script hubs.**
One file · no dependencies · 10 themes · config saving · works on touch and PC

</div>

## Features

- Glass dark UI with animated accent line, sidebar tabs, tab icons, per-tab **search**
- Elements: Toggle (+ hotkey chip), Button (+ confirm / cooldown), Slider, **Range Slider**, Dropdown (single / multi / searchable), **Player Dropdown**, **Segmented**, Input, Keybind (Press / Hold / Toggle), Color Picker (+ hex), **Progress Bar**, **Log**, Image, Label, Paragraph, Link, Divider, collapsible Sections
- Notifications (with buttons), modal dialogs, tooltips, watermark (FPS / ping), splash screen
- 10 built-in themes, live switching, custom themes, custom accent
- Resizable and draggable window, collapsible sidebar, UI scale, minimize, floating **R** launcher on mobile
- Config system: save / load / delete / auto-save / JSON export & import
- Built-in **Settings tab** that wires all of the above for you

## Install

```lua
local RageHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/rgcmainhub/Rage-Hub/main/RageHub.lua"))()
```

## Quick start

```lua
local Window = RageHub:CreateWindow({
    Name = "My Hub",
    Subtitle = "v1.0",
    Theme = "Midnight",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Tab = Window:CreateTab("Main", "⚡")
local Section = Tab:CreateSection("Player")

Section:CreateToggle({
    Name = "God Mode",
    Flag = "God",            -- saved in configs, readable via Window.Flags.God
    Default = false,
    Callback = function(on) print(on) end,
})

Window:CreateSettingsTab()
Window:LoadConfig()          -- after all elements exist
```

See [`Example.lua`](Example.lua) for every element.

## Window options

| Option | Type | Default | Notes |
|---|---|---|---|
| `Name` | string | `"Rage Hub"` | Title |
| `Subtitle` | string | `""` | Small text under the title |
| `Theme` | string / table | `"Midnight"` | Built-in name or a colors table |
| `ToggleKey` | KeyCode | `RightShift` | Show / hide key |
| `Width`, `Height` | number | `620`, `400` | Max size (shrinks on small screens) |
| `Scale` | number | `1` | UI scale (0.6 – 1.5) |
| `Splash` | bool / table | on | `false` to skip, or `{Title, Subtitle, Duration}` |
| `Watermark` | bool / table | off | `{Text, ShowFPS, ShowPing}` |
| `Launcher` | bool | touch devices | Floating draggable **R** button |
| `Resizable` | bool | `true` | Drag the ◢ corner |
| `Search` | bool | `true` | Search box in the sidebar |
| `Sounds` | bool | `false` | UI sounds |
| `ConfigFolder` | string | `RageHub/<Name>` | Where configs are stored |
| `AutoSave` | string | `nil` | Config name to save to on every change |
| `RandomName` | bool | `true` | Randomised ScreenGui name |
| `OnUnload` | function | `nil` | Called when the window is destroyed |

## Elements

Create elements on a **Tab** or a **Section** (`Tab:CreateSection("Name", {Collapsed = false})`).
Every options table accepts `Name`, `Description`, `Tooltip`, `Flag`, `Locked`, `Visible`, `Callback`.

| Method | Extra options | Callback receives |
|---|---|---|
| `CreateButton` | `ButtonText`, `Confirm`, `Cooldown` | – |
| `CreateToggle` | `Default`, `Keybind` | `boolean` |
| `CreateSlider` | `Range`, `Increment`, `Suffix`, `Default` | `number` |
| `CreateRangeSlider` | `Range`, `Increment`, `Suffix`, `Default = {lo, hi}` | `lo, hi` |
| `CreateDropdown` | `Options`, `Default`, `Multi`, `Search`, `MaxHeight` | `string` or `{strings}` |
| `CreatePlayerDropdown` | same as Dropdown, `IncludeSelf` | `string` |
| `CreateSegmented` | `Options`, `Default` | `string` |
| `CreateInput` | `Default`, `Placeholder`, `Numeric`, `Width`, `OnlyOnEnter`, `ClearOnEnter` | `value, enterPressed` |
| `CreateKeybind` | `Default`, `Mode` (`Press`/`Hold`/`Toggle`), `OnChange` | key / held state |
| `CreateColorPicker` | `Default` | `Color3` |
| `CreateProgressBar` | `Default`, `Max`, `Suffix` | – |
| `CreateLog` | `Height`, `MaxLines`, `Timestamps` | – |
| `CreateImage` | `Image`, `Height`, `Crop` | – |
| `CreateLink` | `Url` | copies to clipboard |
| `CreateLabel(text)` · `CreateParagraph{Title, Content}` · `CreateDivider(text?)` | | |

Every element returns an object: `:Get()` · `:Set(value, silent)` · `:SetName()` · `:SetDescription()` · `:SetLocked(bool)` · `:SetVisible(bool)` · `:OnChanged(fn)` · `:Destroy()`.
Dropdowns also have `:Refresh(options, keepSelection)`; Logs have `:Add(text, color?)` / `:Clear()`; Progress bars `:Set(n)`.

## Window methods

```lua
Window:Notify({ Title = "Hi", Content = "Text", Type = "info", Duration = 4,   -- info | success | warning | error
                Buttons = { { Text = "Undo", Callback = function() end } } })
Window:Dialog({ Title = "Sure?", Content = "...", Buttons = { { Text = "No" }, { Text = "Yes", Primary = true, Callback = fn } } })
Window:CreateSettingsTab("Settings")
Window:CreateWatermark({ Text = "My Hub" })
Window:CreateTabLabel("Group")            -- small heading in the sidebar
Window:OnChanged(function(flag, value) end)
Window:SaveConfig("name")  Window:LoadConfig("name")  Window:DeleteConfig("name")  Window:ListConfigs()
Window:ExportConfig()      Window:ImportConfig(jsonString)
Window:SetVisible(bool)  Window:Toggle()  Window:SetMinimized(bool)  Window:SetSidebarCollapsed(bool)
Window:SetSize(w, h)  Window:SetScale(1.1)  Window:SetTitle("x")  Window:SetSubtitle("x")  Window:SelectTab("Main")
Window:Destroy()
RageHub:SetTheme("Ocean")   RageHub:SetAccent(Color3, Color3?)   RageHub:DestroyAll()
```

## Themes

`Midnight` · `Crimson` · `Ocean` · `Emerald` · `Sakura` · `Sunset` · `Dracula` · `Nord` · `Void` · `Light`

```lua
RageHub:AddTheme("Mine", {
    Background = Color3.fromRGB(10, 10, 14), Surface = Color3.fromRGB(20, 20, 28),
    SurfaceHover = Color3.fromRGB(30, 30, 42), Stroke = Color3.fromRGB(50, 50, 70),
    Text = Color3.fromRGB(240, 240, 250), SubText = Color3.fromRGB(140, 140, 165),
    Accent = Color3.fromRGB(255, 80, 120), Accent2 = Color3.fromRGB(255, 160, 60),
})
RageHub:SetTheme("Mine")
```

## Tips

- Config saving needs an executor with `writefile` / `readfile`; it is silently disabled otherwise.
- Call `Window:LoadConfig()` **after** all elements are created.
- The × button hides the window; reopen with the toggle key or the **R** launcher. **Settings → Unload** removes it.
- On narrow screens (phones in portrait) the sidebar starts collapsed; tap **≡** in the top bar.
- Tooltips show on hover (desktop only).

## Tests

`tests/run_tests.sh` runs 85 checks (every element, drag handling, search, config round-trip, notifications, dialogs, themes) on plain [Luau](https://github.com/luau-lang/luau) with a mocked Roblox environment. It can't verify rendering; always eyeball the UI in a real game too.

## License

MIT · Made by DevNameGelo · RGC
