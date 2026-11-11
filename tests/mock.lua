-- Minimal Roblox mock so RageHub can be executed under plain Luau for smoke testing.
local M = {}
M.ALL = {}
M.clock = 0
M.delayed = {}
M.errors = {}

local function newSignal()
    local s = { _h = {} }
    function s:Connect(fn)
        local c = { Connected = true }
        local h = { fn = fn, c = c }
        table.insert(self._h, h)
        function c:Disconnect() c.Connected = false; for i, x in ipairs(s._h) do if x == h then table.remove(s._h, i) break end end end
        return c
    end
    function s:Once(fn) return self:Connect(fn) end
    function s:Wait() return end
    function s:Fire(...)
        for _, h in ipairs({ table.unpack(self._h) }) do
            local ok, err = pcall(h.fn, ...)
            if not ok then table.insert(M.errors, tostring(err)) end
        end
    end
    return s
end
M.newSignal = newSignal

local V3MT = {}
V3MT.__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X*t.X + t.Y*t.Y + (t.Z or 0)^2) end end
V3MT.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = 0 }, V3MT) end
V3MT.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = 0 }, V3MT) end
V3MT.__mul = function(a, b) if type(b) == "number" then return setmetatable({ X = a.X*b, Y = a.Y*b, Z = 0 }, V3MT) end return a end
V3MT.__div = function(a, b) if type(b) == "number" then return setmetatable({ X = a.X/b, Y = a.Y/b, Z = 0 }, V3MT) end return a end
V3MT.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
local function V(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3MT) end
Vector2 = { new = V }
Vector3 = { new = V }

UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
local function U2(xs, xo, ys, yo) return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo }, __type = "UDim2" } end
UDim2 = { new = U2, fromOffset = function(x, y) return U2(0, x, 0, y) end, fromScale = function(x, y) return U2(x, 0, y, 0) end }

local function hsv2rgb(h, s, v)
    local i = math.floor(h * 6); local f = h * 6 - i
    local p, q, t = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
    i = i % 6
    if i == 0 then return v,t,p elseif i == 1 then return q,v,p elseif i == 2 then return p,v,t
    elseif i == 3 then return p,q,v elseif i == 4 then return t,p,v else return v,p,q end
end
local C3 = {}
C3.__index = function(t, k)
    if k == "ToHSV" then return function(self)
        local r, g, b = self.R, self.G, self.B
        local mx, mn = math.max(r, g, b), math.min(r, g, b)
        local d = mx - mn
        local h = 0
        if d > 0 then
            if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
            h = h / 6
        end
        return h, (mx == 0) and 0 or d / mx, mx
    end end
    if k == "ToHex" then return function(self) return string.format("%02X%02X%02X", self.R*255, self.G*255, self.B*255) end end
end
local function mkC(r, g, b, h, s, v) return setmetatable({ R = r, G = g, B = b, _h = h, _s = s, _v = v, __type = "Color3" }, C3) end
Color3 = {
    new = function(r, g, b) return mkC(r or 0, g or 0, b or 0) end,
    fromRGB = function(r, g, b) return mkC((r or 0)/255, (g or 0)/255, (b or 0)/255) end,
    fromHSV = function(h, s, v) local r, g, b = hsv2rgb(h, s, v); return mkC(r, g, b, h, s, v) end,
}
ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
ColorSequence = { new = function(a, b) return { a, b, __type = "ColorSequence" } end }
NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
NumberSequence = { new = function(a, b) return { a, b, __type = "NumberSequence" } end }
TweenInfo = { new = function(...) return { ... } end }

local EnumMT = {}
EnumMT.__index = function(t, k)
    local v = setmetatable({ Name = k, __enum = true }, { __tostring = function() return "Enum." .. k end })
    rawset(t, k, v); return v
end
Enum = setmetatable({}, { __index = function(t, k) local e = setmetatable({}, EnumMT); rawset(t, k, e); return e end })
local rawtypeof = type
typeof = function(v)
    if rawtypeof(v) == "table" then
        if rawget(v, "__enum") then return "EnumItem" end
        local t = rawget(v, "__type"); if t then return t end
        if getmetatable(v) == C3 then return "Color3" end
    end
    return rawtypeof(v)
end

-- Instances
local Methods, SignalNames = {}, {}
for _, n in ipairs({ "MouseEnter","MouseLeave","MouseMoved","InputBegan","InputEnded","InputChanged","Activated","FocusLost","Focused",
    "Changed","Completed","PlayerAdded","PlayerRemoving","RenderStepped","Heartbeat","Destroying","ChildAdded","MouseButton1Click" }) do SignalNames[n] = true end

local function unlink(inst)
    local p = inst._p.Parent
    if p and p._children then for i, c in ipairs(p._children) do if c == inst then table.remove(p._children, i) break end end end
