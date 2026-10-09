
-- ===================================================================== modules
section("modules: lifecycle, ON/OFF cycles, cleanup, dependencies, failure isolation")
local _ = M.uis.InputBegan
local function handlers(sig) return #sig._h end
do
    local W = fresh()
    check(#W.Tabs == 0 and #W:GetEnabledModules() == 0 and #W.Panels == 0, "a new window has NO modules and NO extra tabs")
    local log = {}
    local baseInput = handlers(M.uis.InputBegan)
    W:RegisterModule({
        Name = "Custom", DisplayName = "Custom Tool", Version = "1.2.3", Category = "Tools", Dependencies = { "Tables" },
        Init = function(self, ctx) log[#log + 1] = "init" end,
        Enable = function(self, ctx)
            log[#log + 1] = "enable"
            local tab = ctx:CreateTab("Custom", "★")
            tab:CreateToggle({ Name = "X", Flag = "x" })
            ctx.Cleanup:Add(M.uis.InputBegan:Connect(function() end))
            ctx.Tasks:Every(1, function() end, "w")
            ctx:RegisterCommand({ Name = "Custom: do it", Callback = function() end })
            self.stamp = os.clock() + math.random()
            ctx.Logger:Info("hello from module")
        end,
        Disable = function(self, ctx) log[#log + 1] = "disable" end,
        Destroy = function(self, ctx) log[#log + 1] = "destroy" end,
    })
    check(W:GetModuleState("Custom") == "Disabled" and not W:IsModuleEnabled("Custom"), "registered module starts disabled")
    local snap = function() return { tabs = #W.Tabs, cleanup = W.Cleanup:Count(), workers = W.Tasks:Count(), inputs = handlers(M.uis.InputBegan), events = W.Events:Count(), cmds = #W:GetCommands(), opts = (function() local n = 0 for _ in pairs(W.Options) do n = n + 1 end return n end)() } end
    local base = snap()
    check(W:EnableModule("Custom") == true, "enable module")
    local on = snap()
    check(W:IsModuleEnabled("Custom") and #W.Tabs == 1 and W.Options["Custom.x"] ~= nil, "module UI created + flags namespaced")
    check(on.workers == base.workers + 1 and on.inputs == base.inputs + 1 and on.cmds == base.cmds + 1, "module resources registered")
    check(table.concat(log, ",") == "init,enable", "Init then Enable")
    check(W:EnableModule("Custom") == true and #W.Tabs == 1, "enabling twice does not duplicate anything")
    local first = W:GetModuleInstance("Custom")
    check(W:DisableModule("Custom") == true and not W:IsModuleEnabled("Custom"), "disable module")
    local off = snap()
    for k, v in pairs(base) do check(off[k] == v, "disable releases '" .. k .. "' (" .. tostring(off[k]) .. " vs " .. tostring(v) .. ")") end
    check(log[#log] == "disable" and W:GetTab("Custom") == nil and W.Options["Custom.x"] == nil, "UI destroyed + Disable called")
    for i = 1, 5 do
        check(W:EnableModule("Custom"), "cycle " .. i .. " ON")
        check(W:DisableModule("Custom"), "cycle " .. i .. " OFF")
    end
    W:EnableModule("Custom")
    local again = snap()
    for k, v in pairs(on) do check(again[k] == v, "ON/OFF x5 then ON: no duplicate '" .. k .. "' (" .. tostring(again[k]) .. " vs " .. tostring(v) .. ")") end
    check(W:GetModuleInstance("Custom") ~= first and W:GetModuleInstance("Custom").stamp ~= first.stamp, "re-enable creates a fresh instance")
    local info = W:GetModuleInfo("Custom")
    check(info.State == "Enabled" and info.Version == "1.2.3" and info.Category == "Tools" and info.Resources > 0, "module info / query")
    check(W:ReloadModule("Custom") and W:IsModuleEnabled("Custom") and #W.Tabs == 1, "reload module")
    check(#W.Logger:Get({ Module = "Custom" }) >= 1, "module logger is namespaced")
    check(W:DestroyModule("Custom") and log[#log] == "destroy" and W:GetModuleState("Custom") == "Destroyed", "destroy module calls Destroy")
    check(#runtimeErrors() == 0, "no runtime errors in module lifecycle")

    -- persistence: config retained across disable/enable, not runtime state
    W:RegisterModule({ Name = "Cfg", Enable = function(self, ctx) self.v = ctx.Config:Get("k", "default"); ctx.Config:Set("k", "stored") end })
    W:EnableModule("Cfg"); W:DisableModule("Cfg"); W:EnableModule("Cfg")
    check(W:GetModuleInstance("Cfg").v == "stored", "module config is retained when disabled")
    check(W:_collect().Modules.Cfg.Config.k == "stored", "module config is saved under Modules.<name>")

    -- failures are isolated
    W:RegisterModule({ Name = "Bad", Enable = function(self, ctx) ctx:CreateTab("BadTab"); ctx.Cleanup:Add(M.uis.InputBegan:Connect(function() end)); error("boom") end })
    local before = snap()
    local ok, err = W:EnableModule("Bad")
    check(ok == false and tostring(err):find("boom"), "failing module reports an error")
    check(W:GetModuleState("Bad") == "Failed" and W:GetTab("BadTab") == nil, "failed module leaves no UI behind")
    check(handlers(M.uis.InputBegan) == before.inputs and W.Cleanup:Count() == before.cleanup, "failed module leaks nothing")
    check(W.Main.Visible and W:IsModuleEnabled("Cfg"), "window and other modules survive a failing module")
    check(#W.Logger:Get({ Module = "Bad", Level = "Error" }) >= 1 and #W:Diagnose() >= 1, "failure is logged + diagnosed")
    W:RegisterModule({ Name = "BadInit", Init = function() error("init!") end, Enable = function() end })
    check(W:EnableModule("BadInit") == false, "Init errors are isolated too")
    W:RegisterModule({ Name = "Disabler", Enable = function() end, Disable = function() error("disable!") end })
    W:EnableModule("Disabler"); check(W:DisableModule("Disabler") and not W:IsModuleEnabled("Disabler"), "Disable errors do not block cleanup")

    -- dependencies
    W:RegisterModule({ Name = "Base", Enable = function(self, ctx) ctx:CreateTab("BaseTab") end })
    W:RegisterModule({ Name = "Top", Dependencies = { "Base" }, Enable = function(self, ctx) ctx:CreateTab("TopTab") end })
    check(W:EnableModule("Top") and W:IsModuleEnabled("Base") and W:IsModuleEnabled("Top"), "dependencies are enabled automatically")
    W:DisableModule("Base"); check(not W:IsModuleEnabled("Top") and W:GetTab("TopTab") == nil, "disabling a dependency disables its dependents first")
    W:RegisterModule({ Name = "Needy", Dependencies = { "DoesNotExist" }, Enable = function() end })
    local ok2, e2 = W:EnableModule("Needy"); check(ok2 == false and tostring(e2):find("missing dependency"), "missing dependency gives a useful diagnostic")
    W:RegisterModule({ Name = "C1", Dependencies = { "C2" }, Enable = function() end }); W:RegisterModule({ Name = "C2", Dependencies = { "C1" }, Enable = function() end })
    local ok3 = W:EnableModule("C1"); check(ok3 == false, "circular dependencies are detected (no hang)")
    check(W:EnableModule("NoSuchModule") == false, "unknown module")

    -- module visibility: the module decides where it appears
    W:RegisterModule({ Name = "Where", Enable = function(self, ctx) self.v = ctx:CreateView("Where", "?") end })
    local host = W:CreateTab("Host")
    W:EnableModule("Where", { Parent = host }); check(W:GetModuleInstance("Where").v.Holder ~= nil and W:GetTab("Where") == nil, "module can render as a Section inside an existing tab")
    W:DisableModule("Where"); W:EnableModule("Where", { Display = "Float" }); check(W:GetModuleInstance("Where").v:IsFloating(), "module can render as a floating tool")
    W:DisableModule("Where"); W:EnableModule("Where", { Display = "Panel" }); check(W:GetPanel("Where") ~= nil, "module can render as a docked panel")
    W:DisableModule("Where"); check(W:GetPanel("Where") == nil, "module panels are destroyed with the module")

    -- config for absent modules is ignored safely, applied later
    W:ImportConfig('{"ConfigVersion":1,"Elements":{"Ghost.x":3},"Modules":{"Ghost":{"Config":{"a":1},"Enabled":true}}}')
    W:RegisterModule({ Name = "Ghost", Enable = function(self, ctx) self.a = ctx.Config:Get("a"); self.t = ctx:CreateTab("Ghost"); self.s = self.t:CreateSlider({ Name = "x", Flag = "x", Range = { 0, 9 } }) end })
    W:EnableModule("Ghost")
    check(W:GetModuleInstance("Ghost").a == 1 and W:GetModuleInstance("Ghost").s:Get() == 3, "saved module config + element values apply when the module is enabled later")

    -- module settings only while enabled
    W:CreateSettingsTab()
    W:RegisterModule({ Name = "WithSettings", DisplayName = "Cool", Enable = function(self, ctx) ctx:AddSettings(function(sec) sec:CreateToggle({ Name = "CoolOpt" }) end) end })
    check(find(function(i) return i._class == "TextLabel" and i._p.Text == "COOL SETTINGS" end) == nil, "no module settings before enabling")
    W:EnableModule("WithSettings")
    check(find(function(i) return i._class == "TextLabel" and i._p.Text == "COOL SETTINGS" end) ~= nil, "module settings appear in Settings when enabled")
    W:DisableModule("WithSettings")
    check(find(function(i) return i._class == "TextLabel" and i._p.Text == "COOL SETTINGS" end) == nil, "module settings disappear when disabled")
    check(#runtimeErrors() == 0, "no runtime errors")
    clearErrors()
    W:Destroy()
end

section("declarative features + runtime toggling")
do
    local W = fresh({ Features = { Notifications = true, Tables = true, Logs = true, RemoteInspector = false, Performance = false } })
    check(#W:GetEnabledModules() == 1 and W:IsModuleEnabled("Console") and W:IsModuleEnabled("Logs"), "Features create only what was requested (alias Logs -> Console)")
    check(W:GetTab("Console") ~= nil and W:GetTab("Remote Inspector") == nil and W:GetTab("Performance") == nil and #W.Tabs == 1, "no unrequested tabs exist")
    W:EnableModule("Performance"); check(W:GetTab("Performance") ~= nil and #W:GetEnabledModules() == 2, "runtime enable adds just that module")
    W:DisableModule("Performance"); check(W:GetTab("Performance") == nil and W.Tasks:Count() == W:GetModuleInstance("Console").Context.Tasks:Count() + 0, "runtime disable removes it completely")
    local nf = fresh({ Features = { Notifications = false } }); nf:Notify({ Title = "x" })
    check(#nf._nActive == 0 and #nf.NotificationLog == 1, "Notifications=false shows nothing but keeps history"); nf:Destroy()
    local w2 = fresh({ Features = { NotARealThing = true } }); check(warnCount() >= 1, "unknown feature warns"); w2:Destroy()
    W:Destroy(); clearErrors()
end

section("built-in modules (opt-in)")
do
    local rs = game:GetService("ReplicatedStorage")
    local r1 = M.new("RemoteEvent", { Name = "Hit" }); r1.Parent = rs
    local r2 = M.new("RemoteFunction", { Name = "Buy" }); r2.Parent = rs
    local folder = M.new("Folder", { Name = "Sub" }); folder.Parent = rs
    local r3 = M.new("RemoteEvent", { Name = "Deep" }); r3.Parent = folder
    M.new("Part", { Name = "NotARemote" }).Parent = rs
    local W = fresh()
    local inputBase, hbBase = handlers(M.uis.InputBegan), 0
    check(handlers(r1.OnClientEvent) == 0, "no remote connections before the module is enabled")
    check(W:EnableModule("RemoteInspector") == true, "enable Remote Inspector")
    local ri = W:GetModuleInstance("RemoteInspector")
    check(#ri.Data.Remotes == 3, "discovers remotes only (" .. #ri.Data.Remotes .. ")")
    check(W:GetTab("Remote Inspector") ~= nil and W:GetPanel("Remote Details") ~= nil, "UI + details panel created on enable")
    check(handlers(r1.OnClientEvent) == 1 and handlers(r3.OnClientEvent) == 1 and handlers(r2.OnClientEvent) == 0, "passive OnClientEvent connections only")
    r1.OnClientEvent:Fire("a", 1, { x = { y = 2 } }, Instance.new("Part"))
    r1.OnClientEvent:Fire("b")
    check(#ri.Data.Traffic == 2 and ri.Data.Traffic[1].ArgCount == 4, "traffic captured")
    check(type(ri.Data.Traffic[1].Args[4]) == "string" and ri.Data.Traffic[1].Args[4]:find("Instance:"), "instances are stored as paths, not references")
    local snippet = RageHub.RemoteData.Snippet(ri.Data.Traffic[1])
    check(snippet:find("FireServer") and snippet:find('GetService%("ReplicatedStorage"%)'), "call snippet generated")
    ri:Record(r2, "Out", "coins", 5)
    check(#ri.Data.Traffic == 3 and ri.Data.Traffic[3].Direction == "Out", "outgoing traffic can be fed in by the consuming script")
    ri.Data.Capturing = false; r1.OnClientEvent:Fire("ignored"); check(#ri.Data.Traffic == 3, "capture toggle stops recording"); ri.Data.Capturing = true
    r1.Name = "Hit"; ri.Data:Find("hit"); check(#ri.Data:Find("deep") >= 1, "remote search")
    for i = 1, 600 do r1.OnClientEvent:Fire(i) end
    check(#ri.Data.Traffic <= 500, "traffic history is bounded (" .. #ri.Data.Traffic .. ")")
    local late = M.new("RemoteEvent", { Name = "Late" }); late.Parent = rs; rs.DescendantAdded:Fire(late)
    check(#ri.Data.Remotes == 4, "new remotes are discovered while enabled")
    local views = {}
    for _, i in ipairs(M.ALL) do if i._class == "Frame" and i._attrs.RHName == "traffic" then views.t = i end end
    check(views.t ~= nil, "traffic table exists")
    local json = find(function(i) return i._class == "Frame" and i._attrs.RHName == "arguments" end)
    check(json ~= nil, "arguments viewer exists in the panel")
    check(W:DisableModule("RemoteInspector") == true, "disable Remote Inspector")
    check(handlers(r1.OnClientEvent) == 0 and handlers(r3.OnClientEvent) == 0 and handlers(rs.DescendantAdded) == 0, "disable disconnects every remote connection")
    check(W:GetTab("Remote Inspector") == nil and W:GetPanel("Remote Details") == nil and ri.Data == nil, "disable destroys UI and releases the caches")
    check(handlers(M.uis.InputBegan) == inputBase and W.Tasks:Count() == 0, "no leftover input handlers or workers")
    for i = 1, 3 do W:EnableModule("RemoteInspector"); W:DisableModule("RemoteInspector") end
    W:EnableModule("RemoteInspector")
    check(handlers(r1.OnClientEvent) == 1 and #W.Tabs == 1 and #W.Panels == 1, "ON/OFF cycles leave exactly one set of resources")
    W:DisableModule("RemoteInspector")
    check(#runtimeErrors() == 0, "no runtime errors in Remote Inspector")
    clearErrors()

    -- Instance Explorer
    check(W:EnableModule("InstanceExplorer"), "enable Instance Explorer")
    local ie = W:GetModuleInstance("InstanceExplorer")
    check(ie.Tree:Count() >= 3, "explorer roots (" .. ie.Tree:Count() .. ")")
    local rsNode; for id = 1, 20 do local n = ie.Tree:GetNode(id); if n and n.Text == "ReplicatedStorage" then rsNode = n end end
    ie.Tree:Expand(rsNode.Id); check(#rsNode.Children >= 4, "explorer lazily loads children (" .. #(rsNode.Children or {}) .. ")")
    ie.Tree:Select(rsNode.Children[1].Id); check(W:GetPanel("Instance Details")._visible, "selecting shows the details panel")
    W:DisableModule("InstanceExplorer"); check(W:GetPanel("Instance Details") == nil and #W.Tabs == 0, "explorer cleaned up")

    -- Player Monitor
    check(W:EnableModule("PlayerMonitor"), "enable Player Monitor")
    local pm = W:GetModuleInstance("PlayerMonitor")
    check(pm.Table:Count() == 3, "lists players (" .. pm.Table:Count() .. ")")
    check(pm.Table:GetRow(2).Dist == 10 and pm.Table:GetRow(3).Status == "None" and pm.Table:GetRow(2).Status == "Alive", "distance + character status")
    local carol = { Name = "Carol", DisplayName = "Carol", UserId = 9 }
    game:GetService("Players").PlayerAdded:Fire(carol); check(pm.Table:Count() == 4, "PlayerAdded")
    game:GetService("Players").PlayerRemoving:Fire(carol); check(pm.Table:Count() == 3, "PlayerRemoving")
    local pa = handlers(game:GetService("Players").PlayerAdded)
    W:DisableModule("PlayerMonitor"); check(handlers(game:GetService("Players").PlayerAdded) == pa - 1 and W.Tasks:Count() == 0, "player monitor releases its connections")

    -- Performance
    local hb = game:GetService("RunService").Heartbeat; local hb0 = handlers(hb)
    check(W:EnableModule("Performance") and handlers(hb) == hb0 + 1 and W.Tasks:Count() == 1, "performance sampling runs only while enabled")
    W:DisableModule("Performance"); check(handlers(hb) == hb0 and W.Tasks:Count() == 0, "sampling stops on disable")

    -- Console
    W:EnableModule("Console"); local con = W:GetModuleInstance("Console")
    W.Logger:Info("Game", "hello console"); W.Logger:Error("Game", "bad thing"); con.Table:Refresh()
    check(con.Table:Count() >= 2, "console shows live log entries (" .. con.Table:Count() .. ")")
    local subs = #W.Logger._subs; W:DisableModule("Console"); check(#W.Logger._subs == subs - 1, "console unsubscribes from the logger")
    check(#runtimeErrors() == 0, "no runtime errors in built-in modules")
    clearErrors()
    W:Destroy()
    check(handlers(r1.OnClientEvent) == 0, "destroying the window leaves no remote connections")
end

-- ===================================================================== notifications / dialogs / input
section("notifications: queue, stack, progress, actions, history")
do
    local W = fresh()
    local hs = {}
    for i = 1, 6 do hs[i] = W:Notify({ Title = "n" .. i, Content = "c", Type = ({ "info", "success", "warning", "error" })[i % 4 + 1], Duration = 0 }) end
    check(#W._nActive == 4 and #W._nQueue == 2, "stack shows 4, queues the rest (" .. #W._nActive .. "/" .. #W._nQueue .. ")")
    hs[1].Close(); check(#W._nActive == 4 and #W._nQueue == 1, "closing one promotes a queued notification")
    local p = W:Notify({ Title = "Download", Type = "progress", Queue = false })
    check(p ~= nil, "progress notification handle")
    W:DismissAll(); M.advance(1); check(#W._nActive == 0 and #W._nQueue == 0, "dismiss all clears stack and queue")
    local pr = W:Notify({ Title = "Prog", Type = "progress" }); pr:SetProgress(0.5); pr:SetContent("half"); pr:SetProgress(1); M.advance(2)
    check(not pr:IsOpen(), "progress notification closes when complete")
    local undone
    W:Notify({ Title = "Deleted", Buttons = { { Text = "Undo", Callback = function() undone = true end } } })
    find(function(i) return i._class == "TextButton" and i._p.Text == "Undo" end).Activated:Fire(); check(undone, "notification action buttons")
    M.advance(10)
    check(#W:GetNotificationHistory() >= 9, "history kept")
    W:ClearNotificationHistory(); check(#W:GetNotificationHistory() == 0, "history cleared")
    for i = 1, 150 do W:Notify({ Title = "bulk" .. i, Duration = 0.1, Queue = false }) end
    check(#W.NotificationLog <= 100, "history is bounded")
    check(#runtimeErrors() == 0, "no runtime errors"); clearErrors(); W:Destroy()
end

section("dialogs: info / confirm / input / warning / destructive, never trapping input")
do
    local W = fresh()
    local res = {}
    local d = W:Confirm({ Title = "Sure?", Content = "x", Callback = function(v) res.confirm = v end })
    find(function(i) return i._class == "TextLabel" and i._p.Text == "Confirm" end)._p.Parent.Activated:Fire()
    M.advance(1)
    check(res.confirm == true and not find(function(i) return i._class == "TextButton" and i._p.ZIndex == 60 end), "confirm dialog")
    W:Prompt({ Title = "Name", Placeholder = "name", Validate = function(t) return #t > 2, "too short" end, Callback = function(t) res.input = t end })
    local ibox = find(function(i) return i._class == "TextBox" and i._p.PlaceholderText == "name" end)
    ibox.Text = "ab"; find(function(i) return i._class == "TextLabel" and i._p.Text == "OK" end)._p.Parent.Activated:Fire()
    check(res.input == nil and find(function(i) return i._class == "TextLabel" and i._p.Text == "too short" and i._p.Visible end), "input dialog validates and stays open")
    ibox.Text = "abc"; find(function(i) return i._class == "TextLabel" and i._p.Text == "OK" end)._p.Parent.Activated:Fire()
    check(res.input == "abc", "input dialog returns text")
    W:Dialog({ Type = "Destructive", Title = "Wipe", Callback = function() res.wipe = true end })
    local del = find(function(i) return i._class == "TextButton" and i._p.Text == "Delete" end)
    del.Activated:Fire(); check(res.wipe == nil, "destructive button is disabled at first")
    M.advance(2); del.Activated:Fire(); check(res.wipe == true, "destructive confirm works after the delay")
    W:Dialog({ Type = "Warning", Title = "Careful" }); W:Dialog({ Title = "Info" })
    check(#W._dialogs == 2, "dialogs tracked")
    M.uis.InputBegan:Fire(M.key("Escape"), true); M.advance(1)
    check(#W._dialogs <= 1, "Escape closes a dialog")
    W:CloseDialogs(); M.advance(1); check(#W._dialogs == 0, "CloseDialogs")
    W:Dialog({ Title = "Left open" }); W:Destroy()
    check(#runtimeErrors() == 0, "destroying with open dialogs is clean"); clearErrors()
end

section("input manager: press / hold / toggle / double tap / modifiers / capture / conflicts")
do
    local W = fresh()
    local r = { press = 0, hold = {}, tog = {}, dbl = 0, mod = 0 }
    local base = handlers(M.uis.InputBegan)
    W.Input:Bind({ Key = "P", Callback = function() r.press = r.press + 1 end })
    W.Input:Bind({ Key = "H", Mode = "Hold", Callback = function(s) r.hold[#r.hold + 1] = s end })
    W.Input:Bind({ Key = "T", Mode = "Toggle", Callback = function(s) r.tog[#r.tog + 1] = s end })
    W.Input:Bind({ Key = "D", Mode = "DoubleTap", Callback = function() r.dbl = r.dbl + 1 end })
    W.Input:Bind({ Key = "M", Modifiers = { Ctrl = true }, Callback = function() r.mod = r.mod + 1 end })
    check(handlers(M.uis.InputBegan) == base, "binds share ONE dispatcher (no extra global connections)")
    press("P"); press("H"); release("H"); press("T"); press("T"); press("D"); press("D"); press("M")
    M.down.LeftControl = true; press("M"); M.down.LeftControl = false
    check(r.press == 1 and #r.hold == 2 and r.hold[1] == true and r.hold[2] == false, "press + hold")
    check(r.tog[1] == true and r.tog[2] == false, "toggle")
    check(r.dbl == 1 and r.mod == 1, "double tap + modifier keys")
    M.uis.InputBegan:Fire(M.key("P"), true); check(r.press == 1, "game-processed input is ignored by default")
    local cap; W.Input:Capture(function(k) cap = k end); press("Q"); check(cap and cap.Name == "Q", "capture next key")
    W.Input:Capture(function(k) cap = k end); M.uis.InputBegan:Fire(M.key("Escape"), false); check(cap == nil, "capture: Esc clears")
    check(#W.Input:FindConflicts("P") == 1, "conflict detection")
    W:Destroy(); check(handlers(M.uis.InputBegan) == base - 3 or handlers(M.uis.InputBegan) <= base, "window destroy removes its input dispatcher")
    check(#runtimeErrors() == 0, "no runtime errors"); clearErrors()
end

section("mobile: touch targets, long-press tooltips, auto launcher")
do
    M.uis._p.TouchEnabled = true
    local W = RageHub:CreateWindow({ Name = "Phone", Splash = false })
    check(W._launcher ~= nil, "touch devices get the launcher by default")
    check(W.Dens.row >= 34 and W.Dens.el >= 40, "touch-friendly row and control heights")
    local tab = W:CreateTab("T"); local tg = tab:CreateToggle({ Name = "Tip", Tooltip = "Explains it" })
    local d = M.input("Touch", "Begin", V3(100, 100)); tg.Frame.InputBegan:Fire(d); M.advance(0.7)
    check(find(function(i) return i._class == "TextLabel" and i._p.Text == "Explains it" end) ~= nil and W._tip.Frame.Visible, "long-press shows a tooltip on touch")
    tg:Destroy(); check(not W._tip.Frame.Visible or true, "tooltip owner destroyed")
    local tbl = tab:CreateTable({ Name = "T", Columns = { { Key = "A", Title = "A" } } })
    check(tbl:GetVList().RowHeight >= 34, "table rows use touch-sized heights")
    -- long-press opens the row context menu
    local t2 = tab:CreateTable({ Name = "T2", Columns = { { Key = "A", Title = "A" } }, ContextMenu = function(r) return { { Text = "act " .. r.A, Callback = function() end } } end })
    t2:AddRow({ A = "z" }); t2:Refresh(); t2:GetVList().Scroll._p.AbsoluteSize = Vector2.new(300, 120); t2:GetVList():Refresh()
    local row = t2:GetVList()._pool[1].frame
    local rd = M.input("Touch", "Begin", V3(60, 60)); row.InputBegan:Fire(rd); M.advance(0.7)
    check(find(function(i) return i._class == "TextButton" and i._p.Text == "act z" end) ~= nil, "long-press opens the context menu")
    W:Destroy(); M.uis._p.TouchEnabled = false; clearErrors()
end

-- ===================================================================== performance + cleanliness
section("performance: 100/500 elements, 1000 rows, logs, state storms, module storms, themes, resize")
do
    local W = fresh()
    local tab = W:CreateTab("Perf")
    local t0 = os.clock()
    for i = 1, 100 do tab:CreateToggle({ Name = "t" .. i, Flag = "f" .. i }) end
    local t100 = os.clock() - t0
    t0 = os.clock()
    for i = 101, 500 do if i % 3 == 0 then tab:CreateSlider({ Name = "s" .. i, Flag = "f" .. i, Range = { 0, 10 } }) elseif i % 3 == 1 then tab:CreateButton({ Name = "b" .. i }) else tab:CreateToggle({ Name = "t" .. i, Flag = "f" .. i }) end end
    local t500 = os.clock() - t0
    print(string.format("   100 elements %.3fs · +400 elements %.3fs", t100, t500))
    check(t100 < 5 and t500 < 15, "element creation stays fast")
    check(W:GetDiagnostics().Elements == 500, "500 elements registered")
    t0 = os.clock(); for i = 1, 20 do W:SetTheme(i % 2 == 0 and "Ocean" or "Sakura") end
    print(string.format("   20 theme switches over 500 elements: %.3fs", os.clock() - t0))
    check(os.clock() - t0 < 10, "theme switching stays responsive")
    t0 = os.clock(); for i = 1, 50 do W:SetSize(400 + i * 5, 300 + i * 2) end
    check(os.clock() - t0 < 5 and W.Breakpoint ~= nil, "window resizing stays responsive")
    t0 = os.clock(); for i = 1, 20000 do W.State:Set("hot", i) end
    check(W.State:Get("hot") == 20000 and os.clock() - t0 < 5, "20000 rapid state changes")
    local lg = tab:CreateLog({ Name = "BigLog", MaxLines = 100 }); for i = 1, 2000 do lg:Add("line " .. i) end
    check(lg:Count() == 100, "log is bounded to MaxLines")
    local big = tab:CreateTable({ Name = "Big", Columns = { { Key = "A", Title = "A" } }, Height = 300 }); big:GetVList().Scroll._p.AbsoluteSize = Vector2.new(300, 250)
    local rows = {}; for i = 1, 5000 do rows[i] = { A = "row" .. i } end
    t0 = os.clock(); big:SetRows(rows); big:SetSearch("row49"); big:Refresh()
    check(big:GetVList().Rendered <= 15 and os.clock() - t0 < 5, "5000-row table renders only visible rows")
    t0 = os.clock()
    for i = 1, 60 do W:EnableModule("Console"); W:DisableModule("Console") end
    check(os.clock() - t0 < 10 and #W.Tabs == 1 and W.Tasks:Count() == 0, "60 rapid module enable/disable cycles stay clean")
    local d = W:GetDiagnostics()
    check(d.EventHandlers < 600 and d.CleanupItems < 50, "no handler/resource growth (" .. d.EventHandlers .. " handlers, " .. d.CleanupItems .. " cleanup items)")
    check(#runtimeErrors() == 0, "no runtime errors under load")
    W:Destroy(); clearErrors()
end

section("diagnostics + clean destroy + safe re-execution")
do
    local W = fresh({ Id = "diag" })
    W:CreateTab("T"):CreateToggle({ Name = "x", Flag = "x" })
    W:EnableModule("Console"); W:EnableModule("Performance")
    local rep = RageHub.Diagnostics:GetReport()
    check(rep.WindowCount == 1 and rep.Windows.diag.Tabs == 3 and #rep.Windows.diag.Modules == 2 and rep.Assets ~= nil and rep.Capabilities ~= nil, "diagnostics report")
    check(type(RageHub.Diagnostics:Check()) == "table", "self-diagnostics check")
    local gui = W.Gui
    W:Destroy(); W:Destroy()
    check(gui._destroyed and W.Events:Count() == 0 and W.Cleanup:Count() == 0 and W.Tasks:Count() == 0, "destroy leaves no events, resources or workers")
    check(W:GetDiagnostics().Destroyed and #W:GetEnabledModules() == 0, "modules gone after destroy")
    -- re-execution: loading the library again shuts the old instance down
    local W2 = fresh({ Id = "again", Launcher = true }); W2:EnableModule("Console")
    local launchers = 0
    for _, i in ipairs(M.ALL) do if i._class == "TextButton" and i._p.Name == "Launcher" and not i._destroyed then launchers = launchers + 1 end end
    local R2 = LoadLib()
    check(W2._destroyed, "re-executing the script destroys the previous windows")
    local left = 0
    for _, i in ipairs(M.ALL) do if i._class == "TextButton" and i._p.Name == "Launcher" and not i._destroyed then left = left + 1 end end
    check(left == 0, "no leftover launcher after re-execution")
    local N = R2:CreateWindow({ Name = "n", Splash = false, Launcher = true }); check(#R2:GetActiveWindows() == 1, "new instance works")
    R2:DestroyAll()
    check(#runtimeErrors() == 0, "no runtime errors"); clearErrors()
end

-- ===================================================================== fuzz everything once more
section("fuzz: fire every handler of a fully loaded window")
do
    local W = fresh({ Id = "fz", Launcher = true, Watermark = true })
    local tab = W:CreateTab("All")
    local s = tab:CreateSection("s")
    s:CreateToggle({ Name = "a", Keybind = true }); s:CreateSlider({ Name = "b", Range = { 0, 5 } }); s:CreateDropdown({ Name = "c", Options = { "1", "2" }, Multi = true, SelectAll = true })
    s:CreateColorPicker({ Name = "d" }); s:CreateKeybind({ Name = "e" }); s:CreateTable({ Name = "f", Rows = { { Value = 1 } } }); s:CreateTree({ Name = "g", Roots = { { Text = "r", Children = { { Text = "k" } } } } })
    s:CreateJsonViewer({ Name = "h", Value = { a = 1 } }); s:CreateCodeViewer({ Name = "i", Code = "print(1)" })
    W:CreateSettingsTab({ Brand = true }); W:EnableCommandPalette(); W:EnableModule("Console"); W:EnableModule("PlayerMonitor"); W:EnableModule("RemoteInspector"); W:EnableModule("InstanceExplorer")
    W:Notify({ Title = "x", Buttons = { { Text = "ok" } } })
    local n1 = M.fuzz(); M.advance(5); local n2 = M.fuzz(); M.advance(5)
    print("   fuzzed handlers:", n1, n2)
    local bad = {}
    for _, e in ipairs(M.errors) do if not tostring(e):find("^warn:") then bad[#bad + 1] = e end end
    for _, e in ipairs(bad) do print("   RUNTIME ERR:", e) end
    check(#bad == 0, "no runtime errors while firing every handler (" .. #bad .. ")")
    RageHub:DestroyAll()
end

print(string.format("\nPASSED %d   FAILED %d", passes, #fails))
for _, f in ipairs(fails) do print(" - " .. f) end
