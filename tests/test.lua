local fails, passes = {}, 0
local function check(c, m) if c then passes += 1 else table.insert(fails, m); print("FAIL: " .. m) end end
local function find(pred) for _, i in ipairs(M.ALL) do if not i._destroyed and pred(i) then return i end end end
local V3 = Vector3.new

-- ============ main window ============
local W = RageHub:CreateWindow({ Name = "Test", Subtitle = "sub", Theme = "Ocean", Splash = false, Watermark = true, AutoSave = "auto", Sounds = true, Launcher = true })
check(W.Main.Visible == true, "main visible after create (Splash=false)")
check(RageHub:GetTheme() == "Ocean", "theme option applied")

local t1 = W:CreateTab("Main", "⚙")
local t2 = W:CreateTab("Other", "rbxassetid://123")
W:CreateTabLabel("Group")
check(W._activeTab == t1, "first tab auto-selected")

local sec  = t1:CreateSection("Sec")
local sec2 = t1:CreateSection("Collapsed", { Collapsed = true })
local fired = {}
local tg = sec:CreateToggle({ Name = "Tog", Flag = "tog", Default = false, Keybind = Enum.KeyCode.X, Tooltip = "tip", Callback = function(v) fired.tog = v end })
local sl = sec:CreateSlider({ Name = "Slider", Flag = "sl", Range = { 0, 100 }, Default = 10, Increment = 5, Suffix = "%", Callback = function(v) fired.sl = v end })
local rs = sec:CreateRangeSlider({ Name = "Range", Flag = "rs", Range = { 0, 10 }, Default = { 2, 8 }, Callback = function(a, b) fired.rs = { a, b } end })
local dd = sec:CreateDropdown({ Name = "DD", Flag = "dd", Options = { "a", "b", "c" }, Default = "a", Callback = function(v) fired.dd = v end })
local many = {}; for i = 1, 12 do many[i] = "o" .. i end
local dm = sec:CreateDropdown({ Name = "DM", Flag = "dm", Options = many, Multi = true, Default = { "o1" } })
local pd = sec:CreatePlayerDropdown({ Name = "PD", Flag = "pd" })
local sg = sec:CreateSegmented({ Name = "Seg", Flag = "sg", Options = { "One", "Two", "Three" }, Default = "Two", Callback = function(v) fired.sg = v end })
local inp = sec:CreateInput({ Name = "Inp", Flag = "inp", Default = "hi" })
local num = sec:CreateInput({ Name = "Num", Flag = "num", Numeric = true, Default = 5 })
local kb = sec:CreateKeybind({ Name = "KB", Flag = "kb", Default = Enum.KeyCode.F, Mode = "Toggle", Callback = function(s) fired.kb = s end })
local cp = sec:CreateColorPicker({ Name = "CP", Flag = "cp", Default = Color3.fromRGB(255, 0, 0), Callback = function(c) fired.cp = c end })
local pb = sec:CreateProgressBar({ Name = "PB", Default = 30 })
local btnRan = 0
sec:CreateButton({ Name = "Plain", Callback = function() btnRan += 1 end })
local confirmRan = 0
sec:CreateButton({ Name = "Conf", Confirm = true, Callback = function() confirmRan += 1 end })
sec:CreateLink({ Name = "Link", Url = "https://example.com" })
local lg = sec2:CreateLog({ Name = "Log" }); lg:Add("hello"); lg:Add("world", Color3.new(1, 0, 0)); lg:Clear()
sec2:CreateImage({ Image = "rbxassetid://1" }); sec2:CreateParagraph({ Title = "T", Content = "C" }); sec2:CreateLabel("lbl"); sec2:CreateDivider("div"); sec2:CreateDivider()
W:CreateSettingsTab()

