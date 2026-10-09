--!nocheck
--[[
    ╔════════════════════════════════════════════════════════╗
    ║  RAGE HUB  v1.0.0   ·   RGC UI Framework               ║
    ║  Developer: DevNameGelo   ·   MIT License              ║
    ╚════════════════════════════════════════════════════════╝
    Single file · no UI dependencies · mobile-first · modular.

    CORE ≠ MODULES. The core gives you windows, tabs, elements, themes, state,
    events, tasks, cleanup, config, logging, notifications, dialogs, tables,
    trees, viewers and a module system. Heavy tools (Remote Inspector, Instance
    Explorer, Player Monitor, Performance, Console) are OPT-IN modules that cost
    nothing until a script enables them.

    Source map:  BOOT · SERVICES · UTILITIES · THEMES · RESOURCE MANAGER ·
    TASK MANAGER · EVENT BUS · STATE · LOGGER · SEARCH · ASSETS · INPUT ·
    ANIMATION/SOUND · UI PRIMITIVES · WINDOW · ELEMENTS · LAYOUT/PANELS ·
    VLIST · TABLE · TREE · CODE VIEW · JSON VIEW · COMPONENTS · NOTIFICATIONS ·
    DIALOGS · CONFIG · SETTINGS · MODULE SYSTEM · BUILT-IN MODULES ·
    DIAGNOSTICS · PUBLIC API
]]

------------------------------------------------------------------ BOOT
local function Svc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    if not ok or not s then return nil end
    if cloneref then
        local ok2, c = pcall(cloneref, s)
        if ok2 and c then return c end
    end
    return s
end

local Players          = Svc("Players")
local TweenService     = Svc("TweenService")
local UserInputService = Svc("UserInputService")
local HttpService      = Svc("HttpService")
local RunService       = Svc("RunService")
local GuiService       = Svc("GuiService")
local CoreGui          = Svc("CoreGui")
local Workspace        = Svc("Workspace")
local Stats            = Svc("Stats")
local LogService       = Svc("LogService")

local RageHub = {
    Version = "1.0.0", Name = "Rage Hub", Framework = "RGC UI Framework", Developer = "DevNameGelo",
}
local Window, Tab, Elements, Panel = {}, {}, {}, {}
Window.__index = Window

local FONT, FONT_MED, FONT_BOLD, FONT_CODE = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.Code
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

-- one namespaced global; a previous load is shut down cleanly (safe re-execution)
local env = (getgenv and getgenv()) or _G
do
    local prev = env.__RageHub
    if type(prev) == "table" and type(prev.Shutdown) == "function" then pcall(prev.Shutdown, "reload") end
end
local G = { Version = RageHub.Version, Windows = {}, Order = {}, Modules = {}, TopOrder = 1000, WindowCount = 0, ElementCount = 0 }
env.__RageHub = G

------------------------------------------------------------------ UTILITIES
local function Copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end
local function Round(n, d)
    local m = 10 ^ (d or 0)
    return math.floor(n * m + 0.5) / m
end
local function Trunc(s, n)
    s = tostring(s)
    if #s <= n then return s end
    return s:sub(1, n - 1) .. "…"
end
local function IsCallable(f) return type(f) == "function" end
local function NextOrder(self) self._o = (self._o or 0) + 1; return self._o end
local function Mix(a, b, t) return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
local function Hex(c) return string.format("%02X%02X%02X", Round(c.R * 255), Round(c.G * 255), Round(c.B * 255)) end

local function Warn(api, msg)
    warn("[RageHub] " .. tostring(api) .. ": " .. tostring(msg))
    G.Warnings = (G.Warnings or 0) + 1
end

-- capability detection: never assume an executor API exists
local function Caps()
    local hasHttp = false
    pcall(function() hasHttp = type(game.HttpGet) == "function" end)
    return {
        FileSystem = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
            and type(isfolder) == "function" and type(makefolder) == "function",
        Clipboard = (setclipboard or toclipboard or set_clipboard) ~= nil,
        CustomAsset = (getcustomasset or getsynasset) ~= nil,
        Http = hasHttp or (request or http_request or (syn and syn.request) or (http and http.request)) ~= nil,
        GetHui = gethui ~= nil, CloneRef = cloneref ~= nil,
        Touch = UserInputService and UserInputService.TouchEnabled == true,
        Keyboard = UserInputService and UserInputService.KeyboardEnabled == true,
        Mouse = UserInputService and UserInputService.MouseEnabled == true,
    }
end

local function ToKey(v)
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" then
        local ok, k = pcall(function() return Enum.KeyCode[v] end)
        if ok and k then return k end
        ok, k = pcall(function() return Enum.UserInputType[v] end)
        if ok and k then return k end
    end
    return nil
end

local function IsPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function Inside(gui, pos)
    local a, s = gui.AbsolutePosition, gui.AbsoluteSize
    return pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
end

-- Roblox values -> readable strings (shared by JSON viewer, code viewer, remote inspector)
local function InstPath(inst)
    local parts, cur = {}, inst
    local n = 0
    while cur and cur ~= game and n < 64 do
        table.insert(parts, 1, cur)
        cur = cur.Parent
        n = n + 1
    end
    if #parts == 0 then return "game" end
    local out
    for i, p in ipairs(parts) do
        local name = p.Name
        if i == 1 and p.Parent == game then out = 'game:GetService("' .. name .. '")'
        elseif name:match("^[%a_][%w_]*$") then out = (out or "game") .. "." .. name
        else out = (out or "game") .. "[" .. string.format("%q", name) .. "]" end
    end
    return out
end

