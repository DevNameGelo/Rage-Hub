# Changelog

## 2.0.0

### Added
- **Elements:** RangeSlider (two handles), Segmented control, searchable Dropdown, PlayerDropdown (auto-updating), ProgressBar, Log console, Image, Link (copy to clipboard), collapsible Sections, labelled Dividers
- **Toggle hotkeys:** `Keybind = KeyCode` adds a hotkey chip to any toggle
- **Keybind modes:** `Press`, `Hold`, `Toggle`
- **Slider:** tap the value to type an exact number; ColorPicker: hex input
- **Button:** `Confirm` dialog and `Cooldown`
- **Element API:** `:SetName`, `:SetDescription`, `:SetLocked`, `:SetVisible`, `:OnChanged`, plus `Window:OnChanged` for all flags
- **Tooltips** (`Tooltip = "..."` on any element, desktop hover)
- **Window:** per-tab search, tab icons and tab group labels, resizable (drag ◢), collapsible sidebar (≡), UI scale, splash screen, watermark (FPS / ping), modal dialogs, notification buttons + stack cap + log, optional UI sounds
- **Themes:** Sunset, Dracula, Nord, Void (AMOLED) added (10 total); `RageHub:SetAccent()` for a custom accent
- **Config:** window position/size saved, toggle hotkeys saved, JSON export / import, auto-save
- **Settings tab:** theme, custom accent, transparency, UI scale, toggle key, sounds, watermark, config manager, import/export
- Random ScreenGui name (harder for games to detect by name); `RageHub:DestroyAll()`
- Test suite (`tests/`) running on plain Luau with a mocked Roblox environment

### Fixed
- Every slider / color picker created its own global input listener; now one dispatcher per window
- Theme registry kept destroyed instances alive; now weak-referenced
- A keybind could get stuck in "listening"; clicking elsewhere or the button again now cancels it
- Settings theme dropdown always showed "Midnight" regardless of the active theme
- Slider with `Increment = 0` divided by zero
- Square sidebar / accent-line corners poked out of the rounded window; sidebar is now an inset rounded panel
- Touch dragging now follows the finger that started the drag
- Window is re-centered if it ends up off-screen

## 1.0.0
- Initial release