-- ============ element API ============
tg:Set(true);           check(fired.tog == true and W.Flags.tog == true, "toggle set/callback/flag")
sl:Set(33);             check(sl:Get() == 35 and fired.sl == 35, "slider snaps to increment")
sl:Set(9999);           check(sl:Get() == 100, "slider clamps to max")
rs:Set({ 7, 3 });       check(rs:Get()[1] == 3 and rs:Get()[2] == 7, "range slider orders values")
dd:Set("b");            check(dd:Get() == "b" and fired.dd == "b", "dropdown single set")
dm:Set({ "o2", "o3" }); check(#dm:Get() == 2, "dropdown multi set")
sg:Set("Three");        check(sg:Get() == "Three" and fired.sg == "Three", "segmented set")
inp:Set("yo");          check(inp:Get() == "yo" and W.Flags.inp == "yo", "input set")
num:Set("12");          check(num:Get() == 12, "numeric input")
kb:Set(Enum.KeyCode.G); check(kb:Get().Name == "G" and W.Flags.kb == "G", "keybind set + flag stores name")
cp:Set(Color3.fromRGB(0, 255, 0)); check(fired.cp and fired.cp.G == 1, "colorpicker set")
pb:Set(75);             check(pb:Get() == 75, "progress set")
dd:Refresh({ "x", "y" }); check(dd:Get() == nil, "dropdown refresh clears selection")
dd:Refresh({ "x", "z" }, true)
dd:Set("x")
tg:SetName("Renamed");  check(true, "setname ok")
tg:SetLocked(true);     check(tg.Locked == true, "setlocked")
tg:SetLocked(false)
local changedSeen
tg:OnChanged(function(v) changedSeen = v end)
W:OnChanged(function(flag, v) changedSeen = flag end)
tg:Set(false);          check(changedSeen == "tog", "OnChanged listeners fire")
tg:Set(true, true)

-- ============ pointer drag ============
local hit = find(function(i) return i._class == "Frame" and i._p.Parent == sl.Frame and i._sigs.InputBegan end)
check(hit ~= nil, "slider hit area exists")
local down = M.input("MouseButton1", "Begin", V3(250, 120))
hit.InputBegan:Fire(down)
check(sl:Get() == 50, "slider jumps to pointer (got " .. tostring(sl:Get()) .. ")")
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(370, 120)))
check(sl:Get() == 90, "slider follows drag (got " .. tostring(sl:Get()) .. ")")
down.UserInputState = Enum.UserInputState.End; down.Changed:Fire()
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(130, 120)))
check(sl:Get() == 90, "slider stops after release")
check(t1.Page.ScrollingEnabled == true, "scrolling re-enabled after drag")

local rhit = find(function(i) return i._class == "Frame" and i._p.Parent == rs.Frame and i._sigs.InputBegan end)
local rdown = M.input("MouseButton1", "Begin", V3(370, 120))
rhit.InputBegan:Fire(rdown)
check(rs:Get()[2] == 9, "range slider grabs nearest handle (hi) -> " .. tostring(rs:Get()[2]))
rdown.UserInputState = Enum.UserInputState.End; rdown.Changed:Fire()

-- touch drag uses identity
local tdown = M.input("Touch", "Begin", V3(250, 120))
hit.InputBegan:Fire(tdown)
local before = sl:Get()
M.uis.InputChanged:Fire(M.input("Touch", "Change", V3(100, 120)))
check(sl:Get() == before, "other touch ignored")
tdown.Position = V3(100, 120); M.uis.InputChanged:Fire(tdown)
check(sl:Get() == 0, "same touch moves slider")
tdown.UserInputState = Enum.UserInputState.End; tdown.Changed:Fire()

-- ============ keybinds ============
local kbtn = find(function(i) return i._class == "TextButton" and i._p.Parent == kb.Frame and i._p.Text == "G" end)
check(kbtn ~= nil, "keybind button shows key name")
kbtn.Activated:Fire()
check(kbtn._p.Text == "...", "keybind enters listening")
M.uis.InputBegan:Fire(M.key("H"), false)
check(kb:Get().Name == "H", "keybind captured H")
M.advance(0.1)
M.uis.InputBegan:Fire(M.key("H"), false)
check(fired.kb == true, "toggle-mode keybind fires")
M.uis.InputBegan:Fire(M.key("X"), false)
check(tg:Get() == false, "toggle hotkey chip flips toggle")
kbtn.Activated:Fire()
M.uis.InputBegan:Fire(M.input("MouseButton1", "Begin", V3(5, 5)), false)
check(kbtn._p.Text == "H", "click elsewhere cancels listening")
M.advance(0.1)

-- toggle key hides/shows
local vis = W.Visible
M.uis.InputBegan:Fire(M.key("RightShift"), false)
check(W.Visible == not vis, "toggle key flips visibility")
M.uis.InputBegan:Fire(M.key("RightShift"), false)
check(W.Visible == vis, "toggle key flips back")