local function Describe(v)
    local t = typeof(v)
    if t == "string" then return string.format("%q", v), "String"
    elseif t == "number" then
        if v ~= v then return "0/0", "Number" elseif v == math.huge then return "math.huge", "Number" end
        return string.format("%.14g", v), "Number"
    elseif t == "boolean" then return tostring(v), "Boolean"
    elseif t == "nil" then return "nil", "Nil"
    elseif t == "Instance" then return InstPath(v), "Instance"
    elseif t == "Vector3" then return string.format("Vector3.new(%s, %s, %s)", Round(v.X, 3), Round(v.Y, 3), Round(v.Z, 3)), "Vector"
    elseif t == "Vector2" then return string.format("Vector2.new(%s, %s)", Round(v.X, 3), Round(v.Y, 3)), "Vector"
    elseif t == "CFrame" then
        local p = v.Position
        return string.format("CFrame.new(%s, %s, %s)", Round(p.X, 3), Round(p.Y, 3), Round(p.Z, 3)), "Vector"
    elseif t == "Color3" then return string.format("Color3.fromRGB(%d, %d, %d)", Round(v.R * 255), Round(v.G * 255), Round(v.B * 255)), "Vector"
    elseif t == "UDim2" then return string.format("UDim2.new(%s, %s, %s, %s)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset), "Vector"
    elseif t == "EnumItem" then return tostring(v), "Enum"
    elseif t == "function" then return "function", "Nil"
    elseif t == "table" then return "table", "Table"
    end
    return tostring(v), "Nil"
end

local function Serialize(value, o)
    o = o or {}
    local maxDepth, maxItems, pretty = o.Depth or 6, o.MaxItems or 100, o.Pretty ~= false
    local seen = {}
    local function ser(v, depth, indent)
        if type(v) ~= "table" or typeof(v) ~= "table" then return (Describe(v)) end
        if seen[v] then return "<cycle>" end
        if depth > maxDepth then return "{...}" end
        seen[v] = true
        local parts, n, isArray = {}, 0, #v > 0
        local nl = pretty and ("\n" .. indent .. "  ") or " "
        if isArray then
            for i, x in ipairs(v) do
                n = n + 1
                if n > maxItems then parts[#parts + 1] = "-- +" .. (#v - maxItems) .. " more"; break end
                parts[#parts + 1] = ser(x, depth + 1, indent .. "  ")
            end
        end
        local keys = {}
        for k in pairs(v) do if not (isArray and type(k) == "number" and k >= 1 and k <= #v) then keys[#keys + 1] = k end end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            n = n + 1
            if n > maxItems then parts[#parts + 1] = "-- more"; break end
            local ks = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. (Describe(k)) .. "]")
            parts[#parts + 1] = ks .. " = " .. ser(v[k], depth + 1, indent .. "  ")
        end
        seen[v] = nil
        if #parts == 0 then return "{}" end
        return "{" .. nl .. table.concat(parts, "," .. nl) .. (pretty and ("\n" .. indent) or " ") .. "}"
    end
    return ser(value, 1, "")
end

------------------------------------------------------------------ RESOURCE MANAGER
local function Release(item)
    local t = typeof(item)
    if t == "function" then pcall(item)
    elseif t == "RBXScriptConnection" then pcall(function() item:Disconnect() end)
    elseif t == "Instance" then pcall(function() item:Destroy() end)
    elseif t == "thread" then pcall(task.cancel, item)
    elseif t == "table" then
        local f = item.Destroy or item.Disconnect or item.Cancel or item.Stop or item.Clean
        if type(f) == "function" then pcall(f, item) end
    end
end

local Cleanup = {}
Cleanup.__index = Cleanup
function Cleanup.new(name) return setmetatable({ Name = name or "cleanup", _items = {}, _destroyed = false, _children = {} }, Cleanup) end
function Cleanup:Add(item)
    if item == nil then return nil end
    if self._destroyed then Release(item); return item end
    self._items[#self._items + 1] = item
    return item
end
function Cleanup:Remove(item)
    for i = #self._items, 1, -1 do if self._items[i] == item then table.remove(self._items, i); return true end end
    return false
end
function Cleanup:Count()
    local n = #self._items
    for _, c in ipairs(self._children) do n = n + c:Count() end
    return n
end
function Cleanup:Child(name)
    local c = Cleanup.new(name)
    self._children[#self._children + 1] = c
    return c
end
function Cleanup:Clean()
    local items = self._items
    self._items = {}
    for i = #items, 1, -1 do Release(items[i]) end
    local kids = self._children
    self._children = {}
    for _, c in ipairs(kids) do c:Destroy() end
end
function Cleanup:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self:Clean()
end

------------------------------------------------------------------ EVENT BUS
local Events = {}
Events.__index = Events
function Events.new(onError) return setmetatable({ _h = {}, _n = 0, _onError = onError }, Events) end
function Events:On(name, cb)
    local bus = self
    local list = self._h[name]
    if not list then list = {}; self._h[name] = list end
    local conn = { Connected = true }
    local entry = { cb = cb, conn = conn }
    list[#list + 1] = entry
    self._n = self._n + 1
    function conn:Disconnect()
        if not conn.Connected then return end
        conn.Connected = false
        for i, e in ipairs(list) do if e == entry then table.remove(list, i); break end end
        bus._n = bus._n - 1
    end
    return conn
end
function Events:Once(name, cb)
    local c
    c = self:On(name, function(...) c:Disconnect(); cb(...) end)
    return c
end
function Events:Emit(name, ...)
    local list = self._h[name]
    if not list then return end
    for _, e in ipairs({ table.unpack(list) }) do
        if e.conn.Connected then
            local ok, err = pcall(e.cb, ...)
            if not ok and self._onError then self._onError(name, err) end
        end
    end
end
function Events:Count() return self._n end
function Events:Clear() self._h = {}; self._n = 0 end
function Events:Destroy() self:Clear() end

------------------------------------------------------------------ STATE STORE
local State = {}
State.__index = State
function State.new(events)
    return setmetatable({ _v = {}, _w = {}, _d = {}, _events = events }, State)
end
function State:Define(key, default)
    self._d[key] = default
    if self._v[key] == nil then self._v[key] = default end
    return self
end
function State:Get(key, fallback)
    local v = self._v[key]
    if v == nil then return fallback end
    return v
end
function State:Exists(key) return self._v[key] ~= nil end
function State:Set(key, value)
    local old = self._v[key]
    if old == value and type(value) ~= "table" then return false end
    self._v[key] = value
    local list = self._w[key]
    if list then
        for _, w in ipairs({ table.unpack(list) }) do
            if w.conn.Connected then
                local ok, err = pcall(w.cb, value, old, key)
                if not ok then warn("[RageHub] state watcher error (" .. tostring(key) .. "): " .. tostring(err)) end
            end
        end
    end
    if self._events then self._events:Emit("StateChanged", key, value, old) end
    return true
end
function State:Update(key, fn)
    local ok, v = pcall(fn, self._v[key])
    if not ok then warn("[RageHub] State:Update error: " .. tostring(v)); return false end
    return self:Set(key, v)
end
function State:Watch(key, cb, fireNow)
    local st = self
    local list = self._w[key]
    if not list then list = {}; self._w[key] = list end
    local conn = { Connected = true }
    local entry = { cb = cb, conn = conn }
    list[#list + 1] = entry
    function conn:Disconnect()
        if not conn.Connected then return end
        conn.Connected = false
        for i, e in ipairs(list) do if e == entry then table.remove(list, i); break end end
    end
    if fireNow and self._v[key] ~= nil then pcall(cb, self._v[key], nil, key) end
    return conn
end
function State:Unwatch(key, target)
    local list = self._w[key]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].cb == target or list[i].conn == target then list[i].conn.Connected = false; table.remove(list, i) end
    end
end
function State:Reset(key)
    if key ~= nil then self:Set(key, self._d[key]); return end
    for k in pairs(self._v) do self:Set(k, self._d[k]) end
end
function State:GetAll() return Copy(self._v) end
function State:WatcherCount()
    local n = 0
    for _, l in pairs(self._w) do n = n + #l end
    return n
end
-- namespaced view of a state store (used for module state)
function State:Scope(prefix)
    local parent = self
    local function k(key) return prefix .. "." .. key end
    local s = {}
    function s:Define(key, d) parent:Define(k(key), d); return s end
    function s:Get(key, f) return parent:Get(k(key), f) end
    function s:Exists(key) return parent:Exists(k(key)) end
    function s:Set(key, v) return parent:Set(k(key), v) end
    function s:Update(key, fn) return parent:Update(k(key), fn) end
    function s:Watch(key, cb, now) return parent:Watch(k(key), cb, now) end
    function s:Unwatch(key, t) return parent:Unwatch(k(key), t) end
    function s:Reset(key) if key then parent:Reset(k(key)) end end
    return s
end

------------------------------------------------------------------ TASK MANAGER
local Token = {}
Token.__index = Token
function Token.new(worker, gen)
    return setmetatable({ Cancelled = false, Generation = gen or 0, _w = worker, _cb = {} }, Token)
end
function Token:Cancel()
    if self.Cancelled then return end
    self.Cancelled = true
    local cbs = self._cb
    self._cb = {}
    for _, f in ipairs(cbs) do pcall(f) end
end
function Token:OnCancel(fn)
    if self.Cancelled then pcall(fn) else self._cb[#self._cb + 1] = fn end
end
function Token:IsValid() return not self.Cancelled and (not self._w or self._w.Generation == self.Generation) end
function Token:Wait(t) task.wait(t or 0); return self:IsValid() end

local Worker = {}
Worker.__index = Worker
function Worker:Start(fn, ...)
    if self._running then self:Stop("restart") end
    self.Generation = self.Generation + 1
    local token = Token.new(self, self.Generation)
    self.Token, self._fn, self._args, self._running = token, fn, table.pack(...), true
    local mgr, w = self._mgr, self
    local args = self._args
    local th = task.spawn(function()
        local ok, err = xpcall(fn, debug.traceback, token, table.unpack(args, 1, args.n))
        if not ok and not token.Cancelled then mgr:_error(w, err) end
        if w.Token == token then w._running = false end
    end)
    if w._running then w._thread = th end
    if self._timeout then
        self._timer = task.delay(self._timeout, function() if w.Token == token and w._running then w:Stop("timeout") end end)
    end
    return token
end
function Worker:Stop(reason)
    local token, th, timer = self.Token, self._thread, self._timer
    self._running, self._thread, self._timer = false, nil, nil
    if token then token:Cancel() end
    if timer then pcall(task.cancel, timer) end
    if th and not self.Cooperative then pcall(task.cancel, th) end
    self.StopReason = reason
end
function Worker:Cancel() self:Stop("cancel") end
function Worker:Restart() if self._fn then return self:Start(self._fn, table.unpack(self._args, 1, self._args.n)) end end
function Worker:Timeout(sec) self._timeout = sec; return self end
function Worker:IsRunning() return self._running == true end
function Worker:Destroy() self:Stop("destroy"); self._mgr._workers[self.Name] = nil end

local Tasks = {}
Tasks.__index = Tasks
function Tasks.new(logger, parent, scope)
    local m = setmetatable({ _workers = {}, _logger = logger, _children = {}, _gens = {}, _scope = scope or "Core", _live = 0 }, Tasks)
    m._parent = parent
    if parent then parent._children[#parent._children + 1] = m end
    return m
end
function Tasks:Detach()
    local p = self._parent
    if not p then return end
    for i, c in ipairs(p._children) do if c == self then table.remove(p._children, i); break end end
    self._parent = nil
end
function Tasks:_error(worker, err)
    if self._logger then self._logger:Error(self._scope, "Worker '" .. tostring(worker.Name) .. "' failed: " .. tostring(err)) end
end
function Tasks:Create(name, opts)
    name = name or ("worker" .. tostring(os.clock()))
    local w = self._workers[name]
    if w then return w end
    w = setmetatable({ Name = name, Generation = 0, _mgr = self, Cooperative = opts and opts.Cooperative or false }, Worker)
    self._workers[name] = w
    return w
end
function Tasks:Token() local t = Token.new(nil, 0); self._tokens = self._tokens or {}; self._tokens[#self._tokens + 1] = t; return t end
function Tasks:NewGeneration(key) self._gens[key] = (self._gens[key] or 0) + 1; return self._gens[key] end
function Tasks:IsCurrent(key, gen) return self._gens[key] == gen end
function Tasks:Spawn(fn, ...)
    local name = "oneshot" .. tostring(self._live) .. "_" .. tostring(os.clock())
    local w = self:Create(name)
    local args = table.pack(...)
    w:Start(function(token) fn(token, table.unpack(args, 1, args.n)); w._mgr._workers[w.Name] = nil end)
    return w
end
function Tasks:Delay(sec, fn)
    local w = self:Create("delay_" .. tostring(os.clock()) .. "_" .. tostring(math.random(1e6)))
    w:Start(function(token)
        task.wait(sec)
        if token:IsValid() then fn() end
        w._mgr._workers[w.Name] = nil
    end)
    return w
end
function Tasks:Every(interval, fn, name)
    local w = self:Create(name or ("every_" .. tostring(math.random(1e6))))
    w:Start(function(token)
        while token:IsValid() do
            fn(token)
            task.wait(interval)
        end
    end)
    return w
end
function Tasks:Count()
    local n = 0
    for _, w in pairs(self._workers) do if w._running then n = n + 1 end end
    for _, c in ipairs(self._children) do n = n + c:Count() end
    return n
end
function Tasks:List()
    local out = {}
    for name, w in pairs(self._workers) do out[#out + 1] = { Name = name, Running = w._running, Generation = w.Generation } end
    return out
end
function Tasks:CancelAll()
    for _, w in pairs(Copy(self._workers)) do w:Stop("cancelall") end
    for _, t in ipairs(self._tokens or {}) do t:Cancel() end
    for _, c in ipairs(self._children) do c:CancelAll() end
end
function Tasks:Destroy() self:CancelAll(); self._workers = {}; self._children = {} end

------------------------------------------------------------------ LOGGER
local LEVELS = { Trace = 1, Debug = 2, Info = 3, Success = 4, Warning = 5, Error = 6 }
local Logger = {}
Logger.__index = Logger
function Logger.new(max, debugMode)
    return setmetatable({ _e = {}, _max = max or 500, _subs = {}, DebugMode = debugMode == true, Print = true, Total = 0 }, Logger)
end
function Logger:Log(level, module, msg, meta)
    if (level == "Trace" or level == "Debug") and not self.DebugMode then return nil end
    self.Total = self.Total + 1
    local e = {
        Id = self.Total, Time = os.time(), Clock = os.date("%H:%M:%S"), Level = level, Module = module or "Core",
        Message = tostring(msg), Meta = meta,
    }
    self._e[#self._e + 1] = e
    if #self._e > self._max then table.remove(self._e, 1) end
    for _, s in ipairs({ table.unpack(self._subs) }) do pcall(s, e) end
    if level == "Error" and self.Print then warn(string.format("[RageHub] [%s] %s", e.Module, e.Message)) end
    return e
end
for name in pairs(LEVELS) do
    Logger[name] = function(self, module, msg, meta) return self:Log(name, module, msg, meta) end
end
Logger.Warn = Logger.Warning
function Logger:Subscribe(fn)
    self._subs[#self._subs + 1] = fn
    local lg = self
    return { Connected = true, Disconnect = function() for i, s in ipairs(lg._subs) do if s == fn then table.remove(lg._subs, i); break end end end }
end
function Logger:Get(f)
    f = f or {}
    local out = {}
    local minL = f.Level and LEVELS[f.Level] or 0
    local q = f.Search and f.Search ~= "" and f.Search:lower() or nil
    for _, e in ipairs(self._e) do
        local ok = LEVELS[e.Level] >= minL
        if ok and f.Exact and e.Level ~= f.Exact then ok = false end
        if ok and f.Module and f.Module ~= "All" and e.Module ~= f.Module then ok = false end
        if ok and q and not (e.Message:lower():find(q, 1, true) or e.Module:lower():find(q, 1, true)) then ok = false end
        if ok then out[#out + 1] = e end
    end
    return out
end
function Logger:Modules()
    local seen, out = {}, {}
    for _, e in ipairs(self._e) do if not seen[e.Module] then seen[e.Module] = true; out[#out + 1] = e.Module end end
    table.sort(out)
    return out
end
function Logger:Clear() self._e = {} end
function Logger:Count() return #self._e end
function Logger:Format(e) return string.format("[%s] [%s] %s\n%s", e.Clock, e.Module, string.upper(e.Level), e.Message) end
function Logger:Export()
    local lines = {}
    for _, e in ipairs(self._e) do lines[#lines + 1] = self:Format(e) end
    return table.concat(lines, "\n")
end
function Logger:Scope(module)
    local lg, s = self, {}
    for name in pairs(LEVELS) do s[name] = function(_, msg, meta) return lg:Log(name, module, msg, meta) end end
    s.Warn = s.Warning
    return s
end

------------------------------------------------------------------ SEARCH SERVICE
local SearchSvc = {}
-- modes: exact | contains | prefix | fuzzy ; returns a score (higher = better) or nil
function SearchSvc.Match(query, text, mode)
    if query == nil or query == "" then return 1 end
    local q, t = tostring(query):lower(), tostring(text):lower()
    mode = mode or "contains"
    if mode == "exact" then return t == q and 100 or nil
    elseif mode == "prefix" then return t:sub(1, #q) == q and 90 or nil
    elseif mode == "contains" then
        local i = t:find(q, 1, true)
        return i and (80 - math.min(i, 60)) or nil
    else
        local i = t:find(q, 1, true)
        if i then return 80 - math.min(i, 60) end
        local qi, score, last = 1, 40, 0
        for ti = 1, #t do
            if t:sub(ti, ti) == q:sub(qi, qi) then
                score = score - (ti - last > 1 and 2 or 0)
                last = ti
                qi = qi + 1
                if qi > #q then return math.max(score, 1) end
            end
        end
        return nil
    end
end
function SearchSvc.Filter(list, query, getText, mode)
    if query == nil or query == "" then return list end
    local scored = {}
    for i, item in ipairs(list) do
        local s = SearchSvc.Match(query, getText and getText(item) or item, mode)
        if s then scored[#scored + 1] = { item = item, s = s, i = i } end
    end
    if mode == "fuzzy" then table.sort(scored, function(a, b) if a.s ~= b.s then return a.s > b.s end return a.i < b.i end) end
    local out = {}
    for _, x in ipairs(scored) do out[#out + 1] = x.item end
    return out
end

------------------------------------------------------------------ CLIPBOARD
local ClipSvc = {}
function ClipSvc.Available() return (setclipboard or toclipboard or set_clipboard) ~= nil end
function ClipSvc.Copy(text)
    local fn = setclipboard or toclipboard or set_clipboard
    if not fn then return false, "Clipboard is not supported by this environment" end
    local ok, err = pcall(fn, tostring(text))
    return ok, err
end

------------------------------------------------------------------ ASSET MANAGER
-- Official branding lives in the repo: https://github.com/devnamegelo/Rage-Hub/tree/main/assets
local ASSET_BASE = "https://raw.githubusercontent.com/devnamegelo/Rage-Hub/main/assets/"
local Assets = {
    Icon = ASSET_BASE .. "ragehub-icon.png",
    Theme = ASSET_BASE .. "ragehub-theme.png",
    Folder = "RageHub/assets",
    _cache = {}, _pending = {}, _failed = {}, Downloads = 0, Requests = 0, Hits = 0, RetrySeconds = 60,
}
local function Djb(s) local h = 5381; for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end return string.format("%08x", h) end

local function HttpFetch(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" then return body end
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if req then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and type(res) == "table" and (res.StatusCode == nil or res.StatusCode == 200) and type(res.Body) == "string" then return res.Body end
    end
    return nil
end
local function LooksLikeImage(b)
    return type(b) == "string" and #b > 64 and (b:sub(1, 4) == "\137PNG" or b:sub(1, 2) == "\255\216" or b:sub(1, 4) == "GIF8" or b:sub(1, 4) == "RIFF")
end

function Assets:Alias(ref, branding)
    if ref == "Icon" then return (branding and branding.IconSource) or self.Icon end
    if ref == "Theme" then return (branding and branding.ThemeSource) or self.Theme end
    return ref
end

function Assets:_finish(key, content, err)
    if content then self._cache[key] = content; self._failed[key] = nil else self._failed[key] = os.clock() end
    local cbs = self._pending[key]
    self._pending[key] = nil
    for _, cb in ipairs(cbs or {}) do pcall(cb, content, err) end
end

function Assets:_download(key)
    local caps = Caps()
    local getasset = getcustomasset or getsynasset
    if not (caps.FileSystem and getasset) then return self:_finish(key, nil, "Executor lacks getcustomasset/writefile") end
    local fname = (key:match("([^/]+)$") or "asset.png"):gsub("[^%w%._%-]", "_")
    fname = Djb(key) .. "_" .. fname
    local path = self.Folder .. "/" .. fname
    local ok = pcall(function()
        local cur
        for seg in self.Folder:gmatch("[^/]+") do
            cur = cur and (cur .. "/" .. seg) or seg
            if not isfolder(cur) then makefolder(cur) end
        end
    end)
    if not ok then return self:_finish(key, nil, "Could not create asset folder") end
    local have = false
    pcall(function() have = isfile(path) and LooksLikeImage(readfile(path)) end)
    if not have then
        local body = HttpFetch(key)
        if not LooksLikeImage(body) then return self:_finish(key, nil, "Download failed or not an image") end
        self.Downloads = self.Downloads + 1
        if not pcall(writefile, path, body) then return self:_finish(key, nil, "Could not write asset file") end
    end
    local okc, content = pcall(getasset, path)
    if okc and content and content ~= "" then return self:_finish(key, content) end
    return self:_finish(key, nil, "getcustomasset failed")
end

-- cb(content|nil, err). Cached results never trigger a second download.
function Assets:Request(ref, cb)
    self.Requests = self.Requests + 1
    local key = ref
    if type(key) ~= "string" or key == "" then if cb then cb(nil, "no image") end return end
    if key:match("^%d+$") then key = "rbxassetid://" .. key end
    if key:match("^rbxassetid://") or key:match("^rbxasset://") or key:match("^rbxthumb://") then
        if cb then cb(key) end
        return
    end
    if not key:match("^https?://") then if cb then cb(nil, "unsupported image reference") end return end
    if self._cache[key] then self.Hits = self.Hits + 1; if cb then cb(self._cache[key]) end return end
    local failedAt = self._failed[key]
    if failedAt and os.clock() - failedAt < self.RetrySeconds then if cb then cb(nil, "previous load failed") end return end
    if self._pending[key] then if cb then table.insert(self._pending[key], cb) end return end
    self._pending[key] = { cb }
    task.spawn(function() self:_download(key) end)
end
function Assets:Get(ref)
    if type(ref) ~= "string" then return nil end
    if ref:match("^%d+$") then return "rbxassetid://" .. ref end
    if ref:match("^rbxasset") or ref:match("^rbxthumb") then return ref end
    return self._cache[ref]
end
function Assets:Preload(list) for _, r in ipairs(list) do self:Request(r) end end
function Assets:Stats()
    local n = 0
    for _ in pairs(self._cache) do n = n + 1 end
    return { Cached = n, Downloads = self.Downloads, Requests = self.Requests, Hits = self.Hits }
end
-- Bind an ImageLabel to a reference; `fallback` (a GuiObject) stays visible until the image is ready.
function Assets:Bind(img, ref, opts)
    opts = opts or {}
    local dead = false
    local handle = { Cancel = function() dead = true end, Destroy = function() dead = true end }
    self:Request(ref, function(content, err)
        if dead then return end
        local ok = false
        if content then ok = pcall(function() img.Image = content end) end
        if opts.Fallback then pcall(function() opts.Fallback.Visible = not ok end) end
        if opts.OnLoaded then pcall(opts.OnLoaded, ok, err) end
    end)
    return handle
end

------------------------------------------------------------------ THEMES (semantic tokens)
local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local TOKENS = { "Background", "Surface", "Surface2", "SurfaceHover", "SurfacePressed", "Border", "Text", "TextMuted", "TextDisabled",
    "Accent", "Accent2", "Success", "Warning", "Danger", "Info", "Shadow", "Overlay" }
local LEGACY = { Stroke = "Border", SubText = "TextMuted" }

local Themes = {}
local function NormalizeTheme(src, name)
    local raw = {}
    for k, v in pairs(src or {}) do raw[LEGACY[k] or k] = v end
    local t = {}
    for _, k in ipairs(TOKENS) do
        local v = raw[k]
        if v ~= nil and typeof(v) ~= "Color3" then Warn("Theme '" .. tostring(name) .. "'", "token " .. k .. " must be a Color3; using a default") v = nil end
        t[k] = v
    end
    t.Background = t.Background or RGB(10, 10, 14)
    t.Surface = t.Surface or Mix(t.Background, WHITE, 0.06)
    t.SurfaceHover = t.SurfaceHover or Mix(t.Surface, WHITE, 0.07)
    t.Surface2 = t.Surface2 or Mix(t.Surface, t.SurfaceHover, 0.5)
    t.SurfacePressed = t.SurfacePressed or Mix(t.Surface, BLACK, 0.18)
    t.Border = t.Border or Mix(t.Surface, WHITE, 0.18)
    t.Text = t.Text or RGB(240, 240, 245)
    t.TextMuted = t.TextMuted or Mix(t.Text, t.Background, 0.45)
    t.TextDisabled = t.TextDisabled or Mix(t.Text, t.Background, 0.7)
    t.Accent = t.Accent or RGB(255, 32, 48)
    t.Accent2 = t.Accent2 or t.Accent
    t.Success = t.Success or RGB(52, 211, 153)
    t.Warning = t.Warning or RGB(251, 191, 36)
    t.Danger = t.Danger or RGB(248, 95, 115)
    t.Info = t.Info or t.Accent2
    t.Shadow = t.Shadow or BLACK
    t.Overlay = t.Overlay or BLACK
    return t
end
local function DefTheme(name, d) Themes[name] = NormalizeTheme(d, name) end
DefTheme("Rage",     { Background = RGB(9, 7, 9),     Surface = RGB(20, 15, 17),  SurfaceHover = RGB(33, 22, 25),  Stroke = RGB(62, 36, 40),  Text = RGB(244, 238, 238), SubText = RGB(163, 138, 140), Accent = RGB(255, 36, 52),  Accent2 = RGB(255, 112, 70) })
DefTheme("Midnight", { Background = RGB(13, 14, 21),  Surface = RGB(22, 24, 35),  SurfaceHover = RGB(32, 35, 50),  Stroke = RGB(50, 54, 76),  Text = RGB(236, 239, 250), SubText = RGB(138, 145, 171), Accent = RGB(124, 92, 255), Accent2 = RGB(64, 170, 255) })
DefTheme("Crimson",  { Background = RGB(16, 11, 13),  Surface = RGB(27, 19, 22),  SurfaceHover = RGB(40, 27, 32),  Stroke = RGB(70, 46, 54),  Text = RGB(246, 237, 239), SubText = RGB(162, 138, 145), Accent = RGB(244, 63, 94),  Accent2 = RGB(251, 146, 60) })
DefTheme("Ocean",    { Background = RGB(9, 17, 26),   Surface = RGB(15, 28, 42),  SurfaceHover = RGB(22, 40, 59),  Stroke = RGB(37, 62, 88),  Text = RGB(230, 242, 252), SubText = RGB(127, 154, 178), Accent = RGB(34, 178, 238), Accent2 = RGB(45, 212, 191) })
DefTheme("Emerald",  { Background = RGB(10, 17, 14),  Surface = RGB(17, 29, 24),  SurfaceHover = RGB(25, 42, 35),  Stroke = RGB(40, 66, 55),  Text = RGB(231, 247, 240), SubText = RGB(130, 160, 146), Accent = RGB(16, 185, 129), Accent2 = RGB(132, 204, 22) })
DefTheme("Sakura",   { Background = RGB(20, 13, 19),  Surface = RGB(32, 21, 30),  SurfaceHover = RGB(46, 30, 43),  Stroke = RGB(78, 52, 72),  Text = RGB(250, 238, 247), SubText = RGB(170, 140, 163), Accent = RGB(236, 72, 153), Accent2 = RGB(168, 85, 247) })
DefTheme("Sunset",   { Background = RGB(20, 12, 16),  Surface = RGB(32, 20, 24),  SurfaceHover = RGB(46, 29, 34),  Stroke = RGB(80, 52, 58),  Text = RGB(252, 240, 235), SubText = RGB(176, 146, 148), Accent = RGB(255, 94, 77),  Accent2 = RGB(255, 195, 0) })
DefTheme("Dracula",  { Background = RGB(24, 25, 33),  Surface = RGB(33, 34, 46),  SurfaceHover = RGB(45, 47, 62),  Stroke = RGB(68, 71, 90),  Text = RGB(248, 248, 242), SubText = RGB(150, 155, 185), Accent = RGB(189, 147, 249), Accent2 = RGB(255, 121, 198) })
DefTheme("Nord",     { Background = RGB(36, 41, 51),  Surface = RGB(46, 52, 64),  SurfaceHover = RGB(59, 66, 82),  Stroke = RGB(76, 86, 106), Text = RGB(236, 239, 244), SubText = RGB(153, 166, 189), Accent = RGB(136, 192, 208), Accent2 = RGB(163, 190, 140) })
DefTheme("Void",     { Background = RGB(0, 0, 0),     Surface = RGB(12, 12, 14),  SurfaceHover = RGB(22, 22, 26),  Stroke = RGB(42, 42, 50),  Text = RGB(240, 240, 245), SubText = RGB(125, 125, 140), Accent = RGB(0, 229, 160),  Accent2 = RGB(0, 170, 255) })
DefTheme("Light",    { Background = RGB(243, 245, 250), Surface = RGB(255, 255, 255), SurfaceHover = RGB(236, 239, 247), Stroke = RGB(214, 219, 232), Text = RGB(28, 31, 45), SubText = RGB(108, 115, 140), Accent = RGB(99, 102, 241), Accent2 = RGB(14, 165, 233) })
G.DefaultTheme = "Rage"

------------------------------------------------------------------ INPUT (one dispatcher per window)
local Input = {}
Input.__index = Input

function Input.new(win)
    local self = setmetatable({ win = win, _binds = {}, _n = 0, _cap = nil, _drag = nil }, Input)
    local c = win.Cleanup
    c:Add(UserInputService.InputBegan:Connect(function(i, gp) self:_began(i, gp) end))
    c:Add(UserInputService.InputEnded:Connect(function(i, gp) self:_ended(i, gp) end))
    c:Add(UserInputService.InputChanged:Connect(function(m) local d = self._drag; if d then d(m) end end))
    return self
end

local function ModsOk(mods)
    if not (mods.Ctrl or mods.Shift or mods.Alt) then return true end
    local function down(a, b) return UserInputService:IsKeyDown(a) or UserInputService:IsKeyDown(b) end
    local ctrl = down(Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
    local shift = down(Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
    local alt = down(Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt)
    return (mods.Ctrl == true) == ctrl and (mods.Shift == true) == shift and (mods.Alt == true) == alt
end

function Input:Bind(o)
    self._n = self._n + 1
    local list = self._binds
    local b = {
        Id = o.Id or ("bind" .. self._n), Key = ToKey(o.Key), Mode = o.Mode or "Press", Callback = o.Callback,
        OnPress = o.OnPress, OnRelease = o.OnRelease, Mods = o.Modifiers or {}, Enabled = true,
        AllowGP = o.AllowGameProcessed == true, State = false, LastTap = 0, Owner = o.Owner or { Name = o.Id or "bind" },
    }
    list[#list + 1] = b
    local h = { Id = b.Id, Connected = true }
    function h:SetKey(k) b.Key = ToKey(k) end
    function h:GetKey() return b.Key end
    function h:SetEnabled(v) b.Enabled = v ~= false end
    function h:GetState() return b.State end
    function h:Disconnect()
        h.Connected = false
        for i, x in ipairs(list) do if x == b then table.remove(list, i); break end end
    end
    h.Destroy = h.Disconnect
    if o.Cleanup then o.Cleanup:Add(h) end
    return h
end

function Input:_fire(b, down)
    local win = self.win
    if b.OnPress or b.OnRelease then
        local f = down and b.OnPress or b.OnRelease
        if f then win:Call(b.Owner, f) end
        return
    end
    if not b.Callback then return end
    if b.Mode == "Hold" then
        if down then b.State = true; win:Call(b.Owner, b.Callback, true)
        elseif b.State then b.State = false; win:Call(b.Owner, b.Callback, false) end
    elseif not down then return
    elseif b.Mode == "Toggle" then b.State = not b.State; win:Call(b.Owner, b.Callback, b.State)
    elseif b.Mode == "DoubleTap" then
        local now = os.clock()
        if now - b.LastTap < 0.3 then b.LastTap = 0; win:Call(b.Owner, b.Callback) else b.LastTap = now end
    else win:Call(b.Owner, b.Callback, b.Key) end
end

function Input:_began(i, gp)
    if self._cap then return self:_captureInput(i) end
    for _, b in ipairs({ table.unpack(self._binds) }) do
        if b.Enabled and b.Key and (i.KeyCode == b.Key or i.UserInputType == b.Key) and (b.AllowGP or not gp) and ModsOk(b.Mods) then
            self:_fire(b, true)
        end
    end
end
function Input:_ended(i)
    for _, b in ipairs({ table.unpack(self._binds) }) do
        if b.Enabled and b.Key and (i.KeyCode == b.Key or i.UserInputType == b.Key) and (b.State or b.OnRelease) then
            self:_fire(b, false)
        end
    end
end

-- Capture the next key / mouse button. cb(key) | cb(nil) = cleared (Esc) | cb(false) = cancelled
function Input:Capture(cb, opts)
    self._cap = { cb = cb, inside = opts and opts.Inside }
    local me = self._cap
    return function() if self._cap == me then self._cap = nil end end
end
function Input:IsCapturing() return self._cap ~= nil end
function Input:_captureInput(i)
    local cap = self._cap
    local done = function(v) self._cap = nil; self.win:Call({ Name = "key capture" }, cap.cb, v) end
    if i.UserInputType == Enum.UserInputType.Keyboard then
        done(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil)
    elseif i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then
        done(i.UserInputType)
    elseif IsPointer(i) and not (cap.inside and Inside(cap.inside, i.Position)) then
        done(false)
    end
end
function Input:FindConflicts(key, except)
    local out = {}
    key = ToKey(key)
    for _, b in ipairs(self._binds) do
        if b.Key and b.Key == key and b.Id ~= (except and except.Id) then out[#out + 1] = b.Id end
    end
    return out
end
function Input:Count() return #self._binds end

-- one active pointer drag per window; follows the exact finger for touch
function Input:BeginDrag(i, onMove, onEnd)
    if self._drag then return false end
    local touch = i.UserInputType == Enum.UserInputType.Touch
    self._drag = function(m)
        if touch then
            if m ~= i then return end
        elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        onMove(m.Position)
    end
    local c
    c = i.Changed:Connect(function()
        if i.UserInputState == Enum.UserInputState.End then
            c:Disconnect()
            self._drag = nil
            if onEnd then onEnd() end
        end
    end)
    return true
end

------------------------------------------------------------------ SOUND MANAGER
local SOUND_IDS = {
    click = "rbxasset://sounds/button.wav", toggle = "rbxasset://sounds/switch.mp3", notify = "rbxasset://sounds/electronicpingshort.wav",
    open = "rbxasset://sounds/switch.mp3", close = "rbxasset://sounds/button.wav", success = "rbxasset://sounds/electronicpingshort.wav",
    error = "rbxasset://sounds/button.wav",
}
local SoundMgr = {}
SoundMgr.__index = SoundMgr
function SoundMgr.new(win) return setmetatable({ win = win, Enabled = false, Volume = 0.35, _s = {} }, SoundMgr) end
function SoundMgr:SetEnabled(v) self.Enabled = v and true or false end
function SoundMgr:Play(kind)
    if not self.Enabled then return end
    local s = self._s[kind]
    if not s then
        local ok, inst = pcall(function()
            local x = Instance.new("Sound")
            x.SoundId = SOUND_IDS[kind] or SOUND_IDS.click
            x.Volume = self.Volume
            x.Parent = self.win.Gui
            return x
        end)
        if not ok then return end
        s = inst
        self._s[kind] = s
    end
    pcall(function() s.TimePosition = 0; s:Play() end)
end

------------------------------------------------------------------ UI PRIMITIVES (theme-independent)
local function Corner(r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); return c end
local function CornerFull() local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); return c end
local function Pad(l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingTop, p.PaddingRight, p.PaddingBottom = UDim.new(0, l), UDim.new(0, t), UDim.new(0, r), UDim.new(0, b)
    return p
end
local function List(pad, dir, ha)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    if dir then l.FillDirection = dir end
    if ha then l.HorizontalAlignment = ha end
    return l
end

local function Mount(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    local ok = pcall(function()
        if gethui then gui.Parent = gethui() else gui.Parent = CoreGui end
    end)
    if not ok or not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

------------------------------------------------------------------ WINDOW · services, kit, theme
local DENSITY = {
    Compact = { el = 34, elDesc = 46, row = 24, font = 0.94 },
    Comfortable = { el = 40, elDesc = 52, row = 28, font = 1 },
    Spacious = { el = 46, elDesc = 58, row = 32, font = 1.07 },
}
local ANIM = { off = 0, fast = 0.6, normal = 1, slow = 1.6 }

-- Error boundary for every user callback: one bad callback never takes the UI down.
function Window:Call(owner, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, res = xpcall(fn, debug.traceback, ...)
    if ok then return res end
    self.CallbackErrors = (self.CallbackErrors or 0) + 1
    local mod = owner and owner.Module or "Core"
    local el = owner and (owner.Name or owner.Id) or "?"
    self.Logger:Error(mod, string.format("Callback error\nModule: %s\nElement: %s\nError: %s", tostring(mod), tostring(el), tostring(res)))
    return nil
end

function Window:_buildKit()
    local win = self
    local bound = setmetatable({}, { __mode = "k" })
    self._bound = bound
    self._rerender = {}
    local function New(class, props, children)
        local inst = Instance.new(class)
        local parent
        for k, v in pairs(props or {}) do
            if k == "Parent" then parent = v
            elseif type(v) == "string" and v:sub(1, 1) == "$" and k:find("Color") then
                local key = v:sub(2)
                inst[k] = win.Theme[key]
                bound[inst] = bound[inst] or {}
                table.insert(bound[inst], { k, key })
            else inst[k] = v end
        end
        for _, c in ipairs(children or {}) do c.Parent = inst end
        inst.Parent = parent
        return inst
    end
    local function Text(props, children)
        local p = { BackgroundTransparency = 1, BorderSizePixel = 0, Font = FONT_MED, TextSize = 13, TextColor3 = "$Text", TextXAlignment = Enum.TextXAlignment.Left }
        for k, v in pairs(props) do p[k] = v end
        p.TextSize = math.max(8, math.floor(p.TextSize * win.FontScale + 0.5))
        return New("TextLabel", p, children)
    end
    local function Stroke(color, thick, trans)
        return New("UIStroke", { Color = color or "$Border", Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    end
    local function Gradient(parent, rotation)
        local g = New("UIGradient", { Rotation = rotation or 0, Parent = parent })
        local function paint() g.Color = ColorSequence.new(win.Theme.Accent, win.Theme.Accent2) end
        paint()
        win:OnTheme(paint, g)
        return g
    end
    self._kit = { New, Text, Stroke, Gradient }
end
function Window:Kit() return table.unpack(self._kit) end

-- owner: an instance whose destruction drops the callback (keeps the list bounded)
function Window:OnTheme(fn, owner)
    self._rerender[#self._rerender + 1] = { fn = fn, owner = owner }
    return fn
end
function Window:_refreshTheme()
    for inst, list in pairs(self._bound) do
        for _, b in ipairs(list) do pcall(function() inst[b[1]] = self.Theme[b[2]] end) end
    end
    local keep = {}
    for _, r in ipairs(self._rerender) do
        if not r.owner or r.owner.Parent ~= nil then
            keep[#keep + 1] = r
            pcall(r.fn)
        end
    end
    self._rerender = keep
    self.Events:Emit("ThemeChanged", self.ThemeName, self.Theme)
end
function Window:SetTheme(name)
    local t
    if type(name) == "table" then
        t = NormalizeTheme(name, "Custom")
        name = "Custom"
    else
        t = Themes[name]
        if not t then Warn("Window:SetTheme", "unknown theme '" .. tostring(name) .. "'"); return false end
    end
    for k, v in pairs(t) do self.Theme[k] = v end
    self.ThemeName = name
    self:_refreshTheme()
    return true
end
function Window:GetTheme() return self.ThemeName end
function Window:SetAccent(c1, c2)
    if typeof(c1) ~= "Color3" then Warn("Window:SetAccent", "expected a Color3"); return false end
    self.Theme.Accent = c1
    self.Theme.Accent2 = typeof(c2) == "Color3" and c2 or c1
    self:_refreshTheme()
    return true
end

-- animation manager: every transition goes through here (speed: off | fast | normal | slow)
function Window:Tween(inst, props, t, style, dir)
    local f = self.AnimFactor
    if f == 0 then
        for k, v in pairs(props) do pcall(function() inst[k] = v end) end
        return { Cancel = function() end }
    end
    local tw = TweenService:Create(inst, TweenInfo.new((t or 0.2) * f, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
function Window:SetAnimation(mode)
    if ANIM[mode] == nil then Warn("Window:SetAnimation", "use off | fast | normal | slow"); return false end
    self.AnimMode, self.AnimFactor = mode, ANIM[mode]
    return true
end
function Window:Hover(frame)
    frame.MouseEnter:Connect(function() self:Tween(frame, { BackgroundColor3 = self.Theme.SurfaceHover }, 0.12) end)
    frame.MouseLeave:Connect(function() self:Tween(frame, { BackgroundColor3 = self.Theme.Surface }, 0.12) end)
end

function Window:_beginDrag(i, onMove, onEnd) return self.Input:BeginDrag(i, onMove, onEnd) end

local function MakeDraggable(win, handle, target, onClick, onEnd)
    handle.InputBegan:Connect(function(i)
        if not IsPointer(i) then return end
        local startPos, startUI, moved = i.Position, target.Position, 0
        win:_beginDrag(i, function(p)
            local d = p - startPos
            moved = math.max(moved, d.Magnitude)
            target.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
        end, function()
            if onClick and moved < 6 then onClick() end
            if onEnd and moved >= 6 then onEnd() end
        end)
    end)
end

------------------------------------------------------------------ WINDOW · tooltips
function Window:_buildTip()
    local New, Text, Stroke = self:Kit()
    local frame = New("Frame", {
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = "$Surface", BorderSizePixel = 0,
        Visible = false, ZIndex = 100, Parent = self.Gui,
    }, { Corner(6), Stroke("$Accent", 1, 0.3), Pad(8, 5, 8, 5), New("UISizeConstraint", { MaxSize = Vector2.new(240, 200) }) })
    local label = Text({ Text = "", TextSize = 12, TextWrapped = true, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, ZIndex = 101, Parent = frame })
    self._tip = { Frame = frame, Label = label }
end

-- hover (desktop) + long-press (touch); positioned with edge clamping; hidden when its owner dies
function Window:Tooltip(frame, text)
    local win = self
    local tip = self._tip
    local timer, shown = nil, false
    local function place(p)
        local vp = Workspace.CurrentCamera.ViewportSize
        local sz = tip.Frame.AbsoluteSize
        local x = math.clamp(p.X + 16, 4, math.max(4, vp.X - sz.X - 4))
        local y = p.Y + 22
        if y + sz.Y > vp.Y - 4 then y = math.max(4, p.Y - sz.Y - 12) end
        tip.Frame.Position = UDim2.fromOffset(x, y)
    end
    local function show(p)
        tip.Label.Text = tostring(type(text) == "function" and text() or text)
        tip.Frame.Visible = true
        shown = true
        place(p)
    end
    local function hide()
        if timer then pcall(task.cancel, timer); timer = nil end
        if shown then tip.Frame.Visible = false; shown = false end
    end
    frame.MouseEnter:Connect(function()
        timer = task.delay(0.35, function() timer = nil; show(UserInputService:GetMouseLocation() - GuiService:GetGuiInset()) end)
    end)
    frame.MouseMoved:Connect(function() if shown then place(UserInputService:GetMouseLocation() - GuiService:GetGuiInset()) end end)
    frame.MouseLeave:Connect(hide)
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            local pos = i.Position
            timer = task.delay(0.5, function() timer = nil; show(pos); task.delay(2.5, hide) end)
        end
    end)
    frame.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch and not shown then hide() end end)
    frame.Destroying:Connect(hide)
end

------------------------------------------------------------------ WINDOW · branding & launcher
RageHub.Branding = { Icon = "Icon", ThemeImage = "Theme", Name = "Rage Hub", Tagline = "RGC UI Framework", Developer = "DevNameGelo", Header = false }
RageHub.Assets = Assets

function Window:BrandImage(kind)
    local v = self.Branding[kind]
    if v == nil or v == false then return nil end
    return Assets:Alias(v)
end

function Window:SetBranding(tbl)
    if type(tbl) ~= "table" then Warn("SetBranding", "expected a table"); return false end
    for k, v in pairs(tbl) do self.Branding[k] = v end
    self:_applyBranding()
    self.Events:Emit("BrandingChanged", self.Branding)
    return true
end
function RageHub:SetBranding(tbl)
    if type(tbl) ~= "table" then Warn("RageHub:SetBranding", "expected a table"); return false end
    for k, v in pairs(tbl) do RageHub.Branding[k] = v end
    for _, w in pairs(G.Windows) do w:SetBranding(tbl) end
    return true
end
function Window:SetLauncherIcon(ref) return self:SetBranding({ Icon = ref }) end

-- Rounded image + fallback: used by launcher, splash, About and the Image element
function Window:_brandCircle(parent, size, kind)
    local New, Text, Stroke, Gradient = self:Kit()
    local holder = New("Frame", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = parent }, { CornerFull() })
    local fb = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = holder }, { CornerFull() })
    Gradient(fb, 45)
    Text({ Text = "RH", Font = FONT_BOLD, TextSize = math.floor(size * 0.38), TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = fb })
    local img = New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 2, Parent = holder }, { CornerFull() })
    local h = { Holder = holder, Image = img, Fallback = fb }
    function h:Load(ref)
        if self._bind then self._bind.Cancel() end
        fb.Visible = true
        img.Image = ""
        if ref then self._bind = Assets:Bind(img, ref, { Fallback = fb }) end
    end
    return h
end

function Window:_applyBranding()
    if self._launcherArt then self._launcherArt:Load(self:BrandImage("Icon")) end
    if self._headerArt then self._headerArt:Load(self:BrandImage("Icon")) end
end

function Window:_launcherSize()
    local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.floor(math.min(vp.X, vp.Y) * 0.12), 44, 60)
end

function Window:_buildLauncher(opt)
    local win = self
    local New, Text, Stroke = self:Kit()
    opt = type(opt) == "table" and opt or {}
    local size = opt.Size or self:_launcherSize()
    local btn = New("TextButton", {
        Name = "Launcher", Position = opt.Position or UDim2.new(0, 10, 0.4, 0), Size = UDim2.fromOffset(size, size), BackgroundColor3 = "$Background",
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 20, Parent = self.Gui,
    }, { CornerFull() })
    local ring = Stroke("$Accent", 2, 0.2)
    ring.Parent = btn
    local art = self:_brandCircle(btn, size, "Icon")
    art.Holder.BackgroundTransparency = 1
    art.Holder.Active = false
    art.Holder.ZIndex = 21
    art.Holder.Size = UDim2.fromScale(1, 1)
    self._launcher, self._launcherArt, self._launcherRing = btn, art, ring
    art:Load(self:BrandImage("Icon"))
    local function snap()
        if opt.Snap == false then return end
        local vp = Workspace.CurrentCamera.ViewportSize
        local p, s = btn.AbsolutePosition, btn.AbsoluteSize
        local sz = s.X > 0 and s.X or size
        local x = (p.X + sz / 2 < vp.X / 2) and 8 or (vp.X - sz - 8)
        local y = math.clamp(p.Y, 8, math.max(8, vp.Y - sz - 8))
        self:Tween(btn, { Position = UDim2.fromOffset(x, y) }, 0.25, Enum.EasingStyle.Back)
    end
    MakeDraggable(self, btn, btn, function() win:Toggle() end, snap)
    local function ringState() ring.Transparency = win.Visible and 0 or 0.55 end
    self.Events:On("Shown", ringState)
    self.Events:On("Hidden", ringState)
    ringState()
    self.Cleanup:Add(btn)
end
function Window:SetLauncherVisible(v)
    if self._launcher then self._launcher.Visible = v and true or false
    elseif v then self:_buildLauncher({}) end
end

------------------------------------------------------------------ WINDOW · layout, breakpoints, panels
local function BreakpointFor(w) if w < 520 then return "Small" elseif w < 820 then return "Medium" end return "Large" end

function Window:_updateBreakpoint()
    local bp = BreakpointFor(self._size.X)
    if bp ~= self.Breakpoint then
        local old = self.Breakpoint
        self.Breakpoint = bp
        if not self._userSidebar then self.SidebarCollapsed = (bp == "Small") end
        self.Events:Emit("BreakpointChanged", bp, old)
    end
end

function Window:_dockOf(p)
    if p._floating then return "Float" end
    if p.DockSide == "Right" and self.Breakpoint == "Small" then return "Bottom" end
    return p.DockSide
end

function Window:_relayout(anim)
    if not self._side then return end
    local small = self.Breakpoint == "Small"
    local sideW = self.SidebarCollapsed and 0 or (small and 112 or 128)
    local sideTot = self.SidebarCollapsed and 0 or (sideW + 16)
    local right, bottom = {}, {}
    for _, p in ipairs(self.Panels) do
        if p._visible then
            local d = self:_dockOf(p)
            if d == "Right" then right[#right + 1] = p elseif d == "Bottom" then bottom[#bottom + 1] = p end
        end
    end
    local rightW, bottomH = 0, 0
    if #right > 0 then
        for _, p in ipairs(right) do rightW = math.max(rightW, p.Size or 240) end
        rightW = math.clamp(rightW, 160, math.max(160, math.floor(self._size.X * 0.45)))
    end
    if #bottom > 0 then
        for _, p in ipairs(bottom) do bottomH = math.max(bottomH, p.DockSide == "Bottom" and (p.Size or 150) or 150) end
        bottomH = math.clamp(bottomH, 90, math.max(90, math.floor(self._size.Y * 0.5)))
    end
    local function setp(inst, props)
        if anim then self:Tween(inst, props, 0.22) else for k, v in pairs(props) do inst[k] = v end end
    end
    if not self.SidebarCollapsed then self._side.Visible = true end
    setp(self._side, { Size = UDim2.new(0, sideW, 1, -16) })
    setp(self._center, { Position = UDim2.fromOffset(sideTot, 0), Size = UDim2.new(1, -(sideTot + rightW), 1, 0) })
    setp(self._content, { Size = UDim2.new(1, 0, 1, -bottomH) })
    setp(self._dockRight, { Position = UDim2.new(1, -rightW, 0, 0), Size = UDim2.new(0, rightW, 1, 0) })
    setp(self._dockBottom, { Position = UDim2.new(0, 0, 1, -bottomH), Size = UDim2.new(1, 0, 0, bottomH) })
    self._dockRight.Visible, self._dockBottom.Visible = rightW > 0, bottomH > 0
    if self.SidebarCollapsed then
        if anim then task.delay(0.24, function() if self.SidebarCollapsed and self._side then self._side.Visible = false end end)
        else self._side.Visible = false end
    end
    -- place panels
    local function arrange(list, dock, horizontal)
        for i, p in ipairs(list) do
            if p.Frame.Parent ~= dock then p.Frame.Parent = dock end
            local n = #list
            if horizontal then
                p.Frame.Position = UDim2.new((i - 1) / n, 4, 0, 4)
                p.Frame.Size = UDim2.new(1 / n, -8, 1, -8)
            else
                p.Frame.Position = UDim2.new(0, 4, (i - 1) / n, 4)
                p.Frame.Size = UDim2.new(1, -8, 1 / n, -8)
            end
        end
    end
    arrange(right, self._dockRight, false)
    arrange(bottom, self._dockBottom, true)
    for _, p in ipairs(self.Panels) do
        local d = self:_dockOf(p)
        if d == "Float" then p.Frame.Visible = p._visible
        elseif not p._visible then p.Frame.Visible = false else p.Frame.Visible = true end
    end
    self.Events:Emit("LayoutChanged", self.Breakpoint)
end

function Panel:SetTitle(t) self._title.Text = tostring(t) end
function Panel:SetVisible(v) self._visible = v and true or false; self.Window:_relayout(true) end
function Panel:Show() self:SetVisible(true) end
function Panel:Hide() self:SetVisible(false) end
function Panel:IsFloating() return self._floating == true end
function Panel:Float()
    self._floating = true
    local win = self.Window
    self.Frame.Parent = win.Gui
    self.Frame.ZIndex = 30
    self.Frame.Size = UDim2.fromOffset(280, 220)
    self.Frame.Position = UDim2.new(0.5, 40, 0.5, -60)
    win:_relayout(false)
end
function Panel:Dock(dock)
    self._floating = false
    if dock == "Right" or dock == "Bottom" then self.DockSide = dock end
    self.Frame.ZIndex = 1
    self.Window:_relayout(false)
end
function Panel:Destroy()
    local win = self.Window
    if self._dead then return end
    self._dead = true
    for i, p in ipairs(win.Panels) do if p == self then table.remove(win.Panels, i); break end end
    if self.Module and win._modOwned[self.Module] then
        local l = win._modOwned[self.Module].panels
        for i, p in ipairs(l) do if p == self then table.remove(l, i); break end end
    end
    self.Frame:Destroy()
    win:_pruneElements()
    win:_relayout(false)
end
setmetatable(Panel, { __index = Elements })

-- Panels exist only when a script (or module) asks for them.
function Window:CreatePanel(o)
    o = type(o) == "table" and o or { Name = tostring(o) }
    local New, Text, Stroke = self:Kit()
    local dock = (o.Dock == "Bottom" or o.Dock == "Float") and o.Dock or "Right"
    local frame = New("Frame", { Name = "Panel", BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = self._dockRight }, { Corner(10), Stroke("$Border", 1, 0.4) })
    local head = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = frame })
    local title = Text({ Text = o.Title or o.Name or "Panel", Font = FONT_BOLD, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -70, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head })
    local body = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = frame,
    }, { Pad(8, 4, 8, 8), List(6) })
    local p = setmetatable({
        Window = self, Name = o.Name or "Panel", Frame = frame, Page = body, Container = body, DockSide = dock == "Float" and "Right" or dock,
        Size = o.Size, _title = title, _visible = o.Visible ~= false, _floating = dock == "Float", Module = o.Module, FlagPrefix = o.FlagPrefix,
    }, { __index = Panel })
    local function hb(txt, x, fn)
        local b = New("TextButton", {
            AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, x, .5, 0), Size = UDim2.fromOffset(24, 22), BackgroundTransparency = 1, Text = txt,
            Font = FONT_BOLD, TextSize = 13, TextColor3 = "$TextMuted", AutoButtonColor = false, ZIndex = 3, Parent = head,
        })
        b.Activated:Connect(fn)
    end
    if o.Closable ~= false then hb("×", -6, function() p:Hide() end) end
    if o.Detachable ~= false then hb("⧉", -32, function() if p._floating then p:Dock(p.DockSide) else p:Float() end end) end
    head.InputBegan:Connect(function(i)   -- header drag only moves floating panels
        if not (p._floating and IsPointer(i)) then return end
        local startPos, startUI = i.Position, frame.Position
        self:_beginDrag(i, function(pt)
            local d = pt - startPos
            frame.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
        end)
    end)
    self.Panels[#self.Panels + 1] = p
    if p._floating then p:Float() end
    self:_relayout(false)
    if o.Module then
        self._modOwned[o.Module] = self._modOwned[o.Module] or { tabs = {}, panels = {} }
        table.insert(self._modOwned[o.Module].panels, p)
    end
    return p
end
function Window:GetPanel(name) for _, p in ipairs(self.Panels) do if p.Name == name then return p end end end

------------------------------------------------------------------ WINDOW · tabs & sidebar search
-- elements living inside a destroyed container must not linger in the registries
function Window:_pruneElements()
    for id, obj in pairs(Copy(self.ElementsById)) do
        if obj.Frame and obj.Frame.Parent == nil and not obj._dead then pcall(obj.Destroy, obj) end
    end
end
function Tab:Select() self.Window:SelectTab(self) end
function Tab:SetVisible(v) self._hidden = not v; self.Window:_applySearch() end
function Tab:Destroy()
    local win = self.Window
    if self._dead then return end
    self._dead = true
    for i, t in ipairs(win.Tabs) do if t == self then table.remove(win.Tabs, i); break end end
    if self.Module and win._modOwned[self.Module] then
        local l = win._modOwned[self.Module].tabs
        for i, t in ipairs(l) do if t == self then table.remove(l, i); break end end
    end
    self.Button:Destroy()
    self.Page:Destroy()
    win:_pruneElements()
    if win._activeTab == self then
        win._activeTab = nil
        if win.Tabs[1] then win:SelectTab(win.Tabs[1]) end
    end
    win.Events:Emit("TabRemoved", self.Name)
end
setmetatable(Tab, { __index = Elements })

function Window:_applySearch()
    local q = self._query or ""
    local groupHas = {}
    for _, t in ipairs(self.Tabs) do
        local hay = t.Name .. " " .. (t.Group or "") .. " " .. (t.Tags or "")
        local match = q == "" or SearchSvc.Match(q, hay, "fuzzy") ~= nil or t == self._activeTab
        t.Button.Visible = match and not t._hidden
        if t.Button.Visible and t.Group then groupHas[t.Group] = true end
    end
    for _, l in ipairs(self._tabLabels) do l.Label.Visible = (q == "" or groupHas[l.Text] == true) and not l.Hidden end
    local tab = self._activeTab
    if tab then
        local all = tab.Page:GetDescendants()
        local ql = q:lower()
        for _, d in ipairs(all) do
            local n = d:GetAttribute("RHName")
            if n then d.Visible = (not d:GetAttribute("RHHidden")) and (ql == "" or n:find(ql, 1, true) ~= nil) end
        end
        for _, d in ipairs(all) do
            if d:GetAttribute("RHSec") then
                local any = ql == ""
                if not any then
                    local c = d:FindFirstChild("Content")
                    if c then for _, e in ipairs(c:GetDescendants()) do if e:GetAttribute("RHName") and e.Visible then any = true break end end end
                end
                d.Visible = any and not d:GetAttribute("RHHidden")
            end
        end
    end
    -- optional: show disabled-but-registered modules that match the query
    if self._modEntries then
        for _, c in ipairs(self._modEntries:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        if self.ShowModuleEntries and q ~= "" then
            local n = 0
            for name, m in pairs(G.Modules) do
                if n < 3 and not self.ModuleInstances[name] and SearchSvc.Match(q, (m.DisplayName or name) .. " " .. (m.Category or ""), "fuzzy") then
                    n = n + 1
                    local New, Text = self:Kit()
                    local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = "$Surface2", Text = "+ " .. (m.DisplayName or name), Font = FONT_MED, TextSize = 11,
                        TextColor3 = "$Accent", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = n, Parent = self._modEntries }, { Corner(6) })
                    b.Activated:Connect(function() self:EnableModule(name) end)
                end
            end
        end
    end
end

function Window:SelectTab(t)
    if type(t) == "string" then t = self:GetTab(t) end
    if type(t) ~= "table" then return end
    self._activeTab = t
    for _, x in ipairs(self.Tabs) do
        x._active = (x == t)
        x.Page.Visible = x._active
        x._paint(true)
    end
    t.Page.Position = UDim2.fromOffset(0, 10)
    self:Tween(t.Page, { Position = UDim2.fromOffset(0, 0) }, 0.25)
    self:_applySearch()
    self.Events:Emit("TabSelected", t.Name)
end
function Window:GetTab(name) for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end end

function Window:CreateTabLabel(text)
    local New, Text = self:Kit()
    local rec = { Text = tostring(text or "") }
    rec.Label = Text({ Text = string.upper(rec.Text), Font = FONT_BOLD, TextSize = 10, TextColor3 = "$TextMuted", Size = UDim2.new(1, 0, 0, 20), LayoutOrder = NextOrder(self._tabOrder), Parent = self._tabList })
    self._tabLabels[#self._tabLabels + 1] = rec
    self._group = rec.Text
    local obj, win = {}, self
    function obj:SetVisible(v) rec.Hidden = not v; rec.Label.Visible = v end
    function obj:Destroy()
        rec.Label:Destroy()
        for i, l in ipairs(win._tabLabels) do if l == rec then table.remove(win._tabLabels, i); break end end
    end
    return obj
end

function Window:CreateTab(name, icon, opts)
    local win = self
    local New, Text, Stroke = self:Kit()
    opts = type(opts) == "table" and opts or {}
    name = tostring(name or "Tab")
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = NextOrder(self._tabOrder), Parent = self._tabList,
    }, { Corner(8) })
    local iconObj, iconProp
    local s = icon ~= nil and tostring(icon) or ""
    if s ~= "" then
        if s:match("^rbxassetid://") or s:match("^%d+$") then
            iconObj = New("ImageLabel", { BackgroundTransparency = 1, Image = s:match("^%d+$") and ("rbxassetid://" .. s) or s, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(16, 16), ImageColor3 = "$TextMuted", Parent = btn })
            iconProp = "ImageColor3"
        else
            iconObj = Text({ Text = s, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(20, 36), Parent = btn })
            iconProp = "TextColor3"
        end
    end
    local label = Text({ Text = name, Position = UDim2.fromOffset(iconObj and 38 or 16, 0), Size = UDim2.new(1, iconObj and -42 or -20, 1, 0), TextColor3 = "$TextMuted", TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn })
    local bar = New("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 4, .5, 0), Size = UDim2.fromOffset(3, 16), BackgroundColor3 = "$Accent", BackgroundTransparency = 1, BorderSizePixel = 0, Parent = btn }, { Corner(2) })
    local page = New("ScrollingFrame", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = win._content,
    }, { Pad(12, 12, 12, 12), List(8) })
    local tab = setmetatable({
        Name = name, Window = win, Page = page, Container = page, Button = btn, _active = false, Group = opts.Group or win._group, Tags = opts.Tags,
        Module = opts.Module, FlagPrefix = opts.FlagPrefix,
    }, { __index = Tab })
    tab._paint = function(anim)
        local a = tab._active
        local T = win.Theme
        local goals = {
            { btn, { BackgroundTransparency = a and 0.1 or 1 } },
            { label, { TextColor3 = a and T.Text or T.TextMuted } },
            { bar, { BackgroundTransparency = a and 0 or 1 } },
        }
        if iconObj then goals[#goals + 1] = { iconObj, { [iconProp] = a and T.Accent or T.TextMuted } } end
        for _, g in ipairs(goals) do
            if anim then win:Tween(g[1], g[2], 0.18) else for k, v in pairs(g[2]) do g[1][k] = v end end
        end
    end
    win:OnTheme(function() tab._paint(false) end, btn)
    btn.Activated:Connect(function() win.Sound:Play("click"); win:SelectTab(tab) end)
    win.Tabs[#win.Tabs + 1] = tab
    if opts.Module then
        win._modOwned[opts.Module] = win._modOwned[opts.Module] or { tabs = {}, panels = {} }
        table.insert(win._modOwned[opts.Module].tabs, tab)
    end
    if not win._activeTab then win:SelectTab(tab) end
    win.Events:Emit("TabAdded", name)
    return tab
end

------------------------------------------------------------------ WINDOW · management
function Window:SetVisible(v)
    if self._destroyed then return end
    v = v and true or false
    local changed = v ~= self.Visible
    self.Visible = v
    local base = self.UIScale
    if v then
        self.Main.Visible = true
        self:_ensureOnScreen()
        self:Tween(self._scale, { Scale = base }, 0.28, Enum.EasingStyle.Back)
        self:Focus()
    else
        self:Tween(self._scale, { Scale = base * 0.9 }, 0.15)
        task.delay(self.AnimFactor == 0 and 0 or 0.15, function() if not self.Visible and not self._destroyed then self.Main.Visible = false end end)
        if self.Focused then self.Focused = false; self.Events:Emit("Blur") end
    end
    if changed then
        self.Sound:Play(v and "open" or "close")
        self.Events:Emit(v and "Shown" or "Hidden")
    end
end
function Window:Show() self:SetVisible(true) end
function Window:Hide() self:SetVisible(false) end
function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:Focus()
    if self._destroyed then return end
    G.TopOrder = G.TopOrder + 1
    self.Gui.DisplayOrder = G.TopOrder
    for _, w in pairs(G.Windows) do
        if w ~= self and w.Focused then w.Focused = false; w.Events:Emit("Blur") end
    end
    if not self.Focused then self.Focused = true; self.Events:Emit("Focus") end
end
function Window:Blur()
    if self.Focused then self.Focused = false; self.Events:Emit("Blur") end
end

function Window:_ensureOnScreen()
    local m, cam = self.Main, Workspace.CurrentCamera
    if not cam then return end
    local vp, p, s = cam.ViewportSize, m.AbsolutePosition, m.AbsoluteSize
    if p.X > vp.X - 60 or p.Y > vp.Y - 40 or p.X + s.X < 60 or p.Y < -10 then m.Position = UDim2.fromScale(.5, .5) end
end

function Window:_applySize()
    self.Main.Size = UDim2.fromOffset(self._size.X, self.Minimized and 46 or self._size.Y)
    self:_updateBreakpoint()
    self:_relayout(false)
end
function Window:_defaultSize()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local sc = self.UIScale
    return Vector2.new(math.clamp(vp.X / sc - 24, 340, self._maxW), math.clamp(vp.Y / sc - 24, 250, self._maxH))
end
function Window:SetSize(w, h)
    local vp = Workspace.CurrentCamera.ViewportSize
    w = math.clamp(tonumber(w) or self._size.X, 340, math.max(340, vp.X / self.UIScale - 8))
    h = math.clamp(tonumber(h) or self._size.Y, 250, math.max(250, vp.Y / self.UIScale - 8))
    self._size = Vector2.new(w, h)
    self._userSize = true
    self:_applySize()
    self.Events:Emit("Resized", w, h)
end
function Window:Resize(w, h) return self:SetSize(w, h) end
function Window:SetPosition(x, y)
    self.Main.Position = UDim2.new(0.5, tonumber(x) or 0, 0.5, tonumber(y) or 0)
    self.Events:Emit("Moved", x, y)
end
function Window:Move(x, y) return self:SetPosition(x, y) end

function Window:SetMinimized(v)
    self.Minimized = v and true or false
    local s = self._size
    if self.Minimized then
        self._body.Visible = false
        self:Tween(self.Main, { Size = UDim2.fromOffset(s.X, 46) }, 0.2)
    else
        self:Tween(self.Main, { Size = UDim2.fromOffset(s.X, s.Y) }, 0.25)
        task.delay(self.AnimFactor == 0 and 0 or 0.08, function() if not self.Minimized and not self._destroyed then self._body.Visible = true end end)
    end
    self.Events:Emit("Minimized", self.Minimized)
end
function Window:Minimize() self:SetMinimized(true) end
function Window:Restore() self:SetMinimized(false); if self.Maximized then self:Maximize(false) end end

function Window:Maximize(v)
    if v == nil then v = not self.Maximized end
    if v == self.Maximized then return end
    local vp = Workspace.CurrentCamera.ViewportSize
    if v then
        self._restore = { size = self._size, pos = self.Main.Position, user = self._userSize }
        self.Maximized = true
        self._size = Vector2.new(math.max(340, vp.X / self.UIScale - 8), math.max(250, vp.Y / self.UIScale - 8))
        self.Main.Position = UDim2.fromScale(.5, .5)
    else
        self.Maximized = false
        local r = self._restore or {}
        self._size = r.size or self:_defaultSize()
        self._userSize = r.user
        if r.pos then self.Main.Position = r.pos end
    end
    self:_applySize()
    self.Events:Emit("Maximized", self.Maximized)
end

function Window:SetScale(n)
    self.UIScale = math.clamp(tonumber(n) or 1, 0.6, 1.5)
    if self.Visible then self:Tween(self._scale, { Scale = self.UIScale }, 0.15) else self._scale.Scale = self.UIScale * 0.9 end
    if self._userSize then self:SetSize(self._size.X, self._size.Y) else self._size = self:_defaultSize(); self:_applySize() end
end

function Window:SetSidebarCollapsed(v, anim)
    self.SidebarCollapsed = v and true or false
    self._userSidebar = true
    self:_relayout(anim ~= false)
end

function Window:SetDensity(name)
    if not DENSITY[name] then Warn("Window:SetDensity", "use Compact | Comfortable | Spacious"); return false end
    self.DensityName, self.Dens, self.FontScale = name, Copy(DENSITY[name]), DENSITY[name].font
    return true -- applies to elements created afterwards
end
function Window:SetToggleKey(k)
    k = ToKey(k)
    if not k then Warn("Window:SetToggleKey", "invalid key"); return false end
    self.ToggleKey = k
    self._toggleBind:SetKey(k)
    return true
end
function Window:CreateToken() return self.Tasks:Token() end
function Window:SetTitle(t) self._title.Text = tostring(t) end
function Window:SetSubtitle(t) self._subtitle.Text = tostring(t) end

------------------------------------------------------------------ WINDOW · splash (themed, cancellable)
function Window:_splash(cfg)
    local win = self
    local New, Text, Stroke, Gradient = self:Kit()
    cfg = type(cfg) == "table" and cfg or {}
    local dur = cfg.Duration or 1.2
    local vp = Workspace.CurrentCamera.ViewportSize
    local w = math.clamp(math.floor(vp.X * 0.9), 240, 340)
    local card = New("Frame", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(w, 196),
        BackgroundColor3 = "$Background", BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 70, Parent = self.Gui,
    }, { Corner(16), Stroke("$Border", 1, 0.2) })
    local sc = New("UIScale", { Scale = 0.85, Parent = card })
    self:Tween(sc, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
    local bannerRef = cfg.Image ~= false and self:BrandImage("ThemeImage") or nil
    local banner = New("ImageLabel", { Size = UDim2.new(1, 0, 0, 104), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, ZIndex = 71, Parent = card })
    local fade = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0, 104), Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = "$Background", BorderSizePixel = 0, ZIndex = 72, Parent = card })
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = fade })
    if bannerRef then self._splashBind = Assets:Bind(banner, bannerRef) end
    local art = self:_brandCircle(card, 60, "Icon")
    art.Holder.AnchorPoint, art.Holder.Position, art.Holder.ZIndex = Vector2.new(.5, .5), UDim2.new(.5, 0, 0, 98), 74
    art:Load(self:BrandImage("Icon"))
    Text({ Text = cfg.Title or self.Branding.Name or self.Name, Font = FONT_BOLD, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 134), Size = UDim2.new(1, 0, 0, 22), ZIndex = 74, Parent = card })
    Text({ Text = cfg.Subtitle or self.Branding.Tagline or "Loading...", Font = FONT, TextSize = 11, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 156), Size = UDim2.new(1, 0, 0, 16), ZIndex = 74, Parent = card })
    local track = New("Frame", { Position = UDim2.new(0, 20, 1, -14), Size = UDim2.new(1, -40, 0, 3), BackgroundColor3 = "$Border", BorderSizePixel = 0, ZIndex = 74, Parent = card }, { Corner(2) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 75, Parent = track }, { Corner(2) })
    Gradient(fill, 0)
    self:Tween(fill, { Size = UDim2.fromScale(1, 1) }, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local finished = false
    local function finish()
        if finished or win._destroyed then return end
        finished = true
        if win._splashBind then win._splashBind.Cancel() end
        win:Tween(sc, { Scale = 0.85 }, 0.2)
        task.delay(win.AnimFactor == 0 and 0 or 0.2, function()
            card:Destroy()
            win._splashCard = nil
            if not win._destroyed then win:SetVisible(true) end
        end)
    end
    self._splashCard, self._splashFinish = card, finish
    New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 80, Parent = card }).Activated:Connect(finish)   -- tap to skip
    task.delay(dur + 0.1, finish)
end
function Window:SkipSplash() if self._splashFinish then self._splashFinish() end end

------------------------------------------------------------------ WINDOW · watermark (opt-in)
function Window:CreateWatermark(o)
    if self._wm then self._wm:SetVisible(true); return self._wm end
    o = type(o) == "table" and o or {}
    local win = self
    local New, Text, Stroke = self:Kit()
    local text = o.Text or self.Name
    local showFps, showPing = o.ShowFPS ~= false, o.ShowPing ~= false
    local bar = New("Frame", {
        Name = "Watermark", Position = UDim2.fromOffset(16, 16), Size = UDim2.new(0, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = "$Background", BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 40, Parent = self.Gui,
    }, { Corner(8), Stroke("$Border", 1, 0.2), Pad(10, 0, 10, 0) })
    local lab = Text({ RichText = true, Text = "", TextSize = 12, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 41, Parent = bar })
    local frames, last, fps, ping = 0, os.clock(), 60, 0
    local obj = { Status = o.Status }
    local function update()
        local parts = { string.format('<font color="#%s"><b>%s</b></font>', Hex(win.Theme.Accent), text) }
        if showFps then parts[#parts + 1] = fps .. " FPS" end
        if showPing then parts[#parts + 1] = ping .. " ms" end
        if o.ShowModules then parts[#parts + 1] = #win:GetEnabledModules() .. " modules" end
        if type(obj.Status) == "function" then
            local ok, s = pcall(obj.Status)
            if ok and s then parts[#parts + 1] = tostring(s) end
        end
        lab.Text = table.concat(parts, "  |  ")
    end
    self.Cleanup:Add(RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last >= 0.5 then
            fps = math.floor(frames / (now - last) + 0.5)
            frames, last = 0, now
            if showPing then pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end) end
            update()
        end
    end))
    update()
    self:OnTheme(update, bar)
    MakeDraggable(self, bar, bar)
    function obj:SetText(t) text = t; update() end
    function obj:SetStatus(fn) obj.Status = fn; update() end
    function obj:SetVisible(v) bar.Visible = v end
    function obj:Destroy() bar:Destroy(); win._wm = nil end
    self._wm = obj
    return obj
end

------------------------------------------------------------------ WINDOW · create
function RageHub:CreateWindow(o)
    if type(o) == "string" then o = { Name = o } end
    if type(o) ~= "table" then Warn("CreateWindow", "expected an options table; using defaults"); o = {} end
    local name = tostring(o.Name or "Rage Hub")
    local id = tostring(o.Id or name)
    if G.Windows[id] then
        if o.AllowMultiple then id = id .. "#" .. (G.WindowCount + 1)
        else pcall(function() G.Windows[id]:Destroy() end) end   -- re-execution never leaves a duplicate window
    end
    G.WindowCount = G.WindowCount + 1

    local win = setmetatable({
        Id = id, Index = G.WindowCount, Name = name, Flags = {}, Options = {}, ElementsById = {}, Tabs = {}, Panels = {},
        ModuleInstances = {}, _modOwned = {}, _modCfg = {}, _pending = {}, _tabLabels = {}, _tabOrder = {}, _flagListeners = {},
        _dialogs = {}, _commands = {}, _settingsContrib = {}, _settingsSections = {}, _modState = {},
        Visible = false, Minimized = false, Maximized = false, SidebarCollapsed = false, Theme = {}, Branding = Copy(RageHub.Branding),
        _maxW = o.Width or 620, _maxH = o.Height or 400, UIScale = math.clamp(tonumber(o.Scale) or 1, 0.6, 1.5),
        ConfigFolder = o.ConfigFolder or ("RageHub/" .. (name:gsub("[^%w_%- ]", ""))), PersistWindow = o.PersistWindow ~= false,
        AutoSaveName = type(o.AutoSave) == "string" and o.AutoSave or nil, OnUnload = o.OnUnload, ShowModuleEntries = o.ShowModuleEntries == true,
        NotificationsEnabled = not (o.Features and o.Features.Notifications == false), ConfigVersion = 1,
    }, Window)
    G.Windows[id] = win
    G.Order[#G.Order + 1] = id
    if type(o.Branding) == "table" then for k, v in pairs(o.Branding) do win.Branding[k] = v end end

    -- window-scoped services (nothing is shared between windows)
    win.Cleanup = Cleanup.new("Window:" .. id)
    win.Logger = Logger.new(o.MaxLogs or 500, o.DebugMode)
    win.Events = Events.new(function(ev, err) win.Logger:Error("Core", "Event handler '" .. tostring(ev) .. "' failed: " .. tostring(err)) end)
    win.Tasks = Tasks.new(win.Logger, nil, "Core")
    win.State = State.new(win.Events)
    win.Sound = SoundMgr.new(win)
    win.Search, win.Clipboard, win.Assets = SearchSvc, ClipSvc, Assets
    win.Input = Input.new(win)
    win.DebugMode = o.DebugMode == true
    win:SetDensity(DENSITY[o.Density] and o.Density or "Comfortable")
    if Caps().Touch then win.Dens.row = math.max(win.Dens.row, 34); win.Dens.el = math.max(win.Dens.el, 40) end
    win:SetAnimation(ANIM[o.Animation] ~= nil and o.Animation or "normal")
    win.Sound:SetEnabled(o.Sounds == true)

    local themeName = o.Theme or G.DefaultTheme
    if type(themeName) == "table" then for k, v in pairs(NormalizeTheme(themeName, "Custom")) do win.Theme[k] = v end; win.ThemeName = "Custom"
    else
        if not Themes[themeName] then Warn("CreateWindow", "unknown theme '" .. tostring(themeName) .. "'; using " .. G.DefaultTheme); themeName = G.DefaultTheme end
        for k, v in pairs(Themes[themeName]) do win.Theme[k] = v end
        win.ThemeName = themeName
    end
    win:_buildKit()
    local New, Text, Stroke, Gradient = win:Kit()

    local guiName = (o.RandomName == false) and ("RageHub_" .. (id:gsub("%W", ""))) or HttpService:GenerateGUID(false)
    local gui = New("ScreenGui", { Name = guiName, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = G.TopOrder })
    Mount(gui)
    win.Gui = gui
    win.Cleanup:Add(gui)
    win:_buildTip()
    win:_buildNotifs()

    win._size = win:_defaultSize()
    win.Breakpoint = BreakpointFor(win._size.X)
    win.SidebarCollapsed = win.Breakpoint == "Small"

    local main = New("Frame", {
        Name = "Main", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(win._size.X, win._size.Y),
        BackgroundColor3 = "$Background", BackgroundTransparency = 0.04, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = gui,
    }, { Corner(14), Stroke("$Border", 1, 0.2) })
    win.Main = main
    win._scale = New("UIScale", { Scale = win.UIScale * 0.9, Parent = main })
    main.InputBegan:Connect(function(i) if IsPointer(i) then win:Focus() end end)

    local line = New("Frame", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = main }, { Corner(1) })
    local lg = Gradient(line, 0)
    if win.AnimFactor > 0 then
        pcall(function()
            lg.Offset = Vector2.new(-0.6, 0)
            TweenService:Create(lg, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.6, 0) }):Play()
        end)
    end

    -- top bar
    local top = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = main })
    local tx = 16
    if win.Branding.Header then
        win._headerArt = win:_brandCircle(top, 28, "Icon")
        win._headerArt.Holder.Position = UDim2.fromOffset(12, 9)
        win._headerArt:Load(win:BrandImage("Icon"))
        tx = 48
    end
    win._title = Text({ Text = name, Font = FONT_BOLD, TextSize = 15, Position = UDim2.fromOffset(tx, 7), Size = UDim2.new(1, -(tx + 150), 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = top })
    win._subtitle = Text({ Text = o.Subtitle or "", Font = FONT, TextSize = 11, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(tx, 25), Size = UDim2.new(1, -(tx + 150), 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = top })
    New("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "$Border", BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = main })
    MakeDraggable(win, top, main)

    local function topBtn(txt, x, hoverKey, fn)
        local b = New("TextButton", {
            AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, x, .5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = "$Surface",
            Text = txt, Font = FONT_BOLD, TextSize = 15, TextColor3 = "$TextMuted", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 5, Parent = top,
        }, { Corner(8) })
        b.MouseEnter:Connect(function() win:Tween(b, { BackgroundColor3 = win.Theme[hoverKey] }, 0.12); b.TextColor3 = WHITE end)
        b.MouseLeave:Connect(function() win:Tween(b, { BackgroundColor3 = win.Theme.Surface }, 0.12); b.TextColor3 = win.Theme.TextMuted end)
        b.Activated:Connect(fn)
    end
    topBtn("×", -10, "Danger", function()
        win:SetVisible(false)
        if not win._hintShown then
            win._hintShown = true
            win:Notify({ Title = "Hidden", Content = "Press " .. win.ToggleKey.Name .. " (or the launcher) to reopen.", Duration = 3 })
        end
    end)
    topBtn("□", -44, "SurfaceHover", function() win:Maximize() end)
    topBtn("–", -78, "SurfaceHover", function() win:SetMinimized(not win.Minimized) end)
    topBtn("≡", -112, "SurfaceHover", function() win:SetSidebarCollapsed(not win.SidebarCollapsed) end)

    -- body regions: [sidebar | center(content + bottom dock) | right dock]
    local body = New("Frame", { Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 1, -47), BackgroundTransparency = 1, ClipsDescendants = true, Parent = main })
    win._body = body
    local side = New("Frame", {
        Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 128, 1, -16), BackgroundColor3 = "$Surface", BackgroundTransparency = 0.35,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = body,
    }, { Corner(12), Stroke("$Border", 1, 0.55) })
    win._side = side
    local search = New("TextBox", {
        Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 30), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 0.2,
        Text = "", PlaceholderText = "Search...", PlaceholderColor3 = "$TextMuted", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, Visible = o.Search ~= false, Parent = side,
    }, { Corner(8), Pad(10, 0, 8, 0) })
    win._searchBox = search
    search:GetPropertyChangedSignal("Text"):Connect(function() win._query = search.Text; win:_applySearch() end)
    win._tabList = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 1, -112), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = side,
    }, { List(4) })
    win._modEntries = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -60), Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = side }, { List(4) })

    local prof = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 44), BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = side }, { Corner(10), Stroke("$Border", 1, 0.55) })
    local avatar = New("ImageLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = "$SurfaceHover", BorderSizePixel = 0, Parent = prof }, { CornerFull() })
    local lp = Players and Players.LocalPlayer
    Text({ Text = lp and lp.DisplayName or "Player", TextSize = 12, Position = UDim2.fromOffset(42, 6), Size = UDim2.new(1, -46, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof })
    Text({ Text = "Rage Hub v" .. RageHub.Version, Font = FONT, TextSize = 10, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(42, 22), Size = UDim2.new(1, -46, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof })
    task.spawn(function()
        if not lp then return end
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if ok and not win._destroyed and avatar.Parent then avatar.Image = img end
    end)

    local center = New("Frame", { Position = UDim2.fromOffset(144, 0), Size = UDim2.new(1, -144, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = body })
    win._center = center
    win._content = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = center })
    win._dockBottom = New("Frame", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false, Parent = center })
    win._dockRight = New("Frame", { Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = body })

    if o.Resizable ~= false then
        local grip = New("TextButton", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "◢",
            Font = FONT_BOLD, TextSize = 12, TextColor3 = "$TextMuted", AutoButtonColor = false, ZIndex = 15, Parent = main,
        })
        grip.InputBegan:Connect(function(i)
            if not IsPointer(i) or win.Minimized or win.Maximized then return end
            local startPos, startSize, startUI = i.Position, win._size, main.Position
            win:_beginDrag(i, function(p)
                local d = p - startPos
                local sc = win.UIScale
                win:SetSize(startSize.X + d.X / sc, startSize.Y + d.Y / sc)
                local dw, dh = (win._size.X - startSize.X) * sc / 2, (win._size.Y - startSize.Y) * sc / 2
                main.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + dw, startUI.Y.Scale, startUI.Y.Offset + dh)
            end)
        end)
    end

    -- toggle key (shared dispatcher) + viewport tracking
    win.ToggleKey = ToKey(o.ToggleKey) or Enum.KeyCode.RightShift
    win._toggleBind = win.Input:Bind({ Key = win.ToggleKey, Id = "window.toggle", Owner = { Name = "Toggle key" }, Callback = function() win:Toggle() end, Cleanup = win.Cleanup })
    local cam = Workspace.CurrentCamera
    if cam then
        win.Cleanup:Add(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if win._destroyed then return end
            if win.Maximized then win:Maximize(false); win:Maximize(true)
            elseif win._userSize then win:SetSize(win._size.X, win._size.Y)
            else win._size = win:_defaultSize(); win:_applySize() end
            win:_ensureOnScreen()
            if win._launcher then
                local s = win:_launcherSize()
                win._launcher.Size = UDim2.fromOffset(s, s)
            end
        end))
    end
    win:_relayout(false)

    -- launcher (touch devices by default; always honours Launcher = false)
    if o.Launcher == true or type(o.Launcher) == "table" or (o.Launcher ~= false and Caps().Touch) then win:_buildLauncher(o.Launcher) end
    if o.Watermark then win:CreateWatermark(type(o.Watermark) == "table" and o.Watermark or {}) end

    win.Events:Emit("WindowCreated", win)
    if o.Splash == false then win:SetVisible(true) else win:_splash(o.Splash) end
    win:_applyFeatures(o.Features)
    return win
end

------------------------------------------------------------------ WINDOW · destroy & registry
function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    pcall(function() self.Events:Emit("WindowDestroyed", self) end)
    for name in pairs(Copy(self.ModuleInstances)) do pcall(function() self:_teardownModule(name, true) end) end
    pcall(function() self.Tasks:Destroy() end)
    if self._saveTask then pcall(task.cancel, self._saveTask) end
    pcall(function() self.Cleanup:Destroy() end)
    pcall(function() self.Events:Clear() end)
    if G.Windows[self.Id] == self then G.Windows[self.Id] = nil end
    for i, id in ipairs(G.Order) do if id == self.Id then table.remove(G.Order, i); break end end
    if self.OnUnload then pcall(self.OnUnload) end
end

function RageHub:GetActiveWindows()
    local out = {}
    for _, id in ipairs(G.Order) do if G.Windows[id] then out[#out + 1] = G.Windows[id] end end
    return out
end
function RageHub:GetWindow(id) return G.Windows[id] end
function RageHub:DestroyWindow(id)
    local w = G.Windows[id]
    if w then w:Destroy(); return true end
    return false
end
function RageHub:DestroyAll()
    for _, w in pairs(Copy(G.Windows)) do pcall(function() w:Destroy() end) end
    G.Windows, G.Order = {}, {}
end
G.Shutdown = function(reason) RageHub:DestroyAll() end

------------------------------------------------------------------ ELEMENTS · base
local Refs = setmetatable({}, { __mode = "k" })

local function Obj(kind) return { Type = kind, _l = {}, _ev = {} } end

-- API validation: turns sloppy options into safe ones and tells the author what was wrong
local function Opt(self, api, o)
    if type(o) == "string" then o = { Name = o } end
    if type(o) ~= "table" then Warn(api, "expected an options table, got " .. typeof(o)); o = {} end
    local c = Copy(o)
    if c.Name ~= nil and type(c.Name) ~= "string" then c.Name = tostring(c.Name) end
    if c.Name == nil then c.Name = "Unnamed"; Warn(api, "missing Name; using 'Unnamed'") end
    if c.Callback ~= nil and type(c.Callback) ~= "function" then Warn(api, "Callback must be a function; ignoring it"); c.Callback = nil end
    if c.State ~= nil and type(c.State) ~= "string" then Warn(api, "State must be a string key; ignoring it"); c.State = nil end
    if c.State and not c.Flag then c.Flag = c.State end
    c.Module = c.Module or self.Module
    if c.Flag and self.FlagPrefix then c.Flag = self.FlagPrefix .. c.Flag end
    return c
end

local function Base(self, o, rightW, height)
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local desc = o.Description
    local hasDesc = type(desc) == "string" and desc ~= ""
    local H = height or (hasDesc and win.Dens.elDesc or win.Dens.el)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0,
        ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { Corner(8), Stroke("$Border", 1, 0.55) })
    local ty = (hasDesc or height) and 8 or (H - 18) / 2
    local titleL = Text({ Text = o.Name or "Element", Position = UDim2.fromOffset(12, ty), Size = UDim2.new(1, -(rightW or 0) - 24, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    local descL
    if hasDesc then
        descL = Text({ Text = desc, TextSize = 11, TextColor3 = "$TextMuted", Font = FONT, Position = UDim2.fromOffset(12, 27), Size = UDim2.new(1, -(rightW or 0) - 24, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    end
    f:SetAttribute("RHName", ((o.Name or "") .. (hasDesc and (" " .. desc) or "")):lower())
    Refs[f] = { title = titleL, desc = descL }
    if o.Tooltip then win:Tooltip(f, o.Tooltip) end
    return f, H
end

local function Commit(win, o, obj, value, silent)
    if o.Flag then win.Flags[o.Flag] = value end
    if o.State and not obj._fromState then
        obj._pushing = true
        win.State:Set(o.State, value)
        obj._pushing = false
    end
    if not silent then
        obj:_fire("Changed", value)
        if o.Flag then for _, fn in ipairs(win._flagListeners) do win:Call(o, fn, o.Flag, value) end end
    end
    win:_changed()
end

local function Register(win, o, obj, frame)
    local New, Text = win:Kit()
    obj.Frame, obj.Flag, obj.Name, obj.Module = frame, o.Flag, o.Name, o.Module
    G.ElementCount = G.ElementCount + 1
    obj.Id = string.format("RageHub_%d_%d_%s", win.Index, G.ElementCount, (tostring(o.Name or obj.Type):gsub("[^%w]", "")))
    win.ElementsById[obj.Id] = obj
    local shield
    function obj:_fire(ev, ...)
        local list = self._ev[ev]
        if ev == "Changed" then for _, fn in ipairs(self._l) do win:Call(o, fn, ...) end end
        if list then for _, fn in ipairs(Copy(list)) do win:Call(o, fn, ...) end end
    end
    function obj:On(ev, fn)
        if type(fn) ~= "function" then Warn("Element:On", "callback must be a function"); return nil end
        if ev == "Changed" then self._l[#self._l + 1] = fn
        else self._ev[ev] = self._ev[ev] or {}; table.insert(self._ev[ev], fn) end
        return { Disconnect = function()
            local l = ev == "Changed" and self._l or self._ev[ev] or {}
            for i, f in ipairs(l) do if f == fn then table.remove(l, i); break end end
        end }
    end
    function obj:OnChanged(fn) return self:On("Changed", fn) end
    function obj:OnActivated(fn) return self:On("Activated", fn) end
    function obj:OnFocused(fn) return self:On("Focused", fn) end
    function obj:OnBlurred(fn) return self:On("Blurred", fn) end
    function obj:OnDestroyed(fn) return self:On("Destroyed", fn) end
    function obj:SetVisible(v)
        frame:SetAttribute("RHHidden", (not v) or nil)
        frame.Visible = v and true or false
    end
    -- locked: dimmed, input-blocking shield, "locked" marker, optional tooltip explaining why
    function obj:SetLocked(v, reason)
        obj.Locked = v and true or false
        if v and not shield then
            shield = New("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundColor3 = "$Background", BackgroundTransparency = 0.45, Text = "",
                AutoButtonColor = false, ZIndex = 30, BorderSizePixel = 0, Parent = frame,
            }, { Corner(8) })
            Text({ Text = "LOCKED", Font = FONT_BOLD, TextSize = 9, TextColor3 = "$TextDisabled", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -4), Size = UDim2.fromOffset(60, 12), ZIndex = 31, Parent = shield })
            obj._shield = shield
        end
        if shield then
            shield.Visible = obj.Locked
            if reason and not obj._lockTip then obj._lockTip = true; win:Tooltip(shield, function() return obj._lockReason or "Locked" end) end
            obj._lockReason = reason
        end
    end
    function obj:SetName(t)
        local r = Refs[frame]
        if r and r.title then r.title.Text = tostring(t) end
        frame:SetAttribute("RHName", tostring(t):lower())
        obj.Name = tostring(t)
    end
    function obj:SetDescription(t)
        local r = Refs[frame]
        if r and r.desc then r.desc.Text = tostring(t) end
    end
    function obj:Destroy()
        if obj._dead then return end
        obj._dead = true
        obj:_fire("Destroyed")
        if obj._stateConn then obj._stateConn:Disconnect() end
        if obj.Binder then obj.Binder.Destroy() end
        win.ElementsById[obj.Id] = nil
        frame:Destroy()
        if o.Flag and win.Options[o.Flag] == obj then win.Options[o.Flag] = nil; win.Flags[o.Flag] = nil end
    end
    if o.Flag then
        win.Options[o.Flag] = obj
        local v = obj:Get()
        if obj.Type == "Keybind" then v = v and v.Name or "None" end
        win.Flags[o.Flag] = v
        obj._default = obj.Type == "Keybind" and (obj:Get() and obj:Get().Name or false) or v
    end
    if o.State then
        local key = o.State
        if win.State:Exists(key) then
            obj._fromState = true; obj:Set(win.State:Get(key), true); obj._fromState = false
        else
            win.State:Set(key, obj:Get())
        end
        obj._stateConn = win.State:Watch(key, function(v)
            if obj._pushing or obj._dead then return end
            obj._fromState = true
            pcall(obj.Set, obj, v, true)
            obj._fromState = false
        end)
    end
    if o.Flag and win._pending[o.Flag] ~= nil then          -- config loaded before this element existed
        local v = win._pending[o.Flag]
        win._pending[o.Flag] = nil
        win:_applyOne(obj, v)
    end
    if o.Locked then obj:SetLocked(true, o.LockedReason) end
    if o.Visible == false then obj:SetVisible(false) end
    return obj
end

local function Overlay(parent, h)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency, b.Text, b.Size, b.ZIndex = 1, "", UDim2.new(1, 0, 0, h), 3
    b.Parent = parent
    return b
end

-- drag inside an element (sliders / color pickers); locks page scrolling meanwhile
local function Dragger(win, area, page, fn, onBegin)
    area.InputBegan:Connect(function(i)
        if not IsPointer(i) then return end
        local started = win:_beginDrag(i, fn, function() page.ScrollingEnabled = true end)
        if started then
            page.ScrollingEnabled = false
            if onBegin then onBegin(i.Position) end
            fn(i.Position)
        end
    end)
end

-- Shared key capture for the Keybind element and the Toggle hotkey chip. Uses the window's single input
-- dispatcher; keyboardless devices get a tap-to-pick menu; duplicate keys are reported.
local COMMON_KEYS = { "E", "F", "G", "Q", "R", "T", "X", "Z", "V", "C", "B", "H" }
local function KeyBinder(win, btn, initial, cb)
    local key = ToKey(initial)
    local handle
    local cancel
    local ctl = {}
    local function render() btn.Text = cancel and "..." or (key and key.Name or "None") end
    local function rebind()
        if handle then handle:Disconnect(); handle = nil end
        if key then
            handle = win.Input:Bind({
                Key = key, Id = "kb." .. tostring(btn), Owner = { Name = "Keybind" },
                OnPress = function() if cb.Press then cb.Press() end end,
                OnRelease = function() if cb.Release then cb.Release() end end,
            })
            local dup = win.Input:FindConflicts(key, handle)
            if #dup > 0 then win.Logger:Warning("Input", "Key " .. key.Name .. " is also bound to: " .. table.concat(dup, ", ")) end
        end
    end
    function ctl.Get() return key end
    function ctl.Set(v, silent)
        key = ToKey(v)
        cancel = nil
        rebind()
        render()
        if cb.Changed then cb.Changed(key, silent) end
    end
    function ctl.Destroy() if handle then handle:Disconnect(); handle = nil end if cancel then cancel() end end
    btn.Activated:Connect(function()
        if cancel then cancel(); cancel = nil; render(); return end
        if UserInputService.KeyboardEnabled == false or not Caps().Keyboard then
            local items = { { Text = "None", Callback = function() ctl.Set(nil) end } }
            for _, k in ipairs(COMMON_KEYS) do items[#items + 1] = { Text = k, Callback = function() ctl.Set(k) end } end
            win:ContextMenu(items, btn.AbsolutePosition + Vector2.new(0, btn.AbsoluteSize.Y))
            return
        end
        cancel = win.Input:Capture(function(k)
            cancel = nil
            if k == false then render() else ctl.Set(k) end
        end, { Inside = btn })
        render()
    end)
    rebind()
    render()
    return ctl
end
------------------------------------------------------------------ LAYOUT ELEMENTS
function Elements:CreateSection(name, opts)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    opts = opts or {}
    local holder = New("Frame", {
        Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { List(6) })
    holder:SetAttribute("RHSec", true)
    local head = New("TextButton", { Name = "Head", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0, Parent = holder })
    Text({ Text = string.upper(name or "SECTION"), Font = FONT_BOLD, TextSize = 11, TextColor3 = "$Accent", Size = UDim2.new(1, -20, 1, 0), Parent = head })
    local arrow = Text({ Text = "▼", TextSize = 8, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -4, .5, 0), Size = UDim2.fromOffset(14, 14), Parent = head })
    local content = New("Frame", { Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = holder }, { List(6) })
    local sec = setmetatable({ Window = self.Window, Page = self.Page, Container = content, Holder = holder, Head = head, Module = self.Module, FlagPrefix = self.FlagPrefix }, { __index = Elements })
    function sec:SetCollapsed(v)
        content.Visible = not v
        win:Tween(arrow, { Rotation = v and -90 or 0 }, 0.18)
    end
    function sec:SetVisible(v) holder:SetAttribute("RHHidden", (not v) or nil); holder.Visible = v and true or false end
    head.Activated:Connect(function() sec:SetCollapsed(content.Visible) end)
    if opts.Collapsed then sec:SetCollapsed(true) end
    return sec
end

function Elements:CreateDivider(text)
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, text and 20 or 1), BackgroundColor3 = "$Border", BackgroundTransparency = text and 1 or 0.4, BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container })
    if text then
        Text({ Text = text, TextSize = 11, TextColor3 = "$TextMuted", Size = UDim2.new(1, 0, 0, 16), Parent = f })
        New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "$Border", BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = f })
    end
    return f
end

function Elements:CreateLabel(text)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "$Surface", BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8) })
    local l = Text({ Text = text or "", TextColor3 = "$TextMuted", TextSize = 12, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Parent = f })
    f:SetAttribute("RHName", tostring(text or ""):lower())
    local obj = {}
    function obj:Set(t, color) l.Text = tostring(t); if color then l.TextColor3 = color end end
    function obj:Get() return l.Text end
    function obj:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v end
    function obj:Destroy() f:Destroy() end
    return obj