end
function Methods.Destroy(self)
    unlink(self); self._destroyed = true; self._p.Parent = nil
    for _, c in ipairs({ table.unpack(self._children) }) do c:Destroy() end
end
function Methods.GetChildren(self) return { table.unpack(self._children) } end
function Methods.GetDescendants(self)
    local out = {}
    local function walk(n) for _, c in ipairs(n._children) do table.insert(out, c); walk(c) end end
    walk(self); return out
end
function Methods.FindFirstChildOfClass(self, cls) for _, c in ipairs(self._children) do if c._class == cls then return c end end end
function Methods.FindFirstChild(self, name) for _, c in ipairs(self._children) do if c._p.Name == name then return c end end end
function Methods.WaitForChild(self, name) return Methods.FindFirstChild(self, name) or M.new("Folder", { Name = name }) end
function Methods.IsDescendantOf(self, anc) local p = self._p.Parent; while p do if p == anc then return true end p = p._p.Parent end return false end
function Methods.SetAttribute(self, k, v) self._attrs[k] = v end
function Methods.GetAttribute(self, k) return self._attrs[k] end
function Methods.GetPropertyChangedSignal(self, name) local k = "prop:" .. name; if not self._sigs[k] then self._sigs[k] = newSignal() end return self._sigs[k] end
function Methods.IsA(self, c) return self._class == c end
function Methods.CaptureFocus() end
function Methods.Play() end

local Defaults = {
    AbsolutePosition = function() return V(100, 100) end,
    AbsoluteSize = function() return V(300, 40) end,
    Text = function() return "" end, Visible = function() return true end,
    CanvasPosition = function() return V(0, 0) end,
}
local InstMT = {}
InstMT.__index = function(t, k)
    local p = rawget(t, "_p"); local v = p[k]
    if v ~= nil then return v end
    if Methods[k] then return Methods[k] end
    if SignalNames[k] then local s = newSignal(); t._sigs[k] = s; p[k] = s; return s end
    local d = Defaults[k]; if d then return d() end
    return nil
end
InstMT.__newindex = function(t, k, v)
    if k == "Parent" then
        unlink(t); t._p.Parent = v
        if v and v._children then table.insert(v._children, t) end
    else t._p[k] = v end
end
function M.new(class, props)
    local inst = setmetatable({ _p = {}, _children = {}, _sigs = {}, _attrs = {}, _class = class }, InstMT)
    inst._p.ClassName = class
    for k, v in pairs(props or {}) do inst._p[k] = v end
    table.insert(M.ALL, inst)
    return inst
end
Instance = { new = function(class) return M.new(class) end }

-- Services
local services = {}
local function svc(name, extra)
    local s = M.new("Service", { Name = name })
    for k, v in pairs(extra or {}) do s._p[k] = v end
    services[name] = s; return s
end
local lp = { Name = "Tester", DisplayName = "Tester", UserId = 1 }
local players = svc("Players", { LocalPlayer = lp, GetUserThumbnailAsync = function() return "rbxthumb://x" end, GetPlayers = function() return { lp, { Name = "Alice" }, { Name = "Bob" } } end })
function players.GetPlayers() return { lp, { Name = "Alice" }, { Name = "Bob" } } end
players._p.GetPlayers = players.GetPlayers
svc("TweenService", { Create = function(_, inst, info, props)
    local tw = { Completed = newSignal() }
    function tw:Play() for k, v in pairs(props) do inst[k] = v end end
    function tw:Cancel() end
    return tw end })
local uis = svc("UserInputService", { TouchEnabled = false, GetMouseLocation = function() return V(200, 200) end })
svc("HttpService", {})
svc("RunService", {})
svc("GuiService", { GetGuiInset = function() return V(0, 36) end })
svc("CoreGui", {})
local cam = M.new("Camera", { ViewportSize = V(1280, 720) })
svc("Workspace", { CurrentCamera = cam })
local stat = { Network = { ServerStatsItem = { ["Data Ping"] = { GetValue = function() return 42 end } } } }
svc("Stats", stat)
M.uis = uis
game = { GetService = function(_, n) return services[n] end }

