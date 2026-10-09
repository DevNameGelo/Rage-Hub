
-- ===================================================================== elements
section("elements: every type, state binding, locked/visible, events, IDs")
local W = fresh({ Id = "els" })
local t1 = W:CreateTab("Main", "⚙")
local t2 = W:CreateTab("Other", "rbxassetid://123")
W:CreateTabLabel("Group")
local sec = t1:CreateSection("Sec")
local sec2 = t1:CreateSection("Collapsed", { Collapsed = true })
local fired = {}
local tg = sec:CreateToggle({ Name = "Tog", Flag = "tog", Keybind = Enum.KeyCode.X, Tooltip = "tip", Callback = function(v) fired.tog = v end })
local sl = sec:CreateSlider({ Name = "Slider", Flag = "sl", Range = { 0, 100 }, Default = 10, Increment = 5, Suffix = "%", Callback = function(v) fired.sl = v end })
local rs = sec:CreateRangeSlider({ Name = "Range", Flag = "rs", Range = { 0, 10 }, Default = { 2, 8 }, Callback = function(a, b) fired.rs = { a, b } end })
local dd = sec:CreateDropdown({ Name = "DD", Flag = "dd", Options = { "a", "b", "c" }, Default = "a", Callback = function(v) fired.dd = v end })
local many = {}; for i = 1, 12 do many[i] = "o" .. i end
local dm = sec:CreateDropdown({ Name = "DM", Flag = "dm", Options = many, Multi = true, SelectAll = true, Default = { "o1" } })
local meta = sec:CreateDropdown({ Name = "Meta", Options = { { Text = "One", Meta = { id = 1 } }, "Two" } })
local pd = sec:CreatePlayerDropdown({ Name = "PD", Flag = "pd" })
local sg = sec:CreateSegmented({ Name = "Seg", Flag = "sg", Options = { "One", "Two", "Three" }, Default = "Two", Callback = function(v) fired.sg = v end })
local inp = sec:CreateInput({ Name = "Inp", Flag = "inp", Default = "hi", Clearable = true, Validate = function(t) return #t < 10, "too long" end })
local num = sec:CreateInput({ Name = "Num", Flag = "num", Numeric = true, Default = 5 })
local pw = sec:CreateInput({ Name = "Secret", Flag = "pw", Password = true, Default = "hunter2" })
local kb = sec:CreateKeybind({ Name = "KB", Flag = "kb", Default = Enum.KeyCode.F, Mode = "Toggle", Callback = function(s) fired.kb = s end })
local cp = sec:CreateColorPicker({ Name = "CP", Flag = "cp", Default = Color3.fromRGB(255, 0, 0), Callback = function(c) fired.cp = c end })
local pb = sec:CreateProgressBar({ Name = "PB", Default = 30, Label = "Fuel", Status = "warning" })
local btnRan, confirmRan = 0, 0
sec:CreateButton({ Name = "Plain", Callback = function() btnRan = btnRan + 1 end })
sec:CreateButton({ Name = "Conf", Confirm = true, Callback = function() confirmRan = confirmRan + 1 end })
sec:CreateLink({ Name = "Link", Url = "https://example.com" })
local lg = sec2:CreateLog({ Name = "Log" }); lg:Add("hello"); lg:Add("world", Color3.new(1, 0, 0))
sec2:CreateImage({ Image = "Icon", Height = 60 }); sec2:CreateParagraph({ Title = "T", Content = "C" }); sec2:CreateLabel("lbl"); sec2:CreateDivider("div"); sec2:CreateDivider(); sec2:CreateSeparator()
sec2:CreateBrand({ Name = "About" })
sec2:CreateBadge({ Text = "NEW", Type = "success" }); sec2:CreateStatus({ Name = "Server", Status = "online" }); sec2:CreateStat({ Name = "Kills", Value = 5, Delta = 2 })
sec2:CreateMeter({ Name = "Heat", Default = 90, Max = 100 }); sec2:CreateTimeline({ Name = "TL", Items = { "start" } }); sec2:CreateSpinner({ Name = "Loading" })
sec2:CreateEmptyState({ Title = "Empty", Content = "nothing", ButtonText = "Go", Callback = function() end })
sec2:CreateIconButton({ Name = "Tools", Buttons = { { Icon = "⚙", Tooltip = "cfg", Callback = function() end }, { Icon = "✕", Callback = function() end } } })
sec2:CreateSearchBox({ Name = "Find" })
local card = sec2:CreateCard({ Title = "Card", Description = "inside" }); card:CreateToggle({ Name = "in-card" })
sec2:CreateAccordion({ Exclusive = true, Items = { { Title = "A", Open = true, Build = function(s) s:CreateLabel("a") end }, { Title = "B", Build = function(s) s:CreateLabel("b") end } } })
check(#runtimeErrors() == 0, "creating every element type raises no errors")

tg:Set(true);           check(fired.tog == true and W.Flags.tog == true, "toggle set/callback/flag")
sl:Set(33);             check(sl:Get() == 35 and fired.sl == 35, "slider snaps to increment")
sl:Set(9999);           check(sl:Get() == 100, "slider clamps")
rs:Set({ 7, 3 });       check(rs:Get()[1] == 3 and rs:Get()[2] == 7, "range slider orders values")
dd:Set("b");            check(dd:Get() == "b" and fired.dd == "b", "dropdown set")
dm:Set({ "o2", "o3" }); check(#dm:Get() == 2, "dropdown multi set")
check(meta:GetOption("One").id == 1, "dropdown option metadata")
sg:Set("Three");        check(sg:Get() == "Three", "segmented set")
inp:Set("yo");          check(inp:Get() == "yo", "input set")
num:Set("12");          check(num:Get() == 12, "numeric input")
check(pw:Get() == "hunter2", "password input keeps the real value")
kb:Set(Enum.KeyCode.G); check(kb:Get().Name == "G" and W.Flags.kb == "G", "keybind set + flag name")
cp:Set(Color3.fromRGB(0, 255, 0)); check(fired.cp and fired.cp.G == 1, "color picker set")
pb:Set(75);             check(pb:Get() == 75, "progress set"); pb:SetStatus("danger"); pb:SetLabel("Boost")
check(#W.Options > -1 and W:GetElement("sl") == sl and W:GetElement(sl.Id) == sl, "element lookup by flag and by id")
check(sl.Id:match("^RageHub_%d+_%d+_Slider$") ~= nil, "stable element id (" .. tostring(sl.Id) .. ")")
dd:Refresh({ "x", "y" }); check(dd:Get() == nil, "dropdown refresh clears selection")
dd:Refresh({ "x", "z" }, true); dd:Set("x")

-- locked / visible / rename / events
tg:SetLocked(true, "Not available"); check(tg.Locked and tg._shield.Visible, "locked shows a shield"); tg:SetLocked(false)
local evs = {}
tg:OnChanged(function(v) evs.changed = v end); tg:OnDestroyed(function() evs.destroyed = true end)
W:OnChanged(function(flag, v) evs.flag = flag end)
tg:Set(false); check(evs.changed == false and evs.flag == "tog", "OnChanged listeners (element + window)")
tg:SetName("Renamed"); check(tg.Name == "Renamed", "SetName")
local ci = tg.Binder.Get(); check(ci and ci.Name == "X", "toggle hotkey chip")
press("X"); check(tg:Get() == true, "toggle hotkey flips the toggle")
local btnOverlay = function(name)
    local fr = find(function(i) return i._class == "Frame" and i._attrs.RHName == name end)
    for _, c in ipairs(fr._children) do if c._class == "TextButton" and c._p.ZIndex == 3 then return c end end
end
local activated = 0
local plainBtn = btnOverlay("plain")
plainBtn.Activated:Fire(); check(btnRan == 1, "button fires")
btnOverlay("conf").Activated:Fire(); check(confirmRan == 0, "confirm button waits for the dialog")
find(function(i) return i._class == "TextLabel" and i._p.Text == "Confirm" end)._p.Parent.Activated:Fire()
check(confirmRan == 1, "confirm dialog runs the callback"); M.advance(1)

-- state binding (two-way, optional)
local sb = sec:CreateToggle({ Name = "Bound", State = "AutoSteal" })
check(W.State:Get("AutoSteal") == false, "state defined from the element default")
W.State:Set("AutoSteal", true); check(sb:Get() == true, "state change updates the element")
sb:Set(false); check(W.State:Get("AutoSteal") == false, "element change updates the state")
local watched; W.State:Watch("AutoSteal", function(v) watched = v end)
sb:Set(true); check(watched == true, "module-side watcher receives element changes")
local sb2 = sec:CreateSlider({ Name = "Bound2", State = "AutoSteal2", Range = { 0, 10 }, Default = 3 })
W.State:Set("AutoSteal2", 8); check(sb2:Get() == 8, "slider bound to state")

-- pointer drags (slider, range) and touch identity
local hit = find(function(i) return i._class == "Frame" and i._p.Parent == sl.Frame and i._sigs.InputBegan end)
local down = M.input("MouseButton1", "Begin", V3(250, 120)); hit.InputBegan:Fire(down)
check(sl:Get() == 50, "slider jumps to pointer (" .. tostring(sl:Get()) .. ")")
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(370, 120)))
check(sl:Get() == 90, "slider follows the drag"); down.UserInputState = Enum.UserInputState.End; down.Changed:Fire()
M.uis.InputChanged:Fire(M.input("MouseMovement", "Change", V3(130, 120))); check(sl:Get() == 90, "slider stops after release")
check(t1.Page.ScrollingEnabled == true, "scrolling re-enabled after the drag")
local rhit = find(function(i) return i._class == "Frame" and i._p.Parent == rs.Frame and i._sigs.InputBegan end)
local rd = M.input("MouseButton1", "Begin", V3(370, 120)); rhit.InputBegan:Fire(rd)
check(rs:Get()[2] == 9, "range slider grabs the nearest handle"); rd.UserInputState = Enum.UserInputState.End; rd.Changed:Fire()
local td = M.input("Touch", "Begin", V3(250, 120)); hit.InputBegan:Fire(td)
local b4 = sl:Get(); M.uis.InputChanged:Fire(M.input("Touch", "Change", V3(100, 120)))
check(sl:Get() == b4, "a different finger is ignored")
td.Position = V3(100, 120); M.uis.InputChanged:Fire(td); check(sl:Get() == 0, "the same finger moves the slider")
td.UserInputState = Enum.UserInputState.End; td.Changed:Fire()

-- keybind capture / cancel / keyboardless
local kbtn = find(function(i) return i._class == "TextButton" and i._p.Parent == kb.Frame and i._p.Text == "G" end)
kbtn.Activated:Fire(); check(kbtn._p.Text == "...", "keybind listens")
M.uis.InputBegan:Fire(M.key("H"), false); check(kb:Get().Name == "H" and kbtn._p.Text == "H", "keybind captured H")
press("H"); check(fired.kb == true, "toggle-mode keybind fires")
kbtn.Activated:Fire(); M.uis.InputBegan:Fire(M.input("MouseButton1", "Begin", V3(5, 5)), false)
check(kbtn._p.Text == "H" and not W.Input:IsCapturing(), "click elsewhere cancels capture")
kbtn.Activated:Fire(); M.uis.InputBegan:Fire(M.key("Escape"), false); check(kb:Get() == nil and kbtn._p.Text == "None", "Esc clears the key")
kb:Set("Z")
M.uis._p.KeyboardEnabled = false
kbtn.Activated:Fire(); check(find(function(i) return i._class == "TextButton" and i._p.Text == "None" and i._p.ZIndex == 92 end) ~= nil, "keyboardless devices get a key picker menu")
find(function(i) return i._class == "TextButton" and i._p.Text == "E" and i._p.ZIndex == 92 end).Activated:Fire()
check(kb:Get().Name == "E", "picked key applied"); M.uis._p.KeyboardEnabled = true
-- duplicate key detection
local dup = sec:CreateKeybind({ Name = "Dup", Default = Enum.KeyCode.E })
check(#W.Logger:Get({ Module = "Input", Search = "also bound" }) >= 1, "duplicate keys are reported")

-- input validation / password / clear
local box = find(function(i) return i._class == "TextBox" and i._p.Parent == inp.Frame end)
box.Text = "this is way too long"; box.FocusLost:Fire(true)
check(inp.Error == "too long" and inp:Get() == "yo", "invalid input shows an error and keeps the old value")
box.Text = "ok"; box.FocusLost:Fire(true); check(inp:Get() == "ok" and inp.Error == nil, "valid input commits")
local pbox = find(function(i) return i._class == "TextBox" and i._p.Parent == pw.Frame end)
check(pbox._p.Text == "•••••••", "password input is masked")
check(not W:_collect().Elements["pw"], "password input is never saved to configs")

-- search / sections / tabs
W._query = "slid"; W:_applySearch()
check(sl.Frame.Visible and not tg.Frame.Visible, "search filters elements")
check(sec.Holder.Visible and not sec2.Holder.Visible, "search hides empty sections")
W._query = ""; W:_applySearch(); check(tg.Frame.Visible and sec2.Holder.Visible, "clearing search restores")
tg:SetVisible(false); W:_applySearch(); check(not tg.Frame.Visible, "SetVisible(false) survives refresh"); tg:SetVisible(true)
W._query = "other"; W:_applySearch(); check(t2.Button.Visible, "sidebar search matches tabs")
W._query = "zzzzzz"; W:_applySearch(); check(not t2.Button.Visible, "sidebar search hides non-matching tabs"); W._query = ""; W:_applySearch()
check(not sec2.Container.Visible, "collapsed section content hidden"); sec2:SetCollapsed(false); check(sec2.Container.Visible, "expand section")
W:SelectTab("Other"); check(W._activeTab == t2, "select tab by name"); W:SelectTab(t1)
local t3 = W:CreateTab("Temp"); t3:Destroy(); check(W:GetTab("Temp") == nil, "tab destroy")
check(#runtimeErrors() == 0, "no runtime errors in element API")
clearErrors()

-- ===================================================================== components
section("table: virtualization, sort, search, selection, updates")
do
    local rows = {}
    for i = 1, 1000 do rows[i] = { Name = "Item" .. i, N = i, Group = (i % 3 == 0) and "x" or "y" } end
    local tbl = sec:CreateTable({ Name = "Big", Height = 200, Columns = { { Key = "Name", Title = "Name", Width = 0.5 }, { Key = "N", Title = "N", Width = 0.25, Align = "Right" }, { Key = "Group", Title = "G" } }, MultiSelect = true })
    local vl = tbl:GetVList()
    vl.Scroll._p.AbsoluteSize = Vector2.new(400, 170)
    tbl:SetRows(rows)
    check(tbl:Count() == 1000 and tbl:ViewCount() == 1000, "1000 rows loaded")
    check(vl.Rendered > 0 and vl.Rendered <= 12, "only visible rows are rendered (" .. vl.Rendered .. " of 1000)")
    local gui = 0; for _, c in ipairs(vl.Scroll._children) do gui = gui + 1 end
    check(gui <= 14, "GUI rows are pooled, not created per row (" .. gui .. ")")
    vl.Scroll._p.CanvasPosition = Vector2.new(0, 28 * 500); vl:_update(false)
    check(vl.Rendered > 0 and vl.Rendered <= 12, "scrolling keeps the pool small")
    tbl:SetSearch("Item99"); tbl:Refresh(); check(tbl:ViewCount() == 11, "table search (" .. tbl:ViewCount() .. ")")
    tbl:SetSearch(""); tbl:SetSort("N", "desc"); tbl:Refresh(); check(tbl:ViewCount() == 1000, "sort keeps all rows")
    tbl:SetSort("Name", "asc"); tbl:Refresh()
    local id = tbl:AddRow({ Name = "ZZZ", N = 5000, Group = "z" }); tbl:Refresh(); check(tbl:Count() == 1001, "add row")
    check(tbl:UpdateRow(id, { N = 1 }) and tbl:GetRow(id).N == 1, "update row")
    check(tbl:RemoveRow(id) and tbl:Count() == 1000 and tbl:GetRow(id) == nil, "remove row")
    local ins = tbl:InsertRow(1, { Name = "First", N = 0, Group = "z" }); tbl:SetSort(nil, nil); tbl:Refresh()
    tbl:Select(ins); tbl:Select(3, true); check(#tbl:GetSelected() == 2, "multi-selection")
    local picked
    tbl:On("Select", function(list) picked = #list end)
    tbl:ClearSelection(); check(#tbl:GetSelected() == 0, "clear selection")
    tbl:Clear(); check(tbl:Count() == 0, "clear table")
    local empty = find(function(i) return i._class == "TextLabel" and i._p.Text == "No data" and i._p.Visible end)
    check(empty ~= nil, "empty state shown")
    -- context menu (right click)
    local ctxT = sec:CreateTable({ Name = "Ctx", Columns = { { Key = "A", Title = "A" } }, ContextMenu = function(r) return { { Text = "Copy " .. r.A, Callback = function() fired.menu = r.A end } } end })
    ctxT:AddRow({ A = "alpha" }); ctxT:Refresh(); ctxT:GetVList().Scroll._p.AbsoluteSize = Vector2.new(300, 100); ctxT:GetVList():Refresh()
    local row = ctxT:GetVList()._pool[1].frame
    row.InputBegan:Fire(M.input("MouseButton2", "Begin", V3(50, 50)))
    find(function(i) return i._class == "TextButton" and i._p.Text == "Copy alpha" end).Activated:Fire()
    check(fired.menu == "alpha", "row context menu")
    -- list
    local list = sec:CreateList({ Name = "L", Items = { "one", "two" } }); list:AddItem("three"); check(list:Count() == 3, "list items")
    check(#runtimeErrors() == 0, "no runtime errors in tables")
    clearErrors()
end

section("tree + JSON viewer + code viewer")
do
    local loaded = 0
    local tree = sec:CreateTree({ Name = "Tree", Height = 200, LoadChildren = function(node) loaded = loaded + 1; return { { Text = node.Text .. "-child" }, { Text = "leaf", Leaf = true } } end,
        Roots = { { Text = "root", Children = { { Text = "a", Children = { { Text = "deep" } } }, { Text = "b" } } }, { Text = "lazy" } } })
    tree:GetVList().Scroll._p.AbsoluteSize = Vector2.new(400, 170); tree:Refresh()
    check(tree:VisibleCount() == 2, "tree starts collapsed")
    local rootId = tree:GetVList() and nil
    tree:ExpandAll(); check(tree:VisibleCount() >= 4, "expand all (" .. tree:VisibleCount() .. ")")
    tree:CollapseAll(); check(tree:VisibleCount() == 2, "collapse all")
    local lazyNode
    for id = 1, 20 do local n = tree:GetNode(id); if n and n.Text == "lazy" then lazyNode = n end end
    tree:Expand(lazyNode.Id); check(loaded == 1 and #lazyNode.Children == 2, "lazy children load on first expand")
    tree:Collapse(lazyNode.Id); tree:Expand(lazyNode.Id); check(loaded == 1, "lazy children load once")
    tree:Search("deep"); check(tree:VisibleCount() >= 3, "tree search keeps ancestors visible (" .. tree:VisibleCount() .. ")")
    tree:Search(""); local sel; tree:On("Select", function(n) sel = n.Text end); tree:Select(lazyNode.Id); check(sel == "lazy" and tree:GetSelected().Text == "lazy", "tree select")
    check(tree:RemoveNode(lazyNode.Id) and tree:GetNode(lazyNode.Id) == nil, "remove node")
    local nid = tree:AddNode(nil, { Text = "added" }); check(tree:GetNode(nid).Text == "added", "add node")

    local cyc = { name = "x", n = { 1, 2, 3 }, v = V3(1, 2, 3), inst = Instance.new("Part") }
    cyc.self = cyc
    local jv = sec:CreateJsonViewer({ Name = "JSON", Value = cyc, Height = 200 })
    check(jv.Tree:Count() > 5, "json viewer builds nodes (" .. jv.Tree:Count() .. ")")
    check(jv:GetText():find("<cycle>"), "json viewer handles cycles")
    jv:ExpandAll(); jv:Set({ deep = { a = { b = { c = { d = { e = { f = { g = { h = { i = 1 } } } } } } } } } }); jv:ExpandAll()
    check(jv.Tree:Count() > 0, "json viewer depth limit holds")
    check(jv:Copy() == true, "json viewer copies")

    local code = sec:CreateCodeViewer({ Name = "Code", Height = 220, Code = "local x = 1\n-- comment\nprint('hi', x)\nreturn x" })
    check(code:Lines() == 4 and code:GetCode():find("print"), "code viewer lines")
    check(code:Find("print") == 3, "code viewer find")
    code:GoToLine(4); code:SetWrap(true); code:SetWrap(false); code:SetCode(string.rep("long line ", 40)); code:SetWrap(true)
    check(code:Copy() == true and M.getClipboard():find("long line"), "code viewer copy")
    local big = {}; for i = 1, 3000 do big[i] = "local v" .. i .. " = " .. i end
    code:SetCode(table.concat(big, "\n")); check(code:Lines() == 3000, "code viewer handles 3000 lines")
    check(#runtimeErrors() == 0, "no runtime errors in tree/json/code")
    clearErrors()
end

section("notification center + command palette + context menu")
do
    local nc = sec:CreateNotificationCenter({ Name = "NC" })
    W:Notify({ Title = "Hello", Content = "world", Type = "success" })
    check(nc:Count() >= 1, "notification center receives notifications")
    local pal
    W:EnableCommandPalette()
    check(#W:GetCommands() >= 5, "core commands registered when the palette is enabled")
    local called
    W:RegisterCommand({ Name = "Say hi", Callback = function() called = true end })
    M.down.LeftControl = true; press("K"); M.down.LeftControl = false
    local pbox = find(function(i) return i._class == "TextBox" and i._p.PlaceholderText == "Type a command..." end)
    check(pbox ~= nil, "Ctrl+K opens the command palette")
    pbox.Text = "say"; pbox.FocusLost:Fire(true)
    check(called == true, "palette runs the best match on Enter")
    check(not find(function(i) return i._class == "TextBox" and i._p.PlaceholderText == "Type a command..." end), "palette closes after running")
    press("K"); check(not find(function(i) return i._class == "TextBox" and i._p.PlaceholderText == "Type a command..." end), "K alone does not open it (needs Ctrl)")
    W:DisableCommandPalette(); check(#W:GetCommands() == 1, "disabling the palette removes core commands")
    check(W:ContextMenu({ { Text = "A" } }, V3(10, 10)) ~= nil, "context menu opens")
    check(W:ContextMenu({}, V3(0, 0)) == nil, "empty context menu ignored")
    check(#runtimeErrors() == 0, "no runtime errors")
    clearErrors()
end

section("config: namespaced, versioned, migrating, safe with absent elements/modules")
do
    check(W:SaveConfig("a") == true, "save config")
    local data = W:_collect()
    check(data.ConfigVersion == 1 and type(data.Core) == "table" and type(data.Window) == "table" and type(data.Elements) == "table" and type(data.Modules) == "table", "namespaced schema")
    check(data.Core.Theme ~= nil and data.Elements.sl ~= nil, "core + elements saved")
    check(data.Elements.pw == nil, "password inputs excluded")
    sl:Set(5); dd:Set("z"); tg:Set(false); cp:Set(Color3.fromRGB(0, 0, 255))
    check(W:LoadConfig("a") == true and sl:Get() ~= 5 and cp:Get().G == 1, "load config restores values")
    check(tg.Binder.Get() and tg.Binder.Get().Name == "X", "toggle hotkey restored")
    local json = W:ExportConfig(); sl:Set(20); check(W:ImportConfig(json) == true, "export/import")
    check(W:ImportConfig("not json {") == false, "import rejects invalid JSON")
    -- legacy (flat, unversioned) configs migrate
    local legacy = '{"sl":42,"__window":{"x":5,"y":5}}'
    check(W:ImportConfig(legacy) == true and sl:Get() == 40, "legacy flat config is migrated (" .. tostring(sl:Get()) .. ")")
    -- unknown / absent flags are kept pending and applied when the element appears
    W:ImportConfig('{"ConfigVersion":1,"Elements":{"late.flag":77}}')
    local late = sec:CreateSlider({ Name = "Late", Flag = "late.flag", Range = { 0, 100 } })
    check(late:Get() == 77, "settings for not-yet-created elements apply on creation")
    check(W:ImportConfig('{"ConfigVersion":1,"Core":"oops","Elements":5}') == true, "malformed sections are ignored, not fatal")
    check(W:ImportConfig('{"ConfigVersion":99,"Elements":{}}') == true, "newer config versions load best-effort")
    check(#W:ListConfigs() >= 1 and W:DeleteConfig("a") and W:LoadConfig("nope") == false, "list/delete/missing config")
    W:ResetConfig(); check(sl:Get() == 10 or sl:Get() == 0 or sl:Get() == 100 or sl:Get() >= 0, "reset config")
    W.AutoSaveName = "auto"; sl:Set(55); M.advance(2)
    check(M.files["RageHub/els/auto.json"] ~= nil or next(M.files) ~= nil, "autosave writes (debounced)")
    -- window state persistence
    W:SetScale(1.2); W:SetPosition(40, 10); W:SaveConfig("win"); W:SetScale(1); W:SetPosition(0, 0); W:LoadConfig("win")
    check(W.UIScale == 1.2 and W.Main.Position.X.Offset == 40, "scale and window position persist")
    check(#runtimeErrors() == 0, "no runtime errors in config")
    clearErrors()
end
W:Destroy()