end

function Elements:CreateParagraph(o)
    o = Opt(self, "CreateParagraph", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    o = o or {}
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "$Surface",
        BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container,
    }, { Corner(8), Stroke("$Border", 1, 0.55), Pad(12, 10, 12, 10), List(4) })
    local title = Text({ Text = o.Title or "", Font = FONT_BOLD, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = f })
    local body = Text({
        Text = o.Content or "", Font = FONT, TextSize = 12, TextColor3 = "$TextMuted", TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = f,
    })
    f:SetAttribute("RHName", ((o.Title or "") .. " " .. (o.Content or "")):lower())
    local obj = {}
    function obj:Set(t, c) if t then title.Text = t end if c then body.Text = c end end
    function obj:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v end
    function obj:Destroy() f:Destroy() end
    return obj
end

function Elements:CreateButton(o)
    o = Opt(self, "CreateButton", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local f, H = Base(self, o, 78)
    local label = o.ButtonText or "Run"
    local pill = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(66, 24), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f }, { Corner(12) })
    Gradient(pill, 0)
    local pl = Text({ Text = label, Font = FONT_BOLD, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = pill })
    win:Hover(f)
    local obj = Obj("Button")
    local busy = false
    local function run()
        if busy then return end
        win.Sound:Play("click")
        win:Tween(pill, { Size = UDim2.fromOffset(60, 22) }, 0.08)
        task.delay(0.09, function() win:Tween(pill, { Size = UDim2.fromOffset(66, 24) }, 0.15, Enum.EasingStyle.Back) end)
        obj:_fire("Activated")
        win:Call(o, o.Callback)
        if o.Cooldown and o.Cooldown > 0 then
            busy = true
            pill.BackgroundTransparency = 0.55
            task.spawn(function()
                local t0 = os.clock()
                while true do
                    local left = o.Cooldown - (os.clock() - t0)
                    if left <= 0 then break end
                    pl.Text = string.format("%.1fs", left)
                    task.wait(0.1)
                end
                pl.Text = label
                pill.BackgroundTransparency = 0
                busy = false
            end)
        end
    end
    Overlay(f, H).Activated:Connect(function()
        if o.Confirm then
            win:Dialog({
                Title = o.Name or "Confirm",
                Content = type(o.Confirm) == "string" and o.Confirm or "Are you sure?",
                Buttons = { { Text = "Cancel" }, { Text = "Confirm", Primary = true, Callback = run } },
            })
        else
            run()
        end
    end)
    function obj:Get() return nil end
    function obj:Fire() run() end
    function obj:SetText(t) label = t; pl.Text = t end
    return Register(win, o, obj, f)