-- JSON (tiny)
local function enc(v)
    local t = type(v)
    if t == "table" then
        if #v > 0 or next(v) == nil then local a = {}; for _, x in ipairs(v) do a[#a+1] = enc(x) end; return "[" .. table.concat(a, ",") .. "]" end
        local a = {}; for k, x in pairs(v) do a[#a+1] = string.format("%q:%s", tostring(k), enc(x)) end; return "{" .. table.concat(a, ",") .. "}"
    elseif t == "string" then return string.format("%q", v) elseif t == "number" or t == "boolean" then return tostring(v) end
    return "null"
end
local function dec(s)
    local pos = 1
    local function ws() pos = s:find("%S", pos) or #s + 1 end
    local val
    function val()
        ws(); local c = s:sub(pos, pos)
        if c == "{" then
            pos += 1; local o = {}; ws()
            if s:sub(pos, pos) == "}" then pos += 1 return o end
            while true do
                ws(); local k = val(); ws(); pos += 1; o[k] = val(); ws()
                local d = s:sub(pos, pos); pos += 1
                if d == "}" then break end
            end
            return o
        elseif c == "[" then
            pos += 1; local a = {}; ws()
            if s:sub(pos, pos) == "]" then pos += 1 return a end
            while true do
                a[#a+1] = val(); ws(); local d = s:sub(pos, pos); pos += 1
                if d == "]" then break end
            end
            return a
        elseif c == '"' then
            local e = pos + 1
            while s:sub(e, e) ~= '"' do if s:sub(e, e) == "\\" then e += 1 end e += 1 end
            local str = s:sub(pos + 1, e - 1); pos = e + 1; return (str:gsub('\\"', '"'))
        elseif s:sub(pos, pos + 3) == "true" then pos += 4 return true
        elseif s:sub(pos, pos + 4) == "false" then pos += 5 return false
        elseif s:sub(pos, pos + 3) == "null" then pos += 4 return nil
        else local n = s:match("^-?[%d%.eE+-]+", pos); pos += #n; return tonumber(n) end
    end
    return val()
end
services.HttpService._p.JSONEncode = function(_, v) return enc(v) end
services.HttpService._p.JSONDecode = function(_, s) return dec(s) end
services.HttpService._p.GenerateGUID = function() return "GUID-" .. math.random(1e6) end

-- file system
local files, folders = {}, {}
writefile = function(p, c) files[p] = c end
readfile = function(p) return files[p] end
isfile = function(p) return files[p] ~= nil end
isfolder = function(p) return folders[p] == true end
makefolder = function(p) folders[p] = true end
delfile = function(p) files[p] = nil end
listfiles = function(f) local o = {}; for p in pairs(files) do if p:sub(1, #f) == f then o[#o+1] = p end end return o end
local clipboard
setclipboard = function(t) clipboard = t end
M.getClipboard = function() return clipboard end
M.files = files

-- task
local function run() 
    table.sort(M.delayed, function(a, b) return a.t < b.t end)
    while M.delayed[1] and M.delayed[1].t <= M.clock do
        local d = table.remove(M.delayed, 1)
        local ok, err = pcall(d.fn); if not ok then table.insert(M.errors, "task.delay: " .. tostring(err)) end
    end
end
M.onWait = nil
task = {
    spawn = function(fn, ...) local ok, err = pcall(fn, ...); if not ok then table.insert(M.errors, "task.spawn: " .. tostring(err)) end end,
    defer = function(fn, ...) local ok, err = pcall(fn, ...); if not ok then table.insert(M.errors, "task.defer: " .. tostring(err)) end end,
    delay = function(t, fn) local d = { t = M.clock + t, fn = fn }; table.insert(M.delayed, d); return d end,
    cancel = function(d) for i, x in ipairs(M.delayed) do if x == d then table.remove(M.delayed, i) break end end end,
    wait = function(t)
        M.waits = (M.waits or 0) + 1
        if M.waits > 300 then error("mock wait budget exhausted (endless loop guard)", 0) end
        M.clock += (t or 0.03); if M.onWait then M.onWait() end run(); return t or 0.03
    end,
}
M.advance = function(t) M.clock += t; run() end
warn = function(...) table.insert(M.errors, "warn: " .. table.concat({ ... }, " ")) end

-- fake input object
function M.input(utype, state, pos)
    local i = { UserInputType = Enum.UserInputType[utype], UserInputState = Enum.UserInputState[state or "Begin"], Position = pos or V(150, 120), Changed = newSignal(), KeyCode = Enum.KeyCode.Unknown }
    return i
end
function M.key(name, state) 
    local i = M.input("Keyboard", state or "Begin"); i.KeyCode = Enum.KeyCode[name]; return i
end

-- fuzz: fire every signal handler on every live instance
function M.fuzz()
    local fired = 0
    for _, inst in ipairs({ table.unpack(M.ALL) }) do
        if not inst._destroyed then
            for name, sig in pairs(inst._sigs) do
                for _, h in ipairs({ table.unpack(sig._h) }) do
                    local args
                    if name == "InputBegan" or name == "InputChanged" or name == "InputEnded" then
                        args = { M.input("MouseButton1", "Begin") }
                    elseif name == "MouseMoved" then args = { 100, 100 }
                    elseif name == "FocusLost" then args = { true }
                    else args = {} end
                    fired += 1
                    local ok, err = pcall(h.fn, table.unpack(args))
                    if not ok then table.insert(M.errors, string.format("[%s.%s] %s", inst._class, name, tostring(err))) end
                end
            end
        end
    end
    return fired
end
local ENV = {}
getgenv = function() return ENV end
return M
