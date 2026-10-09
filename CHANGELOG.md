# Changelog

## 1.0.0 — fresh architecture (RGC UI Framework)

Rage Hub is now a **framework**: a small core plus opt-in modules. This is a ground-up redesign, not an extension of the old library.

### Architecture
- **CORE ≠ MODULES.** Core: windows, tabs, sections, elements, themes, state, events, tasks, cleanup, config, logger, input, notifications, dialogs, diagnostics. Everything else is a module that costs nothing until enabled.
- **Module system:** `RegisterModule`, `EnableModule`, `DisableModule`, `ReloadModule`, `DestroyModule`, dependencies (auto-resolved, cycle-safe), manifests/metadata, per-window instances, error isolation, full cleanup on disable, config retained across disable/enable.
- **Services (window-scoped):** Resource manager (`Cleanup`), Task manager (workers, tokens, generations, timeouts), Event bus, State store (`Get/Set/Update/Watch/Reset/Scope`), Logger (levels, filters, scoped), Input manager (one dispatcher: press/hold/toggle/double-tap/modifiers/capture), Animation + Sound managers, Clipboard, Search (exact/contains/prefix/fuzzy), Asset manager.
- **Declarative setup:** `Features = { Logs = true, RemoteInspector = false, ... }`.
- **Safe re-execution:** running the script again shuts the previous instance down (no duplicate windows, launchers or dispatchers). One namespaced global (`__RageHub`).

### UI
- **New components:** Table (virtualized, sort, search, multi-select, context menu), List, Tree (lazy children, search), JSON viewer, Code viewer (line numbers, find, wrap, syntax colours), Context menu, Command palette, Search box, Icon buttons, Card, Badge, Status, Stat, Meter, Timeline, Accordion, Empty state, Spinner, Notification center, Brand card.
- **Virtualization:** only visible rows exist (5000-row table renders ~12 GUI rows).
- **Layout:** optional docked panels (right/bottom/floating), responsive breakpoints (Small/Medium/Large), density modes, collapsible sidebar, maximize, resize, per-window scale.
- **Element API:** stable element IDs, `State = "key"` two-way binding, `OnChanged/OnActivated/OnFocused/OnBlurred/OnDestroyed`, `SetLocked(true, reason)`, `SetVisible`, validation with readable warnings.
- **Theming:** semantic tokens (Background, Surface, Surface2, SurfaceHover, SurfacePressed, Border, Text, TextMuted, TextDisabled, Accent, Accent2, Success, Warning, Danger, Info, Shadow, Overlay), per-window themes, incomplete themes get defaults. New **Rage** theme (default).
- **Notifications:** queue, stack, progress notifications, action buttons, history. **Dialogs:** info, confirm, input (with validation), warning, destructive. Dialogs never trap input (Esc / tap outside).

### Branding & assets
- Official Rage Hub icon + theme image live in `assets/` of the repository and are used by the floating launcher (circular, aspect-correct, draggable, edge-snapping), the splash screen, the About/Brand card and the Image element.
- Asset manager: downloads once, caches on disk and in memory, never retries a failure on every call, falls back to a built-in "RH" mark if the image can't load. `RageHub:SetBranding` / `Window:SetBranding` / `Window:SetLauncherIcon` for custom branding.

### Config
- Namespaced, versioned config (`Core`, `Window`, `Elements`, `Modules`) with **migrations** (v2-era flat files load automatically), settings for absent elements/modules kept safely, JSON export/import, auto-save, reset.

### Built-in opt-in modules
- **Remote Inspector** (passive OnClientEvent observation, separate data layer, no hooks or stealth), **Instance Explorer**, **Player Monitor**, **Performance Monitor**, **Developer Console**.

### Quality
- 399 automated checks (`tests/`) on plain Luau with a mocked Roblox environment: element API, virtualization, modules (ON/OFF cycles, leak checks, failure isolation, dependencies), notifications, dialogs, input, assets/launcher/splash, config migration, mobile behaviour and performance.
- Diagnostics: `RageHub.Diagnostics:GetReport()`, `Window:GetDiagnostics()`, `Window:Diagnose()`.

### Removed / changed
- Version numbering restarts at 1.0.0 (previous 2.x line is retired).
- No key system.
- Familiar names kept: `CreateWindow`, `CreateTab`, `CreateSection`, `CreateToggle`, `CreateButton`, `CreateDropdown`, `CreateSettingsTab`, `Notify`, `SaveConfig`, `LoadConfig`, `Destroy`.