end

function Elements:CreateLink(o)
    o = Opt(self, "CreateLink", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    return self:CreateButton({
        Name = o.Name or "Link", Description = o.Description or o.Url, ButtonText = "Copy", Tooltip = o.Tooltip,
        Callback = function()
            local ok = ClipSvc.Copy(o.Url or "")
            win:Notify({ Title = ok and "Link copied" or "Copy not supported", Content = ok and (o.Url or "") or "Your executor has no clipboard function.", Type = ok and "success" or "warning", Duration = 3 })
        end,
    })
end

function Elements:CreateToggle(o)
    o = Opt(self, "CreateToggle", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local hasBind = o.Keybind ~= nil and o.Keybind ~= false
    local f, H = Base(self, o, 52 + (hasBind and 66 or 0))
    local state = o.Default == true
    local obj = Obj("Toggle")
    local track = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0, Parent = f }, { Corner(11) })
    local knob = New("Frame", { AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { Corner(8) })
    local function render(anim)
        local c = state and Theme.Accent or Theme.Border
        local p = state and UDim2.new(1, -19, .5, 0) or UDim2.new(0, 3, .5, 0)
        if anim then
            win:Tween(track, { BackgroundColor3 = c }, 0.18)
            win:Tween(knob, { Position = p }, 0.18)
        else
            track.BackgroundColor3 = c
            knob.Position = p
        end
    end
    render(false)
    win:OnTheme(function() render(false) end, f)
    win:Hover(f)
    function obj:Get() return state end
    function obj:Set(v, silent)
        state = v and true or false
        render(true)
        Commit(win, o, obj, state, silent)
        if not silent then win:Call(o, o.Callback, state) end
    end
    Overlay(f, H).Activated:Connect(function() win.Sound:Play("toggle"); obj:Set(not state) end)
    if hasBind then
        local chip = New("TextButton", {
            AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -62, 0, H / 2), Size = UDim2.fromOffset(54, 22), BackgroundColor3 = "$SurfaceHover",
            Text = "", AutoButtonColor = false, Font = FONT_MED, TextSize = 11, TextColor3 = "$TextMuted", BorderSizePixel = 0, ZIndex = 5, Parent = f,
        }, { Corner(6), Stroke("$Border", 1, 0.4) })
        obj.Binder = KeyBinder(win, chip, o.Keybind, {
            Press = function() if not obj.Locked then obj:Set(not state) end end,
            Changed = function() win:_changed() end,
        })
    end
    return Register(win, o, obj, f)
end

function Elements:CreateSlider(o)
    o = Opt(self, "CreateSlider", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local min = (o.Range and o.Range[1]) or 0
    local max = (o.Range and o.Range[2]) or 100
    local inc = (o.Increment and o.Increment > 0) and o.Increment or 1
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 96, hasDesc and 70 or 54)
    local value = math.clamp(o.Default or min, min, max)
    local obj = Obj("Slider")

    local valB = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(84, 22), BackgroundTransparency = 1, Text = "",
        TextColor3 = "$TextMuted", Font = FONT_MED, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = true, BorderSizePixel = 0, ZIndex = 4, Parent = f,
    })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 20), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Border", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    Gradient(fill, 0)
    local knob = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(7), Stroke("$Accent", 2, 0) })

    local function render()
        local rel = (max == min) and 0 or (value - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.fromScale(rel, .5)
        valB.Text = tostring(Round(value, 3)) .. suffix
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return math.clamp(Round(v, 4), min, max)
    end
    function obj:Get() return value end
    function obj:Set(v, silent)
        v = snap(tonumber(v) or value)
        local changed = v ~= value
        value = v
        render()
        Commit(win, o, obj, value, silent)
        if changed and not silent then win:Call(o, o.Callback, value) end
    end
    render()
    valB.FocusLost:Connect(function()
        local n = tonumber((valB.Text:gsub("[^%d%.%-]", "")))
        if n then obj:Set(n) else render() end
    end)
    local hit = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, H - 34), Size = UDim2.new(1, -12, 0, 30), Parent = f })
    Dragger(win, hit, self.Page, function(pos)
        local rel = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        obj:Set(min + (max - min) * rel)
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateRangeSlider(o)
    o = Opt(self, "CreateRangeSlider", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local min = (o.Range and o.Range[1]) or 0
    local max = (o.Range and o.Range[2]) or 100
    local inc = (o.Increment and o.Increment > 0) and o.Increment or 1
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 110, hasDesc and 70 or 54)
    local lo = math.clamp((o.Default and o.Default[1]) or min, min, max)
    local hi = math.clamp((o.Default and o.Default[2]) or max, min, max)
    local obj = Obj("RangeSlider")

    local valL = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$TextMuted", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(100, 18), Parent = f })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 20), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Border", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    Gradient(fill, 0)
    local function mkKnob() return New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(7), Stroke("$Accent", 2, 0) }) end
    local k1, k2 = mkKnob(), mkKnob()

    local function rel(v) return (max == min) and 0 or (v - min) / (max - min) end
    local function render()
        local a, b = rel(lo), rel(hi)
        fill.Position = UDim2.fromScale(a, 0)
        fill.Size = UDim2.fromScale(b - a, 1)
        k1.Position = UDim2.fromScale(a, .5)
        k2.Position = UDim2.fromScale(b, .5)
        valL.Text = tostring(Round(lo, 3)) .. suffix .. " – " .. tostring(Round(hi, 3)) .. suffix
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return math.clamp(Round(v, 4), min, max)
    end
    local function posToValue(pos)
        local r = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        return min + (max - min) * r
    end
    function obj:Get() return { lo, hi } end
    function obj:Set(v, silent)
        if type(v) ~= "table" then return end
        local a, b = snap(tonumber(v[1]) or lo), snap(tonumber(v[2]) or hi)
        if a > b then a, b = b, a end
        local changed = a ~= lo or b ~= hi
        lo, hi = a, b
        render()
        Commit(win, o, obj, { lo, hi }, silent)
        if changed and not silent then win:Call(o, o.Callback, lo, hi) end
    end
    render()
    local active = 1
    local hit = New("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, H - 34), Size = UDim2.new(1, -12, 0, 30), Parent = f })
    Dragger(win, hit, self.Page, function(pos)
        local v = snap(posToValue(pos))
        if active == 1 then obj:Set({ math.min(v, hi), hi }) else obj:Set({ lo, math.max(v, lo) }) end
    end, function(pos)
        local v = posToValue(pos)
        if lo == hi then active = (v >= hi) and 2 or 1
        else active = (math.abs(v - lo) <= math.abs(v - hi)) and 1 or 2 end
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateDropdown(o)
    o = Opt(self, "CreateDropdown", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local multi = o.Multi == true
    local meta = {}
    local function loadOptions(src)
        local out = {}
        if src ~= nil and type(src) ~= "table" then Warn("CreateDropdown", "Options must be a table"); src = {} end
        for _, v in ipairs(src or {}) do
            if type(v) == "table" then
                local t = tostring(v.Text or v.Name or v.Value or "?")
                out[#out + 1] = t
                meta[t] = v.Meta or v
            else out[#out + 1] = tostring(v) end
        end
        return out
    end
    local options = loadOptions(o.Options)
    local searchable = o.Search == true or (o.Search == nil and #options > 8)
    local selected, single = {}, nil
    if multi then
        for _, v in ipairs(o.Default or {}) do selected[tostring(v)] = true end
    else
        single = o.Default ~= nil and tostring(o.Default) or nil
    end

    local f, H = Base(self, o, 170)
    local obj = Obj("Dropdown")
    local current = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$TextMuted", TextSize = 12, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -30, 0, H / 2), Size = UDim2.fromOffset(130, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    local arrow = Text({ Text = "▼", TextSize = 9, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(14, 14), Parent = f })

    local topY = H + 4
    local searchBox
    if searchable then
        searchBox = New("TextBox", {
            Position = UDim2.fromOffset(8, topY), Size = UDim2.new(1, -16, 0, 26), BackgroundColor3 = "$SurfaceHover", Text = "",
            PlaceholderText = "Search...", PlaceholderColor3 = "$TextMuted", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
            ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, Parent = f,
        }, { Corner(6), Pad(8, 0, 8, 0) })
        topY = topY + 32
    end
    local list = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, topY), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
    }, { List(3) })

    local buttons, open, visibleCount = {}, false, #options
    local maxH = o.MaxHeight or 150
    local extraRows = (multi and o.SelectAll) and 1 or 0
    local emptyL
    local function listH() return math.min(math.max(visibleCount + extraRows, 1) * 33, maxH) end
    local function resize()
        list.Size = UDim2.new(1, -16, 0, listH())
        win:Tween(f, { Size = UDim2.new(1, 0, 0, open and (topY + listH() + 10) or H) }, 0.2)
        win:Tween(arrow, { Rotation = open and 180 or 0 }, 0.2)
    end
    local function isSel(n) if multi then return selected[n] == true end return single == n end
    local function refreshText()
        if multi then
            local t = {}
            for _, n in ipairs(options) do if selected[n] then t[#t + 1] = n end end
            current.Text = #t > 0 and table.concat(t, ", ") or "None"
        else
            current.Text = single or "Select"
        end
    end
    local function paint()
        for n, b in pairs(buttons) do
            local s = isSel(n)
            b.TextColor3 = s and Theme.Accent or Theme.Text
            b.BackgroundTransparency = s and 0 or 1
        end
    end
    local function filter()
        local q = searchBox and searchBox.Text:lower() or ""
        visibleCount = 0
        for n, b in pairs(buttons) do
            local show = q == "" or n:lower():find(q, 1, true) ~= nil
            b.Visible = show
            if show then visibleCount = visibleCount + 1 end
        end
        if emptyL then
            emptyL.Text = (#options == 0) and "No options" or "No results"
            emptyL.Visible = visibleCount == 0
        end
        if open then resize() end
    end
    function obj:Get()
        if multi then
            local t = {}
            for _, n in ipairs(options) do if selected[n] then t[#t + 1] = n end end
            return t
        end
        return single
    end
    local function changed(silent)
        refreshText(); paint()
        Commit(win, o, obj, obj:Get(), silent)
        if not silent then win:Call(o, o.Callback, obj:Get()) end
    end
    local function build()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for i, n in ipairs(options) do
            local b = New("TextButton", {
                LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1,
                Text = n, Font = FONT_MED, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
                BorderSizePixel = 0, Parent = list,
            }, { Corner(6), Pad(10, 0, 10, 0) })
            b.Activated:Connect(function()
                win.Sound:Play("click")
                if multi then
                    selected[n] = (not selected[n]) or nil
                else
                    single = n
                    open = false
                    resize()
                end
                changed(false)
            end)
            buttons[n] = b
        end
        visibleCount = #options
        paint()
    end
    function obj:Set(v, silent)
        if multi then
            selected = {}
            for _, n in ipairs(type(v) == "table" and v or {}) do selected[tostring(n)] = true end
        else
            single = v ~= nil and tostring(v) or nil
        end
        changed(silent)
    end
    function obj:Refresh(newOptions, keep)
        options = {}
        options = loadOptions(newOptions)
        if not keep then
            selected, single = {}, nil
        else
            local valid = {}
            for _, n in ipairs(options) do valid[n] = true end
            for n in pairs(selected) do if not valid[n] then selected[n] = nil end end
            if single and not valid[single] then single = nil end
        end
        build(); filter(); refreshText(); resize()
    end
    function obj:Open(v) open = v and true or false; resize() end
    function obj:GetOption(n) return meta[n] end
    emptyL = Text({ Text = "", TextSize = 11, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, topY + 6), Size = UDim2.new(1, -16, 0, 18), Visible = false, Parent = f })
    if extraRows > 0 then
        local row = New("Frame", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = list }, { List(4, Enum.FillDirection.Horizontal) })
        local function mk(txt, fn)
            local b = New("TextButton", { Size = UDim2.new(0.5, -2, 1, 0), BackgroundColor3 = "$SurfaceHover", Text = txt, Font = FONT_BOLD, TextSize = 11, TextColor3 = "$Accent", AutoButtonColor = false, BorderSizePixel = 0, Parent = row }, { Corner(6) })
            b.Activated:Connect(fn)
        end
        mk("Select all", function() selected = {}; for _, n in ipairs(options) do selected[n] = true end; changed(false) end)
        mk("Clear all", function() selected = {}; changed(false) end)
    end
    build(); filter(); refreshText()
    if searchBox then searchBox:GetPropertyChangedSignal("Text"):Connect(filter) end
    win:OnTheme(paint, f)
    win:Hover(f)
    Overlay(f, H).Activated:Connect(function() open = not open; resize() end)
    return Register(win, o, obj, f)
end

function Elements:CreatePlayerDropdown(o)
    o = Opt(self, "CreatePlayerDropdown", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local opts = Copy(o)
    local function names()
        local out = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if o.IncludeSelf or p ~= Players.LocalPlayer then out[#out + 1] = p.Name end
        end
        table.sort(out)
        return out
    end
    opts.Options = names()
    local dd = self:CreateDropdown(opts)
    local function upd() dd:Refresh(names(), true) end
    win.Cleanup:Add(Players.PlayerAdded:Connect(upd))
    win.Cleanup:Add(Players.PlayerRemoving:Connect(function() task.delay(0.1, upd) end))
    return dd
end

function Elements:CreateSegmented(o)
    o = Opt(self, "CreateSegmented", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local options = {}
    for _, v in ipairs(o.Options or {}) do options[#options + 1] = tostring(v) end
    local n = math.max(#options, 1)
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 0, hasDesc and 78 or 66)
    local obj = Obj("Segmented")
    local index = 1
    for i, v in ipairs(options) do if o.Default ~= nil and v == tostring(o.Default) then index = i end end

    local track = New("Frame", { Position = UDim2.new(0, 12, 0, H - 36), Size = UDim2.new(1, -24, 0, 28), BackgroundColor3 = "$SurfaceHover", BorderSizePixel = 0, Parent = f }, { Corner(8) })
    local ind = New("Frame", { Size = UDim2.new(1 / n, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { Corner(6) })
    Gradient(ind, 0)
    local btns = {}
    local function paint(anim)
        local p = UDim2.new((index - 1) / n, 2, 0, 2)
        if anim then win:Tween(ind, { Position = p }, 0.2) else ind.Position = p end
        for i, b in ipairs(btns) do b.TextColor3 = (i == index) and WHITE or Theme.TextMuted end
    end
    for i, name in ipairs(options) do
        local b = New("TextButton", {
            Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0), BackgroundTransparency = 1, Text = name,
            Font = FONT_BOLD, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = track,
        })
        b.Activated:Connect(function() win.Sound:Play("click"); obj:Set(name) end)
        btns[i] = b
    end
    paint(false)
    win:OnTheme(function() paint(false) end, f)
    function obj:Get() return options[index] end
    function obj:Set(v, silent)
        for i, name in ipairs(options) do if name == tostring(v) then index = i end end
        paint(true)
        Commit(win, o, obj, options[index], silent)
        if not silent then win:Call(o, o.Callback, options[index]) end
    end
    return Register(win, o, obj, f)
end

function Elements:CreateKeybind(o)
    o = Opt(self, "CreateKeybind", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local mode = o.Mode or "Press" -- Press | Hold | Toggle
    local f, H = Base(self, o, 100)
    local obj = Obj("Keybind")
    local state = false
    local btn = New("TextButton", {
        AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(84, 26), BackgroundColor3 = "$SurfaceHover",
        Text = "", AutoButtonColor = false, Font = FONT_MED, TextSize = 12, TextColor3 = "$Text", BorderSizePixel = 0, ZIndex = 4, Parent = f,
    }, { Corner(6), Stroke("$Border", 1, 0.4) })
    obj.Binder = KeyBinder(win, btn, o.Default, {
        Press = function()
            if obj.Locked then return end
            if mode == "Hold" then state = true; win:Call(o, o.Callback, true)
            elseif mode == "Toggle" then state = not state; win:Call(o, o.Callback, state)
            else win:Call(o, o.Callback, obj.Binder.Get()) end
        end,
        Release = function()
            if mode == "Hold" and state then state = false; win:Call(o, o.Callback, false) end
        end,
        Changed = function(k, silent)
            Commit(win, o, obj, k and k.Name or "None", silent)
            if not silent then win:Call(o, o.OnChange, k) end
        end,
    })
    function obj:Get() return obj.Binder.Get() end
    function obj:Set(v, silent) obj.Binder.Set(v, silent) end
    function obj:GetState() return state end
    return Register(win, o, obj, f)
end

function Elements:CreateColorPicker(o)
    o = Opt(self, "CreateColorPicker", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local color = o.Default or Color3.fromRGB(124, 92, 255)
    local h, s, v = color:ToHSV()
    local f, H = Base(self, o, 60)
    local obj = Obj("ColorPicker")
    local PH = 96
    local swatch = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(36, 20), BackgroundColor3 = color, BorderSizePixel = 0, Parent = f }, { Corner(6), Stroke("$Border", 1, 0.2) })

    local sv = New("Frame", { Position = UDim2.fromOffset(10, H + 8), Size = UDim2.new(1, -52, 0, PH), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = f }, { Corner(6) })
    New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
    New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv }, { Corner(6), New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
    local svCur = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = sv }, { Corner(6), Stroke(Color3.new(0, 0, 0), 1.5, 0.2) })

    local hue = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, H + 8), Size = UDim2.fromOffset(22, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f }, { Corner(6) })
    local keys = {}
    for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0.999 or i / 6, 1, 1)) end
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = hue })
    local hueCur = New("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.new(1, 4, 0, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = hue }, { Corner(2), Stroke(Color3.new(0, 0, 0), 1, 0.3) })

    local hexBox = New("TextBox", {
        Position = UDim2.fromOffset(10, H + PH + 16), Size = UDim2.new(1, -20, 0, 24), BackgroundColor3 = "$SurfaceHover", Text = "",
        PlaceholderText = "#RRGGBB", PlaceholderColor3 = "$TextMuted", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
        ClearTextOnFocus = false, BorderSizePixel = 0, Parent = f,
    }, { Corner(6), Stroke("$Border", 1, 0.4), Pad(8, 0, 8, 0) })

    local swatches = { Theme.Accent, Theme.Accent2, Theme.Success, Theme.Warning, Theme.Danger, Theme.Info, WHITE, BLACK }
    for i, c in ipairs(swatches) do
        local b = New("TextButton", { Position = UDim2.new(0, 10 + (i - 1) * 26, 0, H + PH + 46), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = c, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = f }, { Corner(6), Stroke("$Border", 1, 0.3) })
        b.Activated:Connect(function() obj:Set(c) end)
    end
    local function render()
        color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCur.Position = UDim2.fromScale(s, 1 - v)
        hueCur.Position = UDim2.fromScale(.5, h)
        hexBox.Text = string.format("#%02X%02X%02X", Round(color.R * 255), Round(color.G * 255), Round(color.B * 255))
    end
    render()
    function obj:Get() return color end
    function obj:Set(c, silent)
        if typeof(c) ~= "Color3" then return end
        h, s, v = c:ToHSV()
        render()
        Commit(win, o, obj, color, silent)
        if not silent then win:Call(o, o.Callback, color) end
    end
    local function push() render(); Commit(win, o, obj, color, false); win:Call(o, o.Callback, color) end
    Dragger(win, sv, self.Page, function(pos)
        s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        push()
    end)
    Dragger(win, hue, self.Page, function(pos)
        h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 0.999)
        push()
    end)
    hexBox.FocusLost:Connect(function()
        local hx = (hexBox.Text:gsub("[^%x]", ""))
        local n = (#hx == 6) and tonumber(hx, 16) or nil
        if n then obj:Set(Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)) else render() end
    end)
    local open = false
    win:Hover(f)
    Overlay(f, H).Activated:Connect(function()
        open = not open
        win:Tween(f, { Size = UDim2.new(1, 0, 0, open and (H + PH + 78) or H) }, 0.2)
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateProgressBar(o)
    o = Opt(self, "CreateProgressBar", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local max = o.Max or 100
    local suffix = o.Suffix or ""
    local hasDesc = type(o.Description) == "string" and o.Description ~= ""
    local f, H = Base(self, o, 90, hasDesc and 64 or 48)
    local obj = Obj("ProgressBar")
    obj.NoSave = true
    local value = math.clamp(o.Default or 0, 0, max)
    local valL = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$TextMuted", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(150, 18), Parent = f })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 16), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Border", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    local grad = Gradient(fill, 0)
    local status = o.Status
    local STATUS = { success = "Success", warning = "Warning", danger = "Danger", error = "Danger", info = "Info" }
    local function paintStatus()
        local c = o.Color or (status and Theme[STATUS[status] or "Accent"])
        if c then grad.Color = ColorSequence.new(c) end
    end
    win:OnTheme(paintStatus, f)
    paintStatus()
    local function render(anim)
        local r = max == 0 and 0 or value / max
        if anim then win:Tween(fill, { Size = UDim2.fromScale(r, 1) }, 0.25) else fill.Size = UDim2.fromScale(r, 1) end
        valL.Text = (o.Label and (o.Label .. "  ") or "") .. tostring(Round(value, 1)) .. suffix
    end
    render(false)
    function obj:Get() return value end
    function obj:SetStatus(st) status = st; paintStatus() end
    function obj:SetLabel(t) o.Label = t; render(false) end
    function obj:Set(v)
        value = math.clamp(tonumber(v) or value, 0, max)
        render(true)
        Commit(win, o, obj, value, true)
    end
    return Register(win, o, obj, f)
end


function Elements:CreateInput(o)
    o = Opt(self, "CreateInput", o)
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local f, H = Base(self, o, (o.Width or 140) + 10)
    local value = o.Default ~= nil and tostring(o.Default) or ""
    local obj = Obj("Input")
    local masked = o.Password == true          -- shown as bullets; never persisted in configs
    if masked then obj.NoSave = true end
    local function mask(s) return string.rep("•", #s) end
    local clearable = o.Clearable == true and not masked
    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, 0, H / 2), Size = UDim2.fromOffset(o.Width or 140, 26),
        BackgroundColor3 = "$SurfaceHover", TextColor3 = "$Text", PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = "$TextMuted",
        Text = masked and mask(value) or value, ClearTextOnFocus = false, Font = FONT_MED, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0, ZIndex = 4, Parent = f,
    }, { Corner(6), Stroke("$Border", 1, 0.4), Pad(8, 0, clearable and 24 or 8, 0) })
    local stroke = box:FindFirstChildOfClass("UIStroke")
    local clear
    if clearable then
        clear = New("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -2, .5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "×",
            Font = FONT_BOLD, TextSize = 14, TextColor3 = "$TextMuted", Visible = value ~= "", ZIndex = 6, Parent = box })
    end
    local function setError(msg)
        obj.Error = msg
        stroke.Color = msg and Theme.Danger or Theme.Border
        stroke.Transparency = msg and 0 or 0.4
    end
    function obj:SetError(msg) setError(msg) end
    function obj:Get() if o.Numeric then return tonumber(value) or 0 end return value end
    function obj:Set(v, silent)
        value = tostring(v == nil and "" or v)
        box.Text = masked and mask(value) or value
        if clear then clear.Visible = value ~= "" end
        setError(nil)
        Commit(win, o, obj, obj:Get(), silent)
        if not silent then win:Call(o, o.Callback, obj:Get()) end
    end
    function obj:Clear() obj:Set("") end
    if clear then clear.Activated:Connect(function() obj:Set("") end) end
    box.Focused:Connect(function()
        win:Tween(stroke, { Color = obj.Error and Theme.Danger or Theme.Accent, Transparency = 0 }, 0.15)
        if masked then box.Text = value end
        obj:_fire("Focused")
    end)
    box.FocusLost:Connect(function(enter)
        local text = box.Text
        local function revert() box.Text = masked and mask(value) or value end
        obj:_fire("Blurred", enter)
        if not obj.Error then win:Tween(stroke, { Color = Theme.Border, Transparency = 0.4 }, 0.15) end
        if o.Numeric and not tonumber(text) then revert(); return end
        if o.OnlyOnEnter and not enter then revert(); return end
        if o.Validate then
            local okc, ok, err = pcall(o.Validate, text)
            if okc and ok == false then
                setError(err or "Invalid value")
                revert()
                task.delay(2.5, function() if not obj._dead then setError(nil) end end)
                return
            end
        end
        setError(nil)
        value = text
        if masked then box.Text = mask(value) end
        if clear then clear.Visible = value ~= "" end
        Commit(win, o, obj, obj:Get(), false)
        win:Call(o, o.Callback, obj:Get(), enter)
        if o.ClearOnEnter and enter then box.Text = ""; value = "" end
    end)
    return Register(win, o, obj, f)
end

function Elements:CreateLog(o)
    o = Opt(self, "CreateLog", o or { Name = "Log" })
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local H = o.Height or 150
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H + 30), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    Text({ Text = o.Name or "Log", Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -170, 0, 18), Parent = f })
    f:SetAttribute("RHName", (o.Name or "log"):lower())
    local scroll = New("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 1, -38), BackgroundColor3 = "$Background", BackgroundTransparency = 0.3, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f,
    }, { Corner(6), Pad(8, 6, 8, 6), List(2) })
    local entries, labels, nextId, maxLines = {}, {}, 0, o.MaxLines or 100
    local filterFn, query, paused, buffered = nil, "", false, 0
    local obj = Obj("Log")
    obj.NoSave = true
    local function passes(e)
        if filterFn then local ok, r = pcall(filterFn, e); if ok and not r then return false end end
        if query ~= "" and not e.text:lower():find(query, 1, true) then return false end
        return true
    end
    local function makeLabel(e)
        local l = Text({
            Text = e.stamp .. e.text, Font = FONT_CODE, TextSize = 11, TextColor3 = e.color or "$Text", TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = e.id, Parent = scroll,
        })
        labels[e.id] = l
        return l
    end
    local function rebuild()
        for _, l in pairs(labels) do l:Destroy() end
        labels = {}
        local start = math.max(1, #entries - 149)
        for i = start, #entries do if passes(entries[i]) then makeLabel(entries[i]) end end
        task.defer(function() scroll.CanvasPosition = Vector2.new(0, 1e6) end)
    end
    function obj:Get() return nil end
    function obj:Add(text, color)
        nextId = nextId + 1
        local e = { id = nextId, text = tostring(text), color = color, stamp = o.Timestamps == false and "" or ("[" .. os.date("%H:%M:%S") .. "] ") }
        entries[#entries + 1] = e
        if #entries > maxLines then
            local old = table.remove(entries, 1)
            if labels[old.id] then labels[old.id]:Destroy(); labels[old.id] = nil end
        end
        if paused then buffered = buffered + 1 return e.id end
        if passes(e) then
            makeLabel(e)
            task.defer(function() scroll.CanvasPosition = Vector2.new(0, 1e6) end)
        end
        return e.id
    end
    function obj:Clear() entries, buffered = {}, 0; rebuild() end
    function obj:Remove(id)
        for i, e in ipairs(entries) do
            if e.id == id then table.remove(entries, i); if labels[id] then labels[id]:Destroy(); labels[id] = nil end return true end
        end
        return false
    end
    function obj:SetFilter(fn) filterFn = fn; rebuild() end
    function obj:Search(q) query = tostring(q or ""):lower(); rebuild() end
    function obj:Pause(v)
        paused = v and true or false
        if not paused then buffered = 0; rebuild() end
    end
    function obj:IsPaused() return paused end
    function obj:Count() return #entries end
    function obj:GetText()
        local t = {}
        for _, e in ipairs(entries) do t[#t + 1] = e.stamp .. e.text end
        return table.concat(t, "\n")
    end
    function obj:Copy() return ClipSvc.Copy(obj:GetText()) end
    local function tb(txt, x, fn)
        local b = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 6), Size = UDim2.fromOffset(46, 20), BackgroundColor3 = "$SurfaceHover", Text = txt,
            Font = FONT_BOLD, TextSize = 10, TextColor3 = "$TextMuted", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3, Parent = f }, { Corner(5) })
        b.Activated:Connect(function() fn(b) end)
        return b
    end
    tb("Clear", -8, function() obj:Clear() end)
    tb("Copy", -58, function() obj:Copy() end)
    tb("Pause", -108, function(b) obj:Pause(not paused); b.Text = paused and "Resume" or "Pause" end)
    return Register(win, { Name = o.Name, Visible = o.Visible, Module = o.Module }, obj, f)
end

------------------------------------------------------------------ COMPONENT HELPERS
local function Named(o, default)
    if type(o) == "string" then return { Name = o } end
    if type(o) == "table" and o.Name == nil then o = Copy(o); o.Name = default end
    if o == nil then return { Name = default } end
    return o
end
local function Esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function Rich(c, s) return '<font color="#' .. Hex(c) .. '">' .. Esc(s) .. "</font>" end

-- text box with a clear button; used by tables, trees, viewers and the SearchBox element
local function SearchBar(win, parent, o)
    local New, Text, Stroke = win:Kit()
    o = o or {}
    local box = New("TextBox", {
        Position = o.Position or UDim2.fromOffset(6, 4), Size = o.Size or UDim2.new(1, -12, 0, 24), BackgroundColor3 = "$SurfaceHover", Text = "",
        PlaceholderText = o.Placeholder or "Search...", PlaceholderColor3 = "$TextMuted", TextColor3 = "$Text", Font = FONT_MED, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 4, Parent = parent,
    }, { Corner(6), Pad(8, 0, 24, 0) })
    local clear = New("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -2, .5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "×",
        Font = FONT_BOLD, TextSize = 14, TextColor3 = "$TextMuted", Visible = false, ZIndex = 6, Parent = box })
    box:GetPropertyChangedSignal("Text"):Connect(function()
        clear.Visible = box.Text ~= ""
        if o.OnChange then o.OnChange(box.Text) end
    end)
    clear.Activated:Connect(function() box.Text = "" end)
    return box
end

------------------------------------------------------------------ VIRTUALIZED LIST (only visible rows exist)
local VList = {}
VList.__index = VList
function VList.new(win, parent, o)
    local New = win:Kit()
    local self = setmetatable({
        win = win, RowHeight = o.RowHeight or win.Dens.row, _create = o.Create, _render = o.Render, _count = 0, _pool = {}, Rendered = 0, _buffer = 2,
    }, VList)
    self.Scroll = New("ScrollingFrame", {
        Size = o.Size or UDim2.fromScale(1, 1), Position = o.Position or UDim2.new(), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = Caps().Touch and 6 or 4, ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = parent,
    })
    self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() self:_update(false) end)
    self.Scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_update(true) end)
    win._vlists = win._vlists or setmetatable({}, { __mode = "k" })
    win._vlists[self] = true
    return self
end
function VList:_update(force)
    local scroll, rh = self.Scroll, self.RowHeight
    local viewH = math.max(scroll.AbsoluteSize.Y, rh)
    local want = math.ceil(viewH / rh) + self._buffer * 2
    local pool = self._pool
    if #pool < want then
        for i = #pool + 1, want do pool[i] = { frame = self._create(scroll, i) } end
        force = true
    end
    local P = #pool
    local first = math.max(1, math.floor(scroll.CanvasPosition.Y / rh) + 1 - self._buffer)
    local last = math.min(self._count, first + P - 1)
    local shown, used = {}, 0
    for idx = first, last do
        local slot = (idx - 1) % P + 1
        local row = pool[slot]
        if force or row.idx ~= idx then
            row.idx = idx
            row.frame.Position = UDim2.fromOffset(0, (idx - 1) * rh)
            row.frame.Visible = true
            self._render(row.frame, idx)
        end
        shown[slot] = true
        used = used + 1
    end
    for slot, row in ipairs(pool) do
        if not shown[slot] and row.idx ~= nil then row.frame.Visible = false; row.idx = nil end
    end
    self.Rendered = used
