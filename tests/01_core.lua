-- ===================================================================== helpers
local fails, passes = {}, 0
local function check(c, m) if c then passes = passes + 1 else fails[#fails + 1] = m; print("FAIL: " .. m) end end
local function find(pred) for _, i in ipairs(M.ALL) do if not i._destroyed and pred(i) then return i end end end
local V3 = Vector3.new
local function section(n) print("== " .. n) end
local function runtimeErrors()
    local bad = {}
    for _, e in ipairs(M.errors) do if not tostring(e):find("^warn:") then bad[#bad + 1] = e end end
    return bad
end
local function clearErrors() M.errors = {} end
local function warnCount() local n = 0; for _, e in ipairs(M.errors) do if tostring(e):find("^warn:") then n = n + 1 end end return n end
local ICON, THEME = RageHub.Assets.Icon, RageHub.Assets.Theme
M.http[ICON], M.http[THEME] = M.PNG, M.PNG
local function fresh(o)
    o = o or {}
    if o.Splash == nil then o.Splash = false end
    if o.Launcher == nil then o.Launcher = false end
    o.Name = o.Name or ("T" .. tostring(math.random(1e9)))
    return RageHub:CreateWindow(o)
end
local function press(key, down) M.uis.InputBegan:Fire(M.key(key), false) end
local function release(key) M.uis.InputEnded:Fire(M.key(key, "End"), false) end

-- ===================================================================== core / services
section("boot + registry")
check(RageHub.Version == "1.0.0", "version is 1.0.0")
check(RageHub.Framework == "RGC UI Framework" and RageHub.Developer == "DevNameGelo", "branding strings")
check(#RageHub:GetModules() == 5, "5 built-in modules registered (metadata only)")
check(RageHub:HasFeature("Tables") and RageHub:HasFeature("RemoteInspector") and not RageHub:HasFeature("Nope"), "HasFeature")
check(RageHub:GetModule("Logs").Name == "Console", "module alias resolves")
check(type(RageHub:GetCapabilities().FileSystem) == "boolean", "capabilities detected")
check(#RageHub:GetThemes() >= 11 and RageHub:GetTheme() == "Rage", "themes + default theme")
check(#RageHub:GetActiveWindows() == 0, "no windows before CreateWindow")

section("cleanup / events / state / tasks / logger / search (services)")
do
    local W = fresh()
    local n = 0
    local c = W.Cleanup:Child("t")
    c:Add(function() n = n + 1 end); c:Add({ Destroy = function() n = n + 10 end }); c:Add(M.uis.InputBegan:Connect(function() end))
    c:Add(Instance.new("Frame"))
    check(c:Count() == 4, "cleanup counts items")
    c:Destroy(); c:Destroy()
    check(n == 11, "cleanup releases every item once (" .. n .. ")")
    c:Add(function() n = n + 100 end)
    check(n == 111, "adding to a destroyed cleanup releases immediately")
    -- events
    local hits = 0
    local conn = W.Events:On("X", function(a) hits = hits + a end)
    W.Events:Emit("X", 2); conn:Disconnect(); W.Events:Emit("X", 5)
    check(hits == 2, "events On/Disconnect")
    W.Events:On("Boom", function() error("x") end); W.Events:Emit("Boom")
    check(#W.Logger:Get({ Level = "Error" }) >= 1, "event handler errors are logged, not thrown")
    local once = 0
    W.Events:Once("O", function() once = once + 1 end); W.Events:Emit("O"); W.Events:Emit("O")
    check(once == 1, "events Once")
    -- state
    local seen = {}
    local w = W.State:Watch("k", function(v, old) seen[#seen + 1] = tostring(old) .. ">" .. tostring(v) end)
    W.State:Set("k", 1); W.State:Set("k", 1); W.State:Set("k", 2)
    check(#seen == 2 and seen[2] == "1>2", "state watch fires only on change")
    W.State:Update("k", function(v) return v + 5 end)
    check(W.State:Get("k") == 7 and W.State:Exists("k"), "state update/get/exists")
    W.State:Define("d", 9); W.State:Set("d", 1); W.State:Reset("d")
    check(W.State:Get("d") == 9, "state reset to default")
    w:Disconnect(); W.State:Set("k", 100)
    check(#seen == 3, "state unwatch")
    local sc = W.State:Scope("mod"); sc:Set("a", 3)
    check(W.State:Get("mod.a") == 3 and sc:Get("a") == 3, "scoped state")
    -- tasks: tokens, generations, workers
    local w1 = W.Tasks:Create("w")
    local ran = 0
    local tok = w1:Start(function(token) ran = ran + 1; while token:IsValid() do task.wait(1) end end)
    check(w1.Generation == 1 and w1:IsRunning(), "worker generation counter + running")
    w1:Restart()
    check(w1.Generation == 2 and tok.Cancelled and not tok:IsValid(), "restart cancels the old token and bumps the generation")
    w1:Stop(); check(not w1:IsRunning() and w1.Token.Cancelled, "stop cancels the token")
    local tk = W:CreateToken()
    tk:Cancel()
    check(tk.Cancelled and not tk:IsValid(), "token cancel")
    local g = W.Tasks:NewGeneration("auto")
    check(W.Tasks:IsCurrent("auto", g) and (W.Tasks:NewGeneration("auto") ~= g) and not W.Tasks:IsCurrent("auto", g), "generation invalidation")
    local loops = 0
    local ev = W.Tasks:Every(1, function() loops = loops + 1 end, "ev")
    M.advance(3.5); check(loops == 4 and ev:IsRunning(), "Tasks:Every ticks on its interval (" .. loops .. ")")
    ev:Stop(); M.advance(5); check(loops == 4 and not ev:IsRunning(), "worker Stop halts the loop")
    local tw = W.Tasks:Create("timeout"):Timeout(2); local tk2 = tw:Start(function(t) while t:IsValid() do task.wait(0.5) end end)
    M.advance(3); check(tk2.Cancelled and not tw:IsRunning(), "worker Timeout cancels a stuck worker")
    local to = W.Tasks:Create("to"):Timeout(5)
    to:Start(function(t) while t:IsValid() do task.wait(1) end end)
    -- logger
    W.Logger:Info("A", "hello"); W.Logger:Warning("B", "careful"); W.Logger:Error("A", "bad")
    check(#W.Logger:Get({ Module = "A" }) >= 2, "logger module filter")
    check(#W.Logger:Get({ Level = "Warning" }) >= 2, "logger level filter (min level)")
    check(#W.Logger:Get({ Search = "careful" }) == 1, "logger search")
    check(W.Logger:Format(W.Logger:Get({ Search = "hello" })[1]):find("%[A%] INFO"), "logger format")
    check(W.Logger:Trace("A", "t") == nil, "trace/debug dropped when DebugMode off")
    -- search
    local S = RageHub.Search
    check(S.Match("rem", "Remote Inspector", "prefix") and not S.Match("ins", "Remote Inspector", "prefix"), "search prefix")
    check(S.Match("insp", "Remote Inspector", "contains") and S.Match("INSP", "remote inspector", "contains"), "search contains/case")
    check(S.Match("rmi", "Remote Inspector", "fuzzy") and not S.Match("zzz", "Remote Inspector", "fuzzy"), "search fuzzy")
    check(S.Match("a", "a", "exact") and not S.Match("a", "ab", "exact"), "search exact")
    check(#S.Filter({ "apple", "banana", "apricot" }, "ap", nil, "prefix") == 2, "search filter")
    W:Destroy()
end

section("clipboard / validation / utils")
check(RageHub.Clipboard.Copy("hi") == true and M.getClipboard() == "hi", "clipboard copy")
check(RageHub.Utils.Serialize({ a = 1, b = { 1, 2 } }):find("a = 1"), "serialize")
check(select(1, RageHub.Utils.Describe("x")) == '"x"', "describe")
do
    local before = warnCount()
    local W = fresh()
    local t = W:CreateTab("V")
    t:CreateToggle({})                                  -- missing Name
    t:CreateSlider({ Name = "S", Callback = 5 })        -- bad callback
    t:CreateDropdown({ Name = "D", Options = "oops" })  -- bad options
    t:CreateTable({ Name = "T", Columns = {} })         -- bad columns
    RageHub:AddTheme("bad", { Accent = 5 })             -- bad token
    check(RageHub:SetTheme("nope") == false, "invalid theme rejected")
    check(RageHub:RegisterModule({ Name = "" }) == false, "invalid module rejected")
    check(warnCount() - before >= 5, "validation warnings emitted (" .. (warnCount() - before) .. ")")
    check(#runtimeErrors() == 0, "validation never throws")
    clearErrors()
    check(RageHub:AddTheme("incomplete", { Accent = Color3.fromRGB(1, 2, 3) }), "incomplete theme registers")
    local W2 = fresh({ Theme = "incomplete" })
    check(W2.Theme.Background ~= nil and W2.Theme.TextMuted ~= nil and W2.Theme.Overlay ~= nil, "missing tokens get defaults")
    W2:Destroy(); W:Destroy(); clearErrors()
end

-- ===================================================================== windows
section("window lifecycle + registry + isolation")
do
    local W = fresh({ Id = "main" })
    check(W.Main.Visible and W.Visible, "window visible (Splash=false)")
    check(RageHub:GetWindow("main") == W and #RageHub:GetActiveWindows() == 1, "window registry")
    local W2 = RageHub:CreateWindow({ Id = "main", Name = "again", Splash = false, Launcher = false })
    check(#RageHub:GetActiveWindows() == 1 and W._destroyed, "re-creating the same Id destroys the old window (no duplicates)")
    local A = fresh({ Id = "a", AllowMultiple = true }); local B = fresh({ Id = "b", AllowMultiple = true })
    check(#RageHub:GetActiveWindows() == 3, "multiple windows when requested")
    -- isolation: per-window theme + state
    A:SetTheme("Ocean"); B:SetTheme("Nord")
    check(A.ThemeName == "Ocean" and B.ThemeName == "Nord" and A.Theme.Accent ~= B.Theme.Accent, "per-window themes")
    A.State:Set("x", 1)
    check(B.State:Get("x") == nil, "state not shared between windows")
    local ab = A:CreateTab("T"):CreateToggle({ Name = "t", Flag = "f" })
    check(B.Options["f"] == nil, "flags not shared between windows")
    RageHub:SetTheme("Sunset")
    check(A.ThemeName == "Sunset" and B.ThemeName == "Sunset", "RageHub:SetTheme updates every window")
    -- management
    A:Hide(); check(not A.Visible, "hide"); A:Show(); check(A.Visible, "show"); A:Toggle(); A:Toggle()
    A:SetMinimized(true); check(A.Minimized and not A._body.Visible, "minimize"); A:SetMinimized(false); M.advance(1)
    local s0 = A._size.X
    A:Maximize(true); check(A.Maximized, "maximize"); A:Maximize(false); check(not A.Maximized and A._size.X == s0, "restore from maximize")
    A:SetSize(420, 300); check(A._size.X == 420 and A._size.Y == 300, "resize")
    A:SetPosition(30, -20); check(A.Main.Position.X.Offset == 30, "move")
    A:Focus(); check(A.Focused and not B.Focused, "focus"); B:Focus(); check(B.Focused and not A.Focused, "blur on focus change")
    check(B.Gui.DisplayOrder > A.Gui.DisplayOrder, "focused window is on top")
    A:Destroy(); A:Destroy()
    check(RageHub:DestroyWindow("b") and not RageHub:DestroyWindow("b"), "DestroyWindow")
    RageHub:DestroyAll()
    check(#RageHub:GetActiveWindows() == 0, "DestroyAll")
    check(#runtimeErrors() == 0, "no runtime errors in window lifecycle")
    clearErrors()
end

section("error isolation (callbacks / events)")
do
    local W = fresh()
    local t = W:CreateTab("E")
    local tg = t:CreateToggle({ Name = "Boom", Callback = function() error("kaboom") end })
    tg:Set(true)
    check(W.CallbackErrors == 1, "callback error counted")
    local lg = W.Logger:Get({ Level = "Error" })
    check(#lg >= 1 and lg[#lg].Message:find("Callback error") and lg[#lg].Message:find("Element: Boom"), "callback error logged with element name")
    tg:Set(false); check(tg:Get() == false, "toggle still works after a callback error")
    check(W.Main.Visible, "window survives callback errors")
    W:Destroy(); clearErrors()
end

section("responsive breakpoints + density + animation")
do
    local W = fresh()
    check(W.Breakpoint == "Large" or W.Breakpoint == "Medium", "large viewport -> bigger breakpoint (" .. W.Breakpoint .. ")")
    local seen
    W.Events:On("BreakpointChanged", function(bp) seen = bp end)
    W:SetSize(400, 300)
    check(W.Breakpoint == "Small" and seen == "Small", "shrinking switches to Small + emits event")
    check(W.SidebarCollapsed, "sidebar auto-collapses on Small")
    W:SetSize(900, 400); check(W.Breakpoint == "Large", "growing switches back")
    check(W:SetDensity("Compact") and W.Dens.el < 40 and W:SetDensity("Spacious") and W.Dens.el > 40, "density modes")
    check(W:SetAnimation("off") and W.AnimFactor == 0 and W:SetAnimation("slow") and W.AnimFactor > 1, "animation modes")
    W:SetAnimation("off")
    local f = Instance.new("Frame"); W:Tween(f, { BackgroundTransparency = 0.5 }, 1)
    check(f.BackgroundTransparency == 0.5, "animations off: tween applies instantly")
    W:Destroy()
    -- phone viewport
    local cam = M.cam
    local old = cam.ViewportSize
    cam._p.ViewportSize = Vector2.new(390, 700)
    local P = fresh()
    check(P.Breakpoint == "Small" and P.SidebarCollapsed, "phone portrait: Small + collapsed sidebar")
    P:Destroy()
    cam._p.ViewportSize = old
end

-- ===================================================================== panels / layout
section("panels (opt-in, dockable)")
do
    local W = fresh()
    check(not W._dockRight.Visible and not W._dockBottom.Visible, "no panels unless requested")
    local p = W:CreatePanel({ Name = "Inspector", Dock = "Right", Size = 260 })
    check(W._dockRight.Visible and W._dockRight.Size.X.Offset == 260, "right panel creates a right dock")
    local b = W:CreatePanel({ Name = "Console", Dock = "Bottom", Size = 140 })
    check(W._dockBottom.Visible, "bottom panel creates a bottom dock")
    p:CreateLabel("inside panel"); p:CreateToggle({ Name = "pt" })
    p:Hide(); check(not W._dockRight.Visible, "hiding the last right panel collapses the dock")
    p:Show(); p:Float(); check(p:IsFloating() and not W._dockRight.Visible, "float detaches from the dock")
    p:Dock("Right"); check(not p:IsFloating() and W._dockRight.Visible, "re-dock")
    W:SetSize(400, 300)
    check(p.Frame.Parent == W._dockBottom, "right panels fall back to the bottom dock on Small")
    p:Destroy(); b:Destroy()
    check(#W.Panels == 0 and not W._dockBottom.Visible, "destroying panels frees the layout")
    check(#runtimeErrors() == 0, "no runtime errors in panels")
    W:Destroy(); clearErrors()
end

-- ===================================================================== assets / launcher / splash / branding
section("assets + launcher + branding + splash")
do
    local before = M.httpCalls
    local W = fresh({ Launcher = true })
    local art = W._launcherArt
    check(W._launcher ~= nil and art ~= nil, "launcher created")
    check(art.Image.Image:find("^rbxasset://custom/") ~= nil, "launcher shows the official icon (image bound)")
    check(not art.Fallback.Visible, "fallback hidden once the image is ready")
    check(M.httpCalls - before == 1, "icon downloaded exactly once (" .. (M.httpCalls - before) .. ")")
    check(M.files["RageHub/assets/" .. (function() for k in pairs(M.files) do if k:find("ragehub%-icon") then return k:match("[^/]+$") end end end)()] ~= nil, "icon cached on disk")
    local W2 = fresh({ Launcher = true })
    check(M.httpCalls - before == 1, "second window reuses the cached image (no re-download)")
    check(RageHub.Assets:Stats().Cached >= 1 and RageHub.Assets:Stats().Hits >= 1, "asset stats")
    W2:Destroy()
    -- circular + aspect: crop, rounded
    check(art.Image.ScaleType == Enum.ScaleType.Crop, "launcher image keeps aspect (Crop, not Stretch)")
    check(W._launcher.Size.X.Offset >= 44 and W._launcher.Size.X.Offset <= 60, "launcher touch size 44-60px")
    -- tap toggles, drag moves, release snaps to an edge
    local d = M.input("Touch", "Begin", V3(20, 300))
    W._launcher.InputBegan:Fire(d); d.UserInputState = Enum.UserInputState.End; d.Changed:Fire()
    check(not W.Visible, "tap on launcher toggles window"); W:Show()
    local d2 = M.input("Touch", "Begin", V3(20, 300))
    W._launcher.InputBegan:Fire(d2)
    d2.Position = V3(220, 360); M.uis.InputChanged:Fire(d2)
    check(W._launcher.Position.X.Offset > 100, "launcher drags")
    d2.UserInputState = Enum.UserInputState.End; d2.Changed:Fire()
    local x = W._launcher.Position.X.Offset
    check(W.Visible, "dragging does not toggle the window")
    check(x == 8 or x > 1000, "launcher snaps to a screen edge (x=" .. tostring(x) .. ")")
    -- branding override + icon swap
    W:SetLauncherIcon("rbxassetid://12345")
    check(art.Image.Image == "rbxassetid://12345", "custom launcher icon (asset id)")
    local br
    W.Events:On("BrandingChanged", function() br = true end)
    W:SetBranding({ Name = "My Tool" }); check(br and W.Branding.Name == "My Tool", "SetBranding emits BrandingChanged")
    check(W:BrandImage("ThemeImage") == THEME, "theme image resolves to the repo asset")
    W:SetBranding({ ThemeImage = false }); check(W:BrandImage("ThemeImage") == nil, "branding image can be disabled")
    W:SetBranding({ ThemeImage = "Theme" })
    W:SetLauncherVisible(false); check(not W._launcher.Visible, "launcher can be hidden")
    W:Destroy()
    check(not find(function(i) return i._class == "TextButton" and i._p.Name == "Launcher" end), "destroy removes the launcher")
    -- Launcher = false never creates one
    local N = fresh({ Launcher = false }); check(N._launcher == nil, "Launcher=false creates no launcher"); N:Destroy()
    -- failure fallback
    local url = "https://example.invalid/missing.png"
    local F = fresh({ Launcher = true, Branding = { Icon = url } })
    check(F._launcherArt.Fallback.Visible, "failed image keeps the built-in fallback visible")
    check(F.Main.Visible and F._launcher ~= nil, "UI works when the image fails")
    local calls = M.httpCalls
    F:SetBranding({ Icon = url }); F:SetBranding({ Icon = url })
    check(M.httpCalls == calls, "failed loads are not retried every time")
    check(#runtimeErrors() == 0, "no runtime errors from asset failures")
    F:Destroy()
    -- splash with the theme image, skip by tap
    local S = RageHub:CreateWindow({ Name = "Splash", Splash = { Duration = 1 }, Launcher = false })
    check(S.Main.Visible == false and S._splashCard ~= nil, "splash visible while loading")
    local banner = find(function(i) return i._class == "ImageLabel" and tostring(i._p.Image):find("custom") and i._p.ScaleType == Enum.ScaleType.Crop and i._p.Size and i._p.Size.Y.Offset == 104 end)
    check(banner ~= nil, "splash banner uses the theme image")
    S:SkipSplash(); M.advance(0.5)
    check(S.Main.Visible and S._splashCard == nil, "tap skips the splash")
    S:Destroy()
    local S2 = RageHub:CreateWindow({ Name = "Splash2", Splash = { Duration = 1, Image = false }, Launcher = false })
    M.advance(1.5); M.advance(0.5); check(S2.Main.Visible, "splash completes by itself")
    S2:Destroy()
    local S3 = RageHub:CreateWindow({ Name = "Splash3", Splash = { Duration = 5 }, Launcher = false })
    S3:Destroy(); M.advance(10)
    check(#runtimeErrors() == 0, "destroying during the splash is safe")
    clearErrors()
end
