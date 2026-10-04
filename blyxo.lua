-- BlyxoHub | Ride A Pet
-- Version 1.0.0  |  build 4fd47f60  |  9e892c9  |  2026-09-18 09:15 UTC
--
-- GENERATED FILE - DO NOT EDIT.
-- Edit the modules in src/ and run: python tools/build.py
--
-- Modules in load order:
--   boot/00_runtime.lua                  141 lines
--   boot/01_log.lua                      174 lines
--   boot/02_scope.lua                    173 lines
--   boot/03_profile.lua                  249 lines
--   core/services.lua                     34 lines
--   core/net.lua                          77 lines
--   core/scan.lua                         56 lines
--   core/exec.lua                        355 lines
--   core/device.lua                      122 lines
--   core/character.lua                    84 lines
--   core/config.lua                       31 lines
--   core/state.lua                        14 lines
--   core/util.lua                         29 lines
--   core/profiles.lua                    418 lines
--   ui/lib/theme.lua                     391 lines
--   ui/lib/render.lua                    224 lines
--   ui/lib/widgets.lua                  1655 lines
--   ui/lib/init.lua                     1577 lines
--   ui/logodata.lua                       19 lines
--   ui/logo.lua                          134 lines
--   ui/wording.lua                        68 lines
--   ui/splash.lua                        711 lines
--   ui/stats.lua                        1618 lines
--   ui/island.lua                        173 lines
--   ui/window.lua                        716 lines
--   ui/adapter.lua                       332 lines
--   ui/shell.lua                          83 lines
--   ui/tabs/home.lua                      78 lines
--   ui/tabs/misc.lua                     156 lines
--   ui/tabs/config.lua                   143 lines
--   features/gamethrottle.lua            173 lines
--   features/fps.lua                     477 lines
--   features/misc/servers.lua            271 lines
--   features/misc/webhook.lua            201 lines
--   games/rideapet/standalone.lua       1276 lines

local BLYXO_VERSION = "1.0.0"
local BLYXO_BUILD   = "4fd47f60"
local BLYXO_GAME    = "Ride A Pet"