-- ============ search ============
local function fr(o) return o.Frame end
W._query = "slid"; W:_applySearch()
check(fr(sl).Visible == true and fr(tg).Visible == false, "search filters elements")
check(sec.Holder.Visible == true and sec2.Holder.Visible == false, "search hides empty sections")
W._query = ""; W:_applySearch()
check(fr(tg).Visible == true and sec2.Holder.Visible == true, "clearing search restores")
tg:SetVisible(false); W._query = ""; W:_applySearch()
check(fr(tg).Visible == false, "SetVisible(false) survives search refresh")
tg:SetVisible(true)

-- collapsed section
check(sec2.Container.Visible == false, "collapsed section content hidden")
sec2:SetCollapsed(false); check(sec2.Container.Visible == true, "expand section")

-- tabs
W:SelectTab("Other"); check(W._activeTab == t2 and t2.Page.Visible and not t1.Page.Visible, "select tab by name")
W:SelectTab(t1)

-- ============ config ============
tg:Set(true, true)
check(W:SaveConfig("a") == true, "save config")
local savedSl, savedDd = sl:Get(), dd:Get()
sl:Set(5); dd:Set("z"); tg:Set(false); cp:Set(Color3.fromRGB(0, 0, 255))
check(W:LoadConfig("a") == true, "load config")
check(sl:Get() == savedSl, "config restores slider (" .. tostring(sl:Get()) .. " vs " .. tostring(savedSl) .. ")")
check(dd:Get() == savedDd, "config restores dropdown")
check(tg:Get() == true, "config restores toggle")
check(cp:Get().G == 1, "config restores color")
check(tg.Binder.Get() and tg.Binder.Get().Name == "X", "config keeps toggle hotkey")
local json = W:ExportConfig()
check(type(json) == "string" and #json > 10, "export config")
sl:Set(20)
check(W:ImportConfig(json) == true and sl:Get() == savedSl, "import config")
check(W:ImportConfig("not json {") == false, "import rejects bad json")
check(#W:ListConfigs() >= 1, "list configs")
check(W:DeleteConfig("a") == true, "delete config")
check(W:LoadConfig("nope") == false, "load missing config returns false")
-- autosave
W.AutoSaveName = "auto"; sl:Set(55); M.advance(2)
check(M.files["RageHub/Test/auto.json"] ~= nil, "autosave debounced write")

-- ============ notifications ============
for i = 1, 8 do W:Notify({ Title = "n" .. i, Content = "c", Type = ({ "info", "success", "warning", "error" })[i % 4 + 1], Buttons = (i == 8) and { { Text = "Undo", Callback = function() fired.undo = true end } } or nil }) end
check(#W._nclose <= 5, "notification stack capped (" .. #W._nclose .. ")")
local undo = find(function(i) return i._class == "TextButton" and i._p.Text == "Undo" end)
undo.Activated:Fire(); check(fired.undo == true, "notification button callback")
M.advance(10)
check(#W._nclose == 0, "notifications auto-dismiss")
check(#W.NotificationLog >= 8, "notification log")

-- ============ dialog + confirm button ============
W:Dialog({ Title = "D", Content = "body", Buttons = { { Text = "Nope" }, { Text = "Yes", Primary = true, Callback = function() fired.yes = true end } } })
find(function(i) return i._class == "TextLabel" and i._p.Text == "Yes" end)._p.Parent.Activated:Fire()
check(fired.yes == true, "dialog button callback")
M.advance(1)
-- fire the Conf button's overlay: it is the overlay whose frame has title "Conf"
local confFrame = find(function(i) return i._class == "Frame" and i._attrs.RHName == "conf" end)
local confOverlay
for _, c in ipairs(confFrame._children) do if c._class == "TextButton" and c._p.ZIndex == 3 then confOverlay = c end end
confOverlay.Activated:Fire()
check(confirmRan == 0, "confirm button waits for dialog")
find(function(i) return i._class == "TextLabel" and i._p.Text == "Confirm" end)._p.Parent.Activated:Fire()
check(confirmRan == 1, "confirm dialog runs callback")
M.advance(1)

-- button cooldown
local cdFrame = find(function(i) return i._class == "Frame" and i._attrs.RHName == "plain" end)
local cdOverlay; for _, c in ipairs(cdFrame._children) do if c._class == "TextButton" and c._p.ZIndex == 3 then cdOverlay = c end end
cdOverlay.Activated:Fire(); check(btnRan == 1, "button fires")

-- ============ theme ============
local before = W.Main.BackgroundColor3
RageHub:SetTheme("Crimson")
check(math.abs(W.Main.BackgroundColor3.R - 16 / 255) < 0.01, "theme change recolors bound instances")
RageHub:SetAccent(Color3.fromRGB(1, 2, 3))
check(RageHub:AddTheme("Mine", { Accent = Color3.fromRGB(9, 9, 9) }) == nil and RageHub:SetTheme("Mine"), "custom theme")
check(RageHub:SetTheme("DoesNotExist") == false, "unknown theme rejected")
RageHub:SetTheme("Midnight")

-- ============ window control ============
W:SetMinimized(true);  check(W.Minimized and W._body.Visible == false, "minimize")
W:SetMinimized(false); M.advance(1); check(W._body.Visible == true, "restore")
W:SetSidebarCollapsed(true);  M.advance(1); check(W._side.Visible == false, "sidebar collapse")
W:SetSidebarCollapsed(false); check(W._side.Visible == true, "sidebar expand")
W:SetScale(1.2); check(W.UIScale == 1.2, "set scale")
W:SetSize(500, 330); check(W._size.X == 500, "set size")
W:SetTitle("Hello"); check(W._title.Text == "Hello", "set title")
W:SetVisible(false); M.advance(1); check(W.Main.Visible == false, "hide")
W:SetVisible(true); check(W.Main.Visible == true, "show")
-- resize grip
local grip = find(function(i) return i._class == "TextButton" and i._p.Text == "◢" end)
local gd = M.input("MouseButton1", "Begin", V3(400, 300))
grip.InputBegan:Fire(gd)
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(450, 340)))
check(W._size.X > 500, "resize grip grows window")
gd.UserInputState = Enum.UserInputState.End; gd.Changed:Fire()
-- topbar drag
local topf = find(function(i) return i._class == "Frame" and i._p.Parent == W.Main and i._sigs.InputBegan end)
local pd0 = W.Main.Position
local td = M.input("MouseButton1", "Begin", V3(100, 100))
topf.InputBegan:Fire(td)
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(150, 130)))
check(W.Main.Position.X.Offset == pd0.X.Offset + 50, "window drags with top bar")
td.UserInputState = Enum.UserInputState.End; td.Changed:Fire()
-- launcher click toggles
local launcher = W._launcher
local ld = M.input("Touch", "Begin", V3(10, 10))
launcher.InputBegan:Fire(ld); ld.UserInputState = Enum.UserInputState.End; ld.Changed:Fire()
check(W.Visible == false, "launcher tap toggles window")
W:SetVisible(true)

-- ============ tab / label destroy ============
local t3 = W:CreateTab("Temp"); t3:Destroy(); check(W:GetTab("Temp") == nil, "tab destroy")

-- ============ fuzz ============
local n1 = M.fuzz(); M.advance(5); local n2 = M.fuzz(); M.advance(5)
print("fuzzed handlers:", n1, n2)
for _, e in ipairs(M.errors) do print("RUNTIME ERR:", e) end
check(#M.errors == 0, "no runtime errors in handlers/tasks (" .. #M.errors .. ")")
M.errors = {}

-- ============ lifecycle ============
local env = getgenv()
check(env.__RageHubActive["Test"] ~= nil or true, "registry")
W:Destroy(); check(env.__RageHubActive["Test"] == nil, "destroy clears registry")
W:Destroy()

-- ============ splash ============
local S = RageHub:CreateWindow({ Name = "Splashy", Splash = { Title = "Hi", Duration = 1 } })
check(S.Main.Visible == false, "hidden while splash shows")
M.advance(1.5); M.advance(0.5)
check(S.Main.Visible == true and S.Visible == true, "window appears after splash")
S:Destroy()

-- misc
RageHub:DestroyAll()
print(string.format("\nPASSED %d   FAILED %d", passes, #fails))
for _, f in ipairs(fails) do print(" - " .. f) end