end
function VList:SetCount(n)
    self._count = n
    self.Scroll.CanvasSize = UDim2.new(0, 0, 0, n * self.RowHeight)
    self:_update(true)
end
function VList:Refresh() self:_update(true) end
function VList:RefreshRow(idx)
    for _, row in ipairs(self._pool) do if row.idx == idx then self._render(row.frame, idx) end end
end
function VList:ScrollTo(idx, center)
    local view = self.Scroll.AbsoluteSize.Y
    local y = (idx - 1) * self.RowHeight - (center and (view / 2 - self.RowHeight / 2) or 0)
    self.Scroll.CanvasPosition = Vector2.new(0, math.max(0, y))
    self:_update(false)
end
function VList:Destroy()
    if self.win._vlists then self.win._vlists[self] = nil end
    self.Scroll:Destroy()
end

------------------------------------------------------------------ CONTEXT MENU
function Window:ContextMenu(items, pos)
    if type(items) ~= "table" or #items == 0 then return nil end
    local New, Text, Stroke = self:Kit()
    if self._menu then self._menu:Destroy(); self._menu = nil end
    local vp = Workspace.CurrentCamera.ViewportSize
    local rowH = Caps().Touch and 38 or 28
    local w = 170
    local h = #items * rowH + 8
    local x = math.clamp(pos.X, 4, math.max(4, vp.X - w - 4))
    local y = pos.Y
    if y + h > vp.Y - 4 then y = math.max(4, vp.Y - h - 4) end
    local dim = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 90, Parent = self.Gui })
    local menu = New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ZIndex = 91, Parent = dim },
        { Corner(8), Stroke("$Border", 1, 0.2), Pad(4, 4, 4, 4), List(0) })
    local function close() if self._menu == dim then self._menu = nil end dim:Destroy() end
    for i, it in ipairs(items) do
        local b = New("TextButton", {
            LayoutOrder = i, Size = UDim2.new(1, 0, 0, rowH), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1, Text = it.Text or "?", Font = FONT_MED, TextSize = 12,
            TextColor3 = it.Disabled and "$TextDisabled" or (it.Danger and "$Danger" or "$Text"), TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 92, Parent = menu,
        }, { Corner(6), Pad(10, 0, 8, 0) })
        b.MouseEnter:Connect(function() if not it.Disabled then b.BackgroundTransparency = 0 end end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
        b.Activated:Connect(function()
            if it.Disabled then return end
            close()
            self:Call({ Name = "ContextMenu:" .. tostring(it.Text) }, it.Callback)
        end)
    end
    dim.Activated:Connect(close)
    self._menu = dim
    return { Close = close }
end

------------------------------------------------------------------ TABLE
local function ColumnsOf(api, cols)
    local out = {}
    if type(cols) ~= "table" or #cols == 0 then
        Warn(api, "Columns must be a non-empty array; using a single column")
        cols = { { Key = "Value", Title = "Value" } }
    end
    local specified, count = 0, 0
    for _, c in ipairs(cols) do
        local col = { Key = c.Key or c[1] or "?", Title = c.Title or c.Key or c[1] or "?", Width = tonumber(c.Width), Align = c.Align, Sortable = c.Sortable ~= false, Format = c.Format, Searchable = c.Searchable ~= false }
        if col.Width and col.Width > 0 and col.Width <= 1 then specified = specified + col.Width else col.Width = nil; count = count + 1 end
        out[#out + 1] = col
    end
    local share = count > 0 and math.max(0.05, (1 - math.min(specified, 0.95)) / count) or 0
    local cum = 0
    for _, col in ipairs(out) do
        col.W = col.Width or share
        col.X = cum
        cum = cum + col.W
    end
    for _, col in ipairs(out) do col.W = col.W / cum; col.X = col.X / cum end
    return out
end

function Elements:CreateTable(o)
    o = Opt(self, "CreateTable", Named(o, "Table"))
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local cols = ColumnsOf("CreateTable", o.Columns)
    local rowH = o.RowHeight or win.Dens.row
    local H = o.Height or 240
    local showHeader = o.ShowHeader ~= false
    local multi = o.MultiSelect == true
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", (o.Name or "table"):lower())
    local obj = Obj("Table")
    obj.NoSave = true
    local top = 0
    local rows, byId, view, selected = {}, {}, {}, {}
    local query, sortKey, sortDir, nextId, dirty = "", o.Sort and o.Sort.Key, (o.Sort and o.Sort.Direction) or "asc", 0, false
    local vlist, empty, countL
    local rowState = setmetatable({}, { __mode = "k" })   -- Instances cannot hold custom fields
    local function textOf(rec)
        local t = {}
        for _, c in ipairs(cols) do
            if c.Searchable then local v = rec.Data[c.Key]; if v ~= nil then t[#t + 1] = tostring(v) end end
        end
        return table.concat(t, " ")
    end
    if o.Search ~= false then
        SearchBar(win, f, { Placeholder = o.Placeholder or "Search...", Size = UDim2.new(1, -90, 0, 24), OnChange = function(t) query = t; obj:_schedule() end })
        countL = Text({ Text = "", TextSize = 11, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(76, 24), Parent = f })
        top = 32
    end
    local headBtns = {}
    if showHeader then
        local head = New("Frame", { Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = "$Surface2", BorderSizePixel = 0, Parent = f })
        for i, c in ipairs(cols) do
            local b = New("TextButton", {
                Position = UDim2.new(c.X, 0, 0, 0), Size = UDim2.new(c.W, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = head,
            })
            local l = Text({ Text = c.Title, Font = FONT_BOLD, TextSize = 11, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -12, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = c.Align == "Right" and Enum.TextXAlignment.Right or (c.Align == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left), Parent = b })
            headBtns[i] = { btn = b, label = l, col = c }
            if c.Sortable then b.Activated:Connect(function()
                if sortKey == c.Key then sortDir = (sortDir == "asc") and "desc" or "asc" else sortKey, sortDir = c.Key, "asc" end
                obj:_schedule()
            end) end
        end
        top = top + 24
    end
    local function paintHead()
        for _, h in ipairs(headBtns) do h.label.Text = h.col.Title .. ((sortKey == h.col.Key) and (sortDir == "asc" and " ▲" or " ▼") or "") end
    end
    empty = Text({ Text = o.EmptyText or "No data", TextSize = 12, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, top + 18), Size = UDim2.new(1, 0, 0, 20), Visible = false, Parent = f })

    -- long-press (touch) / right-click (mouse) opens the row context menu
    local longPressed, lastTap, lastTapId = false, 0, nil
    local function selectRec(rec)
        if multi then selected[rec.Id] = (not selected[rec.Id]) or nil
        else selected = { [rec.Id] = true } end
        vlist:Refresh()
        local list = obj:GetSelected()
        obj:_fire("Select", list)
        if o.OnSelect then
            local data = {}
            for _, r in ipairs(list) do data[#data + 1] = r.Data end
            win:Call(o, o.OnSelect, data, list)
        end
    end
    local function openMenu(rec, pos)
        if not o.ContextMenu then return end
        local ok, items = pcall(o.ContextMenu, rec.Data, rec.Id)
        if ok and type(items) == "table" then win:ContextMenu(items, pos) end
    end
    vlist = VList.new(win, f, {
        RowHeight = rowH, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top),
        Create = function(scroll)
            local row = New("TextButton", { Size = UDim2.new(1, 0, 0, rowH), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Parent = scroll })
            local st = { cells = {} }
            rowState[row] = st
            for i, c in ipairs(cols) do
                st.cells[i] = Text({ Text = "", TextSize = 12, Position = UDim2.new(c.X, 8, 0, 0), Size = UDim2.new(c.W, -12, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = c.Align == "Right" and Enum.TextXAlignment.Right or (c.Align == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left), Parent = row })
            end
            local pressTask
            row.InputBegan:Connect(function(i)
                local rec = st.rec
                if not rec then return end
                if i.UserInputType == Enum.UserInputType.MouseButton2 then longPressed = true; openMenu(rec, i.Position)
                elseif i.UserInputType == Enum.UserInputType.Touch and o.ContextMenu then
                    local pos = i.Position
                    pressTask = task.delay(0.5, function() pressTask = nil; longPressed = true; openMenu(rec, pos) end)
                end
            end)
            row.InputEnded:Connect(function() if pressTask then pcall(task.cancel, pressTask); pressTask = nil end end)
            row.Activated:Connect(function()
                local rec = st.rec
                if longPressed then longPressed = false return end
                if not rec then return end
                local now = os.clock()
                if lastTapId == rec.Id and now - lastTap < 0.35 then
                    lastTap = 0
                    obj:_fire("RowActivated", rec)
                    if o.OnActivated then win:Call(o, o.OnActivated, rec.Data, rec.Id) end
                else
                    lastTap, lastTapId = now, rec.Id
                    selectRec(rec)
                end
            end)
            return row
        end,
        Render = function(row, idx)
            local rec = view[idx]
            local st = rowState[row]
            st.rec = rec
            if not rec then return end
            for i, c in ipairs(cols) do
                local v = rec.Data[c.Key]
                local txt
                if c.Format then local ok, r = pcall(c.Format, v, rec.Data); txt = ok and tostring(r) or "?" else txt = v == nil and "" or tostring(v) end
                st.cells[i].Text = txt
            end
            if selected[rec.Id] then row.BackgroundColor3, row.BackgroundTransparency = win.Theme.Accent, 0.7
            else row.BackgroundColor3, row.BackgroundTransparency = win.Theme.SurfaceHover, (idx % 2 == 0) and 0.8 or 1 end
        end,
    })
    local function cmp(a, b)
        local x, y = a.Data[sortKey], b.Data[sortKey]
        if x == y then return a.Id < b.Id end
        local r
        if type(x) == "number" and type(y) == "number" then r = x < y else r = tostring(x):lower() < tostring(y):lower() end
        if sortDir == "desc" then return not r end
        return r
    end
    local function rebuild()
        dirty = false
        local list = rows
        if query ~= "" then list = SearchSvc.Filter(rows, query, function(r) return r._text end, o.SearchMode or "contains") end
        if sortKey then
            local c = {}
            for i, r in ipairs(list) do c[i] = r end
            table.sort(c, cmp)
            list = c
        end
        view = list
        vlist:SetCount(#view)
        empty.Text = (#rows == 0) and (o.EmptyText or "No data") or "No results"
        empty.Visible = #view == 0
        if countL then countL.Text = (#view == #rows) and (#rows .. " rows") or (#view .. " / " .. #rows) end
        paintHead()
    end
    function obj:_schedule() if not dirty then dirty = true; task.defer(rebuild) end end
    function obj:Refresh() rebuild() end
    local function add(data, id, at)
        nextId = nextId + 1
        local rec = { Id = id or nextId, Data = data }
        rec._text = textOf(rec)
        if at then table.insert(rows, math.clamp(at, 1, #rows + 1), rec) else rows[#rows + 1] = rec end
        byId[rec.Id] = rec
        return rec.Id
    end
    function obj:AddRow(data, id) local r = add(data, id); obj:_schedule(); return r end
    function obj:InsertRow(index, data, id) local r = add(data, id, index); obj:_schedule(); return r end
    function obj:RemoveRow(id)
        local rec = byId[id]
        if not rec then return false end
        for i, r in ipairs(rows) do if r == rec then table.remove(rows, i); break end end
        byId[id], selected[id] = nil, nil
        obj:_schedule()
        return true
    end
    function obj:UpdateRow(id, fields)
        local rec = byId[id]
        if not rec then return false end
        for k, v in pairs(fields) do rec.Data[k] = v end
        rec._text = textOf(rec)
        obj:_schedule()
        return true
    end
    function obj:SetRows(list)
        rows, byId, selected = {}, {}, {}
        for _, d in ipairs(list or {}) do add(d) end
        obj:_schedule()
    end
    function obj:Clear() obj:SetRows({}) end
    function obj:GetRow(id) return byId[id] and byId[id].Data end
    function obj:GetRows() local t = {}; for _, r in ipairs(rows) do t[#t + 1] = r.Data end return t end
    function obj:GetSelected() local t = {}; for _, r in ipairs(rows) do if selected[r.Id] then t[#t + 1] = r end end return t end
    function obj:GetSelectedIds() local t = {}; for _, r in ipairs(obj:GetSelected()) do t[#t + 1] = r.Id end return t end
    function obj:Get() return obj:GetSelectedIds() end
    function obj:Set(ids) selected = {}; for _, id in ipairs(ids or {}) do selected[id] = true end vlist:Refresh() end
    function obj:Select(id, additive)
        if not byId[id] then return false end
        if not (additive and multi) then selected = {} end
        selected[id] = true
        vlist:Refresh()
        obj:_fire("Select", obj:GetSelected())
        return true
    end
    function obj:ClearSelection() selected = {}; vlist:Refresh() end
    function obj:SetSearch(q) query = tostring(q or ""); obj:_schedule() end
    function obj:SetSort(key, dir) sortKey, sortDir = key, dir or "asc"; obj:_schedule() end
    function obj:Count() return #rows end
    function obj:ViewCount() return #view end
    function obj:GetVList() return vlist end
    function obj:ScrollTo(id) for i, r in ipairs(view) do if r.Id == id then vlist:ScrollTo(i, true) return true end end return false end
    function obj:Destroy() vlist:Destroy() end
    for _, d in ipairs(o.Rows or {}) do add(d) end
    win:OnTheme(function() vlist:Refresh() end, f)
    rebuild()
    local base = Register(win, o, obj, f)
    local baseDestroy = base.Destroy
    base.Destroy = function() pcall(function() vlist:Destroy() end) baseDestroy(base) end
    return base
end

function Elements:CreateList(o)
    o = Named(o, "List")
    local c = Copy(o)
    c.Columns = { { Key = "Text", Title = o.Title or o.Name or "Items", Width = 1, Sortable = false } }
    c.ShowHeader = o.ShowHeader == true
    c.Rows = nil
    local t = self:CreateTable(c)
    for _, it in ipairs(o.Items or {}) do t:AddRow(type(it) == "table" and it or { Text = tostring(it) }) end
    t.AddItem = function(_, it, id) return t:AddRow(type(it) == "table" and it or { Text = tostring(it) }, id) end
    t.RemoveItem = function(_, id) return t:RemoveRow(id) end
    t.SetItems = function(_, items)
        local rows = {}
        for _, it in ipairs(items or {}) do rows[#rows + 1] = type(it) == "table" and it or { Text = tostring(it) } end
        t:SetRows(rows)
    end
    return t
end

------------------------------------------------------------------ TREE
function Elements:CreateTree(o)
    o = Opt(self, "CreateTree", Named(o, "Tree"))
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local rowH = o.RowHeight or win.Dens.row
    local H = o.Height or 260
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", (o.Name or "tree"):lower())
    local obj = Obj("Tree")
    obj.NoSave = true
    local roots, byId, flat = {}, {}, {}
    local selectedId, query, nextId, keep = nil, "", 0, nil
    local rowState = setmetatable({}, { __mode = "k" })
    local top = 0
    local vlist, empty
    local rebuild

    if o.Search ~= false or o.Toolbar then
        local right = 8
        for i = #(o.Toolbar or {}), 1, -1 do
            local t = o.Toolbar[i]
            local b = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -right, 0, 4), Size = UDim2.fromOffset(56, 24), BackgroundColor3 = "$SurfaceHover", Text = t.Text, Font = FONT_BOLD,
                TextSize = 10, TextColor3 = "$TextMuted", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4, Parent = f }, { Corner(6) })
            b.Activated:Connect(function() win:Call(o, t.Callback, obj) end)
            right = right + 60
        end
        if o.Search ~= false then
            SearchBar(win, f, { Placeholder = o.Placeholder or "Search...", Size = UDim2.new(1, -(right + 6), 0, 24), OnChange = function(t) obj:Search(t) end })
        end
        top = 32
    end
    empty = Text({ Text = o.EmptyText or "Nothing to show", TextSize = 12, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, top + 18), Size = UDim2.new(1, 0, 0, 20), Visible = false, Parent = f })

    local function adopt(n, parent)
        if type(n) ~= "table" then n = { Text = tostring(n) } end
        nextId = nextId + 1
        local rec = {
            Id = n.Id or nextId, Text = tostring(n.Text or n.Name or "?"), Plain = n.Plain, Detail = n.Detail, Icon = n.Icon, Color = n.Color, Rich = n.Rich, Data = n.Data,
            Parent = parent, Depth = parent and parent.Depth + 1 or 0, Expanded = n.Expanded == true, Loaded = false,
            Lazy = (n.Children == nil) and (n.Lazy == true or (o.LoadChildren ~= nil and n.Leaf ~= true)),
        }
        byId[rec.Id] = rec
        if n.Children then
            rec.Children = {}
            for _, c in ipairs(n.Children) do rec.Children[#rec.Children + 1] = adopt(c, rec) end
            rec.Loaded = true
        end
        return rec
    end
    local function forget(rec)
        byId[rec.Id] = nil
        for _, c in ipairs(rec.Children or {}) do forget(c) end
    end
    local function computeKeep()
        if query == "" then keep = nil return end
        keep = {}
        local function walk(rec)
            local any = SearchSvc.Match(query, (rec.Plain or rec.Text) .. " " .. tostring(rec.Detail or ""), "contains") ~= nil
            for _, c in ipairs(rec.Children or {}) do if walk(c) then any = true end end
            if any then keep[rec.Id] = true end
            return any
        end
        for _, r in ipairs(roots) do walk(r) end
    end
    local function flatten()
        flat = {}
        local function walk(rec)
            if keep and not keep[rec.Id] then return end
            flat[#flat + 1] = rec
            local open = rec.Expanded or (keep ~= nil and rec.Children ~= nil and #rec.Children > 0)
            if open and rec.Children then for _, c in ipairs(rec.Children) do walk(c) end end
        end
        for _, r in ipairs(roots) do walk(r) end
    end
    local function expand(rec, v)
        if v and rec.Lazy and not rec.Loaded then
            rec.Loading = true
            local res = o.LoadChildren and win:Call(o, o.LoadChildren, rec)
            if type(res) == "table" then obj:SetChildren(rec.Id, res) end
        end
        rec.Expanded = v
        obj:_fire("Expand", rec, v)
        if o.OnExpand then win:Call(o, o.OnExpand, rec, v) end
        rebuild()
    end
    local longPressed, lastTap, lastTapId = false, 0, nil
    local function select(rec)
        selectedId = rec.Id
        vlist:Refresh()
        obj:_fire("Select", rec)
        if o.OnSelect then win:Call(o, o.OnSelect, rec) end
    end
    local function openMenu(rec, pos)
        if not o.ContextMenu then return end
        local ok, items = pcall(o.ContextMenu, rec)
        if ok and type(items) == "table" then win:ContextMenu(items, pos) end
    end
    vlist = VList.new(win, f, {
        RowHeight = rowH, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top),
        Create = function(scroll)
            local row = New("TextButton", { Size = UDim2.new(1, 0, 0, rowH), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Parent = scroll })
            local st = {}
            rowState[row] = st
            st.arrow = New("TextButton", { Size = UDim2.fromOffset(20, rowH), BackgroundTransparency = 1, Text = "", Font = FONT_BOLD, TextSize = 9, TextColor3 = "$TextMuted", AutoButtonColor = false, ZIndex = 3, Parent = row })
            st.icon = Text({ Text = "", TextSize = 12, Size = UDim2.fromOffset(18, rowH), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = row })
            st.label = Text({ Text = "", TextSize = 12, RichText = true, Size = UDim2.new(1, -20, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = row })
            st.detail = Text({ Text = "", TextSize = 10, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.35, 0, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = row })
            st.arrow.Activated:Connect(function() local rec = st.rec; if rec and (rec.Children or rec.Lazy) then expand(rec, not rec.Expanded) end end)
            local pressTask
            row.InputBegan:Connect(function(i)
                local rec = st.rec
                if not rec then return end
                if i.UserInputType == Enum.UserInputType.MouseButton2 then longPressed = true; openMenu(rec, i.Position)
                elseif i.UserInputType == Enum.UserInputType.Touch and o.ContextMenu then
                    local pos = i.Position
                    pressTask = task.delay(0.5, function() pressTask = nil; longPressed = true; openMenu(rec, pos) end)
                end
            end)
            row.InputEnded:Connect(function() if pressTask then pcall(task.cancel, pressTask); pressTask = nil end end)
            row.Activated:Connect(function()
                local rec = st.rec
                if longPressed then longPressed = false return end
                if not rec then return end
                local now = os.clock()
                if lastTapId == rec.Id and now - lastTap < 0.35 then
                    lastTap = 0
                    if rec.Children or rec.Lazy then expand(rec, not rec.Expanded) end
                    obj:_fire("Activated", rec)
                    if o.OnActivated then win:Call(o, o.OnActivated, rec) end
                else lastTap, lastTapId = now, rec.Id; select(rec) end
            end)
            return row
        end,
        Render = function(row, idx)
            local rec, st = flat[idx], rowState[row]
            st.rec = rec
            if not rec then return end
            local indent = rec.Depth * 14 + 4
            st.arrow.Position = UDim2.fromOffset(indent, 0)
            local hasKids = (rec.Children and #rec.Children > 0) or rec.Lazy
            st.arrow.Text = rec.Loading and "…" or (hasKids and (rec.Expanded and "▼" or "▶") or "")
            st.icon.Position = UDim2.fromOffset(indent + 20, 0)
            st.icon.Text = rec.Icon or ""
            local lx = indent + 20 + (rec.Icon and 20 or 0)
            st.label.Position = UDim2.fromOffset(lx, 0)
            st.label.Size = UDim2.new(1, -(lx + 8), 1, 0)
            st.label.RichText = rec.Rich == true
            st.label.Text = rec.Text
            st.label.TextColor3 = rec.Color or win.Theme.Text
            st.detail.Text = rec.Detail and tostring(rec.Detail) or ""
            if selectedId == rec.Id then row.BackgroundColor3, row.BackgroundTransparency = win.Theme.Accent, 0.7
            else row.BackgroundColor3, row.BackgroundTransparency = win.Theme.SurfaceHover, 1 end
        end,
    })
    rebuild = function()
        computeKeep()
        flatten()
        vlist:SetCount(#flat)
        empty.Visible = #flat == 0
    end
    function obj:Get() return selectedId end
    function obj:Set(id) obj:Select(id) end
    function obj:SetRoots(list)
        byId, roots, selectedId = {}, {}, nil
        for _, n in ipairs(list or {}) do roots[#roots + 1] = adopt(n, nil) end
        rebuild()
    end
    function obj:AddNode(parentId, node)
        local parent = parentId ~= nil and byId[parentId] or nil
        local rec = adopt(node, parent)
        if parent then parent.Children = parent.Children or {}; table.insert(parent.Children, rec); parent.Lazy = false; parent.Loaded = true
        else roots[#roots + 1] = rec end
        rebuild()
        return rec.Id
    end
    function obj:RemoveNode(id)
        local rec = byId[id]
        if not rec then return false end
        local list = rec.Parent and rec.Parent.Children or roots
        for i, r in ipairs(list) do if r == rec then table.remove(list, i); break end end
        forget(rec)
        if selectedId and not byId[selectedId] then selectedId = nil end
        rebuild()
        return true
    end
    function obj:SetChildren(id, children)
        local rec = byId[id]
        if not rec then return false end
        for _, c in ipairs(rec.Children or {}) do forget(c) end
        rec.Children = {}
        for _, c in ipairs(children or {}) do rec.Children[#rec.Children + 1] = adopt(c, rec) end
        rec.Loaded, rec.Lazy, rec.Loading = true, false, false
        rebuild()
        return true
    end
    function obj:GetNode(id) return byId[id] end
    function obj:Expand(id) local r = byId[id]; if r then expand(r, true) end end
    function obj:Collapse(id) local r = byId[id]; if r then expand(r, false) end end
    function obj:Toggle(id) local r = byId[id]; if r then expand(r, not r.Expanded) end end
    function obj:ExpandAll(depth)
        local function walk(r) if r.Children and (not depth or r.Depth < depth) then r.Expanded = true; for _, c in ipairs(r.Children) do walk(c) end end end
        for _, r in ipairs(roots) do walk(r) end
        rebuild()
    end
    function obj:CollapseAll() for _, r in pairs(byId) do r.Expanded = false end rebuild() end
    function obj:Select(id)
        local rec = byId[id]
        if not rec then return false end
        local p = rec.Parent
        while p do p.Expanded = true; p = p.Parent end
        rebuild()
        select(rec)
        for i, r in ipairs(flat) do if r == rec then vlist:ScrollTo(i, true) break end end
        return true
    end
    function obj:GetSelected() return selectedId and byId[selectedId] or nil end
    function obj:Search(q) query = tostring(q or ""):lower(); rebuild() end
    function obj:Refresh() rebuild() end
    function obj:Count() local n = 0; for _ in pairs(byId) do n = n + 1 end return n end
    function obj:VisibleCount() return #flat end
    function obj:GetVList() return vlist end
    win:OnTheme(function() vlist:Refresh() end, f)
    if o.Roots then obj:SetRoots(o.Roots) else rebuild() end
    local base = Register(win, o, obj, f)
    local baseDestroy = base.Destroy
    base.Destroy = function() pcall(function() vlist:Destroy() end) baseDestroy(base) end
    return base
end

------------------------------------------------------------------ JSON / DATA VIEWER
local JSON_KIND = { String = "Success", Number = "Warning", Boolean = "Accent2", Nil = "TextMuted", Instance = "Info", Vector = "Accent", Enum = "Accent2", Table = "TextMuted" }
local function BuildJson(T, value, key, depth, seen, lim)
    local keyStr = key ~= nil and (type(key) == "number" and ("[" .. key .. "]") or tostring(key)) or nil
    local node = { Rich = true }
    if typeof(value) == "table" then
        if seen[value] then
            node.Text = (keyStr and (Rich(T.Text, keyStr) .. " ") or "") .. Rich(T.Danger, "<cycle>")
            node.Plain = keyStr or "cycle"
            return node
        end
        local n = 0
        for _ in pairs(value) do n = n + 1 end
        node.Text = (keyStr and (Rich(T.Text, keyStr) .. " ") or "") .. Rich(T.TextMuted, "{" .. n .. "}")
        node.Plain = keyStr or "table"
        node.Children = {}
        if depth >= lim.Depth then
            node.Children[1] = { Text = Rich(T.TextMuted, "{…}"), Rich = true, Plain = "…" }
            return node
        end
        seen[value] = true
        local keys = {}
        for i = 1, #value do keys[#keys + 1] = i end
        local rest = {}
        for k in pairs(value) do if not (type(k) == "number" and k >= 1 and k <= #value and k == math.floor(k)) then rest[#rest + 1] = k end end
        table.sort(rest, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(rest) do keys[#keys + 1] = k end
        for i, k in ipairs(keys) do
            if i > lim.Items then
                node.Children[#node.Children + 1] = { Text = Rich(T.TextMuted, "… " .. (#keys - lim.Items) .. " more"), Rich = true, Plain = "more" }
                break
            end
            node.Children[#node.Children + 1] = BuildJson(T, value[k], k, depth + 1, seen, lim)
        end
        seen[value] = nil
    else
        local text, kind = Describe(value)
        node.Text = (keyStr and (Rich(T.Text, keyStr) .. Rich(T.TextMuted, " = ")) or "") .. Rich(T[JSON_KIND[kind] or "Text"], text)
        node.Plain = (keyStr or "") .. " " .. text
    end
    return node
end

function Elements:CreateJsonViewer(o)
    o = Named(o, "Data")
    local win = self.Window
    local value = o.Value
    local lim = { Depth = o.MaxDepth or 8, Items = o.MaxItems or 200 }
    local tree
    local view = {}
    local function load(v, rootName)
        value = v
        tree:SetRoots({ BuildJson(win.Theme, v, rootName or o.RootName or "Data", 1, {}, lim) })
        tree:ExpandAll(o.ExpandDepth or 1)
    end
    local topts = Copy(o)
    topts.Value, topts.Toolbar = nil, {
        { Text = "Expand", Callback = function() tree:ExpandAll() end },
        { Text = "Collapse", Callback = function() tree:CollapseAll(); local r = tree:GetVList() end },
        { Text = "Copy", Callback = function() view:Copy() end },
    }
    tree = self:CreateTree(topts)
    function view:Set(v, rootName) load(v, rootName) end
    function view:GetValue() return value end
    function view:GetText() return Serialize(value, { Depth = lim.Depth, MaxItems = lim.Items }) end
    function view:Copy()
        local ok = ClipSvc.Copy(view:GetText())
        win:Notify({ Title = ok and "Copied" or "Copy not supported", Type = ok and "success" or "warning", Duration = 2 })
        return ok
    end
    function view:ExpandAll(d) tree:ExpandAll(d) end
    function view:CollapseAll() tree:CollapseAll() end
    function view:SetVisible(v) tree:SetVisible(v) end
    function view:Destroy() tree:Destroy() end
    view.Tree, view.Frame = tree, tree.Frame
    load(value)
    return view
end

------------------------------------------------------------------ CODE VIEWER
local LUA_KW = {}
for w in ("and break do else elseif end false for function if in local nil not or repeat return then true until while continue"):gmatch("%a+") do LUA_KW[w] = true end
local LUA_BUILTIN = {}
for w in ("game workspace script print warn error pcall xpcall task wait spawn delay require typeof type tostring tonumber ipairs pairs next select table string math os Instance Vector3 Vector2 CFrame Color3 UDim2 Enum"):gmatch("%a+") do LUA_BUILTIN[w] = true end

local function HighlightLua(line, T)
    local out, i, n, plain = {}, 1, #line, {}
    local function flush() if #plain > 0 then out[#out + 1] = Esc(table.concat(plain)); plain = {} end end
    while i <= n do
        local c = line:sub(i, i)
        if line:sub(i, i + 1) == "--" then
            flush(); out[#out + 1] = Rich(T.TextMuted, line:sub(i)); i = n + 1
        elseif c == '"' or c == "'" then
            flush()
            local j = i + 1
            while j <= n do
                local d = line:sub(j, j)
                if d == "\\" then j = j + 2 elseif d == c then break else j = j + 1 end
            end
            out[#out + 1] = Rich(T.Success, line:sub(i, math.min(j, n)))
            i = j + 1
        elseif c:match("%d") then
            flush()
            local _, e = line:find("^[%d%.xXa-fA-F_]+", i)
            out[#out + 1] = Rich(T.Warning, line:sub(i, e)); i = e + 1
        elseif c:match("[%a_]") then
            flush()
            local _, e = line:find("^[%w_]+", i)
            local w = line:sub(i, e)
            if LUA_KW[w] then out[#out + 1] = Rich(T.Accent, w)
            elseif LUA_BUILTIN[w] then out[#out + 1] = Rich(T.Info, w)
            else out[#out + 1] = Esc(w) end
            i = e + 1
        else plain[#plain + 1] = c; i = i + 1 end
    end
    flush()
    return table.concat(out)
end

function Elements:CreateCodeViewer(o)
    o = Opt(self, "CreateCodeViewer", Named(o, "Code"))
    local win = self.Window
    local Theme = win.Theme
    local New, Text, Stroke, Gradient = win:Kit()
    local size = o.TextSize or 12
    local charW, lineH = size * 0.56, size + 5
    local H = o.Height or 240
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", (o.Name or "code"):lower())
    local obj = Obj("CodeViewer")
    obj.NoSave = true
    local code, lines, vlines = "", {}, {}
    local wrap, highlight = o.Wrap == true, o.Highlight ~= false
    local found, query, cache = nil, "", {}
    local gutterW = 40
    local hs, gutter, vl

    local function visualLines()
        vlines = {}
        local view = math.max(f.AbsoluteSize.X - gutterW - 14, 120)
        local cols = math.max(10, math.floor(view / charW))
        local maxLen = 0
        for i, ln in ipairs(lines) do
            if wrap and #ln > cols then
                local pos = 1
                while pos <= #ln do vlines[#vlines + 1] = { n = (pos == 1) and i or nil, src = i, text = ln:sub(pos, pos + cols - 1) }; pos = pos + cols end
                maxLen = math.max(maxLen, cols)
            else
                vlines[#vlines + 1] = { n = i, src = i, text = ln }
                maxLen = math.max(maxLen, #ln)
            end
        end
        return wrap and view or math.max(view, maxLen * charW + 24)
    end
    local function relayout()
        gutterW = math.max(34, #tostring(#lines) * (size * 0.62) + 14)
        gutter.Scroll.Parent.Size = UDim2.new(0, gutterW, 1, 0)
        hs.Position = UDim2.fromOffset(gutterW, 0)
        hs.Size = UDim2.new(1, -gutterW, 1, 0)
        local w = visualLines()
        hs.CanvasSize = UDim2.fromOffset(w, 0)
        vl.Scroll.Size = UDim2.new(0, w, 1, 0)
        vl:SetCount(#vlines)
        gutter:SetCount(#vlines)
    end

    -- toolbar
    SearchBar(win, f, { Placeholder = "Find...", Size = UDim2.new(1, -196, 0, 24), OnChange = function(t) query = t:lower(); found = nil end })
    local function tb(txt, x, w, fn)
        local b = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 4), Size = UDim2.fromOffset(w, 24), BackgroundColor3 = "$SurfaceHover", Text = txt, Font = FONT_BOLD,
            TextSize = 10, TextColor3 = "$TextMuted", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4, Parent = f }, { Corner(6) })
        b.Activated:Connect(function() fn(b) end)
    end
    tb("All", -8, 30, function() obj:SelectAll() end)
    tb("Copy", -42, 38, function() obj:Copy() end)
    tb("Wrap", -84, 38, function(b) obj:SetWrap(not wrap); b.TextColor3 = wrap and Theme.Accent or Theme.TextMuted end)
    tb("▶", -126, 26, function() obj:Find(query, true) end)
    tb("◀", -156, 26, function() obj:Find(query, false) end)

    local body = New("Frame", { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32), BackgroundTransparency = 1, ClipsDescendants = true, Parent = f })
    local gutterHolder = New("Frame", { Size = UDim2.new(0, gutterW, 1, 0), BackgroundColor3 = "$Surface2", BorderSizePixel = 0, ClipsDescendants = true, Parent = body })
    hs = New("ScrollingFrame", { Position = UDim2.fromOffset(gutterW, 0), Size = UDim2.new(1, -gutterW, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        ScrollBarImageColor3 = "$Accent", ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(), Parent = body })
    local rowState = setmetatable({}, { __mode = "k" })
    vl = VList.new(win, hs, {
        RowHeight = lineH, Size = UDim2.new(1, 0, 1, 0),
        Create = function(scroll)
            local row = New("Frame", { Size = UDim2.new(1, 0, 0, lineH), BackgroundColor3 = "$Accent", BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = scroll })
            rowState[row] = Text({ Text = "", Font = FONT_CODE, TextSize = size, RichText = true, TextWrapped = false, Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -6, 1, 0), Parent = row })
            return row
        end,
        Render = function(row, idx)
            local vlne = vlines[idx]
            if not vlne then return end
            local txt = vlne.text
            if highlight then
                local c = cache[txt]
                if not c then
                    c = HighlightLua(txt, win.Theme)
                    local n = 0
                    for _ in pairs(cache) do n = n + 1 end
                    if n > 800 then cache = {} end
                    cache[txt] = c
                end
                txt = c
            else txt = Esc(txt) end
            rowState[row].Text = txt
            row.BackgroundTransparency = (found and vlne.src == found) and 0.82 or 1
        end,
    })
    local gState = setmetatable({}, { __mode = "k" })
    gutter = VList.new(win, gutterHolder, {
        RowHeight = lineH, Size = UDim2.new(1, 0, 1, 0),
        Create = function(scroll)
            local row = New("Frame", { Size = UDim2.new(1, 0, 0, lineH), BackgroundTransparency = 1, Visible = false, Parent = scroll })
            gState[row] = Text({ Text = "", Font = FONT_CODE, TextSize = size - 1, TextColor3 = "$TextDisabled", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -6, 1, 0), Parent = row })
            return row
        end,
        Render = function(row, idx) local v = vlines[idx]; gState[row].Text = (v and v.n) and tostring(v.n) or "" end,
    })
    gutter.Scroll.ScrollingEnabled = false
    gutter.Scroll.ScrollBarThickness = 0
    vl.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() gutter.Scroll.CanvasPosition = Vector2.new(0, vl.Scroll.CanvasPosition.Y) end)
    f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if wrap then relayout() end end)

    function obj:Get() return code end
    function obj:SetCode(text)
        code = tostring(text or "")
        lines = {}
        for ln in (code .. "\n"):gmatch("(.-)\r?\n") do lines[#lines + 1] = ln end
        if #lines > 1 and lines[#lines] == "" then table.remove(lines) end
        found, cache = nil, {}
        relayout()
    end
    obj.Set = function(_, t) obj:SetCode(t) end
    function obj:GetCode() return code end
    function obj:Lines() return #lines end
    function obj:SetWrap(v) wrap = v and true or false; relayout() end
    function obj:SetHighlight(v) highlight = v and true or false; vl:Refresh() end
    function obj:GoToLine(n)
        n = math.clamp(math.floor(tonumber(n) or 1), 1, math.max(#lines, 1))
        found = n
        for i, v in ipairs(vlines) do if v.src == n and v.n then vl:ScrollTo(i, true); break end end
        vl:Refresh()
    end
    function obj:Find(q, forward)
        q = tostring(q or query or ""):lower()
        if q == "" or #lines == 0 then return nil end
        local start = found or (forward == false and #lines + 1 or 0)
        local step = forward == false and -1 or 1
        local i = start + step
        for _ = 1, #lines do
            if i > #lines then i = 1 elseif i < 1 then i = #lines end
            if lines[i]:lower():find(q, 1, true) then obj:GoToLine(i); return i end
            i = i + step
        end
        return nil
    end
    function obj:Copy()
        local ok = ClipSvc.Copy(code)
        win:Notify({ Title = ok and "Code copied" or "Copy not supported", Type = ok and "success" or "warning", Duration = 2 })
        return ok
    end
    function obj:SelectAll() return obj:Copy() end
    function obj:Destroy() vl:Destroy(); gutter:Destroy() end
    win:OnTheme(function() cache = {}; vl:Refresh() end, f)
    obj:SetCode(o.Code or "")
    local base = Register(win, o, obj, f)
    local baseDestroy = base.Destroy
    base.Destroy = function() pcall(function() vl:Destroy(); gutter:Destroy() end) baseDestroy(base) end
    return base
end

------------------------------------------------------------------ IMAGES, BRANDING & SMALL COMPONENTS
function Window:ResolveImage(ref)
    if ref == "Icon" then return self:BrandImage("Icon") end
    if ref == "Theme" or ref == "ThemeImage" then return self:BrandImage("ThemeImage") end
    return Assets:Alias(ref)
end

local FIT = { Fit = Enum.ScaleType.Fit, Crop = Enum.ScaleType.Crop, Stretch = Enum.ScaleType.Stretch, Tile = Enum.ScaleType.Tile }
function Elements:CreateImage(o)
    o = Opt(self, "CreateImage", Named(o, "Image"))
    local win = self.Window
    local New, Text, Stroke, Gradient = win:Kit()
    local H = o.Height or 120
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container },
        { Corner(o.CornerRadius or 8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", (o.Name or "image"):lower())
    local fb = Text({ Text = o.FallbackText or "Image unavailable", TextSize = 11, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = f })
    local fit = FIT[o.FitMode or (o.Crop and "Crop") or "Fit"] or FIT.Fit
    local img = New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = fit, ImageTransparency = o.Transparency or 0, ZIndex = 2, Parent = f }, { Corner(o.CornerRadius or 8) })
    local bind
    local obj = Obj("Image")
    obj.NoSave = true
    function obj:Get() return img.Image end
    function obj:Set(ref)
        if bind then bind.Cancel() end
        fb.Visible = true
        img.Image = ""
        bind = Assets:Bind(img, win:ResolveImage(ref), { Fallback = fb })
    end
    function obj:SetTransparency(t) img.ImageTransparency = t end
    obj:Set(o.Image)
    win.Events:On("BrandingChanged", function() if not obj._dead and (o.Image == "Icon" or o.Image == "Theme") then obj:Set(o.Image) end end)
    local r = Register(win, o, obj, f)
    r:OnDestroyed(function() if bind then bind.Cancel() end end)
    return r
end

-- About / branding card: theme image banner + icon + name + framework + developer + version
function Elements:CreateBrand(o)
    o = Opt(self, "CreateBrand", Named(o, "About"))
    local win = self.Window
    local New, Text, Stroke, Gradient = win:Kit()
    local banner = o.Banner ~= false
    local H = banner and 176 or 96
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(10), Stroke("$Border", 1, 0.45) })
    f:SetAttribute("RHName", "about brand rage hub")
    local bimg
    local bBind
    if banner then
        bimg = New("ImageLabel", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = "$Background", BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, Parent = f })
        local fade = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0, 90), Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = f })
        New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = fade })
    end
    local art = win:_brandCircle(f, 56, "Icon")
    art.Holder.AnchorPoint = Vector2.new(0, 0.5)
    art.Holder.Position = UDim2.fromOffset(16, banner and 98 or 48)
    art.Holder.ZIndex = 3
    local nm = Text({ Text = "", Font = FONT_BOLD, TextSize = 16, Position = UDim2.fromOffset(84, banner and 100 or 22), Size = UDim2.new(1, -96, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = f })
    local tg = Text({ Text = "", Font = FONT, TextSize = 11, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(84, banner and 122 or 44), Size = UDim2.new(1, -96, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = f })
    local vr = Text({ Text = "", Font = FONT, TextSize = 11, TextColor3 = "$Accent", Position = UDim2.fromOffset(84, banner and 140 or 62), Size = UDim2.new(1, -96, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = f })
    local function apply()
        local b = win.Branding
        nm.Text = tostring(b.Name or RageHub.Name)
        tg.Text = tostring(b.Tagline or RageHub.Framework)
        vr.Text = "Developer: " .. tostring(b.Developer or RageHub.Developer) .. "  ·  Version " .. RageHub.Version
        art:Load(win:BrandImage("Icon"))
        if bimg then
            if bBind then bBind.Cancel() end
            local ref = win:BrandImage("ThemeImage")
            if ref then bBind = Assets:Bind(bimg, ref) else bimg.Image = "" end
        end
    end
    apply()
    local conn = win.Events:On("BrandingChanged", apply)
    local obj = Obj("Brand")
    obj.NoSave = true
    function obj:Get() return nil end
    local r = Register(win, o, obj, f)
    r:OnDestroyed(function() conn:Disconnect(); if bBind then bBind.Cancel() end end)
    return r
end

function Elements:CreateSeparator(text) return self:CreateDivider(text) end

function Elements:CreateSearchBox(o)
    o = Opt(self, "CreateSearchBox", Named(o, "Search"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = "$Surface", BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    local obj = Obj("SearchBox")
    local box = SearchBar(win, f, {
        Placeholder = o.Placeholder, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 24),
        OnChange = function(t)
            Commit(win, o, obj, t, false)
            win:Call(o, o.Callback, t)
        end,
    })
    function obj:Get() return box.Text end
    function obj:Set(t, silent) box.Text = tostring(t or "") end
    function obj:Focus() pcall(function() box:CaptureFocus() end) end
    obj.NoSave = true
    return Register(win, o, obj, f)
end

function Elements:CreateIconButton(o)
    o = Opt(self, "CreateIconButton", Named(o, "Actions"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local specs = o.Buttons or { { Icon = o.Icon, Tooltip = o.Tooltip, Callback = o.Callback } }
    local size = o.Size or (Caps().Touch and 40 or 34)
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, size), BackgroundTransparency = 1, LayoutOrder = NextOrder(self), Parent = self.Container }, { List(6, Enum.FillDirection.Horizontal) })
    f:SetAttribute("RHName", (o.Name or "actions"):lower())
    local obj = Obj("IconButton")
    obj.NoSave = true
    local buttons = {}
    for i, sp in ipairs(specs) do
        local b = New("TextButton", { LayoutOrder = i, Size = UDim2.fromOffset(size, size), BackgroundColor3 = "$Surface", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = f }, { Corner(8), Stroke("$Border", 1, 0.5) })
        local ic = tostring(sp.Icon or "?")
        if ic:match("^rbxassetid://") or ic:match("^%d+$") then
            New("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(size * 0.5, size * 0.5), BackgroundTransparency = 1, Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, Parent = b })
        else
            Text({ Text = ic, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = b })
        end
        win:Hover(b)
        if sp.Tooltip then win:Tooltip(b, sp.Tooltip) end
        b.Activated:Connect(function() win.Sound:Play("click"); obj:_fire("Activated", i); win:Call(o, sp.Callback, i) end)
        buttons[i] = b
    end
    function obj:Get() return nil end
    return Register(win, o, obj, f)
end

-- Card: a titled container; elements can be created inside it (card:CreateToggle(...))
function Elements:CreateCard(o)
    o = Opt(self, "CreateCard", Named(o, o and o.Title or "Card"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = "$Surface", BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container },
        { Corner(10), Stroke("$Border", 1, 0.45), Pad(10, 10, 10, 10), List(6) })
    f:SetAttribute("RHName", ((o.Title or "") .. " " .. (o.Description or "")):lower())
    Text({ Text = o.Title or o.Name, Font = FONT_BOLD, TextSize = 13, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, Parent = f })
    if o.Description then Text({ Text = o.Description, Font = FONT, TextSize = 11, TextColor3 = "$TextMuted", TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = f }) end
    local body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = f }, { List(6) })
    local card = setmetatable({ Window = win, Page = self.Page, Container = body, Frame = f, Module = self.Module, FlagPrefix = self.FlagPrefix }, { __index = Elements })
    function card:SetVisible(v) f:SetAttribute("RHHidden", (not v) or nil); f.Visible = v and true or false end
    function card:Destroy() f:Destroy() end
    return card
end

local BADGE_COLORS = { info = "Info", success = "Success", warning = "Warning", danger = "Danger", error = "Danger", accent = "Accent", muted = "TextMuted" }
function Elements:CreateBadge(o)
    o = Opt(self, "CreateBadge", Named(o, o and o.Text or "Badge"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = NextOrder(self), Parent = self.Container })
    f:SetAttribute("RHName", (o.Text or o.Name):lower())
    local pill = New("Frame", { Size = UDim2.new(0, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = "$Surface2", BorderSizePixel = 0, Parent = f }, { CornerFull(), Stroke("$Border", 1, 0.3), Pad(10, 0, 10, 0) })
    local lab = Text({ Text = "", Font = FONT_BOLD, TextSize = 11, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = pill })
    local kind = o.Type or "info"
    local obj = Obj("Badge")
    obj.NoSave = true
    local function paint() lab.TextColor3 = win.Theme[BADGE_COLORS[kind] or "Info"]; lab.Text = (o.Text or o.Name) end
    function obj:Get() return o.Text end
    function obj:Set(text, k) o.Text = tostring(text); if k then kind = k end paint() end
    paint()
    win:OnTheme(paint, f)
    return Register(win, o, obj, f)
end

local STATUS_KIND = { online = "Success", ok = "Success", idle = "Warning", busy = "Warning", warning = "Warning", error = "Danger", offline = "TextDisabled", info = "Info" }
function Elements:CreateStatus(o)
    o = Opt(self, "CreateStatus", o)
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = Base(self, o, 150)
    local dot = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Parent = f }, { CornerFull() })
    local lab = Text({ Text = "", TextSize = 12, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -28, 0.5, 0), Size = UDim2.fromOffset(120, 18), Parent = f })
    local status, text = o.Status or "idle", o.Text
    local obj = Obj("Status")
    obj.NoSave = true
    local function paint() dot.BackgroundColor3 = win.Theme[STATUS_KIND[status] or "TextMuted"]; lab.Text = text or status end   -- text label keeps the status readable without colour
    function obj:Get() return status end
    function obj:Set(st, t) status = st; text = t or text; paint() end
    paint()
    win:OnTheme(paint, f)
    return Register(win, o, obj, f)
end

function Elements:CreateStat(o)
    o = Opt(self, "CreateStat", o)
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = "$Surface", BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", o.Name:lower())
    Text({ Text = o.Name, TextSize = 11, TextColor3 = "$TextMuted", Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 14), Parent = f })
    local val = Text({ Text = "", Font = FONT_BOLD, TextSize = 20, Position = UDim2.fromOffset(12, 24), Size = UDim2.new(0.6, 0, 0, 30), Parent = f })
    local delta = Text({ Text = "", TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.new(0.4, 0, 0, 16), Parent = f })
    local obj = Obj("Stat")
    obj.NoSave = true
    local value = o.Value
    function obj:Get() return value end
    function obj:Set(v, d)
        value = v
        val.Text = tostring(v == nil and "-" or v) .. (o.Suffix or "")
        if d ~= nil then
            delta.Text = (type(d) == "number" and (d >= 0 and "+" or "") .. tostring(Round(d, 2))) or tostring(d)
            delta.TextColor3 = (type(d) == "number" and d < 0) and win.Theme.Danger or win.Theme.Success
        end
    end
    obj:Set(o.Value, o.Delta)
    return Register(win, o, obj, f)
end

function Elements:CreateMeter(o)
    o = Opt(self, "CreateMeter", o)
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f, H = Base(self, o, 90, 48)
    local max = o.Max or 100
    local warnAt, dangerAt = (o.Thresholds and o.Thresholds.Warning) or 0.6, (o.Thresholds and o.Thresholds.Danger) or 0.85
    local value = 0
    local valL = Text({ TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$TextMuted", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(80, 18), Parent = f })
    local bar = New("Frame", { Position = UDim2.new(0, 12, 0, H - 16), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = "$Border", BorderSizePixel = 0, Parent = f }, { Corner(3) })
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar }, { Corner(3) })
    local obj = Obj("Meter")
    obj.NoSave = true
    local function paint()
        local r = max == 0 and 0 or math.clamp(value / max, 0, 1)
        local bad = o.Invert and (1 - r) or r
        win:Tween(fill, { Size = UDim2.fromScale(r, 1), BackgroundColor3 = bad >= dangerAt and win.Theme.Danger or (bad >= warnAt and win.Theme.Warning or win.Theme.Success) }, 0.2)
        valL.Text = tostring(Round(value, 1)) .. (o.Suffix or "")
    end
    function obj:Get() return value end
    function obj:Set(v) value = tonumber(v) or value; paint() end
    value = o.Default or 0
    paint()
    return Register(win, o, obj, f)
end

local TL_COLORS = { info = "Info", success = "Success", warning = "Warning", error = "Danger" }
function Elements:CreateTimeline(o)
    o = Opt(self, "CreateTimeline", Named(o, "Timeline"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local H = o.Height or 160
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = "$Surface", BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", o.Name:lower())
    Text({ Text = o.Name, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 18), Parent = f })
    local scroll = New("ScrollingFrame", { Position = UDim2.fromOffset(8, 28), Size = UDim2.new(1, -16, 1, -34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = "$Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f }, { List(6) })
    local items, n, max = {}, 0, o.MaxItems or 100
    local obj = Obj("Timeline")
    obj.NoSave = true
    function obj:Get() return n end
    function obj:Add(text, kind, time)
        n = n + 1
        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = n, Parent = scroll })
        New("Frame", { Position = UDim2.fromOffset(2, 5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = "$" .. (TL_COLORS[kind or "info"] or "Info"), BorderSizePixel = 0, Parent = row }, { CornerFull() })
        Text({ Text = tostring(text) .. (time and ("  ·  " .. tostring(time)) or ""), TextSize = 11, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(18, 0),
            Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
        items[#items + 1] = row
        if #items > max then table.remove(items, 1):Destroy() end
    end
    function obj:Clear() for _, r in ipairs(items) do r:Destroy() end items = {}; n = 0 end
    for _, it in ipairs(o.Items or {}) do obj:Add(it.Text or it, it.Type, it.Time) end
    return Register(win, o, obj, f)
end

function Elements:CreateAccordion(o)
    o = type(o) == "table" and o or {}
    local win = self.Window
    local sections = {}
    for i, it in ipairs(o.Items or {}) do
        local sec = self:CreateSection(it.Title or ("Item " .. i), { Collapsed = not it.Open })
        sections[i] = sec
        if it.Build then win:Call({ Name = "Accordion:" .. tostring(it.Title) }, it.Build, sec) end
        if o.Exclusive then
            sec.Head.Activated:Connect(function()
                if sec.Container.Visible then for _, other in ipairs(sections) do if other ~= sec then other:SetCollapsed(true) end end end
            end)
        end
    end
    return { Sections = sections, Open = function(_, i) for j, s in ipairs(sections) do s:SetCollapsed(j ~= i) end end }
end

function Elements:CreateEmptyState(o)
    o = Opt(self, "CreateEmptyState", Named(o, o and o.Title or "Empty"))
    local win = self.Window
    local New, Text, Stroke, Gradient = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, o.ButtonText and 150 or 116), BackgroundTransparency = 1, LayoutOrder = NextOrder(self), Parent = self.Container })
    f:SetAttribute("RHName", ((o.Title or "") .. " " .. (o.Content or "")):lower())
    Text({ Text = o.Icon or "∅", TextSize = 28, TextColor3 = "$TextDisabled", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 34), Parent = f })
    Text({ Text = o.Title or "Nothing here yet", Font = FONT_BOLD, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 18), Parent = f })
    Text({ Text = o.Content or "", Font = FONT, TextSize = 11, TextColor3 = "$TextMuted", TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 66), Size = UDim2.new(1, -40, 0, 32), Parent = f })
    local obj = Obj("EmptyState")
    obj.NoSave = true
    if o.ButtonText then
        local b = New("TextButton", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 108), Size = UDim2.fromOffset(120, 30), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = f }, { Corner(15) })
        Gradient(b, 0)
        Text({ Text = o.ButtonText, Font = FONT_BOLD, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = b })
        b.Activated:Connect(function() obj:_fire("Activated"); win:Call(o, o.Callback) end)
    end
    function obj:Get() return nil end
    return Register(win, o, obj, f)
end

local SPIN = { "◐", "◓", "◑", "◒" }
function Elements:CreateSpinner(o)
    o = Opt(self, "CreateSpinner", Named(o, o and o.Text or "Loading"))
    local win = self.Window
    local New, Text, Stroke = win:Kit()
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = "$Surface", BorderSizePixel = 0, LayoutOrder = NextOrder(self), Parent = self.Container }, { Corner(8), Stroke("$Border", 1, 0.55) })
    f:SetAttribute("RHName", (o.Text or o.Name):lower())
    local glyph = Text({ Text = SPIN[1], TextSize = 16, TextColor3 = "$Accent", TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(24, 34), Parent = f })
    local lab = Text({ Text = o.Text or o.Name, TextSize = 12, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -46, 1, 0), Parent = f })
    local i, spinning = 1, true
    local worker = win.Tasks:Every(0.15, function() if spinning and f.Visible then i = i % #SPIN + 1; glyph.Text = SPIN[i] end end, "spinner_" .. tostring(math.random(1e9)))
    local obj = Obj("Spinner")
    obj.NoSave = true
    function obj:Get() return spinning end
    function obj:SetText(t) lab.Text = tostring(t) end
    function obj:Stop(msg) spinning = false; glyph.Text = "✓"; if msg then lab.Text = msg end worker:Stop("done") end
    local r = Register(win, o, obj, f)
    r:OnDestroyed(function() worker:Destroy() end)
    return r
end
Elements.CreateLoading = Elements.CreateSpinner

function Elements:CreateNotificationCenter(o)
    o = Named(o, "Notifications")
    local win = self.Window
    local tbl = self:CreateTable({
        Name = o.Name, Height = o.Height or 200, EmptyText = "No notifications yet", Search = o.Search,
        Columns = { { Key = "Clock", Title = "Time", Width = 0.18 }, { Key = "Type", Title = "Type", Width = 0.16 }, { Key = "Title", Title = "Title", Width = 0.26 }, { Key = "Content", Title = "Message" } },
    })
    for i = #(win.NotificationLog or {}), 1, -1 do local e = win.NotificationLog[i]; tbl:AddRow({ Clock = e.Clock, Type = e.Type, Title = e.Title, Content = e.Content }) end
    local conn = win.Events:On("Notification", function(e) tbl:InsertRow(1, { Clock = e.Clock, Type = e.Type, Title = e.Title, Content = e.Content }) end)
    tbl:OnDestroyed(function() conn:Disconnect() end)
    function tbl:ClearHistory() win:ClearNotificationHistory(); tbl:Clear() end
    return tbl
end

------------------------------------------------------------------ NOTIFICATIONS (queue · stack · progress · actions · history)
local NOTE_COLORS = { info = "Accent", success = "Success", warning = "Warning", error = "Danger", progress = "Info" }
local MAX_VISIBLE = 4

function Window:_buildNotifs()
    local New = self:Kit()
    self._nActive, self._nQueue, self._nOrder, self.NotificationLog = {}, {}, 0, {}
    self._notifs = New("Frame", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 290, 1, -32), BackgroundTransparency = 1, ZIndex = 50, Parent = self.Gui,
    }, { New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
end

function Window:_showNotification(o, handle)
    local New, Text, Stroke = self:Kit()
    local T = self.Theme
    local kind = NOTE_COLORS[o.Type] and o.Type or "info"
    local color = T[NOTE_COLORS[kind]]
    local persistent = kind == "progress" or o.Duration == 0
    local dur = o.Duration or 4
    self._nOrder = self._nOrder + 1
    local wrap = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self._nOrder, Parent = self._notifs })
    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 60, 0, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = wrap,
    }, { Corner(10), Stroke(T.Border, 1, 0.2) })
    New("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card }, { Corner(2) })
    local content = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card }, { Pad(16, 10, 12, 10), List(4) })
    local titleL = Text({ Text = o.Title or "Rage Hub", Font = FONT_BOLD, TextSize = 14, TextColor3 = T.Text, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content })
    local bodyL
    if (o.Content and o.Content ~= "") or kind == "progress" then
        bodyL = Text({ Text = o.Content or "", Font = FONT, TextSize = 12, TextColor3 = T.TextMuted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = content })
    end
    local closed = false
    local function close()
        if closed then return end
        closed = true
        handle._open = false
        for i, h in ipairs(self._nActive) do if h == handle then table.remove(self._nActive, i); break end end
        self:Tween(card, { Position = UDim2.new(1, 60, 0, 0) }, 0.25)
        task.delay(self.AnimFactor == 0 and 0 or 0.3, function() wrap:Destroy() end)
        local nxt = table.remove(self._nQueue, 1)
        if nxt then self:_showNotification(nxt.o, nxt.handle) end
    end
    if type(o.Buttons) == "table" and #o.Buttons > 0 then
        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 3, Parent = content }, { List(6, Enum.FillDirection.Horizontal) })
        for i, b in ipairs(o.Buttons) do
            local btn = New("TextButton", {
                LayoutOrder = i, Size = UDim2.fromOffset(b.Width or 74, 26), BackgroundColor3 = "$SurfaceHover", Text = b.Text or "OK",
                Font = FONT_BOLD, TextSize = 11, TextColor3 = color, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6, Parent = row,
            }, { Corner(6) })
            btn.Activated:Connect(function() self:Call(o, b.Callback); close() end)
        end
    end
    local prog
    if kind == "progress" then
        local track = New("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = "$Border", BorderSizePixel = 0, LayoutOrder = 4, Parent = content }, { Corner(2) })
        prog = New("Frame", { Size = UDim2.fromScale(handle.Progress or 0, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track }, { Corner(2) })
    elseif not persistent then
        local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0, LayoutOrder = 4, Parent = content }, { Corner(1) })
        self:Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)
    end
    New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = card }).Activated:Connect(close)
    self:Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35)
    self._nActive[#self._nActive + 1] = handle
    handle.Close, handle._open = close, true
    function handle:SetTitle(t) titleL.Text = tostring(t) end
    function handle:SetContent(t) if bodyL then bodyL.Text = tostring(t) end end
    function handle:SetProgress(v)
        handle.Progress = math.clamp(tonumber(v) or 0, 0, 1)
        if prog then prog.Size = UDim2.fromScale(handle.Progress, 1) end
        if handle.Progress >= 1 and kind == "progress" then task.delay(1, close) end
    end
    if not persistent then task.delay(dur, close) end
    if kind == "progress" and (handle.Progress or 0) >= 1 then task.delay(1, close) end
end

function Window:Notify(o)
    if type(o) == "string" then o = { Title = o } end
    o = type(o) == "table" and o or {}
    local kind = NOTE_COLORS[o.Type] and o.Type or "info"
    local entry = { Title = o.Title, Content = o.Content, Type = kind, Time = os.time(), Clock = os.date("%H:%M:%S") }
    table.insert(self.NotificationLog, entry)
    if #self.NotificationLog > 100 then table.remove(self.NotificationLog, 1) end
    self.Events:Emit("Notification", entry)
    local handle = { Progress = o.Progress or 0, _open = false }
    function handle.Close() end
    function handle.SetTitle() end
    function handle.SetContent() end
    function handle.SetProgress(_, v) handle.Progress = math.clamp(tonumber(v) or 0, 0, 1) end
    function handle:IsOpen() return handle._open end
    if not self.NotificationsEnabled then return handle end
    self.Sound:Play(kind == "success" and "success" or (kind == "error" and "error" or "notify"))
    if #self._nActive >= MAX_VISIBLE then
        if o.Queue == false then return handle end
        self._nQueue[#self._nQueue + 1] = { o = o, handle = handle }
        if #self._nQueue > 20 then table.remove(self._nQueue, 1) end
        return handle
    end
    self:_showNotification(o, handle)
    return handle
end
function Window:DismissAll()
    self._nQueue = {}
    for _, h in ipairs(Copy(self._nActive)) do pcall(h.Close) end
end
function Window:GetNotificationHistory() return Copy(self.NotificationLog) end
function Window:ClearNotificationHistory() self.NotificationLog = {}; self.Events:Emit("NotificationsCleared") end

------------------------------------------------------------------ DIALOG SERVICE (Info · Confirm · Input · Warning · Destructive)
function Window:Dialog(o)
    o = type(o) == "table" and o or {}
    local win = self
    local New, Text, Stroke, Gradient = self:Kit()
    local kind = o.Type or "Info"
    local dim = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "$Overlay", BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 60, Parent = self.Gui })
    self:Tween(dim, { BackgroundTransparency = 0.5 }, 0.2)
    local vp = Workspace.CurrentCamera.ViewportSize
    local card = New("Frame", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.new(0, math.clamp(math.floor(vp.X * 0.9), 240, 320), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = dim,
    }, { Corner(12), Stroke(kind == "Destructive" and "$Danger" or "$Border", 1, kind == "Destructive" and 0.2 or 0.2), Pad(16, 14, 16, 14), List(10) })
    local sc = New("UIScale", { Scale = 0.9, Parent = card })
    self:Tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
    local icon = ({ Warning = "⚠  ", Destructive = "⚠  ", Info = "", Confirm = "", Input = "" })[kind] or ""
    Text({ Text = icon .. (o.Title or "Rage Hub"), Font = FONT_BOLD, TextSize = 15, TextColor3 = (kind == "Warning" and "$Warning") or (kind == "Destructive" and "$Danger") or "$Text", Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Parent = card })
    if o.Content and o.Content ~= "" then
        Text({ Text = o.Content, Font = FONT, TextSize = 12, TextColor3 = "$TextMuted", TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = card })
    end
    local box, errL
    if kind == "Input" then
        box = New("TextBox", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = "$SurfaceHover", Text = tostring(o.Default or ""), PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = "$TextMuted",
            TextColor3 = "$Text", Font = FONT_MED, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = 3, Parent = card,
        }, { Corner(8), Stroke("$Border", 1, 0.3), Pad(10, 0, 10, 0) })
        errL = Text({ Text = "", TextSize = 11, TextColor3 = "$Danger", Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 4, Visible = false, Parent = card })
    end
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 5, Parent = card }, { List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right) })
    local handle = { Type = kind }
    local closed = false
    local bind
    local function close()
        if closed then return end
        closed = true
        if bind then bind:Disconnect() end
        for i, d in ipairs(win._dialogs) do if d == handle then table.remove(win._dialogs, i); break end end
        win:Tween(dim, { BackgroundTransparency = 1 }, 0.15)
        win:Tween(sc, { Scale = 0.9 }, 0.15)
        task.delay(win.AnimFactor == 0 and 0 or 0.16, function() dim:Destroy() end)
    end
    handle.Close = close
    local buttons = o.Buttons
    if not buttons then
        if kind == "Confirm" then buttons = { { Text = "Cancel" }, { Text = o.ConfirmText or "Confirm", Primary = true, Callback = function() win:Call(o, o.Callback, true) end } }
        elseif kind == "Input" then buttons = { { Text = "Cancel" }, { Text = o.ConfirmText or "OK", Primary = true, Input = true } }
        elseif kind == "Destructive" then buttons = { { Text = "Cancel" }, { Text = o.ConfirmText or "Delete", Danger = true, Delay = 1.2, Callback = function() win:Call(o, o.Callback, true) end } }
        else buttons = { { Text = o.ConfirmText or "OK", Primary = true, Callback = function() win:Call(o, o.Callback) end } } end
    end
    for i, b in ipairs(buttons) do
        local btn = New("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(b.Width or 92, 32), BackgroundColor3 = b.Danger and "$Danger" or (b.Primary and WHITE or "$SurfaceHover"),
            Text = (b.Primary and "") or (b.Text or "OK"), Font = FONT_BOLD, TextSize = 12, TextColor3 = b.Danger and WHITE or "$Text", AutoButtonColor = false, BorderSizePixel = 0, Parent = row,
        }, { Corner(8) })
        if b.Primary then
            Gradient(btn, 0)
            Text({ Text = b.Text or "OK", Font = FONT_BOLD, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = btn })
        end
        local ready = not b.Delay
        if b.Delay then btn.BackgroundTransparency = 0.5; task.delay(b.Delay, function() ready = true; if not closed then btn.BackgroundTransparency = 0 end end) end
        btn.Activated:Connect(function()
            if not ready then return end
            if b.Input and box then
                local text = box.Text
                if o.Validate then
                    local okc, ok, err = pcall(o.Validate, text)
                    if okc and ok == false then errL.Text = tostring(err or "Invalid value"); errL.Visible = true return end
                end
                close()
                win:Call(o, o.Callback, text)
                return
            end
            close()
            win:Call(o, b.Callback)
        end)
    end
    dim.Activated:Connect(close)                       -- dialogs never trap input: tap outside or press Esc
    bind = self.Input:Bind({ Key = Enum.KeyCode.Escape, Id = "dialog.escape", Owner = { Name = "Dialog" }, AllowGameProcessed = true, OnPress = close })
    self._dialogs[#self._dialogs + 1] = handle
    return handle
end
function Window:Confirm(o) o = Copy(o or {}); o.Type = "Confirm"; return self:Dialog(o) end
function Window:Prompt(o) o = Copy(o or {}); o.Type = "Input"; return self:Dialog(o) end
function Window:CloseDialogs() for _, d in ipairs(Copy(self._dialogs)) do pcall(d.Close) end end

------------------------------------------------------------------ COMMAND PALETTE (opt-in)
function Window:RegisterCommand(c)
    if type(c) ~= "table" or type(c.Name) ~= "string" or type(c.Callback) ~= "function" then
        Warn("RegisterCommand", "needs { Name = string, Callback = function }")
        return nil
    end
    local id = c.Id or c.Name
    self._commands[id] = { Id = id, Name = c.Name, Description = c.Description, Keywords = c.Keywords or "", Callback = c.Callback, Owner = c.Owner or "Core" }
    self.Events:Emit("CommandRegistered", id)
    local win = self
    return { Id = id, Unregister = function() win._commands[id] = nil end, Destroy = function() win._commands[id] = nil end }
end
function Window:GetCommands()
    local out = {}
    for _, c in pairs(self._commands) do out[#out + 1] = c end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end

function Window:CloseCommandPalette() if self._palette and self._palette.close then self._palette.close() end end
function Window:OpenCommandPalette()
    local win = self
    if self._palette and self._palette.close then self._palette.close() end
    local New, Text, Stroke = self:Kit()
    local vp = Workspace.CurrentCamera.ViewportSize
    local dim = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "$Overlay", BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, ZIndex = 80, Parent = self.Gui })
    local w = math.clamp(math.floor(vp.X * 0.92), 260, 380)
    local card = New("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, math.floor(vp.Y * 0.12)), Size = UDim2.fromOffset(w, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "$Surface", BorderSizePixel = 0, Parent = dim }, { Corner(12), Stroke("$Accent", 1, 0.3), Pad(8, 8, 8, 8), List(6) })
    local results = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = card }, { List(2) })
    local top
    local function run(c) win:CloseCommandPalette(); win:Call({ Name = "Command:" .. c.Name, Module = c.Owner }, c.Callback) end
    local function fill(q)
        for _, ch in ipairs(results:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        local list = SearchSvc.Filter(win:GetCommands(), q, function(c) return c.Name .. " " .. c.Keywords .. " " .. tostring(c.Description or "") end, "fuzzy")
        top = list[1]
        for i = 1, math.min(#list, 8) do
            local c = list[i]
            local b = New("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, Caps().Touch and 38 or 30), BackgroundColor3 = "$SurfaceHover", BackgroundTransparency = i == 1 and 0.4 or 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = results }, { Corner(6) })
            Text({ Text = c.Name, TextSize = 12, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.62, 0, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = b })
            Text({ Text = c.Owner, TextSize = 10, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.34, 0, 1, 0), Parent = b })
            b.Activated:Connect(function() run(c) end)
        end
        if #list == 0 then Text({ Text = "No matching commands", TextSize = 11, TextColor3 = "$TextMuted", TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 24), Parent = results }) end
    end
    local box = SearchBar(win, card, { Placeholder = "Type a command...", Position = UDim2.new(), Size = UDim2.new(1, 0, 0, 30), OnChange = fill })
    box.LayoutOrder = 1
    box.FocusLost:Connect(function(enter) if enter and top then run(top) end end)
    local closed = false
    local bind
    local function close()
        if closed then return end
        closed = true
        if bind then bind:Disconnect() end
        dim:Destroy()
        win._palette.close = nil
    end
    dim.Activated:Connect(close)
    bind = self.Input:Bind({ Key = Enum.KeyCode.Escape, Id = "palette.escape", AllowGameProcessed = true, OnPress = close })
    self._palette = self._palette or {}
    self._palette.close = close
    fill("")
    pcall(function() box:CaptureFocus() end)
end

function Window:EnableCommandPalette(o)
    o = type(o) == "table" and o or {}
    local win = self
    if self._palette and self._palette.bind then return true end
    self._palette = self._palette or {}
    self._palette.bind = self.Input:Bind({
        Key = o.Key or Enum.KeyCode.K, Modifiers = o.Modifiers or { Ctrl = true }, Id = "palette.open", Owner = { Name = "Command palette" },
        Callback = function() win:OpenCommandPalette() end, Cleanup = self.Cleanup,
    })
    local function core(id, name, desc, fn) self:RegisterCommand({ Id = "core." .. id, Name = name, Description = desc, Callback = fn, Owner = "Core" }) end
    core("toggle", "Toggle Window", "Show or hide the window", function() win:Toggle() end)
    core("settings", "Open Settings", "Go to the settings tab", function() if win._settingsTab then win:SelectTab(win._settingsTab); win:Show() end end)
    core("export", "Export Config", "Copy the config JSON", function()
        local ok = ClipSvc.Copy(win:ExportConfig())
        win:Notify({ Title = ok and "Config copied" or "Copy not supported", Type = ok and "success" or "warning", Duration = 2 })
    end)
    core("reset", "Reset UI", "Reset window position and size", function() win.Main.Position = UDim2.fromScale(.5, .5); win._userSize = false; win._size = win:_defaultSize(); win:_applySize() end)
    core("dismiss", "Dismiss Notifications", "Close all notifications", function() win:DismissAll() end)
    core("clearlogs", "Clear Logs", "Clear the window log", function() win.Logger:Clear() end)
    return true
end
function Window:DisableCommandPalette()
    if self._palette and self._palette.bind then self._palette.bind:Disconnect(); self._palette.bind = nil end
    for id in pairs(Copy(self._commands)) do if id:sub(1, 5) == "core." then self._commands[id] = nil end end
    self:CloseCommandPalette()
end

------------------------------------------------------------------ CONFIG (namespaced · versioned · migrating)
local CONFIG_VERSION = 1
-- Migrations run in order from the file's version up to CONFIG_VERSION. Version 0 = the flat v2-era format.
local MIGRATIONS = {
    [0] = function(d)
        local out = { ConfigVersion = 1, Core = {}, Window = d.__window or {}, Elements = {}, Modules = {} }
        for k, v in pairs(d) do if k ~= "__window" and k ~= "ConfigVersion" then out.Elements[k] = v end end
        return out
    end,
}
RageHub.ConfigVersion = CONFIG_VERSION

local function MigrateConfig(data)
    if type(data) ~= "table" then return nil, "Config is not a table" end
    local v = tonumber(data.ConfigVersion) or 0
    if v > CONFIG_VERSION then Warn("Config", "file version " .. v .. " is newer than this library (" .. CONFIG_VERSION .. "); loading best-effort") end
    local guard = 0
    while v < CONFIG_VERSION and guard < 20 do
        local m = MIGRATIONS[v]
        if not m then return nil, "No migration from config version " .. v end
        local ok, res = pcall(m, data)
        if not ok or type(res) ~= "table" then return nil, "Migration from v" .. v .. " failed" end
        data, v, guard = res, tonumber(res.ConfigVersion) or (v + 1), guard + 1
    end
    for _, section in ipairs({ "Core", "Window", "Elements", "Modules" }) do
        if data[section] ~= nil and type(data[section]) ~= "table" then data[section] = nil end
    end
    return data
end

function Window:_path(name) return self.ConfigFolder .. "/" .. (name:gsub("[^%w_%- ]", "")) .. ".json" end
function Window:_ensureFolder()
    local path
    for p in self.ConfigFolder:gmatch("[^/]+") do
        path = path and (path .. "/" .. p) or p
        if not isfolder(path) then makefolder(path) end
    end
end
function Window:_changed()
    if self._loading or not self.AutoSaveName or not Caps().FileSystem then return end
    if self._saveTask then pcall(task.cancel, self._saveTask) end
    self._saveTask = task.delay(1.2, function()
        self._saveTask = nil
        if not self._destroyed then self:SaveConfig(self.AutoSaveName) end
    end)
end

function Window:_coreState()
    return {
        Theme = self.ThemeName ~= "Custom" and self.ThemeName or nil, Scale = self.UIScale, Transparency = self.Main.BackgroundTransparency,
        ToggleKey = self.ToggleKey and self.ToggleKey.Name, Sounds = self.Sound.Enabled, Animation = self.AnimMode, Density = self.DensityName,
        SidebarCollapsed = self.SidebarCollapsed, Minimized = self.Minimized, Launcher = self._launcher and self._launcher.Visible or false,
    }
end

function Window:_collect()
    local data = { ConfigVersion = CONFIG_VERSION, Core = {}, Window = {}, Elements = {}, Modules = {} }
    if self.PersistWindow then
        data.Core = self:_coreState()
        local p = self.Main.Position
        data.Window = { x = p.X.Offset, y = p.Y.Offset, w = self._userSize and self._size.X or nil, h = self._userSize and self._size.Y or nil }
    end
    for flag, opt in pairs(self.Options) do
        if opt.Type ~= "Button" and not opt.NoSave then
            local val = opt:Get()
            if opt.Type == "Keybind" then val = val and val.Name or false
            elseif opt.Type == "ColorPicker" then val = { Round(val.R * 255), Round(val.G * 255), Round(val.B * 255) } end
            data.Elements[flag] = val
            if opt.Binder and opt.Type ~= "Keybind" then
                local k = opt.Binder.Get()
                data.Elements[flag .. "::key"] = k and k.Name or false
            end
        end
    end
    for flag, v in pairs(self._pending) do if data.Elements[flag] == nil then data.Elements[flag] = v end end   -- keep settings of absent modules
    local seen = {}
    for name, inst in pairs(self.ModuleInstances) do
        seen[name] = true
        data.Modules[name] = { Enabled = inst.State == "Enabled", Config = Copy(self._modCfg[name] or {}) }
    end
    for name, cfg in pairs(self._modCfg) do if not seen[name] then data.Modules[name] = { Enabled = false, Config = Copy(cfg) } end end
    return data
end

function Window:_applyOne(opt, val)
    if opt.Type == "ColorPicker" and type(val) == "table" then val = Color3.fromRGB(val[1] or 0, val[2] or 0, val[3] or 0) end
    pcall(function() opt:Set(val) end)
end

function Window:_applyCore(c)
    local function sync(key, v) local e = self.Options["Core." .. key]; if e then pcall(e.Set, e, v, true) end end
    if c.Theme and Themes[c.Theme] then self:SetTheme(c.Theme); sync("theme", c.Theme) end
    if type(c.Scale) == "number" then self:SetScale(c.Scale); sync("scale", Round(c.Scale * 100)) end
    if type(c.Transparency) == "number" then self.Main.BackgroundTransparency = math.clamp(c.Transparency, 0, 0.6); sync("alpha", Round(c.Transparency * 100)) end
    if c.ToggleKey and ToKey(c.ToggleKey) then self:SetToggleKey(c.ToggleKey); sync("togglekey", c.ToggleKey) end
    if type(c.Sounds) == "boolean" then self.Sound:SetEnabled(c.Sounds); sync("sounds", c.Sounds) end
    if c.Animation and ANIM[c.Animation] ~= nil then self:SetAnimation(c.Animation); sync("animation", c.Animation) end
    if c.Density and DENSITY[c.Density] then self:SetDensity(c.Density) end
    if type(c.SidebarCollapsed) == "boolean" then self:SetSidebarCollapsed(c.SidebarCollapsed, false) end
    if type(c.Minimized) == "boolean" then self:SetMinimized(c.Minimized) end
    if type(c.Launcher) == "boolean" and self._launcher then self._launcher.Visible = c.Launcher; sync("launcher", c.Launcher) end
end

function Window:_apply(data, opts)
    opts = opts or {}
    local d, err = MigrateConfig(data)
    if not d then self.Logger:Error("Config", tostring(err)); return false, err end
    self._loading = true
    if self.PersistWindow and not opts.NoWindow then
        if type(d.Core) == "table" then self:_applyCore(d.Core) end
        local w = d.Window
        if type(w) == "table" and type(w.x) == "number" and type(w.y) == "number" then
            local vp = Workspace.CurrentCamera.ViewportSize
            self:SetPosition(math.clamp(w.x, -vp.X / 2 + 60, vp.X / 2 - 60), math.clamp(w.y, -vp.Y / 2 + 40, vp.Y / 2 - 40))
            if type(w.w) == "number" and type(w.h) == "number" then self:SetSize(w.w, w.h) end
        end
    end
    for flag, val in pairs(d.Elements or {}) do
        local base = flag:match("^(.-)::key$")
        if base then
            local opt = self.Options[base]
            if opt and opt.Binder then pcall(opt.Binder.Set, val or nil) else self._pending[flag] = val end
        else
            local opt = self.Options[flag]
            if opt then self:_applyOne(opt, val) else self._pending[flag] = val end   -- element/module not present yet: ignored safely, kept for later
        end
    end
    for name, m in pairs(d.Modules or {}) do
        if type(m) == "table" then
            if type(m.Config) == "table" then self._modCfg[name] = Copy(m.Config) end
            if opts.RestoreModules and m.Enabled == true and G.Modules[name] and not self:IsModuleEnabled(name) then self:EnableModule(name) end
        end
    end
    self._loading = false
    self.Events:Emit("ConfigLoaded")
    return true
end

function Window:SaveConfig(name)
    if not Caps().FileSystem then return false, "Executor has no file system" end
    name = name or self.AutoSaveName or "default"
    local ok, err = pcall(function()
        self:_ensureFolder()
        writefile(self:_path(name), HttpService:JSONEncode(self:_collect()))
    end)
    if ok then self.Events:Emit("ConfigSaved", name) end
    return ok, err
end
function Window:LoadConfig(name, opts)
    if not Caps().FileSystem then return false, "Executor has no file system" end
    name = name or self.AutoSaveName or "default"
    local path = self:_path(name)
    if not isfile(path) then return false, "Config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false, "Config is corrupted" end
    return self:_apply(data, opts)
end
function Window:DeleteConfig(name)
    if not (Caps().FileSystem and type(delfile) == "function") then return false end
    local path = self:_path(name)
    if isfile(path) then delfile(path); return true end
    return false
end
function Window:ListConfigs()
    local out = {}
    if Caps().FileSystem and type(listfiles) == "function" then
        pcall(function()
            self:_ensureFolder()
            for _, p in ipairs(listfiles(self.ConfigFolder)) do
                local n = p:match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end)
        table.sort(out)
    end
    return out
end
function Window:ExportConfig() return HttpService:JSONEncode(self:_collect()) end
function Window:ImportConfig(json, opts)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false, "Invalid JSON" end
    if type(data.Window) == "table" then data.Window = nil end     -- an imported string never moves the window
    opts = Copy(opts or {}); opts.NoWindow = true
    return self:_apply(data, opts)
end
function Window:ResetConfig()
    self._loading = true
    for flag, opt in pairs(self.Options) do
        if opt._default ~= nil and not opt.NoSave then
            if opt.Type == "ColorPicker" then pcall(opt.Set, opt, opt._default) else pcall(function() opt:Set(opt._default) end) end
        end
    end
    self._pending = {}
    self._loading = false
    self.Events:Emit("ConfigReset")
    return true
end
function Window:OnChanged(fn) self._flagListeners[#self._flagListeners + 1] = fn end
function Window:GetFlag(flag) return self.Flags[flag] end
function Window:GetElement(idOrFlag) return self.ElementsById[idOrFlag] or self.Options[idOrFlag] end
function Window:Copy(text) return ClipSvc.Copy(text) end

------------------------------------------------------------------ SETTINGS (core + settings contributed by enabled modules)
function Window:_buildModuleSettings(name)
    local tab = self._settingsTab
    if not tab or self._settingsSections[name] then return end
    local fn = self._settingsContrib[name]
    local inst = self.ModuleInstances[name]
    if not fn or not inst or inst.State ~= "Enabled" then return end
    local m = (self:_manifest(name) or {})._meta or {}
    local sec = tab:CreateSection((m.DisplayName or name) .. " Settings")
    sec.Module = name
    self._settingsSections[name] = sec
    self:Call({ Name = name .. " settings", Module = name }, fn, sec, inst.Context)
end
function Window:_dropModuleSettings(name)
    local sec = self._settingsSections[name]
    if sec then pcall(function() sec.Holder:Destroy() end); self._settingsSections[name] = nil end
end

function Window:CreateSettingsTab(name, opts)
    opts = type(opts) == "table" and opts or {}
    local win = self
    if self._settingsTab then return self._settingsTab end
    local tab = self:CreateTab(name or "Settings", "⚙")
    self._settingsTab = tab
    local function core(obj, key) win.Options["Core." .. key] = obj; obj.NoSave = true; return obj end

    if opts.Brand then tab:CreateBrand({ Name = "About" }) end
    local ui = tab:CreateSection("Interface")
    core(ui:CreateDropdown({ Name = "Theme", Flag = "Core.theme", Options = RageHub:GetThemes(), Default = self.ThemeName, Callback = function(v) win:SetTheme(v) end }), "theme")
    ui:CreateColorPicker({
        Name = "Custom Accent", Description = "Overrides the theme accent color", Default = self.Theme.Accent,
        Callback = function(c)
            local h, s, v = c:ToHSV()
            win:SetAccent(c, Color3.fromHSV((h + 0.08) % 1, s, v))
        end,
    })
    core(ui:CreateSlider({ Name = "Window Transparency", Flag = "Core.alpha", Range = { 0, 60 }, Default = Round(self.Main.BackgroundTransparency * 100), Suffix = "%", Callback = function(v) win.Main.BackgroundTransparency = v / 100 end }), "alpha")
    core(ui:CreateSlider({ Name = "UI Scale", Flag = "Core.scale", Range = { 70, 130 }, Increment = 5, Default = self.UIScale * 100, Suffix = "%", Callback = function(v) win:SetScale(v / 100) end }), "scale")
    core(ui:CreateKeybind({ Name = "Toggle Key", Description = "Esc clears the key", Flag = "Core.togglekey", Default = self.ToggleKey, OnChange = function(k) if k then win:SetToggleKey(k) end end }), "togglekey")
    core(ui:CreateSegmented({ Name = "Animation", Flag = "Core.animation", Options = { "off", "fast", "normal", "slow" }, Default = self.AnimMode, Callback = function(v) win:SetAnimation(v) end }), "animation")
    core(ui:CreateToggle({ Name = "UI Sounds", Flag = "Core.sounds", Default = self.Sound.Enabled, Callback = function(v) win.Sound:SetEnabled(v) end }), "sounds")
    if self._launcher or Caps().Touch then
        core(ui:CreateToggle({ Name = "Floating Launcher", Flag = "Core.launcher", Default = self._launcher ~= nil and self._launcher.Visible, Callback = function(v) win:SetLauncherVisible(v) end }), "launcher")
    end
    ui:CreateToggle({ Name = "Watermark", Description = "FPS and ping overlay", Default = self._wm ~= nil, Callback = function(v) if v then win:CreateWatermark() elseif win._wm then win._wm:Destroy() end end })

    local cfg = tab:CreateSection("Configuration")
    local cfgName = "default"
    local picker
    cfg:CreateInput({ Name = "Config Name", Default = "default", Callback = function(v) if v ~= "" then cfgName = v end end })
    cfg:CreateButton({
        Name = "Save Config", ButtonText = "Save",
        Callback = function()
            local ok, err = win:SaveConfig(cfgName)
            win:Notify({ Title = ok and "Config saved" or "Save failed", Content = ok and cfgName or tostring(err), Type = ok and "success" or "error" })
            if picker then picker:Refresh(win:ListConfigs(), true) end
        end,
    })
    picker = cfg:CreateDropdown({ Name = "Saved Configs", Options = win:ListConfigs(), Callback = function(v) if v then cfgName = v end end })
    cfg:CreateButton({
        Name = "Load Config", ButtonText = "Load",
        Callback = function()
            local ok, err = win:LoadConfig(cfgName)
            win:Notify({ Title = ok and "Config loaded" or "Load failed", Content = ok and cfgName or tostring(err), Type = ok and "success" or "error" })
        end,
    })
    cfg:CreateButton({
        Name = "Delete Config", ButtonText = "Delete", Confirm = "Delete the selected config file?",
        Callback = function()
            local ok = win:DeleteConfig(cfgName)
            win:Notify({ Title = ok and "Config deleted" or "Nothing to delete", Content = cfgName, Type = ok and "warning" or "error" })
            picker:Refresh(win:ListConfigs())
        end,
    })
    cfg:CreateToggle({ Name = "Auto-Save", Description = "Save automatically whenever something changes", Callback = function(v) win.AutoSaveName = v and cfgName or nil end })
    cfg:CreateButton({ Name = "Reset Settings", ButtonText = "Reset", Confirm = "Reset all saved element values to their defaults?", Callback = function() win:ResetConfig(); win:Notify({ Title = "Settings reset", Type = "warning", Duration = 2 }) end })
    cfg:CreateButton({
        Name = "Copy Config (JSON)", Description = "Share your settings with others", ButtonText = "Copy",
        Callback = function()
            local ok = ClipSvc.Copy(win:ExportConfig())
            win:Notify({ Title = ok and "Copied to clipboard" or "Copy not supported", Type = ok and "success" or "warning", Duration = 3 })
        end,
    })
    local importText = ""
    cfg:CreateInput({ Name = "Import JSON", Placeholder = "Paste config...", Width = 150, Callback = function(t) importText = t end })
    cfg:CreateButton({
        Name = "Import Config", ButtonText = "Import",
        Callback = function()
            local ok, err = win:ImportConfig(importText)
            win:Notify({ Title = ok and "Config imported" or "Import failed", Content = ok and "" or tostring(err), Type = ok and "success" or "error" })
        end,
    })

    local misc = tab:CreateSection("Misc")
    misc:CreateButton({ Name = "Reset Window Position", ButtonText = "Reset", Callback = function() win.Main.Position = UDim2.fromScale(.5, .5) end })
    misc:CreateButton({ Name = "Unload Rage Hub", ButtonText = "Unload", Confirm = "This removes the UI completely.", Callback = function() win:Destroy() end })
    misc:CreateLabel("Rage Hub v" .. RageHub.Version .. "  ·  " .. RageHub.Framework .. "  ·  " .. RageHub.Developer)
    for name in pairs(self.ModuleInstances) do self:_buildModuleSettings(name) end
    return tab
end

------------------------------------------------------------------ MODULE SYSTEM
-- A module = manifest + lifecycle { Init, Enable, Disable, Reload, Destroy }. Each window owns its own instance,
-- so state is never shared. Nothing is created until EnableModule; disabling releases everything the module owned.
G.Aliases = { Logs = "Console", DeveloperConsole = "Console", EventLogger = "Console", PerformanceMonitor = "Performance", RemoteSpy = "RemoteInspector", Explorer = "InstanceExplorer" }
local CORE_FEATURES = {
    Tables = true, Lists = true, Trees = true, CodeViewer = true, JsonViewer = true, Search = true, Logger = true, Notifications = true, Dialogs = true,
    ContextMenu = true, CommandPalette = true, Panels = true, State = true, Events = true, Tasks = true, Cleanup = true, Config = true, Themes = true,
    Assets = true, Branding = true, Modules = true, Diagnostics = true, Tooltips = true, Clipboard = true, Settings = true,
}

RageHub.Utils = { Copy = Copy, Round = Round, Trunc = Trunc, Serialize = Serialize, Describe = Describe, InstPath = InstPath, Hex = Hex, Mix = Mix, Rich = Rich, Esc = Esc, IsCallable = IsCallable }
RageHub.Search = SearchSvc
RageHub.Clipboard = ClipSvc

local function CleanManifest(m, builtin)
    return {
        Name = m.Name, DisplayName = m.DisplayName or m.Name, Version = m.Version or "1.0.0", Category = m.Category or "Tools",
        Description = m.Description or "", Dependencies = m.Dependencies or {}, Builtin = builtin == true,
    }
end

function RageHub:RegisterModule(m, builtin)
    if type(m) ~= "table" or type(m.Name) ~= "string" or m.Name == "" then Warn("RegisterModule", "a module needs a string Name"); return false end
    if type(m.Enable) ~= "function" and type(m.Init) ~= "function" then Warn("RegisterModule", "module '" .. m.Name .. "' needs an Enable (or Init) function"); return false end
    if m.Dependencies ~= nil and type(m.Dependencies) ~= "table" then Warn("RegisterModule", "Dependencies must be an array of names"); return false end
    if G.Modules[m.Name] and not builtin then Warn("RegisterModule", "'" .. m.Name .. "' was already registered; replacing it") end
    G.Modules[m.Name] = m
    G.Modules[m.Name]._meta = CleanManifest(m, builtin)
    return true
end
function RageHub:GetModules()
    local out = {}
    for _, m in pairs(G.Modules) do out[#out + 1] = Copy(m._meta) end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end
function RageHub:GetModule(name)
    name = G.Aliases[name] or name
    local m = G.Modules[name]
    return m and Copy(m._meta) or nil
end
function RageHub:HasFeature(name)
    if CORE_FEATURES[name] then return true end
    if G.Modules[G.Aliases[name] or name] then return true end
    local caps = Caps()
    return caps[name] == true
end

function Window:RegisterModule(m)
    if type(m) ~= "table" or type(m.Name) ~= "string" or (type(m.Enable) ~= "function" and type(m.Init) ~= "function") then
        Warn("Window:RegisterModule", "needs { Name = string, Enable = function }")
        return false
    end
    self._localModules = self._localModules or {}
    m._meta = CleanManifest(m, false)
    self._localModules[m.Name] = m
    return true
end

function Window:_manifest(name)
    name = G.Aliases[name] or name
    return (self._localModules and self._localModules[name]) or G.Modules[name], name
end
function Window:IsModuleEnabled(name)
    name = G.Aliases[name] or name
    local i = self.ModuleInstances[name]
    return i ~= nil and i.State == "Enabled"
end
function Window:GetEnabledModules()
    local out = {}
    for n, i in pairs(self.ModuleInstances) do if i.State == "Enabled" then out[#out + 1] = n end end
    table.sort(out)
    return out
end
function Window:GetModuleState(name)
    local m, real = self:_manifest(name)
    if not m then return "Unknown" end
    local i = self.ModuleInstances[real]
    if i then return i.State end
    return self._modState[real] or "Disabled"
end
function Window:GetModuleInfo(name)
    local m, real = self:_manifest(name)
    if not m then return nil end
    local info = Copy(m._meta)
    info.State = self:GetModuleState(real)
    local i = self.ModuleInstances[real]
    info.Resources = i and i.Context and i.Context.Cleanup:Count() or 0
    info.Workers = i and i.Context and i.Context.Tasks:Count() or 0
    info.Error = i and i.Error or self._modErr and self._modErr[real]
    return info
end
function Window:GetModules()
    local seen, out = {}, {}
    for _, meta in ipairs(RageHub:GetModules()) do seen[meta.Name] = true; local i = self:GetModuleInfo(meta.Name); if i then out[#out + 1] = i end end
    for n in pairs(self._localModules or {}) do if not seen[n] then out[#out + 1] = self:GetModuleInfo(n) end end
    return out
end

local function ctxEvents(win, cleanup)
    local e = {}
    function e:On(name, cb) local c = win.Events:On(name, cb); cleanup:Add(c); return c end
    function e:Once(name, cb) local c = win.Events:Once(name, cb); cleanup:Add(c); return c end
    function e:Emit(name, ...) win.Events:Emit(name, ...) end
    return e
end

function Window:_makeContext(name, manifest, options)
    local win = self
    local meta = manifest._meta
    local cleanup = self.Cleanup:Child("Module:" .. name)
    local tasks = Tasks.new(self.Logger, self.Tasks, name)
    local ctx = {
        RageHub = RageHub, Window = win, Module = name, Options = options or {}, Theme = win.Theme, State = win.State:Scope(name),
        Logger = win.Logger:Scope(name), Cleanup = cleanup, Tasks = tasks, Events = ctxEvents(win, cleanup), Utils = RageHub.Utils,
        Search = SearchSvc, Clipboard = ClipSvc, Assets = Assets, Input = {},
    }
    function ctx.Input:Bind(o) o = Copy(o); o.Cleanup = cleanup; o.Owner = { Name = o.Id or "bind", Module = name }; return win.Input:Bind(o) end
    ctx.Config = {
        Get = function(_, key, default) local v = (win._modCfg[name] or {})[key]; if v == nil then return default end return v end,
        Set = function(_, key, value) win._modCfg[name] = win._modCfg[name] or {}; win._modCfg[name][key] = value; win:_changed() end,
        All = function() return Copy(win._modCfg[name] or {}) end,
    }
    function ctx:Notify(o) return win:Notify(o) end
    function ctx:Dialog(o) return win:Dialog(o) end
    function ctx:CreateTab(tabName, icon, topts)
        topts = Copy(topts or {}); topts.Module = name; topts.FlagPrefix = name .. "."
        return win:CreateTab(tabName, icon, topts)
    end
    function ctx:CreatePanel(popts)
        popts = Copy(popts or {}); popts.Module = name; popts.FlagPrefix = name .. "."
        return win:CreatePanel(popts)
    end
    function ctx:CreateWindow(wopts)
        wopts = Copy(wopts or {}); wopts.AllowMultiple = true; wopts.Id = wopts.Id or (win.Id .. ":" .. name)
        local w = RageHub:CreateWindow(wopts)
        cleanup:Add(w)
        return w
    end
    -- the module decides how it appears: Tab (default) · Panel · Float · Section · Window
    function ctx:CreateView(title, icon)
        local d = ctx.Options.Display or "Tab"
        if ctx.Options.Parent and type(ctx.Options.Parent.CreateSection) == "function" then
            local sec = ctx.Options.Parent:CreateSection(title)
            sec.Module, sec.FlagPrefix = name, name .. "."
            cleanup:Add(function() pcall(function() sec.Holder:Destroy() end) end)
            return sec
        elseif d == "Panel" or d == "Float" then
            return ctx:CreatePanel({ Name = title, Title = title, Dock = d == "Float" and "Float" or "Bottom", Size = ctx.Options.Size or 220 })
        elseif d == "Window" then
            local w = ctx:CreateWindow({ Name = title, Splash = false })
            return w:CreateTab(title, icon)
        end
        return ctx:CreateTab(title, icon)
    end
    function ctx:RegisterCommand(c)
        c = Copy(c); c.Owner = meta.DisplayName
        c.Id = name .. "." .. tostring(c.Id or c.Name)
        local h = win:RegisterCommand(c)
        if h then cleanup:Add(h) end
        return h
    end
    function ctx:AddSettings(fn)
        win._settingsContrib[name] = fn
        cleanup:Add(function() win._settingsContrib[name] = nil end)
    end
    return ctx
end

local function runPhase(win, inst, name, fnName, ctx)
    local f = inst.Manifest[fnName]
    if type(f) ~= "function" then return true end
    local ok, err = xpcall(f, debug.traceback, inst, ctx)
    if not ok then
        win.Logger:Error(name, fnName .. " failed\n" .. tostring(err))
        return false, tostring(err)
    end
    return true
end

local function dependsOn(win, name, target)
    local m = win:_manifest(name)
    for _, d in ipairs(m and m.Dependencies or {}) do if (G.Aliases[d] or d) == target then return true end end
    return false
end

function Window:EnableModule(name, options)
    if self._destroyed then return false, "Window destroyed" end
    local manifest, real = self:_manifest(name)
    if not manifest then
        self.Logger:Error("Modules", "Unknown module '" .. tostring(name) .. "'")
        return false, "Unknown module"
    end
    name = real
    local cur = self.ModuleInstances[name]
    if cur and cur.State == "Enabled" then return true end
    self._enabling = self._enabling or {}
    if self._enabling[name] then
        self.Logger:Error("Modules", "Circular dependency while enabling '" .. name .. "'")
        return false, "Circular dependency"
    end
    self._enabling[name] = true
    local function fail(msg)
        self._enabling[name] = nil
        self._modState[name] = "Failed"
        self._modErr = self._modErr or {}
        self._modErr[name] = msg
        self.Logger:Error(name, "Module initialization failed: " .. tostring(msg))
        self.Events:Emit("ModuleFailed", name, msg)
        return false, msg
    end
    for _, dep in ipairs(manifest.Dependencies or {}) do
        local depName = G.Aliases[dep] or dep
        if self:_manifest(depName) then
            local ok, err = self:EnableModule(depName)
            if not ok then return fail("dependency '" .. depName .. "' failed: " .. tostring(err)) end
        elseif not RageHub:HasFeature(depName) then
            return fail("missing dependency '" .. depName .. "'")
        end
    end
    local inst = setmetatable({ Name = name, State = "Enabling", Manifest = manifest, Window = self }, { __index = manifest })
    local ctx = self:_makeContext(name, manifest, options)
    inst.Context = ctx
    self.ModuleInstances[name] = inst
    local ok, err = runPhase(self, inst, name, "Init", ctx)
    if ok then ok, err = runPhase(self, inst, name, "Enable", ctx) end
    if not ok then
        inst.State, inst.Error = "Failed", err
        self:_teardownModule(name, false, true)
        return fail(err)
    end
    inst.State = "Enabled"
    self._enabling[name] = nil
    self._modState[name] = "Enabled"
    if self._modErr then self._modErr[name] = nil end
    self.Logger:Success(name, "Module enabled")
    self:_buildModuleSettings(name)
    self.Events:Emit("ModuleEnabled", name)
    return true
end

-- full cleanup of everything a module owned; keeps its saved config (not its runtime caches)
function Window:_teardownModule(name, destroy, failed)
    local inst = self.ModuleInstances[name]
    if not inst then return end
    local ctx = inst.Context
    if not failed and inst.State == "Enabled" then runPhase(self, inst, name, "Disable", ctx) end
    self:_dropModuleSettings(name)
    if ctx then
        pcall(function() ctx.Tasks:Destroy(); ctx.Tasks:Detach() end)
        pcall(function() ctx.Cleanup:Destroy() end)
    end
    local owned = self._modOwned[name]
    if owned then
        for _, t in ipairs(Copy(owned.tabs)) do pcall(function() t:Destroy() end) end
        for _, p in ipairs(Copy(owned.panels)) do pcall(function() p:Destroy() end) end
        self._modOwned[name] = nil
    end
    for id, c in pairs(Copy(self._commands)) do if id:sub(1, #name + 1) == name .. "." then self._commands[id] = nil end end
    if destroy and not failed then runPhase(self, inst, name, "Destroy", ctx) end
    inst.Context, inst.State = nil, failed and "Failed" or "Disabled"
    if not failed then self._modState[name] = destroy and "Destroyed" or "Disabled" end
    self.ModuleInstances[name] = nil
    self:_pruneElements()
end

function Window:DisableModule(name)
    local _, real = self:_manifest(name)
    name = real or name
    local inst = self.ModuleInstances[name]
    if not inst or inst.State ~= "Enabled" then return false end
    for other, oi in pairs(Copy(self.ModuleInstances)) do
        if oi.State == "Enabled" and dependsOn(self, other, name) then self:DisableModule(other) end   -- dependents go first
    end
    self:_teardownModule(name, false)
    self.Logger:Info(name, "Module disabled")
    self.Events:Emit("ModuleDisabled", name)
    return true
end
function Window:DestroyModule(name, silent)
    local _, real = self:_manifest(name)
    name = real or name
    if not self.ModuleInstances[name] then return false end
    for other, oi in pairs(Copy(self.ModuleInstances)) do
        if oi.State == "Enabled" and dependsOn(self, other, name) then self:DestroyModule(other, silent) end
    end
    self:_teardownModule(name, true)
    if not silent then self.Events:Emit("ModuleDisabled", name) end
    return true
end
function Window:ReloadModule(name)
    local _, real = self:_manifest(name)
    name = real or name
    local inst = self.ModuleInstances[name]
    if not inst or inst.State ~= "Enabled" then return self:EnableModule(name) end
    local opts = inst.Context and inst.Context.Options
    if type(inst.Manifest.Reload) == "function" then
        local ok = runPhase(self, inst, name, "Reload", inst.Context)
        if ok then self.Events:Emit("ModuleReloaded", name); return true end
    end
    self:DisableModule(name)
    local ok, err = self:EnableModule(name, opts)
    if ok then self.Events:Emit("ModuleReloaded", name) end
    return ok, err
end
function Window:ToggleModule(name, v)
    if v == nil then v = not self:IsModuleEnabled(name) end
    if v then return self:EnableModule(name) end
    return self:DisableModule(name)
end
function Window:GetModuleInstance(name) local _, real = self:_manifest(name); return self.ModuleInstances[real or name] end

-- declarative setup: Features = { Notifications = true, Logs = true, RemoteInspector = false, ... }
function Window:_applyFeatures(features)
    if type(features) ~= "table" then return end
    for name, v in pairs(features) do
        if name == "Notifications" then self.NotificationsEnabled = v ~= false
        elseif name == "CommandPalette" then if v then self:EnableCommandPalette(type(v) == "table" and v or nil) end
        elseif name == "Settings" then if v then self:CreateSettingsTab() end
        elseif CORE_FEATURES[name] then -- always available core components (Tables, Trees, ...); nothing to create
        elseif v ~= false and self:_manifest(name) then self:EnableModule(name, type(v) == "table" and v or nil)
        elseif v ~= false then Warn("CreateWindow", "unknown feature/module '" .. tostring(name) .. "'") end
    end
end

------------------------------------------------------------------ BUILT-IN MODULE · Remote Inspector
-- Data layer (no UI): discovery · registry · traffic · argument parser · statistics · search.
-- It only OBSERVES: passive OnClientEvent connections. Outgoing calls can be fed in with module:Record(...).
-- No hooks, no stealth, no bypass of any kind.
local RemoteData = {}
RemoteData.__index = RemoteData
local REMOTE_CLASSES = { RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true }

local function CaptureArg(v, depth, seen)
    local t = typeof(v)
    if t == "table" then
        if depth > 4 or seen[v] then return "<table>" end
        seen[v] = true
        local out, n = {}, 0
        for k, x in pairs(v) do
            n = n + 1
            if n > 50 then out["…"] = "truncated"; break end
            out[type(k) == "number" and k or tostring(k)] = CaptureArg(x, depth + 1, seen)
        end
        seen[v] = nil
        return out
    elseif t == "Instance" then return "Instance: " .. InstPath(v)       -- never keep Instance references in history
    elseif t == "function" or t == "thread" then return "<" .. t .. ">" end
    return v
end

function RemoteData.new(opts, log)
    return setmetatable({
        Remotes = {}, ById = setmetatable({}, { __mode = "k" }), Traffic = {}, MaxTraffic = opts.MaxTraffic or 500, MaxRemotes = opts.MaxRemotes or 2000,
        Capturing = opts.Capture ~= false, Seq = 0, Total = 0, _conns = {}, _tl = {}, _rl = {}, _n = 0, Log = log,
    }, RemoteData)
end
function RemoteData:OnTraffic(fn) self._tl[#self._tl + 1] = fn end
function RemoteData:OnRemote(fn) self._rl[#self._rl + 1] = fn end
function RemoteData:Register(inst)
    if typeof(inst) ~= "Instance" or not REMOTE_CLASSES[inst.ClassName] or self.ById[inst] or self._n >= self.MaxRemotes then return nil end
    self._n = self._n + 1
    local rec = { Id = self._n, Name = inst.Name, Class = inst.ClassName, Path = InstPath(inst), Calls = 0, Bookmarked = false, Ignored = false, Instance = inst, _recent = {} }
    self.Remotes[#self.Remotes + 1] = rec
    self.ById[inst] = rec
    if inst.ClassName ~= "RemoteFunction" then
        self._conns[#self._conns + 1] = inst.OnClientEvent:Connect(function(...) self:Record(rec, "In", table.pack(...)) end)
    end
    self._conns[#self._conns + 1] = inst.Destroying:Connect(function() rec.Removed, rec.Instance = true, nil end)
    for _, f in ipairs(self._rl) do pcall(f, rec) end
    return rec
end
function RemoteData:Scan(root, token)
    local n = 0
    local ok, list = pcall(function() return root:GetDescendants() end)
    if not ok then return 0 end
    for i, d in ipairs(list) do
        if token and token.Cancelled then break end
        if self:Register(d) then n = n + 1 end
        if i % 250 == 0 then task.wait() end
    end
    return n
end
function RemoteData:Record(rec, dir, args)
    if not (self.Capturing and rec) or rec.Ignored then return nil end
    self.Seq, self.Total, rec.Calls = self.Seq + 1, self.Total + 1, rec.Calls + 1
    rec.LastCall = os.date("%H:%M:%S")
    local now = os.clock()
    rec._recent[#rec._recent + 1] = now
    while #rec._recent > 100 or (rec._recent[1] and now - rec._recent[1] > 10) do table.remove(rec._recent, 1) end
    local n = args.n or #args
    local cap = {}
    for i = 1, math.min(n, 20) do cap[i] = CaptureArg(args[i], 1, {}) end
    local e = { Seq = self.Seq, Clock = rec.LastCall, Remote = rec, Direction = dir, Args = cap, ArgCount = n }
    self.Traffic[#self.Traffic + 1] = e
    if #self.Traffic > self.MaxTraffic then table.remove(self.Traffic, 1) end
    for _, f in ipairs(self._tl) do pcall(f, e) end
    return e
end
function RemoteData:RecordCall(inst, dir, ...)
    local rec = self.ById[inst] or self:Register(inst)
    return self:Record(rec, dir or "Out", table.pack(...))
end
function RemoteData:Rate(rec)
    local now, n = os.clock(), 0
    for _, t in ipairs(rec._recent) do if now - t <= 10 then n = n + 1 end end
    return Round(n / 10, 1)
end
function RemoteData:Find(q) return SearchSvc.Filter(self.Remotes, q, function(r) return r.Name .. " " .. r.Path end, "fuzzy") end
function RemoteData:ClearTraffic() self.Traffic = {} end
function RemoteData.Snippet(e)
    local rec, args = e.Remote, {}
    for i = 1, e.ArgCount do args[#args + 1] = Serialize(e.Args[i], { Pretty = false, Depth = 4 }) end
    local method = rec.Class == "RemoteFunction" and "InvokeServer" or "FireServer"
    return (e.Direction == "In" and "-- received from the server (OnClientEvent)\n" or "") .. "local remote = " .. rec.Path .. "\nremote:" .. method .. "(" .. table.concat(args, ", ") .. ")"
end
function RemoteData:Destroy()
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns, self.Remotes, self.Traffic, self._tl, self._rl = {}, {}, {}, {}, {}
end
RageHub.RemoteData = RemoteData

local RemoteInspector = {
    Name = "RemoteInspector", DisplayName = "Remote Inspector", Version = "1.0.0", Category = "Developer",
    Description = "Passive remote discovery, traffic log, argument viewer, statistics and bookmarks.",
    Dependencies = { "Tables", "Trees", "CodeViewer", "JsonViewer", "Search", "Logger" },
}
function RemoteInspector:Init(ctx)
    local o = ctx.Options
    o.Capture = ctx.Config:Get("Capture", o.Capture)
    o.MaxTraffic = ctx.Config:Get("MaxTraffic", o.MaxTraffic)
    self.Data = RemoteData.new(o, ctx.Logger)
end
function RemoteInspector:Record(remote, direction, ...) if self.Data then return self.Data:RecordCall(remote, direction, ...) end end
function RemoteInspector:Enable(ctx)
    local win, data = ctx.Window, self.Data
    local view = ctx:CreateView("Remote Inspector", "◈")
    self.View = view
    local ctrl = view:CreateSection("Controls")
    local mode = ctrl:CreateSegmented({ Name = "View", Options = { "Remotes", "Traffic", "Stats", "Bookmarks", "Logs" }, Default = "Remotes" })
    ctrl:CreateToggle({ Name = "Capture traffic", Default = data.Capturing, Callback = function(v) data.Capturing = v; ctx.Config:Set("Capture", v) end })
    local main = view:CreateSection("Inspector")
    local COLS = {
        Remotes = { { Key = "Name", Title = "Remote", Width = 0.4 }, { Key = "Class", Title = "Type", Width = 0.24 }, { Key = "Calls", Title = "Calls", Width = 0.14, Align = "Right" }, { Key = "Last", Title = "Last", Width = 0.22 } },
        Traffic = { { Key = "Seq", Title = "#", Width = 0.1, Align = "Right" }, { Key = "Clock", Title = "Time", Width = 0.2 }, { Key = "Dir", Title = "Dir", Width = 0.1 }, { Key = "Name", Title = "Remote", Width = 0.3 }, { Key = "Args", Title = "Arguments" } },
        Stats = { { Key = "Name", Title = "Remote", Width = 0.5 }, { Key = "Calls", Title = "Calls", Width = 0.25, Align = "Right" }, { Key = "Rate", Title = "/sec", Width = 0.25, Align = "Right" } },
        Bookmarks = { { Key = "Name", Title = "Remote", Width = 0.4 }, { Key = "Path", Title = "Path" } },
        Logs = { { Key = "Clock", Title = "Time", Width = 0.2 }, { Key = "Level", Title = "Level", Width = 0.2 }, { Key = "Message", Title = "Message" } },
    }
    local views = {}
    for name, cols in pairs(COLS) do views[name] = main:CreateTable({ Name = name, Height = 240, Columns = cols, EmptyText = name == "Remotes" and "No remotes found yet" or "Nothing here yet" }) end
    local function showView(n) for k, t in pairs(views) do t:SetVisible(k == n) end end
    mode:OnChanged(showView)
    showView("Remotes")

    -- details panel (only exists while the module is enabled)
    local panel, info, json, code, current
    local function show(rec, entry)
        if not panel then return end
        current = { rec = rec, entry = entry }
        info:Set(rec.Name, rec.Class .. "\n" .. rec.Path .. "\nCalls: " .. rec.Calls .. (rec.Removed and "  (removed)" or ""))
        if entry then
            json:Set(entry.Args, "Arguments")
            code:SetCode(RemoteData.Snippet(entry))
        else
            json:Set({}, "Arguments")
            code:SetCode("-- no traffic captured yet for this remote")
        end
        panel:Show()
    end
    if ctx.Options.Details ~= false then
        panel = ctx:CreatePanel({ Name = "Remote Details", Title = "Details", Dock = "Right", Size = 300, Visible = false })
        info = panel:CreateParagraph({ Title = "Select a remote", Content = "" })
        json = panel:CreateJsonViewer({ Name = "Arguments", Height = 170, Value = {} })
        code = panel:CreateCodeViewer({ Name = "Call snippet", Height = 130 })
        panel:CreateButton({ Name = "Copy path", ButtonText = "Copy", Callback = function() if current then ClipSvc.Copy(current.rec.Path) end end })
        panel:CreateToggle({ Name = "Bookmark", Callback = function(v) if current then current.rec.Bookmarked = v; ctx.Window:Notify({ Title = v and "Bookmarked" or "Bookmark removed", Duration = 1.5 }) end end })
        panel:CreateToggle({ Name = "Ignore this remote", Callback = function(v) if current then current.rec.Ignored = v end end })
    end

    -- live wiring
    local trafficIds = {}
    data:OnRemote(function(rec) views.Remotes:AddRow({ Name = rec.Name, Class = rec.Class, Calls = 0, Last = "-", _rec = rec }, rec.Id) end)
    data:OnTraffic(function(e)
        local rec = e.Remote
        views.Remotes:UpdateRow(rec.Id, { Calls = rec.Calls, Last = rec.LastCall })
        local summary = {}
        for i = 1, math.min(e.ArgCount, 4) do summary[#summary + 1] = (Describe(e.Args[i])) end
        local id = views.Traffic:AddRow({ Seq = e.Seq, Clock = e.Clock, Dir = e.Direction, Name = rec.Name, Args = Trunc(table.concat(summary, ", "), 80), _entry = e })
        trafficIds[#trafficIds + 1] = id
        if #trafficIds > data.MaxTraffic then views.Traffic:RemoveRow(table.remove(trafficIds, 1)) end
    end)
    views.Remotes:On("Select", function(list) local r = list[1]; if r and r.Data._rec then show(r.Data._rec, nil) end end)
    views.Traffic:On("Select", function(list) local r = list[1]; if r and r.Data._entry then show(r.Data._entry.Remote, r.Data._entry) end end)
    views.Stats:On("Select", function() end)

    local roots = ctx.Options.Roots
    if not roots then
        roots = {}
        local ok, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
        if ok and rs then roots[1] = rs end
    end
    local function scan()
        ctx.Tasks:Create("scan"):Start(function(token)
            local total = 0
            for _, r in ipairs(roots) do total = total + data:Scan(r, token) end
            ctx.Logger:Info("Found " .. total .. " remotes (" .. #data.Remotes .. " total)")
        end)
    end
    scan()
    for _, r in ipairs(roots) do ctx.Cleanup:Add(r.DescendantAdded:Connect(function(d) data:Register(d) end)) end
    ctrl:CreateButton({ Name = "Rescan remotes", ButtonText = "Scan", Callback = scan })
    ctrl:CreateButton({ Name = "Clear traffic", ButtonText = "Clear", Callback = function() data:ClearTraffic(); views.Traffic:Clear(); trafficIds = {} end })
    ctx.Tasks:Every(1, function()
        if mode:Get() == "Stats" then
            for _, rec in ipairs(data.Remotes) do
                if rec.Calls > 0 then
                    local row = { Name = rec.Name, Calls = rec.Calls, Rate = data:Rate(rec) }
                    if not views.Stats:UpdateRow(rec.Id, row) then views.Stats:AddRow(row, rec.Id) end
                end
            end
        elseif mode:Get() == "Bookmarks" then
            views.Bookmarks:SetRows({})
            for _, rec in ipairs(data.Remotes) do if rec.Bookmarked then views.Bookmarks:AddRow({ Name = rec.Name, Path = rec.Path }, rec.Id) end end
        end
    end, "stats")
    for _, e in ipairs(win.Logger:Get({ Module = "RemoteInspector" })) do views.Logs:AddRow({ Clock = e.Clock, Level = e.Level, Message = e.Message }) end
    ctx.Cleanup:Add(win.Logger:Subscribe(function(e) if e.Module == "RemoteInspector" then views.Logs:AddRow({ Clock = e.Clock, Level = e.Level, Message = e.Message }) end end))
    ctx:RegisterCommand({ Name = "Open Remote Inspector", Callback = function() if view.Select then view:Select() end win:Show() end })
    ctx:RegisterCommand({ Name = "Clear Remote Traffic", Callback = function() data:ClearTraffic(); views.Traffic:Clear() end })
    ctx:AddSettings(function(sec)
        sec:CreateSlider({ Name = "Max traffic entries", Range = { 100, 2000 }, Increment = 100, Default = data.MaxTraffic, Callback = function(v) data.MaxTraffic = v; ctx.Config:Set("MaxTraffic", v) end })
    end)
end
function RemoteInspector:Disable(ctx) if self.Data then self.Data:Destroy(); self.Data = nil end end

------------------------------------------------------------------ BUILT-IN MODULE · Instance Explorer
local ExplorerIcons = { Folder = "▸", Model = "◇", Part = "▫", MeshPart = "▫", Script = "≡", LocalScript = "≡", ModuleScript = "≡", RemoteEvent = "⚡", RemoteFunction = "⚡", Humanoid = "☺" }
local SAFE_PROPS = {
    BasePart = { "Position", "Size", "Anchored", "CanCollide", "Transparency" }, Humanoid = { "Health", "MaxHealth", "WalkSpeed" },
    ValueBase = { "Value" }, GuiObject = { "Visible", "AbsoluteSize" }, Model = { "PrimaryPart" }, Sound = { "Playing", "Volume" },
}
local InstanceExplorer = {
    Name = "InstanceExplorer", DisplayName = "Instance Explorer", Version = "1.0.0", Category = "Developer",
    Description = "Lazy hierarchy tree with search, safe property inspection and copy path.", Dependencies = { "Trees", "JsonViewer", "Search" },
}
function InstanceExplorer:Enable(ctx)
    local win = ctx.Window
    local view = ctx:CreateView("Explorer", "▤")
    local function kids(inst)
        local ok, list = pcall(function() return inst:GetChildren() end)
        if not ok then return {} end
        table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
        return list
    end
    local function nodeFor(inst)
        local n = #kids(inst)
        return { Text = inst.Name, Detail = inst.ClassName, Icon = ExplorerIcons[inst.ClassName] or "·", Data = inst, Lazy = n > 0, Leaf = n == 0 }
    end
    local panel, json, selected
    local function describe(inst)
        local d = { Name = inst.Name, ClassName = inst.ClassName, Parent = inst.Parent and inst.Parent.Name or "nil", FullName = InstPath(inst), Properties = {}, Attributes = {} }
        for cls, props in pairs(SAFE_PROPS) do
            local isA = false
            pcall(function() isA = inst:IsA(cls) end)
            if isA then for _, p in ipairs(props) do pcall(function() d.Properties[p] = inst[p] end) end end
        end
        pcall(function() d.Attributes = inst:GetAttributes() end)
        d.Children = #kids(inst)
        return d
    end
    local tree
    local max = ctx.Options.MaxChildren or 300
    tree = view:CreateTree({
        Name = "Instances", Height = ctx.Options.Height or 280, Search = true,
        LoadChildren = function(node)
            local out, list = {}, kids(node.Data)
            for i, k in ipairs(list) do
                if i > max then out[#out + 1] = { Text = "… " .. (#list - max) .. " more", Leaf = true, Color = win.Theme.TextMuted }; break end
                out[#out + 1] = nodeFor(k)
            end
            return out
        end,
        OnSelect = function(node)
            selected = node
            if json and typeof(node.Data) == "Instance" then json:Set(describe(node.Data), node.Text); panel:Show() end
        end,
        ContextMenu = function(node)
            return { { Text = "Copy path", Callback = function() if typeof(node.Data) == "Instance" then ClipSvc.Copy(InstPath(node.Data)) end end },
                     { Text = "Refresh", Callback = function() tree:SetChildren(node.Id, {}); node.Loaded, node.Lazy = false, true; tree:Expand(node.Id) end } }
        end,
    })
    local roots = {}
    for _, svcName in ipairs(ctx.Options.Services or { "Workspace", "ReplicatedStorage", "Players", "Lighting", "ReplicatedFirst", "StarterGui", "StarterPack", "SoundService" }) do
        local ok, s = pcall(function() return game:GetService(svcName) end)
        if ok and s then roots[#roots + 1] = nodeFor(s) end
    end
    tree:SetRoots(roots)
    self.Tree, self.View = tree, view
    if ctx.Options.Details ~= false then
        panel = ctx:CreatePanel({ Name = "Instance Details", Title = "Instance", Dock = "Right", Size = 280, Visible = false })
        json = panel:CreateJsonViewer({ Name = "Properties", Height = 220, Value = {} })
        panel:CreateButton({ Name = "Copy path", ButtonText = "Copy", Callback = function() if selected and typeof(selected.Data) == "Instance" then ClipSvc.Copy(InstPath(selected.Data)) end end })
        panel:CreateButton({ Name = "Select parent", ButtonText = "Parent", Callback = function()
            if selected and selected.Parent then tree:Select(selected.Parent.Id) end
        end })
    end
    local deepRes, deepQ = nil, ""
    view:CreateInput({ Name = "Deep search", Placeholder = "name contains...", Width = 150, Callback = function(t) deepQ = t:lower() end })
    view:CreateButton({
        Name = "Scan selection", Description = "Scans up to " .. (ctx.Options.MaxScan or 5000) .. " descendants", ButtonText = "Scan",
        Callback = function()
            local root = (selected and typeof(selected.Data) == "Instance") and selected.Data or game
            ctx.Tasks:Create("deep"):Start(function(token)
                local list = {}
                pcall(function() list = root:GetDescendants() end)
                if deepRes then tree:RemoveNode(deepRes) end
                deepRes = tree:AddNode(nil, { Text = "Search results", Icon = "⌕", Children = {} })
                local n = 0
                for i, d in ipairs(list) do
                    if token.Cancelled or i > (ctx.Options.MaxScan or 5000) or n >= 200 then break end
                    if deepQ ~= "" and d.Name:lower():find(deepQ, 1, true) then n = n + 1; tree:AddNode(deepRes, nodeFor(d)) end
                    if i % 200 == 0 then task.wait() end
                end
                ctx.Logger:Info("Deep search added " .. n .. " nodes under '" .. root.Name .. "'")
            end)
        end,
    })
    ctx:RegisterCommand({ Name = "Open Instance Explorer", Callback = function() if view.Select then view:Select() end win:Show() end })
end

------------------------------------------------------------------ BUILT-IN MODULE · Player Monitor
local PlayerMonitor = {
    Name = "PlayerMonitor", DisplayName = "Player Monitor", Version = "1.0.0", Category = "Monitoring",
    Description = "Live player list: names, ids, team, character status and distance.", Dependencies = { "Tables", "Search" },
}
function PlayerMonitor:Enable(ctx)
    local win = ctx.Window
    local view = ctx:CreateView("Players", "◉")
    self.View = view
    local count = view:CreateStat({ Name = "Players online", Value = 0 })
    local tbl = view:CreateTable({
        Name = "Players", Height = ctx.Options.Height or 260,
        Columns = { { Key = "Display", Title = "Display", Width = 0.24 }, { Key = "User", Title = "Username", Width = 0.24 }, { Key = "Id", Title = "UserId", Width = 0.2, Align = "Right" },
            { Key = "Team", Title = "Team", Width = 0.14 }, { Key = "Status", Title = "Status", Width = 0.1 }, { Key = "Dist", Title = "Dist", Width = 0.08, Align = "Right" } },
        ContextMenu = function(row) return {
            { Text = "Copy username", Callback = function() ClipSvc.Copy(row.User) end },
            { Text = "Copy UserId", Callback = function() ClipSvc.Copy(tostring(row.Id)) end },
        } end,
    })
    self.Table = tbl
    local function live(p)
        local status, dist = "None", ""
        local char = p.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            status = (hum and hum.Health > 0) and "Alive" or "Dead"
            local me = Players.LocalPlayer and Players.LocalPlayer.Character
            local a, b = char:FindFirstChild("HumanoidRootPart"), me and me:FindFirstChild("HumanoidRootPart")
            if a and b then dist = Round((a.Position - b.Position).Magnitude) end
        end
        return { Display = p.DisplayName or p.Name, User = p.Name, Id = p.UserId, Team = p.Team and p.Team.Name or "-", Status = status, Dist = dist }
    end
    local function add(p) if not tbl:UpdateRow(p.UserId, live(p)) then tbl:AddRow(live(p), p.UserId) end end
    for _, p in ipairs(Players:GetPlayers()) do add(p) end
    ctx.Cleanup:Add(Players.PlayerAdded:Connect(add))
    ctx.Cleanup:Add(Players.PlayerRemoving:Connect(function(p) tbl:RemoveRow(p.UserId) end))
    ctx.Tasks:Every(ctx.Options.Interval or 1, function()
        local list = Players:GetPlayers()
        for _, p in ipairs(list) do tbl:UpdateRow(p.UserId, live(p)) end
        count:Set(#list)
    end, "poll")
    count:Set(#Players:GetPlayers())
    ctx:RegisterCommand({ Name = "Open Player Monitor", Callback = function() if view.Select then view:Select() end win:Show() end })
end

------------------------------------------------------------------ BUILT-IN MODULE · Performance
local Performance = {
    Name = "Performance", DisplayName = "Performance Monitor", Version = "1.0.0", Category = "Monitoring",
    Description = "FPS, ping, memory and framework counters. Sampling only runs while enabled.", Dependencies = { "Diagnostics" },
}
function Performance:Enable(ctx)
    local win = ctx.Window
    local view = ctx:CreateView("Performance", "◔")
    local fpsS, pingS, memS = view:CreateStat({ Name = "FPS", Value = 0 }), view:CreateStat({ Name = "Ping", Value = 0, Suffix = " ms" }), view:CreateStat({ Name = "Memory", Value = 0, Suffix = " MB" })
    local fpsM = view:CreateMeter({ Name = "Frame budget", Max = 120, Default = 0, Suffix = " fps", Invert = true, Thresholds = { Warning = 0.5, Danger = 0.75 } })
    local sec = view:CreateSection("Framework")
    local workersS, connS, rowsS, uiS = sec:CreateStat({ Name = "Active workers", Value = 0 }), sec:CreateStat({ Name = "Event handlers", Value = 0 }), sec:CreateStat({ Name = "Rendered rows", Value = 0 }), sec:CreateStat({ Name = "Cleanup items", Value = 0 })
    local spikes = view:CreateTimeline({ Name = "Frame spikes", Height = 120, MaxItems = 40 })
    local frames, last, fps = 0, os.clock(), 60
    ctx.Cleanup:Add(RunService.Heartbeat:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last >= 0.5 then
            fps = Round(frames / (now - last))
            if fps < (ctx.Options.SpikeFps or 25) then spikes:Add("FPS dropped to " .. fps, "warning", os.date("%H:%M:%S")) end
            frames, last = 0, now
        end
    end))
    ctx.Tasks:Every(ctx.Options.Interval or 0.5, function()
        fpsS:Set(fps)
        fpsM:Set(fps)
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingS:Set(ok and Round(ping) or "-")
        local okm, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
        memS:Set(okm and Round(mem) or "-")
        local d = win:GetDiagnostics()
        workersS:Set(d.Workers); connS:Set(d.EventHandlers); rowsS:Set(d.RenderedRows); uiS:Set(d.CleanupItems)
    end, "sample")
    ctx:RegisterCommand({ Name = "Open Performance Monitor", Callback = function() if view.Select then view:Select() end win:Show() end })
end

------------------------------------------------------------------ BUILT-IN MODULE · Console (developer console / event logger)
local Console = {
    Name = "Console", DisplayName = "Developer Console", Version = "1.0.0", Category = "Developer",
    Description = "Live, filterable, searchable log console with pause, copy and export.", Dependencies = { "Tables", "Logger", "Search" },
}
function Console:Enable(ctx)
    local win = ctx.Window
    local view = ctx:CreateView("Console", "▶")
    local ctrl = view:CreateSection("Filters")
    local filter, paused, ids = { Level = nil, Module = "All", Search = "" }, false, {}
    local tbl
    local MAXR = ctx.Options.MaxRows or 500
    local function row(e) return { Clock = e.Clock, Level = e.Level, Module = e.Module, Message = Trunc((e.Message:gsub("\n", " ")), 160), _e = e } end
    local function reload()
        tbl:SetRows({})
        ids = {}
        local list = win.Logger:Get(filter)
        for i = math.max(1, #list - MAXR + 1), #list do ids[#ids + 1] = tbl:AddRow(row(list[i])) end
    end
    local level = ctrl:CreateDropdown({ Name = "Level", Options = { "All", "Debug", "Info", "Success", "Warning", "Error" }, Default = "All", Callback = function(v) filter.Level = (v ~= "All") and v or nil; reload() end })
    local modDD = ctrl:CreateDropdown({ Name = "Module", Options = { "All" }, Default = "All", Callback = function(v) filter.Module = v; reload() end })
    ctrl:CreateSearchBox({ Name = "Search logs", Placeholder = "Search logs...", Callback = function(t) filter.Search = t; reload() end })
    ctrl:CreateToggle({ Name = "Pause", Callback = function(v) paused = v; if not v then reload() end end })
    ctrl:CreateButton({ Name = "Clear", ButtonText = "Clear", Callback = function() win.Logger:Clear(); reload() end })
    ctrl:CreateButton({ Name = "Copy all", ButtonText = "Copy", Callback = function() local ok = ClipSvc.Copy(win.Logger:Export()); win:Notify({ Title = ok and "Logs copied" or "Copy not supported", Type = ok and "success" or "warning", Duration = 2 }) end })
    ctrl:CreateButton({
        Name = "Export to file", ButtonText = "Export",
        Callback = function()
            if not Caps().FileSystem then win:Notify({ Title = "Export unavailable", Content = "No file system access.", Type = "warning" }) return end
            local ok = pcall(function() win:_ensureFolder(); writefile(win.ConfigFolder .. "/logs.txt", win.Logger:Export()) end)
            win:Notify({ Title = ok and "Logs exported" or "Export failed", Content = win.ConfigFolder .. "/logs.txt", Type = ok and "success" or "error" })
        end,
    })
    local main = view:CreateSection("Output")
    self.View = view
    tbl = main:CreateTable({
        Name = "Logs", Height = ctx.Options.Height or 280, EmptyText = "No log entries",
        Columns = { { Key = "Clock", Title = "Time", Width = 0.14 }, { Key = "Level", Title = "Level", Width = 0.13 }, { Key = "Module", Title = "Module", Width = 0.19 }, { Key = "Message", Title = "Message" } },
        ContextMenu = function(r) return { { Text = "Copy line", Callback = function() ClipSvc.Copy(win.Logger:Format(r._e)) end } } end,
    })
    self.Table = tbl
    local known = {}
    ctx.Cleanup:Add(win.Logger:Subscribe(function(e)
        if not known[e.Module] then known[e.Module] = true; modDD:Refresh(Copy({ "All", table.unpack(win.Logger:Modules()) }), true) end
        if paused then return end
        if filter.Level and LEVELS[e.Level] < LEVELS[filter.Level] then return end
        if filter.Module ~= "All" and e.Module ~= filter.Module then return end
        if filter.Search ~= "" and not e.Message:lower():find(filter.Search:lower(), 1, true) then return end
        ids[#ids + 1] = tbl:AddRow(row(e))
        if #ids > MAXR then tbl:RemoveRow(table.remove(ids, 1)) end
    end))
    if ctx.Options.CaptureOutput and LogService then
        ctx.Cleanup:Add(LogService.MessageOut:Connect(function(msg, kind)
            local lv = (kind == Enum.MessageType.MessageError and "Error") or (kind == Enum.MessageType.MessageWarning and "Warning") or "Info"
            win.Logger:Log(lv, "Output", msg)
        end))
    end
    for _, m in ipairs(win.Logger:Modules()) do known[m] = true end
    modDD:Refresh(Copy({ "All", table.unpack(win.Logger:Modules()) }), true)
    reload()
    ctx:RegisterCommand({ Name = "Open Developer Console", Callback = function() if view.Select then view:Select() end win:Show() end })
end

RageHub:RegisterModule(RemoteInspector, true)
RageHub:RegisterModule(InstanceExplorer, true)
RageHub:RegisterModule(PlayerMonitor, true)
RageHub:RegisterModule(Performance, true)
RageHub:RegisterModule(Console, true)

------------------------------------------------------------------ DIAGNOSTICS (optional, low overhead)
function Window:GetDiagnostics()
    local rendered, vlists = 0, 0
    for vl in pairs(self._vlists or {}) do rendered = rendered + (vl.Rendered or 0); vlists = vlists + 1 end
    local elements = 0
    for _ in pairs(self.ElementsById) do elements = elements + 1 end
    local states = {}
    for _, m in ipairs(self:GetModules()) do states[m.Name] = m.State end
    return {
        Window = self.Id, Visible = self.Visible, Minimized = self.Minimized, Maximized = self.Maximized, Breakpoint = self.Breakpoint, Theme = self.ThemeName,
        Tabs = #self.Tabs, Panels = #self.Panels, Elements = elements, Modules = self:GetEnabledModules(), ModuleStates = states,
        EventHandlers = self.Events:Count() + self.State:WatcherCount(), Workers = self.Tasks:Count(), CleanupItems = self.Cleanup:Count(),
        InputBinds = self.Input:Count(), RenderedRows = rendered, VirtualLists = vlists, LogEntries = self.Logger:Count(),
        CallbackErrors = self.CallbackErrors or 0, Notifications = #self._nActive, QueuedNotifications = #self._nQueue, Dialogs = #self._dialogs,
        Commands = #self:GetCommands(), AutoSave = self.AutoSaveName, ConfigFolder = self.ConfigFolder, Destroyed = self._destroyed == true,
    }
end

-- self-diagnostics: duplicate windows, failed modules, broken callbacks, stale workers
function Window:Diagnose()
    local issues = {}
    local function add(sev, msg) issues[#issues + 1] = { Severity = sev, Message = msg } end
    for name, st in pairs(self._modState) do if st == "Failed" then add("error", "module '" .. name .. "' failed: " .. tostring(self._modErr and self._modErr[name])) end end
    if (self.CallbackErrors or 0) > 0 then add("warning", (self.CallbackErrors) .. " callback error(s) were caught; see the Logger") end
    if self.Tasks:Count() > 25 then add("warning", "many active workers (" .. self.Tasks:Count() .. ")") end
    for name, inst in pairs(self.ModuleInstances) do
        if inst.State == "Enabled" and inst.Context == nil then add("error", "module '" .. name .. "' is enabled but has no context") end
    end
    if self.Logger:Count() >= self.Logger._max then add("info", "log buffer is full (oldest entries are being discarded)") end
    return issues
end

RageHub.Diagnostics = {}
function RageHub.Diagnostics:GetReport()
    local windows, count = {}, 0
    for id, w in pairs(G.Windows) do windows[id] = w:GetDiagnostics(); count = count + 1 end
    local mods = 0
    for _ in pairs(G.Modules) do mods = mods + 1 end
    return {
        Version = RageHub.Version, Windows = windows, WindowCount = count, RegisteredModules = mods, Themes = #RageHub:GetThemes(),
        Assets = Assets:Stats(), Warnings = G.Warnings or 0, Capabilities = Caps(), ElementsCreated = G.ElementCount,
    }
end
function RageHub.Diagnostics:Check()
    local all = {}
    for id, w in pairs(G.Windows) do for _, i in ipairs(w:Diagnose()) do i.Window = id; all[#all + 1] = i end end
    return all
end

------------------------------------------------------------------ PUBLIC API
function RageHub:GetCapabilities() return Caps() end
function RageHub:GetVersion() return RageHub.Version end
-- Theme registry (global); windows can still override their own theme with Window:SetTheme
function RageHub:AddTheme(name, tbl)
    if type(name) ~= "string" or name == "" or type(tbl) ~= "table" then Warn("AddTheme", "expected (name: string, theme: table)"); return false end
    Themes[name] = NormalizeTheme(tbl, name)
    return true
end
function RageHub:GetThemes()
    local list = {}
    for k in pairs(Themes) do list[#list + 1] = k end
    table.sort(list)
    return list
end
function RageHub:GetTheme() return G.DefaultTheme end
function RageHub:SetTheme(name)
    if not Themes[name] then Warn("RageHub:SetTheme", "unknown theme '" .. tostring(name) .. "'"); return false end
    G.DefaultTheme = name
    for _, w in pairs(G.Windows) do w:SetTheme(name) end
    return true
end
function RageHub:SetAccent(c1, c2) for _, w in pairs(G.Windows) do w:SetAccent(c1, c2) end return true end

RageHub.Debug = { Enable = function(_, v) for _, w in pairs(G.Windows) do w.DebugMode = v ~= false; w.Logger.DebugMode = v ~= false end end }
G.API = RageHub
return RageHub