local env = (type(getgenv) == "function" and getgenv()) or _G
env.BlyxoGeneration = (env.BlyxoGeneration or 0) + 1
local BX = {
generation  = env.BlyxoGeneration,
version     = BLYXO_VERSION,
build       = BLYXO_BUILD,
game        = BLYXO_GAME,
_factories  = {},
_loaded     = {},
_loading    = {},
_conns      = {},
}
env.BX = BX
function BX.alive()
return env.BlyxoGeneration == BX.generation
end
function BX.module(name, factory)
if BX._factories[name] then
error(("duplicate module %q"):format(name), 2)
end
BX._factories[name] = factory
end
function BX.require(name)
local cached = BX._loaded[name]
if cached ~= nil then return cached end
if BX._loading[name] then
error(("circular dependency: %s"):format(name), 2)
end
local factory = BX._factories[name]
if not factory then
error(("no such module: %s"):format(name), 2)
end
BX._loading[name] = true
local ok, result = pcall(factory, BX)
BX._loading[name] = nil
if not ok then
error(("module %q failed to load: %s"):format(name, tostring(result)), 2)
end
if result == nil then
error(("module %q returned nil (forgot to return M?)"):format(name), 2)
end
BX._loaded[name] = result
return result
end
function BX.connect(signal, fn)
local c = signal:Connect(fn)
BX._conns[#BX._conns + 1] = c
return c
end
function BX.offthread(fn, timeout)
local done, result, failure = false, nil, nil
task.spawn(function()
local ok, r = pcall(fn)
if ok then result = r else failure = r end
done = true
end)
local startedAt = os.clock()
timeout = timeout or 5
while not done and (os.clock() - startedAt) < timeout do
task.wait(0.03)
end
return result, done, failure
end
BX._teardownHooks = {}
function BX.onTeardown(label, fn)
BX._teardownHooks[#BX._teardownHooks + 1] = { label = tostring(label), fn = fn }
end
function BX.teardown()
if BX._tornDown then return end
BX._tornDown = true
for i = #BX._teardownHooks, 1, -1 do
local h = BX._teardownHooks[i]
local ok, err = pcall(h.fn)
if not ok then
pcall(function()
local lg = BX._loaded["boot.log"]
if lg then lg._emit(4, "teardown", ("%s: %s"):format(h.label, tostring(err))) end
end)
end
end
BX._teardownHooks = {}
pcall(function()
local lg = BX._loaded["boot.log"]
if lg and lg.flushNow then lg.flushNow() end
end)
if BX.destroyAllScopes then pcall(BX.destroyAllScopes) end
for _, c in ipairs(BX._conns) do
pcall(function() c:Disconnect() end)
end
BX._conns = {}
BX._loaded = {}
end
if type(env.BlyxoTeardown) == "function" then
pcall(env.BlyxoTeardown)
end
env.BlyxoTeardown = BX.teardown
BX.module("boot.log", function(BX)
local M = {}
local TRACE_FILE  = "BlyxoHub_trace.txt"
local FLUSH_GAP   = 3.0
local RING        = 500   
local canWrite  = (type(writefile) == "function")
local debugOn   = function()
local env = (type(getgenv) == "function" and getgenv()) or _G
return env.BlyxoDebug == true
end
local PREV_FILE = "BlyxoHub_trace_prev.txt"
if canWrite and type(readfile) == "function" and type(isfile) == "function" then
pcall(function()
local env = (type(getgenv) == "function" and getgenv()) or _G
if env.__BLYXO_LOG_ROTATED then return end
env.__BLYXO_LOG_ROTATED = true
if isfile(TRACE_FILE) then writefile(PREV_FILE, readfile(TRACE_FILE)) end
end)
end
if canWrite then
pcall(writefile, TRACE_FILE, "[boot] BlyxoHub logger initialized\n")
end
local ring, ringN, ringHead = {}, 0, 0
local flushAt     = 0
local seen, seenN = {}, 0   
local SEEN_MAX    = 400     
M.LEVELS = { TRACE = 1, INFO = 2, WARN = 3, ERROR = 4 }
M.level  = M.LEVELS.INFO
local function stamp()
return ("%7.2f"):format(os.clock())
end
local dirty = false
local function writeNow()
if not canWrite then return end
flushAt = os.clock()
dirty = false
local out, n = {}, 0
local start = (ringN < RING) and 1 or (ringHead % RING) + 1
for i = 0, ringN - 1 do
n = n + 1
out[n] = ring[((start - 1 + i) % RING) + 1]
end
local body = table.concat(out, "\n", 1, n)
if BX.profile and BX.profile.measure then
BX.profile.measure("log/writefile", pcall, writefile, TRACE_FILE, body)
else
pcall(writefile, TRACE_FILE, body)
end
end
local function flush(force)
if not canWrite then return end
if force then return writeNow() end
dirty = true
end
if canWrite then
task.spawn(function()
while BX.alive() do
task.wait(FLUSH_GAP)
if dirty then pcall(writeNow) end
end
if dirty then pcall(writeNow) end
end)
end
function M.flushNow() pcall(writeNow) end
local TAGS = { "TRACE", "INFO", "WARN", "ERROR" }
local function emit(level, mod, msg)
if level < M.level then return end
local line = ("[%s] %-5s %-16s %s"):format(stamp(), TAGS[level], mod, msg)
ringHead = (ringHead % RING) + 1
ring[ringHead] = line
if ringN < RING then ringN = ringN + 1 end
if debugOn() or level >= M.LEVELS.WARN then
print("[BLYXO] " .. line)
end
flush(level >= M.LEVELS.ERROR)
end
function M.for_module(name)
return {
trace = function(m, ...)
if M.level > 1 then return end
emit(1, name, select("#", ...) > 0 and m:format(...) or m)
end,
info  = function(m, ...) emit(2, name, select("#", ...) > 0 and m:format(...) or m) end,
warn  = function(m, ...) emit(3, name, select("#", ...) > 0 and m:format(...) or m) end,
error = function(m, ...) emit(4, name, select("#", ...) > 0 and m:format(...) or m) end,
}
end
function M.session(msg)
emit(2, "session", "=== " .. msg .. " ===")
flush(true)
end
function M.repeats()
local out = {}
for label, n in pairs(seen) do
if n > 1 then out[#out + 1] = ("%s x%d"):format(label, n) end
end
table.sort(out)
return out
end
function BX.try(label, fn, ...)
local ok, result = pcall(fn, ...)
if not ok then
if seen[label] == nil then
if seenN >= SEEN_MAX then
label = "(other)"
else
seenN = seenN + 1
end
end
local n = (seen[label] or 0) + 1
seen[label] = n
if n == 1 then
emit(4, "try", ("%s: %s"):format(label, tostring(result)))
elseif n == 10 or n == 100 or n == 1000 then
emit(3, "try", ("%s: still failing (x%d)"):format(label, n))
end
end
return ok, result
end
function BX.guard(label, fn)
return function(...)
return select(2, BX.try(label, fn, ...))
end
end
M._emit = emit
M._seen = seen
return M
end)
BX._scopes = {}
function BX.scope(name)
local existing = BX._scopes[name]
if existing and not existing.dead then existing:destroy() end
local sc = {
name    = name,
dead    = false,
conns   = {},
insts   = {},
threads = {},
tweens  = {},
gen     = BX.generation,
}
function sc:alive()
return (not self.dead) and BX.alive()
end
function sc:connect(signal, fn)
if self.dead then return nil end
local c = signal:Connect(fn)
self.conns[#self.conns + 1] = c
return c
end
function sc:own(inst)
if self.dead then
pcall(function() inst:Destroy() end)
return inst
end
self.insts[#self.insts + 1] = inst
return inst
end
function sc:spawn(label, fn, ...)
if self.dead then return nil end
local th
th = task.spawn(function(...)
BX.try(self.name .. "/" .. label, fn, ...)
for i, t in ipairs(self.threads) do
if t == th then table.remove(self.threads, i) break end
end
end, ...)
self.threads[#self.threads + 1] = th
return th
end
function sc:loop(label, interval, fn)
local tag = self.name .. "/" .. label
local body = BX.profile and BX.profile.wrapLoop(tag, interval, fn) or fn
return self:spawn(label .. "/loop", function()
while self:alive() do
BX.try(tag, body)
if not self:alive() then return end
task.wait(interval)
end
end)
end
function sc:onFrame(label, signal, fn)
local tag = self.name .. "/" .. label
local guarded = BX.guard(tag, fn)
local timed = BX.profile and BX.profile.wrap(tag, guarded) or guarded
return self:connect(signal, timed)
end
function sc:delay(label, seconds, fn)
if self.dead then return end
task.delay(seconds, function()
if not self:alive() then return end
BX.try(self.name .. "/" .. label, fn)
end)
end
function sc:tween(obj, t, props, style, dir)
if self.dead then return nil end
local tween
BX.try(self.name .. "/tween", function()
tween = BX.require("core.services").TweenService:Create(obj,
TweenInfo.new(t, style or Enum.EasingStyle.Quint,
dir or Enum.EasingDirection.Out), props)
tween:Play()
end)
if tween then self.tweens[#self.tweens + 1] = tween end
return tween
end
function sc:destroy()
if self.dead then return end
self.dead = true
for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
for _, t in ipairs(self.tweens) do pcall(function() t:Cancel() end) end
for _, i in ipairs(self.insts) do pcall(function() i:Destroy() end) end
local me = coroutine.running()
for _, th in ipairs(self.threads) do
if th ~= me then pcall(task.cancel, th) end
end
self.conns, self.insts, self.threads, self.tweens = {}, {}, {}, {}
if BX._scopes[self.name] == self then BX._scopes[self.name] = nil end
end
function sc:counts()
return {
conns   = #self.conns,
insts   = #self.insts,
threads = #self.threads,
tweens  = #self.tweens,
}
end
BX._scopes[name] = sc
return sc
end
function BX.scopeReport()
local out = {}
for name, sc in pairs(BX._scopes) do
if not sc.dead then
local c = sc:counts()
out[#out + 1] = ("%-24s conns=%-3d insts=%-4d threads=%-3d tweens=%d")
:format(name, c.conns, c.insts, c.threads, c.tweens)
end
end
table.sort(out)
return out
end
function BX.destroyAllScopes()
for _, sc in pairs(BX._scopes) do
pcall(function() sc:destroy() end)
end
BX._scopes = {}
end
BX.profile = {
enabled = true,
_stats  = {},    
_mem0   = nil,
_t0     = os.clock(),
}
local P = BX.profile
P._watch = {}
function P.watch(name, fn) P._watch[name] = fn end
function P.watched()
local out = {}
for name, fn in pairs(P._watch) do
local ok, n = pcall(fn)
out[#out + 1] = ("%s=%s"):format(name, ok and tostring(n) or "?")
end
table.sort(out)
return out
end
P._marks = {}
local function markRead()
local plr = game:GetService("Players").LocalPlayer
local char = plr and plr.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
if not hum then return -1, "no-humanoid", false end
return hum.Health, hum:GetState().Name, hum:GetAttribute("BlyxoStealHum") == true
end
function P.mark(name)
local ok, health, state, swapped = pcall(markRead)
local row = {
name = name, at = os.clock(),
health = ok and health or -1,
state = ok and state or "?",
swapped = ok and swapped or false,
}
P._marks[#P._marks + 1] = row
if #P._marks > 200 then table.remove(P._marks, 1) end
return row
end
function P.marksSince(t)
local out = {}
for _, r in ipairs(P._marks) do
if r.at >= (t or 0) then
out[#out + 1] = ("%s@%.2f hp=%.0f %s%s"):format(
r.name, r.at - (t or 0), r.health, r.state, r.swapped and " swapped" or "")
end
end
return out
end
local heapKb = function()
local ok, v = pcall(collectgarbage, "count")
return (ok and type(v) == "number") and v or 0
end
P.journalOn = false
P._journal, P._jHead, P.JOURNAL = {}, 0, 512
function P.stamp(label, t0, dt)
if not P.journalOn then return end
P._jHead = (P._jHead % P.JOURNAL) + 1
local row = P._journal[P._jHead]
if not row then row = {}; P._journal[P._jHead] = row end
row[1], row[2], row[3] = label, t0, dt
end
local function statFor(label, kind, interval)
local s = P._stats[label]
if not s then
s = { n = 0, total = 0, max = 0, last = 0, alloc = 0, kind = kind,
interval = interval, since = os.clock(), yields = 0, wall = 0 }
P._stats[label] = s
end
return s
end
P.frameNo = 0
BX.scope("boot.profile.clock"):connect(game:GetService("RunService").Heartbeat, function()
P.frameNo = P.frameNo + 1
end)
local function timed(s, label, fn, ...)
local t0, k0, f0 = os.clock(), heapKb(), P.frameNo
local r1, r2, r3, r4 = fn(...)
local dt = os.clock() - t0
s.n = s.n + 1
if P.frameNo ~= f0 then
s.yields = s.yields + 1
s.wall = s.wall + dt
return r1, r2, r3, r4
end
local dk = heapKb() - k0
s.total = s.total + dt
s.last = dt
if dk > 0 then s.alloc = s.alloc + dk end
if dt > s.max then s.max = dt end
if P.journalOn then P.stamp(label, t0, dt) end
return r1, r2, r3, r4
end
function P.wrap(label, fn)
local s = statFor(label, "frame")
return function(...)
if not P.enabled then return fn(...) end
return timed(s, label, fn, ...)
end
end
function P.wrapLoop(label, interval, fn)
local s = statFor(label, "loop", interval)
return function(...)
if not P.enabled then return fn(...) end
return timed(s, label, fn, ...)
end
end
function P.measure(label, fn, ...)
if not P.enabled then return fn(...) end
timed(statFor(label, "io"), label, fn, ...)
end
function P.rows()
local rows, now = {}, os.clock()
for label, s in pairs(P._stats) do
if s.n > 0 then
local sync = math.max(s.n - s.yields, 1)
rows[#rows + 1] = {
label = label, kind = s.kind,
hz    = s.n / math.max(now - s.since, 0.001),
avg   = (s.total / sync) * 1000,
max   = s.max * 1000,
total = s.total,
n     = s.n,
yields = s.yields,
wallAvg = s.yields > 0 and (s.wall / s.yields) * 1000 or 0,
kbPer = s.alloc / sync,
interval = s.interval,
}
end
end
table.sort(rows, function(a, b) return a.total > b.total end)
return rows
end
function P.reset()
for _, s in pairs(P._stats) do
s.n, s.total, s.max, s.last, s.alloc, s.since = 0, 0, 0, 0, 0, os.clock()
s.yields, s.wall = 0, 0
end
end
function P.report()
local out = { ("%-40s %-5s %7s %8s %8s %8s %8s %5s"):format(
"job", "kind", "hz", "avg ms", "max ms", "calls", "kb/call", "yld") }
for _, r in ipairs(P.rows()) do
out[#out + 1] = ("%-40s %-5s %7.2f %8.3f %8.3f %8d %8.2f %5d")
:format(r.label, r.kind, r.hz, r.avg, r.max, r.n, r.kbPer, r.yields)
end
return out
end
local StatsService = game:GetService("Stats")
local function memMb()
local ok, v = pcall(StatsService.GetTotalMemoryUsageMb, StatsService)
if ok and type(v) == "number" then return v end
ok, v = pcall(gcinfo)
return (ok and type(v) == "number") and (v / 1024) or 0
end
function P.health()
local conns, threads, scopes, insts = 0, 0, 0, 0
for _, sc in pairs(BX._scopes or {}) do
if not sc.dead then
scopes = scopes + 1
conns   = conns + #sc.conns
insts   = insts + #sc.insts
threads = threads + #sc.threads
end
end
local mem = memMb()
P._mem0 = P._mem0 or mem
local loaded = 0
for _ in pairs(BX._loaded) do loaded = loaded + 1 end
return {
uptime  = os.clock() - P._t0,
mem     = mem,
memGrow = mem - P._mem0,
scopes  = scopes,
conns   = conns,
insts   = insts,
threads = threads,
loaded  = loaded,
}
end
function P.start()
local sc  = BX.scope("boot.profile")
local log = BX.require("boot.log").for_module("profile")
local fps, lastFrame, last = 0, P.frameNo, os.clock()
sc:loop("health", 60, function()
local now = os.clock()
fps = (P.frameNo - lastFrame) / math.max(now - last, 0.001)
lastFrame, last = P.frameNo, now
local h = P.health()
local w = P.watched()
log.info("health up=%.0fs fps=%.0f mem=%.0fMB (%+.0f) scopes=%d conns=%d insts=%d threads=%d%s",
h.uptime, fps, h.mem, h.memGrow, h.scopes, h.conns, h.insts, h.threads,
#w > 0 and (" | " .. table.concat(w, " ")) or "")
end)
return sc
end
BX.module("core.services", function(BX)
local log = BX.require("boot.log").for_module("services")
local M = {}
local WANTED = {
"Players", "ReplicatedStorage", "RunService", "TweenService",
"UserInputService", "Lighting", "Workspace", "HttpService",
"TextService", "Stats",
"TeleportService",
}
for _, name in ipairs(WANTED) do
local ok, svc = pcall(game.GetService, game, name)
if ok and svc then
M[name] = svc
else
log.error("service unavailable: %s", name)
end
end
if M.Players and not M.Players.LocalPlayer then
local deadline = os.clock() + 10
while not M.Players.LocalPlayer and os.clock() < deadline do task.wait(0.1) end
if M.Players.LocalPlayer then
log.info("LocalPlayer arrived late (%.1fs) - waited for it", 10 - (deadline - os.clock()))
else
log.error("Players.LocalPlayer is still nil after 10s")
end
end
M.LocalPlayer = M.Players and M.Players.LocalPlayer
return M
end)
BX.module("core.net", function(BX)
local svc = BX.require("core.services")
local log = BX.require("boot.log").for_module("net")
local M = {}
local container, containerAt = nil, 0
local CONTAINER_TTL = 30
local function networking()
local now = os.clock()
if container and container.Parent and (now - containerAt) < CONTAINER_TTL then
return container
end
local pkgs = svc.ReplicatedStorage:FindFirstChild("Packages")
local net = pkgs and pkgs:FindFirstChild("Networking")
container, containerAt = net, now
return net
end
function M.find(name)
local net = networking()
return net and net:FindFirstChild(name) or nil
end
function M.call(name, ...)
local rf = M.find(name)
if not rf then return false, "remote not found: " .. tostring(name) end
local ok, a, b = pcall(function(...) return rf:InvokeServer(...) end, ...)
if not ok then return false, tostring(a) end
return a, b
end
function M.list(pattern)
local net = networking()
if not net then return {} end
local out = {}
for _, remote in ipairs(net:GetChildren()) do
local name = remote.Name
if not pattern or name:lower():find(pattern, 1, true) then
out[#out + 1] = ("%s (%s)"):format(name, remote.ClassName)
end
end
table.sort(out)
return out
end
function M.fire(name, ...)
local re = M.find(name)
if not re then return false, "remote not found: " .. tostring(name) end
local ok, err = pcall(function(...) re:FireServer(...) end, ...)
if not ok then return false, tostring(err) end
return true
end
return M
end)
BX.module("core.scan", function(BX)
local M = {}
function M.collect(root, visit, budget)
if not root or type(visit) ~= "function" then return 0 end
budget = tonumber(budget) or 0.0015
local stack = { root }
local count = 0
while #stack > 0 do
local sliceAt = os.clock()
local batch = 0
repeat   
local node = table.remove(stack)
local ok, children = pcall(node.GetChildren, node)
if ok and type(children) == "table" then
for i = #children, 1, -1 do
stack[#stack + 1] = children[i]
end
end
if node ~= root then
local keepGoing = visit(node)
count = count + 1
if keepGoing == false then
stack = {}
end
end
batch = batch + 1
if batch >= 256 then
task.wait()
batch = 0
end
until #stack == 0 or os.clock() - sliceAt >= budget
task.wait()
end
return count
end
function M.snapshot(root, budget)
local out = {}
M.collect(root, function(node)
out[#out + 1] = node
end, budget)
return out
end
return M
end)
BX.module("core.exec", function(BX)
local log = BX.require("boot.log").for_module("exec")
local M = {}
local env = (type(getgenv) == "function" and getgenv()) or _G
local deny = type(env.BLYXO_CAPS_DENY) == "table" and env.BLYXO_CAPS_DENY or {}
M.simulatedDenies = deny
local function fn(name)
if deny[name] then return nil end
local ok, v
ok, v = pcall(function() return type(getgenv) == "function" and getgenv()[name] or nil end)
if not ok or type(v) ~= "function" then
ok, v = pcall(function() return getfenv and getfenv()[name] or nil end)
end
if not ok or type(v) ~= "function" then
ok, v = pcall(function() return (_G and _G[name]) end)
end
if not ok or type(v) ~= "function" then
ok, v = pcall(function()
local chunk = loadstring and loadstring("return " .. name)
return chunk and chunk() or nil
end)
end
return (ok and type(v) == "function") and v or nil
end
local function first(...)
for _, name in ipairs({ ... }) do
local f = fn(name)
if f then return f, name end
end
return nil, nil
end
local f_writefile   = first("writefile")
local f_readfile    = first("readfile")
local f_isfile      = first("isfile")
local f_delfile     = first("delfile")
local f_isfolder    = first("isfolder")
local f_makefolder  = first("makefolder")
local f_listfiles   = first("listfiles")
local f_customasset = first("getcustomasset", "getsynasset")
local f_gethui      = first("gethui")
local f_getgc       = first("getgc")
local f_getconns    = first("getconnections")
local f_hookfn      = first("hookfunction", "replaceclosure")
local f_getrawmeta  = first("getrawmetatable")
local f_setreadonly = first("setreadonly", "make_writeable")
local f_queueport   = first("queue_on_teleport", "queueonteleport")
local f_identify    = first("identifyexecutor", "getexecutorname")
local f_fireprompt  = first("fireproximityprompt")
local f_setident    = first("setthreadidentity", "set_thread_identity",
"setidentity", "setthreadcontext")
local f_getident    = first("getthreadidentity", "get_thread_identity",
"getidentity", "getthreadcontext")
local f_clip, clipName = first("setclipboard", "toclipboard", "set_clipboard", "setrbxclipboard")
local canRequire, requireWhy = true, "unprobed"
do
local ok, err = pcall(function()
local RS = game:GetService("ReplicatedStorage")
local data = RS:FindFirstChild("Data")
local probe = data and data:FindFirstChild("Areas")
if not (probe and probe:IsA("ModuleScript")) then return end
canRequire, requireWhy = true, probe:GetFullName()
end)
if not ok then canRequire, requireWhy = false, tostring(err) end
if deny.gameRequire then canRequire, requireWhy = false, "simulated deny" end
end
local f_request, requestName
do
local ok, v = pcall(function() return syn and syn.request end)
if ok and type(v) == "function" then
f_request, requestName = v, "syn.request"
else
ok, v = pcall(function() return http and http.request end)
if ok and type(v) == "function" then
f_request, requestName = v, "http.request"
else
f_request, requestName = first("request", "http_request", "httprequest")
end
end
end
M.can = {
files      = (f_writefile and f_readfile and f_isfile) and true or false,
folders    = (f_isfolder and f_makefolder) and true or false,
listFiles  = f_listfiles and true or false,
customAsset = f_customasset and true or false,
identity   = (f_setident and f_getident) and true or false,
hiddenUi   = f_gethui and true or false,
gc         = f_getgc and true or false,
connections = f_getconns and true or false,
hooking    = (f_hookfn and f_getrawmeta) and true or false,
clipboard  = f_clip and true or false,
request    = f_request and true or false,
teleportQueue = f_queueport and true or false,
prompts    = true,
gameRequire = canRequire,
}
M.promptVia = f_fireprompt and "fireproximityprompt" or "InputHoldBegin"
M.gameRequireWhy = requireWhy
M.name = "unknown"
if f_identify then
local ok, n = pcall(f_identify)
if ok and type(n) == "string" and #n > 0 then M.name = n end
end
local FRAGILE = { "solara" }
M.fragile = false
do
local lower = M.name:lower()
for _, bad in ipairs(FRAGILE) do
if lower:find(bad, 1, true) then M.fragile = true break end
end
end
if M.fragile then
M.can.hooking, M.can.gc = false, false
f_getgc = nil
if BX.profile then BX.profile.enabled = false end
log.warn("fragile executor (%s): hooks, gc, per-frame profiling, renderer settings and custom assets are off", M.name)
end
function M.hiddenParent()
local ok, playerGui = pcall(function()
local player = game:GetService("Players").LocalPlayer
return player and (player:FindFirstChildOfClass("PlayerGui")
or player:WaitForChild("PlayerGui", 10))
end)
if ok and playerGui then return playerGui end
if f_gethui then
local ok, ui = pcall(f_gethui)
if ok and ui then return ui end
end
return nil
end
function M.writeFile(path, data)
if not f_writefile then return false end
return (BX.try("exec.writeFile", f_writefile, path, data))
end
function M.readFile(path)
if not f_readfile then return nil end
local ok, data = BX.try("exec.readFile", f_readfile, path)
return ok and data or nil
end
function M.isFile(path)
if not f_isfile then return false end
local ok, yes = pcall(f_isfile, path)
return ok and yes or false
end
function M.listFiles(path)
if not f_listfiles then return nil end
local ok, files = BX.try("exec.listFiles", f_listfiles, path)
if not ok or type(files) ~= "table" then return nil end
return files
end
function M.deleteFile(path)
if not f_delfile then return false end
return (BX.try("exec.deleteFile", f_delfile, path))
end
function M.ensureFolder(path)
if not M.can.folders then return false end
local built = ""
for part in tostring(path):gmatch("[^/]+") do
built = (built == "") and part or (built .. "/" .. part)
local ok, exists = pcall(f_isfolder, built)
if ok and not exists then
if not BX.try("exec.makeFolder", f_makefolder, built) then return false end
end
end
return true
end
function M.requireGame(inst)
if not (f_setident and f_getident) then return require(inst) end
local okPrev, prev = pcall(f_getident)
if not okPrev or type(prev) ~= "number" then return require(inst) end
local result
local ok, err = pcall(function()
f_setident(2)
result = require(inst)
end)
pcall(f_setident, prev)
if not ok then error(err, 0) end
return result
end
function M.customAsset(path)
if not f_customasset then return nil end
local ok, id = BX.try("exec.customAsset", f_customasset, path)
return ok and id or nil
end
function M.clipboard(text)
for _, name in ipairs({ "setclipboard", "toclipboard", "set_clipboard", "setrbxclipboard" }) do
local f = fn(name)
if f and pcall(f, text) then return true end
end
return false
end
function M.httpRequest(opts)
if not f_request then return nil end
local ok, res = BX.try("exec.httpRequest", f_request, opts)
return ok and res or nil
end
function M.gcScan(tablesOnly)
if not f_getgc then return {} end
local t0 = os.clock()
local ok, objs = BX.try("exec.gcScan", f_getgc, tablesOnly and true or false)
if not ok or type(objs) ~= "table" then return {} end
local ms = (os.clock() - t0) * 1000
M.lastGcMs = ms
log.warn("gc sweep: %d objects in %.0fms", #objs, ms)
return objs
end
function M.firePrompt(prompt, holdDuration)
if f_fireprompt then
return (BX.try("exec.firePrompt", f_fireprompt, prompt, holdDuration or 0))
end
return (BX.try("exec.firePrompt.hold", function()
prompt:InputHoldBegin()
local hold = tonumber(holdDuration)
if hold == nil then hold = tonumber(prompt.HoldDuration) or 0 end
if hold > 0 then task.wait(hold + 0.05) end
prompt:InputHoldEnd()
end))
end
function M.report()
local have, missing = {}, {}
for k, v in pairs(M.can) do
table.insert(v and have or missing, k)
end
table.sort(have); table.sort(missing)
local denied = {}
for k in pairs(deny) do denied[#denied + 1] = tostring(k) end
table.sort(denied)
return {
executor = M.name,
have = have,
missing = missing,
denied = denied,
promptVia = M.promptVia,
gameRequireWhy = requireWhy,
}
end
local r = M.report()
log.info("executor=%s clipboard=%s request=%s prompts=%s gameRequire=%s (%s)",
M.name, tostring(clipName), tostring(requestName), M.promptVia,
tostring(canRequire), tostring(requireWhy))
if #r.denied > 0 then
log.warn("SIMULATED capability denies active: %s", table.concat(r.denied, ", "))
end
log.info("supported: %s", #r.have > 0 and table.concat(r.have, ", ") or "(none)")
if #r.missing > 0 then
log.warn("unsupported here: %s", table.concat(r.missing, ", "))
end
return M
end)
BX.module("core.device", function(BX)
local svc = BX.require("core.services")
local cfg = BX.require("core.config")
local log = BX.require("boot.log").for_module("device")
local M = {}
M.isTouch = svc.UserInputService.TouchEnabled
and not svc.UserInputService.KeyboardEnabled
local function shortSide()
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize
if not vp or vp.Y < 10 then return 1080 end
return math.min(vp.X, vp.Y)
end
M.smallScreen = shortSide() < 500
M.tier = (M.isTouch and M.smallScreen) and "low" or "mid"
M.fps = nil
local MULT = { low = 2.2, mid = 1.35, high = 1.0 }
function M.scale(seconds)
return seconds * (MULT[M.tier] or 1.35)
end
function M.budget(n)
local share = (M.tier == "low" and 0.35) or (M.tier == "mid" and 0.7) or 1
return math.max(1, math.floor(n * share + 0.5))
end
function M.lite()
return M.tier == "low"
end
local listeners = {}
function M.onTier(sc, label, fn)
listeners[#listeners + 1] = { scope = sc, label = label, fn = fn }
end
local function setTier(t)
if M.tier == t then return end
local was = M.tier
M.tier = t
log.info("tier %s -> %s (fps %.0f, touch=%s, short=%d)",
was, t, M.fps or -1, tostring(M.isTouch), shortSide())
for i = #listeners, 1, -1 do
local L = listeners[i]
if not L.scope or L.scope.dead then
table.remove(listeners, i)
else
BX.try("device/" .. L.label, L.fn, t, was)
end
end
end
local sc = BX.scope("core.device")
local lastFrame, lastAt = BX.profile.frameNo, os.clock()
local pending, pendingCount = nil, 0
sc:loop("measure", 5, function()
local now = os.clock()
local fps = (BX.profile.frameNo - lastFrame) / math.max(now - lastAt, 0.001)
lastFrame, lastAt = BX.profile.frameNo, now
M.fps = M.fps and (M.fps + (fps - M.fps) * 0.4) or fps
local want = M.tier
if M.tier == "high" then
if M.fps < 45 then want = "mid" end
elseif M.tier == "mid" then
if M.fps < cfg.LITE_FPS then want = "low"
elseif M.fps > 75 then want = "high" end
else
if M.fps > 40 then want = "mid" end
end
if want == "high" and M.isTouch and M.smallScreen then want = "mid" end
if want == M.tier then
pending, pendingCount = nil, 0
return
end
if pending == want then
pendingCount = pendingCount + 1
else
pending, pendingCount = want, 1
end
if pendingCount >= 2 then
setTier(want)
pending, pendingCount = nil, 0
end
end)
log.info("start tier=%s touch=%s smallScreen=%s", M.tier,
tostring(M.isTouch), tostring(M.smallScreen))
return M
end)
BX.module("core.character", function(BX)
local svc = BX.require("core.services")
local log = BX.require("boot.log").for_module("character")
local M = {}
local plr = svc.LocalPlayer
local current = setmetatable({}, { __mode = "v" })
local listeners = {}   
function M.get()
local c = current.char
if c and c.Parent then return c end
return plr and plr.Character
end
function M.root()
local c = M.get()
return c and c:FindFirstChild("HumanoidRootPart")
end
function M.humanoid()
local c = M.get()
return c and c:FindFirstChildOfClass("Humanoid")
end
local function fire(char)
current.char = char
for i = #listeners, 1, -1 do
local L = listeners[i]
if not L.scope or L.scope.dead then
table.remove(listeners, i)
else
BX.try(("character/%s"):format(L.label), L.fn, char)
end
end
end
function M.onSpawn(sc, label, fn)
listeners[#listeners + 1] = { scope = sc, label = label, fn = fn }
local c = M.get()
if c then BX.try(("character/%s"):format(label), fn, c) end
end
local sc = BX.scope("core.character")
if plr then
sc:connect(plr.CharacterAdded, function(char)
log.trace("respawn")
task.spawn(function()
BX.try("character/wait", function()
char:WaitForChild("HumanoidRootPart", 10)
end)
if BX.alive() then fire(char) end
end)
end)
sc:connect(plr.CharacterRemoving, function()
current.char = nil
end)
current.char = plr.Character
else
log.error("no LocalPlayer - character tracking unavailable")
end
M._listenerCount = function() return #listeners end
return M
end)
BX.module("core.config", function(BX)
return {
CARRY_SPEED        = 500,
OUTBOUND_SPEED_MIN = 500,
OUTBOUND_SPEED_MAX = 1200,
LITE_FPS           = 25,
STATS_HZ           = 4,
LOG_LEVEL          = 2,
FPS_MESH_LOD       = false,
AUTO_FPS_BOOST     = true,
SHOW_STATS         = true,
DEFAULT_ANTI_TREADMILL = false,
}
end)
BX.module("core.state", function(BX)
return {
heldEggUid      = nil,     
autoStealOn     = false,   
autoStealBusy   = false,   
autoStealState  = "DISABLED",
stayOnTreadmill = false,
lastFps         = 0,       
startedAt       = os.clock(),
}
end)
BX.module("core.util", function(BX)
local M = {}
function M.clamp(v, lo, hi)
return math.max(lo, math.min(hi, v))
end
function M.round(v, places)
local m = 10 ^ (places or 0)
return math.floor(v * m + 0.5) / m
end
function M.wait(seconds)
task.wait(seconds)
return BX.alive()
end
function M.short(n)
if n >= 1e6 then return ("%.1fM"):format(n / 1e6) end
if n >= 1e3 then return ("%.1fk"):format(n / 1e3) end
return tostring(math.floor(n))
end
return M
end)
BX.module("core.profiles", function(BX)
local svc  = BX.require("core.services")
local exec = BX.require("core.exec")
local log  = BX.require("boot.log").for_module("profiles")
local M = {}
local FORMAT = 1
local GAME_SUFFIX = ""
if BX.game and BX.game ~= "Steal An Egg" then
GAME_SUFFIX = "_" .. tostring(BX.game):gsub("%W+", "")
end
local DIR = "BlyxoHub/profiles" .. GAME_SUFFIX
local SETTINGS = "BlyxoHub/settings" .. GAME_SUFFIX .. ".json"
M.FORMAT = FORMAT
local SKIP_KEYS = { "url", "token", "secret", "key", "password" }
local ORDER = {
"Theme", "Background",
"FarmAreas", "FarmRarities", "FarmMutations",
"FarmMinWeight", "FarmMinIncome",
"FarmTargetBy", "FarmPriority",
"WebhookOn", "AntiTreadmill", "AntiTrap", "BatAura",
"UseTreadmillWhileWaiting", "TreadmillLock",
"FarmAutoSteal", "AutoSteal",
}
local ALLOW = {}
for _, k in ipairs(ORDER) do ALLOW[k] = true end
M.ALLOW = ALLOW
local KIND = {
Theme = "string", Background = "string",
FarmAreas = "table", FarmRarities = "table", FarmMutations = "table",
FarmMinWeight = "string", FarmMinIncome = "string",
FarmTargetBy = "string", FarmPriority = "string",
WebhookOn = "boolean", AntiTreadmill = "boolean", AntiTrap = "boolean",
BatAura = "boolean",
UseTreadmillWhileWaiting = "boolean", TreadmillLock = "boolean",
FarmAutoSteal = "boolean", AutoSteal = "boolean",
}
function M.allow(key, kind)
key = tostring(key)
if not ALLOW[key] then
ORDER[#ORDER + 1] = key
ALLOW[key] = true
end
KIND[key] = kind
end
local function skipped(name)
if not ALLOW[name] then return true end
local n = tostring(name):lower()
for _, bad in ipairs(SKIP_KEYS) do
if n:find(bad, 1, true) then return true end
end
return false
end
local function validValue(key, value)
local want = KIND[key]
if not want then return false end
if want == "table" then return type(value) == "table" end
return type(value) == want
end
function M.available()
return exec.can.files and exec.can.folders and true or false
end
local listing, listingOk = {}, false
local function safeName(name)
name = tostring(name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
return name
end
local function pathFor(name)
return DIR .. "/" .. name .. ".json"
end
function M.refresh()
listing, listingOk = {}, false
if not M.available() then return listing end
BX.try("profiles.refresh", function()
exec.ensureFolder("BlyxoHub")
exec.ensureFolder(DIR)
local files = exec.listFiles(DIR)
if not files then
log.warn("this executor has no listfiles - saved profiles cannot be listed")
return
end
for _, f in ipairs(files) do
local name = tostring(f):match("([^/\\]+)%.json$")
if name then listing[#listing + 1] = name end
end
table.sort(listing)
listingOk = true
end)
return listing
end
function M.list()
if not listingOk then M.refresh() end
return listing
end
local flagSource = nil
function M.setFlagSource(fn) flagSource = fn end
local appearanceSource, appearanceApply = nil, nil
function M.setAppearanceHooks(read, apply)
appearanceSource, appearanceApply = read, apply
end
local appliers = {}
function M.onApply(flag, fn) appliers[tostring(flag)] = fn end
local function elementValue(el)
if type(el) ~= "table" then return el end
local v = el.CurrentValue
if v == nil then v = el.Value end
if v == nil then v = el.value end
return v
end
local function collectFlags()
local out = {}
if type(flagSource) ~= "function" then return out end
local ok, flags = pcall(flagSource)
if not ok or type(flags) ~= "table" then return out end
for name, el in pairs(flags) do
if not skipped(name) then
local v = elementValue(el)
local t = type(v)
if t == "boolean" or t == "number" or t == "string" then
out[tostring(name)] = v
elseif t == "table" then
local copy = {}
for i, item in ipairs(v) do
if type(item) == "string" or type(item) == "number" then
copy[i] = item
end
end
out[tostring(name)] = copy
end
end
end
return out
end
function M.save(name)
if not M.available() then return false, "This executor cannot save files" end
name = safeName(name)
if name == "" then return false, "Give the profile a name" end
local payload = {
version = FORMAT,
saved = os.date("!%Y-%m-%dT%H:%M:%SZ"),
build = tostring(BX.build),
flags = collectFlags(),
appearance = (type(appearanceSource) == "function")
and select(2, pcall(appearanceSource)) or nil,
}
local body
local okEnc = pcall(function() body = svc.HttpService:JSONEncode(payload) end)
if not okEnc or not body then return false, "Could not encode the profile" end
local path = pathFor(name)
local ok = BX.try("profiles.save", function()
exec.ensureFolder("BlyxoHub")
exec.ensureFolder(DIR)
if not exec.writeFile(path, body) then error("writefile refused", 0) end
end)
if not ok then return false, "Could not write the profile" end
if not exec.isFile(path) then
log.warn("profile %q: writefile returned but isfile says no", name)
return false, "Written but not found - this executor's file access is broken"
end
local back = exec.readFile(path)
if back ~= body then
log.warn("profile %q: readback mismatch (%d vs %d bytes)", name,
type(back) == "string" and #back or -1, #body)
return false, "Written but readback differs - not saved"
end
M.refresh()
local n = 0
for _ in pairs(payload.flags) do n = n + 1 end
log.info("saved profile %q (%d flags)", name, n)
return true, "Saved " .. name
end
local loading = false
function M.load(name)
if not M.available() then return false, "This executor cannot read files" end
if loading then return false, "A profile is still loading" end
name = safeName(name)
if name == "" then return false, "Pick a profile" end
local path = pathFor(name)
if not exec.isFile(path) then return false, "No profile called " .. name end
local body = exec.readFile(path)
if type(body) ~= "string" or body == "" then
return false, name .. " is empty"
end
local data
local okDec = pcall(function() data = svc.HttpService:JSONDecode(body) end)
if not okDec or type(data) ~= "table" then
log.warn("profile %q is not valid JSON - refusing it", name)
return false, name .. " is corrupt"
end
local v = tonumber(data.version) or 0
if v > FORMAT then
return false, name .. " was saved by a newer version"
end
loading = true
local applied, ignored = 0, {}
local flagsIn = type(data.flags) == "table" and data.flags or {}
local elements = {}
if type(flagSource) == "function" then
local ok, flags = pcall(flagSource)
if ok and type(flags) == "table" then elements = flags end
end
for _, key in ipairs(ORDER) do
local value = flagsIn[key]
if value ~= nil then
if skipped(key) or not validValue(key, value) then
ignored[#ignored + 1] = key
else
local el = elements[key]
if type(el) == "table" and type(el.Set) == "function" then
BX.try("profiles.set." .. key, function() el:Set(value) end)
end
local fn = appliers[key]
if fn then
if BX.try("profiles.apply." .. key, fn, value) then applied = applied + 1 end
elseif el then
applied = applied + 1
end
end
end
end
for key in pairs(flagsIn) do
if not ALLOW[key] then ignored[#ignored + 1] = key end
end
if type(data.appearance) == "table" and type(appearanceApply) == "function" then
BX.try("profiles.appearance", function() appearanceApply(data.appearance) end)
end
loading = false
if #ignored > 0 then
log.info("profile %q: ignored %s", name, table.concat(ignored, ", "))
end
log.info("loaded profile %q (%d settings applied)", name, applied)
return true, ("Loaded %s (%d settings)"):format(name, applied)
end
function M.delete(name)
if not M.available() then return false, "This executor cannot delete files" end
name = safeName(name)
local path = pathFor(name)
if name == "" or not exec.isFile(path) then return false, "No such profile" end
local ok = BX.try("profiles.delete", function() exec.deleteFile(path) end)
M.refresh()
if not ok then return false, "Could not delete " .. name end
log.info("deleted profile %q", name)
return true, "Deleted " .. name
end
local function readSettings()
if not M.available() or not exec.isFile(SETTINGS) then return {} end
local body = exec.readFile(SETTINGS)
local data
pcall(function() data = svc.HttpService:JSONDecode(body) end)
return type(data) == "table" and data or {}
end
function M.autoLoadName()
local s = readSettings()
local n = s.autoLoad
return type(n) == "string" and n ~= "" and n or nil
end
function M.setAutoLoad(name)
if not M.available() then return false, "This executor cannot save files" end
name = safeName(name)
local s = readSettings()
s.autoLoad = (name ~= "" and name) or nil
s.version = FORMAT
local body
if not pcall(function() body = svc.HttpService:JSONEncode(s) end) then
return false, "Could not save the setting"
end
local wrote = BX.try("profiles.settings", function()
exec.ensureFolder("BlyxoHub")
if not exec.writeFile(SETTINGS, body) then error("writefile refused", 0) end
end)
if not wrote then return false, "Could not write the auto-load setting" end
local verify = readSettings()
if verify.autoLoad ~= s.autoLoad then
return false, "Auto-load setting was not saved"
end
log.info("auto-load profile is now %s", name ~= "" and ("%q"):format(name) or "off")
return true, name ~= "" and ("Auto-loading " .. name) or "Auto-load off"
end
local autoLoadRan = false
local LAST = "Last session"
local lastSaveAt, lastDirty = 0, false
local SAVE_EVERY = 5
function M.touch()
lastDirty = true
end
function M.startAutoSave()
local sc = BX.scope("core.profiles.autosave")
sc:loop("autosave", SAVE_EVERY, function()
if not lastDirty or not M.available() then return end
if M.autoLoadName() and M.autoLoadName() ~= LAST then
lastDirty = false
return
end
lastDirty = false
lastSaveAt = os.clock()
local ok, why = M.save(LAST)
if not ok then log.warn("could not keep the session profile: %s", tostring(why)) end
end)
end
function M.runAutoLoad()
if autoLoadRan then return false, "already ran" end
autoLoadRan = true
local name = M.autoLoadName()
if not name then
local found = false
for _, row in ipairs(M.list() or {}) do
local rowName = type(row) == "table" and (row.name or row[1]) or row
if tostring(rowName) == LAST then found = true break end
end
if not found then return false, "no auto-load profile set" end
name = LAST
log.info("no auto-load profile set - restoring %q", LAST)
end
local ok, msg = M.load(name)
if not ok then log.warn("auto-load failed: %s", tostring(msg)) end
return ok, msg
end
return M
end)
BX.module("ui.lib.theme", function(BX)
local T = {}
T.PANEL     = Color3.fromRGB(13, 13, 15)    
T.WORKSPACE = Color3.fromRGB(18, 17, 24)    
T.PANEL_2   = T.WORKSPACE                   
T.LINE      = Color3.fromRGB(42, 42, 48)    
T.CARD_TOP    = Color3.fromRGB(26, 26, 32)
T.CARD_BOT    = Color3.fromRGB(18, 18, 22)
T.CARD_TOP_H  = Color3.fromRGB(28, 27, 35)  
T.CARD_BOT_H  = Color3.fromRGB(20, 20, 26)
T.CARD_ROT    = 55
T.ELEMENT   = Color3.fromRGB(22, 22, 27)
T.ELEMENT_H = Color3.fromRGB(24, 24, 30)
T.CARD_EDGE   = Color3.fromRGB(42, 42, 48)
T.CARD_EDGE_H = Color3.fromRGB(128, 103, 163)   
T.TRACK     = Color3.fromRGB(43, 41, 56)    
T.COMMUNITY_TOP  = Color3.fromRGB(24, 21, 31)
T.COMMUNITY_BOT  = Color3.fromRGB(17, 17, 22)
T.COMMUNITY_EDGE = Color3.fromRGB(48, 40, 61)
T.UPDATE_TOP     = Color3.fromRGB(24, 24, 32)
T.UPDATE_BOT     = Color3.fromRGB(18, 18, 23)
T.CTA_BG    = Color3.fromRGB(24, 20, 31)
T.CTA_BG_H  = Color3.fromRGB(33, 26, 45)
T.CTA_EDGE  = Color3.fromRGB(64, 50, 79)
T.CTA_TEXT  = Color3.fromRGB(232, 226, 240)
T.CARD_TITLE  = Color3.fromRGB(243, 239, 248)   
T.BADGE_BG    = Color3.fromRGB(115, 81, 176)    
T.ROW_TAG     = Color3.fromRGB(169, 154, 192)
T.ROW_TEXT    = Color3.fromRGB(225, 221, 235)
T.ROW_TEXT_LAST = Color3.fromRGB(242, 239, 255)
T.TEXT      = Color3.fromRGB(236, 236, 240)
T.MUTED     = Color3.fromRGB(120, 120, 128)
T.PAGE_TITLE = Color3.fromRGB(221, 216, 231)
T.SECTION   = Color3.fromRGB(178, 161, 196)
T.TAB_OFF   = Color3.fromRGB(120, 120, 128)
T.TAB_ON    = Color3.fromRGB(236, 236, 240)
T.SELECT_TEXT = Color3.fromRGB(185, 168, 208)
T.ACCENT    = Color3.fromRGB(167, 139, 250)  
T.ACCENT_DEEP = Color3.fromRGB(91, 43, 216)  
T.ACCENT_2  = T.ACCENT
T.ACCENT_D  = T.TRACK
T.WARN      = Color3.fromRGB(224, 123, 138)
T.WHITE     = Color3.fromRGB(255, 255, 255)
T.BLACK     = Color3.fromRGB(0, 0, 0)
T.TOGGLE_ON = ColorSequence.new(T.ACCENT_DEEP, T.ACCENT)          
T.TAB_ACTIVE = ColorSequence.new(                                  
Color3.fromRGB(44, 36, 63), Color3.fromRGB(33, 26, 50))
T.TAB_ACTIVE_ROT = 20
T.TAB_EDGE  = Color3.fromRGB(77, 59, 112)
T.SELECT_BG = Color3.fromRGB(88, 62, 128)    
T.SELECT_EDGE = Color3.fromRGB(116, 88, 155) 
T.CAPSULE_EDGE = T.ACCENT                    
T.WORDMARK_GRADIENT = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
ColorSequenceKeypoint.new(0.55, Color3.fromRGB(229, 220, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(167, 139, 250)),
})
local FAMILY = "rbxassetid://12187365364"
local function face(weight)
local ok, f = pcall(Font.new, FAMILY, weight)
if ok and f then return f end
return Font.fromEnum(Enum.Font.GothamMedium)
end
T.FONT       = face(Enum.FontWeight.Regular)
T.FONT_MED   = face(Enum.FontWeight.Medium)
T.FONT_BOLD  = face(Enum.FontWeight.SemiBold)
T.MEASURE_FONT = Enum.Font.GothamMedium
T.SIZE_TITLE   = 20     
T.SIZE_SUB     = 12     
T.SIZE_PAGE    = 18     
T.SIZE_SECTION = 12     
T.SIZE_ROW     = 15     
T.SIZE_DESC    = 13     
T.SIZE_TAB     = 15
T.SIZE_BADGE   = 11
T.SIZE_SELECT  = 11     
T.WIN_W = 820
T.WIN_H = 480
T.WIN_W_NARROW = 380
T.WIN_H_NARROW = 540
T.RADIUS_WIN = 22
T.TITLEBAR_H  = 74
T.TITLEBAR_PAD_X = 24
T.TABBAR_W  = 196       
T.TABBAR_H  = 52        
T.RAIL_PAD_X = 12
T.RAIL_PAD_Y = 10
T.TAB_H     = 38
T.TAB_GAP   = 2
T.TAB_PAD_X = 14
T.RADIUS_TAB = 10
T.WORKSPACE_PAD_X = 28
T.WORKSPACE_PAD_Y = 24
T.PAGE_HEADER_H = 46
T.ROW_H      = 49
T.SECTION_H  = 34       
T.PAD        = 28
T.GAP        = 8
T.CARD_PAD_X = 15
T.CARD_PAD_Y = 11
T.CARD_GAP   = 14
T.RADIUS     = 13
T.RADIUS_SM  = 10
T.CONTROL_INSET = 18
T.CONTROL_RESERVE = 190     
T.VALUE_RESERVE   = 190
T.TOGGLE_W = 36
T.TOGGLE_H = 20
T.SELECT_W = 190
T.SELECT_H = 42
T.ACTION_W = 78
T.ACTION_H = 22
T.STATUS_W = 76
T.STATUS_H = 24
T.SIZE_PILL = 10
T.USER_CHIP_H = 58
T.USER_CHIP_RADIUS = 16
T.LOGO       = BX.require("ui.logo").image()
T.LOGO_FLAT  = T.LOGO
T.LOGO_GLOSS = T.LOGO
T.LOGO_SIZE  = 46       
T.LOGO_RADIUS = 13
T.LOGO_FILE  = nil
T.SIDE_W        = 138       
T.SIDE_BTN_H    = 44
T.SIDE_GAP      = 9         
T.SIDE_COL_GAP  = 14        
T.SIDE_RADIUS   = 10
T.SIDE_BG       = Color3.fromRGB(88, 52, 186)   
T.SIDE_BG_HOV   = Color3.fromRGB(104, 64, 208)
T.SIDE_BG_ON    = Color3.fromRGB(139, 104, 239) 
T.SIDE_EDGE     = Color3.fromRGB(24, 12, 46)    
T.SIDE_EDGE_ON  = Color3.fromRGB(214, 198, 255)
T.SIDE_TEXT     = Color3.fromRGB(255, 255, 255)
T.SIDE_STROKE_W = 2.5       
T.SIDE_TEXT_SIZE = 16
T.SEARCH_H      = 44
T.SEARCH_GAP    = 12
T.SEARCH_BG     = Color3.fromRGB(20, 18, 28)
T.SEARCH_FIELD  = Color3.fromRGB(30, 27, 41)
T.SEARCH_EDGE   = Color3.fromRGB(64, 50, 99)
T.STROKE_REST  = 0.55
T.STROKE_HOVER = 0.30
T.SHADOW_BLUR  = 60
T.SHADOW_ALPHA = 0.35
T.BLOOM_BLUR   = 170
T.BLOOM_ALPHA  = 0.93
T.CAPSULE_W      = 292
T.CAPSULE_W_WIDE = 320
T.CAPSULE_H      = 42
T.CAPSULE_H_WIDE = 46
T.CAPSULE_TOP    = 20
T.CAPSULE_RADIUS = 22
T.CAPSULE_EDGE_A = 0.48     
T.OVERLAY_Z    = 50
T.OVERLAY_SHADOW = 34
T.DIM_ALPHA    = 0.42
T.DIM_GRADIENT = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.25),
NumberSequenceKeypoint.new(0.5, 0),
NumberSequenceKeypoint.new(1, 0.25),
})
T.EASE_UI     = Enum.EasingStyle.Quint
T.EASE_WINDOW = Enum.EasingStyle.Exponential
T.FADE        = 0.12
T.MOVE        = 0.20
T.ENTER       = 0.36
T.TAB_FADE    = 0.18
T.SLIDE_IN    = 8
T.PRESS_SCALE = 0.985
T.MORPH       = 0.46
T.MORPH_CHROME = 0.22
function T.asset(path, fallback)
if not path then return fallback end
local got = nil
pcall(function()
local exec = BX.require("core.exec")
if exec.can.customAsset and exec.isFile(path) then
got = exec.customAsset(path)
end
end)
return got or fallback
end
function T.corner(radius)
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, radius or T.RADIUS)
return c
end
function T.stroke(colour, thickness, transparency)
local s = Instance.new("UIStroke")
s.Color = colour or T.LINE
s.Thickness = thickness or 1
s.Transparency = transparency or 0
s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
return s
end
function T.roundTopLeftOnly(frame, radius, colour)
radius = radius or T.RADIUS_WIN
local function patch(name, anchor, pos)
local f = Instance.new("Frame")
f.Name = name
f.AnchorPoint = anchor
f.Position = pos
f.Size = UDim2.fromOffset(radius, radius)
f.BackgroundColor3 = colour or T.WORKSPACE
f.BorderSizePixel = 0
f.ZIndex = 0
f.Parent = frame
end
patch("SquareTR", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0))
patch("SquareBL", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0))
patch("SquareBR", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0))
end
function T.gradient(sequence, rotation, transparency)
local g = Instance.new("UIGradient")
g.Color = sequence
g.Rotation = rotation or 90
if transparency then g.Transparency = transparency end
return g
end
function T.cardGradient(hovered)
return T.gradient(ColorSequence.new(
hovered and T.CARD_TOP_H or T.CARD_TOP,
hovered and T.CARD_BOT_H or T.CARD_BOT), T.CARD_ROT)
end
function T.shadow(object, blur, transparency)
local ok, s = pcall(function()
local sh = Instance.new("UIShadow")
sh.Color = T.BLACK
sh.BlurRadius = UDim.new(0, blur or T.SHADOW_BLUR)
sh.Transparency = transparency or T.SHADOW_ALPHA
sh.ZIndex = -1
sh.Parent = object
return sh
end)
return ok and s or nil
end
function T.fitScale(width, height)
local scale = 1
pcall(function()
local vp = workspace.CurrentCamera.ViewportSize
scale = math.clamp(
math.min((vp.X - 32) / width, (vp.Y - 32) / height), 0.5, 1)
end)
return scale
end
return T
end)
BX.module("ui.lib.render", function(BX)
local svc = BX.require("core.services")
local log = BX.require("boot.log").for_module("ui.render")
local M = {}
local pending = setmetatable({}, { __mode = "k" })
local pendingN = 0
local jobs = {}
local stats = { sets = 0, coalesced = 0, applied = 0, jobs = 0, frames = 0,
errors = 0, maxBatch = 0, requeued = 0 }
function M.stats() return table.clone(stats) end
function M.set(inst, prop, value)
if typeof(inst) ~= "Instance" then return false end
stats.sets = stats.sets + 1
local props = pending[inst]
if not props then
props = {}
pending[inst] = props
pendingN = pendingN + 1
elseif props[prop] ~= nil then
stats.coalesced = stats.coalesced + 1
end
props[prop] = value
return true
end
function M.setAll(inst, props)
if typeof(inst) ~= "Instance" then return false end
for k, v in pairs(props) do M.set(inst, k, v) end
return true
end
function M.call(fn)
if type(fn) ~= "function" then return false end
jobs[#jobs + 1] = fn
return true
end
function M.tween(inst, seconds, props, style, direction)
if typeof(inst) ~= "Instance" then return false end
return M.call(function()
local info = TweenInfo.new(seconds,
style or Enum.EasingStyle.Quint,
direction or Enum.EasingDirection.Out)
local t = svc.TweenService:Create(inst, info, props)
t:Play()
return t
end)
end
local function applyOne(inst, props)
if not inst.Parent and not inst:IsA("ScreenGui") then
return
end
for prop, value in pairs(props) do
local ok, err = pcall(function() inst[prop] = value end)
if ok then
stats.applied = stats.applied + 1
elseif tostring(err):find("capability", 1, true) then
stats.requeued = stats.requeued + 1
M.set(inst, prop, value)
else
stats.errors = stats.errors + 1
log.warn("write %s.%s failed: %s", inst.Name, tostring(prop), tostring(err))
end
end
end
local draining = false
local function drain()
if draining then return end
draining = true
local batch = 0
if pendingN > 0 then
local work = pending
pending, pendingN = setmetatable({}, { __mode = "k" }), 0
for inst, props in pairs(work) do
batch = batch + 1
applyOne(inst, props)
end
end
if #jobs > 0 then
local work = jobs
jobs = {}
for _, fn in ipairs(work) do
stats.jobs = stats.jobs + 1
local ok, err = pcall(fn)
if not ok then
stats.errors = stats.errors + 1
log.warn("render job failed: %s", tostring(err))
end
end
end
if batch > stats.maxBatch then stats.maxBatch = batch end
draining = false
end
M.drain = drain
local sc = nil
local started = false
function M.start()
if started then return true end
started = true
sc = BX.scope("ui.lib.render")
sc:spawn("drain", function()
while sc:alive() do
svc.RunService.RenderStepped:Wait()
stats.frames = stats.frames + 1
drain()
end
end)
log.info("render queue started")
return true
end
function M.stop()
if sc then sc:destroy() sc = nil end
started = false
pending, pendingN, jobs = setmetatable({}, { __mode = "k" }), 0, {}
end
function M.build(fn, timeout)
local limit = timeout or 5
local result, done, failure = BX.offthread(fn, limit)
if not done then
failure = ("timed out after %ss"):format(tostring(limit))
log.warn("render.build %s", failure)
end
if failure then log.error("render.build failed: %s", tostring(failure)) end
return result, done, failure
end
function M.flush() drain() end
return M
end)
BX.module("ui.lib.widgets", function(BX)
local svc = BX.require("core.services")
local T   = BX.require("ui.lib.theme")
local R   = BX.require("ui.lib.render")
local log = BX.require("boot.log").for_module("ui.widgets")
local W = {}
local UIS = svc.UserInputService
local ctx = { overlay = nil, scale = nil, root = nil }
function W.setContext(c) ctx = c or {} end
local function scaleK()
local s = ctx.scale
local k = s and s.Scale or 1
return (k > 0.01) and k or 1
end
local function mk(class, props, children)
local o = Instance.new(class)
local parent = props and props.Parent
for k, v in pairs(props or {}) do
if k ~= "Parent" then o[k] = v end
end
for _, c in ipairs(children or {}) do c.Parent = o end
if parent then o.Parent = parent end
return o
end
W.mk = mk
local function label(text, size, colour, bold)
return mk("TextLabel", {
BackgroundTransparency = 1,
Text = text or "",
FontFace = bold and T.FONT_BOLD or T.FONT,
TextSize = size or T.SIZE_ROW,
TextColor3 = colour or T.TEXT,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Center,
RichText = false,
})
end
local function hitbox(parent, height)
return mk("TextButton", {
Name = "Hit",
BackgroundTransparency = 1,
Text = "",
Size = height and UDim2.new(1, 0, 0, height) or UDim2.fromScale(1, 1),
AutoButtonColor = false,
ZIndex = 5,
Parent = parent,
})
end
local function chevron(parent, size, colour)
size = size or 9
local holder = mk("Frame", {
Name = "Chevron",
BackgroundTransparency = 1,
Size = UDim2.fromOffset(size * 2, size * 2),
Parent = parent,
})
local function bar(rot, xOff)
return mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, xOff, 0.5, 0),
Size = UDim2.fromOffset(size, 1.6),
BackgroundColor3 = colour or T.MUTED,
BorderSizePixel = 0,
Rotation = rot,
Parent = holder,
}, { T.corner(1) })
end
local a = bar(45, -size * 0.32)
local b = bar(-45, size * 0.32)
return holder, a, b
end
W.chevron = chevron
local function smallPill(parent, text, width, height)
local pill = mk("Frame", {
Name = "Pill",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -T.CONTROL_INSET, 0.5, 0),
Size = UDim2.fromOffset(width, height),
BackgroundColor3 = T.SELECT_BG,
BackgroundTransparency = 0.88,
BorderSizePixel = 0,
Parent = parent,
}, {
T.corner(height / 2),
T.stroke(T.SELECT_EDGE, 1, 0.68),
})
local lbl = label(text, T.SIZE_PILL, T.SELECT_TEXT, false)
lbl.Size = UDim2.fromScale(1, 1)
lbl.TextXAlignment = Enum.TextXAlignment.Center
lbl.Parent = pill
return pill, lbl
end
local function card(parent, opts)
local hasDesc = opts.description ~= nil and opts.description ~= ""
local reserve = opts.reserve or T.CONTROL_RESERVE
local ctrlH = opts.controlHeight or 26
local expandable = opts.expandable == true
local root = mk("Frame", {
Name = "Card_" .. tostring(opts.name or "?"),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = opts.order or 0,
ClipsDescendants = false,
Parent = parent,
}, {
T.corner(T.RADIUS),
T.cardGradient(false),
T.stroke(T.CARD_EDGE, 1, 0),
mk("UISizeConstraint", { MinSize = Vector2.new(0, opts.minHeight or T.ROW_H) }),
mk("UIPadding", {
PaddingLeft = UDim.new(0, T.CARD_PAD_X),
PaddingRight = UDim.new(0, T.CARD_PAD_X),
PaddingTop = UDim.new(0, T.CARD_PAD_Y),
PaddingBottom = UDim.new(0, T.CARD_PAD_Y),
}),
mk("UIListLayout", {
FillDirection = expandable and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
VerticalAlignment = Enum.VerticalAlignment.Center,
Padding = UDim.new(0, expandable and 6 or T.CARD_GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local header = root
if expandable then
header = mk("Frame", {
Name = "Header",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = 1,
Parent = root,
})
end
local col = mk("Frame", {
Name = "TextCol",
BackgroundTransparency = 1,
Size = UDim2.new(1, -(reserve + T.CONTROL_INSET + T.CARD_GAP), 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = 1,
Parent = header,
}, {
mk("UIListLayout", {
Padding = UDim.new(0, 3),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local title = label(opts.name, T.SIZE_ROW, T.TEXT, true)
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 0)
title.AutomaticSize = Enum.AutomaticSize.Y
title.TextYAlignment = Enum.TextYAlignment.Top
title.LayoutOrder = 1
title.Parent = col
local desc = nil
if hasDesc then
desc = label(opts.description, T.SIZE_DESC, T.MUTED, false)
desc.Name = "Desc"
desc.Size = UDim2.new(1, 0, 0, 0)
desc.AutomaticSize = Enum.AutomaticSize.Y
desc.TextWrapped = true
desc.TextYAlignment = Enum.TextYAlignment.Top
desc.LayoutOrder = 2
desc.Parent = col
end
local ctrl = (reserve > 0) and mk("Frame", {
Name = "Ctrl",
BackgroundTransparency = 1,
Size = UDim2.fromOffset(reserve + T.CONTROL_INSET, ctrlH),
LayoutOrder = 2,
Parent = header,
}) or nil
if expandable then
col.Position = UDim2.fromOffset(0, 0)
col.Size = UDim2.new(1, -(reserve + T.CARD_GAP), 0, 0)
if ctrl then
ctrl.AnchorPoint = Vector2.new(1, 0.5)
ctrl.Position = UDim2.new(1, 0, 0.5, 0)
end
end
local edge = root:FindFirstChildOfClass("UIStroke")
local fill = root:FindFirstChildOfClass("UIGradient")
local press = mk("UIScale", { Scale = 1, Parent = root })
local shell = {
root = root, header = header, col = col, title = title, desc = desc,
ctrl = ctrl, edge = edge, fill = fill, press = press,
order = opts.order or 0,
}
return shell
end
local function makeHoverable(shell, hit)
local inside, held = false, false
local function paint()
if shell.fill then
R.set(shell.fill, "Color", ColorSequence.new(
inside and T.CARD_TOP_H or T.CARD_TOP,
inside and T.CARD_BOT_H or T.CARD_BOT))
end
if shell.edge then
R.tween(shell.edge, T.FADE, {
Color = inside and T.CARD_EDGE_H or T.CARD_EDGE,
Transparency = inside and 0.5 or 0,
})
end
if shell.press then
R.tween(shell.press, T.FADE, {
Scale = held and T.PRESS_SCALE or 1,
}, T.EASE_UI)
end
end
hit.MouseEnter:Connect(function() inside = true paint() end)
hit.MouseLeave:Connect(function() inside = false held = false paint() end)
hit.MouseButton1Down:Connect(function() held = true paint() end)
hit.MouseButton1Up:Connect(function() held = false paint() end)
return paint
end
local function newHandle(kind, shell)
local h = { kind = kind, _root = shell and shell.root or nil, _dead = false }
function h:instance() return self._root end
function h:setTitle(text)
if shell and shell.title then R.set(shell.title, "Text", tostring(text)) end
end
function h:setDescription(text)
if shell and shell.desc then R.set(shell.desc, "Text", tostring(text)) end
end
function h:setVisible(on)
if self._root then R.set(self._root, "Visible", on and true or false) end
end
function h:destroy()
if self._dead then return end
self._dead = true
local root = self._root
if root then R.call(function() root:Destroy() end) end
end
return h
end
function W.section(parent, opts)
local root = mk("Frame", {
Name = "Section",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, T.SECTION_H),
LayoutOrder = opts.order or 0,
Parent = parent,
})
local text = label(string.upper(tostring(opts.name or "")),
T.SIZE_SECTION, T.SECTION, true)
text.Name = "Label"
text.AnchorPoint = Vector2.new(0, 1)
text.Position = UDim2.new(0, 2, 1, 0)
text.Size = UDim2.new(1, -4, 0, 14)
text.TextYAlignment = Enum.TextYAlignment.Bottom
text.Parent = root
local h = newHandle("section", { root = root, title = text })
function h:set(v) R.set(text, "Text", string.upper(tostring(v))) end
function h:get() return text.Text end
return h
end
function W.label(parent, opts)
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = T.VALUE_RESERVE, controlHeight = T.STATUS_H,
})
local _, value = smallPill(shell.ctrl, tostring(opts.text or ""),
T.VALUE_RESERVE, T.STATUS_H)
value.Name = "Value"
value.TextTruncate = Enum.TextTruncate.AtEnd
local current = tostring(opts.text or "")
local h = newHandle("label", shell)
function h:set(v)
v = tostring(v)
if v == current then return end
current = v
R.set(value, "Text", v)
end
function h:get() return current end
return h
end
function W.button(parent, opts)
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = T.ACTION_W, controlHeight = T.ACTION_H,
})
smallPill(shell.ctrl, string.upper(tostring(opts.action or "RUN")),
T.ACTION_W, T.ACTION_H)
local hit = hitbox(shell.root)
R.set(hit, "Size", UDim2.new(1, T.CARD_PAD_X * 2, 1, T.CARD_PAD_Y * 2))
R.set(hit, "Position", UDim2.fromOffset(-T.CARD_PAD_X, -T.CARD_PAD_Y))
makeHoverable(shell, hit)
local h = newHandle("button", shell)
hit.Activated:Connect(function()
if h._dead then return end
if opts.callback then
task.spawn(function() BX.try("ui.button/" .. tostring(opts.name), opts.callback) end)
end
end)
function h:set() end
function h:get() return nil end
return h
end
function W.toggle(parent, opts)
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = T.TOGGLE_W, controlHeight = T.TOGGLE_H,
})
local track = mk("Frame", {
Name = "Track",
Size = UDim2.fromScale(1, 1),
BackgroundColor3 = T.ACCENT_D,
BorderSizePixel = 0,
Parent = shell.ctrl,
}, { T.corner(T.TOGGLE_H / 2) })
local knobSize = T.TOGGLE_H - 6
local knob = mk("Frame", {
Name = "Knob",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 3, 0.5, 0),
Size = UDim2.fromOffset(knobSize, knobSize),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Parent = track,
}, {
T.corner(knobSize / 2),
})
local state = opts.value and true or false
local h = newHandle("toggle", shell)
local hit = hitbox(shell.root)
R.set(hit, "Size", UDim2.new(1, T.CARD_PAD_X * 2, 1, T.CARD_PAD_Y * 2))
R.set(hit, "Position", UDim2.fromOffset(-T.CARD_PAD_X, -T.CARD_PAD_Y))
makeHoverable(shell, hit)
local function paint(animate)
local pos = state and UDim2.new(1, -(knobSize + 3), 0.5, 0)
or UDim2.new(0, 3, 0.5, 0)
local col = state and T.ACCENT or T.ACCENT_D
if animate then
R.tween(knob, T.MOVE, { Position = pos }, T.EASE_UI)
R.tween(track, T.MOVE, { BackgroundColor3 = col })
else
R.set(knob, "Position", pos)
R.set(track, "BackgroundColor3", col)
end
end
paint(false)
function h:set(v)
v = v and true or false
if v == state then return end
state = v
paint(true)
end
function h:get() return state end
hit.Activated:Connect(function()
if h._dead then return end
state = not state
paint(true)
if opts.callback then
local v = state
task.spawn(function()
BX.try("ui.toggle/" .. tostring(opts.name), opts.callback, v)
end)
end
end)
return h
end
function W.slider(parent, opts)
local min = tonumber(opts.min) or 0
local max = tonumber(opts.max) or 100
local step = tonumber(opts.step) or 1
if max <= min then max = min + 1 end
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = 104, controlHeight = 20,
})
local readout = label("", T.SIZE_DESC, T.MUTED, false)
readout.Name = "Readout"
readout.Size = UDim2.fromScale(1, 1)
readout.TextXAlignment = Enum.TextXAlignment.Right
readout.Parent = shell.ctrl
local barRow = mk("Frame", {
Name = "BarRow",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 18),
LayoutOrder = 3,
Parent = shell.col,
})
local track = mk("Frame", {
Name = "Track",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
Size = UDim2.new(1, 0, 0, 5),
BackgroundColor3 = T.TRACK,
BorderSizePixel = 0,
Parent = barRow,
}, { T.corner(3) })
local fill = mk("Frame", {
Name = "Fill",
Size = UDim2.fromScale(0, 1),
BackgroundColor3 = T.ACCENT,
BorderSizePixel = 0,
Parent = track,
}, { T.corner(3) })
local knob = mk("Frame", {
Name = "Knob",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0, 0.5),
Size = UDim2.fromOffset(14, 14),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
ZIndex = 4,
Parent = track,
}, { T.corner(7) })
local grab = mk("TextButton", {
Name = "Grab",
BackgroundTransparency = 1,
Text = "",
Size = UDim2.new(1, 20, 1, 12),
Position = UDim2.fromOffset(-10, -6),
AutoButtonColor = false,
ZIndex = 6,
Parent = barRow,
})
local value = math.clamp(tonumber(opts.value) or min, min, max)
local function quantise(v)
v = math.clamp(v, min, max)
if step > 0 then v = math.floor((v - min) / step + 0.5) * step + min end
return math.clamp(v, min, max)
end
local function fmt(v)
if step >= 1 then return tostring(math.floor(v + 0.5)) end
return string.format("%.2f", v)
end
local function paint(animate)
local a = (value - min) / (max - min)
if animate then
R.tween(fill, 0.1, { Size = UDim2.fromScale(a, 1) })
R.tween(knob, 0.1, { Position = UDim2.fromScale(a, 0.5) })
else
R.set(fill, "Size", UDim2.fromScale(a, 1))
R.set(knob, "Position", UDim2.fromScale(a, 0.5))
end
R.set(readout, "Text", fmt(value) .. (opts.suffix or ""))
end
paint(false)
local h = newHandle("slider", shell)
function h:set(v)
v = quantise(tonumber(v) or value)
if v == value then return end
value = v
paint(true)
end
function h:get() return value end
local dragging = false
local function fromX(x)
local abs = track.AbsolutePosition.X
local w = math.max(track.AbsoluteSize.X, 1)
return quantise(min + math.clamp((x - abs) / w, 0, 1) * (max - min))
end
local function drive(x, final)
local v = fromX(x)
if v ~= value then
value = v
paint(false)
if opts.callback and opts.live ~= false then
task.spawn(function()
BX.try("ui.slider/" .. tostring(opts.name), opts.callback, v)
end)
end
end
if final and opts.callback and opts.live == false then
task.spawn(function()
BX.try("ui.slider/" .. tostring(opts.name), opts.callback, value)
end)
end
end
grab.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
dragging = true
R.tween(knob, T.FADE, { Size = UDim2.fromOffset(17, 17) })
drive(input.Position.X, false)
end)
UIS.InputChanged:Connect(function(input)
if not dragging or h._dead then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement
and input.UserInputType ~= Enum.UserInputType.Touch then return end
drive(input.Position.X, false)
end)
UIS.InputEnded:Connect(function(input)
if not dragging then return end
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
dragging = false
R.tween(knob, T.FADE, { Size = UDim2.fromOffset(14, 14) })
drive(input.Position.X, true)
end)
return h
end
function W.input(parent, opts)
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = T.VALUE_RESERVE, controlHeight = 30,
})
local box = mk("TextBox", {
Name = "Box",
Size = UDim2.fromScale(1, 1),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 0.25,
BorderSizePixel = 0,
Text = tostring(opts.value or ""),
PlaceholderText = tostring(opts.placeholder or ""),
PlaceholderColor3 = T.MUTED,
FontFace = T.FONT,
TextSize = T.SIZE_DESC,
TextColor3 = T.TEXT,
TextXAlignment = Enum.TextXAlignment.Right,
ClearTextOnFocus = false,
Parent = shell.ctrl,
}, {
T.corner(T.RADIUS_SM),
T.stroke(T.LINE, 1, T.STROKE_REST),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}),
})
local h = newHandle("input", shell)
local current = tostring(opts.value or "")
local edge = box:FindFirstChildOfClass("UIStroke")
box.Focused:Connect(function()
if edge then R.tween(edge, T.FADE, { Transparency = T.STROKE_HOVER }) end
end)
box.FocusLost:Connect(function(enterPressed)
if edge then R.tween(edge, T.FADE, { Transparency = T.STROKE_REST }) end
local v = box.Text
if v == current then return end
current = v
if opts.callback then
task.spawn(function()
BX.try("ui.input/" .. tostring(opts.name), opts.callback, v, enterPressed)
end)
end
end)
function h:set(v)
v = (v == nil) and "" or tostring(v)
if v == current then return end
current = v
R.set(box, "Text", v)
end
function h:get() return current end
h.input = box
return h
end
local openDropdown = nil
function W.setOpenDropdown(h) openDropdown = h end
function W.clearOpenDropdown(h)
if openDropdown == h then openDropdown = nil end
end
function W.closeOpenDropdown(except)
local cur = openDropdown
if cur and cur ~= except and cur.isOpen and cur:isOpen() then
cur:setOpen(false)
end
end
function W.dropdown(parent, opts)
local multi = opts.multi and true or false
local ARROW = 8
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = T.SELECT_W, controlHeight = T.SELECT_H, expandable = true,
})
local pill = mk("Frame", {
Name = "Select",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -T.CONTROL_INSET, 0.5, 0),
Size = UDim2.fromOffset(T.SELECT_W, T.SELECT_H),
BackgroundColor3 = T.SELECT_BG,
BackgroundTransparency = 0.88,
BorderSizePixel = 0,
Parent = shell.ctrl,
}, {
T.corner(T.SELECT_H / 2),
T.stroke(T.SELECT_EDGE, 1, 0.68),
})
local arrowHolder = chevron(pill, ARROW, T.SELECT_TEXT)
arrowHolder.AnchorPoint = Vector2.new(1, 0.5)
arrowHolder.Position = UDim2.new(1, -8, 0.5, 0)
local chosen = label("", T.SIZE_SELECT, T.SELECT_TEXT, false)
chosen.Name = "Chosen"
chosen.AnchorPoint = Vector2.new(0, 0.5)
chosen.Position = UDim2.new(0, 14, 0.5, 0)
chosen.Size = UDim2.new(1, -(14 + ARROW * 2 + 14), 1, 0)
chosen.TextXAlignment = Enum.TextXAlignment.Left
chosen.TextTruncate = Enum.TextTruncate.AtEnd
chosen.Parent = pill
local hit = mk("TextButton", {
Name = "Hit",
BackgroundTransparency = 1,
Text = "",
Size = UDim2.new(1, T.CARD_PAD_X * 2, 0, 0),
Position = UDim2.fromOffset(-T.CARD_PAD_X, -T.CARD_PAD_Y),
AutoButtonColor = false,
ZIndex = 5,
Parent = shell.header,
})
local function fitHit()
R.set(hit, "Size", UDim2.new(1, T.CARD_PAD_X * 2, 0,
shell.col.AbsoluteSize.Y + T.CARD_PAD_Y * 2))
end
shell.col:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitHit)
shell.header:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitHit)
fitHit()
makeHoverable(shell, hit)
local panel = mk("Frame", {
Name = "DropPanel",
BackgroundColor3 = T.ELEMENT,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 0),
Visible = false,
LayoutOrder = 2,
ZIndex = 2,
ClipsDescendants = true,
Parent = shell.root,
}, {
T.corner(T.RADIUS),
T.stroke(T.LINE, 1, 0.45),
})
T.shadow(panel, T.OVERLAY_SHADOW, 0.45)
local inner = mk("ScrollingFrame", {
Name = "Inner",
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollBarImageColor3 = T.LINE,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollingDirection = Enum.ScrollingDirection.Y,
ZIndex = 2,
Parent = panel,
}, {
mk("UIListLayout", {
Padding = UDim.new(0, 4),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
}),
})
search.Parent = panel
local function layoutInner()
local top = search.Visible and (SEARCH_H + 4) or 0
R.set(inner, "Position", UDim2.fromOffset(6, 6 + top))
R.set(inner, "Size", UDim2.new(1, -12, 1, -(12 + top)))
end
local OPT_H, MAX_SHOWN = 38, 6
local SEARCH_MIN, SEARCH_H = 8, 30
local query = ""
local search = mk("TextBox", {
Name = "Search",
Position = UDim2.fromOffset(0, 0),
Size = UDim2.new(1, 0, 0, SEARCH_H),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.975,
BorderSizePixel = 0,
Text = "",
PlaceholderText = "Search",
PlaceholderColor3 = Color3.fromRGB(129, 123, 140),
FontFace = T.FONT,
TextSize = 11,
TextColor3 = Color3.fromRGB(238, 238, 238),
TextXAlignment = Enum.TextXAlignment.Left,
ClearTextOnFocus = false,
Visible = false,
ZIndex = 4,
Parent = nil,
}, {
T.corner(9),
T.stroke(Color3.fromRGB(139, 111, 177), 1, 0.74),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}),
})
local frames, options = {}, {}
local selected = multi and {} or nil
local single, open = nil, false
local h = newHandle("dropdown", shell)
local function chosenText()
if multi then
local n, first = 0, nil
for _, o in ipairs(options) do
if selected[o] then n = n + 1 first = first or o end
end
if n == 0 then return opts.placeholder or "SELECT" end
if n == 1 then return first end
return ("%d selected"):format(n)
end
return single or (opts.placeholder or "SELECT")
end
local function isSelected(text)
if multi then return selected[text] == true end
return single == text
end
local paintRows
local function pick(text)
if multi then
selected[text] = (not selected[text]) or nil
else
single = text
end
R.set(chosen, "Text", chosenText())
paintRows()
if not multi then h:setOpen(false) end
if opts.callback then
local payload
if multi then
payload = {}
for _, o in ipairs(options) do
if selected[o] then payload[#payload + 1] = o end
end
else
payload = single
end
task.spawn(function()
BX.try("ui.dropdown/" .. tostring(opts.name), opts.callback, payload)
end)
end
end
local function ensureFrame(i)
local f = frames[i]
if f then return f end
local btn = mk("TextButton", {
Name = "Opt" .. i,
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.965,
BorderSizePixel = 0,
Size = UDim2.new(1, -4, 0, OPT_H),
LayoutOrder = i,
AutoButtonColor = false,
Text = "",
ZIndex = 3,
Parent = inner,
}, { T.corner(10), T.stroke(T.WHITE, 1, 0.94) })
local marker = mk("Frame", {
Name = "Check",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 12, 0.5, 0),
Size = UDim2.fromOffset(16, 16),
BackgroundColor3 = T.ACCENT,
BackgroundTransparency = 0.94,
BorderSizePixel = 0,
ZIndex = 4,
Parent = btn,
}, { T.corner(5), T.stroke(T.ACCENT, 1, 0.58) })
local txt = label("", 11, T.SELECT_TEXT, false)
txt.Position = UDim2.new(0, 38, 0, 0)
txt.Size = UDim2.new(1, -50, 1, 0)
txt.TextTruncate = Enum.TextTruncate.AtEnd
txt.ZIndex = 4
txt.Parent = btn
f = { btn = btn, txt = txt, marker = marker, text = nil, shown = true }
btn.MouseEnter:Connect(function()
if isSelected(f.text) then return end
R.set(btn, "BackgroundTransparency", 0.925)
end)
btn.MouseLeave:Connect(function()
if isSelected(f.text) then return end
R.set(btn, "BackgroundTransparency", 0.965)
end)
btn.Activated:Connect(function()
if h._dead or not f.text then return end
pick(f.text)
end)
frames[i] = f
return f
end
paintRows = function()
for i, o in ipairs(options) do
local f = frames[i]
if f then
local on = isSelected(o)
R.set(f.btn, "BackgroundColor3", on and Color3.fromRGB(130, 96, 181) or T.WHITE)
R.set(f.btn, "BackgroundTransparency", on and 0.8 or 0.965)
R.set(f.marker, "BackgroundTransparency", on and 0.66 or 0.94)
local mEdge = f.marker:FindFirstChildOfClass("UIStroke")
if mEdge then
R.set(mEdge, "Color", on and Color3.fromRGB(182, 156, 255) or T.ACCENT)
R.set(mEdge, "Transparency", on and 0 or 0.58)
end
local bEdge = f.btn:FindFirstChildOfClass("UIStroke")
if bEdge then
R.set(bEdge, "Color", on and T.ACCENT or T.WHITE)
R.set(bEdge, "Transparency", on and 0.66 or 0.94)
end
R.set(f.txt, "TextColor3", on and T.TEXT or T.MUTED)
R.set(f.btn, "BackgroundTransparency", on and 0 or 0.25)
R.set(f.btn, "BackgroundColor3", on and T.ACCENT_D or T.PANEL_2)
R.set(f.marker, "BackgroundColor3", on and T.ACCENT or T.PANEL_2)
end
end
end
local function matches(text)
if query == "" then return true end
return tostring(text):lower():find(query, 1, true) ~= nil
end
local function applyFilter()
local n = 0
for i, o in ipairs(options) do
local f = frames[i]
if f then
local vis = matches(o)
f.shown = vis
R.set(f.btn, "Visible", vis)
if vis then n = n + 1 end
end
end
return n
end
local function wantHeight()
local n = 0
for i = 1, #options do
local f = frames[i]
if not f or f.shown ~= false then n = n + 1 end
end
local shown = math.min(math.max(n, 1), MAX_SHOWN)
local base = shown * (OPT_H + 4) + 12
return base + (search.Visible and (SEARCH_H + 4) or 0)
end
search:GetPropertyChangedSignal("Text"):Connect(function()
query = tostring(search.Text):lower()
local n = applyFilter()
if open then
R.tween(panel, T.FADE, { Size = UDim2.new(1, 0, 0, wantHeight()) })
end
return n
end)
function h:setOpen(on)
on = on and true or false
if on == open then return end
if on then
open = true
if search.Visible and query ~= "" then
query = ""
R.set(search, "Text", "")
applyFilter()
end
W.closeOpenDropdown(h)
R.set(panel, "Visible", true)
R.set(panel, "Size", UDim2.new(1, 0, 0, 0))
R.tween(panel, T.MOVE, {
Size = UDim2.new(1, 0, 0, wantHeight()),
}, T.EASE_UI)
W.setOpenDropdown(h)
else
open = false
R.tween(panel, T.MOVE, { Size = UDim2.new(1, 0, 0, 0) })
R.call(function()
task.delay(T.MOVE, function()
if not open then R.set(panel, "Visible", false) end
end)
end)
W.clearOpenDropdown(h)
end
R.tween(arrowHolder, T.MOVE, { Rotation = on and 180 or 0 })
end
function h:isOpen() return open end
shell.root:GetPropertyChangedSignal("Visible"):Connect(function()
if open and not shell.root.Visible then h:setOpen(false) end
end)
hit.Activated:Connect(function()
if h._dead then return end
h:setOpen(not open)
end)
function h:setOptions(newOptions)
if type(newOptions) ~= "table" then return false end
local same = #newOptions == #options
if same then
for i = 1, #newOptions do
if newOptions[i] ~= options[i] then same = false break end
end
end
if same then return true end
options = table.clone(newOptions)
for i = 1, #options do
local f = ensureFrame(i)
if f.text ~= options[i] then
f.text = options[i]
R.set(f.txt, "Text", options[i])
end
R.set(f.btn, "Visible", true)
end
for i = #options + 1, #frames do
frames[i].text = nil
R.set(frames[i].btn, "Visible", false)
end
if multi then
local keep = {}
for _, o in ipairs(options) do
if selected[o] then keep[o] = true end
end
selected = keep
elseif single and not table.find(options, single) then
single = nil
end
R.set(search, "Visible", #options >= SEARCH_MIN)
layoutInner()
applyFilter()
R.set(chosen, "Text", chosenText())
paintRows()
if open then
open = false
h:setOpen(true)
end
return true
end
function h:set(v)
if multi then
local want = {}
if type(v) == "table" then
for _, o in ipairs(v) do want[o] = true end
elseif v ~= nil then
want[v] = true
end
selected = want
else
single = (v ~= nil) and tostring(v) or nil
end
R.set(chosen, "Text", chosenText())
paintRows()
end
function h:get()
if multi then
local out = {}
for _, o in ipairs(options) do
if selected[o] then out[#out + 1] = o end
end
return out
end
return single
end
function h:options() return table.clone(options) end
h:setOptions(opts.options or {})
if opts.value ~= nil then h:set(opts.value) end
R.set(chosen, "Text", chosenText())
return h
end
function W.richCard(parent, opts)
local root = mk("Frame", {
Name = "Rich_" .. tostring(opts.name or "?"),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = opts.order or 0,
Parent = parent,
}, {
T.corner(T.RADIUS),
T.gradient(ColorSequence.new(T.COMMUNITY_TOP, T.COMMUNITY_BOT), T.CARD_ROT),
T.stroke(T.COMMUNITY_EDGE, 1, 0),
mk("UIPadding", {
PaddingLeft = UDim.new(0, T.CARD_PAD_X), PaddingRight = UDim.new(0, T.CARD_PAD_X),
PaddingTop = UDim.new(0, T.CARD_PAD_Y), PaddingBottom = UDim.new(0, T.CARD_PAD_Y),
}),
mk("UIListLayout", {
Padding = UDim.new(0, 7),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local title = label(opts.name, 19, T.CARD_TITLE, true)
title.Size = UDim2.new(1, 0, 0, 0)
title.AutomaticSize = Enum.AutomaticSize.Y
title.TextYAlignment = Enum.TextYAlignment.Top
title.LayoutOrder = 1
title.Parent = root
local body = label(tostring(opts.text or ""), T.SIZE_DESC, T.MUTED, false)
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.TextWrapped = true
body.TextYAlignment = Enum.TextYAlignment.Top
body.LayoutOrder = 2
body.Parent = root
local h = newHandle("richCard", { root = root, title = title, desc = body })
if opts.action then
local cta = mk("TextButton", {
Name = "Action",
Text = "",
AutoButtonColor = false,
BackgroundColor3 = T.CTA_BG,
BorderSizePixel = 0,
Size = UDim2.fromOffset(0, 37),
AutomaticSize = Enum.AutomaticSize.X,
LayoutOrder = 3,
Parent = root,
}, {
T.corner(12),
T.stroke(T.CTA_EDGE, 1, 0),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
}),
})
local ctaLabel = label(tostring(opts.action.label or "Open"), 13,
T.CTA_TEXT, true)
ctaLabel.Size = UDim2.fromOffset(0, 37)
ctaLabel.AutomaticSize = Enum.AutomaticSize.X
ctaLabel.Parent = cta
cta.MouseEnter:Connect(function()
R.tween(cta, T.FADE, { BackgroundColor3 = T.CTA_BG_H })
end)
cta.MouseLeave:Connect(function()
R.tween(cta, T.FADE, { BackgroundColor3 = T.CTA_BG })
end)
cta.Activated:Connect(function()
if opts.action.callback then
task.spawn(function()
BX.try("ui.richCard/" .. tostring(opts.action.label),
opts.action.callback)
end)
end
end)
h.action = cta
end
function h:set(v) R.set(body, "Text", tostring(v)) end
function h:get() return body.Text end
return h
end
function W.listCard(parent, opts)
local root = mk("Frame", {
Name = "List_" .. tostring(opts.name or "?"),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = opts.order or 0,
Parent = parent,
}, {
T.corner(T.RADIUS),
T.gradient(ColorSequence.new(T.UPDATE_TOP, T.UPDATE_BOT), T.CARD_ROT),
T.stroke(T.CARD_EDGE, 1, 0),
mk("UIPadding", {
PaddingLeft = UDim.new(0, T.CARD_PAD_X), PaddingRight = UDim.new(0, T.CARD_PAD_X),
PaddingTop = UDim.new(0, T.CARD_PAD_Y), PaddingBottom = UDim.new(0, T.CARD_PAD_Y),
}),
mk("UIListLayout", {
Padding = UDim.new(0, 12),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local head = mk("Frame", {
Name = "Head",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 24),
LayoutOrder = 1,
Parent = root,
})
local title = label(opts.name, 17, T.TEXT, true)
title.Size = UDim2.new(1, -120, 1, 0)
title.Parent = head
if opts.badge then
local pill = mk("Frame", {
Name = "Badge",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, 0, 0.5, 0),
Size = UDim2.fromOffset(0, 20),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = T.BADGE_BG,
BackgroundTransparency = 0.9,
BorderSizePixel = 0,
Parent = head,
}, {
T.corner(10),
T.stroke(T.ACCENT, 1, 0.76),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7),
}),
})
local bl = label(string.upper(tostring(opts.badge)), 9, T.ACCENT, true)
bl.Size = UDim2.fromOffset(0, 20)
bl.AutomaticSize = Enum.AutomaticSize.X
bl.Parent = pill
end
local list = mk("Frame", {
Name = "Rows",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = 2,
Parent = root,
}, {
mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
})
local rows = opts.rows or {}
for i, row in ipairs(rows) do
local line = mk("Frame", {
Name = "Row" .. i,
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 34),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = i,
Parent = list,
}, {
mk("UIPadding", {
PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
}),
})
local tag = label(string.upper(tostring(row[1])), 9, T.ROW_TAG, true)
tag.Position = UDim2.fromOffset(0, 0)
tag.Size = UDim2.new(0, 70, 0, 20)
tag.TextYAlignment = Enum.TextYAlignment.Top
tag.Parent = line
local body = label(tostring(row[2]), 12,
(i == #rows) and T.ROW_TEXT_LAST or T.ROW_TEXT, false)
body.Position = UDim2.fromOffset(80, 0)
body.Size = UDim2.new(1, -80, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.TextWrapped = true
body.TextYAlignment = Enum.TextYAlignment.Top
body.Parent = line
if i < #rows then
mk("Frame", {
Name = "Rule",
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 0, 1, 0),
Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.955,
BorderSizePixel = 0,
Parent = line,
})
end
end
local h = newHandle("listCard", { root = root, title = title })
function h:set() end
function h:get() return nil end
return h
end
function W.popover(anchor, items, opts)
opts = opts or {}
local width = opts.width or 200
local ROW, PADV = 34, 6
local panel = mk("Frame", {
Name = "Popover",
BackgroundColor3 = T.ELEMENT,
BorderSizePixel = 0,
Size = UDim2.fromOffset(width, 0),
Visible = false,
ClipsDescendants = true,
ZIndex = T.OVERLAY_Z + 10,
Parent = ctx.overlay,
}, {
T.corner(T.RADIUS),
T.stroke(T.LINE, 1, 0.4),
mk("UIListLayout", {
Padding = UDim.new(0, 2),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, PADV), PaddingBottom = UDim.new(0, PADV),
PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
}),
})
T.shadow(panel, T.OVERLAY_SHADOW, 0.4)
local h = { _open = false }
local rows = 0
for i, item in ipairs(items or {}) do
if item.divider then
rows = rows + 1
mk("Frame", {
Name = "Divider",
Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.LINE,
BackgroundTransparency = 0.4,
BorderSizePixel = 0,
LayoutOrder = i,
ZIndex = T.OVERLAY_Z + 11,
Parent = panel,
})
else
rows = rows + 1
local tone = (item.tone == "warn" and T.WARN)
or (item.tone == "muted" and T.MUTED) or T.TEXT
local btn = mk("TextButton", {
Name = "Item" .. i,
Text = "",
AutoButtonColor = false,
BackgroundColor3 = T.ELEMENT_H,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, ROW),
LayoutOrder = i,
ZIndex = T.OVERLAY_Z + 11,
Parent = panel,
}, { T.corner(T.RADIUS_SM) })
local txt = label(tostring(item.text or ""), T.SIZE_DESC, tone, false)
txt.Position = UDim2.new(0, 10, 0, 0)
txt.Size = UDim2.new(1, -20, 1, 0)
txt.ZIndex = T.OVERLAY_Z + 12
txt.Parent = btn
btn.MouseEnter:Connect(function()
R.tween(btn, T.FADE, { BackgroundTransparency = 0 })
end)
btn.MouseLeave:Connect(function()
R.tween(btn, T.FADE, { BackgroundTransparency = 1 })
end)
btn.Activated:Connect(function()
h:setOpen(false)
if item.callback then
task.spawn(function()
BX.try("ui.popover/" .. tostring(item.text), item.callback)
end)
end
end)
end
end
local function contentHeight()
local n, dividers = 0, 0
for _, item in ipairs(items or {}) do
if item.divider then dividers = dividers + 1 else n = n + 1 end
end
return n * ROW + dividers * 1 + (rows - 1) * 2 + PADV * 2
end
function h:setOpen(on)
on = on and true or false
if on == h._open then return end
if on and not (ctx.overlay and ctx.root and anchor) then return end
h._open = on
if on then
W.closeOpenDropdown(nil)
local k = scaleK()
local a, rootAbs = anchor.AbsolutePosition, ctx.root.AbsolutePosition
local x = (a.X - rootAbs.X) / k
local y = (a.Y - rootAbs.Y) / k
local aH = anchor.AbsoluteSize.Y / k
local wantH = contentHeight()
local top = (opts.align == "above") and (y - wantH - 8) or (y + aH + 8)
R.set(panel, "Visible", true)
R.set(panel, "Position", UDim2.fromOffset(x, top + 6))
R.set(panel, "Size", UDim2.fromOffset(width, 0))
R.tween(panel, T.MOVE, {
Size = UDim2.fromOffset(width, wantH),
Position = UDim2.fromOffset(x, top),
}, T.EASE_UI)
else
R.tween(panel, T.MOVE, { Size = UDim2.fromOffset(width, 0) })
R.call(function()
task.delay(T.MOVE, function()
if not h._open then R.set(panel, "Visible", false) end
end)
end)
end
end
function h:isOpen() return h._open end
function h:toggle() h:setOpen(not h._open) end
function h:destroy() R.call(function() panel:Destroy() end) end
return h
end
function W.row(parent, opts)
local root = mk("Frame", {
Name = "Group",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = (opts and opts.order) or 0,
Parent = parent,
}, {
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
Padding = UDim.new(0, T.GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
VerticalAlignment = Enum.VerticalAlignment.Top,
}),
})
local h = newHandle("row", { root = root })
local cells = {}
local function cell()
local c = mk("Frame", {
Name = "Cell" .. (#cells + 1),
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = #cells + 1,
Parent = root,
})
cells[#cells + 1] = c
local n = #cells
for _, existing in ipairs(cells) do
R.set(existing, "Size",
UDim2.new(1 / n, -(T.GAP * (n - 1)) / n, 0, 0))
end
return c
end
function h:toggle(o) return W.toggle(cell(), o) end
function h:button(o) return W.button(cell(), o) end
function h:label(o)  return W.label(cell(), o) end
return h
end
return W
end)
BX.module("ui.lib", function(BX)
local svc = BX.require("core.services")
local exec = BX.require("core.exec")
local dev = BX.require("core.device")
local T   = BX.require("ui.lib.theme")
local R   = BX.require("ui.lib.render")
local W   = BX.require("ui.lib.widgets")
local log = BX.require("boot.log").for_module("ui.lib")
local M = {}
M.theme, M.render, M.widgets = T, R, W
local notifier = nil
function M.setNotifier(fn) notifier = fn end
local function islandNotify(title, body, o)
local island = BX._loaded["ui.island"]
if not island then
local ok, mod = pcall(BX.require, "ui.island")
island = ok and mod or nil
end
if not island or type(island.show) ~= "function" then return false end
island.show(o.key or "notify", {
title = tostring(title or "BlyxoHub"),
sub = body and tostring(body) or nil,
tone = o.tone or "normal",
hold = o.hold or 4,
pulse = o.pulse,
})
return true
end
function M.notify(title, body, o)
o = o or {}
if notifier then
return (BX.try("ui.notify", notifier, title, body, o))
end
local ok = BX.try("ui.notify.island", islandNotify, title, body, o)
if not ok then
log.info("notify (no surface): %s - %s", tostring(title), tostring(body))
end
return ok
end
function M.build(fn, timeout) return R.build(fn, timeout) end
local UIS = svc.UserInputService
local mk = W.mk
function M.window(opts)
opts = opts or {}
R.start()
local narrow = dev.smallScreen or dev.isTouch
local wantW = opts.width or (narrow and T.WIN_W_NARROW or T.WIN_W)
local wantH = opts.height or (narrow and T.WIN_H_NARROW or T.WIN_H)
local gui = mk("ScreenGui", {
Name = opts.guiName or ("Blyxo_" .. tostring(math.random(1e6, 9e6))),
ResetOnSpawn = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
DisplayOrder = 1000,
IgnoreGuiInset = true,
})
gui.Parent = exec.hiddenParent()
local dim = mk("Frame", {
Name = "Backdrop",
Size = UDim2.fromScale(1, 1),
BackgroundColor3 = T.BLACK,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Active = false,
ZIndex = 0,
Parent = gui,
}, {
mk("UIGradient", { Rotation = 90, Transparency = T.DIM_GRADIENT }),
})
local sideW     = narrow and 0 or T.SIDE_W
local sideGap   = narrow and 0 or T.SIDE_COL_GAP
local searchH   = narrow and 0 or T.SEARCH_H
local searchGap = narrow and 0 or T.SEARCH_GAP
local fullW = wantW + (sideW + sideGap) * 2
local fullH = wantH + searchH + searchGap
local holder = mk("Frame", {
Name = "Holder",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(fullW, fullH),
BackgroundTransparency = 1,
Parent = gui,
})
local fit = T.fitScale(fullW, fullH)
local scale = mk("UIScale", { Scale = fit * 0.96, Parent = holder })
local root = mk("Frame", {
Name = "Window",
Position = UDim2.fromOffset(sideW + sideGap, 0),
Size = UDim2.fromOffset(wantW, wantH),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 0,
BorderSizePixel = 0,
ClipsDescendants = true,
Parent = holder,
}, {
T.corner(T.RADIUS_WIN),
})
T.shadow(root, T.SHADOW_BLUR, T.SHADOW_ALPHA)
BX.try("ui.lib.bloom", function()
local bloom = T.shadow(root, T.BLOOM_BLUR, T.BLOOM_ALPHA)
if bloom then bloom.Color = T.ACCENT end
end)
local overlay = mk("Frame", {
Name = "Overlay",
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
ClipsDescendants = false,
ZIndex = T.OVERLAY_Z,
Parent = root,
})
W.setContext({ overlay = overlay, scale = scale, root = root })
local win = {}
local bar = mk("Frame", {
Name = "TitleBar",
Size = UDim2.new(1, 0, 0, T.TITLEBAR_H),
BackgroundTransparency = 1,
ZIndex = 2,
Parent = root,
})
local logo = mk("ImageLabel", {
Name = "Logo",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, T.TITLEBAR_PAD_X, 0.5, 0),
Size = UDim2.fromOffset(T.LOGO_SIZE, T.LOGO_SIZE),
BackgroundTransparency = 1,
Image = T.asset(T.LOGO_FILE, T.LOGO_FLAT),
ImageColor3 = T.WHITE,
ScaleType = Enum.ScaleType.Fit,
Parent = bar,
})
local lockup = mk("Frame", {
Name = "Lockup",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, T.PAD + 38, 0.5, 0),
Size = UDim2.fromOffset(0, 40),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundTransparency = 1,
Parent = bar,
}, {
mk("UIListLayout", {
Padding = UDim.new(0, 1),
SortOrder = Enum.SortOrder.LayoutOrder,
VerticalAlignment = Enum.VerticalAlignment.Center,
}),
})
local title = mk("TextLabel", {
Name = "Title",
BackgroundTransparency = 1,
Text = tostring(opts.title or "BlyxoHub"),
FontFace = T.FONT_BOLD,
TextSize = T.SIZE_TITLE,
TextColor3 = T.WHITE,
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.fromOffset(0, 22),
AutomaticSize = Enum.AutomaticSize.X,
LayoutOrder = 1,
Parent = lockup,
}, {
T.gradient(T.WORDMARK_GRADIENT, 0),
})
mk("TextLabel", {
Name = "Subtitle",
BackgroundTransparency = 1,
Text = tostring(opts.subtitle or ""),
FontFace = T.FONT,
TextSize = T.SIZE_SUB,
TextColor3 = T.MUTED,
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.fromOffset(0, 16),
AutomaticSize = Enum.AutomaticSize.X,
Visible = opts.subtitle ~= nil,
LayoutOrder = 2,
Parent = lockup,
})
local badgePill = nil
if opts.badge then
local pill = mk("Frame", {
Name = "Badge",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
Size = UDim2.fromOffset(0, 27),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = Color3.fromRGB(235, 231, 245),
BackgroundTransparency = 0.1,
BorderSizePixel = 0,
Parent = bar,
}, {
T.corner(14),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11),
}),
})
mk("TextLabel", {
BackgroundTransparency = 1,
Text = tostring(opts.badge),
FontFace = T.FONT_BOLD,
TextSize = T.SIZE_BADGE,
TextColor3 = Color3.fromRGB(25, 21, 31),
Size = UDim2.fromOffset(0, 27),
AutomaticSize = Enum.AutomaticSize.X,
Parent = pill,
})
local function fitPill()
R.set(pill, "Position",
UDim2.new(0, T.PAD + 38 + lockup.AbsoluteSize.X + 12, 0.5, 0))
end
lockup:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPill)
fitPill()
badgePill = pill
end
local controls = mk("Frame", {
Name = "Controls",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -(T.PAD - 8), 0.5, 0),
Size = UDim2.fromOffset(0, 32),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundTransparency = 1,
Parent = bar,
}, {
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
Padding = UDim.new(0, 2),
SortOrder = Enum.SortOrder.LayoutOrder,
VerticalAlignment = Enum.VerticalAlignment.Center,
}),
})
local function iconButton(order, draw)
local b = mk("TextButton", {
Name = "Ctl" .. order,
Text = "",
AutoButtonColor = false,
BackgroundTransparency = 1,
Size = UDim2.fromOffset(32, 32),
LayoutOrder = order,
Parent = controls,
})
local marks = draw(b)
b.MouseEnter:Connect(function()
for _, m in ipairs(marks) do R.tween(m, T.FADE, { BackgroundColor3 = T.TEXT }) end
end)
b.MouseLeave:Connect(function()
for _, m in ipairs(marks) do R.tween(m, T.FADE, { BackgroundColor3 = T.MUTED }) end
end)
return b
end
local function barMark(parent, rot)
return mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(13, 1.6),
BackgroundColor3 = T.MUTED,
BorderSizePixel = 0,
Rotation = rot,
Parent = parent,
}, { T.corner(1) })
end
local minBtn = iconButton(1, function(b) return { barMark(b, 0) } end)
local closeBtn = iconButton(2, function(b)
return { barMark(b, 45), barMark(b, -45) }
end)
local capsuleSlot = mk("Frame", {
Name = "CapsuleSlot",
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, 2),
Size = UDim2.fromOffset(320, 46),
BackgroundTransparency = 1,
Parent = bar,
})
win.capsuleSlot = capsuleSlot
local railW = narrow and 0 or sideW
local railH = narrow and T.TABBAR_H or 0
local function column(name, xOffset)
return mk("ScrollingFrame", {
Name = name,
Position = UDim2.fromOffset(xOffset, 0),
Size = UDim2.new(0, sideW, 1, -(searchH + searchGap)
- (opts.user and T.USER_CHIP_H or 0)),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 0,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollingDirection = Enum.ScrollingDirection.Y,
Parent = holder,
}, {
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Vertical,
Padding = UDim.new(0, T.SIDE_GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", { PaddingTop = UDim.new(0, T.TITLEBAR_H - 24) }),
})
end
local rail, railRight
if narrow then
rail = mk("ScrollingFrame", {
Name = "Tabs",
Position = UDim2.new(0, 0, 0, T.TITLEBAR_H + 1),
Size = UDim2.new(1, 0, 0, railH),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 0,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.X,
ScrollingDirection = Enum.ScrollingDirection.X,
Parent = root,
}, {
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
Padding = UDim.new(0, T.TAB_GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14),
PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
}),
})
else
rail = column("TabsLeft", 0)
railRight = column("TabsRight", sideW + sideGap + wantW + sideGap)
end
if not narrow then
local _ = nil
if opts.user then
local chip = mk("TextButton", {
Name = "UserChip",
Text = "",
AutoButtonColor = false,
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 2, 0, wantH - 4),
Size = UDim2.new(0, railW - 4, 0, T.USER_CHIP_H),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.957,
BorderSizePixel = 0,
Parent = holder,
}, {
T.corner(T.USER_CHIP_RADIUS),
T.stroke(T.WHITE, 1, 0.9),
})
chip.MouseEnter:Connect(function()
R.tween(chip, T.FADE, { BackgroundTransparency = 0.94 })
end)
chip.MouseLeave:Connect(function()
R.tween(chip, T.FADE, { BackgroundTransparency = 0.957 })
end)
win.userChip = chip
R.set(chip, "ZIndex", 4)
local COLLAPSED, EXPANDED = T.USER_CHIP_H, 96
local DETAILS_H = 38
local expanded = false
R.set(chip, "ClipsDescendants", true)
mk("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding = UDim.new(0, 0),
Parent = chip,
})
mk("UIPadding", {
PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
Parent = chip,
})
local details = mk("Frame", {
Name = "Details",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
LayoutOrder = 1,
Visible = false,
Parent = chip,
}, {
mk("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding = UDim.new(0, 3),
}),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
}),
})
local function detailRow(order, key, value)
local row = mk("Frame", {
Name = key,
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 14),
LayoutOrder = order,
Parent = details,
})
mk("TextLabel", {
BackgroundTransparency = 1,
Text = key,
FontFace = T.FONT,
TextSize = 10,
TextColor3 = Color3.fromRGB(143, 137, 152),
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.new(0.5, 0, 1, 0),
Parent = row,
})
local val = mk("TextLabel", {
Name = "Value",
BackgroundTransparency = 1,
Text = tostring(value),
FontFace = T.FONT_BOLD,
TextSize = 10,
TextColor3 = Color3.fromRGB(217, 211, 225),
TextXAlignment = Enum.TextXAlignment.Right,
TextTruncate = Enum.TextTruncate.AtEnd,
AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, 0, 0, 0),
Size = UDim2.new(0.55, 0, 1, 0),
Parent = row,
})
return val
end
local execName = "Unknown"
BX.try("ui.lib.chipExec", function()
local n = exec.name
if type(n) == "string" and #n > 0 then execName = n end
end)
local deviceName = "PC"
BX.try("ui.lib.chipDevice", function()
if dev.isTouch then
deviceName = dev.smallScreen and "Phone" or "Tablet"
end
end)
detailRow(1, "Executor", execName)
detailRow(2, "Device", deviceName)
local base = mk("Frame", {
Name = "Base",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 38),
LayoutOrder = 2,
Parent = chip,
})
mk("ImageLabel", {
Name = "Avatar",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 8, 0.5, 0),
Size = UDim2.fromOffset(34, 34),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Image = tostring(opts.userImage or ""),
Parent = base,
}, {
T.corner(17),
T.gradient(ColorSequence.new(
Color3.fromRGB(74, 70, 84), Color3.fromRGB(36, 33, 42)), 55),
T.stroke(T.WHITE, 1, 0.84),
})
local realName = tostring(opts.user)
local masked = string.rep("*", math.clamp(#realName, 6, 12))
local revealed = false
local nameLabel = mk("TextLabel", {
Name = "Name",
BackgroundTransparency = 1,
Text = masked,
FontFace = T.FONT_BOLD,
TextSize = 12,
TextColor3 = Color3.fromRGB(232, 230, 237),
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
Position = UDim2.new(0, 50, 0, 0),
Size = UDim2.new(1, -(50 + 34), 1, 0),
Parent = base,
})
local eye = mk("TextButton", {
Name = "Reveal",
Text = "",
AutoButtonColor = false,
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -2, 0.5, 0),
Size = UDim2.fromOffset(26, 26),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.965,
BorderSizePixel = 0,
Parent = base,
}, { T.corner(8), T.stroke(T.WHITE, 1, 0.9) })
local ring = mk("Frame", {
Name = "Ring",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(13, 9),
BackgroundTransparency = 1,
Parent = eye,
}, { T.corner(5), T.stroke(Color3.fromRGB(170, 162, 178), 1, 0) })
mk("Frame", {
Name = "Pupil",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(4, 4),
BackgroundColor3 = Color3.fromRGB(170, 162, 178),
BorderSizePixel = 0,
Parent = ring,
}, { T.corner(2) })
local slash = mk("Frame", {
Name = "Slash",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(17, 1.5),
Rotation = -35,
BackgroundColor3 = Color3.fromRGB(170, 162, 178),
BorderSizePixel = 0,
Parent = eye,
}, { T.corner(1) })
local function paintName()
R.set(nameLabel, "Text", revealed and realName or masked)
R.set(slash, "Visible", not revealed)
end
eye.Activated:Connect(function()
revealed = not revealed
paintName()
end)
local function setExpanded(on)
on = on and true or false
if on == expanded then return end
expanded = on
if on then R.set(details, "Visible", true) end
R.tween(chip, T.MOVE, {
Size = UDim2.new(0, railW - 20, 0, on and EXPANDED or COLLAPSED),
}, T.EASE_UI)
R.tween(details, T.MOVE, {
Size = UDim2.new(1, 0, 0, on and DETAILS_H or 0),
}, T.EASE_UI)
if not on then
R.call(function()
task.delay(T.MOVE, function()
if not expanded then R.set(details, "Visible", false) end
end)
end)
end
end
chip.Activated:Connect(function() setExpanded(not expanded) end)
win.setChipExpanded = function(_, on) setExpanded(on) end
end
end
local body = mk("Frame", {
Name = "Body",
Position = UDim2.new(0, railW, 0, T.TITLEBAR_H + railH),
Size = UDim2.new(1, -railW, 1, -(T.TITLEBAR_H + railH)),
BackgroundColor3 = T.WORKSPACE,
BackgroundTransparency = narrow and 1 or 0,
BorderSizePixel = 0,
Parent = root,
}, { T.corner(narrow and 0 or T.RADIUS_WIN) })
if not narrow then T.roundTopLeftOnly(body, T.RADIUS_WIN, T.WORKSPACE) end
mk("Frame", {
Name = "PageFade",
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 0, 1, 0),
Size = UDim2.new(1, 0, 0, 86),
BackgroundColor3 = T.WORKSPACE,
BorderSizePixel = 0,
Active = false,
ZIndex = 6,
Parent = body,
}, {
T.gradient(ColorSequence.new(T.WORKSPACE, T.WORKSPACE), 90,
NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.78, 0.1),
NumberSequenceKeypoint.new(1, 0),
})),
})
do
local dragging, startPos, startMouse = false, nil, nil
bar.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
dragging = true
startPos, startMouse = holder.Position, input.Position
end)
UIS.InputChanged:Connect(function(input)
if not dragging then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement
and input.UserInputType ~= Enum.UserInputType.Touch then return end
local d = input.Position - startMouse
R.set(holder, "Position", UDim2.new(
startPos.X.Scale, startPos.X.Offset + d.X,
startPos.Y.Scale, startPos.Y.Offset + d.Y))
end)
UIS.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1
or input.UserInputType == Enum.UserInputType.Touch then
if dragging and win.rememberPosition then win.rememberPosition() end
dragging = false
end
end)
end
win.gui, win.root, win.overlay, win.scale = gui, root, overlay, scale
win.notify = function(_, title, body, o)
if type(_) == "string" then return M.notify(_, title, body) end
return M.notify(title, body, o)
end
local tabs, order, current = {}, 0, nil
local visible = not opts.startHidden
if opts.startHidden then
gui.Enabled = false
dim.BackgroundTransparency = 1
end
function win:setVisible(on)
on = on and true or false
if on == visible then return end
visible = on
if not on then W.closeOpenDropdown(nil) end
R.tween(dim, T.FADE, { BackgroundTransparency = on and T.DIM_ALPHA or 1 })
if on then
R.set(gui, "Enabled", true)
else
R.call(function()
task.delay(T.FADE, function()
if not visible then R.set(gui, "Enabled", false) end
end)
end)
end
end
function win:isVisible() return visible end
function win:toggle()
if visible then
if not self:minimise() then self:setVisible(false) end
else
if not self:restore() then self:setVisible(true) end
end
end
function win:destroy()
R.call(function() gui:Destroy() end)
end
minBtn.Activated:Connect(function()
if not win:minimise() then win:setVisible(false) end
end)
closeBtn.Activated:Connect(function()
if opts.onClose then
task.spawn(function() BX.try("ui.window.close", opts.onClose) end)
else
win:setVisible(false)
end
end)
local function selectTab(name)
if current == name then return end
current = name
W.closeOpenDropdown(nil)
if type(win.clearSearch) == "function" then
BX.try("ui.lib.clearSearch", win.clearSearch)
end
local instant = dev.lite()
for n, t in pairs(tabs) do
local on = (n == name)
if on then
R.set(t.wrap, "Visible", true)
if instant then
R.set(t.wrap, "GroupTransparency", 0)
R.set(t.wrap, "Position", UDim2.fromOffset(0, 0))
else
R.set(t.wrap, "GroupTransparency", 1)
R.set(t.wrap, "Position", UDim2.fromOffset(0, T.SLIDE_IN))
R.tween(t.wrap, T.TAB_FADE, {
GroupTransparency = 0,
Position = UDim2.fromOffset(0, 0),
}, T.EASE_UI)
end
elseif t.wrap.Visible then
if instant then
R.set(t.wrap, "Visible", false)
else
R.tween(t.wrap, T.TAB_FADE * 0.6, { GroupTransparency = 1 })
local wrap, who = t.wrap, n
R.call(function()
task.delay(T.TAB_FADE, function()
if current ~= who then R.set(wrap, "Visible", false) end
end)
end)
end
end
local tabEdge = t.button:FindFirstChildOfClass("UIStroke")
if narrow then
R.tween(t.button, T.FADE, {
BackgroundColor3 = T.WHITE,
BackgroundTransparency = on and 0 or 1,
})
R.tween(t.label, T.FADE, { TextColor3 = on and T.TAB_ON or T.TAB_OFF })
if tabEdge then
R.tween(tabEdge, T.FADE, { Transparency = on and 0 or 1 })
end
else
R.tween(t.button, T.FADE, {
BackgroundColor3 = on and T.SIDE_BG_ON or T.SIDE_BG,
BackgroundTransparency = 0,
})
R.set(t.label, "TextColor3", T.SIDE_TEXT)
if tabEdge then
R.tween(tabEdge, T.FADE, {
Color = on and T.SIDE_EDGE_ON or T.SIDE_EDGE,
})
end
end
end
end
win.select = function(_, name) selectTab(name) end
function win:selected() return current end
local quickRail = mk("Frame", {
Name = "QuickActionRail",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -12, 0.5, 0),
Size = UDim2.fromOffset(74, 286),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 0.02,
BorderSizePixel = 0,
ZIndex = 100,
Parent = gui,
}, {
T.corner(8),
T.stroke(T.LINE, 1, 0.1),
mk("UIPadding", {
PaddingTop = UDim.new(0, 12),
PaddingBottom = UDim.new(0, 12),
}),
mk("UIListLayout", {
HorizontalAlignment = Enum.HorizontalAlignment.Center,
VerticalAlignment = Enum.VerticalAlignment.Top,
Padding = UDim.new(0, 10),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local function quickAction(order, labelText, colour, target, badgeText)
local button = mk("TextButton", {
Name = "Quick_" .. target,
LayoutOrder = order,
Size = UDim2.fromOffset(48, 48),
BackgroundColor3 = colour,
BorderSizePixel = 0,
AutoButtonColor = false,
Text = labelText,
TextColor3 = T.WHITE,
FontFace = T.FONT_BOLD,
TextSize = 22,
ZIndex = 101,
Parent = quickRail,
}, { T.corner(6), T.stroke(T.BLACK, 2, 0) })
button.Activated:Connect(function() win:select(target) end)
button.MouseEnter:Connect(function() R.tween(button, T.FADE, {
BackgroundColor3 = colour:Lerp(T.WHITE, 0.12),
}) end)
button.MouseLeave:Connect(function() R.tween(button, T.FADE, {
BackgroundColor3 = colour,
}) end)
if badgeText then
local badge = mk("TextLabel", {
Name = "Badge",
AnchorPoint = Vector2.new(1, 1),
Position = UDim2.new(1, 7, 1, 7),
Size = UDim2.fromOffset(22, 22),
BackgroundColor3 = Color3.fromRGB(79, 212, 108),
BorderSizePixel = 0,
Text = badgeText,
TextColor3 = Color3.fromRGB(16, 35, 25),
FontFace = T.FONT_BOLD,
TextSize = 12,
ZIndex = 102,
Parent = button,
}, { T.corner(11), T.stroke(T.PANEL, 2, 0) })
end
return button
end
quickAction(1, "◆", Color3.fromRGB(28, 120, 168), "Event")
quickAction(2, "◉", Color3.fromRGB(215, 38, 56), "Main", "6")
quickAction(3, "✿", Color3.fromRGB(240, 139, 47), "Farm")
quickAction(4, "ϟ", Color3.fromRGB(137, 87, 216), "Misc")
function win:tab(name)
if tabs[name] then return tabs[name].api end
order = order + 1
local side = (opts.tabSide and opts.tabSide[name]) or "left"
local host = (not narrow and side == "right" and railRight) or rail
local btn = mk("TextButton", {
Name = "Tab_" .. name,
Text = "",
AutoButtonColor = false,
BackgroundColor3 = narrow and T.ELEMENT or T.SIDE_BG,
BackgroundTransparency = narrow and 1 or 0,
BorderSizePixel = 0,
LayoutOrder = order,
Size = narrow and UDim2.fromOffset(104, railH - 16)
or UDim2.new(1, 0, 0, T.SIDE_BTN_H),
Parent = host,
}, narrow and {
T.corner(T.RADIUS_TAB),
T.gradient(T.TAB_ACTIVE, T.TAB_ACTIVE_ROT),
T.stroke(T.TAB_EDGE, 1, 1),
} or {
T.corner(T.SIDE_RADIUS),
T.stroke(T.SIDE_EDGE, T.SIDE_STROKE_W, 0),
})
local lbl = mk("TextLabel", {
BackgroundTransparency = 1,
Text = name,
FontFace = narrow and T.FONT or T.FONT_BOLD,
TextSize = narrow and T.SIZE_TAB or T.SIDE_TEXT_SIZE,
TextColor3 = narrow and T.TAB_OFF or T.SIDE_TEXT,
TextXAlignment = Enum.TextXAlignment.Center,
Position = UDim2.new(0, 0, 0, 0),
Size = UDim2.fromScale(1, 1),
Parent = btn,
})
local wrap = mk("CanvasGroup", {
Name = "Page_" .. name,
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
GroupTransparency = 1,
Visible = false,
Parent = body,
})
local page = mk("ScrollingFrame", {
Name = "Scroll",
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollBarImageColor3 = T.LINE,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollingDirection = Enum.ScrollingDirection.Y,
Parent = wrap,
}, {
mk("UIListLayout", {
Padding = UDim.new(0, T.GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, T.WORKSPACE_PAD_Y),
PaddingLeft = UDim.new(0, T.WORKSPACE_PAD_X),
PaddingRight = UDim.new(0, T.WORKSPACE_PAD_X),
PaddingBottom = UDim.new(0, T.WORKSPACE_PAD_Y),
}),
})
local head = mk("Frame", {
Name = "PageHeader",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, T.PAGE_HEADER_H),
LayoutOrder = 0,
Parent = page,
})
mk("TextLabel", {
Name = "Title",
BackgroundTransparency = 1,
Text = name,
FontFace = T.FONT_BOLD,
TextSize = T.SIZE_PAGE,
TextColor3 = T.PAGE_TITLE,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Top,
Position = UDim2.fromOffset(2, 0),
Size = UDim2.new(1, -4, 0, 24),
Parent = head,
})
btn.Activated:Connect(function() selectTab(name) end)
local n = 0
local function nextOrder() n = n + 1 return n end
local api = { name = name, page = page }
function api:section(o) o = o or {} o.order = nextOrder() return W.section(page, o) end
function api:label(o)   o = o or {} o.order = nextOrder() return W.label(page, o) end
function api:button(o)  o = o or {} o.order = nextOrder() return W.button(page, o) end
function api:toggle(o)  o = o or {} o.order = nextOrder() return W.toggle(page, o) end
function api:slider(o)  o = o or {} o.order = nextOrder() return W.slider(page, o) end
function api:dropdown(o) o = o or {} o.order = nextOrder() return W.dropdown(page, o) end
function api:input(o)   o = o or {} o.order = nextOrder() return W.input(page, o) end
function api:row(o)     o = o or {} o.order = nextOrder() return W.row(page, o) end
function api:richCard(o) o = o or {} o.order = nextOrder() return W.richCard(page, o) end
function api:listCard(o) o = o or {} o.order = nextOrder() return W.listCard(page, o) end
function api:heading(text)
local lbl = head:FindFirstChild("Title")
if lbl then R.set(lbl, "Text", tostring(text)) end
end
function api:select()   selectTab(name) end
tabs[name] = { api = api, button = btn, label = lbl, page = page,
wrap = wrap }
if not current then selectTab(name) end
return api
end
function win:tabNames()
local out = {}
for n in pairs(tabs) do out[#out + 1] = n end
table.sort(out)
return out
end
local searchRow = nil
if not narrow then
searchRow = mk("Frame", {
Name = "SearchRow",
Position = UDim2.fromOffset(sideW + sideGap, wantH + searchGap),
Size = UDim2.fromOffset(wantW, searchH),
BackgroundColor3 = T.SEARCH_BG,
BorderSizePixel = 0,
Parent = holder,
}, {
T.corner(T.SIDE_RADIUS),
T.stroke(T.SIDE_EDGE, T.SIDE_STROKE_W, 0),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
}),
})
mk("TextLabel", {
Name = "SearchLabel",
BackgroundTransparency = 1,
Text = "Search",
FontFace = T.FONT_BOLD,
TextSize = 14,
TextColor3 = T.SIDE_TEXT,
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.new(0, 62, 1, 0),
Parent = searchRow,
})
local field = mk("TextBox", {
Name = "SearchField",
Position = UDim2.fromOffset(68, 0),
Size = UDim2.new(1, -68, 1, 0),
BackgroundColor3 = T.SEARCH_FIELD,
BorderSizePixel = 0,
Text = "",
PlaceholderText = "Filter features...",
PlaceholderColor3 = Color3.fromRGB(129, 123, 140),
FontFace = T.FONT,
TextSize = 13,
TextColor3 = T.TEXT,
TextXAlignment = Enum.TextXAlignment.Left,
ClearTextOnFocus = false,
Parent = searchRow,
}, {
T.corner(8),
T.stroke(T.SEARCH_EDGE, 1, 0),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}),
})
local function cardText(node)
local parts = {}
for _, d in ipairs(node:GetDescendants()) do
if d:IsA("TextLabel") or d:IsA("TextButton") then
local t = tostring(d.Text or "")
if #t > 0 then parts[#parts + 1] = t end
end
end
return table.concat(parts, " "):lower()
end
local function applySearch(query)
query = tostring(query or ""):lower()
local page = current and tabs[current]
if not page or not page.wrap then return end
local scroll = page.wrap:FindFirstChild("Scroll")
if not scroll then return end
for _, node in ipairs(scroll:GetChildren()) do
if node:IsA("GuiObject") and node.Name ~= "PageHeader" then
if query == "" then
R.set(node, "Visible", true)
elseif node.Name:match("^Section") then
R.set(node, "Visible", false)
else
R.set(node, "Visible",
cardText(node):find(query, 1, true) ~= nil)
end
end
end
end
field:GetPropertyChangedSignal("Text"):Connect(function()
BX.try("ui.lib.search", applySearch, field.Text)
end)
win.clearSearch = function()
if field.Text ~= "" then R.set(field, "Text", "") end
end
else
win.clearSearch = function() end
end
local chrome = {}
local function addChrome(o) if o then chrome[#chrome + 1] = o end end
addChrome(lockup)     addChrome(badgePill)  addChrome(controls)
addChrome(rail)       addChrome(body)       addChrome(railRight)
addChrome(searchRow)  addChrome(win.userChip)
local function setChrome(on)
for _, o in ipairs(chrome) do
R.set(o, "Visible", on and true or false)
end
end
local restPos = UDim2.fromScale(0.5, 0.5)
local restSize = UDim2.fromOffset(fullW, fullH)
win.rememberPosition = function() restPos = holder.Position end
local function rectOf(inst)
if not (inst and inst.Parent) then return nil end
local ok, p, sz = pcall(function()
return inst.AbsolutePosition, inst.AbsoluteSize
end)
if not ok or not p or sz.X < 1 then return nil end
return {
centre = UDim2.fromOffset(p.X + sz.X / 2, p.Y + sz.Y / 2),
size = UDim2.fromOffset(sz.X / fit, sz.Y / fit),
}
end
local morphed = false
function win:morphFrom(geom)
if morphed or dev.lite()
or not (geom and geom.panel and geom.panel.size and geom.panel.size.X > 1) then
self:setVisible(true)
return false
end
morphed = true
R.set(holder, "Size", UDim2.fromOffset(
geom.panel.size.X / fit, geom.panel.size.Y / fit))
R.set(scale, "Scale", fit)      
if geom.logo and geom.logo.size and geom.logo.size.X > 1 then
local rel = geom.logo.pos - geom.panel.pos
local lw = geom.logo.size.X / fit
R.set(logo, "Size", UDim2.fromOffset(lw, lw))
R.set(logo, "Position",
UDim2.fromOffset(rel.X / fit, (rel.Y / fit) + lw / 2))
end
setChrome(false)
self:setVisible(true)
R.flush()
R.tween(holder, T.MORPH, { Size = restSize }, T.EASE_WINDOW)
R.tween(logo, T.MORPH, {
Size = UDim2.fromOffset(T.LOGO_SIZE, T.LOGO_SIZE),
Position = UDim2.new(0, T.TITLEBAR_PAD_X, 0.5, 0),
}, T.EASE_WINDOW)
R.call(function()
task.delay(T.MORPH_CHROME, function() setChrome(true) end)
end)
return true
end
local launcherFn = nil
local launcherBound = nil
local minimised = false
function win:isMinimised() return minimised end
local function launcher()
if not launcherFn then return nil end
local ok, inst = pcall(launcherFn)
return ok and inst or nil
end
function win:minimise()
if minimised or not visible then return false end
local rect = rectOf(launcher())
minimised = true
win.rememberPosition()
if not rect or dev.lite() then
self:setVisible(false)
return false
end
setChrome(false)
R.tween(holder, T.MORPH, { Position = rect.centre, Size = rect.size },
T.EASE_WINDOW)
R.tween(dim, T.MORPH, { BackgroundTransparency = 1 })
R.call(function()
task.delay(T.MORPH + 0.02, function()
if minimised then
R.set(gui, "Enabled", false)
visible = false
end
end)
end)
return true
end
function win:restore()
if not minimised then
self:setVisible(true)
return false
end
minimised = false
local rect = rectOf(launcher())
if not rect or dev.lite() then
self:setVisible(true)
return false
end
R.set(holder, "Position", rect.centre)
R.set(holder, "Size", rect.size)
setChrome(false)
R.set(gui, "Enabled", true)
visible = true
R.flush()
R.tween(holder, T.MORPH, { Position = restPos, Size = restSize },
T.EASE_WINDOW)
R.tween(dim, T.MORPH, { BackgroundTransparency = T.DIM_ALPHA })
R.call(function()
task.delay(T.MORPH_CHROME, function() setChrome(true) end)
end)
return true
end
local TAP_TIME, TAP_SLOP = 0.35, 8
function win:setLauncher(fn)
launcherFn = fn
local inst = launcher()
if not inst or inst == launcherBound then return inst ~= nil end
launcherBound = inst
local downAt, downPos = 0, nil
inst.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
downAt, downPos = os.clock(), input.Position
end)
inst.InputEnded:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
if downAt == 0 or not downPos then return end
local heldFor = os.clock() - downAt
local moved = (Vector2.new(input.Position.X, input.Position.Y)
- Vector2.new(downPos.X, downPos.Y)).Magnitude
downAt, downPos = 0, nil
if heldFor > TAP_TIME or moved > TAP_SLOP then return end
task.spawn(function()
BX.try("ui.lib.launcherTap", function()
if minimised or not visible then win:restore() else win:minimise() end
end)
end)
end)
return true
end
if not opts.deferEntrance then
R.tween(dim, T.ENTER, { BackgroundTransparency = T.DIM_ALPHA })
R.tween(scale, T.ENTER, { Scale = fit }, T.EASE_WINDOW)
if not dev.lite() then
bar.Visible = false
rail.Visible = false
R.call(function()
task.delay(0.06, function() R.set(bar, "Visible", true) end)
task.delay(0.12, function() R.set(rail, "Visible", true) end)
end)
end
end
log.info("window built (%dx%d at scale %.2f, %s layout)", wantW, wantH, fit,
narrow and "narrow/top-tabs" or "wide/left-rail")
return win
end
return M
end)
BX.module("ui.logodata", function(BX)
return {
name = "logo-33f70fd5.png",
b64 = "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",
}
end)
BX.module("ui.logo", function(BX)
local exec = BX.require("core.exec")
local log = BX.require("boot.log").for_module("logo")
local M = {}
local FALLBACK_ASSET = "rbxassetid://95108798243406"
local FOLDER = "BlyxoHub/assets"
local OVERRIDE = FOLDER .. "/logo.png"
local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decode(text)
local out
pcall(function()
local lib = crypt
local candidates = {}
local function add(fn) if type(fn) == "function" then candidates[#candidates + 1] = fn end end
if type(lib) == "table" then
add(lib.base64decode)
if type(lib.base64) == "table" then add(lib.base64.decode) end
end
add(base64decode)
add(base64_decode)
for _, fn in ipairs(candidates) do
local ok, data = pcall(fn, text)
if ok and type(data) == "string" and #data > 0 then out = data return end
end
end)
if out then return out end
local map = {}
for i = 1, 64 do map[ALPHABET:sub(i, i)] = i - 1 end
local bytes, n = {}, 0
for i = 1, #text, 4 do
local a = map[text:sub(i, i)]
local b = map[text:sub(i + 1, i + 1)]
if not (a and b) then break end
local c, d = map[text:sub(i + 2, i + 2)], map[text:sub(i + 3, i + 3)]
n = n + 1; bytes[n] = string.char(a * 4 + math.floor(b / 16))
if c then n = n + 1; bytes[n] = string.char((b % 16) * 16 + math.floor(c / 4)) end
if d then n = n + 1; bytes[n] = string.char((c % 4) * 64 + d) end
end
return table.concat(bytes)
end
local function assetFor(path)
if not exec.isFile(path) then return nil end
local id = exec.customAsset(path)
if type(id) == "string" and id ~= "" then return id end
return nil
end
local function fromWorkspace()
if not (exec.can.customAsset and exec.can.files) then return nil end
local override = assetFor(OVERRIDE)
if override then
log.info("using the dropped %s", OVERRIDE)
return override
end
local data = BX.require("ui.logodata")
local path = FOLDER .. "/" .. data.name
if not exec.isFile(path) then
local bytes = decode(data.b64)
if #bytes < 64 then
log.warn("could not decode the baked mark")
return nil
end
exec.ensureFolder(FOLDER)
if not exec.writeFile(path, bytes) then return nil end
end
return assetFor(path)
end
local resolved = nil
function M.image()
if resolved then return resolved end
local ok, id = BX.try("logo.resolve", fromWorkspace)
resolved = (ok and id) or FALLBACK_ASSET
if resolved == FALLBACK_ASSET then
log.warn("no file access for the mark - falling back to the upload")
end
return resolved
end
function M.icon()
local id = M.image()
local numeric = tostring(id):match("^rbxassetid://(%d+)$")
return numeric and tonumber(numeric) or id
end
return M
end)
BX.module("ui.wording", function(BX)
local M = {}
local RULES = {
{ "^delivered",                    "Egg delivered!" },
{ "egg inventory full",            "Your egg inventory is full - sell, place or hatch eggs" },
{ "inventory is full",             "Your egg inventory is full - sell, place or hatch eggs" },
{ "^field resetting",              "The egg field is resetting - it continues after" },
{ "^guards out: (.+)",             "Waiting for the guard to walk back (%1)" },
{ "waiting for the guard",         "Waiting for the guard to walk back" },
{ "movement not trusted",          "The server slowed you down - pausing a moment" },
{ "no bait egg",                   "No egg in the Forest to distract the guard yet" },
{ "egg back in its nest",          "The egg went back to its nest - trying again" },
{ "^selected egg is gone",         "Your egg is gone - pick another one" },
{ "^egg taken by someone else",    "Someone else grabbed that egg - picking another" },        { "^waiting for the selected egg", "Waiting for your egg to be free" },
{ "^nothing matches the filter",   "No eggs match your filters right now" },
{ "^nothing to steal",             "No eggs to steal right now" },
{ "^field=0",                      "No eggs out right now" },
{ "^held egg",                     "Dropping the egg you are holding first" },
{ "^bait not taken",               "The guard did not take the bait - trying again" },
{ "^approach:",                    "Could not reach the egg - trying again" },
{ "^grab:",                        "Could not pick up the egg - trying again" },
{ "^drop recovery:",               "Picking the dropped egg back up" },
{ "^carry:",                       "Lost the egg on the way home - trying again" },
{ "^target picker failed",         "Could not choose an egg - trying again" },
{ "^cancelled",                    "Stopped" },
{ "^toggled off",                  "Stopped" },
{ "^hub unloaded",                 "Stopped" },
}
function M.plain(why)
local text = tostring(why or "")
if text == "" then return "" end
local lower = text:lower()
for _, rule in ipairs(RULES) do
local caps = { lower:match(rule[1]) }
if #caps > 0 then
local first = caps[1]
local at = lower:find(first, 1, true)
local original = at and text:sub(at, at + #first - 1) or first
return (rule[2]:gsub("%%1", function() return original end))
end
end
return text:sub(1, 1):upper() .. text:sub(2)
end
M.GUARDED = "guarded"
M.ON_GROUND = "on the ground"
return M
end)
BX.module("ui.splash", function(BX)
local svc = BX.require("core.services")
local exec = BX.require("core.exec")
local log = BX.require("boot.log").for_module("splash")
local sc = BX.scope("ui.splash")
local timeline = BX.timeline or function() end
local M = {}
M.step = function() end
M.fail = function() end
M.done = function() end
M.whenClosed = function(fn) pcall(fn) end
M.stats = function() return {} end
M.geometry = function() return nil end
local WIDTH, HEIGHT, PAD = 520, 376, 44
local AUTO_CONTINUE = 10 
local INVITE = "https://discord.gg/9KSXyabAYV"
local LOGO = BX.require("ui.logo").image()
local FAMILY = "rbxassetid://12187365364"
local SIZE_TITLE, SIZE_PRIMARY, SIZE_SMALL = 30, 14, 12
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local PANEL = Color3.fromRGB(12, 12, 12)
local ELEMENT = Color3.fromRGB(22, 22, 24)
local LINE = Color3.fromRGB(40, 40, 46)
local TEXT = Color3.fromRGB(236, 236, 240)
local MUTED = Color3.fromRGB(120, 120, 128)
local TRACK = Color3.fromRGB(30, 30, 33)
local WARN = Color3.fromRGB(255, 140, 128)
local ok, errorMessage = pcall(function()
local createdAt = os.clock()
local parent = exec.hiddenParent()
local old = parent:FindFirstChild("BlyxoSplash")
if old then old:Destroy() end
local EXPO = Enum.EasingStyle.Exponential
local tweenCount = 0
local function tween(object, info, properties)
local okTween, animation = pcall(svc.TweenService.Create, svc.TweenService, object, info, properties)
if not okTween then return nil end
tweenCount = tweenCount + 1
animation:Play()
return animation
end
local function ease(duration, style, direction, repeats, reverses, delay)
return TweenInfo.new(duration, style or EXPO, direction or Enum.EasingDirection.Out,
repeats or 0, reverses or false, delay or 0)
end
local function font(weight)
local okFont, face = pcall(Font.new, FAMILY, weight)
return okFont and face or Font.fromEnum(Enum.Font.GothamMedium)
end
local faders = {}
local function fade(object, properties)
local rest = {}
for property, value in pairs(properties) do
rest[property] = value
pcall(function() object[property] = 1 end)
end
faders[#faders + 1] = { object = object, rest = rest }
return object
end
local function playFade(info, hidden)
for _, entry in ipairs(faders) do
if entry.object.Parent then
local target = {}
for property, value in pairs(entry.rest) do
target[property] = hidden and 1 or value
end
tween(entry.object, info, target)
end
end
end
local function new(className, props, parentObject)
local object = Instance.new(className)
for key, value in pairs(props) do object[key] = value end
object.Parent = parentObject
return object
end
local function round(object, radius)
return new("UICorner", { CornerRadius = radius or UDim.new(0, 10) }, object)
end
local function shadow(object, color, blur, transparency)
local okShadow, instance = pcall(function()
return new("UIShadow", { Color = color, BlurRadius = UDim.new(0, blur), ZIndex = -1 }, object)
end)
if okShadow and instance then fade(instance, { Transparency = transparency }) end
return okShadow and instance or nil
end
local gui = new("ScreenGui", {
Name = "BlyxoSplash", DisplayOrder = 999997, IgnoreGuiInset = true,
ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parent)
local dim = new("Frame", {
Name = "Backdrop", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
BackgroundColor3 = BLACK, BackgroundTransparency = 1,
}, gui)
new("UIGradient", {
Rotation = 90,
Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0),
NumberSequenceKeypoint.new(0.5, 0.35),
NumberSequenceKeypoint.new(1, 0),
}),
}, dim)
local holder = new("Frame", {
Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = 1,
}, gui)
local baseScale = 1
pcall(function()
local viewport = workspace.CurrentCamera.ViewportSize
baseScale = math.clamp(math.min((viewport.X - 32) / WIDTH, (viewport.Y - 32) / HEIGHT), 0.55, 1)
end)
local scale = new("UIScale", { Scale = baseScale * 0.92 }, holder)
local panel = fade(new("Frame", {
Name = "Panel", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = WHITE,
}, holder), { BackgroundTransparency = 0 })
round(panel, UDim.new(0, 18))
new("UIGradient", {
Rotation = 90,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 27)),
ColorSequenceKeypoint.new(0.45, Color3.fromRGB(13, 13, 14)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 9, 10)),
}),
}, panel)
shadow(panel, BLACK, 60, 0.35)
local panelStroke = fade(new("UIStroke", {
Color = WHITE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, panel), { Transparency = 0.35 })
new("UIGradient", {
Rotation = 90,
Color = ColorSequence.new(Color3.fromRGB(58, 58, 64), Color3.fromRGB(22, 22, 25)),
}, panelStroke)
local function text(name, props)
props.Name = name
props.BackgroundTransparency = 1
props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
props.ZIndex = props.ZIndex or 3
local parentObject = props.Parent or panel
props.Parent = nil
return fade(new("TextLabel", props, parentObject), { TextTransparency = 0 })
end
local chip = new("Frame", {
Name = "Welcome", Position = UDim2.fromOffset(4, 16), Size = UDim2.fromOffset(0, 44),
AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = ELEMENT, BorderSizePixel = 0, ZIndex = 3,
}, panel)
local okWelcome, welcomeError = pcall(function()
local player = game:GetService("Players").LocalPlayer
if not player then chip:Destroy() return end
fade(chip, { BackgroundTransparency = 0 })
round(chip, UDim.new(1, 0))
fade(new("UIStroke", { Color = LINE, Thickness = 1 }, chip), { Transparency = 0 })
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 16) }, chip)
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10),
}, chip)
local avatar = fade(new("ImageLabel", {
Name = "Avatar", Size = UDim2.fromOffset(32, 32), LayoutOrder = 1,
BackgroundColor3 = Color3.fromRGB(34, 34, 38), BorderSizePixel = 0, ZIndex = 4,
Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60"):format(player.UserId),
}, chip), { BackgroundTransparency = 0, ImageTransparency = 0 })
round(avatar, UDim.new(1, 0))
local lines = new("Frame", {
Name = "Lines", Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X,
BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 4,
}, chip)
new("UIListLayout", {
FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center,
SortOrder = Enum.SortOrder.LayoutOrder,
}, lines)
text("Greeting", {
Parent = lines, Size = UDim2.fromOffset(0, 15), AutomaticSize = Enum.AutomaticSize.X,
FontFace = font(Enum.FontWeight.Regular), Text = "Welcome back,",
TextColor3 = MUTED, TextSize = SIZE_SMALL, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.None, LayoutOrder = 1, ZIndex = 4,
})
local nameLabel = text("Name", {
Parent = lines, Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
FontFace = font(Enum.FontWeight.SemiBold),
Text = (player.DisplayName ~= "" and player.DisplayName) or player.Name,
TextColor3 = WHITE, TextSize = SIZE_PRIMARY, TextXAlignment = Enum.TextXAlignment.Left,
LayoutOrder = 2, ZIndex = 4,
})
new("UISizeConstraint", { MaxSize = Vector2.new(190, 18) }, nameLabel)
end)
if not okWelcome then
log.error("welcome chip failed: %s", tostring(welcomeError))
pcall(function() chip:Destroy() end)
end
local emblem = new("Frame", {
Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54),
Size = UDim2.fromOffset(92, 92), BackgroundTransparency = 1, ZIndex = 2,
}, panel)
local core = fade(new("Frame", {
Name = "Core", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(72, 72), BackgroundColor3 = ELEMENT, BorderSizePixel = 0, ZIndex = 2,
}, emblem), { BackgroundTransparency = 0 })
round(core, UDim.new(1, 0))
local glow = shadow(core, WHITE, 44, 0.9)
fade(new("UIStroke", { Color = LINE, Thickness = 1 }, core), { Transparency = 0 })
fade(new("ImageLabel", {
Name = "Logo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(38, 38), BackgroundTransparency = 1, Image = LOGO,
ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
}, core), { ImageTransparency = 0 })
local ripple = new("Frame", {
Name = "Ripple", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ZIndex = 1,
}, emblem)
round(ripple, UDim.new(1, 0))
local rippleStroke = new("UIStroke", { Color = WHITE, Thickness = 1.5, Transparency = 1 }, ripple)
local function ring(name, restTransparency)
local frame = new("Frame", {
Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
}, emblem)
round(frame, UDim.new(1, 0))
local stroke = fade(new("UIStroke", { Color = WHITE, Thickness = 1.5 }, frame),
{ Transparency = restTransparency })
return frame, stroke
end
local _, trackStroke = ring("RingTrack", 0.9)
local _, arcStroke = ring("RingArc", 0)
local arc = new("UIGradient", {
Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0),
NumberSequenceKeypoint.new(0.45, 1),
NumberSequenceKeypoint.new(1, 1),
}),
}, arcStroke)
local title = text("Title", {
Position = UDim2.fromOffset(PAD, 160), Size = UDim2.new(1, -PAD * 2, 0, 36),
FontFace = font(Enum.FontWeight.Bold), Text = "BlyxoHub", TextColor3 = WHITE, TextSize = SIZE_TITLE,
})
local titleSheen = new("UIGradient", {
Offset = Vector2.new(-1, 0), Rotation = 20,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(196, 196, 204)),
ColorSequenceKeypoint.new(0.42, Color3.fromRGB(196, 196, 204)),
ColorSequenceKeypoint.new(0.5, WHITE),
ColorSequenceKeypoint.new(0.58, Color3.fromRGB(196, 196, 204)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 196, 204)),
}),
}, title)
text("Subtitle", {
Position = UDim2.fromOffset(PAD, 196), Size = UDim2.new(1, -PAD * 2, 0, 16),
FontFace = font(Enum.FontWeight.Medium), Text = string.upper(BX.game or "Steal An Egg"),
TextColor3 = MUTED, TextSize = SIZE_SMALL,
})
local PERCENT_WIDTH = 44 
local status = text("Status", {
Position = UDim2.fromOffset(PAD, 244), Size = UDim2.new(1, -PAD * 2 - PERCENT_WIDTH - 8, 0, 18),
FontFace = font(Enum.FontWeight.Medium), Text = "Starting…", TextColor3 = TEXT,
TextSize = SIZE_PRIMARY, TextXAlignment = Enum.TextXAlignment.Left,
})
local percent = text("Percentage", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -PAD, 0, 245),
Size = UDim2.fromOffset(PERCENT_WIDTH, 18), FontFace = font(Enum.FontWeight.Medium),
Text = "0%", TextColor3 = MUTED, TextSize = SIZE_SMALL,
TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.None,
})
local track = fade(new("Frame", {
Name = "ProgressTrack", Position = UDim2.fromOffset(PAD, 272), Size = UDim2.new(1, -PAD * 2, 0, 3),
BackgroundColor3 = TRACK, BorderSizePixel = 0, ZIndex = 2,
}, panel), { BackgroundTransparency = 0 })
round(track, UDim.new(1, 0))
local fill = fade(new("Frame", {
Name = "ProgressFill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE,
BorderSizePixel = 0, ZIndex = 3,
}, track), { BackgroundTransparency = 0 })
round(fill, UDim.new(1, 0))
local fillGlow = shadow(fill, WHITE, 10, 0.8)
local barSheen = new("UIGradient", {
Offset = Vector2.new(-1, 0),
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 188)),
ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 180, 188)),
ColorSequenceKeypoint.new(0.5, WHITE),
ColorSequenceKeypoint.new(0.6, Color3.fromRGB(180, 180, 188)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 188)),
}),
}, fill)
local ACTION_Y, ACTION_H = 306, 40
local unlocked = false
local link = new("TextButton", {
Name = "Continue", Position = UDim2.fromOffset(PAD, ACTION_Y), Size = UDim2.fromOffset(80, ACTION_H),
BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 3,
}, panel)
local linkLabel = text("Label", {
Parent = link, Size = UDim2.fromScale(1, 1),
FontFace = font(Enum.FontWeight.Medium), Text = "Continue  →", TextColor3 = MUTED,
TextSize = SIZE_PRIMARY, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.None, ZIndex = 4,
})
local underlineTrack = fade(new("Frame", {
Name = "UnderlineTrack", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 0.5, 12),
Size = UDim2.fromOffset(80, 1), BackgroundColor3 = MUTED, BorderSizePixel = 0,
ClipsDescendants = true, ZIndex = 4,
}, link), { BackgroundTransparency = 0.75 })
local function fitLink()
local width = math.ceil(linkLabel.TextBounds.X)
if width <= 0 then return end
link.Size = UDim2.fromOffset(width, ACTION_H)
underlineTrack.Size = UDim2.fromOffset(width, 1)
end
linkLabel:GetPropertyChangedSignal("TextBounds"):Connect(fitLink)
fitLink()
local meter = new("Frame", {
Name = "AutoContinue", Size = UDim2.fromScale(0, 1), BackgroundColor3 = TEXT,
BorderSizePixel = 0, ZIndex = 5,
}, underlineTrack)
local discordButton = new("TextButton", {
Name = "JoinDiscord", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -PAD, 0, ACTION_Y),
Size = UDim2.fromOffset(196, ACTION_H), BackgroundColor3 = WHITE, BorderSizePixel = 0,
AutoButtonColor = false, Text = "", ZIndex = 3,
}, panel)
fade(discordButton, { BackgroundTransparency = 0 })
round(discordButton, UDim.new(0, 10))
local discordGlow = shadow(discordButton, WHITE, 22, 0.88)
local discordLabel = text("Label", {
Parent = discordButton, Size = UDim2.fromScale(1, 1), ZIndex = 5,
FontFace = font(Enum.FontWeight.SemiBold), Text = "Join Discord  ↗", TextColor3 = PANEL,
TextSize = SIZE_PRIMARY,
})
local discordScale = new("UIScale", { Scale = 1 }, discordButton)
link.MouseEnter:Connect(function()
if unlocked then tween(linkLabel, ease(0.25), { TextColor3 = TEXT }) end
end)
link.MouseLeave:Connect(function()
tween(linkLabel, ease(0.3), { TextColor3 = MUTED })
end)
discordButton.MouseEnter:Connect(function()
if not unlocked then return end
tween(discordButton, ease(0.25), { BackgroundColor3 = Color3.fromRGB(230, 230, 236) })
if discordGlow then tween(discordGlow, ease(0.3), { Transparency = 0.7 }) end
end)
discordButton.MouseLeave:Connect(function()
tween(discordButton, ease(0.3), { BackgroundColor3 = WHITE })
tween(discordScale, ease(0.3), { Scale = 1 })
if discordGlow and unlocked then tween(discordGlow, ease(0.3), { Transparency = 0.82 }) end
end)
discordButton.MouseButton1Down:Connect(function()
if unlocked then tween(discordScale, ease(0.15), { Scale = 0.97 }) end
end)
discordButton.MouseButton1Up:Connect(function()
tween(discordScale, ease(0.3), { Scale = 1 })
end)
local function setLocked(locked, info)
link.Active = not locked
discordButton.Active = not locked
tween(linkLabel, info, { TextTransparency = locked and 0.6 or 0 })
tween(discordButton, info, { BackgroundTransparency = locked and 0.9 or 0 })
tween(discordLabel, info, { TextTransparency = locked and 0.6 or 0 })
if discordGlow then tween(discordGlow, info, { Transparency = locked and 1 or 0.82 }) end
end
local barValue = new("NumberValue", { Name = "ProgressValue", Value = 0 }, gui)
local closed, closing, drawn = false, false, false
local realProgress = 0
local closedCallbacks = {}
local fillTween, countdown
local BLUR_SIZE = 14
local blur, blurReason
local function startBlur()
local lite = false
pcall(function() lite = BX.require("core.device").lite() end)
if lite then blurReason = "device tier low" return end
pcall(function()
local level = UserSettings().GameSettings.SavedQualityLevel
if level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 3 then
blurReason = "graphics quality " .. level.Value
end
end)
if blurReason then return end
local frames, started = 0, os.clock()
while frames < 12 and not closing do
svc.RunService.RenderStepped:Wait()
frames = frames + 1
end
local fps = frames / math.max(os.clock() - started, 1e-3)
if fps < 45 then blurReason = ("fps %.0f"):format(fps) return end
if closing or closed then return end
local camera = workspace.CurrentCamera
if not camera then return end
blur = new("BlurEffect", { Name = "BlyxoSplashBlur", Size = 0 }, camera)
tween(blur, ease(0.6, Enum.EasingStyle.Quad), { Size = BLUR_SIZE })
blurReason = ("on (fps %.0f)"):format(fps)
end
local function startBlurLogged()
startBlur()
log.info("background blur: %s", tostring(blurReason or "skipped"))
end
local shownPercent = -1
barValue.Changed:Connect(function(value)
if not fill or not fill.Parent then return end
fill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1)
local whole = math.floor(math.clamp(value, 0, 1) * 100 + 0.5)
if whole ~= shownPercent then
shownPercent = whole
percent.Text = whole .. "%"
end
end)
local function animateProgress(value)
if not drawn or not barValue or value <= barValue.Value + 0.0005 then return end
if fillTween then fillTween:Cancel() end
fillTween = tween(barValue, ease(math.clamp(0.45 + (value - barValue.Value) * 1.2, 0.45, 1.1),
Enum.EasingStyle.Quart), { Value = value })
end
local function setText(object, value)
if object.Text == value then return end
object.Text = value
if drawn then
object.TextTransparency = 0.75
tween(object, ease(0.35), { TextTransparency = 0 })
end
end
local function cleanup()
if fillTween then fillTween:Cancel() end
if countdown then countdown:Cancel() end
if blur then blur:Destroy() blur = nil end
if gui then gui:Destroy() end
gui, fill, barValue = nil, nil, nil
end
local function notifyClosed()
for i = #closedCallbacks, 1, -1 do
pcall(closedCallbacks[i])
closedCallbacks[i] = nil
end
end
local function close()
if closing or closed then return end
closing = true
if countdown then countdown:Pause() end
timeline("SPLASH EXIT START")
notifyClosed()
playFade(ease(0.3, Enum.EasingStyle.Quad), true)
tween(meter, ease(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
if blur then tween(blur, ease(0.4, Enum.EasingStyle.Quad), { Size = 0 }) end
tween(dim, ease(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
tween(scale, ease(0.4, EXPO, Enum.EasingDirection.InOut), { Scale = baseScale * 0.82 })
task.delay(0.42, function()
closed = true
cleanup()
timeline("SPLASH DESTROYED")
sc:destroy()
end)
end
local secondsLeft, paused, flashUntil = AUTO_CONTINUE, false, 0
local function readyText()
if paused then return "Ready — paused" end
return ("Ready — opening in %ds"):format(secondsLeft)
end
local function refreshReady()
if unlocked and not closing and os.clock() >= flashUntil then
status.Text = readyText()
end
end
local function flash(message)
flashUntil = os.clock() + 1.6
setText(status, message)
task.delay(1.65, refreshReady)
end
discordButton.Activated:Connect(function()
if not unlocked or closing then return end
local opened = pcall(function()
game:GetService("GuiService"):OpenBrowserWindow(INVITE)
end)
local copied = exec.clipboard(INVITE)
flash(copied and "Invite copied to your clipboard" or
(opened and "Opening Discord…" or "discord.gg/9KSXyabAYV"))
end)
link.Activated:Connect(function()
if unlocked then close() end
end)
local function setPaused(value)
if not countdown or closing or paused == value then return end
paused = value
if value then countdown:Pause() else countdown:Play() end
refreshReady()
end
for _, action in ipairs({ link, discordButton }) do
action.MouseEnter:Connect(function() setPaused(true) end)
action.MouseLeave:Connect(function() setPaused(false) end)
end
local function unlock()
if unlocked or closing or closed then return end
unlocked = true
setLocked(false, ease(0.5))
tween(arcStroke, ease(0.6), { Transparency = 1 })
tween(trackStroke, ease(0.6), { Transparency = 0.6 })
if glow then
tween(glow, ease(0.18, Enum.EasingStyle.Quad), { Transparency = 0.35 })
task.delay(0.2, function()
if glow.Parent then tween(glow, ease(1), { Transparency = 0.82 }) end
end)
end
rippleStroke.Transparency = 0.3
tween(rippleStroke, ease(0.7, Enum.EasingStyle.Quad), { Transparency = 1 })
tween(ripple, ease(0.7, Enum.EasingStyle.Quart), { Size = UDim2.fromOffset(128, 128) })
local progress = new("NumberValue", { Value = 0 }, gui)
progress.Changed:Connect(function(v)
if meter.Parent then meter.Size = UDim2.fromScale(v, 1) end
local left = math.max(1, math.ceil(AUTO_CONTINUE * (1 - v) - 1e-3))
if left ~= secondsLeft then
secondsLeft = left
refreshReady()
end
end)
countdown = svc.TweenService:Create(progress,
TweenInfo.new(AUTO_CONTINUE, Enum.EasingStyle.Linear), { Value = 1 })
tweenCount = tweenCount + 1
countdown.Completed:Connect(function(state)
if state == Enum.PlaybackState.Completed then close() end
end)
paused = false
countdown:Play()
setText(status, readyText())
end
sc:spawn("entrance", function()
svc.RunService.RenderStepped:Wait()
if closing or closed then return end
drawn = true
tween(dim, ease(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.3 })
tween(scale, ease(0.8), { Scale = baseScale })
playFade(ease(0.6), false)
setLocked(true, ease(0.6))
if chip.Parent then
tween(chip, ease(0.9, EXPO, Enum.EasingDirection.Out, 0, false, 0.15),
{ Position = UDim2.fromOffset(16, 16) })
end
task.spawn(startBlurLogged)
tween(arc, ease(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
if glow then
tween(glow, ease(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.7 })
end
tween(barSheen, ease(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), { Offset = Vector2.new(1, 0) })
tween(titleSheen, ease(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.2),
{ Offset = Vector2.new(1, 0) })
animateProgress(realProgress)
end)
local function tidy(value)
return (tostring(value):gsub("%.%.%.$", "…"))
end
function M.step(textValue, value)
if closed or closing or unlocked then return end
if textValue ~= nil then setText(status, tidy(textValue)) end
local nextProgress = math.clamp(tonumber(value) or realProgress, 0, 1)
if nextProgress <= realProgress then return end
realProgress = nextProgress
animateProgress(realProgress)
end
function M.fail(message)
if closed or closing then return end
status.TextColor3 = WARN
fill.BackgroundColor3 = WARN
arcStroke.Color = WARN
if fillGlow then fillGlow.Color = WARN end
setText(status, tidy(message or "Startup failed"))
M.step(nil, 1)
task.delay(2, close)
end
function M.whenClosed(fn)
if type(fn) ~= "function" then return end
if closed then pcall(fn) else closedCallbacks[#closedCallbacks + 1] = fn end
end
function M.done()
if closed or closing or unlocked then return end
status.TextColor3 = TEXT
M.step(nil, 1)
task.spawn(function()
while not drawn and not closing and not closed do task.wait() end
if fillTween and fillTween.PlaybackState == Enum.PlaybackState.Playing then
fillTween.Completed:Wait()
end
if closed or closing then return end
unlock()
end)
end
function M.stats()
return { tweensMade = tweenCount, instancesTotal = #faders, gate = "auto_continue", blur = blurReason }
end
function M.geometry()
if closed or not panel or not panel.Parent then return nil end
local g = { }
local ok = pcall(function()
g.panel = { pos = panel.AbsolutePosition, size = panel.AbsoluteSize }
if core and core.Parent then
g.logo = { pos = core.AbsolutePosition, size = core.AbsoluteSize }
end
end)
return ok and g.panel and g or nil
end
BX.onTeardown("ui.splash", function()
if not closed then
notifyClosed()
cleanup()
end
end)
M.step("Starting…", 0.10)
timeline("SPLASH CREATED")
log.info("created loading card in %.0fms", (os.clock() - createdAt) * 1000)
end)
if not ok then log.error("construction failed: %s", tostring(errorMessage)) end
return M
end)
BX.module("ui.stats", function(BX)
local svc = BX.require("core.services")
local cfg = BX.require("core.config")
local st  = BX.require("core.state")
local exec = BX.require("core.exec")
local logo = BX.require("ui.logo")
local log = BX.require("boot.log").for_module("stats")
local M = {}
local Stats, RunService = svc.Stats, svc.RunService
local UIS, TS, HS       = svc.UserInputService, svc.TweenService, svc.HttpService
local TextService       = svc.TextService
local T = nil
pcall(function()
if BX._factories and BX._factories["ui.lib.theme"] then
T = BX.require("ui.lib.theme")
end
end)
local function themed(key, fallback)
local v = T and T[key]
if v ~= nil then return v end
return fallback
end
local BG_TOP  = themed("PANEL", Color3.fromRGB(24, 24, 27))
local BG_BOT  = Color3.fromRGB(24, 14, 42)
local ELEMENT = themed("LINE", Color3.fromRGB(40, 40, 46))
local ACCENT  = themed("ACCENT", Color3.fromRGB(124, 77, 255))
local ICON    = themed("MUTED", Color3.fromRGB(120, 120, 128))
local TEXT    = themed("TEXT", Color3.fromRGB(236, 236, 240))
local MUTED   = themed("MUTED", Color3.fromRGB(120, 120, 128))
local WARN    = Color3.fromRGB(240, 190, 90)
local BAD     = Color3.fromRGB(240, 110, 110)
local FAMILY = "rbxassetid://12187365364"
local FONT, TEXT_SIZE, UNIT_SIZE = Enum.Font.GothamMedium, 14, 12
local function face(weight)
local ok, f = pcall(Font.new, FAMILY, weight)
return ok and f or Font.fromEnum(FONT)
end
local STROKE_T = 0.35
local POS_FILE = "BlyxoHub_stats_pos.json"   
local NUM_EASE_K = 12     
local TONE_FADE  = 0.45   
local FPS_ALPHA  = 0.28   
local PING_ALPHA = 0.30
local BANDS = {
fps  = { dir = -1,
warn = { enter = 50,  exit = 54  },
bad  = { enter = 25,  exit = 29  } },
ping = { dir = 1,
warn = { enter = 150, exit = 132 },
bad  = { enter = 250, exit = 220 } },
}
local SPIKE_FACTOR  = 2.5   
local SPIKE_FLOOR   = 120   
local SPIKE_CONFIRM = 2     
local STALE_AFTER = 6       
local BLANK = "--"
local ICON_ROOT = "BlyxoHub/icons"
local ICON_DIR  = ICON_ROOT .. "/v1"
local ICON_BASE = "https://raw.githubusercontent.com/google/material-design-icons/3.0.1/"
local ICON_SRC  = {
clock = "action/2x_web/ic_schedule_white_48dp.png",
pulse = "editor/2x_web/ic_show_chart_white_48dp.png",
wifi  = "notification/2x_web/ic_wifi_white_48dp.png",
}
local iconAsset = {}   
local iconTone  = {}   
local iconsAsked = false   
local sessionT0 = os.clock()
local gui, pill, scaler, stroke, brandFrame
local launcher, launcherTitle, launcherSub
local chevron, chevronGlyph   
local sc   
local bars, labels, fadeList, iconBoxes = {}, {}, {}, {}
local momentRow, momentDot, momentTitle, momentSub, momentBar
local momentNodes = {}
local momentActive, momentToken, momentSignature, momentWidth, momentProgress = false, 0, nil, nil, nil
local momentMeasurePending, momentLastTitle, momentLastSub = false, nil, nil
local applyCompact
local cellFrames = {}          
local tip, tipLabel, tipStroke, tipScale 
local hovering = false
local frames, shownFps = 0, nil
local fpsLevel, pingLevel = 0, 0
local pingEma, pingSuspect, pingSeenAt = nil, 0, nil
local hoverKind, hoverUntil = nil, 0
local target, moving, dragging = nil, false, false
local docked = false
function M.setDock(_) docked = false end
function M.isDocked() return false end
local function positionLauncher()
if not launcher or not launcher.Parent or not pill or not pill.Parent then return end
local ok = pcall(function()
local vp = workspace.CurrentCamera.ViewportSize
local a, sz = pill.AbsolutePosition, pill.AbsoluteSize
launcher.Position = UDim2.fromScale(
(a.X + sz.X / 2) / vp.X,
(a.Y + sz.Y + 10) / vp.Y)
end)
if not ok then launcher.Visible = false end
end
local grabInput, grabStart, grabPos
local baseScale, closing = 1, false
local function mk(class, props, parent)
local o = Instance.new(class)
for k, v in pairs(props) do o[k] = v end
o.Parent = parent
return o
end
local function tw(o, t, props, style)
BX.try("stats.tween", function()
TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint,
Enum.EasingDirection.Out), props):Play()
end)
end
local function line(parent, x1, y1, x2, y2)
local dx, dy = x2 - x1, y2 - y1
mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 1.5),
Rotation = math.deg(math.atan2(dy, dx)),
BackgroundColor3 = ICON, BorderSizePixel = 0,
}, parent)
end
local function drawIcon(box, kind)
if kind == "clock" then
local ring = mk("Frame", {
Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(12, 12),
BackgroundTransparency = 1,
}, box)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
mk("UIStroke", { Color = ICON, Thickness = 1.5 }, ring)
line(box, 8, 8, 8, 5)
line(box, 8, 8, 10.5, 8)
elseif kind == "pulse" then
local p = { {1, 9}, {4.5, 9}, {6.5, 4}, {9.5, 13}, {11.5, 9}, {15, 9} }
for i = 1, #p - 1 do line(box, p[i][1], p[i][2], p[i + 1][1], p[i + 1][2]) end
else
bars = {}
for i = 1, 3 do
local h = 2 + i * 3.5
bars[i] = mk("Frame", {
Position = UDim2.fromOffset(2 + (i - 1) * 4.5, 14 - h),
Size = UDim2.fromOffset(3, h),
BackgroundColor3 = ICON, BorderSizePixel = 0,
}, box)
mk("UICorner", { CornerRadius = UDim.new(0, 1) }, bars[i])
end
end
end
local function validPng(data)
if type(data) ~= "string" or #data < 200 then return false end
if data:sub(2, 4) ~= "PNG" then return false end
local function be32(at)
local a, b, c, d = data:byte(at, at + 3)
if not d then return 0 end
return ((a * 256 + b) * 256 + c) * 256 + d
end
local w, h = be32(17), be32(21)
return w >= 16 and w <= 512 and h >= 16 and h <= 512
end
local function fillIcon(box, kind)
for _, c in ipairs(box:GetChildren()) do c:Destroy() end
if kind == "wifi" then bars = {} end   
if iconAsset[kind] then
mk("ImageLabel", {
Name = "Img", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
Image = iconAsset[kind], ImageColor3 = iconTone[kind] or ICON,
ScaleType = Enum.ScaleType.Fit,
}, box)
else
drawIcon(box, kind)
end
end
local function icon(parent, kind)
local box = mk("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 }, parent)
iconBoxes[kind] = box
fillIcon(box, kind)
return box
end
local function cell(parent, order, kind, widest, unit)
local c = mk("Frame", {
Name = kind, LayoutOrder = order, AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, 18), BackgroundTransparency = 1,
}, parent)
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
VerticalAlignment = Enum.VerticalAlignment.Center,
Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
}, c)
icon(c, kind).LayoutOrder = 1
cellFrames[kind] = c
local w = 0
BX.try("stats.measure", function()
w = TextService:GetTextSize(widest, TEXT_SIZE, FONT, Vector2.new(1000, 100)).X
end)
local value = mk("TextLabel", {
LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(math.ceil(w), 18), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.SemiBold), TextSize = TEXT_SIZE, TextColor3 = TEXT,
TextXAlignment = unit and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
Text = BLANK,
}, c)
if unit then
mk("TextLabel", {
Name = "Unit", LayoutOrder = 3, AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, 18), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.Medium), TextSize = UNIT_SIZE, TextColor3 = MUTED,
Text = unit,
}, c)
end
return value
end
local function divider(parent, order, name)
local gap = mk("Frame", {
Name = name or "Divider", LayoutOrder = order, Size = UDim2.fromOffset(12, 14),
BackgroundTransparency = 1, ClipsDescendants = true,
}, parent)
mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(1, 14), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.85,
BorderSizePixel = 0,
}, gap)
return gap
end
local function setMoment(spec)
if not pill or not pill.Parent or closing then return false end
if not spec then
if not momentActive then return true end
momentToken += 1
local token = momentToken
momentActive = false
momentSignature, momentWidth, momentProgress = nil, nil, nil
momentMeasurePending, momentLastTitle, momentLastSub = false, nil, nil
tw(momentRow, 0.3, { Size = UDim2.fromOffset(0, 24) })
task.delay(0.32, function()
if token ~= momentToken or not pill or not pill.Parent then return end
momentRow.Visible = false
for _, node in ipairs(momentNodes) do node.Visible = true end
if compact then applyCompact(false) end
end)
return true
end
local titleText, subText = tostring(spec.title or ""), tostring(spec.sub or "")
local signature = table.concat({ titleText, subText, tostring(spec.tone or "normal") }, "\0")
local entering = not momentActive
if entering then momentToken += 1 end
local token = momentToken
local titleChanged, subChanged = momentTitle.Text ~= titleText, momentSub.Text ~= subText
momentActive, momentSignature = true, signature
if entering then
for _, node in ipairs(momentNodes) do node.Visible = false end
end
if titleChanged then momentTitle.Text = titleText end
if subChanged then momentSub.Text = subText end
momentDot.BackgroundColor3 = spec.tone == "warn" and WARN
or spec.tone == "bad" and BAD or TEXT
local progress = type(spec.progress) == "number" and math.clamp(spec.progress, 0, 1) or nil
momentBar.Visible = progress ~= nil
momentProgress = progress
if progress ~= nil and (not momentBar:GetAttribute("Progress")
or math.abs(momentBar:GetAttribute("Progress") - progress) > 0.01) then
local trackWidth = math.max(0, (momentWidth or 0) - 48)
momentBar.Size = UDim2.fromOffset(trackWidth * progress, 2)
momentBar:SetAttribute("Progress", progress)
elseif progress == nil then
momentBar:SetAttribute("Progress", nil)
end
momentRow.Visible = true
if entering then momentRow.Size = UDim2.fromOffset(0, 24) end
if entering or titleChanged or subChanged then
momentLastTitle, momentLastSub = titleText, subText
if not momentMeasurePending then
momentMeasurePending = true
task.defer(function()
momentMeasurePending = false
if token ~= momentToken or not momentActive or not momentRow.Parent then return end
momentSub.Position = UDim2.fromOffset(momentTitle.TextBounds.X + 30, 1)
local width = math.clamp(momentTitle.TextBounds.X + momentSub.TextBounds.X + 66, 170, 360)
if not momentWidth or math.abs(momentWidth - width) > 12 then
momentWidth = width
tw(momentRow, entering and 0.35 or 0.18,
{ Size = UDim2.fromOffset(width, 24) },
entering and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
end
if momentProgress ~= nil then
momentBar.Size = UDim2.fromOffset(
math.max(0, width - 48) * momentProgress, 2)
end
end)
end
end
return true
end
local function clock(s)
s = math.floor(s)
local h, m = math.floor(s / 3600), math.floor(s / 60) % 60
if h > 0 then return ("%d:%02d:%02d"):format(h, m, s % 60) end
return ("%02d:%02d"):format(m, s % 60)
end
local function readPing()
local ok, v = pcall(function()
return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
end)
if ok and type(v) == "number" and v > 0 then return v end
ok, v = pcall(function() return svc.LocalPlayer:GetNetworkPing() * 1000 end)
return (ok and type(v) == "number") and v or nil
end
local function paint(obj, prop, color)
if obj and obj[prop] ~= color then tw(obj, TONE_FADE, { [prop] = color }) end
end
local function ema(prev, value, alpha)
if prev == nil then return value end
return prev + (value - prev) * alpha
end
local LEVEL_COLOR = { [0] = TEXT, [1] = WARN, [2] = BAD }
local function grade(band, v, cur)
cur = cur or 0
local function worseThan(x)
if band.dir < 0 then return v <= x else return v >= x end
end
local function betterThan(x)
if band.dir < 0 then return v >= x else return v <= x end
end
if cur >= 2 then
if not betterThan(band.bad.exit) then return 2 end
return betterThan(band.warn.exit) and 0 or 1
elseif cur == 1 then
if worseThan(band.bad.enter) then return 2 end
return betterThan(band.warn.exit) and 0 or 1
else
if worseThan(band.bad.enter) then return 2 end
return worseThan(band.warn.enter) and 1 or 0
end
end
local QUALITY = {
fps  = { [0] = "Smooth",    [1] = "Fair", [2] = "Poor" },
ping = { [0] = "Excellent", [1] = "Good", [2] = "Poor" },
}
local function tintIcon(kind, color)
if iconTone[kind] == color then return end
iconTone[kind] = color
local box = iconBoxes[kind]
if not box or not box.Parent then return end
for _, d in ipairs(box:GetDescendants()) do
if d:IsA("ImageLabel") then
paint(d, "ImageColor3", color)
elseif d:IsA("UIStroke") then
paint(d, "Color", color)
elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
paint(d, "BackgroundColor3", color)
end
end
end
local NUM = {
{ key = "fps",  fmt = "%d" },   
{ key = "ping", fmt = "%d" },
}
local function entry(key)
for i = 1, #NUM do
if NUM[i].key == key then return NUM[i] end
end
end
local function setTarget(key, value)
local e = entry(key)
if not e then return end
e.target = value
if e.shown == nil then e.shown = value end
end
local function setUnavailable(key)
local e = entry(key)
if not e or e.target == nil then return end
e.shown, e.target, e.lastWhole = nil, nil, nil
local label = labels[key]
if label and label.Text ~= BLANK then label.Text = BLANK end
end
local function easeNumbers(dt)
local k = 1 - math.exp(-dt * NUM_EASE_K)
for i = 1, #NUM do
local e = NUM[i]
local label = labels[e.key]
if e.target and label then
local diff = e.target - e.shown
if diff < 0.01 and diff > -0.01 then
e.shown = e.target
else
e.shown += diff * k
end
local whole = math.floor(e.shown + 0.5)
if whole ~= e.lastWhole then
e.lastWhole = whole
label.Text = e.fmt:format(whole)
end
end
end
end
local function resetNumbers()
for i = 1, #NUM do
local e = NUM[i]
e.shown, e.target, e.lastWhole = nil, nil, nil
end
end
local DETAIL_HOLD = 2.5   
local function detailFor(kind)
if kind == "clock" then
return "Session time"
end
local key = (kind == "pulse") and "fps" or "ping"
local e = entry(key)
if not e or not e.target then
return (key == "fps" and "FPS" or "Ping") .. "  \u{B7}  no reading"
end
local level = (key == "fps") and fpsLevel or pingLevel
local word  = QUALITY[key][level]
if key == "fps" then
return ("%d FPS  \u{B7}  %s"):format(math.floor(e.target + 0.5), word)
end
return ("%d ms  \u{B7}  %s"):format(math.floor(e.target + 0.5), word)
end
local function hideTip()
hoverKind, hoverUntil = nil, 0
if not tip then return end
tw(tip, 0.18, { BackgroundTransparency = 1 })
tw(tipLabel, 0.18, { TextTransparency = 1 })
if tipStroke then tw(tipStroke, 0.18, { Transparency = 1 }) end
end
local function placeTip()
if not tip or not pill or not hoverKind then return end
local cellF = cellFrames[hoverKind]
local cx = cellF and cellF.Parent
and (cellF.AbsolutePosition.X + cellF.AbsoluteSize.X / 2)
or (pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2)
local halfW = tip.AbsoluteSize.X / 2
local vpX = gui.AbsoluteSize.X
cx = math.clamp(cx, halfW + 6, math.max(vpX - halfW - 6, halfW + 6))
local origin = gui.AbsolutePosition
tip.Position = UDim2.fromOffset(cx - origin.X, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 6 - origin.Y)
end
local function showTip(kind)
if not tip or not pill or hoverKind == kind then return end
hoverKind = kind
tipLabel.Text = detailFor(kind)
placeTip()
tw(tip, 0.16, { BackgroundTransparency = 0.08 })
tw(tipLabel, 0.16, { TextTransparency = 0 })
if tipStroke then tw(tipStroke, 0.16, { Transparency = 0.55 }) end
end
local function kindAtX(x)
for kind, f in pairs(cellFrames) do
if f.Parent then
local left = f.AbsolutePosition.X
if x >= left and x <= left + f.AbsoluteSize.X then return kind end
end
end
return nil
end
local function pickScale()
local vp = gui and gui.AbsoluteSize or Vector2.new(1000, 1000)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
if not touch then return 1.2 end
local short = math.min(vp.X, vp.Y)
if short < 10 then return 0.85 end
return math.clamp(short / 620, 0.78, 1.25)
end
local function defaultPos()
local vy = gui and gui.AbsoluteSize.Y or 0
return UDim2.fromScale(0.5, vy > 0 and (8 / vy) or 0.01)
end
local function clampPos(p)
local vp, sz = gui.AbsoluteSize, pill.AbsoluteSize
if vp.X < 1 or vp.Y < 1 then return p end
local hx, hy = (sz.X / 2 + 4) / vp.X, (sz.Y + 4) / vp.Y
local top = 4 / vp.Y
return UDim2.fromScale(
math.clamp(p.X.Scale, math.min(hx, 0.5), math.max(1 - hx, 0.5)),
math.clamp(p.Y.Scale, top, math.max(1 - hy, top)))
end
local function readPrefs()
local raw = exec.readFile(POS_FILE)
if not raw then return {} end
local ok, t = pcall(function() return HS:JSONDecode(raw) end)
return (ok and type(t) == "table") and t or {}
end
local function writePrefs(change)
BX.try("stats.savePrefs", function()
local t = readPrefs()
for k, v in pairs(change) do t[k] = v end
exec.writeFile(POS_FILE, HS:JSONEncode(t))
end)
end
local function loadPos()
local t = readPrefs()
if tonumber(t.x) and tonumber(t.y) then
return UDim2.fromScale(tonumber(t.x), tonumber(t.y))
end
return nil
end
local function savePos(p)
if not p then return end
writePrefs({ x = p.X.Scale, y = p.Y.Scale })
end
local function moveTo(p)
target = clampPos(p)
moving = true
end
local function dragTo(at)
if not gui or not grabStart then return end
local vp = gui.AbsoluteSize
if vp.X < 1 or vp.Y < 1 then return end
local dx, dy = at.X - grabStart.X, at.Y - grabStart.Y
moveTo(UDim2.fromScale(grabPos.X.Scale + dx / vp.X, grabPos.Y.Scale + dy / vp.Y))
end
local function release()
if not dragging then return end
dragging, grabInput = false, nil
if scaler then tw(scaler, 0.25, { Scale = baseScale }, Enum.EasingStyle.Back) end
if stroke then tw(stroke, 0.3, { Transparency = STROKE_T }) end
savePos(target)
end
local function collectFade()
fadeList = {}
if not pill then return end
local function add(o, prop) fadeList[#fadeList + 1] = { o, prop, o[prop] } end
add(pill, "BackgroundTransparency")
add(stroke, "Transparency")
for _, d in ipairs(pill:GetDescendants()) do
if d:IsA("TextLabel") then
add(d, "TextTransparency")
elseif d:IsA("ImageLabel") then
add(d, "ImageTransparency")
elseif d:IsA("UIStroke") or d:IsA("UIShadow") then
add(d, "Transparency")
elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
add(d, "BackgroundTransparency")
end
end
end
local compact = readPrefs().compact == true
local COMPACT_T = 0.4
local collapsible = {}   
local function contentsOf(frame)
local list = {}
for _, d in ipairs(frame:GetDescendants()) do
if d:IsA("TextLabel") then list[#list + 1] = { d, "TextTransparency" }
elseif d:IsA("ImageLabel") then list[#list + 1] = { d, "ImageTransparency" }
elseif d:IsA("UIStroke") then list[#list + 1] = { d, "Transparency" }
elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then list[#list + 1] = { d, "BackgroundTransparency" } end
end
return list
end
local function restingValue(obj, prop)
for _, f in ipairs(fadeList) do
if f[1] == obj and f[2] == prop then return f[3] end
end
return 0
end
applyCompact = function(animate)
for _, part in ipairs(collapsible) do
local frame = part.frame
if frame.Parent then
local t = animate and COMPACT_T or 0
local info = TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
if compact then
local s = scaler and scaler.Scale or baseScale
if frame.AbsoluteSize.X > 0 then part.width = frame.AbsoluteSize.X / math.max(s, 0.01) end
frame.AutomaticSize = Enum.AutomaticSize.None
frame.ClipsDescendants = true
frame.Size = UDim2.fromOffset(part.width or 0, frame.Size.Y.Offset)
for _, c in ipairs(contentsOf(frame)) do
if t > 0 then tw(c[1], t * 0.6, { [c[2]] = 1 }) else c[1][c[2]] = 1 end
end
if t > 0 then
TS:Create(frame, info, { Size = UDim2.fromOffset(0, frame.Size.Y.Offset) }):Play()
else
frame.Size = UDim2.fromOffset(0, frame.Size.Y.Offset)
end
else
local width = part.width or 60
for _, c in ipairs(contentsOf(frame)) do
local rest = restingValue(c[1], c[2])
if t > 0 then tw(c[1], t, { [c[2]] = rest }) else c[1][c[2]] = rest end
end
local function settle()
if not frame.Parent or compact then return end
frame.ClipsDescendants = part.isDivider == true
if not part.isDivider then
frame.Size = UDim2.fromOffset(0, frame.Size.Y.Offset)
frame.AutomaticSize = Enum.AutomaticSize.X
end
end
if t > 0 then
local anim = TS:Create(frame, info, { Size = UDim2.fromOffset(width, frame.Size.Y.Offset) })
anim.Completed:Connect(settle)
anim:Play()
else
frame.Size = UDim2.fromOffset(width, frame.Size.Y.Offset)
settle()
end
end
end
end
if chevronGlyph and chevronGlyph.Parent then
local rot = compact and 180 or 0
if animate then
tw(chevronGlyph, COMPACT_T, { Rotation = rot })
else
chevronGlyph.Rotation = rot
end
end
if pill and target then
task.delay(animate and COMPACT_T + 0.05 or 0.05, function()
if pill and target then moveTo(target) end
end)
end
end
function M.isCompact() return compact end
function M.setLauncher(on)
if not launcher or not launcher.Parent then return false end
launcher.Visible = on and true or false
if launcher.Visible then positionLauncher() end
return true
end
function M.setCompact(on)
on = on and true or false
if on == compact then return end
compact = on
writePrefs({ compact = on })
if pill and not closing then applyCompact(true) end
end
local function fade(on, t, pop)
for _, f in ipairs(fadeList) do
if f[1].Parent then tw(f[1], t, { [f[2]] = on and f[3] or 1 }) end
end
if scaler then
tw(scaler, t, { Scale = on and baseScale or baseScale * 0.9 },
(on and pop) and Enum.EasingStyle.Back or Enum.EasingStyle.Exponential)
end
end
local function hits(obj, inp)
if not obj or not obj.Parent then return false end
local p, s = obj.AbsolutePosition, obj.AbsoluteSize
local inset = 0
pcall(function() inset = game:GetService("GuiService"):GetGuiInset().Y end)
local x, y = inp.Position.X, inp.Position.Y
return x >= p.X and x <= p.X + s.X
and ((y >= p.Y and y <= p.Y + s.Y) or (y + inset >= p.Y and y + inset <= p.Y + s.Y))
end
local menu, menuScale, menuOpenedAt = nil, nil, 0
local LONG_PRESS = 0.5     
local LONG_PRESS_SLOP = 10 
local function notify(title, text)
BX.try("stats.menuNotify", function()
local win = BX._loaded["ui.window"]
if win and win.notify then win.notify(title, text, 4) end
end)
end
local function closeMenu()
if not menu then return end
local m = menu
menu = nil
for _, d in ipairs(m:GetDescendants()) do
if d:IsA("TextLabel") then tw(d, 0.15, { TextTransparency = 1 })
elseif d:IsA("UIStroke") or d:IsA("UIShadow") then tw(d, 0.15, { Transparency = 1 })
elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then tw(d, 0.15, { BackgroundTransparency = 1 }) end
end
tw(m, 0.15, { BackgroundTransparency = 1 })
if menuScale then tw(menuScale, 0.15, { Scale = 0.95 }) end
task.delay(0.17, function() pcall(function() m:Destroy() end) end)
end
local function fpsBoostOn()
local ok, on = pcall(function() return BX.require("features.fps").isOn() end)
return ok and on == true
end
local function openMenu()
if not gui or not pill or closing then return end
if menu then closeMenu() return end
hideTip()
menuOpenedAt = os.clock()
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local ROW_H, WIDTH = touch and 40 or 32, 176
menu = mk("Frame", {
Name = "QuickMenu", AnchorPoint = Vector2.new(0.5, 0.5),
Size = UDim2.fromOffset(WIDTH, ROW_H * 3 + 12), BackgroundColor3 = Color3.new(1, 1, 1),
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 20,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, menu)
mk("UIGradient", {
Rotation = 90, Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, BG_TOP),
ColorSequenceKeypoint.new(0.45, Color3.fromRGB(13, 13, 14)),
ColorSequenceKeypoint.new(1, BG_BOT),
}),
}, menu)
local mStroke = mk("UIStroke", {
Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 1,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, menu)
mk("UIGradient", {
Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(58, 58, 64), Color3.fromRGB(22, 22, 25)),
}, mStroke)
local mShadow
pcall(function()
mShadow = mk("UIShadow", {
Color = Color3.new(0, 0, 0), BlurRadius = UDim.new(0, 26), Transparency = 1, ZIndex = -1,
}, menu)
end)
mk("UIPadding", {
PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
}, menu)
mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, menu)
menuScale = mk("UIScale", { Scale = baseScale * 0.95 }, menu)
local fadeIn = {}
local function row(order, label, onPick, withSwitch)
local b = mk("TextButton", {
LayoutOrder = order, Size = UDim2.new(1, 0, 0, ROW_H),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
AutoButtonColor = false, Text = "", ZIndex = 21,
}, menu)
mk("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
local t = mk("TextLabel", {
Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0),
BackgroundTransparency = 1, FontFace = face(Enum.FontWeight.Medium),
TextSize = TEXT_SIZE, TextColor3 = TEXT, TextTransparency = 1,
TextXAlignment = Enum.TextXAlignment.Left, Text = label, ZIndex = 22,
}, b)
fadeIn[#fadeIn + 1] = { t, "TextTransparency", 0 }
local knob, track
if withSwitch then
track = mk("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
Size = UDim2.fromOffset(28, 16), BackgroundColor3 = Color3.new(1, 1, 1),
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 22,
}, b)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
knob = mk("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0),
Size = UDim2.fromOffset(12, 12), BackgroundColor3 = BG_BOT,
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 23,
}, track)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
end
local function paintSwitch(on, animate)
if not track then return end
local trackT, knobPos = on and 0 or 0.8, on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
local knobColor = on and BG_BOT or ICON
if animate then
tw(track, 0.25, { BackgroundTransparency = trackT })
tw(knob, 0.25, { Position = knobPos, BackgroundTransparency = 0, BackgroundColor3 = knobColor })
else
knob.Position, knob.BackgroundColor3 = knobPos, knobColor
fadeIn[#fadeIn + 1] = { track, "BackgroundTransparency", trackT }
fadeIn[#fadeIn + 1] = { knob, "BackgroundTransparency", 0 }
end
end
if withSwitch then paintSwitch(withSwitch(), false) end
b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundTransparency = 0.94 }) end)
b.MouseLeave:Connect(function() tw(b, 0.2, { BackgroundTransparency = 1 }) end)
b.Activated:Connect(function()
BX.try("stats.menuPick", function() onPick(paintSwitch) end)
end)
end
row(1, "FPS Boost", function(paintSwitch)
local want = not fpsBoostOn()
local misc = BX._loaded["ui.tabs.misc"]
if misc and misc.setFpsBoost then misc.setFpsBoost(want)
else BX.require("features.fps").setEnabled(want) end
paintSwitch(want, true)
end, fpsBoostOn)
row(2, "Server Hop", function()
closeMenu()
task.spawn(function()
local ok, msg = BX.require("features.misc.servers").hop()
notify("Servers", tostring(msg))
end)
end)
row(3, "Rejoin", function()
closeMenu()
task.spawn(function()
local ok, msg = BX.require("features.misc.servers").rejoin()
notify("Servers", tostring(msg))
end)
end)
local vp = gui.AbsoluteSize
local below = pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 8
local height = (ROW_H * 3 + 12) * baseScale
local bottomEdge = gui.AbsolutePosition.Y + vp.Y
local y = (below + height > bottomEdge - 8) and (pill.AbsolutePosition.Y - 8 - height) or below
local halfW = WIDTH * baseScale / 2
local x = math.clamp(pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2, halfW + 6, math.max(vp.X - halfW - 6, halfW + 6))
local origin = gui.AbsolutePosition
menu.Position = UDim2.fromOffset(x - origin.X, y + height / 2 - origin.Y)
tw(menu, 0.25, { BackgroundTransparency = 0.02 })
tw(mStroke, 0.25, { Transparency = STROKE_T })
if mShadow then tw(mShadow, 0.25, { Transparency = 0.45 }) end
tw(menuScale, 0.25, { Scale = baseScale })
for _, f in ipairs(fadeIn) do tw(f[1], 0.25, { [f[2]] = f[3] }) end
end
local function teardown()
if sc then sc:destroy(); sc = nil end
if gui then pcall(function() gui:Destroy() end) end
gui, pill, scaler, stroke, brandFrame = nil, nil, nil, nil, nil
launcher, launcherTitle, launcherSub = nil, nil, nil
chevron, chevronGlyph = nil, nil
menu, menuScale = nil, nil
bars, labels, fadeList, iconBoxes = {}, {}, {}, {}
cellFrames = {}
momentRow, momentDot, momentTitle, momentSub, momentBar = nil, nil, nil, nil, nil
momentNodes, momentActive = {}, false
momentSignature, momentWidth, momentProgress = nil, nil, nil
momentMeasurePending, momentLastTitle, momentLastSub = false, nil, nil
tip, tipLabel, tipStroke = nil, nil, nil
dragging, moving, closing, shownFps, grabInput = false, false, false, nil, nil
resetNumbers()
iconTone = {}
fpsLevel, pingLevel = 0, 0
pingEma, pingSuspect, pingSeenAt = nil, 0, nil
hoverKind, hoverUntil, hovering = nil, 0, false
end
local function build()
sc = BX.scope("ui.stats")
local parent = exec.hiddenParent()
local old = parent:FindFirstChild("BlyxoStats")
if old then old:Destroy() end
gui = mk("ScreenGui", {
Name = "BlyxoStats", DisplayOrder = 100000, IgnoreGuiInset = true,
ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parent)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
pill = mk("TextButton", {
AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.01),
AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, touch and 46 or 42),
BackgroundColor3 = Color3.fromRGB(29, 20, 46), BackgroundTransparency = 0.08,
BorderSizePixel = 0, Active = true, AutoButtonColor = false,
Text = "", Selectable = false,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 22) }, pill)
mk("UIGradient", {
Rotation = 90,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 20, 46)),
ColorSequenceKeypoint.new(0.45, Color3.fromRGB(14, 13, 20)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 13, 20)),
}),
}, pill)
stroke = mk("UIStroke", {
Color = Color3.fromRGB(167, 139, 250), Transparency = 0.48, Thickness = 1,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, pill)
pcall(function()
local glow = Instance.new("UIShadow")
glow.Color = Color3.fromRGB(91, 43, 216)
glow.BlurRadius = UDim.new(0, 30)
glow.Transparency = 0.72
glow.ZIndex = -1
glow.Parent = pill
end)
pcall(function()
mk("UIShadow", {
Color = Color3.new(0, 0, 0), BlurRadius = UDim.new(0, 22),
Transparency = 0.45, ZIndex = -1,
}, pill)
end)
mk("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, pill)
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
VerticalAlignment = Enum.VerticalAlignment.Center,
Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
}, pill)
launcher = mk("TextButton", {
Name = "BlyxoHubLauncher", AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.fromScale(0.5, 0.08), Size = UDim2.fromOffset(250, 58),
BackgroundColor3 = Color3.fromRGB(12, 12, 16), BackgroundTransparency = 0.04,
BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false,
Active = true, ZIndex = 20,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 29) }, launcher)
mk("UIStroke", {
Color = Color3.fromRGB(91, 91, 105), Transparency = 0.48, Thickness = 1,
}, launcher)
mk("ImageLabel", {
Name = "Logo", AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.fromOffset(18, 29), Size = UDim2.fromOffset(30, 30),
BackgroundTransparency = 1, Image = logo.image(),
ScaleType = Enum.ScaleType.Fit, ZIndex = 21,
}, launcher)
launcherTitle = mk("TextLabel", {
Name = "Title", Position = UDim2.fromOffset(62, 11),
Size = UDim2.fromOffset(170, 22), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.SemiBold), TextSize = 16,
TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
Text = "BlyxoHub", ZIndex = 21,
}, launcher)
launcherSub = mk("TextLabel", {
Name = "Subtitle", Position = UDim2.fromOffset(62, 32),
Size = UDim2.fromOffset(170, 18), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.Medium), TextSize = 12,
TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
Text = "Tap to show", ZIndex = 21,
}, launcher)
sc:connect(launcher.Activated, BX.guard("stats.revealLauncher", function()
local shell = BX._loaded["ui.shell"]
if shell and type(shell.reveal) == "function" then shell.reveal() end
end))
baseScale = pickScale()
scaler = mk("UIScale", { Scale = baseScale }, pill)
brandFrame = mk("Frame", {
Name = "BlyxoBrand", LayoutOrder = 0, Size = UDim2.fromOffset(108, 30),
BackgroundTransparency = 1, BorderSizePixel = 0,
}, pill)
mk("ImageLabel", {
Name = "Logo", AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.fromOffset(0, 15), Size = UDim2.fromOffset(26, 26),
BackgroundTransparency = 1, Image = logo.image(),
ScaleType = Enum.ScaleType.Fit,
}, brandFrame)
mk("TextLabel", {
Name = "Title", Position = UDim2.fromOffset(32, 1),
Size = UDim2.fromOffset(76, 18), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.SemiBold), TextSize = 13,
TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
Text = "BlyxoHub",
}, brandFrame)
mk("TextLabel", {
Name = "Subtitle", Position = UDim2.fromOffset(32, 17),
Size = UDim2.fromOffset(76, 13), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.Medium), TextSize = 9,
TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
Text = BX.game or "Steal An Egg",
}, brandFrame)
momentRow = mk("Frame", {
Name = "DynamicIslandRow", LayoutOrder = 1, Visible = false,
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
}, pill)
momentDot = mk("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(8, 12),
Size = UDim2.fromOffset(7, 7), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
}, momentRow)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, momentDot)
momentTitle = mk("TextLabel", {
Position = UDim2.fromOffset(24, 1), Size = UDim2.fromOffset(0, 22),
AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.SemiBold), TextSize = TEXT_SIZE,
TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
}, momentRow)
momentSub = mk("TextLabel", {
Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(0, 22),
AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.Medium), TextSize = UNIT_SIZE,
TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
}, momentRow)
momentBar = mk("Frame", {
Name = "Progress", AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 24, 1, -2), Size = UDim2.new(0, 0, 0, 2),
BackgroundColor3 = TEXT, BorderSizePixel = 0, Visible = false,
}, momentRow)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, momentBar)
labels.time = cell(pill, 2, "clock", "00:00")
local d1 = divider(pill, 3, "TimeDivider")
labels.fps  = cell(pill, 4, "pulse", "000", "FPS")
local d2 = divider(pill, 5, "PingDivider")
labels.ping = cell(pill, 6, "wifi", "000", "ms")
local spacer = mk("Frame", { LayoutOrder = 7, Size = UDim2.fromOffset(4, 18), BackgroundTransparency = 1, Visible = false }, pill)
local hit = touch and 34 or 24
chevron = mk("TextButton", {
Name = "Collapse", LayoutOrder = 8, Size = UDim2.fromOffset(hit, hit),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
AutoButtonColor = false, Text = "", Selectable = false, Visible = false,
}, pill)
mk("UICorner", { CornerRadius = UDim.new(0, 7) }, chevron)
chevronGlyph = mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
Rotation = compact and 180 or 0,
}, chevron)
line(chevronGlyph, 6.5, 1.5, 3, 5)
line(chevronGlyph, 3, 5, 6.5, 8.5)
local function glyphTone(color)
for _, b in ipairs(chevronGlyph:GetChildren()) do
if b:IsA("Frame") then b.BackgroundColor3 = color end
end
end
glyphTone(ICON)
sc:connect(chevron.MouseEnter, function()
glyphTone(TEXT)
tw(chevron, 0.25, { BackgroundTransparency = 0.94 })
end)
sc:connect(chevron.MouseLeave, function()
glyphTone(ICON)
tw(chevron, 0.25, { BackgroundTransparency = 1 })
end)
sc:connect(chevron.Activated, BX.guard("stats.collapse", function()
M.setCompact(not compact)
end))
collapsible = {
{ frame = cellFrames.clock },
{ frame = d1, width = 21, isDivider = true },
{ frame = d2, width = 21, isDivider = true },
{ frame = cellFrames.wifi },
}
momentNodes = { brandFrame, cellFrames.clock, d1, cellFrames.pulse, d2, cellFrames.wifi, spacer, chevron }
if not iconsAsked and exec.can.customAsset and exec.can.files and not exec.fragile then
iconsAsked = true
sc:spawn("icons", function()
BX.try("stats.iconDirs", function() exec.ensureFolder(ICON_DIR) end)
local got = 0
for kind, src in pairs(ICON_SRC) do
local path = ICON_DIR .. "/" .. kind .. ".png"
local ok = BX.try("stats.icon." .. kind, function()
local have = exec.isFile(path) and validPng(exec.readFile(path))
if not have then
local png = game:HttpGet(ICON_BASE .. src)
assert(validPng(png), "not a usable png")
assert(exec.writeFile(path, png), "writefile refused")
end
iconAsset[kind] = assert(exec.customAsset(path), "no custom asset")
end)
if ok then got += 1 end
end
log.info("material icons ready: %d/3", got)
if got > 0 and gui and not closing and sc and sc:alive() then
for kind, box in pairs(iconBoxes) do
if box.Parent and iconAsset[kind] then
fillIcon(box, kind)
local img = box:FindFirstChild("Img")
if img then fadeList[#fadeList + 1] = { img, "ImageTransparency", 0 } end
end
end
end
end)
end
tip = mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0), AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, 22), BackgroundColor3 = BG_BOT,
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5,
}, gui)
mk("UICorner", { CornerRadius = UDim.new(0, 7) }, tip)
tipStroke = mk("UIStroke", {
Color = ELEMENT, Transparency = 1, Thickness = 1,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, tip)
mk("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, tip)
tipScale = mk("UIScale", { Scale = baseScale }, tip)
tipLabel = mk("TextLabel", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22),
BackgroundTransparency = 1, FontFace = face(Enum.FontWeight.Medium), TextSize = UNIT_SIZE,
TextColor3 = TEXT, TextTransparency = 1, Text = "", ZIndex = 5,
}, tip)
target = clampPos(loadPos() or defaultPos())
pill.Position = target
sc:connect(gui:GetPropertyChangedSignal("AbsoluteSize"), BX.guard("stats.resize", function()
baseScale = pickScale()
if scaler and not dragging then scaler.Scale = baseScale end
if tipScale then tipScale.Scale = baseScale end
if target then moveTo(target) end
end))
sc:connect(pill.MouseEnter, function() hovering = true end)
sc:connect(pill.MouseLeave, function() hovering = false; hideTip() end)
local lastTap = 0
sc:connect(pill.InputBegan, BX.guard("stats.grab", function(inp)
local kind = inp.UserInputType
if kind == Enum.UserInputType.MouseButton2 then
openMenu()
return
end
if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
return
end
if hits(chevron, inp) then return end
if kind == Enum.UserInputType.Touch then
local startPos = inp.Position
task.delay(LONG_PRESS, function()
if not dragging or grabInput ~= inp or closing then return end
local moved = (inp.Position - startPos).Magnitude
if moved > LONG_PRESS_SLOP then return end
release()
openMenu()
end)
end
local now = os.clock()
if now - lastTap < 0.3 then
lastTap = 0
release()
moveTo(defaultPos())
savePos(target)
return
end
lastTap = now
if kind == Enum.UserInputType.Touch then
local k = kindAtX(inp.Position.X)
if k then
showTip(k)
hoverUntil = now + DETAIL_HOLD
end
end
dragging, grabInput, grabPos = true, inp, target or pill.Position
grabStart = (kind == Enum.UserInputType.MouseButton1)
and UIS:GetMouseLocation() or inp.Position
tw(scaler, 0.2, { Scale = baseScale * 1.05 }, Enum.EasingStyle.Back)
tw(stroke, 0.2, { Transparency = 0.1 })
end))
sc:connect(pill.Activated, BX.guard("stats.revealWindow", function()
local shell = BX._loaded["ui.shell"]
local hidden = shell and type(shell.isHidden) == "function" and shell.isHidden()
if shell and hidden then
shell.reveal()
end
end))
sc:connect(UIS.InputChanged, BX.guard("stats.dragTouch", function(inp)
if dragging and grabInput and inp == grabInput
and inp.UserInputType == Enum.UserInputType.Touch then
dragTo(inp.Position)
end
end))
sc:connect(UIS.InputBegan, BX.guard("stats.menuDismiss", function(inp)
if not menu then return end
if inp.KeyCode == Enum.KeyCode.Escape then closeMenu() return end
local kind = inp.UserInputType
if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.MouseButton2
and kind ~= Enum.UserInputType.Touch then return end
if os.clock() - menuOpenedAt < 0.15 then return end
if not hits(menu, inp) then closeMenu() end
end))
sc:connect(UIS.InputEnded, BX.guard("stats.release", function(inp)
if not dragging or not grabInput then return end
if inp == grabInput or (inp.UserInputType == Enum.UserInputType.MouseButton1
and grabInput.UserInputType == Enum.UserInputType.MouseButton1) then
release()
end
end))
collectFade()
end
function M.show(on)
if not on then
if not gui or closing then return end
closing = true
release()
fade(false, 0.22)
local g = gui
task.delay(0.25, function()
if gui == g and closing then teardown() end
end)
return
end
if gui then
if closing then closing = false; fade(true, 0.3) end
return
end
local built, why = pcall(build)
if not built then
log.error("could not build: %s", tostring(why))
teardown()
return
end
for _, f in ipairs(fadeList) do
if f[1].Parent then f[1][f[2]] = 1 end
end
scaler.Scale = baseScale * 0.9
BX.try("stats.entryPos", function()
local vy = math.max(gui.AbsoluteSize.Y, 1)
pill.Position = UDim2.fromScale(target.X.Scale, target.Y.Scale - 12 / vy)
end)
local entering = gui
sc:spawn("entrance", function()
for _ = 1, 2 do RunService.RenderStepped:Wait() end
if gui ~= entering or closing or not BX.alive() then return end
if compact then applyCompact(false) end
fade(true, 0.4)
moving = true
end)
sc:delay("settle", 0.1, function()
if pill and target then moveTo(target) end
end)
frames = 0
sc:onFrame("frame", RunService.RenderStepped, function(dt)
frames += 1
easeNumbers(dt)
if launcher and launcher.Visible then positionLauncher() end
if hovering and not dragging then
local k = kindAtX(UIS:GetMouseLocation().X)
if k then showTip(k) elseif hoverKind then hideTip() end
elseif hoverUntil > 0 and os.clock() > hoverUntil then
hideTip()
end
if hoverKind then placeTip() end
if dragging and grabInput
and grabInput.UserInputType == Enum.UserInputType.MouseButton1 then
dragTo(UIS:GetMouseLocation())
end
if moving and target and pill then
local p = pill.Position:Lerp(target, 1 - math.exp(-math.min(dt, 1 / 30) * 20))
if math.abs(p.X.Scale - target.X.Scale) < 1e-4
and math.abs(p.Y.Scale - target.Y.Scale) < 1e-4 then
p = target
if not dragging then moving = false end
end
pill.Position = p
end
end)
local myGui = gui
sc:spawn("ticker", function()
local last = os.clock()
local interval = 1 / math.max(cfg.STATS_HZ / 2, 1)
local tick = BX.profile.wrapLoop("ui.stats/ticker", interval, function()
local now = os.clock()
local t = clock(now - sessionT0)
if labels.time.Text ~= t then labels.time.Text = t end
local rawFps = frames / math.max(now - last, 0.001)
frames, last = 0, now
shownFps = ema(shownFps, rawFps, FPS_ALPHA)
st.lastFps = shownFps
setTarget("fps", shownFps)
fpsLevel = grade(BANDS.fps, shownFps, fpsLevel)
local fpsTone = LEVEL_COLOR[fpsLevel]
paint(labels.fps, "TextColor3", fpsTone)
tintIcon("pulse", fpsLevel == 0 and ICON or fpsTone)
if hoverKind and tipLabel then
local fresh = detailFor(hoverKind)
if tipLabel.Text ~= fresh then tipLabel.Text = fresh end
end
local raw = readPing()
if raw and pingEma and raw > math.max(pingEma * SPIKE_FACTOR, SPIKE_FLOOR) then
pingSuspect = pingSuspect + 1
if pingSuspect < SPIKE_CONFIRM then
log.trace("ping outlier held: %.0fms (settled %.0fms)", raw, pingEma)
raw = nil
end
elseif raw then
pingSuspect = 0
end
if raw then
pingEma    = ema(pingEma, raw, PING_ALPHA)
pingSeenAt = now
setTarget("ping", pingEma)
pingLevel = grade(BANDS.ping, pingEma, pingLevel)
local pingTone = LEVEL_COLOR[pingLevel]
paint(labels.ping, "TextColor3", pingTone)
tintIcon("wifi", pingLevel == 0 and ICON or pingTone)
if not closing then
local lit = 3 - pingLevel
for i, b in ipairs(bars) do
local want = i <= lit and 0 or 0.7
if b.Parent and b.BackgroundTransparency ~= want then
tw(b, 0.3, { BackgroundTransparency = want })
end
end
end
elseif pingSeenAt and (now - pingSeenAt) > STALE_AFTER then
setUnavailable("ping")
pingEma, pingLevel, pingSeenAt = nil, 0, nil
tintIcon("wifi", ICON)
end
end)
while gui == myGui and myGui.Parent and BX.alive() do
task.wait(interval)
if gui ~= myGui then return end
BX.try("stats.tick", tick)
end
if not BX.alive() then teardown() end
end)
end
function M.anchor()
if not pill or not pill.Parent or closing then return nil end
return pill, (scaler and scaler.Scale) or baseScale
end
function M.surface()
if not gui or not gui.Parent or closing then return nil end
return gui, pill, (scaler and scaler.Scale) or baseScale
end
function M.moment(spec)
return setMoment(spec)
end
M._probe = function()
return {
guiAlive = gui ~= nil and gui.Parent ~= nil,
time     = labels.time and labels.time.Text,
fps      = labels.fps and labels.fps.Text,
ping     = labels.ping and labels.ping.Text,
scale    = scaler and scaler.Scale,
pillSize = pill and tostring(pill.AbsoluteSize),
conns    = sc and #sc.conns or 0,
fadeN    = #fadeList,
}
end
return M
end)
BX.module("ui.island", function(BX)
local svc = BX.require("core.services")
local M = {}
local shown, current = false, nil
local persistent, persistentOrder = {}, {}
local transient
local started = false
local function stats()
return BX._loaded["ui.stats"] or BX.require("ui.stats")
end
local function resolve()
if transient and os.clock() < transient.untilT then
return transient.spec, transient.key
end
transient = nil
for i = #persistentOrder, 1, -1 do
local key = persistentOrder[i]
if persistent[key] then return persistent[key], key end
end
end
local function refresh()
if not BX.alive() then return end
local spec, key = resolve()
local hud = stats()
if hud and hud.moment then hud.moment(spec) end
shown, current = spec ~= nil, key
end
function M.show(key, spec)
spec = spec or {}
transient = { key = key, spec = spec, untilT = os.clock() + (spec.hold or 3) }
BX.try("island.show", refresh)
local untilT = transient.untilT
task.delay((spec.hold or 3) + 0.05, function()
if transient and transient.untilT == untilT then BX.try("island.expire", refresh) end
end)
end
function M.set(key, spec)
if persistent[key] == nil then persistentOrder[#persistentOrder + 1] = key end
persistent[key] = spec or {}
if not transient then BX.try("island.set", refresh) end
end
function M.clear(key)
if persistent[key] == nil then return end
persistent[key] = nil
for i = #persistentOrder, 1, -1 do
if persistentOrder[i] == key then table.remove(persistentOrder, i) end
end
if not transient then BX.try("island.clear", refresh) end
end
function M.isShowing() return shown end
function M.start()
if started then return end
started = true
local auto = BX.require("features.autosteal")
local carry = BX.require("features.carry")
local eggs = BX.require("features.eggs")
local phases = {
READY_TO_STEAL = "baiting the guard", BAIT_DONE = "heading to the egg",
AT_TARGET = "grabbing", TARGET_GRAB_RETRY = "grabbing",
CARRYING = "carrying", RETURNING = "carrying",
}
local hud = stats()
if hud and hud.show then hud.show(true) end
local sc = BX.scope("ui.island")
sc:loop("steal", 0.2, function()
local live = auto.live()
if not (live.running and live.target and live.busy) then
M.clear("steal")
return
end
local progress = carry.progress()
M.set("steal", {
title = "Stealing " .. tostring(live.target.name or "egg"),
sub = progress and ("carrying %d%%"):format(math.floor(progress * 100 + 0.5))
or phases[live.phase or ""] or "stealing",
progress = progress,
})
end)
auto.onDelivered(function(target)
local rate = target and tonumber(target.value)
M.clear("steal")
M.show("delivered", {
title = "Egg delivered!",
sub = rate and rate > 0 and ("+%s/s"):format(eggs.formatRate(rate))
or tostring(target and target.name or ""),
tone = "good", hold = 3, pulse = true,
})
end)
BX.try("island.boss", function()
local boss = BX.require("features.boss")
local wasOpen = false
boss.onChange(function()
local state = boss.status()
local open = type(state.body) == "string" and state.body:find("^Open") ~= nil
if open and not wasOpen then
M.show("boss", { title = "Boss world open",
sub = state.body:gsub("^Open%s*·%s*", ""), tone = "warn", hold = 4, pulse = true })
end
wasOpen = open
end)
end)
BX.try("island.rift", function()
local rift = BX.require("features.rift")
local lastNeed
rift.onChange(function()
local state = rift.status()
local need = type(state.body) == "string" and state.body:match("^Steal (.-) now") or nil
if need and need ~= lastNeed then
M.show("rift", { title = "Rift needs " .. need,
sub = "it's on the field", tone = "warn", hold = 4, pulse = true })
end
lastNeed = need
end)
end)
BX.try("island.luck", function()
local remote = svc.ReplicatedStorage.Packages.Networking:FindFirstChild("RE/LuckWindow/StateRefreshed")
if not (remote and remote:IsA("RemoteEvent")) then return end
local endsAt
local function findEnd(value, depth)
if type(value) ~= "table" or depth > 2 then return nil end
local now = workspace:GetServerTimeNow()
for key, item in pairs(value) do
if type(item) == "number" and item > now and item < now + 86400 then
local name = tostring(key):lower()
if name:find("end") or name:find("expire") or name:find("until") or name:find("close") then return item end
elseif type(item) == "table" then
local nested = findEnd(item, depth + 1)
if nested then return nested end
end
end
end
sc:connect(remote.OnClientEvent, function(payload)
endsAt = findEnd(payload, 0)
if not endsAt then M.clear("luck") end
end)
sc:loop("luck", 1, function()
if not endsAt then return end
local left = endsAt - workspace:GetServerTimeNow()
if left <= 0 then endsAt = nil M.clear("luck") return end
M.set("luck", { title = "Luck window",
sub = ("%d:%02d left"):format(math.floor(left / 60), math.floor(left % 60)), tone = "good" })
end)
end)
end
function M.stop()
shown, current, started = false, nil, false
persistent, persistentOrder, transient = {}, {}, nil
local hud = BX._loaded["ui.stats"]
if hud and hud.moment then BX.try("island.stop", hud.moment, nil) end
end
BX.onTeardown("ui.island", M.stop)
return M
end)
BX.module("ui.window", function(BX)
local exec = BX.require("core.exec")
local svc  = BX.require("core.services")
local log  = BX.require("boot.log").for_module("window")
local UIS  = svc.UserInputService
local M = { ok = false }
local URLS = {
"https://sirius.menu/gen2",
"https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
}
local FETCH_TIMEOUT = 15     
local INIT_TIMEOUT  = 15     
local ATTEMPTS      = 2
local timeline = BX.timeline or function() end
local serializedHost = exec.fragile
do
local executorName = tostring(exec.name or ""):lower()
if executorName:find("xeno", 1, true) then serializedHost = true end
end
local function bounded(label, fn, timeout)
if serializedHost then
local ok, res = pcall(fn)
return ok, res, false
end
local done, ok, res = false, nil, nil
task.spawn(function()
ok, res = pcall(fn)
done = true
end)
local t0 = os.clock()
while not done and (os.clock() - t0) < timeout do
if not BX.alive() then return false, "retired", false end
task.wait(0.05)
end
if not done then return false, label .. " timed out after " .. timeout .. "s", true end
return ok, res, false
end
local MOTION_MIN, MOTION_MAX, MOTION_CAP = 0.25, 0.4, 0.8
local function unifyMotion(source)
local changed = 0
local patched = source:gsub("TweenInfo%.new%((%d*%.?%d+)([,%)])", function(num, tail)
local d = tonumber(num)
if not d or d < 0.12 or d > MOTION_CAP then return nil end
local clamped = math.clamp(d, MOTION_MIN, MOTION_MAX)
if clamped == d then return nil end
changed = changed + 1
return "TweenInfo.new(" .. tostring(clamped) .. tail
end)
log.info("motion: %d library tween durations unified to %.2f-%.2fs", changed, MOTION_MIN, MOTION_MAX)
return patched
end
local Rayfield, lastErr
local INIT_FLAG = "BlyxoHub/rayfield_init.flag"
local diedLastRun = false
if exec.can.files then
diedLastRun = exec.isFile(INIT_FLAG)
if diedLastRun then
log.error("the client died inside the library init last run (%s) - it is the library load, not our code",
tostring(exec.readFile(INIT_FLAG)))
exec.deleteFile(INIT_FLAG)
end
end
local CACHE = "BlyxoHub/rayfield_gen2.lua"
local canCache = exec.can.files and not diedLastRun
if diedLastRun and exec.can.files and exec.isFile(CACHE) then
log.warn("deleting the cached library: the last run died loading one")
exec.deleteFile(CACHE)
end
local function initFrom(source, label)
timeline("RAYFIELD INIT START", label)
local c0 = os.clock()
if serializedHost then
local okMem, live = BX.try("window.preInitMem", gcinfo)
task.wait()
log.info("pre-init: %s KB live, yielding before a %d byte compile",
okMem and tostring(live) or "?", #source)
end
if exec.can.files then
BX.try("window.initFlag", function()
exec.ensureFolder("BlyxoHub")
exec.writeFile(INIT_FLAG, tostring(label) .. " | " .. tostring(#source) .. " bytes")
end)
end
local okLoad, lib = bounded("library init", function()
local prepared = serializedHost and source or unifyMotion(source)
local chunk = loadstring(prepared) or assert(loadstring(source))
task.wait()
return chunk()
end, INIT_TIMEOUT)
timeline("RAYFIELD INIT END", ("%.0fms compile+run"):format((os.clock() - c0) * 1000))
if exec.can.files then BX.try("window.initFlagClear", exec.deleteFile, INIT_FLAG) end
if okLoad and type(lib) == "table" then return lib end
return nil, "library init failed: " .. tostring(lib)
end
local function refreshCache()
if not canCache or serializedHost then return end
task.spawn(function()
BX.try("window.cacheRefresh", function()
local fresh = game:HttpGet(URLS[1])
if type(fresh) == "string" and #fresh > 1000 then
exec.ensureFolder("BlyxoHub")
exec.writeFile(CACHE, fresh)
log.info("rayfield cache refreshed (%d bytes)", #fresh)
end
end)
end)
end
if canCache then
local cached = exec.isFile(CACHE) and exec.readFile(CACHE) or nil
if type(cached) == "string" and #cached > 1000 then
local lib, why = initFrom(cached, "local copy")
if lib then
Rayfield = lib
refreshCache()
else
log.warn("cached Rayfield failed (%s) - deleting it and downloading", tostring(why))
exec.deleteFile(CACHE)
end
end
end
for attempt = 1, (Rayfield and 0 or ATTEMPTS) do
for _, url in ipairs(URLS) do
if not BX.alive() then break end
timeline("RAYFIELD FETCH START", url)
local f0 = os.clock()
local ok, res = bounded("fetch", function() return game:HttpGet(url) end, FETCH_TIMEOUT)
timeline("RAYFIELD FETCH END", ("%.0fms, %s bytes"):format((os.clock() - f0) * 1000,
type(res) == "string" and #res or "?"))
if ok and type(res) == "string" and #res > 1000 then
local lib, why = initFrom(res, url)
if lib then
Rayfield = lib
if canCache and url == URLS[1] then
BX.try("window.cacheWrite", function()
exec.ensureFolder("BlyxoHub")
exec.writeFile(CACHE, res)
end)
end
break
end
lastErr = why
else
lastErr = tostring(res)
end
end
if Rayfield or not BX.alive() then break end
log.warn("UI host attempt %d/%d failed: %s", attempt, ATTEMPTS, tostring(lastErr))
task.wait(attempt * 1.5)
end
if not BX.alive() then
M.error = "retired by a newer copy"
return M
end
if not Rayfield then
log.error("could not load the UI library: %s", tostring(lastErr))
M.error = "Menu host unreachable (" .. tostring(lastErr) .. ")"
return M
end
local env = (type(getgenv) == "function" and getgenv()) or _G
task.spawn(function()
pcall(function()
if env.__BLYXO_WINDOW and not env.__BLYXO_WINDOW.unloaded then
env.__BLYXO_WINDOW:Unload()
end
end)
end)
task.wait()
local windowIcon = BX.require("ui.logo").icon()
local w0 = os.clock()
local okWin, window = bounded("CreateWindow", function()
return Rayfield:CreateWindow({
name = "BlyxoHub",
subtitle = BX.game or "Steal An Egg",
icon = windowIcon,
showName = "BlyxoHub",
sidebarLayout = true,
profile = "Welcome back",
theme = {
AccentColor     = Color3.fromRGB(255, 255, 255),
AccentStroke    = Color3.fromRGB(40, 40, 44),
AccentGlow      = 0.6,
TextColor       = Color3.fromRGB(236, 236, 240),
BackgroundColor = Color3.fromRGB(12, 12, 12),
ElementColor    = Color3.fromRGB(21, 21, 23),
WindowColor     = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 9, 10)),
ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 13, 14)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 27)),
}),
ElementGradient = ColorSequence.new(Color3.fromRGB(21, 21, 23), Color3.fromRGB(23, 23, 25)),
ElementStroke   = Color3.fromRGB(32, 32, 36),
ElementStrokeGradient = ColorSequence.new(Color3.fromRGB(36, 36, 40), Color3.fromRGB(30, 30, 34)),
ElementStrokeHover = Color3.fromRGB(48, 48, 54),
TabBackground   = ColorSequence.new(Color3.fromRGB(34, 34, 38), Color3.fromRGB(26, 26, 29)),
TabStroke       = ColorSequence.new(Color3.fromRGB(58, 58, 64), Color3.fromRGB(34, 34, 38)),
SliderBackground = Color3.fromRGB(30, 30, 33),
SliderBackgroundHover = Color3.fromRGB(38, 38, 42),
SliderProgress  = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 208)),
NeutralButton   = Color3.fromRGB(26, 26, 29),
NeutralButtonHover = Color3.fromRGB(34, 34, 38),
NeutralButtonStroke = Color3.fromRGB(58, 58, 64),
StatBackground  = Color3.fromRGB(18, 18, 20),
ShadowColor     = Color3.fromRGB(0, 0, 0),
},
configuration = {
autoSave = false,
autoLoad = false,
fileName = "BlyxoHub_" .. tostring(BX.game or "Steal An Egg"):gsub("%s+", ""),
},
})
end, INIT_TIMEOUT)
if not okWin or type(window) ~= "table" then
log.error("CreateWindow failed: %s", tostring(window))
M.error = "Could not build the menu (" .. tostring(window) .. ")"
return M
end
timeline("RAYFIELD WINDOW CREATED", ("%.0fms CreateWindow"):format((os.clock() - w0) * 1000))
env.__BLYXO_WINDOW = window
M.ok, M.window, M.lib = true, window, Rayfield
local heldShow = false
BX.try("window.holdShow", function()
if window.hidden and not window.animating then
window.animating = true
heldShow = true
end
end)
BX.try("window.versionTag", function()
window:CreateTag({
title = tostring(BX.versionTag or "V5.1"),
color = Color3.fromRGB(206, 206, 212),
})
end)
local sc = BX.scope("ui.window")
local screen = nil
BX.try("window.resolveGui", function()
if typeof(window.screenGui) == "Instance" and window.screenGui:IsA("ScreenGui") then
screen = window.screenGui
end
end)
if not screen then
BX.try("window.findGui", function()
local root = exec.hiddenParent()
for _ = 1, 20 do
for _, g in ipairs(root:GetChildren()) do
if g:IsA("ScreenGui") and g.Name ~= "BlyxoSplash"
and g.Name ~= "BlyxoStats" and g:FindFirstChild("Main") then
screen = g
break
end
end
if screen then break end
task.wait(0.05)
end
end)
if screen then
log.warn("window.screenGui missing - fell back to searching for it")
end
end
M.screen = screen
local hiddenByHub = false
if not screen then
log.error("could not resolve the menu ScreenGui - it cannot be hidden during loading")
end
local function keepIslandVisible()
BX.try("window.keepIsland", function()
local stats = BX._loaded["ui.stats"] or BX.require("ui.stats")
stats.setDock(nil)
stats.show(true)
if stats.setLauncher then stats.setLauncher(true) end
end)
end
local function suppressRayfieldLauncher()
local root = exec.hiddenParent()
for _, candidate in ipairs(root:GetChildren()) do
if candidate:IsA("ScreenGui") and candidate.Name ~= "BlyxoStats"
and candidate.Name ~= "BlyxoSplash" then
local candidateName = tostring(candidate.Name):lower()
if candidate ~= screen and candidateName:find("rayfield", 1, true) then
candidate.Enabled = false
continue
end
for _, d in ipairs(candidate:GetDescendants()) do
if (d:IsA("TextLabel") or d:IsA("TextButton")) then
local text = tostring(d.Text or ""):lower()
if text:find("tap to show", 1, true) then
if candidate == screen then
local holder = d.Parent
for _ = 1, 4 do
if not holder or holder.Parent == candidate then break end
if holder:IsA("GuiObject") and holder.AbsoluteSize.X >= 150 then break end
holder = holder.Parent
end
if holder and holder:IsA("GuiObject") then holder.Visible = false end
else
candidate.Enabled = false
end
break
end
end
end
end
end
end
local function hideRayfield()
hiddenByHub = true
if screen then screen.Enabled = false end
keepIslandVisible()
suppressRayfieldLauncher()
task.defer(function()
if screen then screen.Enabled = false end
keepIslandVisible()
suppressRayfieldLauncher()
end)
task.delay(0.15, function()
if screen then screen.Enabled = false end
suppressRayfieldLauncher()
end)
task.delay(0.5, suppressRayfieldLauncher)
end
local nativeUnload = window.Unload
local unloading = false
if type(nativeUnload) == "function" then
window.Unload = function(self, ...)
if unloading then return nativeUnload(self, ...) end
hideRayfield()
return true
end
end
local nativeMinimize = window.Minimize
if type(nativeMinimize) == "function" then
window.Minimize = function()
hideRayfield()
return true
end
end
local nativeClose = window.Close
if type(nativeClose) == "function" then
window.Close = function()
hideRayfield()
return true
end
end
function M.hide()
if not screen then return false end
hideRayfield()
return true
end
function M.reveal()
if not screen or not screen.Parent then return false end
hiddenByHub = false
screen.Enabled = true
BX.try("window.hideLauncher", function()
local stats = BX._loaded["ui.stats"] or BX.require("ui.stats")
if stats.setLauncher then stats.setLauncher(false) end
end)
if heldShow then
heldShow = false
window.animating = false
task.spawn(function()
BX.try("window.releaseShow", function()
if window.hidden and not window.unloaded then window:Show() end
end)
end)
end
return true
end
local boundChrome = setmetatable({}, { __mode = "k" })
local function bindChrome(obj)
if boundChrome[obj] or not obj:IsA("GuiButton") then return end
local text = tostring(obj:IsA("TextButton") and obj.Text or ""):gsub("%s+", "")
local name = tostring(obj.Name or ""):lower()
if name:find("blyxochromeoverlay", 1, true) then return end
local isHide = text == "-" or text == "−" or text == "×"
or text == "x" or name:find("minimi", 1, true)
or name:find("close", 1, true)
local inTopRight = false
pcall(function()
local x = screen.AbsolutePosition.X + screen.AbsoluteSize.X * 0.70
inTopRight = obj.AbsolutePosition.Y <= screen.AbsolutePosition.Y + 105
and obj.AbsolutePosition.X >= x
end)
if not isHide and not inTopRight then return end
boundChrome[obj] = true
BX.try("window.chromeOverlay", function()
local overlay = Instance.new("TextButton")
overlay.Name = "BlyxoChromeOverlay"
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Active = true
overlay.Selectable = false
overlay.AnchorPoint = obj.AnchorPoint
overlay.Position = obj.Position
overlay.Size = obj.Size
overlay.LayoutOrder = obj.LayoutOrder
overlay.Rotation = obj.Rotation
overlay.ZIndex = (obj.ZIndex or 1) + 10
overlay.Parent = obj.Parent
sc:connect(overlay.Activated, BX.guard("window.chromeOverlayClick", hideRayfield))
end)
pcall(function() obj.Active = false end)
sc:connect(UIS.InputBegan, BX.guard("window.chromeHide", function(inp)
local kind = inp.UserInputType
if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
local p = inp.Position
local a, s = obj.AbsolutePosition, obj.AbsoluteSize
if p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y then
hideRayfield()
end
end))
end
if screen then
BX.try("window.bindChrome", function()
for _, obj in ipairs(screen:GetDescendants()) do bindChrome(obj) end
sc:connect(screen.DescendantAdded, function(obj)
task.defer(function() pcall(bindChrome, obj) end)
end)
end)
end
if screen then
BX.try("window.bindChromeInput", function()
sc:connect(UIS.InputBegan, BX.guard("window.chromeInput", function(inp)
local kind = inp.UserInputType
if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
if not screen.Enabled then return end
local p = inp.Position
local a, s = screen.AbsolutePosition, screen.AbsoluteSize
local inChrome = p.Y >= a.Y and p.Y <= a.Y + 120
and p.X >= a.X + s.X * 0.72 and p.X <= a.X + s.X
if inChrome then hideRayfield() end
end))
local root = exec.hiddenParent()
sc:connect(root.ChildAdded, function(child)
task.defer(function()
if child:IsA("ScreenGui") then suppressRayfieldLauncher() end
end)
end)
end)
end
local restyled = setmetatable({}, { __mode = "k" })
local semibold = nil
pcall(function() semibold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold) end)
local function restyle(obj)
if restyled[obj] or not obj.Parent then return end
if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
restyled[obj] = true
local size = obj.TextSize
if size == 16 then
obj.TextSize = 14
if semibold and not obj:IsA("TextBox") then obj.FontFace = semibold end
elseif size >= 13 and size <= 15 then
obj.TextSize = 12
end
end
if screen then
BX.try("window.restyle", function()
local count = 0
for _, d in ipairs(screen:GetDescendants()) do
restyle(d)
count = count + 1
end
sc:connect(screen.DescendantAdded, function(d)
task.defer(function() pcall(restyle, d) end)
end)
log.info("restyle: %d existing instances checked", count)
end)
end
BX.try("window.welcomeBadge", function()
if window.profileSubtitle and window.profileName then
window.profileSubtitle.LayoutOrder = 1
window.profileName.LayoutOrder = 2
window.profileSubtitle.TextColor3 = Color3.fromRGB(120, 120, 128)
end
end)
function M.isVisible()
return screen ~= nil and screen.Parent ~= nil and screen.Enabled == true
end
function M.isHidden()
return hiddenByHub or not M.isVisible()
end
local ORDER = { Home = 10, Main = 20, Farm = 30, Event = 40,
Misc = 60, Config = 90 }
M.ORDER = ORDER
local tabsByName = {}
function M.tab(name, order)
local ok, t = BX.try("window.tab." .. name, function()
return window:CreateTab({ name = name, customOrder = order or ORDER[name] or 80 })
end)
if ok and t then tabsByName[name] = t end
return ok and t or nil
end
local UI_FILE = "BlyxoHub_ui.json"
local function readUi()
local raw = exec.readFile(UI_FILE)
if not raw then return {} end
local ok, t = pcall(function() return svc.HttpService:JSONDecode(raw) end)
return (ok and type(t) == "table") and t or {}
end
function M.restoreLastTab()
local saved = readUi().lastTab
local tab = saved and tabsByName[saved]
if tab then
BX.try("window.selectSaved", function() tab:Select(true) end)
log.info("reopened last tab: %s", tostring(saved))
end
local lastName = saved
sc:loop("rememberTab", 1.0, function()
local cur = window.selectedTab
local name = type(cur) == "table" and cur.name or nil
if not name or name == lastName or not tabsByName[name] then return end
lastName = name
BX.try("window.saveTab", function()
local t = readUi()
t.lastTab = name
exec.writeFile(UI_FILE, svc.HttpService:JSONEncode(t))
end)
end)
end
local hasNotify = type(Rayfield.Notify) == "function"
local hasToast = type(window.Toast) == "function"
function M.notify(title, content, duration)
log.info("[notify] %s: %s", tostring(title or "BlyxoHub"), tostring(content or ""))
local island = BX._loaded["ui.island"]
local text = tostring(content or "")
if island and island.show then
local ok = BX.try("window.island", function()
island.show("notify", {
title = tostring(title or "BlyxoHub"), sub = text,
hold = math.clamp(tonumber(duration) or 3, 2, 6),
})
end)
if ok then return true end
end
return false
end
M.hasNotify = hasNotify or hasToast
function M.unload()
unloading = true
BX.try("window.unload", function()
if window and not window.unloaded then
if type(nativeUnload) == "function" then nativeUnload(window) else window:Unload() end
end
end)
unloading = false
sc:destroy()
end
log.info("menu built")
return M
end)
BX.module("ui.adapter", function(BX)
local log = BX.require("boot.log").for_module("ui.adapter")
local M = {}
local backend = "rayfield"
function M.backend() return backend end
function M.setBackend(name)
backend = (name == "lib") and "lib" or "rayfield"
log.info("backend: %s", backend)
return backend
end
local stats = { created = 0, silentSets = 0, echoesSwallowed = 0, callbacks = 0 }
function M.stats() return table.clone(stats) end
local function wrapNative(el, kind, name)
local h = {
kind = kind, name = name, _el = el, _native = true,
}
function h:set(v) stats.silentSets = stats.silentSets + 1 el:set(v) end
function h:get() return el:get() end
function h:setOptions(o) if el.setOptions then return el:setOptions(o) end end
function h:Set(v) self:set(v) end
function h:Refresh(o, force) return self:setOptions(o, force) end
function h:Destroy() if el.destroy then el:destroy() end end
h.input = rawget(el, "input")
function h:options() return el.options and el:options() or {} end
function h:setTitle(t) if el.setTitle then el:setTitle(t) end end
function h:setDescription(t) if el.setDescription then el:setDescription(t) end end
function h:setVisible(v) if el.setVisible then el:setVisible(v) end end
function h:destroy() if el.destroy then el:destroy() end end
function h:raw() return el end
return h
end
local function rayValue(el)
if type(el) ~= "table" then return el end
local v = el.CurrentOption
if v ~= nil then return v end
v = el.CurrentValue
if v == nil then v = el.Value end
if v == nil then v = el.value end
return v
end
local function wrapRayfield(el, kind, name, guard)
local h = { kind = kind, name = name, _el = el, _native = false }
function h:set(v)
if el == nil then return end
stats.silentSets = stats.silentSets + 1
guard.writes = guard.writes + 1
local ok = BX.try("adapter.set/" .. tostring(name), function()
if type(el.Set) == "function" then
el:Set(v)
else
error("element has no Set()", 0)
end
end)
if not ok then
guard.writes = math.max(0, guard.writes - 1)
end
end
function h:get()
if el == nil then return nil end
return rayValue(el)
end
function h:Set(v) self:set(v) end
function h:setOptions(options, force)
if el == nil or type(options) ~= "table" then return false end
local sig = table.concat(options, "\0")
if not force and sig == self._sig then return true end
self._sig = sig
local applied = BX.try("adapter.setOptions/" .. tostring(name), function()
el:Refresh(options)
end)
if not applied then
task.wait()
applied = BX.try("adapter.setOptions.retry/" .. tostring(name), function()
el:Refresh(options)
end)
if not applied then self._sig = nil end
end
return applied
end
function h:Refresh(options, force)
return self:setOptions(options, force)
end
function h:options() return (type(el) == "table" and el.options) or {} end
function h:setTitle(t)
BX.try("adapter.setTitle", function()
if el.Set and self.kind == "label" then el:Set(t) end
end)
end
function h:SetTitle(t) self:setTitle(t) end
function h:setDescription() end
function h:setVisible(v)
BX.try("adapter.setVisible", function()
if type(el.SetVisible) == "function" then el:SetVisible(v and true or false) end
end)
end
function h:destroy()
BX.try("adapter.destroy", function()
if type(el.Destroy) == "function" then el:Destroy() end
end)
end
function h:raw() return el end
return h
end
function M.wrapTab(raw)
if raw == nil then return nil end
local native = type(raw.toggle) == "function"
local tab = { _raw = raw, native = native }
local function wrapCallback(name, fn, guard)
return function(value)
if guard.writes > 0 then
guard.writes = guard.writes - 1
stats.echoesSwallowed = stats.echoesSwallowed + 1
return
end
if not fn then return end
stats.callbacks = stats.callbacks + 1
BX.try("adapter.touchProfile", function()
local prof = BX._loaded["core.profiles"]
if prof and prof.touch then prof.touch() end
end)
task.spawn(function()
BX.try("ui/" .. tostring(name), fn, value)
end)
end
end
local function create(kind, opts)
opts = opts or {}
stats.created = stats.created + 1
local name = opts.name or kind
if native then
local el = raw[kind](raw, opts)
return wrapNative(el, kind, name)
end
local guard = { writes = 0 }
local o = table.clone(opts)
if o.callback then o.callback = wrapCallback(name, opts.callback, guard) end
if kind == "dropdown" and o.multi ~= nil then
o.multiSelect = o.multi and true or false
o.multi = nil
end
local method = ({
section = "CreateSection", label = "CreateText",
button = "CreateButton", toggle = "CreateToggle",
slider = "CreateSlider", dropdown = "CreateDropdown",
input = "CreateInput",
})[kind]
if not method or type(raw[method]) ~= "function" then
log.warn("backend has no %s", tostring(method or kind))
return wrapRayfield(nil, kind, name, guard)
end
local el = raw[method](raw, o)
return wrapRayfield(el, kind, name, guard)
end
function tab:CreateSection(o)  return create("section", o) end
function tab:CreateText(o)     return create("label", o) end
function tab:CreateLabel(o)    return create("label", o) end
function tab:CreateButton(o)   return create("button", o) end
function tab:CreateToggle(o)   return create("toggle", o) end
function tab:CreateSlider(o)   return create("slider", o) end
function tab:CreateDropdown(o) return create("dropdown", o) end
function tab:CreateInput(o)    return create("input", o) end
function tab:CreateRichCard(o)
o = o or {}
if native then
local el = raw:richCard(o)
return wrapNative(el, "richCard", o.name)
end
local text = tab:CreateText({ name = o.name, text = o.text })
if o.action then
tab:CreateButton({ name = o.action.label, callback = o.action.callback })
end
return text
end
function tab:CreateListCard(o)
o = o or {}
if native then
local el = raw:listCard(o)
return wrapNative(el, "listCard", o.name)
end
local lines = {}
for _, row in ipairs(o.rows or {}) do
lines[#lines + 1] = ("%s  %s"):format(tostring(row[1]), tostring(row[2]))
end
return tab:CreateText({ name = o.name, text = table.concat(lines, "\n") })
end
function tab:SetHeading(text)
if native and type(raw.heading) == "function" then raw:heading(text) end
end
function tab:CreateGroup(o)
if native and type(raw.row) == "function" then
local row = raw:row(o)
local g = { _row = row, native = true }
function g:CreateToggle(opts)
local el = row:toggle(opts)
return wrapNative(el, "toggle", opts and opts.name)
end
function g:CreateButton(opts)
local el = row:button(opts)
return wrapNative(el, "button", opts and opts.name)
end
return g
end
if type(raw.CreateGroup) == "function" then
local ok, row = pcall(raw.CreateGroup, raw, o)
if ok and row then return M.wrapTab(row) end
end
return tab
end
return tab
end
return M
end)
BX.module("ui.shell", function(BX)
local log = BX.require("boot.log").for_module("shell")
local ad = BX.require("ui.adapter")
local legacy = BX.require("ui.window")
local M = {
ok = legacy.ok,
error = legacy.error,
window = legacy.window,
screen = legacy.screen,
ORDER = legacy.ORDER,
backend = "rayfield",
}
if not legacy.ok then
log.error("Rayfield menu unavailable: %s", tostring(legacy.error))
return M
end
ad.setBackend("rayfield")
local tabs = {}
function M.tab(name)
if tabs[name] then return tabs[name] end
local raw = legacy.tab(name, M.ORDER[name])
if not raw then return nil end
local wrapped = ad.wrapTab(raw)
tabs[name] = wrapped
return wrapped
end
function M.hide()
return legacy.hide()
end
function M.reveal()
local shown = legacy.reveal()
BX.try("shell.stats", function()
local cfg = BX.require("core.config")
if cfg.SHOW_STATS then
local stats = BX.require("ui.stats")
stats.setDock(nil)
stats.show(true)
end
end)
return shown
end
function M.isVisible()
return legacy.isVisible()
end
function M.isHidden()
return type(legacy.isHidden) == "function" and legacy.isHidden() or not M.isVisible()
end
function M.notify(title, content, duration)
return legacy.notify(title, content, duration)
end
M.hasNotify = legacy.hasNotify
function M.restoreLastTab()
return legacy.restoreLastTab()
end
function M.unload()
local stats = BX._loaded["ui.stats"]
if stats and type(stats.show) == "function" then
BX.try("shell.stats.hide", function() stats.show(false) end)
end
return legacy.unload()
end
M.win = legacy.window
log.info("menu built on Rayfield; Dynamic Island remains external")
return M
end)
BX.module("ui.tabs.home", function(BX)
local exec = BX.require("core.exec")
local win  = BX.require("ui.shell")
local log  = BX.require("boot.log").for_module("home")
local M = {}
local INVITE = "https://discord.gg/9KSXyabAYV"
local UPDATES = type(BX.releaseNotes) == "table" and BX.releaseNotes or {
{ "New",      "Added support to Xeno and Solara" },
{ "Fixed",    "Smoother loading and more reliable session state" },
{ "Improved", "Unified stats, delivery feedback, and rejoin flow" },
}
local function openDiscord()
BX.try("home.openBrowser", function()
game:GetService("GuiService"):OpenBrowserWindow(INVITE)
end)
local copied = exec.clipboard(INVITE)
log.info("discord: opened (copied=%s)", tostring(copied))
win.notify("BlyxoHub", copied and "Discord opened and invite copied"
or ("Join at " .. INVITE))
end
function M.build(tab)
if not tab then return M end
if type(tab.SetHeading) == "function" then
tab:SetHeading("BlyxoHub Community")
end
tab:CreateRichCard({
name = "Community",
text = "Release notes, support, and early access for BlyxoHub users.",
action = { label = "Join Discord", callback = openDiscord },
})
tab:CreateSection({ name = "Updates" })
local major = tostring(BX.version or "5"):match("^(%d+)") or "5"
tab:CreateListCard({
name = "Latest",
badge = ("V%s Release"):format(major),
rows = UPDATES,
})
return M
end
return M
end)
BX.module("ui.tabs.misc", function(BX)
local servers = BX.require("features.misc.servers")
local hook    = BX.require("features.misc.webhook")
local fps     = BX.require("features.fps")
local win     = BX.require("ui.shell")
local prof    = BX.require("core.profiles")
local log     = BX.require("boot.log").for_module("misc.tab")
local cfg     = BX.require("core.config")
local exec    = BX.require("core.exec")
local M = {}
local webhookStatus = nil
local fpsToggle = nil
function M.setFpsBoost(on)
on = on and true or false
if fpsToggle and fpsToggle.Set then
BX.try("misc.fpsSet", function() fpsToggle:Set(on) end)
else
if not on then fps.userTurnedOff = true end
BX.try("misc.fpsDirect", function() fps.setEnabled(on) end)
end
end
local function say(title, ok, msg)
win.notify(title, tostring(msg), ok and 3 or 4)
end
function M.build(tab)
if not tab then return M end
tab:CreateSection({ name = "Performance" })
fpsToggle = tab:CreateToggle({
name = "Low Graphics",
description = "Reduce rendering load for smoother FPS.",
value = cfg.AUTO_FPS_BOOST == true,
callback = function(on)
on = on and true or false
if not on then fps.userTurnedOff = true end
BX.try("misc.fpsToggle", function() fps.setEnabled(on) end)
end,
})
tab:CreateSection({ name = "Servers" })
tab:CreateButton({
name = "Rejoin Server",
callback = function()
local ok, msg = servers.rejoin()
say("Servers", ok, msg)
end,
})
tab:CreateSection({ name = "Webhooks" })
webhookStatus = tab:CreateText({
name = "Webhook",
text = hook.hasUrl() and ("Sending to " .. hook.redactedUrl())
or "No URL set - paste one below",
})
tab:CreateInput({
name = "Webhook URL",
description = "Discord webhook. Stored on this device, not in your profile.",
placeholder = "https://discord.com/api/webhooks/...",
callback = function(value)
local ok, why = hook.setUrl(value)
BX.try("misc.webhookUrlStatus", function()
if not webhookStatus then return end
if ok and hook.hasUrl() then
webhookStatus:Set("Saved - sending to " .. hook.redactedUrl())
elseif ok then
webhookStatus:Set("No URL set - paste one below")
else
webhookStatus:Set(tostring(why))
end
end)
win.notify("Webhook", tostring(why or (ok and "Saved" or "Rejected")), 4)
end,
})
tab:CreateButton({
name = "Send Test Message",
description = "Posts one test payload to the URL above.",
callback = function()
if not hook.hasUrl() then
win.notify("Webhook", "Set a URL first", 4)
return
end
local ok, why = hook.test()
win.notify("Webhook", ok and "Test sent" or tostring(why or "Test failed"), 5)
end,
})
tab:CreateToggle({
name = "Webhook Logging",
description = "Send delivery events to the configured endpoint.",
value = false,
flag = "WebhookOn",
callback = function(on)
BX.try("misc.webhookToggle", function() hook.setEnabled(on) end)
if on and not exec.can.request then
local why = "Webhooks are not supported by this executor (no HTTP request API)"
log.warn("%s", why)
win.notify("Webhook", why, 6)
BX.try("misc.webhookStatus", function()
if webhookStatus then webhookStatus:Set(why) end
end)
end
end,
})
if not exec.can.request then
BX.try("misc.webhookUnsupported", function()
if webhookStatus then
webhookStatus:Set("HTTP request support is unavailable on this executor.")
end
end)
end
log.info("misc tab built")
return M
end
function M.teardown()
webhookStatus, fpsToggle = nil, nil
BX.try("misc.teardown", function() hook.setEnabled(false) end)
log.info("misc tab torn down")
end
return M
end)
BX.module("ui.tabs.config", function(BX)
local prof = BX.require("core.profiles")
local win  = BX.require("ui.shell")
local log  = BX.require("boot.log").for_module("config.tab")
local M = {}
local loadDrop
local NONE = "None"
local function say(ok, msg)
win.notify("Config", tostring(msg), ok and 3 or 4)
end
local function options()
local list = prof.list()
local out = { NONE }
for _, n in ipairs(list) do out[#out + 1] = n end
return out
end
local function refreshLists()
local opts = options()
BX.try("config.refreshLists", function()
if loadDrop and loadDrop.Refresh then loadDrop:Refresh(opts) end
end)
return opts
end
local function pick(v)
local s = type(v) == "table" and v[1] or v
s = tostring(s or "")
if s == NONE then return "" end
return s
end
function M.build(tab)
if not tab then return M end
tab:CreateSection({ name = "Profiles" })
if not prof.available() then
tab:CreateText({
name = "Profiles",
text = "Saving settings is not supported by this executor. Everything else works.",
})
log.warn("no filesystem (%s) - profile controls not built",
table.concat(BX.require("core.exec").report().missing, ","))
return M
end
local pendingName = ""
tab:CreateInput({
name = "Profile Name",
description = "What to call the next save. Blank saves as Default.",
placeholder = "farm setup",
callback = function(value)
pendingName = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end,
})
tab:CreateButton({
name = "Save Profile",
description = "Store current settings under the name above.",
callback = function()
local name = pendingName ~= "" and pendingName or "Default"
local ok, msg = prof.save(name)
if ok then
refreshLists()
msg = ("Saved as %q"):format(name)
end
say(ok, msg)
end,
})
tab:CreateButton({
name = "Delete Profile",
description = "Removes the profile selected under Load Profile.",
callback = function()
local name = loadDrop and pick(loadDrop.get and loadDrop:get() or nil) or ""
if name == "" then
say(false, "Pick a profile under Load Profile first")
return
end
local ok, msg = prof.delete(name)
if ok then
refreshLists()
msg = ("Deleted %q"):format(name)
end
say(ok, msg)
end,
})
tab:CreateSection({ name = "Loading" })
loadDrop = tab:CreateDropdown({
name = "Load Profile",
options = options(),
currentOption = prof.autoLoadName() or NONE,
callback = function(v)
local name = pick(v)
if name == "" then return end
local ok, msg = prof.load(name)
say(ok, msg)
end,
})
tab:CreateToggle({
name = "Auto Load Profile",
description = "Load the selected profile on start.",
value = prof.autoLoadName() ~= nil,
callback = function(on)
local selected = loadDrop and loadDrop:get() or ""
local ok, msg = prof.setAutoLoad(on and pick(selected) or "")
say(ok, msg)
end,
})
tab:CreateButton({
name = "Unload BlyxoHub",
description = "Close the hub and stop its workers.",
callback = function() win.unload() end,
})
log.info("config tab built (%d profiles)", #prof.list())
return M
end
return M
end)
BX.module("features.gamethrottle", function(BX)
local svc  = BX.require("core.services")
local st   = BX.require("core.state")
local exec = BX.require("core.exec")
local log  = BX.require("boot.log").for_module("gamethrottle")
local M = {}
local K = {
PETS_HZ    = 20,
PROMPTS_HZ = 10,
}
M.K = K
local env = (type(getgenv) == "function" and getgenv()) or _G
local ENV_KEY = "__BLYXO_THROTTLE"
local enabled = false
local stats = { pets = false, prompts = false, petSteps = 0, petSkips = 0,
promptSteps = 0, promptSkips = 0 }
function M.isOn() return enabled end
function M.stats() return table.clone(stats) end
local function petsClass()
local mod
pcall(function()
mod = svc.Players.LocalPlayer.PlayerScripts.Game.Plots
.ActiveAssetsController.AssetMovementBatch
end)
if not (mod and mod:IsA("ModuleScript")) then return nil end
local ok, cls = pcall(require, mod)
if ok and type(cls) == "table" and type(rawget(cls, "_step")) == "function" then
return cls
end
return nil
end
local function followerAdvance()
if exec.fragile then return nil end
local getups = (debug and debug.getupvalues) or rawget(env, "getupvalues")
if type(getups) ~= "function" then return nil end
local mod = svc.ReplicatedStorage:FindFirstChild("Client")
mod = mod and mod:FindFirstChild("SmartProximityPrompt")
mod = mod and mod:FindFirstChild("FollowerLoop")
if not (mod and mod:IsA("ModuleScript")) then return nil end
local ok, lib = pcall(require, mod)
if not ok or type(lib) ~= "table" or type(lib.Add) ~= "function" then return nil end
local okU, ups = pcall(getups, lib.Add)
if not okU or type(ups) ~= "table" then return nil end
for _, u in pairs(ups) do
if type(u) == "function" then
local okN, name = pcall(debug.info, u, "n")
if okN and name == "advance" then return u end
end
end
return nil
end
local function restore(rec, why)
if type(rec) ~= "table" then return end
if rec.cls and rec.step then
pcall(rawset, rec.cls, "_step", rec.step)
end
if rec.advance and rec.advanceOrig and type(hookfunction) == "function" then
pcall(hookfunction, rec.advance, rec.advanceOrig)
end
log.info("restored game loops (%s)", tostring(why))
end
if type(env[ENV_KEY]) == "table" then
local stale = env[ENV_KEY]
env[ENV_KEY] = nil
BX.try("throttle.restoreStale", restore, stale, "previous copy")
end
function M.setEnabled(on)
on = on and true or false
if on == enabled then return true end
if not on then
enabled = false
restore(env[ENV_KEY], "toggled off")
env[ENV_KEY] = nil
stats.pets, stats.prompts = false, false
return true
end
enabled = true
local rec = {}
env[ENV_KEY] = rec
BX.try("throttle.pets", function()
if exec.fragile then log.info("fragile executor - game loops left alone") return end
local cls = petsClass()
if not cls then log.info("pet movement batch not found - left alone") return end
local orig = rawget(cls, "_step")
local period = 1 / K.PETS_HZ
local acc = setmetatable({}, { __mode = "k" })
rec.cls, rec.step = cls, orig
rawset(cls, "_step", function(self, dt)
local a = (acc[self] or 0) + (tonumber(dt) or 0)
if a < period then
acc[self] = a
stats.petSkips = stats.petSkips + 1
return
end
acc[self] = 0
stats.petSteps = stats.petSteps + 1
return orig(self, a)
end)
stats.pets = true
end)
BX.try("throttle.prompts", function()
if not exec.can.hooking or type(hookfunction) ~= "function" then
log.info("no hookfunction - prompt follower left alone")
return
end
local advance = followerAdvance()
if not advance then log.info("prompt follower not found - left alone") return end
local period = 1 / K.PROMPTS_HZ
local acc = 0
local orig
local function throttled(dt)
dt = tonumber(dt) or 0
if st.autoStealOn then
acc = 0
return orig(dt)
end
acc = acc + dt
if acc < period then
stats.promptSkips = stats.promptSkips + 1
return
end
local d = acc
acc = 0
stats.promptSteps = stats.promptSteps + 1
return orig(d)
end
orig = hookfunction(advance, throttled)
rec.advance, rec.advanceOrig = advance, orig
stats.prompts = true
end)
log.info("on (pets %s @%dHz, prompts %s @%dHz)",
tostring(stats.pets), K.PETS_HZ, tostring(stats.prompts), K.PROMPTS_HZ)
return true
end
return M
end)
BX.module("features.fps", function(BX)
local svc = BX.require("core.services")
local log = BX.require("boot.log").for_module("fps")
local scan = BX.require("core.scan")
local M = {}
local K = {
BUDGET      = 0.002,  
MESH_PER_FRAME = 12,  
GUI_SURFACE = 150,    
PRUNE_EVERY = 30,     
DEFER       = 5.0,    
MAX_BOOST   = 40000,  
GUI_DISTANCE = 120,   
MAX_POTATO  = 400000, 
}
M.K = K
local env = (type(getgenv) == "function" and getgenv()) or _G
local exec = BX.require("core.exec")
if exec.fragile then
K.BUDGET, K.DEFER = 0.001, 8.0
K.MESH_PER_FRAME = 4
end
local MESH_LOD = BX.require("core.config").FPS_MESH_LOD == true and not exec.fragile
local function newRecord()
return { objs = {}, keys = {}, was = {}, n = 0 }
end
local function restoreRecord(rec, why)
if type(rec) ~= "table" then return 0 end
local put = 0
if type(rec.props) == "table" then
for i = #rec.props, 1, -1 do
local e = rec.props[i]
if e and e.obj and pcall(function() e.obj[e.key] = e.was end) then put = put + 1 end
rec.props[i] = nil
end
log.info("restored %d properties (%s, previous build)", put, tostring(why))
return put
end
if type(rec.objs) ~= "table" then return 0 end
for i = rec.n or #rec.objs, 1, -1 do
local obj, key = rec.objs[i], rec.keys[i]
if obj ~= nil and key ~= nil then
if pcall(function() obj[key] = rec.was[i] end) then put = put + 1 end
end
rec.objs[i], rec.keys[i], rec.was[i] = nil, nil, nil
end
rec.n = 0
log.info("restored %d properties (%s)", put, tostring(why))
return put
end
local function fences()
local esp = workspace:FindFirstChild("BlyxoESP")
local plr = svc.Players.LocalPlayer
return esp, plr and plr.Character
end
local function offLimits(d, esp, char)
if esp and d:IsDescendantOf(esp) then return true end
if char and d:IsDescendantOf(char) then return true end
return false
end
local function makeTier(def)
local T = { enabled = false, sweeping = false, rec = nil, sc = nil,
stats = { changed = 0, added = 0, pruned = 0, refused = 0, sweepMs = 0, seen = 0 } }
if type(env[def.envKey]) == "table" then
local stale = env[def.envKey]
env[def.envKey] = nil
BX.try("fps.restoreStale." .. def.name, function()
restoreRecord(stale, def.name .. ": previous copy, before re-applying")
end)
end
local function set(obj, key, value)
local rec = T.rec
if not rec then return false end
if rec.n >= def.cap then
T.stats.refused = T.stats.refused + 1
if T.stats.refused == 1 then
log.warn("%s: tracking ceiling of %d reached - further instances left as they are",
def.name, def.cap)
end
return false
end
local was
if not pcall(function() was = obj[key] end) then return false end
if was == value then return false end
if not pcall(function() obj[key] = value end) then return false end
local n = rec.n + 1
rec.n = n
rec.objs[n], rec.keys[n], rec.was[n] = obj, key, was
T.stats.changed = T.stats.changed + 1
return true
end
local function handle(d, esp, char)
local ok = pcall(def.match, d, set, esp, char, T)
return ok
end
local function sweep()
if T.sweeping then return end
T.sweeping = true
local t0 = os.clock()
local before = T.stats.changed
local esp, char = fences()
for _, d in ipairs(scan.snapshot(svc.Lighting, K.BUDGET)) do handle(d, esp, char) end
local desc = M._snapshot
if not desc or (os.clock() - (M._snapshotAt or 0)) > 60 then
desc = scan.snapshot(workspace, K.BUDGET)
M._snapshot, M._snapshotAt = desc, os.clock()
end
local total = #desc
T.stats.seen = total
local function stealBusy()
local ok, busy = BX.try("fps.stealBusy", function()
local auto = BX._loaded["features.autosteal"]
return auto and auto.isRunning() and auto.isBusy()
end)
return ok and busy == true
end
local i = 1
while i <= total do
while stealBusy() and T.enabled and T.sc and T.sc:alive() do
svc.RunService.Heartbeat:Wait()
end
esp, char = fences()
local f0 = os.clock()
T.meshBudget = K.MESH_PER_FRAME
for j = i, total do
local d = desc[j]
if d then handle(d, esp, char) end
i = j + 1
if (os.clock() - f0) >= K.BUDGET then break end
end
svc.RunService.Heartbeat:Wait()
if not T.enabled or not (T.sc and T.sc:alive()) then break end
end
desc = nil
if def.name == "potato" then M._snapshot = nil end
while T.deferMesh and #T.deferMesh > 0 and T.enabled and T.sc and T.sc:alive() do
while stealBusy() and T.enabled and T.sc and T.sc:alive() do
svc.RunService.Heartbeat:Wait()
end
local esp2, char2 = fences()
for _ = 1, K.MESH_PER_FRAME do
local d = table.remove(T.deferMesh)
if not d then break end
if d.Parent and not offLimits(d, esp2, char2) then
set(d, "RenderFidelity", Enum.RenderFidelity.Performance)
end
end
svc.RunService.Heartbeat:Wait()
end
T.deferMesh = nil
T.stats.sweepMs = (os.clock() - t0) * 1000
T.sweeping = false
log.info("%s sweep: %d descendants, %d properties changed, %.0fms",
def.name, total, T.stats.changed - before, T.stats.sweepMs)
if def.afterSweep and T.enabled then BX.try("fps.afterSweep." .. def.name, def.afterSweep) end
end
function T.setEnabled(on)
on = on and true or false
if on == T.enabled then return true end
T.enabled = on
if not on then
if T.sc then T.sc:destroy() T.sc = nil end
if def.onOff then BX.try("fps.onOff." .. def.name, def.onOff) end
local put = restoreRecord(T.rec, def.name .. " toggled off")
T.rec = nil
env[def.envKey] = nil
T.stats.changed = 0
log.info("%s off (%d properties restored)", def.name, put)
return true
end
T.rec = newRecord()
env[def.envKey] = T.rec      
T.sc = BX.scope("features.fps." .. def.name)
if def.globals then BX.try("fps.globals." .. def.name, def.globals, set) end
if def.onOn then BX.try("fps.onOn." .. def.name, def.onOn) end
T.sc:spawn("sweep", sweep)
local function added(d)
if not T.enabled then return end
local esp, char = fences()
local n0 = T.stats.changed
handle(d, esp, char)
if T.stats.changed > n0 then T.stats.added = T.stats.added + 1 end
end
T.sc:connect(workspace.DescendantAdded, BX.guard("fps.added." .. def.name, added))
T.sc:connect(svc.Lighting.DescendantAdded, BX.guard("fps.addedLighting." .. def.name, added))
T.sc:loop("prune", K.PRUNE_EVERY, function()
local rec = T.rec
if not rec then return end
local objs, keys, was = rec.objs, rec.keys, rec.was
local keep, dropped = 0, 0
for idx = 1, rec.n do
local obj = objs[idx]
local gone = obj == nil or (typeof(obj) == "Instance" and obj.Parent == nil)
if gone then
dropped = dropped + 1
else
keep = keep + 1
objs[keep], keys[keep], was[keep] = obj, keys[idx], was[idx]
end
end
for idx = keep + 1, rec.n do objs[idx], keys[idx], was[idx] = nil, nil, nil end
rec.n = keep
if dropped > 0 then
T.stats.pruned = T.stats.pruned + dropped
log.trace("%s: pruned %d destroyed (%d tracked)", def.name, dropped, keep)
end
end)
log.info("%s on", def.name)
return true
end
function T.snapshot()
local s = table.clone(T.stats)
s.on = T.enabled
s.tracked = T.rec and T.rec.n or 0
return s
end
BX.onTeardown("fps." .. def.name, function() T.setEnabled(false) end)
return T
end
local EFFECTS = {
ParticleEmitter = true, Trail = true, Beam = true,
Smoke = true, Fire = true, Sparkles = true,
}
local POST = {
BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
SunRaysEffect = true, DepthOfFieldEffect = true,
}
local LIGHTS = { PointLight = true, SpotLight = true, SurfaceLight = true }
BX.try("fps.throttleStale", function() BX.require("features.gamethrottle") end)
local boost = makeTier({
name = "boost", envKey = "__BLYXO_FPS", cap = K.MAX_BOOST,
match = function(d, set, esp, char, T)
local cls = d.ClassName
if EFFECTS[cls] then
if not offLimits(d, esp, char) then set(d, "Enabled", false) end
elseif POST[cls] then
set(d, "Enabled", false)
elseif cls == "Clouds" then
set(d, "Enabled", false)
elseif cls == "Atmosphere" then
set(d, "Density", 0)
set(d, "Haze", 0)
set(d, "Glare", 0)
elseif LIGHTS[cls] then
if not offLimits(d, esp, char) then set(d, "Shadows", false) end
elseif cls == "MeshPart" then
if MESH_LOD and not offLimits(d, esp, char) and d.RenderFidelity ~= Enum.RenderFidelity.Performance then
local left = T and T.meshBudget
if left ~= nil then
if left <= 0 then
T.deferMesh = T.deferMesh or {}
T.deferMesh[#T.deferMesh + 1] = d
return
end
T.meshBudget = left - 1
end
set(d, "RenderFidelity", Enum.RenderFidelity.Performance)
end
elseif cls == "BillboardGui" then
if not offLimits(d, esp, char) then
local md = d.MaxDistance
if md == 0 or md > K.GUI_DISTANCE then set(d, "MaxDistance", K.GUI_DISTANCE) end
end
elseif cls == "SurfaceGui" then
if not offLimits(d, esp, char) then
local md = d.MaxDistance
if md == 0 or md > K.GUI_SURFACE then set(d, "MaxDistance", K.GUI_SURFACE) end
end
elseif cls == "Highlight" then
if not offLimits(d, esp, char) then set(d, "Enabled", false) end
elseif cls == "Explosion" then
set(d, "Visible", false)
end
end,
globals = function(set)
set(svc.Lighting, "GlobalShadows", false)
local ter = workspace:FindFirstChildOfClass("Terrain")
if ter then
set(ter, "Decoration", false)
set(ter, "WaterWaveSize", 0)
set(ter, "WaterWaveSpeed", 0)
set(ter, "WaterReflectance", 0)
set(ter, "WaterTransparency", 0)
end
set(svc.Lighting, "EnvironmentDiffuseScale", 0)
set(svc.Lighting, "EnvironmentSpecularScale", 0)
set(svc.Lighting, "ShadowSoftness", 0)
local sky = svc.Lighting:FindFirstChildOfClass("Sky")
if sky then
set(sky, "CelestialBodiesShown", false)
set(sky, "StarCount", 0)
end
if exec.fragile then return end
local okR, r = pcall(function() return settings().Rendering end)
if okR and r then
set(r, "QualityLevel", Enum.QualityLevel.Level01)
pcall(function() set(r, "EditQualityLevel", Enum.QualityLevel.Level01) end)
pcall(function() set(r, "MeshPartDetailLevel", Enum.MeshPartDetailLevel.Level04) end)
end
pcall(function()
local ugs = UserSettings():GetService("UserGameSettings")
set(ugs, "SavedQualityLevel", Enum.SavedQualitySetting.QualityLevel1)
end)
end,
onOn = function()
BX.require("features.gamethrottle").setEnabled(true)
end,
afterSweep = function()
if M.wantAll and not M._potato.enabled then M._potato.setEnabled(true) end
end,
onOff = function()
BX.require("features.gamethrottle").setEnabled(false)
end,
})
local TEXTURED = { Decal = true, Texture = true }
local potato = makeTier({
name = "potato", envKey = "__BLYXO_FPS_POTATO", cap = K.MAX_POTATO,
match = function(d, set, esp, char)
local cls = d.ClassName
if TEXTURED[cls] then
if not offLimits(d, esp, char) then set(d, "Transparency", 1) end
elseif cls == "SpecialMesh" then
if not offLimits(d, esp, char) then set(d, "TextureId", "") end
elseif cls == "MeshPart" then
if d.TextureID ~= "" and not offLimits(d, esp, char) then set(d, "TextureID", "") end
elseif cls ~= "Terrain" and d:IsA("BasePart") then
if d.Reflectance ~= 0 and not offLimits(d, esp, char) then set(d, "Reflectance", 0) end
end
end,
})
M._potato = potato
function M.isOn() return boost.enabled end
function M.setEnabled(on)
on = on and true or false
M.wantAll = on
if not on then
M.userTurnedOff = true
potato.setEnabled(false)
return boost.setEnabled(false)
end
return boost.setEnabled(true)
end
function M.stats()
local b, p = boost.snapshot(), potato.snapshot()
return {
boost = b, potato = p,
effects = b.changed, tracked = b.tracked + p.tracked, sweepMs = b.sweepMs + p.sweepMs,
}
end
BX.profile.watch("fps.tracked", function()
return (boost.rec and boost.rec.n or 0) + (potato.rec and potato.rec.n or 0)
end)
local armed = false
function M.arm()
if armed then return false end
armed = true
task.delay(K.DEFER, function()
if not BX.alive() then return end
if boost.enabled or M.userTurnedOff then return end
BX.try("fps.armApply", function() M.setEnabled(true) end)
end)
return true
end
return M
end)
BX.module("features.misc.servers", function(BX)
local svc  = BX.require("core.services")
local exec = BX.require("core.exec")
local log  = BX.require("boot.log").for_module("servers")
local M = {}
local K = {
MAX_PAGES = 5, TRIES = 4,
FAILED_FOR = 600,     
FAILED_MAX = 200,     
TP_SETTLE  = 2.5,
}
M.K = K
local searching = false
local failed, failedN = {}, 0
BX.profile.watch("servers.failed", function() return failedN end)
local function pruneFailed()
local now = os.clock()
local live, n = {}, 0
for id, at in pairs(failed) do
if (now - at) > K.FAILED_FOR then
failed[id] = nil
else
n = n + 1
live[n] = id
end
end
if n > K.FAILED_MAX then
table.sort(live, function(a, b) return failed[a] < failed[b] end)
for i = 1, n - K.FAILED_MAX do
failed[live[i]] = nil
end
n = K.FAILED_MAX
end
failedN = n
end
local function markFailed(id)
if not id then return end
failed[id] = os.clock()
pruneFailed()
end
local function canFetch()
if exec.can.request then return true end
local ok, f = pcall(function() return game.HttpGet end)
return ok and type(f) == "function"
end
local function fetchPage(cursor)
local url = ("https://games.roblox.com/v1/games/%d/servers/Public"
.. "?sortOrder=Asc&limit=100"):format(game.PlaceId)
if cursor then url = url .. "&cursor=" .. tostring(cursor) end
local body, via, status
if exec.can.request then
local res
BX.try("servers.fetch", function()
res = exec.httpRequest({ Url = url, Method = "GET" })
end)
body = res and (res.Body or res.body)
status = res and (res.StatusCode or res.status_code)
via = "request"
end
if not body then
local ok, got = pcall(function() return game:HttpGet(url) end)
if ok and type(got) == "string" then body, via = got, "HttpGet"
elseif not ok then status = tostring(got) end
end
if not body then
log.warn("server list: no response (via %s, %s)", tostring(via), tostring(status))
return nil, "no response" .. (tostring(status):find("429") and " - rate limited, wait a few seconds" or "")
end
local decoded
pcall(function() decoded = svc.HttpService:JSONDecode(body) end)
if type(decoded) ~= "table" or type(decoded.data) ~= "table" then
log.warn("server list: unreadable (via %s, status %s, %d bytes: %s)",
tostring(via), tostring(status), #body, body:sub(1, 80))
return nil, "unreadable list"
end
log.info("server list: page via %s, %d servers%s", via, #decoded.data,
decoded.nextPageCursor and ", more pages" or "")
return decoded
end
local function candidates()
pruneFailed()
local out, cursor = {}, nil
local here = tostring(game.JobId)
local listed, pages, why = 0, 0, nil
for _ = 1, K.MAX_PAGES do
local page, err = fetchPage(cursor)
if not page then why = why or err break end
pages = pages + 1
for _, sv in ipairs(page.data) do
listed = listed + 1
local playing = tonumber(sv.playing) or 0
local maxP = tonumber(sv.maxPlayers) or 0
if sv.id and sv.id ~= here             
and not failed[sv.id]               
and maxP > 0 and playing < maxP     
then
out[#out + 1] = {
id = sv.id, playing = playing, maxPlayers = maxP,
ping = tonumber(sv.ping) or 0,
}
end
end
cursor = page.nextPageCursor
if not cursor then break end
end
log.info("candidates: %d of %d listed over %d page(s) (here=%s, failed cache=%d)",
#out, listed, pages, here:sub(1, 8), failedN)
return out, listed, why
end
local function teleport(sv)
local failedWhy = nil
local conn
pcall(function()
conn = svc.TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
if plr == svc.Players.LocalPlayer then
failedWhy = tostring(result) .. " " .. tostring(msg or "")
end
end)
end)
log.info("teleporting to %s (%d/%d players)", tostring(sv.id):sub(1, 8),
sv.playing, sv.maxPlayers)
pcall(function() BX.require("boot.log").flushNow() end)
local ok, err = pcall(function()
svc.TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id,
svc.Players.LocalPlayer)
end)
if ok then
local t0 = os.clock()
while not failedWhy and (os.clock() - t0) < K.TP_SETTLE do task.wait(0.1) end
end
if conn then pcall(function() conn:Disconnect() end) end
if not ok or failedWhy then
markFailed(sv.id)
log.warn("teleport to %s failed: %s", tostring(sv.id):sub(1, 8),
tostring(failedWhy or err))
return false, failedWhy or err
end
log.info("teleport requested: %s (%d/%d players)", tostring(sv.id):sub(1, 8),
sv.playing, sv.maxPlayers)
return true
end
local function go(order, what)
if searching then return false, "Already searching" end
if not canFetch() then
log.warn("%s: no HTTP capability on this executor (request=%s)", what, tostring(exec.can.request))
return false, "Server search is not supported by this executor"
end
searching = true
log.info("%s: click", what)
local okRun, ok, msg = pcall(function()
local list, listed, why = candidates()
if #list == 0 then
if listed == 0 then
return false, "Could not read the server list" .. (why and (" (" .. why .. ")") or "")
end
return false, ("All %d listed servers are full or recently refused us"):format(listed)
end
table.sort(list, order)
local lastWhy
for i = 1, math.min(#list, K.TRIES) do
local sv = list[i]
local tpOk, tpWhy = teleport(sv)
if tpOk then
log.info("%s: joining %d/%d players (listed ping %s)", what, sv.playing, sv.maxPlayers, tostring(sv.ping))
if what == "ping" and sv.ping > 0 then
return true, ("Joining a server with %dms ping, %d players"):format(sv.ping, sv.playing)
end
return true, ("Joining a server with %d players"):format(sv.playing)
end
lastWhy = tpWhy
end
return false, "Teleport refused " .. math.min(#list, K.TRIES) .. " times"
.. (lastWhy and (" (" .. tostring(lastWhy) .. ")") or "") .. " - press again"
end)
searching = false
if not okRun then
log.warn("%s: failed: %s", what, tostring(ok))
return false, "Server search failed - see the log"
end
return ok, msg
end
function M.lowestServer()
return go(function(a, b)
if a.playing ~= b.playing then return a.playing < b.playing end
local ap = a.ping > 0 and a.ping or math.huge
local bp = b.ping > 0 and b.ping or math.huge
return ap < bp
end, "lowest")
end
function M.bestPing()
return go(function(a, b)
local ap = a.ping > 0 and a.ping or math.huge
local bp = b.ping > 0 and b.ping or math.huge
if ap ~= bp then return ap < bp end
return a.playing < b.playing
end, "ping")
end
function M.hop()
return go(function(a, b) return a.playing < b.playing end, "hop")
end
function M.rejoin()
if searching then return false, "Already switching servers" end
local plr = svc.Players.LocalPlayer
log.info("rejoin: click (job %s)", tostring(game.JobId):sub(1, 8))
pcall(function() BX.require("boot.log").flushNow() end)
local ok, err = pcall(function()
if #svc.Players:GetPlayers() <= 1 or game.JobId == "" then
svc.TeleportService:Teleport(game.PlaceId, plr)
else
svc.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end
end)
if not ok then
log.warn("rejoin failed: %s", tostring(err))
return false, "Could not rejoin - try Server Hop"
end
return true, "Rejoining this server..."
end
function M.stats()
pruneFailed()
return { failedServers = failedN, searching = searching }
end
return M
end)
BX.module("features.misc.webhook", function(BX)
local svc  = BX.require("core.services")
local exec = BX.require("core.exec")
local util = BX.require("core.util")
local log  = BX.require("boot.log").for_module("webhook")
local M = {}
local K = { MIN_GAP = 3.0, TIMEOUT = 8 }
M.K = K
local enabled = false
local url = nil              
local lastSend = 0
local stats = { sent = 0, failed = 0, dropped = 0, skipped = 0 }
function M.stats() return table.clone(stats) end
function M.isOn() return enabled end
function M.hasUrl() return url ~= nil and url ~= "" end
function M.redactedUrl()
if not M.hasUrl() then return "not set" end
local host = tostring(url):match("^https?://([^/]+)") or "?"
return ("%s/...(%d chars)"):format(host, #url)
end
function M.setEnabled(on)
enabled = on and true or false
log.info("%s (url %s)", enabled and "enabled" or "disabled", M.redactedUrl())
return true
end
local URL_FILE = "BlyxoHub/webhook.txt"
local function remember(v)
if not exec.can.files then return end
BX.try("webhook.remember", function()
if v == nil or v == "" then
if exec.isFile(URL_FILE) then exec.deleteFile(URL_FILE) end
return
end
exec.ensureFolder("BlyxoHub")
exec.writeFile(URL_FILE, v)
end)
end
function M.setUrl(v, quiet)
v = tostring(v or ""):gsub("%s", "")
if v == "" then
url = nil
if not quiet then remember(nil) end
log.info("url cleared")
return true, "URL cleared"
end
if not v:match("^https://") then
return false, "That does not look like a webhook URL"
end
url = v
if not quiet then remember(v) end
log.info("url set (%s)", M.redactedUrl())
return true, "Webhook URL saved"
end
BX.try("webhook.restore", function()
if not exec.can.files or not exec.isFile(URL_FILE) then return end
local saved = exec.readFile(URL_FILE)
if type(saved) == "string" and saved:match("^https://") then
M.setUrl(saved, true)
log.info("url restored from %s (%s)", URL_FILE, M.redactedUrl())
end
end)
local function embedFor(e)
local fields = {}
local function add(name, value)
if value == nil or value == "" then return end
fields[#fields + 1] = { name = name, value = tostring(value), inline = true }
end
add("Income", (e.value and (util.short(e.value) .. "/s")) or nil)
add("Weight", e.kg and e.kg > 0 and ("%.1f kg"):format(e.kg) or nil)
add("Rarity", e.rarity ~= "?" and e.rarity or nil)
add("Mutation", e.mutation)
add("Area", e.areaId)
return {
username = "BlyxoHub",
embeds = { {
title = "Egg delivered",
description = "**" .. tostring(e.name or "Egg") .. "**",
color = 5814783,
fields = fields,
footer = { text = "BlyxoHub " .. tostring(BX.version) },
timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
} },
}
end
local function post(payload, tag)
if not exec.can.request then
stats.skipped = stats.skipped + 1
log.warn("no HTTP request capability - nothing sent")
return false
end
local body
local okEnc = pcall(function() body = svc.HttpService:JSONEncode(payload) end)
if not okEnc or not body then
stats.failed = stats.failed + 1
return false
end
local res
local ok = BX.try("webhook.post", function()
res = exec.httpRequest({
Url = url, Method = "POST",
Headers = { ["Content-Type"] = "application/json" },
Body = body,
})
end)
local code = res and (res.StatusCode or res.status_code)
if ok and code and code >= 200 and code < 300 then
stats.sent = stats.sent + 1
log.info("%s sent (HTTP %s)", tag, tostring(code))
return true
end
stats.failed = stats.failed + 1
log.warn("%s failed (HTTP %s)", tag, tostring(code or "no response"))
return false
end
function M.onDelivered(e)
if not enabled or not M.hasUrl() or type(e) ~= "table" then return end
local now = os.clock()
if now - lastSend < K.MIN_GAP then
stats.dropped = stats.dropped + 1
return
end
lastSend = now
task.spawn(function()
BX.try("webhook.delivered", function()
post(embedFor(e), "delivery")
end)
end)
end
function M.test()
if not M.hasUrl() then return false, "Set a webhook URL first" end
task.spawn(function()
BX.try("webhook.test", function()
post({
username = "BlyxoHub",
embeds = { {
title = "Test",
description = "Webhook is working.",
color = 5814783,
footer = { text = "BlyxoHub " .. tostring(BX.version) },
timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
} },
}, "test")
end)
end)
return true, "Test sent"
end
return M
end)
return (function(...)
local RideAPet = {}
local env = (type(getgenv) == "function" and getgenv()) or _G
local BX = env.BX
assert(type(BX) == "table" and type(BX.require) == "function",
"BlyxoHub runtime missing - build with: python tools/build.py --game rideapet-standalone")
local log = BX.require("boot.log").for_module("rideapet")
do
if type(env.__BLYXO_RAP_CLEANUP) == "function" then pcall(env.__BLYXO_RAP_CLEANUP) end
env.__BLYXO_RAP_CLEANUP = nil
pcall(function()
if env.__BLYXO_RAP_WINDOW and env.__BLYXO_RAP_WINDOW.Unload then env.__BLYXO_RAP_WINDOW:Unload() end
end)
env.__BLYXO_RAP_WINDOW = nil
local parents = { game:GetService("CoreGui") }
pcall(function() if type(gethui) == "function" then parents[2] = gethui() end end)
for _, parent in ipairs(parents) do
for _, gui in ipairs(parent:GetChildren()) do
local n = gui.Name
if n == "BlyxoRideAPetSplash" or n == "BlyxoRideAPetIsland" or n == "BlyxoHubLogoOverlay" then
pcall(function() gui:Destroy() end)
end
end
end
end
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local GameRemote = Remotes:WaitForChild("Game")
local EggPickup  = GameRemote:WaitForChild("EggPickup")
local EggPlaced  = GameRemote:WaitForChild("EggPlaced")
local ToPlot     = GameRemote:WaitForChild("TeleportToPlot")
local ActiveEggs = ReplicatedStorage:WaitForChild("ServerData"):WaitForChild("ActiveEggs")
local EggAssets  = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Eggs")
local GameData   = ReplicatedStorage:WaitForChild("GameData")
local EggsData   = require(GameData:WaitForChild("Eggs"))
local GeneralData= require(GameData:WaitForChild("General"))
local K = {
PROMPT_RANGE  = 15,
ARRIVE        = 8,
TWEEN_SPEED   = 350,
CARRY_SPEED   = 100,
TWEEN_MIN     = 0.25,
TWEEN_LIFT    = 4,     
TRAVEL_CEILING = 30,
MAX_CHASE     = 1600,
INTERACT_TRIES = 4,
INTERACT_GAP   = 0.35,
BREAK_MARGIN  = 4,
DEPOSIT_CONFIRM = 3,
TELEPORT_WAIT   = 6,
CYCLE_GAP       = 0.4,
UNDER_MAP_DEPTH  = 500,
UNDER_MAP_SPEED  = 260,
UI_SCAN_RANGE    = 10000,
UNDER_MAP_MIN    = 0.25,
FAST_RETURN_DEFAULT = true,
}
RideAPet.K = K
RideAPet.state  = "idle"
RideAPet.status = "stopped"
RideAPet.stats  = { deposited = 0, lost = 0, trips = 0, luck = 0, byEgg = {} }
RideAPet.target = nil
RideAPet.pinnedEgg = nil
RideAPet.oneShotTaken = false
RideAPet.tripped, RideAPet.trippedBy = false, nil
local running, loopThread = false, nil
local stopRequested = false
local runId, loopBusy = 0, false
local listeners = {}
local staleGuids = {}
local island
local function getIsland()
if island == nil then
local ok, mod = pcall(BX.require, "ui.island")
island = (ok and type(mod) == "table" and type(mod.set) == "function") and mod or false
end
return island or nil
end
local PHASE_PROGRESS = {
move = 0.05, interact = 0.40, ["return"] = 0.55, carry = 0.80, deposit = 0.90,
}
local function setState(state, status, tone, progress)
RideAPet.state, RideAPet.status = state, status
for _, fn in ipairs(listeners) do pcall(fn, state, status) end
local isl = getIsland()
if not isl then return end
local target = RideAPet.target
if state == "done" then
pcall(isl.clear, "rideapet")
pcall(isl.show, "rideapet.done", {
title = "Egg delivered!",
sub = tostring(target and target.egg or "Egg") .. " · complete",
tone = "good", hold = 3, pulse = true,
})
return
end
if running and target and PHASE_PROGRESS[state] then
pcall(isl.set, "rideapet", {
title = "Grabbing " .. tostring(target.egg),
sub = status,
tone = tone or "normal",
progress = progress or PHASE_PROGRESS[state],
})
return
end
local n = RideAPet.stats.deposited
local spec = {
title = ("Egg farm · %d egg%s"):format(n, n == 1 and "" or "s"),
sub = status,
tone = tone or "normal",
}
if running then
pcall(isl.set, "rideapet", spec)
else
pcall(isl.clear, "rideapet")
spec.hold = 4
pcall(isl.show, "rideapet", spec)
end
end
function RideAPet.onStatus(fn)
if type(fn) == "function" then listeners[#listeners + 1] = fn end
end
local baselineFlags = LocalPlayer:GetAttribute("TeleportFlags") or 0
do
BX.connect(LocalPlayer:GetAttributeChangedSignal("TeleportFlags"), function()
local now = LocalPlayer:GetAttribute("TeleportFlags") or 0
if now > baselineFlags then
RideAPet.tripped = true
RideAPet.trippedBy = ("TeleportFlags rose to %d"):format(now)
end
end)
local msg = Remotes:FindFirstChild("Reusable")
msg = msg and msg:FindFirstChild("GameMessage")
if msg then
BX.connect(msg.OnClientEvent, function(text)
text = tostring(text or "")
if text:find("Teleport Detected") or text:find("Egg Was Returned") then
RideAPet.tripped, RideAPet.trippedBy = true, text
end
end)
end
end
local function character()
local c = LocalPlayer.Character
return (c and c.Parent and c:FindFirstChild("HumanoidRootPart")) and c or nil
end
local function root() local c = character() return c and c.HumanoidRootPart end
local function humanoid() local c = character() return c and c:FindFirstChildOfClass("Humanoid") end
local function basketFolder()
return LocalPlayer:FindFirstChild("Basket")
end
function RideAPet.carrying()
local b = basketFolder()
return b ~= nil and #b:GetChildren() > 0
end
function RideAPet.breaksIn()
local b = basketFolder()
if not b then return nil end
local now, soonest, window = workspace:GetServerTimeNow(), nil, nil
for _, c in ipairs(b:GetChildren()) do
local at = tonumber(c:GetAttribute("BreakAt"))
if at then
local left = at - now
if not soonest or left < soonest then
soonest = left
window = tonumber(c:GetAttribute("BreakSeconds")) or math.max(left, 1)
end
end
end
return soonest, window
end
local function luckOf(eggName)
local info = EggsData[eggName]
return (info and info.Luck) or 0
end
local function rarityOf(eggName)
local info = EggsData[eggName]
return info and info.Rarity or "?"
end
function RideAPet.breakWindowFor(eggName)
local r = rarityOf(eggName)
return (GeneralData.EggBreakTimer and GeneralData.EggBreakTimer[r]) or 20
end
function RideAPet.scan(maxRange)
local hrp = root()
if not hrp then return {} end
local here = hrp.Position
local out, present = {}, {}
for _, rec in ipairs(ActiveEggs:GetChildren()) do
present[rec.Name] = true
local pos, name = rec:GetAttribute("Position"), rec:GetAttribute("Egg")
if not staleGuids[rec.Name] and typeof(pos) == "Vector3" and name and EggAssets:FindFirstChild(name) then
local d = (pos - here).Magnitude
if not maxRange or d <= maxRange then
out[#out + 1] = {
rec = rec, guid = rec.Name, egg = name, pos = pos, dist = d,
luck = luckOf(name), rarity = rarityOf(name),
weight = rec:GetAttribute("Weight") or 1,
mutation = rec:GetAttribute("Mutation"),
}
end
end
end
for guid in pairs(staleGuids) do
if not present[guid] then staleGuids[guid] = nil end
end
table.sort(out, function(a, b)
if a.luck ~= b.luck then return a.luck > b.luck end
return a.dist < b.dist
end)
return out
end
function RideAPet.select(maxRange)
local searchRange = RideAPet.pinnedEgg and K.UI_SCAN_RANGE or (maxRange or K.MAX_CHASE)
local board = RideAPet.scan(searchRange)
if RideAPet.pinnedEgg then
for _, target in ipairs(board) do
if target.guid == RideAPet.pinnedEgg or target.egg == RideAPet.pinnedEgg then
return target
end
end
end
return board[1]
end
function RideAPet.pin(eggName)
RideAPet.pinnedEgg = (type(eggName) == "string" and eggName ~= "") and eggName or nil
return RideAPet.pinnedEgg
end
function RideAPet.plot()
local plots = workspace:FindFirstChild("Plots")
if not plots then return nil end
for _, p in ipairs(plots:GetChildren()) do
if p:GetAttribute("NestsOwnerLoaded") == LocalPlayer.UserId then return p end
end
return nil
end
function RideAPet.freeNest()
local plot = RideAPet.plot()
if not plot then return nil end
local nests = plot:FindFirstChild("Nests")
if not nests then return nil, plot end
for _, n in ipairs(nests:GetChildren()) do
if n:GetAttribute("Unlocked") == true and not n:GetAttribute("Occupied") then
return n, plot
end
end
return nil, plot
end
function RideAPet.canPlant()
return LocalPlayer:GetAttribute("NoNest") == true
end
function RideAPet.petRoom()
local plot = RideAPet.plot()
local pets = plot and plot:FindFirstChild("Pets")
local have = pets and #pets:GetChildren() or 0
local max = tonumber(LocalPlayer:GetAttribute("MaxPets")) or 0
return have, max, (max > 0 and have < max)
end
local function promptFirer()
local ok, fn = pcall(function() return fireproximityprompt end)
if ok and type(fn) == "function" then return fn end
ok, fn = pcall(function() return getgenv().fireproximityprompt end)
if ok and type(fn) == "function" then return fn end
return nil
end
local function tweenTo(pos, stopWhen, speed, onProgress)
speed = speed or K.TWEEN_SPEED
local char, hrp = character(), root()
if not char or not hrp then return false, "no character" end
local from = hrp.CFrame
local goal = CFrame.new(pos + Vector3.new(0, K.TWEEN_LIFT, 0))
local dist = (goal.Position - from.Position).Magnitude
if dist <= K.ARRIVE then return true, dist end
local driver = Instance.new("CFrameValue")
driver.Value = from
local hum = humanoid()
local restoreState
if hum then
restoreState = hum:GetState()
pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
end
local conn = driver.Changed:Connect(function(cf)
local c = character()
if not c then return end
pcall(function() c:PivotTo(cf) end)
local r = root()
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
end)
local flat = Vector3.new(goal.Position.X, from.Position.Y, goal.Position.Z)
if (flat - from.Position).Magnitude > 1 then
goal = CFrame.lookAt(goal.Position, goal.Position + (flat - from.Position).Unit)
end
local fromRotation = CFrame.Angles(from:ToEulerAnglesXYZ())
local heightGoal = CFrame.new(from.Position.X, goal.Position.Y, from.Position.Z) * fromRotation
local heightDistance = math.abs(goal.Position.Y - from.Position.Y)
local horizontalDistance = (goal.Position - heightGoal.Position).Magnitude
local heightDuration = math.max(heightDistance / speed, K.TWEEN_MIN)
local horizontalDuration = math.max(horizontalDistance / speed, K.TWEEN_MIN)
local segments = {}
if heightDistance > 1 then segments[#segments + 1] = { heightGoal, heightDuration } end
if horizontalDistance > 1 then segments[#segments + 1] = { goal, horizontalDuration } end
local deadline = os.clock() + math.min(heightDuration + horizontalDuration + 3, K.TRAVEL_CEILING)
local total, started, lastReport = 0, os.clock(), 0
for _, segment in ipairs(segments) do total = total + segment[2] end
local aborted
for _, segment in ipairs(segments) do
local tween = TweenService:Create(
driver,
TweenInfo.new(segment[2], Enum.EasingStyle.Linear),
{ Value = segment[1] })
tween:Play()
while os.clock() < deadline do
if RideAPet.tripped then aborted = "detection tripped" break end
if stopRequested then aborted = "stopped" break end
if stopWhen and stopWhen() then aborted = "aborted" break end
if tween.PlaybackState ~= Enum.PlaybackState.Playing then break end
if onProgress and total > 0 and os.clock() - lastReport >= 0.15 then
lastReport = os.clock()
pcall(onProgress, math.clamp((lastReport - started) / total, 0, 1))
end
RunService.Heartbeat:Wait()
end
tween:Cancel()
if aborted then break end
end
conn:Disconnect()
driver:Destroy()
if hum and restoreState then
pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end
if aborted then return false, aborted end
local now = root()
local gap = now and (pos - now.Position).Magnitude or math.huge
if gap <= K.PROMPT_RANGE then return true, gap end
return false, ("ended %d studs short"):format(math.floor(gap))
end
RideAPet.tweenTo = tweenTo
local function tweenUnderMap(stopWhen)
local char, hrp = character(), root()
if not char or not hrp then return false, "no character" end
if stopWhen and stopWhen() then return false, "aborted" end
local from = hrp.CFrame
local ignore = { char }
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local floorY = nil
local origin = from.Position + Vector3.new(0, 8, 0)
for _ = 1, 24 do
rayParams.FilterDescendantsInstances = ignore
local hit = workspace:Raycast(origin, Vector3.new(0, -4096, 0), rayParams)
if not hit then break end
floorY = hit.Position.Y
ignore[#ignore + 1] = hit.Instance
origin = Vector3.new(origin.X, hit.Position.Y, origin.Z)
end
pcall(function()
local plot = RideAPet.plot()
local base = plot and plot:FindFirstChild("Baseplate")
if base then
local baseY = base.Position.Y - base.Size.Y / 2
if not floorY or baseY < floorY then floorY = baseY end
end
end)
local targetY = (floorY or from.Position.Y) - K.UNDER_MAP_DEPTH
if targetY > from.Position.Y - K.UNDER_MAP_DEPTH then
targetY = from.Position.Y - K.UNDER_MAP_DEPTH
end
targetY = math.max(targetY, workspace.FallenPartsDestroyHeight + 50)
local goal = CFrame.new(from.Position.X, targetY, from.Position.Z) *
CFrame.Angles(from:ToEulerAnglesXYZ())
local drop = from.Position.Y - targetY
local duration = math.max(drop / K.UNDER_MAP_SPEED, K.UNDER_MAP_MIN)
local driver = Instance.new("CFrameValue")
driver.Value = from
local hum = humanoid()
local conn = driver.Changed:Connect(function(cf)
local c = character()
if not c then return end
pcall(function() c:PivotTo(cf) end)
local r = root()
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
end)
if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
local tween = TweenService:Create(
driver,
TweenInfo.new(duration, Enum.EasingStyle.Linear),
{ Value = goal })
tween:Play()
local deadline = os.clock() + duration + 2
local aborted
while os.clock() < deadline do
if RideAPet.tripped then aborted = "detection tripped" break end
if stopRequested then aborted = "stopped" break end
if stopWhen and stopWhen() then aborted = "aborted" break end
if tween.PlaybackState ~= Enum.PlaybackState.Playing then break end
RunService.Heartbeat:Wait()
end
tween:Cancel()
conn:Disconnect()
driver:Destroy()
if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
if aborted then return false, aborted end
local now = root()
if not now then return false, "root lost" end
return math.abs(now.Position.Y - targetY) <= 8,
("under-map return ended at Y %.1f"):format(now.Position.Y)
end
RideAPet.tweenUnderMap = tweenUnderMap
local function renderedIndex()
local index = {}
local folder = workspace:FindFirstChild("RenderedEggs")
if not folder then return index end
for _, m in ipairs(folder:GetChildren()) do
if m:IsA("Model") then
local ok, pivot = pcall(function() return m:GetPivot().Position end)
if ok then
local list = index[m.Name]
if not list then list = {}; index[m.Name] = list end
list[#list + 1] = { pos = pivot, model = m }
end
end
end
return index
end
RideAPet.renderedIndex = renderedIndex
local function promptFor(target, index)
index = index or renderedIndex()
for _, entry in ipairs(index[target.egg] or {}) do
if (entry.pos - target.pos).Magnitude < 6 then
local p = entry.model:FindFirstChildWhichIsA("ProximityPrompt", true)
if p then return p end
end
end
return nil
end
RideAPet.isRendered = function(target, index)
return target ~= nil and promptFor(target, index) ~= nil
end
local function interact(target)
local prompt
local renderDeadline = os.clock() + 3
repeat
prompt = promptFor(target)
if prompt then break end
task.wait(0.1)
until os.clock() >= renderDeadline
if not prompt then
staleGuids[target.guid] = true
if type(RideAPet.refreshUI) == "function" then
pcall(RideAPet.refreshUI, "stale")
end
return false, "egg is stale or no longer rendered"
end
local fire = promptFirer()
for _ = 1, K.INTERACT_TRIES do
if RideAPet.tripped then return false, "detection tripped" end
if not target.rec.Parent and not RideAPet.carrying() then
return false, "taken by someone else"
end
if fire then
pcall(fire, prompt)
else
EggPickup:FireServer(target.guid)
end
local deadline = os.clock() + K.INTERACT_GAP
while os.clock() < deadline do
if RideAPet.carrying() then return true end
task.wait(0.05)
end
end
local deadline = os.clock() + 1.5
while os.clock() < deadline do
if RideAPet.carrying() then return true end
task.wait(0.05)
end
return false, target.rec.Parent and "prompt did not take" or "taken by someone else"
end
local function returnToPlot()
local plot = RideAPet.plot()
if not plot then return false, "plot not found" end
local nest = RideAPet.freeNest()
local aim
if nest then
local ok, pivot = pcall(function() return nest:GetPivot().Position end)
aim = ok and pivot or nil
end
if not aim then
local base = plot:FindFirstChild("Baseplate")
aim = base and base.Position
end
if not aim then return false, "no landing spot on the plot" end
return tweenTo(aim, nil, K.CARRY_SPEED)
end
function RideAPet.warpHome()
ToPlot:FireServer()
local t0 = os.clock()
while os.clock() - t0 < K.TELEPORT_WAIT do
task.wait(0.15)
local plot = RideAPet.plot()
local base = plot and plot:FindFirstChild("Baseplate")
local hrp = root()
if base and hrp and (hrp.Position - base.Position).Magnitude < 120 then return true end
end
return false
end
local function deposit()
if not RideAPet.carrying() then return false, "nothing to deposit" end
local nest, plot = RideAPet.freeNest()
if not plot then return false, "plot not found" end
local plotEggs = plot:FindFirstChild("Eggs")
local was = plotEggs and #plotEggs:GetChildren() or 0
local carriedBefore = #basketFolder():GetChildren()
local how
if nest then
how = "nest " .. nest.Name
local anchor = nest:FindFirstChild("PlacePromptAnchor")
local prompt = anchor and anchor:FindFirstChildOfClass("ProximityPrompt")
local fire = promptFirer()
if prompt and fire then
pcall(fire, prompt)
else
EggPlaced:FireServer({ NestId = nest.Name })
end
elseif RideAPet.canPlant() then
local hrp = root()
local spot = (hrp and hrp.Position) or (plot.Baseplate and plot.Baseplate.Position)
how = "planted"
EggPlaced:FireServer({ PlantPosition = spot })
else
return false, "every nest is full - unlock one or hatch what is on the plot"
end
local deadline = os.clock() + K.DEPOSIT_CONFIRM
while os.clock() < deadline do
local landed = plotEggs and #plotEggs:GetChildren() > was
local taken  = nest and nest:GetAttribute("Occupied") == true
if landed or taken then return true, how end
task.wait(0.05)
end
local b = basketFolder()
if b and #b:GetChildren() < carriedBefore then
return false, RideAPet.tripped
and ("egg taken back: " .. tostring(RideAPet.trippedBy))
or "egg left the basket but never reached the plot"
end
return false, "placement not accepted"
end
RideAPet.deposit = deposit
RideAPet.returnToPlot = returnToPlot
local function delivered(target)
local s = RideAPet.stats
s.deposited = s.deposited + 1
s.luck = s.luck + target.luck
s.byEgg[target.egg] = (s.byEgg[target.egg] or 0) + 1
pcall(function()
local hook = BX._loaded["features.misc.webhook"]
if hook then
hook.onDelivered({ name = target.egg, rarity = target.rarity, mutation = target.mutation })
end
end)
end
function RideAPet.trip(maxRange, opts)
opts = opts or {}
local fastReturn = true
if RideAPet.tripped then
setState("stopped", "stopped: " .. tostring(RideAPet.trippedBy), "bad")
return false, { reason = RideAPet.trippedBy, fatal = true }
end
if RideAPet.carrying() then
setState("return", "carrying already - heading home", "warn")
local returned = fastReturn and RideAPet.warpHome() or returnToPlot()
if not returned then return false, { reason = "plot return failed" } end
local ok, how = deposit()
if not ok then return false, { reason = how } end
RideAPet.stats.deposited = RideAPet.stats.deposited + 1
end
local pets, maxPets, room = RideAPet.petRoom()
if not room and not RideAPet.canPlant() then
setState("blocked", ("plot full · %d/%d pets - sell or store one"):format(pets, maxPets), "warn")
return false, { reason = ("plot is at pet capacity (%d/%d)"):format(pets, maxPets), idle = true }
end
if not RideAPet.freeNest() and not RideAPet.canPlant() then
setState("blocked", "no free nest - unlock one or hatch the plot", "warn")
return false, { reason = "no free nest", idle = true }
end
setState("scan", "scanning the board")
local target = RideAPet.select(maxRange)
if not target then
setState("idle", "no eggs in range - waiting for restock")
return false, { reason = "no eggs in range", idle = true }
end
RideAPet.target = target
RideAPet.stats.trips = RideAPet.stats.trips + 1
local flying = ("flying out · %d studs"):format(math.floor(target.dist))
setState("move", flying)
local gone = function() return not target.rec.Parent and not RideAPet.carrying() end
local arrived, why = tweenTo(target.pos, gone, nil, function(f)
setState("move", flying, nil, PHASE_PROGRESS.move + (PHASE_PROGRESS.interact - PHASE_PROGRESS.move) * f)
end)
if not arrived then
setState("scan", "approach failed: " .. tostring(why))
return false, { reason = "approach failed: " .. tostring(why) }
end
setState("interact", "picking it up")
local got, err = interact(target)
if not got then
setState("scan", "missed: " .. tostring(err))
return false, { reason = err }
end
local pinnedTrip = RideAPet.pinnedEgg ~= nil and
(RideAPet.pinnedEgg == target.guid or RideAPet.pinnedEgg == target.egg)
if pinnedTrip then
RideAPet.oneShotTaken = true
running = false
end
if fastReturn then
setState("return", "got it · dropping below the map")
local under, underWhy = tweenUnderMap(function()
return not RideAPet.carrying()
end)
if not under then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", "under-map return failed: " .. tostring(underWhy), "bad")
return false, { reason = underWhy }
end
setState("return", "teleporting home", nil, 0.70)
local home = RideAPet.warpHome()
if not home then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", "plot return failed", "bad")
return false, { reason = "plot return failed" }
end
end
local left, window = RideAPet.breaksIn()
local waited = os.clock()
while not left and os.clock() - waited < 2 do
task.wait(0.05)
left, window = RideAPet.breaksIn()
end
setState("carry", ("carrying · %.0fs left"):format(left or 0))
if fastReturn then
setState("deposit", "depositing")
local placed, how = deposit()
if not placed then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", "deposit failed: " .. tostring(how), "bad")
return false, { reason = how }
end
delivered(target)
setState("done", ("deposited %s (%s)"):format(target.egg, how), "good")
if pinnedTrip then running = false end
return true, { egg = target.egg, rarity = target.rarity, luck = target.luck,
dist = target.dist, how = how, fastReturn = true, pinned = pinnedTrip }
end
local hrp = root()
local plot = RideAPet.plot()
local base = plot and plot:FindFirstChild("Baseplate")
if left and hrp and base then
local ride = (base.Position - hrp.Position).Magnitude / K.CARRY_SPEED
if left < ride + K.BREAK_MARGIN then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", ("too far to bank it (%.0fs left, %.0fs ride)"):format(left, ride), "bad")
return false, { reason = "not enough break time to get home" }
end
end
setState("return", ("heading home · %.0fs left"):format(RideAPet.breaksIn() or 0))
returnToPlot()
left = RideAPet.breaksIn()
if left and left <= 0 then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", "egg broke before deposit", "bad")
return false, { reason = "egg broke in transit" }
end
setState("deposit", "depositing")
local placed, how = deposit()
if not placed then
RideAPet.stats.lost = RideAPet.stats.lost + 1
setState("scan", "deposit failed: " .. tostring(how), "bad")
return false, { reason = how }
end
delivered(target)
setState("done", ("deposited %s (%s)"):format(target.egg, how), "good")
if pinnedTrip then running = false end
return true, {
egg = target.egg, rarity = target.rarity, luck = target.luck,
dist = target.dist, how = how, pinned = pinnedTrip,
}
end
function RideAPet.isRunning() return running end
function RideAPet.start(opts)
if running then return false, "already running" end
opts = opts or {}
running = true
runId = runId + 1
local myRun = runId
RideAPet.oneShotTaken = false
if RideAPet.tripped then
RideAPet.tripped, RideAPet.trippedBy = false, nil
baselineFlags = LocalPlayer:GetAttribute("TeleportFlags") or 0
end
setState("scan", "starting")
loopThread = task.spawn(function()
local waitUntil = os.clock() + 8
while loopBusy and os.clock() < waitUntil do task.wait(0.05) end
if myRun ~= runId then return end
stopRequested = false
loopBusy = true
local function live() return running and myRun == runId and BX.alive() end
while live() do
if RideAPet.oneShotTaken then break end
local ok, info = RideAPet.trip(opts.maxRange, opts)
if opts.onResult then pcall(opts.onResult, ok, info) end
if not ok and info and info.fatal then break end
if ok and info and info.pinned then break end
if not live() then break end
task.wait((info and info.idle) and 1.5 or K.CYCLE_GAP)
end
loopBusy = false
if myRun ~= runId then return end
running = false
if RideAPet.state ~= "stopped" then
setState("idle", RideAPet.tripped and ("stopped: " .. tostring(RideAPet.trippedBy)) or "stopped")
end
if type(RideAPet.onLoopEnded) == "function" then pcall(RideAPet.onLoopEnded) end
end)
return true
end
function RideAPet.stop()
running = false
stopRequested = true
runId = runId + 1
loopThread = nil
local hum = humanoid()
if hum then
pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
pcall(function() hum:Move(Vector3.zero, false) end)
end
setState("idle", "stopped")
local isl = getIsland()
if isl and isl.clear then pcall(isl.clear, "rideapet") end
return true
end
function RideAPet.goHome(smooth)
setState("return", "going to plot")
local ok = smooth and returnToPlot() or RideAPet.warpHome()
setState("idle", ok and "at plot" or "could not reach plot")
return ok
end
BX.versionTag = "V1"
BX.releaseNotes = {
{ "New",      "Home, Misc and Config tabs, profiles and the webhook" },
{ "Fixed",    "High eggs, menu showing early, duplicate UI on re-run" },
{ "Improved", "Faster flight out and a lighter egg list" },
}
local function formatLuck(value)
if value >= 1e12 then return ("%.1fT"):format(value / 1e12) end
if value >= 1e9 then return ("%.1fB"):format(value / 1e9) end
if value >= 1e6 then return ("%.1fM"):format(value / 1e6) end
if value >= 1e3 then return ("%.1fK"):format(value / 1e3) end
return tostring(value)
end
local NO_EGGS = "No eggs found"
local eggDropdown, autoToggle
local eggLabels = {}
local function eggOptions()
local out, map = {}, {}
local index = renderedIndex()
for _, target in ipairs(RideAPet.scan(K.UI_SCAN_RANGE)) do
if RideAPet.isRendered(target, index) then
local label = ("%s  ·  %s  ·  %d studs"):format(
target.egg, formatLuck(target.luck), math.floor(target.dist))
if map[label] then label = label .. ("  [%s]"):format(target.guid:sub(1, 6)) end
out[#out + 1], map[label] = label, target.guid
end
end
if #out == 0 then out[1] = NO_EGGS end
return out, map
end
local function refreshEggs()
local list, map = eggOptions()
eggLabels = map
if eggDropdown then pcall(function() eggDropdown:Refresh(list, true) end) end
end
RideAPet.refreshUI = refreshEggs
RideAPet.onLoopEnded = function()
if autoToggle then pcall(function() autoToggle:set(false) end) end
end
local function buildMain(tab)
tab:CreateSection({ name = "Stealing" })
local list, map = eggOptions()
eggLabels = map
eggDropdown = tab:CreateDropdown({
name = "Target Egg",
description = "Highest luck first. Leave it unselected for the best egg.",
options = list,
callback = function(value)
local picked = type(value) == "table" and value[1] or value
RideAPet.pin(eggLabels[picked])
end,
})
tab:CreateButton({ name = "Refresh Eggs", callback = refreshEggs })
autoToggle = tab:CreateToggle({
name = "Auto Steal",
description = "Fly to the egg, pick it up, drop below the map, then teleport home.",
value = false,
flag = "RideAPetAutoSteal",
callback = function(enabled)
if enabled == true then RideAPet.start({ fastReturn = true }) else RideAPet.stop() end
end,
})
tab:CreateButton({ name = "Go to My Plot", callback = function() RideAPet.goHome() end })
end
local function boot()
local splash = {
step = function() end, fail = function() end, done = function() end,
whenClosed = function(fn) pcall(fn) end,
}
pcall(function()
local real = BX.require("ui.splash")
if type(real) == "table" and type(real.step) == "function" then splash = real end
end)
splash.step("Reading the egg board...", 0.15)
splash.step("Building interface...", 0.30)
local ok, win = pcall(BX.require, "ui.shell")
if not ok or type(win) ~= "table" or not win.ok then
local why = ok and type(win) == "table" and win.error or win
log.error("menu unavailable: %s", tostring(why))
splash.fail("Failed to load the menu: " .. tostring(why))
return
end
BX.try("rap.hide", function() win.hide() end)
local unloadWindow = win.unload
BX.onTeardown("rideapet.window", function() pcall(unloadWindow) end)
BX.onTeardown("rideapet.farm", function()
pcall(RideAPet.stop)
eggDropdown, autoToggle = nil, nil
end)
win.unload = function() BX.teardown() end
local function tabStage(name, progress, fn)
splash.step(nil, progress)
if not BX.try("rap.tab." .. name, fn) then log.error("%s tab failed", name) end
task.wait()
end
tabStage("home", 0.45, function() BX.require("ui.tabs.home").build(win.tab("Home")) end)
tabStage("main", 0.60, function() buildMain(win.tab("Main")) end)
tabStage("misc", 0.72, function() BX.require("ui.tabs.misc").build(win.tab("Misc")) end)
tabStage("config", 0.84, function()
local prof = BX.require("core.profiles")
prof.allow("RideAPetAutoSteal", "boolean")
prof.setFlagSource(function()
local w = win.window
return (type(w) == "table" and type(w.controls) == "table" and w.controls) or {}
end)
BX.require("ui.tabs.config").build(win.tab("Config"))
end)
BX.try("rap.fps", function()
if BX.require("core.config").AUTO_FPS_BOOST then BX.require("features.fps").arm() end
end)
BX.try("rap.lastTab", function() win.restoreLastTab() end)
BX.try("rap.autoload", function()
local prof = BX.require("core.profiles")
prof.runAutoLoad()
prof.startAutoSave()
end)
if not BX.alive() then return end
splash.step("Ready", 1.0)
splash.whenClosed(function()
BX.try("rap.reveal", function()
win.reveal()
if running then setState(RideAPet.state, RideAPet.status) end
end)
end)
splash.done()
log.info("Ride A Pet hub ready")
end
task.spawn(function()
local ok, err = pcall(boot)
if not ok then log.error("boot failed: %s", tostring(err)) end
end)
return RideAPet
end)(...)
