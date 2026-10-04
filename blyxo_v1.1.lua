-- BlyxoHub | Ride A Pet
-- Version 1.1.0  |  build 19cebcdc  |  9e892c9  |  2026-09-21 17:45 UTC
--
-- GENERATED FILE - DO NOT EDIT.
-- Edit the modules in src/ and run: python tools/build.py
--
-- Modules in load order:
--   boot/00_runtime.lua                  162 lines
--   boot/01_log.lua                      174 lines
--   boot/02_scope.lua                    173 lines
--   boot/03_profile.lua                  249 lines
--   core/services.lua                     34 lines
--   core/net.lua                          77 lines
--   core/scan.lua                         56 lines
--   core/data.lua                        774 lines
--   core/profiles.lua                    592 lines
--   core/exec.lua                        378 lines
--   core/device.lua                      122 lines
--   core/character.lua                    84 lines
--   core/config.lua                       31 lines
--   core/state.lua                        14 lines
--   core/util.lua                         37 lines
--   auth/vampauth.lua                    121 lines
--   ui/lib/theme.lua                     576 lines
--   ui/lib/render.lua                    373 lines
--   ui/lib/widgets.lua                  2278 lines
--   ui/lib/init.lua                     2703 lines
--   ui/sfx.lua                            44 lines
--   ui/logodata.lua                       19 lines
--   ui/logo.lua                          164 lines
--   ui/wording.lua                        68 lines
--   ui/splash.lua                        794 lines
--   ui/stats.lua                        1934 lines
--   ui/island.lua                        203 lines
--   ui/window.lua                        718 lines
--   ui/adapter.lua                       416 lines
--   ui/shell.lua                         236 lines
--   ui/tabs/home.lua                      88 lines
--   ui/tabs/misc.lua                     192 lines
--   ui/tabs/config.lua                   172 lines
--   features/gamethrottle.lua            173 lines
--   features/fps.lua                     477 lines
--   features/misc/servers.lua            310 lines
--   features/misc/webhook.lua            286 lines
--   games/rideapet/eggfarm.lua          1391 lines
--   games/rideapet/hatch.lua             199 lines
--   games/rideapet/tab.lua               221 lines
--   games/rideapet/main.lua              405 lines

local BLYXO_VERSION = "1.1.0"
local BLYXO_BUILD   = "19cebcdc"
local BLYXO_GAME    = "Ride A Pet"
local BLYXO_EDITION = "full"

local env = (type(getgenv) == "function" and getgenv()) or _G
env.BlyxoGeneration = (env.BlyxoGeneration or 0) + 1
local BX = {
generation  = env.BlyxoGeneration,
version     = BLYXO_VERSION,
build       = BLYXO_BUILD,
game        = BLYXO_GAME,
edition     = BLYXO_EDITION or "full",
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
local factory = BX._factories[name]
if not factory and type(BX._deferred) == "table" then
for i, entry in ipairs(BX._deferred) do
if entry and entry[1] == name then
BX._deferred[i] = false
local chunk, err = loadstring(entry[3], "=" .. tostring(entry[2]))
if not chunk then error(tostring(err), 2) end
local ok, failure = pcall(chunk)
if not ok then error(tostring(failure), 2) end
factory = BX._factories[name]
if not factory then
error(("deferred module %q did not register"):format(name), 2)
end
break
end
end
end
if BX._loading[name] then
error(("circular dependency: %s"):format(name), 2)
end
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
BX.module("core.data", function(BX)
local svc  = BX.require("core.services")
local exec = BX.require("core.exec")
local log  = BX.require("boot.log").for_module("data")
local M = {}
local cache = {}      
local RETRY_AFTER = 2
local function atPath(...)
local node = svc.ReplicatedStorage
for _, part in ipairs({ ... }) do
if not node then return nil end
node = node:FindFirstChild(part)
end
return node
end
local heapTried, heapFound = false, {}
local HEAP_SHAPES = {
assets = function(t)
local dir = rawget(t, "Directory")
if type(dir) ~= "table" then return false end
for _, entry in pairs(dir) do
return type(entry) == "table" and type(entry.Rarity) == "table"
end
return false
end,
assetEarnings = function(t) return type(rawget(t, "LiveRatePerSecond")) == "function" end,
eggState = function(t) return type(rawget(t, "ReadFieldEggs")) == "function" end,
}
local SWEEP_FLAG = "BlyxoHub/heap_sweep.flag"
local function harvestHeap()
if heapTried then return end
heapTried = true
if not exec.can.gc then
log.warn("require failed and this executor has no gc access - names and rates stay unavailable")
return
end
if exec.can.files and exec.isFile(SWEEP_FLAG) then
log.warn("skipping the heap sweep: the client died in one last run")
return
end
if exec.can.files then
exec.ensureFolder("BlyxoHub")
exec.writeFile(SWEEP_FLAG, "sweeping")
end
local objs = exec.gcScan(true)
if exec.can.files then exec.deleteFile(SWEEP_FLAG) end
local scanned, hits = 0, {}
for _, obj in ipairs(objs) do
if type(obj) == "table" then
scanned = scanned + 1
for key, shape in pairs(HEAP_SHAPES) do
if not heapFound[key] then
local ok, matched = pcall(shape, obj)
if ok and matched then
heapFound[key] = obj
hits[#hits + 1] = key
end
end
end
end
end
log.info("heap sweep: %d tables, recovered %s", scanned,
#hits > 0 and table.concat(hits, ", ") or "NOTHING (this executor runs its own Lua state)")
end
local function assembleAssets(inst)
if not WARM_ENABLED then return nil end
local kids = inst:GetChildren()
local built, ok, failed = {}, 0, 0
for _, child in ipairs(kids) do
if child:IsA("ModuleScript") then
local entry
local got = pcall(function() entry = exec.requireGame(child) end)
if got and type(entry) == "table"
and (entry.DisplayName ~= nil or entry.Rarity ~= nil) then
built[child.Name] = entry
ok = ok + 1
else
failed = failed + 1
end
end
end
log.info("Data.Assets pieced from children: %d loaded, %d refused, of %d",
ok, failed, #kids)
if ok == 0 then return nil end
return { Directory = built }
end
local function searchModule(name)
for _, d in ipairs(svc.ReplicatedStorage:GetDescendants()) do
if d:IsA("ModuleScript") and d.Name == name then return d end
end
return nil
end
local warmed, warmDone, warmValues = false, {}, {}
local knownCategories = {}
function M.noteCategories(list)
for _, category in pairs(list or {}) do
if type(category) == "string" then knownCategories[category] = true end
end
end
local warmLoaded = 0
local WARM_ENABLED = false
local function warmModuleGraph()
local baked = BX._loaded["features.catalog"] or BX.require("features.catalog")
if baked and baked.loaded then
if not warmed then
warmed = true
log.info("baked catalog present - not reading any game module")
end
return 0
end
if not WARM_ENABLED then
if not warmed then
warmed = true
log.warn("module warm pass disabled: requiring game modules breaks the game's own scripts")
end
return 0
end
if warmed then return warmLoaded end
warmed = true
local roots = {}
local rs = svc.ReplicatedStorage
local assets = rs:FindFirstChild("Data")
assets = assets and assets:FindFirstChild("Assets")
local configs = assets and assets:FindFirstChild("Configs")
for _, d in ipairs(configs and configs:GetChildren() or {}) do
if d:IsA("ModuleScript") and #roots < 400 then roots[#roots + 1] = d end
end
if #roots == 0 then
log.warn("no Data.Assets.Configs modules to read - names and rates stay unavailable")
return 0
end
local loaded = 0
for pass = 1, 4 do
local before = loaded
for _, mod in ipairs(roots) do
if not warmDone[mod] then
local value
local ok = pcall(function() value = exec.requireGame(mod) end)
if ok then
warmDone[mod] = true
loaded = loaded + 1
if type(value) == "table" then warmValues[mod:GetFullName()] = value end
end
end
end
log.info("module warm pass %d: %d of %d loaded", pass, loaded, #roots)
if loaded == before then break end
end
warmLoaded = loaded
return loaded
end
local function knownCount()
local n = 0
for _ in pairs(knownCategories) do n = n + 1 end
return n
end
local function directoryScore(candidate)
if type(candidate) ~= "table" then return 0 end
local hits = 0
for category in pairs(knownCategories) do
local entry = rawget(candidate, category)
if type(entry) == "table" then hits = hits + 1 end
end
return hits
end
local saidMined = false
local slotShaped = nil
local function findSlotIdentity()
for name, value in pairs(warmValues) do
if type(rawget(value, "SlotKey")) == "function"
and type(rawget(value, "LooksLikeFirstAreaUid")) == "function" then
log.info("slot identity recovered from %s", name)
return value
end
end
return nil
end
local function directoryFromConfigs()
local built, n = {}, 0
for name, value in pairs(warmValues) do
local pet = name:match("^ReplicatedStorage%.Data%.Assets%.Configs%.(.+)$")
if pet and type(value) == "table" then
built[pet] = value
n = n + 1
end
end
return n > 0 and built or nil, n
end
local mutationCache, saidMutations = nil, false
function M.mutationFactor(name)
if not name then return nil end
if not mutationCache then
mutationCache = {}
for full, value in pairs(warmValues) do
local id = full:match("%.Mutations%.Configs%.(.+)$") or full:match("%.Mutations%.(.+)$")
if id and type(value) == "table" then mutationCache[id] = value end
end
if not saidMutations then
saidMutations = true
local n, sampleKey = 0, nil
for key in pairs(mutationCache) do n = n + 1 sampleKey = sampleKey or key end
if sampleKey then
local fields = {}
for key, value in pairs(mutationCache[sampleKey]) do
fields[#fields + 1] = ("%s=%s"):format(tostring(key), tostring(value):sub(1, 16))
end
table.sort(fields)
log.info("mutation configs: %d loaded, %q = { %s }", n, sampleKey,
table.concat(fields, ", "))
else
log.info("no mutation configs loaded - mutated eggs price at base rate")
end
end
end
local entry = mutationCache[tostring(name)]
if type(entry) ~= "table" then return nil end
return tonumber(entry.EarningMultiplier or entry.Multiplier or entry.EarningRateMultiplier
or entry.RateMultiplier or entry.Bonus)
end
local function mineWarmed()
local assembled, count = directoryFromConfigs()
if assembled then
local score = directoryScore(assembled)
if score > 0 or knownCount() == 0 then
if not saidMined then
saidMined = true
log.info("pet directory assembled from %d Data.Assets.Configs modules (%d of %d live categories)",
count, score, knownCount())
local sampleKey
for category in pairs(knownCategories) do
if type(rawget(assembled, category)) == "table" then sampleKey = category break end
end
if not sampleKey then
for category in pairs(assembled) do sampleKey = category break end
end
local entry = sampleKey and rawget(assembled, sampleKey)
if type(entry) == "table" then
local fields = {}
for key, value in pairs(entry) do
local shown = tostring(value):sub(1, 20)
if type(value) == "table" then
local inner = {}
for k2, v2 in pairs(value) do
inner[#inner + 1] = ("%s=%s"):format(tostring(k2), tostring(v2):sub(1, 14))
if #inner >= 6 then break end
end
table.sort(inner)
shown = "{" .. table.concat(inner, ",") .. "}"
end
fields[#fields + 1] = ("%s:%s=%s"):format(tostring(key), typeof(value), shown)
end
table.sort(fields)
log.info("entry %q = { %s }", tostring(sampleKey), table.concat(fields, ", "))
end
end
local earned
for _, value in pairs(warmValues) do
if type(rawget(value, "LiveRatePerSecond")) == "function" then earned = value break end
end
slotShaped = slotShaped or findSlotIdentity()
return assembled, earned, "configs"
end
end
local directory, earnings, best, bestName = nil, nil, 0, nil
for name, value in pairs(warmValues) do
if not earnings and type(rawget(value, "LiveRatePerSecond")) == "function" then
earnings = value
log.info("pricing function found in %s", name)
end
for _, candidate in ipairs({ value, rawget(value, "Directory") }) do
local score = directoryScore(candidate)
if score > best then best, bestName, directory = score, name, candidate end
end
end
if directory and not saidMined then
saidMined = true
log.info("pet directory: %s matches %d of %d live categories", bestName, best, knownCount())
for category in pairs(knownCategories) do
local entry = rawget(directory, category)
if type(entry) == "table" then
local fields = {}
for key, value in pairs(entry) do
fields[#fields + 1] = ("%s:%s=%s"):format(tostring(key), typeof(value),
tostring(value):sub(1, 20))
end
table.sort(fields)
log.info("entry %q = { %s }", category, table.concat(fields, ", "))
break
end
end
elseif not directory and knownCount() > 0 and not saidMined then
saidMined = true
local names = {}
for name in pairs(warmValues) do names[#names + 1] = name:gsub("^ReplicatedStorage%.", "") end
table.sort(names)
log.warn("no loaded module keys any of the %d live categories", knownCount())
for i = 1, math.min(#names, 80), 20 do
log.info("loaded modules %d-%d: %s", i, math.min(i + 19, #names),
table.concat(table.move(names, i, math.min(i + 19, #names), 1, {}), ", "))
end
end
return directory, earnings, "shape"
end
local function resolve(key, path)
local held = cache[key]
if held and held.mod then return held.mod end
if held and held.missing and (os.clock() - (held.at or 0)) < RETRY_AFTER then
return nil
end
cache[key] = nil
local inst = atPath(table.unpack(path))
if not (inst and inst:IsA("ModuleScript")) then
local name = path[#path]
local found = searchModule(name)
if found then
log.warn("%s was not a module at %s - using %s",
name, table.concat(path, "."), found:GetFullName())
inst = found
end
end
if not inst then
cache[key] = { missing = true, at = os.clock() }
return nil
end
local mod
local ok = BX.try("data.require." .. key, function() mod = exec.requireGame(inst) end)
if not ok or type(mod) ~= "table" then
if HEAP_SHAPES[key] then
harvestHeap()
if heapFound[key] then
log.info("%s recovered from the heap", key)
cache[key] = { mod = heapFound[key] }
return heapFound[key]
end
end
if warmModuleGraph() > 0 then
local retried
if pcall(function() retried = exec.requireGame(inst) end) and type(retried) == "table" then
log.info("%s loaded after warming the module graph", key)
cache[key] = { mod = retried }
return retried
end
local directory, earnings, source = mineWarmed()
local trusted = (source == "configs") or (directory and knownCount() > 0)
if key == "assets" and directory and trusted then
local stand = { Directory = directory }
cache[key] = { mod = stand }
return stand
end
if key == "assetEarnings" and earnings then
cache[key] = { mod = earnings }
return earnings
end
if key == "slotIdentity" and slotShaped then
cache[key] = { mod = slotShaped }
return slotShaped
end
end
if key == "assets" then
local pieced = assembleAssets(inst)
if pieced then
cache[key] = { mod = pieced }
return pieced
end
end
cache[key] = { missing = true, at = os.clock() }
return nil
end
cache[key] = { mod = mod }
return mod
end
function M.assets()        return resolve("assets", { "Data", "Assets" }) end
function M.areas()         return resolve("areas", { "Data", "Areas" }) end
function M.eggState()      return resolve("eggState", { "Client", "EggState" }) end
function M.assetEarnings() return resolve("assetEarnings", { "Shared", "Util", "AssetEarnings" }) end
function M.plotState()     return resolve("plotState", { "Client", "PlotState" }) end
function M.slotIdentity()  return resolve("slotIdentity", { "Shared", "Util", "AreaEggSlotIdentity" }) end
function M.resetWall()     return resolve("resetWall", { "Client", "AreaEggResetWall" }) end
function M.bases()         return resolve("bases", { "Data", "Bases" }) end
function M.save()          return resolve("save", { "Shared", "Save" }) end
function M.eggCycle()      return resolve("eggCycle", { "Shared", "Util", "AreaEggCycle" }) end
function M.fusionFlags()   return resolve("fusionFlags", { "Shared", "Flags", "ShrineFusionFlags" }) end
local LIMIT_FALLBACK = 115
function M.eggInventory()
local count, limit
BX.try("data.eggInventoryCount", function()
local save = M.save()
local s = save and save.Get and save.Get(svc.Players.LocalPlayer)
if type(s) == "table" and type(s.EggInventory) == "table" then
count = 0
for _ in pairs(s.EggInventory) do count = count + 1 end
end
end)
BX.try("data.eggInventoryLimit", function()
local flags = M.fusionFlags()
local f = flags and flags.EggInventoryLimit
limit = f and type(f.Get) == "function" and tonumber(f:Get()) or nil
end)
limit = limit or LIMIT_FALLBACK
if not count then return nil, nil, limit end
return count >= limit, count, limit
end
function M.secondsUntilReset()
local cyc = M.eggCycle()
if not (cyc and type(cyc.SecondsUntilReset) == "function") then return nil end
local ok, s = pcall(cyc.SecondsUntilReset, workspace:GetServerTimeNow())
return ok and tonumber(s) or nil
end
local WALL_MARGIN = 1.5
M.WALL_MARGIN = WALL_MARGIN
local function wallOpensAfter()
local d = resolve("resetCycleData", { "Data", "AreaEggResetCycle" }) or {}
return (tonumber(d.WallCountdownDelayAfterDayStartsSeconds) or 2)
+ (tonumber(d.WallCountdownSeconds) or 3)
end
function M.secondsSinceReset()
local cyc = M.eggCycle()
local left = M.secondsUntilReset()
if not left then return nil end
local period = cyc and tonumber(cyc.ResetPeriodSeconds) or 300
return period - left
end
function M.secondsUntilFieldOpens()
local since = M.secondsSinceReset()
if not since then return nil end
local left = wallOpensAfter() + WALL_MARGIN - since
return left > 0 and left or nil
end
local function wallCollision()
local o = workspace:FindFirstChild("__OBJECTS")
o = o and o:FindFirstChild("Areas")
return o and o:FindFirstChild("WallStartCollision") or nil
end
function M.fieldSealed()
local flag = nil
local wall = M.resetWall()
if wall and type(wall.IsSealed) == "function" then
local ok, sealed = pcall(wall.IsSealed)
if ok then flag = (sealed == true) end
end
local part = wallCollision()
if flag ~= nil then return flag end
if part and part:IsA("BasePart") then return part.CanCollide end
local schedule = nil
BX.try("data.fieldSealed.schedule", function()
local cyc = M.eggCycle()
if not (cyc and type(cyc.IsNightPhase) == "function") then return end
local now = workspace:GetServerTimeNow()
if cyc.IsNightPhase(now) then schedule = true return end
local since = M.secondsSinceReset()
if since then schedule = since < (wallOpensAfter() + WALL_MARGIN) end
end)
if schedule then return true end
if flag == nil and schedule == nil then return nil end
return false
end
function M.onWallChanged(sc, fn)
local n = 0
BX.try("data.wallSignal", function()
local wall = M.resetWall()
local sig = wall and wall.Changed
if type(sig) == "table" and type(sig.Connect) == "function" then
sc:connect(sig, function(sealed) fn(sealed == true, "signal") end)
n = n + 1
end
end)
BX.try("data.wallPart", function()
local part = wallCollision()
if part and part:IsA("BasePart") then
sc:connect(part:GetPropertyChangedSignal("CanCollide"), function()
fn(part.CanCollide, "collision")
end)
n = n + 1
end
end)
return n
end
local profileAt, profileCache, saidProfile = 0, nil, false
local PROFILE_TTL = 5
function M.profile()
local mod = M.save()
if mod and type(mod.Get) == "function" then
local ok, prof = pcall(mod.Get, svc.Players.LocalPlayer)
if ok and type(prof) == "table" then return prof end
end
local now = os.clock()
if profileCache and (now - profileAt) < PROFILE_TTL then return profileCache end
local got = BX.require("core.net").call("RF/ProfileMirror/FetchProfile")
if type(got) ~= "table" then
if not saidProfile then
saidProfile = true
log.warn("no profile: Save is unrequirable and RF/ProfileMirror/FetchProfile gave %s",
typeof(got))
end
return nil
end
if not saidProfile then
saidProfile = true
local keys = {}
for key in pairs(got) do keys[#keys + 1] = tostring(key) end
table.sort(keys)
log.info("profile via RF/ProfileMirror/FetchProfile: %s", table.concat(keys, ", "))
end
profileCache, profileAt = got, now
return got
end
function M.assetsDir()
local a = M.assets()
return a and a.Directory or nil
end
function M.areasDir()
local a = M.areas()
return a and a.Directory or nil
end
function M.report()
local out = {}
for key, held in pairs(cache) do
out[#out + 1] = key .. (held.missing and "=MISSING" or "=ok")
end
table.sort(out)
return out
end
return M
end)
BX.module("core.profiles", function(BX)
local svc  = BX.require("core.services")
local exec = BX.require("core.exec")
local log  = BX.require("boot.log").for_module("profiles")
local M = {}
local FORMAT = 2
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
if kind and not KIND[key] then KIND[key] = kind end
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
local controls = {}
local pending = {}
local applyTo 
function M.register(flag, handle, kind)
flag = tostring(flag)
M.allow(flag, kind)
controls[flag] = handle
local waiting = pending[flag]
if waiting ~= nil then
pending[flag] = nil
if validValue(flag, waiting) then applyTo(flag, waiting, handle) end
end
end
function M.controls() return controls end
local listing, listingOk = {}, false
local function safeName(name)
name = tostring(name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
return name
end
local function pathFor(name)
return DIR .. "/" .. name .. ".json"
end
local INDEX = DIR .. "/index.json"
local function readIndex()
local names = {}
if not exec.isFile(INDEX) then return names end
local body = exec.readFile(INDEX)
local data
pcall(function() data = svc.HttpService:JSONDecode(body) end)
if type(data) == "table" then
for _, n in ipairs(data.names or data) do
if type(n) == "string" and n ~= "" then names[#names + 1] = n end
end
end
return names
end
local function writeIndex(names)
local body
if not pcall(function() body = svc.HttpService:JSONEncode({ version = FORMAT, names = names }) end) then
return false
end
return BX.try("profiles.index", function()
exec.ensureFolder("BlyxoHub")
exec.ensureFolder(DIR)
if not exec.writeFile(INDEX, body) then error("writefile refused", 0) end
end) and true or false
end
local function indexAdd(name)
local names = readIndex()
if not table.find(names, name) then names[#names + 1] = name end
return writeIndex(names)
end
local function indexRemove(name)
local names = readIndex()
local i = table.find(names, name)
if i then table.remove(names, i) end
return writeIndex(names)
end
function M.refresh()
listing, listingOk = {}, false
if not M.available() then return listing end
BX.try("profiles.refresh", function()
exec.ensureFolder("BlyxoHub")
exec.ensureFolder(DIR)
local seen = {}
for _, name in ipairs(readIndex()) do
if not seen[name] and exec.isFile(pathFor(name)) then
seen[name] = true
listing[#listing + 1] = name
end
end
if exec.can.listFiles then
local files = exec.listFiles(DIR)
for _, f in ipairs(files or {}) do
local name = tostring(f):match("([^/\\]+)%.json$")
if name and name ~= "index" and not seen[name] then
seen[name] = true
listing[#listing + 1] = name
end
end
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
local windowSource, windowApply = nil, nil
function M.setWindowGeometryHooks(read, apply)
windowSource, windowApply = read, apply
end
local appliers = {}
function M.onApply(flag, fn) appliers[tostring(flag)] = fn end
applyTo = function(key, value, el)
if type(el) == "table" then
if type(el.set) == "function" then
BX.try("profiles.set." .. key, function() el:set(value) end)
elseif type(el.Set) == "function" then
BX.try("profiles.set." .. key, function() el:Set(value) end)
end
end
local fn = appliers[key]
if fn then
return BX.try("profiles.apply." .. key, fn, value)
end
if type(el) == "table" and type(el._callback) == "function" then
return BX.try("profiles.callback." .. key, el._callback, value)
end
return el ~= nil
end
local function elementValue(el)
if type(el) ~= "table" then return el end
if type(el.get) == "function" then
local ok, v = pcall(el.get, el)
if ok then return v end
end
local v = el.CurrentValue
if v == nil then v = el.Value end
if v == nil then v = el.value end
return v
end
local function allElements()
local out = {}
if type(flagSource) == "function" then
local ok, flags = pcall(flagSource)
if ok and type(flags) == "table" then
for name, el in pairs(flags) do out[name] = el end
end
end
for name, el in pairs(controls) do out[name] = el end
return out
end
local function collectFlags()
local out = {}
for name, v in pairs(pending) do
if not skipped(name) then out[tostring(name)] = v end
end
for name, el in pairs(allElements()) do
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
window = (type(windowSource) == "function")
and select(2, pcall(windowSource)) or nil,
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
indexAdd(name)
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
local applied, deferred, ignored = 0, 0, {}
local flagsIn = type(data.flags) == "table" and data.flags or {}
local elements = allElements()
local keys, seen = {}, {}
for _, key in ipairs(ORDER) do
if flagsIn[key] ~= nil then keys[#keys + 1] = key seen[key] = true end
end
local rest = {}
for key in pairs(flagsIn) do
if not seen[key] then rest[#rest + 1] = key end
end
table.sort(rest)
for _, key in ipairs(rest) do keys[#keys + 1] = key end
for _, key in ipairs(keys) do
local value = flagsIn[key]
local el = elements[key]
if skipped(key) and el == nil and not ALLOW[key] then
local n = tostring(key):lower()
local secret = false
for _, bad in ipairs(SKIP_KEYS) do
if n:find(bad, 1, true) then secret = true break end
end
if secret then ignored[#ignored + 1] = key
else pending[key] = value deferred = deferred + 1 end
elseif skipped(key) or (KIND[key] and not validValue(key, value)) then
ignored[#ignored + 1] = key
elseif el == nil then
pending[key] = value
deferred = deferred + 1
else
if applyTo(key, value, el) then applied = applied + 1 end
end
end
if type(data.appearance) == "table" and type(appearanceApply) == "function" then
BX.try("profiles.appearance", function() appearanceApply(data.appearance) end)
end
if type(data.window) == "table" and type(windowApply) == "function" then
BX.try("profiles.window", function() windowApply(data.window) end)
end
loading = false
if #ignored > 0 then
log.info("profile %q: ignored %s", name, table.concat(ignored, ", "))
end
log.info("loaded profile %q (%d settings applied, %d waiting for their tab)", name, applied, deferred)
return true, ("Loaded %s (%d settings)"):format(name, applied + deferred)
end
function M.delete(name)
if not M.available() then return false, "This executor cannot delete files" end
name = safeName(name)
local path = pathFor(name)
if name == "" or not exec.isFile(path) then return false, "No such profile" end
local ok = BX.try("profiles.delete", function() exec.deleteFile(path) end)
if ok then indexRemove(name) end
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
function M.rememberWindowGeometry()
if not M.available() or type(windowSource) ~= "function" then return false end
local ok, geometry = pcall(windowSource)
if not ok or type(geometry) ~= "table" then return false end
local s = readSettings()
s.window = geometry
s.version = FORMAT
local body
if not pcall(function() body = svc.HttpService:JSONEncode(s) end) then return false end
return BX.try("profiles.windowSettings", function()
exec.ensureFolder("BlyxoHub")
if not exec.writeFile(SETTINGS, body) then error("writefile refused", 0) end
end) and true or false
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
local settings = readSettings()
if type(settings.window) == "table" and type(windowApply) == "function" then
BX.try("profiles.windowSettings", function() windowApply(settings.window) end)
end
local name = M.autoLoadName()
if not name then
local found = false
for _, row in ipairs(M.list() or {}) do
local rowName = type(row) == "table" and (row.name or row[1]) or row
if tostring(rowName) == LAST then found = true break end
end
if not found and exec.isFile(pathFor(LAST)) then found = true end
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
M.can.hooking, M.can.gc, M.can.listFiles, M.can.customAsset = false, false, false, false
f_getgc = nil
f_listfiles, f_customasset = nil, nil
if BX.profile then BX.profile.enabled = false end
log.warn("fragile executor (%s): hooks, gc, profile listing, per-frame profiling, renderer settings and custom assets are off", M.name)
end
if M.name:lower():find("madium", 1, true) then
f_listfiles = nil
M.can.listFiles = false
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
function M.requestFunction() return f_request, requestName end
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
local STEPS = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "k" } }
function M.short(n)
n = tonumber(n) or 0
for _, step in ipairs(STEPS) do
if n >= step[1] then
local v = n / step[1]
local text = (v >= 100 or v == math.floor(v)) and ("%d"):format(math.floor(v + 0.5)) or ("%.1f"):format(v)
return text .. step[2]
end
end
return tostring(math.floor(n))
end
return M
end)
BX.module("auth.vampauth", function(BX)
local PROJECT_ID = "R9Z3HF7LBJ0BBIUY"
local AUTH_SECRET = "cef8607da5c3bb3e11f93d8109133e266a7c0d2e3077a190"
local KEY_LINK = "https://vampauth.com/R9Z3HF7LBJ0BBIUY/flow"
local last = ""
local client
local function message(text)
last = tostring(text or "")
return last
end
local function loadClient()
if client then return client end
if AUTH_SECRET == "REPLACE_WITH_YOUR_NEW_VAMP_AUTH_SECRET" then
message("Add your new Vampauth Auth Secret in auth/vampauth.lua first.")
return nil
end
local ok, factory = pcall(function()
local source
local exec = BX.require("core.exec")
local request = exec.requestFunction and exec.requestFunction()
if type(request) == "function" then
local requested, response = pcall(request, {
Url = "https://vampauth.com/client/vampauth.lua",
Method = "GET",
})
if requested and type(response) == "table" then
local status = tonumber(response.StatusCode or response.statusCode
or response.status_code or response.status) or 0
local body = response.Body or response.body
if status >= 200 and status < 300 and type(body) == "string" and #body > 0 then
source = body
end
end
end
if not source then
source = game:HttpGet("https://vampauth.com/client/vampauth.lua")
end
local loader = loadstring or load
return loader(source)()
end)
if not ok or type(factory) ~= "table" then
message("Could not load the Vampauth client.")
return nil
end
local made, instance = pcall(factory.new, {
projectId = PROJECT_ID,
authSecret = AUTH_SECRET,
})
if not made or not instance then
message("Could not initialize Vampauth.")
return nil
end
client = instance
return client
end
local function copyLink()
local set = setclipboard or toclipboard
if type(set) == "function" then
local ok = pcall(set, KEY_LINK)
if ok then
message("Vampauth key link copied.")
return true, KEY_LINK, true
end
end
message("Vampauth key link is ready below.")
return true, KEY_LINK, false
end
local function verifyKey(key)
key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
if key == "" then message("Key is empty."); return false end
local vp = loadClient()
if not vp then return nil end
local ok, valid, data = pcall(function()
local passed, result = vp:Check(key)
return passed, result
end)
if not ok then
message("Vampauth key check failed.")
return nil
end
if valid then
message("Vampauth key is valid.")
return true
end
message(type(data) == "string" and data or "Invalid or expired key.")
return false
end
local function lastMessage() return last end
return {
copyLink = copyLink,
verifyKey = verifyKey,
lastMessage = lastMessage,
}
end)
BX.module("ui.lib.theme", function(BX)
local T = {}
T.PANEL     = Color3.fromRGB(13, 13, 16)    
T.RAIL_BG   = T.PANEL
T.WORKSPACE = T.PANEL
T.GROUP_BG  = Color3.fromRGB(29, 30, 34)    
T.HAIRLINE  = Color3.fromRGB(255, 255, 255) 
T.HAIRLINE_A = 0.92
T.ROW_WASH_HOV = 0.94                       
T.ROW_WASH_HELD = 0.91
T.PANEL_2   = T.WORKSPACE                   
T.LINE      = Color3.fromRGB(52, 53, 58)    
T.CARD_TOP    = Color3.fromRGB(29, 30, 34)
T.CARD_BOT    = Color3.fromRGB(29, 30, 34)
T.CARD_TOP_H  = Color3.fromRGB(33, 34, 38)  
T.CARD_BOT_H  = Color3.fromRGB(33, 34, 38)
T.CARD_ROT    = 55
T.ELEMENT   = Color3.fromRGB(31, 32, 36)
T.ELEMENT_H = Color3.fromRGB(38, 39, 44)
T.CARD_EDGE   = Color3.fromRGB(58, 59, 65)
T.CARD_EDGE_ALPHA   = 1        
T.CARD_EDGE_ALPHA_H = 0.5      
T.CARD_EDGE_H = Color3.fromRGB(128, 103, 163)   
T.TRACK     = Color3.fromRGB(67, 68, 74)    
T.COMMUNITY_TOP  = Color3.fromRGB(29, 30, 34)
T.COMMUNITY_BOT  = Color3.fromRGB(29, 30, 34)
T.COMMUNITY_EDGE = Color3.fromRGB(48, 40, 61)
T.UPDATE_TOP     = Color3.fromRGB(29, 30, 34)
T.UPDATE_BOT     = Color3.fromRGB(29, 30, 34)
T.CTA_BG    = Color3.fromRGB(24, 20, 31)
T.CTA_BG_H  = Color3.fromRGB(33, 26, 45)
T.CTA_EDGE  = Color3.fromRGB(64, 50, 79)
T.CTA_TEXT  = Color3.fromRGB(232, 226, 240)
T.CARD_TITLE  = Color3.fromRGB(243, 239, 248)   
T.BADGE_BG    = Color3.fromRGB(115, 81, 176)    
T.ROW_TAG     = Color3.fromRGB(169, 154, 192)
T.ROW_TEXT    = Color3.fromRGB(225, 221, 235)
T.ROW_TEXT_LAST = Color3.fromRGB(242, 239, 255)
T.TEXT      = Color3.fromRGB(235, 235, 238)
T.MUTED     = Color3.fromRGB(153, 154, 161)   
T.PAGE_TITLE = Color3.fromRGB(235, 235, 238)
T.SECTION   = Color3.fromRGB(151, 152, 159)
T.TAB_OFF   = Color3.fromRGB(160, 161, 168)
T.TAB_ON    = Color3.fromRGB(245, 245, 246)
T.SELECT_TEXT = Color3.fromRGB(205, 180, 255)
T.ACCENT    = Color3.fromRGB(167, 139, 250)  
T.ACCENT_DEEP = Color3.fromRGB(91, 43, 180)
T.ACCENT_2  = T.ACCENT
T.ACCENT_D  = T.TRACK
T.WARN      = Color3.fromRGB(224, 123, 138)
T.GOOD      = Color3.fromRGB(52, 199, 89)     
T.WHITE     = Color3.fromRGB(255, 255, 255)
T.BLACK     = Color3.fromRGB(0, 0, 0)
T.TOGGLE_ON = ColorSequence.new(T.ACCENT_DEEP, T.ACCENT)          
T.TAB_ACTIVE = ColorSequence.new(
Color3.fromRGB(67, 51, 96), Color3.fromRGB(43, 33, 63))
T.TAB_ACTIVE_ROT = 20
T.TAB_WASH      = Color3.fromRGB(255, 255, 255)
T.TAB_WASH_ON   = 0.9
T.TAB_WASH_HOV  = 0.94
T.TAB_EDGE  = Color3.fromRGB(111, 81, 166)
T.SELECT_BG = Color3.fromRGB(88, 62, 128)    
T.SELECT_EDGE = Color3.fromRGB(116, 88, 155) 
T.CAPSULE_EDGE = T.ACCENT                    
T.WORDMARK_GRADIENT = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
ColorSequenceKeypoint.new(0.55, Color3.fromRGB(229, 220, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(167, 139, 250)),
})
T.WORDMARK_GLASS = ColorSequence.new({
ColorSequenceKeypoint.new(0,    Color3.fromRGB(139, 61, 255)),
ColorSequenceKeypoint.new(0.32, Color3.fromRGB(176, 140, 255)),
ColorSequenceKeypoint.new(0.47, Color3.fromRGB(236, 228, 255)),
ColorSequenceKeypoint.new(0.53, Color3.fromRGB(255, 255, 255)),
ColorSequenceKeypoint.new(0.68, Color3.fromRGB(176, 140, 255)),
ColorSequenceKeypoint.new(1,    Color3.fromRGB(139, 61, 255)),
})
T.GLASS_ROT   = 20      
T.GLASS_SWEEP = 3.2     
T.GLASS_EDGE  = Color3.fromRGB(255, 255, 255)  
T.GLASS_EDGE_ALPHA = 0.78
local COMMON_FONT = Font.fromEnum(Enum.Font.GothamMedium)
local BOLD_FONT = Font.fromEnum(Enum.Font.GothamBold)
local okTitle, TITLE_FONT = pcall(Font.new, "rbxassetid://12187365364", Enum.FontWeight.SemiBold)
if not okTitle or not TITLE_FONT then TITLE_FONT = COMMON_FONT end
T.FONT_TITLE = TITLE_FONT
T.FONT       = COMMON_FONT
T.FONT_MED   = COMMON_FONT
T.FONT_BOLD  = BOLD_FONT
T.MEASURE_FONT = Enum.Font.Gotham
T.SIZE_TITLE   = 20     
T.SIZE_SUB     = 12     
T.SIZE_PAGE    = 26     
T.SIZE_CARD_TITLE = 15  
T.SIZE_SECTION = 11     
T.SIZE_ROW     = 16     
T.SIZE_DESC    = 13     
T.SIZE_TAB     = 17
T.SIZE_BADGE   = 11
T.SIZE_VERSION_TAG = 14
T.SIZE_SELECT  = 13
T.WIN_W = 900
T.WIN_H = 620
T.WIN_W_NARROW = 520
T.WIN_H_NARROW = 540
T.WIN_MIN_W = 560
T.WIN_MIN_H = 340
T.WIN_MIN_W_NARROW = 300
T.WIN_MIN_H_NARROW = 360
T.RADIUS_WIN = 10
T.TITLEBAR_H  = 56
T.TITLEBAR_PAD_X = 16
T.TABBAR_W  = 176       
T.TABBAR_H  = 48        
T.RAIL_PAD_X = 12
T.RAIL_PAD_Y = 10
T.TAB_H     = 42
T.TAB_GAP   = 1
T.TAB_PAD_X = 14
T.RADIUS_TAB = 10
T.WORKSPACE_PAD_X = 24
T.WORKSPACE_PAD_Y = 8
T.PAGE_HEADER_H = 36
T.ROW_H      = 46
T.SECTION_H  = 28       
T.PAD        = 24
T.GAP        = 6
T.FADE_H     = 60     
T.CARD_PAD_X = 14
T.CARD_PAD_Y = 8
T.CARD_GAP   = 12
T.RADIUS     = 10
T.RADIUS_SM  = 8
T.CONTROL_INSET = 14
T.CONTROL_RESERVE = 190     
T.VALUE_RESERVE   = 190
T.TOGGLE_W = 36
T.TOGGLE_H = 20
T.TOGGLE_KNOB = 16
T.TOGGLE_KNOB_WIDE = 18    
T.SELECT_W = 190
T.SELECT_H = 38
T.ACTION_W = 78
T.ACTION_H = 22
T.STATUS_W = 76
T.STATUS_H = 26
T.SIZE_PILL = 10
T.USER_CHIP_H = 58
T.USER_CHIP_RADIUS = 16
T.LOGO       = BX.require("ui.logo").image()
T.LOGO_FLAT  = T.LOGO
T.LOGO_GLOSS = T.LOGO
T.LOGO_SIZE  = 40       
T.LOGO_RADIUS = 13
T.LOGO_FILE  = nil
T.SIDE_W        = 160       
T.SIDE_BTN_H    = 50
T.SIDE_GAP      = 8         
T.SIDE_COL_GAP  = 12        
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
T.BLOOM_BLUR   = 120
T.BLOOM_ALPHA  = 0.78
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
T.EASE_WINDOW = Enum.EasingStyle.Quint
T.FADE        = 0.2
T.MOVE        = 0.35
T.ENTER       = 0.35
T.TAB_FADE    = 0.12    
T.TAB_PAGE    = 0.20    
T.SLIDE_IN    = 3       
T.PRESS_SCALE = 0.98
T.PRESS_IN    = 0.06    
T.PRESS_OUT   = 0.22    
T.MORPH       = 0.35
T.MORPH_CHROME = 0.16
T.LIFT_SCALE   = 1.015
T.LIFT_SHADOW  = 0.22    
T.DRAG_K       = 180     
T.DRAG_C       = 26.8    
T.THROW        = 0.12    
T.EDGE_GIVE    = 0.25    
T.EDGE_MAX     = 48      
T.CLOSE_TINT   = Color3.fromRGB(255, 95, 86)
T.MORPH_IN    = 0.42
T.MORPH_OUT   = 0.42
T.EASE_SPRING = Enum.EasingStyle.Quint
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
function T.roundBottomLeftOnly(frame, radius, colour)
radius = radius or T.RADIUS_WIN
local function patch(name, anchor, pos)
local f = Instance.new("Frame")
f.Name = name
f.AnchorPoint = anchor
f.Position = pos
f.Size = UDim2.fromOffset(radius, radius)
f.BackgroundColor3 = colour or T.PANEL
f.BorderSizePixel = 0
f.ZIndex = 0
f.Parent = frame
end
patch("SquareTL", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0))
patch("SquareTR", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0))
patch("SquareBR", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0))
end
function T.roundTopLeftBottomRight(frame, radius, colour)
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
end
function T.roundBottomRightOnly(frame, radius, colour)
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
patch("SquareTL", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0))
patch("SquareTR", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0))
patch("SquareBL", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0))
end
function T.roundBottomOnly(frame, radius, colour)
radius = radius or T.RADIUS_WIN
local function patch(name, anchor, pos)
local f = Instance.new("Frame")
f.Name = name
f.AnchorPoint = anchor
f.Position = pos
f.Size = UDim2.fromOffset(radius, radius)
f.BackgroundColor3 = colour or T.PANEL
f.BorderSizePixel = 0
f.ZIndex = 0
f.Parent = frame
end
patch("SquareTL", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0))
patch("SquareTR", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0))
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
T.TOUCH_MARGIN = 16
function T.fitScale(width, height, margin)
margin = margin or 64
local scale = 1
pcall(function()
local vp = workspace.CurrentCamera.ViewportSize
scale = math.clamp(
math.min((vp.X - margin) / width, (vp.Y - margin) / height), 0.35, 1)
end)
return scale
end
function T.fitTouchSize(width, height)
local w, h = width, height
pcall(function()
local vp = workspace.CurrentCamera.ViewportSize
if vp.X < 100 or vp.Y < 100 then return end
w = math.clamp(vp.X - T.TOUCH_MARGIN, T.WIN_MIN_W_NARROW, width)
h = math.clamp(vp.Y - T.TOUCH_MARGIN, 220, height)
end)
return math.floor(w), math.floor(h)
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
errors = 0, maxBatch = 0, requeued = 0, dropped = 0 }
function M.stats() return table.clone(stats) end
local MAX_JOBS = 2000
local warnedJobs = false
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
local n = #jobs
if n >= MAX_JOBS then
local keep = {}
for i = n - MAX_JOBS // 2 + 1, n do keep[#keep + 1] = jobs[i] end
stats.dropped = stats.dropped + (n - #keep)
jobs = keep
if not warnedJobs then
warnedJobs = true
log.error("render queue overflowed (%d jobs, %d frames drained) - the drain loop is not keeping up",
n, stats.frames)
end
end
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
local lastFrameStuck = false
local function drain()
if draining then return end
draining = true
local batch = 0
local requeuedBefore, appliedBefore = stats.requeued, stats.applied
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
lastFrameStuck = batch > 0
and stats.applied == appliedBefore
and stats.requeued > requeuedBefore
draining = false
end
M.drain = drain
local sc = nil
local started = false
local loopAlive = false
local loopGen = 0
local restarts = 0
local signalMode = 1
local SIGNAL_NAMES = { "RenderStepped", "Heartbeat", "task.wait" }
local function spawnLoop(reason)
if not sc or not sc:alive() then return end
loopGen = loopGen + 1
local myGen = loopGen
loopAlive = true
local RunService = svc.RunService
sc:spawn("drain#" .. myGen, function()
local waitErrs, stuckFrames = 0, 0
while sc:alive() and myGen == loopGen do   
local okWait = false
if signalMode == 1 then
okWait = pcall(function() RunService.RenderStepped:Wait() end)
end
if not okWait and signalMode <= 2 then
okWait = pcall(function() RunService.Heartbeat:Wait() end)
end
if not okWait then
waitErrs = waitErrs + 1
if waitErrs == 1 and signalMode < 3 then
log.error("render loop: no frame signal reachable, falling back to task.wait")
end
task.wait()
end
stats.frames = stats.frames + 1
local okDrain, err = pcall(drain)
if not okDrain then
stats.errors = stats.errors + 1
draining = false
log.warn("render frame failed: %s", tostring(err))
end
if lastFrameStuck then
stuckFrames = stuckFrames + 1
if stuckFrames >= 3 then
if restarts < 3 then
log.error("render loop thread is capability-narrowed after %d frames; re-creating it", stuckFrames)
end
break
end
else
stuckFrames = 0
end
end
if myGen == loopGen then
loopAlive = false
if sc and sc:alive() then
restarts = restarts + 1
task.defer(function() spawnLoop("narrowed") end)
end
end
end)
if reason and restarts <= 3 then
log.warn("render loop re-created (%s, restart %d)", reason, restarts)
end
end
function M.start()
if started then return true end
started = true
sc = BX.scope("ui.lib.render")
spawnLoop(nil)
local lastSeen, stalled = stats.frames, 0
local framesAtRestart = -1
local function watchdog()
if not sc or not sc:alive() then return end
if stats.frames == lastSeen then
stalled = stalled + 1
if stalled >= 2 then
stalled = 0
loopAlive = false
if stats.frames == framesAtRestart and signalMode < 3 then
signalMode = signalMode + 1
log.error("render loop: %s never delivered a frame here, pacing on %s instead",
SIGNAL_NAMES[signalMode - 1], SIGNAL_NAMES[signalMode])
end
framesAtRestart = stats.frames
restarts = restarts + 1
spawnLoop("watchdog: no frames for 2s")
end
else
stalled = 0
end
lastSeen = stats.frames
task.delay(1.0, watchdog)
end
task.delay(1.0, watchdog)
log.info("render queue started")
return true
end
function M.stop()
if sc then sc:destroy() sc = nil end
started = false
loopAlive = false
pending, pendingN, jobs = setmetatable({}, { __mode = "k" }), 0, {}
end
function M.health()
return ("render: frames=%d applied=%d jobs=%d requeued=%d errors=%d dropped=%d restarts=%d pending=%d/%d loop=%s")
:format(stats.frames, stats.applied, stats.jobs, stats.requeued,
stats.errors, stats.dropped, restarts, pendingN, #jobs, loopAlive and "alive" or "DEAD")
.. " signal=" .. tostring(SIGNAL_NAMES[signalMode])
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
local SFX = BX.require("ui.sfx")
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
local groups = setmetatable({}, { __mode = "k" })
local function groupFor(parent)
if parent:GetAttribute("Grouped") then return nil, true end
local g = groups[parent]
if g and g.Parent then return g, true end
return nil, false
end
local function card(parent, opts)
local group, grouped = groupFor(parent)
if group then parent = group end
local hasDesc = opts.description ~= nil and opts.description ~= ""
local reserve = opts.reserve or T.CONTROL_RESERVE
local ctrlH = opts.controlHeight or 26
local expandable = opts.expandable == true
local cardHeight = opts.minHeight or (expandable and 62 or (hasDesc and 52 or 44))
local root = mk("Frame", {
Name = "Card_" .. tostring(opts.name or "?"),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, cardHeight),
AutomaticSize = Enum.AutomaticSize.None,
LayoutOrder = opts.order or 0,
ClipsDescendants = false,
Parent = parent,
}, {
T.corner(T.RADIUS),
T.cardGradient(false),
T.stroke(T.CARD_EDGE, 1, T.CARD_EDGE_ALPHA),
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
if not expandable then
col.AutomaticSize = Enum.AutomaticSize.None
col.Size = UDim2.new(1, -(reserve + T.CONTROL_INSET + T.CARD_GAP),
0, hasDesc and 37 or 18)
col.Position = UDim2.fromOffset(T.CARD_PAD_X, T.CARD_PAD_Y)
end
local title = label(opts.name, T.SIZE_ROW, T.TEXT, true)
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, hasDesc and 18 or 18)
title.AutomaticSize = Enum.AutomaticSize.None
title.TextYAlignment = Enum.TextYAlignment.Top
title.LayoutOrder = 1
title.Parent = col
local desc = nil
if hasDesc then
desc = label(opts.description, T.SIZE_DESC, T.MUTED, false)
desc.Name = "Desc"
desc.Size = UDim2.new(1, 0, 0, 16)
desc.AutomaticSize = Enum.AutomaticSize.None
desc.TextWrapped = false
desc.TextTruncate = Enum.TextTruncate.AtEnd
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
if not expandable then
local list = root:FindFirstChildOfClass("UIListLayout")
if list then list:Destroy() end
col.Visible = false
title.Parent = root
title.Position = UDim2.fromOffset(0, 0)
title.Size = UDim2.new(1, -(reserve + T.CONTROL_INSET + T.CARD_GAP), 0, 18)
title.ZIndex = 11
if desc then
desc.Parent = root
desc.Position = UDim2.fromOffset(0, 21)
desc.Size = UDim2.new(1, -(reserve + T.CONTROL_INSET + T.CARD_GAP), 0, 16)
desc.ZIndex = 11
end
if ctrl then
ctrl.AnchorPoint = Vector2.new(1, 0.5)
ctrl.Position = UDim2.new(1, 0, 0.5, 0)
end
end
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
local press = nil
local wash = nil
local shell = {
root = root, header = header, col = col, title = title, desc = desc,
ctrl = ctrl, edge = edge, fill = fill, press = press, wash = wash,
grouped = grouped,
order = opts.order or 0,
}
return shell
end
local function makeHoverable(shell, hit)
local inside, held = false, false
local function paint()
if shell.fill then
R.set(shell.fill, "Color", ColorSequence.new(
(inside or held) and T.CARD_TOP_H or T.CARD_TOP,
(inside or held) and T.CARD_BOT_H or T.CARD_BOT))
end
if shell.edge then
R.tween(shell.edge, T.FADE, {
Color = (inside or held) and T.CARD_EDGE_H or T.CARD_EDGE,
Transparency = held and 0.72 or (inside and 0.88 or T.CARD_EDGE_ALPHA),
Thickness = 1,
})
end
if shell.wash then
R.tween(shell.wash, held and T.PRESS_IN or T.FADE, {
BackgroundTransparency = held and T.ROW_WASH_HELD
or (inside and T.ROW_WASH_HOV or 1),
})
end
if shell.press then
R.tween(shell.press, held and T.PRESS_IN or T.PRESS_OUT, {
Scale = held and T.PRESS_SCALE or 1,
}, held and Enum.EasingStyle.Quad or T.EASE_UI)
end
end
hit.MouseEnter:Connect(function() inside = true paint(); SFX.hover() end)
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
function W.subnav(parent, opts)
opts = opts or {}
local root = mk("Frame", {
Name = "Subnav",
BackgroundColor3 = T.BLACK,
BackgroundTransparency = 0.86,
BorderSizePixel = 0,
Size = UDim2.new(1, 0, 0, 32),
LayoutOrder = opts.order or 0,
Parent = parent,
}, {
T.corner(9),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
}),
mk("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
VerticalAlignment = Enum.VerticalAlignment.Center,
Padding = UDim.new(0, 2),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local buttons = {}
local active = nil
local function paint(name, on)
local b = buttons[name]
if not b then return end
R.tween(b, T.TAB_FADE, {
BackgroundTransparency = on and 0.72 or 1,
TextColor3 = on and T.TAB_ON or T.TAB_OFF,
}, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
end
local function select(name)
if active == name then return end
if active then paint(active, false) end
active = name
paint(name, true)
end
for i, item in ipairs(opts.items or {}) do
local name = tostring(item)
local b = mk("TextButton", {
Name = "Filter_" .. name,
AutoButtonColor = false,
AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = T.ACCENT_DEEP,
BackgroundTransparency = 1,
BorderSizePixel = 0,
FontFace = T.FONT,
LayoutOrder = i,
Text = name,
TextColor3 = T.TAB_OFF,
TextSize = 12,
Size = UDim2.fromOffset(0, 26),
Parent = root,
}, {
T.corner(7),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}),
})
buttons[name] = b
b.Activated:Connect(function()
select(name)
if opts.callback then opts.callback(name) end
end)
end
if opts.items and opts.items[1] then select(tostring(opts.items[1])) end
local h = newHandle("subnav", { root = root })
function h:select(name) select(tostring(name)) end
return h
end
function W.section(parent, opts)
local root = mk("Frame", {
Name = "Section",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = opts.order or 0,
Parent = parent,
}, {
mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
})
local head = mk("Frame", {
Name = "Head",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, T.SECTION_H),
LayoutOrder = 1,
Parent = root,
})
local group = mk("Frame", {
Name = "Group",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
AutomaticSize = Enum.AutomaticSize.Y,
LayoutOrder = 2,
Parent = root,
}, {
mk("UIListLayout", {
Padding = UDim.new(0, T.GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
groups[parent] = group
local text = label(string.upper(tostring(opts.name or "")),
T.SIZE_SECTION, T.SECTION, true)
text.Name = "Label"
text.AnchorPoint = Vector2.new(0, 1)
text.Position = UDim2.new(0, 2, 1, -8)
text.Size = UDim2.new(1, -4, 0, 14)
text.TextYAlignment = Enum.TextYAlignment.Bottom
text.Parent = head
local h = newHandle("section", { root = root, title = text })
h.group = group
function h:set(v) R.set(text, "Text", string.upper(tostring(v))) end
function h:get() return text.Text end
return h
end
function W.label(parent, opts)
local wide = opts.wide == true
local reserve = wide and (T.VALUE_RESERVE + 72) or T.VALUE_RESERVE
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = reserve,
controlHeight = wide and 38 or T.STATUS_H,
minHeight = wide and 62 or nil,
})
local cell = mk("Frame", {
Name = "Status",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -T.CONTROL_INSET, 0.5, 0),
Size = UDim2.fromOffset(reserve, wide and 38 or T.STATUS_H),
BackgroundTransparency = 1,
Parent = shell.ctrl,
})
local value = label(tostring(opts.text or ""), T.SIZE_DESC, T.TEXT, true)
value.Name = "Value"
value.AnchorPoint = Vector2.new(wide and 0 or 1, 0.5)
value.Position = wide and UDim2.fromOffset(16, 0) or UDim2.new(1, 0, 0.5, 0)
value.Size = wide and UDim2.new(1, -16, 1, 0) or UDim2.new(1, -16, 1, 0)
value.TextXAlignment = wide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
value.TextWrapped = wide
value.TextTruncate = wide and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
value.Parent = cell
local dot = mk("Frame", {
Name = "Dot",
AnchorPoint = wide and Vector2.new(0, 0.5) or Vector2.new(1, 0.5),
Position = wide and UDim2.fromOffset(0, 0) or UDim2.new(1, -(value.TextBounds.X + 12), 0.5, 0),
Size = UDim2.fromOffset(8, 8),
BackgroundColor3 = T.TEXT,
BorderSizePixel = 0,
Parent = cell,
}, { T.corner(4) })
local function tone(text)
if opts.tone then return opts.tone end
local t = tostring(text):lower()
if t:match("^open") or t:match("^on%f[%A]") or t:match("^ready") or t:match("^unlocked")
or t:match("^active") or t:match("^running") or t:match("^connected") then return "good" end
if t:match("^closed") or t:match("^off%f[%A]") or t:match("^locked") or t:find("expired")
or t:find("failed") or t:find("error") or t:match("^not ") then return "bad" end
return "normal"
end
local TONE = { good = T.GOOD, bad = T.WARN, warn = T.WARN, normal = T.TEXT }
local function place()
if wide then return end
local w = math.min(value.TextBounds.X, cell.AbsoluteSize.X - 16)
R.set(dot, "Position", UDim2.new(1, -(w + 12), 0.5, 0))
end
local function paintTone(text)
R.tween(dot, T.FADE, { BackgroundColor3 = TONE[tone(text)] or T.TEXT })
end
value:GetPropertyChangedSignal("TextBounds"):Connect(place)
place()
paintTone(opts.text)
local current = tostring(opts.text or "")
local h = newHandle("label", shell)
function h:set(v)
v = tostring(v)
if v == current then return end
current = v
R.set(value, "Text", v)
paintTone(v)
end
function h:get() return current end
function h:setTone(t) opts.tone = t paintTone(current) end
return h
end
local function directControlText(shell, opts)
local inset = 0
if shell.title then shell.title.Visible = false end
if shell.desc then shell.desc.Visible = false end
local title = label(tostring(opts.name or ""), T.SIZE_ROW, T.TEXT, true)
title.Name = "ControlTitle"
title.Position = UDim2.fromOffset(inset, 0)
title.Size = UDim2.new(1, -(inset + T.CARD_PAD_X + (opts.reserve or 0)
+ T.CONTROL_INSET + T.CARD_GAP), 0, 18)
title.TextYAlignment = Enum.TextYAlignment.Top
title.ZIndex = 12
title.Parent = shell.root
if opts.description and opts.description ~= "" then
local desc = label(tostring(opts.description), T.SIZE_DESC, T.MUTED, false)
desc.Name = "ControlDescription"
desc.Position = UDim2.fromOffset(inset, 21)
desc.Size = UDim2.new(1, -(inset + T.CARD_PAD_X + (opts.reserve or 0)
+ T.CONTROL_INSET + T.CARD_GAP), 0, 16)
desc.TextWrapped = false
desc.TextTruncate = Enum.TextTruncate.AtEnd
desc.TextYAlignment = Enum.TextYAlignment.Top
desc.ZIndex = 12
desc.Parent = shell.root
end
end
function W.button(parent, opts)
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = 0, controlHeight = 0,
})
directControlText(shell, {
name = opts.name, description = opts.description,
reserve = 0,
})
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
directControlText(shell, {
name = opts.name, description = opts.description,
reserve = T.TOGGLE_W,
})
local track = mk("Frame", {
Name = "Track",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
Size = UDim2.fromOffset(T.TOGGLE_W, T.TOGGLE_H),
BackgroundColor3 = T.ACCENT_D,
BorderSizePixel = 0,
Parent = shell.ctrl,
}, { T.corner(T.TOGGLE_H / 2) })
local knobSize = T.TOGGLE_KNOB
local inset = (T.TOGGLE_H - knobSize) / 2
local knob = mk("Frame", {
Name = "Knob",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, inset, 0.5, 0),
Size = UDim2.fromOffset(knobSize, knobSize),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Parent = track,
}, {
T.corner(knobSize / 2),
})
local initialState = opts.value
if initialState == nil then initialState = opts.currentValue end
local state = initialState and true or false
local h = newHandle("toggle", shell)
local hit = hitbox(shell.root)
R.set(hit, "Size", UDim2.new(1, T.CARD_PAD_X * 2, 1, T.CARD_PAD_Y * 2))
R.set(hit, "Position", UDim2.fromOffset(-T.CARD_PAD_X, -T.CARD_PAD_Y))
makeHoverable(shell, hit)
local function paint(animate)
local w = knobSize
local pos = state and UDim2.new(1, -(w + inset), 0.5, 0)
or UDim2.new(0, inset, 0.5, 0)
local size = UDim2.fromOffset(w, knobSize)
local col = state and T.ACCENT or T.ACCENT_D
if animate then
R.tween(knob, 0.16, { Position = pos, Size = size }, Enum.EasingStyle.Cubic,
Enum.EasingDirection.Out)
R.tween(track, 0.16, { BackgroundColor3 = col }, Enum.EasingStyle.Cubic,
Enum.EasingDirection.Out)
else
R.set(knob, "Position", pos)
R.set(knob, "Size", size)
R.set(track, "BackgroundColor3", col)
end
end
paint(false)
hit.InputEnded:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
paint(true)
end)
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
ZIndex = T.OVERLAY_Z + 3,
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
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
ClipsDescendants = true,
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
local scrim, scrimClose = nil, nil
function W.scrim(on, onTap)
if not ctx.overlay then return end
if not scrim or not scrim.Parent then
scrim = mk("TextButton", {
Name = "Scrim",
Text = "",
AutoButtonColor = false,
BackgroundColor3 = T.BLACK,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Size = UDim2.fromScale(1, 1),
Visible = false,
ZIndex = T.OVERLAY_Z,
Parent = ctx.overlay,
}, { T.corner(T.RADIUS_WIN) })
scrim.Activated:Connect(function()
if scrimClose then scrimClose() end
end)
end
scrimClose = onTap
if on then
R.set(scrim, "Visible", true)
R.tween(scrim, T.FADE, { BackgroundTransparency = 0.6 })
else
R.tween(scrim, T.FADE, { BackgroundTransparency = 1 })
R.call(function()
task.delay(T.FADE + 0.02, function()
if scrim and scrim.BackgroundTransparency >= 0.99 then scrim.Visible = false end
end)
end)
end
end
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
local preview = type(opts.preview) == "function" and opts.preview or nil
local meta = type(opts.meta) == "function" and opts.meta or nil
local PILL_W = meta and 204 or T.SELECT_W
local PILL_H = meta and 54 or T.SELECT_H
local shell = card(parent, {
name = opts.name, description = opts.description, order = opts.order,
reserve = PILL_W, controlHeight = PILL_H,
minHeight = meta and (PILL_H + T.CARD_PAD_Y * 2) or nil,
expandable = true,
})
local pill = mk("Frame", {
Name = "Select",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -T.CONTROL_INSET, 0.5, 0),
Size = UDim2.fromOffset(PILL_W, PILL_H),
BackgroundColor3 = T.SELECT_BG,
BackgroundTransparency = 0.88,
BorderSizePixel = 0,
Parent = shell.ctrl,
}, {
T.corner(PILL_H / 2),
T.stroke(T.SELECT_EDGE, 1, 0.68),
})
local arrowHolder = chevron(pill, ARROW, T.SELECT_TEXT)
arrowHolder.AnchorPoint = Vector2.new(1, 0.5)
arrowHolder.Position = UDim2.new(1, -8, 0.5, 0)
local PREVIEW = 28
local PILL_PREVIEW = PILL_H - 12
local function viewport(name, size, z, parent)
local vp = mk("ViewportFrame", {
Name = name,
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
Size = UDim2.fromOffset(size, size),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Ambient = Color3.fromRGB(190, 190, 200),
LightColor = Color3.fromRGB(255, 255, 255),
LightDirection = Vector3.new(-0.4, -1, -0.6),
Visible = false,
ZIndex = z,
Parent = parent,
}, { T.corner(7) })
local cam = Instance.new("Camera")
cam.FieldOfView = 40
cam.Parent = vp
vp.CurrentCamera = cam
return { vp = vp, cam = cam, text = nil }
end
local function showIn(slot, text)
if not preview or slot.text == text then return end
slot.text = text
local vp, cam = slot.vp, slot.cam
for _, c in ipairs(vp:GetChildren()) do
if c ~= cam then c:Destroy() end
end
local model = nil
if text then
local ok, got = pcall(preview, text)
if ok then model = got end
end
if typeof(model) ~= "Instance" then
R.set(vp, "Visible", false)
return
end
model.Parent = vp
local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
if not ok then
model:Destroy()
R.set(vp, "Visible", false)
return
end
local radius = math.max(size.Magnitude / 2, 0.5)
local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.02
local dir = Vector3.new(0.55, 0.38, 1).Unit
cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
R.set(vp, "Visible", true)
end
local pillPreview = preview and viewport("Preview", PILL_PREVIEW, 2, pill) or nil
if pillPreview then
pillPreview.vp.Position = UDim2.new(0, 6, 0.5, 0)
end
local chosen = label("", T.SIZE_SELECT, T.SELECT_TEXT, true)
chosen.Name = "Chosen"
chosen.AnchorPoint = Vector2.new(0, 0.5)
chosen.Position = UDim2.new(0, 14, 0.5, 0)
chosen.Size = UDim2.new(1, -(14 + ARROW * 2 + 14), 1, 0)
chosen.TextXAlignment = Enum.TextXAlignment.Left
chosen.TextTruncate = Enum.TextTruncate.AtEnd
chosen.Parent = pill
local pillKicker, pillName, pillRarity, pillValue
if meta then
chosen.Visible = false
local left = 6 + PILL_PREVIEW + 8
pillKicker = label(tostring(opts.metaTitle or "BEST EGG"), 9, T.MUTED, true)
pillKicker.Position = UDim2.fromOffset(left, 7)
pillKicker.Size = UDim2.new(1, -(left + 44), 0, 13)
pillKicker.Parent = pill
pillName = label("", 13, T.SELECT_TEXT, true)
pillName.Position = UDim2.fromOffset(left, 19)
pillName.Size = UDim2.new(1, -(left + 42), 0, 19)
pillName.TextTruncate = Enum.TextTruncate.AtEnd
pillName.Parent = pill
pillRarity = label("", 10, T.ACCENT, true)
pillRarity.Position = UDim2.fromOffset(left, 40)
pillRarity.Size = UDim2.new(0.55, 0, 0, 14)
pillRarity.Parent = pill
pillValue = label("", 11, Color3.fromRGB(82, 218, 133), true)
pillValue.AnchorPoint = Vector2.new(1, 0)
pillValue.Position = UDim2.new(1, -30, 0, 39)
pillValue.Size = UDim2.fromOffset(74, 15)
pillValue.TextXAlignment = Enum.TextXAlignment.Right
pillValue.Parent = pill
end
local function layoutPill(withPicture)
local left = withPicture and (5 + PILL_PREVIEW + 8) or 14
R.set(chosen, "Position", UDim2.new(0, left, 0.5, 0))
R.set(chosen, "Size", UDim2.new(1, -(left + ARROW * 2 + 14), 1, 0))
end
local function paintPill(value)
if pillPreview then
showIn(pillPreview, value)
layoutPill(pillPreview.vp.Visible)
end
if meta and pillName then
local info
if value then
local ok, got = pcall(meta, value)
if ok and type(got) == "table" then info = got end
end
R.set(pillKicker, "Text", tostring(opts.metaTitle or "BEST EGG"))
R.set(pillName, "Text", tostring(info and info.name or value or opts.placeholder or "SELECT"))
R.set(pillRarity, "Text", tostring(info and info.rarity or ""))
R.set(pillValue, "Text", tostring(info and info.value or ""))
end
end
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
ZIndex = T.OVERLAY_Z + 1,
ClipsDescendants = true,
Parent = ctx.overlay,
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
ZIndex = T.OVERLAY_Z + 2,
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
local search
local SEARCH_H = 30
local open = false
local wantHeight
local h
local function layoutInner()
local top = 44
R.set(inner, "Position", UDim2.fromOffset(6, 6 + top))
R.set(inner, "Size", UDim2.new(1, -12, 1, -(12 + top)))
end
local SHEET_HEAD = 44
local SHEET_MARGIN = 16
local sheetHead = mk("Frame", {
Name = "SheetHead",
Size = UDim2.new(1, 0, 0, SHEET_HEAD),
BackgroundTransparency = 1,
ZIndex = T.OVERLAY_Z + 2,
Parent = panel,
})
mk("Frame", {
Name = "Grab",
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, 8),
Size = UDim2.fromOffset(36, 4),
BackgroundColor3 = T.MUTED,
BackgroundTransparency = 0.5,
BorderSizePixel = 0,
ZIndex = T.OVERLAY_Z + 3,
Parent = sheetHead,
}, { T.corner(2) })
local sheetTitle = label(tostring(opts.name or ""), T.SIZE_ROW, T.TEXT, true)
sheetTitle.Name = "Title"
sheetTitle.Position = UDim2.fromOffset(T.CARD_PAD_X, 16)
sheetTitle.Size = UDim2.new(1, -T.CARD_PAD_X * 2, 0, 24)
sheetTitle.ZIndex = T.OVERLAY_Z + 3
sheetTitle.Parent = sheetHead
local sheetClose = mk("TextButton", {
Name = "Close",
AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, -10, 0, 8),
Size = UDim2.fromOffset(40, 32),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.94,
BorderSizePixel = 0,
AutoButtonColor = false,
Text = "×",
TextColor3 = T.TEXT,
FontFace = T.FONT,
TextSize = 24,
ZIndex = T.OVERLAY_Z + 4,
Parent = sheetHead,
}, { T.corner(10), T.stroke(T.WHITE, 1, 0.88) })
local lastClose = 0
local function closeSheet()
local now = os.clock()
if now - lastClose < 0.08 then return end
lastClose = now
if h and not h._dead then h:setOpen(false) end
end
sheetClose.Activated:Connect(closeSheet)
sheetClose.MouseButton1Click:Connect(closeSheet)
sheetClose.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
closeSheet()
end
end)
local function sheetHeight()
return SHEET_HEAD + wantHeight()
end
local function sheetRest()
return UDim2.new(0, SHEET_MARGIN, 1, -(sheetHeight() + SHEET_MARGIN))
end
local function positionPanel()
R.set(panel, "Position", sheetRest())
R.set(panel, "Size", UDim2.new(1, -SHEET_MARGIN * 2, 0, sheetHeight()))
end
local OPT_H, MAX_SHOWN = meta and 54 or 38, 7
local SEARCH_MIN = 8
local query = ""
search = mk("TextBox", {
Name = "Search",
Position = UDim2.fromOffset(6, 6),
Size = UDim2.new(1, -12, 0, SEARCH_H),
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
search.Parent = panel
local frames, options = {}, {}
local selected = multi and {} or nil
local single = nil
h = newHandle("dropdown", shell)
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
paintPill(not multi and single or nil)
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
ZIndex = T.OVERLAY_Z + 3,
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
ZIndex = T.OVERLAY_Z + 4,
Parent = btn,
}, { T.corner(5), T.stroke(T.ACCENT, 1, 0.58) })
local textLeft = 38
local pic
if preview then
local previewSize = meta and 36 or PREVIEW
pic = viewport("Preview", previewSize, T.OVERLAY_Z + 4, btn)
pic.vp.Position = UDim2.new(0, 36, 0.5, 0)
textLeft = 36 + previewSize + 8
end
local txt = label("", 11, T.SELECT_TEXT, true)
txt.Position = UDim2.new(0, textLeft, 0, meta and 6 or 0)
txt.Size = UDim2.new(1, -(textLeft + 12), 0, meta and 19 or 38)
txt.TextTruncate = Enum.TextTruncate.AtEnd
txt.ZIndex = T.OVERLAY_Z + 4
txt.Parent = btn
local sub, value
if meta then
sub = label("", 10, T.ACCENT, true)
sub.Position = UDim2.new(0, textLeft, 0, 28)
sub.Size = UDim2.new(0.5, 0, 0, 16)
sub.TextTruncate = Enum.TextTruncate.AtEnd
sub.ZIndex = T.OVERLAY_Z + 4
sub.Parent = btn
value = label("", 11, Color3.fromRGB(82, 218, 133), true)
value.AnchorPoint = Vector2.new(1, 0)
value.Position = UDim2.new(1, -14, 0, 28)
value.Size = UDim2.fromOffset(86, 16)
value.TextXAlignment = Enum.TextXAlignment.Right
value.ZIndex = T.OVERLAY_Z + 4
value.Parent = btn
end
f = { btn = btn, txt = txt, sub = sub, value = value, marker = marker,
pic = pic, text = nil, shown = true }
btn.MouseEnter:Connect(function()
if isSelected(f.text) then return end
R.set(btn, "BackgroundColor3", T.ACCENT_D)
R.set(btn, "BackgroundTransparency", 0.72)
R.set(txt, "TextColor3", T.TEXT)
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, { Color = T.ACCENT, Transparency = 0.5, Thickness = 1.1 }) end
end)
btn.MouseLeave:Connect(function()
if isSelected(f.text) then return end
R.set(btn, "BackgroundColor3", T.PANEL_2)
R.set(btn, "BackgroundTransparency", 0.22)
R.set(txt, "TextColor3", T.TEXT)
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, { Color = T.WHITE, Transparency = 0.94, Thickness = 1 }) end
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
R.set(f.txt, "TextColor3", T.TEXT)
if f.sub then R.set(f.sub, "TextColor3", T.ACCENT) end
if f.value then R.set(f.value, "TextColor3", Color3.fromRGB(82, 218, 133)) end
R.set(f.btn, "BackgroundTransparency", on and 0 or 0.22)
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
wantHeight = function()
local n = 0
for i = 1, #options do
local f = frames[i]
if not f or f.shown ~= false then n = n + 1 end
end
local shown = math.min(math.max(n, 1), MAX_SHOWN)
local base = shown * (OPT_H + 4) + 12
return base
end
search:GetPropertyChangedSignal("Text"):Connect(function()
query = tostring(search.Text):lower()
local n = applyFilter()
if open then
R.tween(panel, T.FADE, { Size = UDim2.new(1, -SHEET_MARGIN * 2, 0, sheetHeight()),
Position = sheetRest() })
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
layoutInner()
local hgt = sheetHeight()
R.set(panel, "Size", UDim2.new(1, -SHEET_MARGIN * 2, 0, hgt))
R.set(panel, "Position", UDim2.new(0, SHEET_MARGIN, 1, SHEET_MARGIN))
R.set(panel, "Visible", true)
W.scrim(true, function() h:setOpen(false) end)
R.tween(panel, T.MOVE, { Position = sheetRest() }, T.EASE_UI)
W.setOpenDropdown(h)
else
open = false
W.scrim(false)
R.tween(panel, T.FADE, { Position = UDim2.new(0, SHEET_MARGIN, 1, SHEET_MARGIN) }, T.EASE_UI)
R.call(function()
task.delay(T.FADE + 0.02, function()
if not open then R.set(panel, "Visible", false) end
end)
end)
W.clearOpenDropdown(h)
end
R.set(arrowHolder, "Rotation", on and 180 or 0)
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
local info
if meta then
local ok, got = pcall(meta, options[i])
if ok and type(got) == "table" then info = got end
end
R.set(f.txt, "Text", tostring(info and info.name or options[i]))
if f.sub then R.set(f.sub, "Text", tostring(info and info.rarity or "")) end
if f.value then R.set(f.value, "Text", tostring(info and info.value or "")) end
if f.pic then showIn(f.pic, options[i]) end
end
R.set(f.btn, "Visible", true)
end
for i = #options + 1, #frames do
frames[i].text = nil
if frames[i].pic then showIn(frames[i].pic, nil) end
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
R.set(search, "Visible", false)
layoutInner()
applyFilter()
R.set(chosen, "Text", chosenText())
paintPill(not multi and single or nil)
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
paintPill(not multi and single or nil)
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
local initialOption = opts.value
if initialOption == nil then initialOption = opts.currentOption end
if initialOption ~= nil then h:set(initialOption) end
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
PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
}),
mk("UIListLayout", {
Padding = UDim.new(0, 10),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local title = label(opts.name, opts.titleSize or T.SIZE_CARD_TITLE, T.CARD_TITLE, true)
title.Size = UDim2.new(1, 0, 0, 0)
title.AutomaticSize = Enum.AutomaticSize.Y
title.TextYAlignment = Enum.TextYAlignment.Top
title.LayoutOrder = 1
title.Parent = root
local body = label(tostring(opts.text or ""), opts.textSize or T.SIZE_DESC, T.MUTED, false)
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
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Size = UDim2.fromOffset(0, 40),
AutomaticSize = Enum.AutomaticSize.X,
LayoutOrder = 3,
Parent = root,
}, {
T.corner(20),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
}),
})
local ctaLabel = label(tostring(opts.action.label or "Open"), opts.action.textSize or 14,
T.PANEL, true)
ctaLabel.Size = UDim2.fromOffset(0, 40)
ctaLabel.AutomaticSize = Enum.AutomaticSize.X
ctaLabel.Parent = cta
cta.MouseEnter:Connect(function()
R.tween(cta, T.FADE, { BackgroundColor3 = Color3.fromRGB(232, 232, 236) })
end)
cta.MouseLeave:Connect(function()
R.tween(cta, T.FADE, { BackgroundColor3 = T.WHITE })
end)
cta.MouseButton1Down:Connect(function()
R.tween(cta, 0.08, { BackgroundColor3 = Color3.fromRGB(226, 226, 231) },
Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end)
cta.MouseButton1Up:Connect(function()
R.tween(cta, 0.14, { BackgroundColor3 = T.WHITE },
Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
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
local title = label(opts.name, opts.titleSize or T.SIZE_CARD_TITLE, T.TEXT, true)
title.Size = UDim2.new(1, -120, 1, 0)
title.Parent = head
if opts.badge then
local bl = label(string.upper(tostring(opts.badge)), opts.badgeSize or 10, T.MUTED, true)
bl.Name = "Badge"
bl.AnchorPoint = Vector2.new(1, 0.5)
bl.Position = UDim2.new(1, 0, 0.5, 0)
bl.Size = UDim2.fromOffset(0, 20)
bl.AutomaticSize = Enum.AutomaticSize.X
bl.TextXAlignment = Enum.TextXAlignment.Right
bl.Parent = head
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
local tag = label(string.upper(tostring(row[1])), opts.tagSize or 9, T.ROW_TAG, true)
tag.Position = UDim2.fromOffset(0, 0)
tag.Size = UDim2.new(0, 70, 0, 20)
tag.TextYAlignment = Enum.TextYAlignment.Top
tag.Parent = line
local body = label(tostring(row[2]), opts.rowTextSize or 12,
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
Position = UDim2.new(0, 80, 1, 0),
Size = UDim2.new(1, -80, 0, 1),
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
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, { Color = T.ACCENT, Transparency = 0.5, Thickness = 1.1 }) end
end)
btn.MouseLeave:Connect(function()
R.tween(btn, T.FADE, { BackgroundTransparency = 1 })
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, { Color = T.WHITE, Transparency = 0.94, Thickness = 1 }) end
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
local group, grouped = groupFor(parent)
if group then parent = group end
local root = mk("Frame", {
Name = "Row",
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
local SFX = BX.require("ui.sfx")
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
local windowScope = BX.scope("ui.lib.window")
local initialViewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
or Vector2.new(0, 0)
local narrow = true
local topTabs = false
local wantW = opts.width or (dev.isTouch and T.WIN_W_NARROW or T.WIN_W)
local wantH = opts.height or (dev.isTouch and T.WIN_H_NARROW or T.WIN_H)
local fitMargin = 64
if dev.isTouch then
wantW, wantH = T.fitTouchSize(wantW, wantH)
fitMargin = T.TOUCH_MARGIN
end
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
local sideW     = (narrow or topTabs) and 0 or T.SIDE_W
local sideGap   = narrow and 0 or T.SIDE_COL_GAP
local searchH   = 0
local searchGap = 0
local fullW = wantW
local fullH = wantH
local holder = mk("Frame", {
Name = "Holder",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(fullW, fullH),
BackgroundTransparency = 1,
Parent = gui,
})
local fit = T.fitScale(fullW, fullH, fitMargin)
local scale = mk("UIScale", { Scale = fit, Parent = holder })
local rootCorner = T.corner(T.RADIUS_WIN)
local root = mk("Frame", {
Name = "Window",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromScale(1, 1),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 0.18,
BorderSizePixel = 0,
Active = true,
ClipsDescendants = true,
Parent = holder,
}, {
rootCorner,
})
local shadow = T.shadow(root, T.SHADOW_BLUR, T.SHADOW_ALPHA)
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
Active = true,
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
if tostring(T.LOGO):find("95108798243406", 1, true) then
logo.Visible = false
local mark = mk("Frame", {
Name = "VectorLogo", AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, T.TITLEBAR_PAD_X, 0.5, 0),
Size = UDim2.fromOffset(T.LOGO_SIZE, T.LOGO_SIZE),
BackgroundTransparency = 1, Parent = bar,
})
local function ribbon(pos, size, rotation)
return mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
Size = size, Rotation = rotation,
BackgroundColor3 = T.ACCENT, BorderSizePixel = 0,
Parent = mark,
}, { T.corner(UDim.new(1, 0)) })
end
ribbon(UDim2.fromOffset(19, 13), UDim2.fromOffset(27, 9), -35)
ribbon(UDim2.fromOffset(21, 27), UDim2.fromOffset(27, 9), -35)
mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(20, 20),
Size = UDim2.fromOffset(10, 10), Rotation = 45,
BackgroundColor3 = T.ACCENT, BorderSizePixel = 0, Parent = mark,
})
end
local lockup = mk("Frame", {
Name = "Lockup",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, T.TITLEBAR_PAD_X + 38, 0.5, 0),
Size = UDim2.fromOffset(0, 40),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundTransparency = 1,
Visible = not topTabs,
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
FontFace = T.FONT_TITLE or T.FONT_BOLD,
TextSize = T.SIZE_TITLE,
TextColor3 = T.WHITE,
TextXAlignment = Enum.TextXAlignment.Left,
Size = UDim2.fromOffset(0, 22),
AutomaticSize = Enum.AutomaticSize.X,
Visible = false,
LayoutOrder = 1,
Parent = lockup,
}, {
T.gradient(T.WORDMARK_GLASS, T.GLASS_ROT),
mk("UIStroke", {
ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
Color = T.GLASS_EDGE,
Transparency = T.GLASS_EDGE_ALPHA,
Thickness = 0.6,
}),
})
BX.try("ui.lib.glass", function()
local g = title:FindFirstChildOfClass("UIGradient")
if not g then return end
g.Offset = Vector2.new(-0.6, 0)
R.call(function()
svc.TweenService:Create(g, TweenInfo.new(T.GLASS_SWEEP,
Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
{ Offset = Vector2.new(0.6, 0) }):Play()
end)
end)
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
Visible = opts.subtitle ~= nil and not topTabs,
LayoutOrder = 2,
Parent = lockup,
})
local badgePill = nil
if opts.badge then
local pill = mk("Frame", {
Name = "Badge",
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 0, 0.5, 0),
Size = UDim2.fromOffset(0, 32),
AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = T.ACCENT_D,
BackgroundTransparency = 0.16,
BorderSizePixel = 0,
Parent = bar,
}, {
T.corner(16),
T.stroke(T.ACCENT, 1, 0.28),
mk("UIPadding", {
PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13),
}),
})
mk("TextLabel", {
BackgroundTransparency = 1,
Text = tostring(opts.badge),
FontFace = T.FONT_TITLE or T.FONT_BOLD,
TextSize = T.SIZE_VERSION_TAG,
TextColor3 = T.WHITE,
Size = UDim2.fromOffset(0, 32),
AutomaticSize = Enum.AutomaticSize.X,
Parent = pill,
})
local function fitPill()
local x
if topTabs then
x = T.TITLEBAR_PAD_X + T.LOGO_SIZE + 4
else
x = T.TITLEBAR_PAD_X + 38 + lockup.AbsoluteSize.X + 12
end
R.set(pill, "Position", UDim2.new(0, x, 0.5, 0))
end
if not topTabs then lockup:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPill) end
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
local ctlButtons = {}
local function iconButton(order, draw, o)
o = o or {}
local b = mk("TextButton", {
Name = "Ctl" .. order,
Text = "",
AutoButtonColor = false,
BackgroundTransparency = 1,
Size = UDim2.fromOffset(24, 24),
LayoutOrder = order,
Parent = controls,
})
local disc = mk("Frame", {
Name = "Disc",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(22, 22),
BackgroundColor3 = o.tint or T.TEXT,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Parent = b,
}, { T.corner(6) })
local press = mk("UIScale", { Scale = 1, Parent = b })
local marks = draw(b)
local hover, held = false, false
local restWash = 0.92
local function paint()
local on = hover or held
R.tween(disc, T.FADE, { BackgroundTransparency = on and restWash or 1 })
for _, m in ipairs(marks) do
R.tween(m, T.FADE, { BackgroundColor3 = on and T.WHITE or T.MUTED })
if o.spin then
R.tween(m, 0.2, { Rotation = m:GetAttribute("rest") + (on and o.spin or 0) })
elseif o.widen then
R.tween(m, 0.2, { Size = UDim2.fromOffset(on and o.widen or 13, 1.6) })
end
end
end
for _, m in ipairs(marks) do m:SetAttribute("rest", m.Rotation) end
b.MouseEnter:Connect(function() hover = true paint() end)
b.MouseLeave:Connect(function() hover = false held = false paint()
R.tween(press, 0.22, { Scale = 1 }, Enum.EasingStyle.Back) end)
b.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
held = true
R.tween(press, 0.06, { Scale = 0.86 }, Enum.EasingStyle.Quad)
paint()
end)
b.InputEnded:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
held = false
R.tween(press, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
paint()
end)
ctlButtons[#ctlButtons + 1] = { button = b, disc = disc, marks = marks }
return b
end
local function fadeControls(on, t)
for _, c in ipairs(ctlButtons) do
for _, m in ipairs(c.marks) do
R.tween(m, t or 0.1, { BackgroundTransparency = on and 0 or 1 })
end
if not on then R.tween(c.disc, t or 0.1, { BackgroundTransparency = 1 }) end
end
end
local function barMark(parent, rot)
return mk("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(10, 1.4),
BackgroundColor3 = T.MUTED,
BorderSizePixel = 0,
Rotation = rot,
Parent = parent,
}, { T.corner(1) })
end
local minBtn = iconButton(1, function(b) return { barMark(b, 0) } end, { widen = 11 })
local closeBtn = iconButton(2, function(b)
return { barMark(b, 45), barMark(b, -45) }
end, {})
local capsuleSlot = mk("Frame", {
Name = "CapsuleSlot",
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, 2),
Size = UDim2.fromOffset(320, 46),
BackgroundTransparency = 1,
Parent = bar,
})
win.capsuleSlot = capsuleSlot
local railW = (narrow or topTabs) and 0 or sideW
local railH = narrow and T.TABBAR_H or 0
local function column(name, xOffset)
return mk("ScrollingFrame", {
Name = name,
Position = topTabs and UDim2.fromOffset(0, T.TITLEBAR_H)
or UDim2.fromOffset(xOffset, 0),
Size = topTabs
and UDim2.new(1, 0, 0, railH)
or UDim2.new(0, sideW, 1, -(searchH + searchGap)
- (opts.user and T.USER_CHIP_H or 0)),
BackgroundTransparency = 1,
BorderSizePixel = 0,
ScrollBarThickness = 0,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollingDirection = Enum.ScrollingDirection.Y,
Parent = root,
}, {
mk("UIListLayout", {
FillDirection = topTabs and Enum.FillDirection.Horizontal
or Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Center,
VerticalAlignment = topTabs and Enum.VerticalAlignment.Center
or Enum.VerticalAlignment.Top,
Padding = UDim.new(0, topTabs and T.TAB_GAP or T.SIDE_GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, topTabs and 0 or T.TITLEBAR_H + 10),
PaddingLeft = UDim.new(0, topTabs and 18 or 8),
PaddingRight = UDim.new(0, topTabs and 18 or 8),
}),
})
end
local rail, railRight
local topTabBed = nil
local tabIndicatorLayer = nil
local tabIndicator = nil
local sidebarFade = nil
if narrow or topTabs then
if topTabs then
topTabBed = mk("Frame", {
Name = "TabButtonContainer",
Position = UDim2.fromOffset(T.TITLEBAR_PAD_X + T.LOGO_SIZE + 4, 8),
Size = UDim2.fromOffset(8, 46),
BackgroundColor3 = T.BLACK,
BackgroundTransparency = 0.76,
BorderSizePixel = 0,
Parent = root,
}, { T.corner(12) })
end
rail = mk("ScrollingFrame", {
Name = "Tabs",
Position = topTabs and UDim2.fromOffset(T.TITLEBAR_PAD_X + T.LOGO_SIZE + 8, 8)
or UDim2.new(0, 0, 0, T.TITLEBAR_H + 1),
Size = topTabs and UDim2.new(1, -(T.TITLEBAR_PAD_X + T.LOGO_SIZE + 150), 0, 46)
or UDim2.new(1, 0, 0, railH),
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
VerticalAlignment = topTabs and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Center,
Padding = UDim.new(0, T.TAB_GAP),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
mk("UIPadding", {
PaddingTop = UDim.new(0, topTabs and 4 or 14),
PaddingLeft = UDim.new(0, topTabs and 0 or 14),
PaddingRight = UDim.new(0, topTabs and 0 or 14),
PaddingBottom = UDim.new(0, topTabs and 4 or 14),
}),
})
if topTabs and topTabBed then
local list = rail:FindFirstChildOfClass("UIListLayout")
local function fitTopTabBed()
if list then
R.set(topTabBed, "Size", UDim2.fromOffset(list.AbsoluteContentSize.X + 8, 46))
end
end
if list then
list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitTopTabBed)
end
fitTopTabBed()
end
tabIndicatorLayer = mk("Frame", {
Name = "ActiveTabIndicatorLayer",
Position = rail.Position,
Size = rail.Size,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Active = false,
ZIndex = 0,
Parent = root,
})
tabIndicator = mk("Frame", {
Name = "ActiveTabIndicator",
BackgroundColor3 = T.ACCENT,
BackgroundTransparency = 0.78,
BorderSizePixel = 0,
Size = UDim2.fromOffset(0, 0),
Visible = false,
Active = false,
ZIndex = 0,
Parent = tabIndicatorLayer,
}, { T.corner(10) })
elseif not topTabs then
local railBg = mk("Frame", {
Name = "RailBg",
Position = UDim2.fromOffset(0, 0),
Size = UDim2.new(0, sideW, 1, 0),
BackgroundColor3 = T.RAIL_BG,
BorderSizePixel = 0,
ZIndex = 0,
Parent = root,
}, { T.corner(T.RADIUS_WIN) })
for _, spec in ipairs({ { "SquareTR", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0) },
{ "SquareBR", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0) } }) do
mk("Frame", {
Name = spec[1], AnchorPoint = spec[2], Position = spec[3],
Size = UDim2.fromOffset(T.RADIUS_WIN, T.RADIUS_WIN),
BackgroundColor3 = T.RAIL_BG, BorderSizePixel = 0, ZIndex = 0,
Parent = railBg,
})
end
rail = column("TabsLeft", 0)
railRight = nil
end
if not narrow and not topTabs then
sidebarFade = mk("Frame", {
Name = "SidebarFade",
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 0, 1, 0),
Size = UDim2.new(0, sideW, 0, T.FADE_H),
BackgroundColor3 = T.WHITE,
BorderSizePixel = 0,
Active = false,
ZIndex = 6,
Parent = root,
}, {
T.corner(T.RADIUS_WIN),
T.gradient(ColorSequence.new(T.RAIL_BG, T.RAIL_BG), 90,
NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.35, 0.85),
NumberSequenceKeypoint.new(0.7, 0.35),
NumberSequenceKeypoint.new(1, 0),
}))
})
end
if not narrow then
mk("Frame", {
Name = "SidebarDivider",
Position = UDim2.fromOffset(railW, T.TITLEBAR_H),
Size = UDim2.new(0, 1, 1, -T.TITLEBAR_H),
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.93,
BorderSizePixel = 0,
ZIndex = 2,
Parent = root,
})
end
if opts.user then
local _ = nil
if opts.user then
local chip = mk("TextButton", {
Name = "UserChip",
Text = "",
AutoButtonColor = false,
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 16, 1, -16),
Size = UDim2.fromOffset(dev.isTouch and 216 or 236, T.USER_CHIP_H),
BackgroundColor3 = T.BLACK,
BackgroundTransparency = 0.18,
BorderSizePixel = 0,
Parent = root,
}, {
T.corner(T.USER_CHIP_RADIUS),
T.stroke(T.ACCENT, 1, 0.5),
})
chip.MouseEnter:Connect(function()
R.tween(chip, T.FADE, { BackgroundTransparency = 0.12 })
end)
chip.MouseLeave:Connect(function()
R.tween(chip, T.FADE, { BackgroundTransparency = 0.18 })
end)
win.userChip = chip
R.set(chip, "ZIndex", 4)
local CHIP_W = dev.isTouch and 216 or 236
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
T.stroke(T.ACCENT, 1, 0.35),
})
local realName = tostring(opts.user)
local realUser = tostring(opts.userTag or ("@" .. realName))
local masked = string.rep("*", math.max(#realName, 1))
local maskedUser = string.rep("*", math.max(#realUser, 1))
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
Size = UDim2.new(1, -(dev.isTouch and 100 or 92), 0, 18),
Parent = base,
})
local usernameLabel = mk("TextLabel", {
Name = "Username",
BackgroundTransparency = 1,
Text = maskedUser,
FontFace = T.FONT,
TextSize = 10,
TextColor3 = Color3.fromRGB(155, 149, 166),
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
Position = UDim2.new(0, 50, 0, 18),
Size = UDim2.new(1, -(dev.isTouch and 100 or 92), 0, 14),
Parent = base,
})
local eye = mk("TextButton", {
Name = "Reveal",
Text = "",
AutoButtonColor = false,
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -2, 0.5, 0),
Size = UDim2.fromOffset(dev.isTouch and 34 or 26, dev.isTouch and 34 or 26),
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
local eyeIcon = mk("ImageLabel", {
Name = "MaterialIcon",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(18, 18),
BackgroundTransparency = 1,
ImageTransparency = 0,
Parent = eye,
})
local eyeOnAsset, eyeOffAsset
local iconsBound = false
local function bindEyeIcons()
if iconsBound or not chip.Parent then return end
local st = BX._loaded["ui.stats"]
if not st or type(st.fetchIcon) ~= "function" then return end
iconsBound = true
st.fetchIcon("profile-eye-on", "action/2x_web/ic_visibility_white_48dp.png", function(asset)
eyeOnAsset = asset
R.set(eyeIcon, "Image", asset)
R.set(eyeIcon, "Visible", true)
R.set(ring, "Visible", false)
R.set(slash, "Visible", false)
end)
st.fetchIcon("profile-eye-off", "action/2x_web/ic_visibility_off_white_48dp.png", function(asset)
eyeOffAsset = asset
if not revealed then R.set(eyeIcon, "Image", asset) end
R.set(eyeIcon, "Visible", true)
R.set(ring, "Visible", false)
R.set(slash, "Visible", false)
end)
end
task.spawn(function()
for _ = 1, 40 do
if iconsBound or not chip.Parent then return end
bindEyeIcons()
if iconsBound then return end
task.wait(0.25)
end
end)
local privacySeq = 0
local function paintName()
privacySeq = privacySeq + 1
local seq = privacySeq
local nextName = revealed and realName or masked
local nextUser = revealed and realUser or maskedUser
local nextIcon = revealed and eyeOnAsset or eyeOffAsset
if nextIcon then
R.set(eyeIcon, "Image", nextIcon)
else
R.set(ring, "Visible", true)
R.set(slash, "Visible", not revealed)
end
R.tween(nameLabel, 0.11, { TextTransparency = 1 }, Enum.EasingStyle.Quad)
R.tween(usernameLabel, 0.11, { TextTransparency = 1 }, Enum.EasingStyle.Quad)
R.call(function()
task.delay(0.11, function()
if seq ~= privacySeq or not chip.Parent then return end
R.set(nameLabel, "Text", nextName)
R.set(usernameLabel, "Text", nextUser)
R.tween(nameLabel, 0.16, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
R.tween(usernameLabel, 0.16, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
end)
end)
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
Size = UDim2.fromOffset(CHIP_W, on and EXPANDED or COLLAPSED),
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
local contentInset = (narrow or topTabs) and 0 or railW
local body = mk("Frame", {
Name = "Body",
Position = UDim2.new(0, contentInset, 0, T.TITLEBAR_H + railH),
Size = UDim2.new(1, -contentInset,
1, -(T.TITLEBAR_H + railH + searchH + searchGap)),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 1,
BorderSizePixel = 0,
Parent = root,
}, { T.corner(T.RADIUS_WIN) })
if topTabs then
T.roundBottomOnly(body, T.RADIUS_WIN, T.PANEL)
elseif not narrow then
T.roundBottomRightOnly(body, T.RADIUS_WIN, T.PANEL)
end
do
local minW = narrow and T.WIN_MIN_W_NARROW or T.WIN_MIN_W
local minH = narrow and T.WIN_MIN_H_NARROW or T.WIN_MIN_H
local tile = dev.isTouch and 40 or 30
local grip = mk("TextButton", {
Name = "ResizeGrip",
AnchorPoint = Vector2.new(1, 1),
Position = UDim2.new(1, -8, 1, -8),
Size = UDim2.fromOffset(tile, tile),
BackgroundColor3 = T.ELEMENT,
BackgroundTransparency = 0.35,
Text = "",
AutoButtonColor = false,
ZIndex = 20,
Parent = root,
}, {
T.corner(T.RADIUS),
mk("UIStroke", { Color = T.CARD_EDGE, Transparency = 0.2, Thickness = 1 }),
})
local iconSize = dev.isTouch and 24 or 18
local ticks = {}
for i, len in ipairs({ 12, 6 }) do
ticks[i] = mk("Frame", {
AnchorPoint = Vector2.new(1, 1),
Position = UDim2.new(1, -8 - (i - 1) * 2, 1, -8 - (i - 1) * 2),
Size = UDim2.fromOffset(len, 1.5),
BackgroundColor3 = T.TEXT,
BackgroundTransparency = 0.3,
BorderSizePixel = 0,
Rotation = -45,
ZIndex = 21,
Parent = grip,
}, { T.corner(1) })
end
local gripIcon = mk("ImageLabel", {
Name = "Icon",
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(iconSize, iconSize),
BackgroundTransparency = 1,
ImageColor3 = T.TEXT,
ImageTransparency = 0.3,
ScaleType = Enum.ScaleType.Fit,
Visible = false,
ZIndex = 21,
Parent = grip,
})
BX.try("ui.lib.gripIcon", function()
local st = BX.require("ui.stats")
if not (st and type(st.fetchIcon) == "function") then return end
st.fetchIcon("resize", "maps/2x_web/ic_zoom_out_map_white_48dp.png", function(asset)
R.set(gripIcon, "Image", asset)
R.set(gripIcon, "Visible", true)
for _, t in ipairs(ticks) do R.set(t, "Visible", false) end
end)
end)
local function paint(on)
R.tween(grip, T.FADE, {
BackgroundColor3 = on and T.ACCENT or T.ELEMENT,
BackgroundTransparency = on and 0.15 or 0.35,
})
R.tween(gripIcon, T.FADE, { ImageTransparency = on and 0 or 0.3 })
for _, t in ipairs(ticks) do
R.tween(t, T.FADE, { BackgroundTransparency = on and 0 or 0.3 })
end
end
grip.MouseEnter:Connect(function() paint(true) end)
grip.MouseLeave:Connect(function() paint(false) end)
local NEAR = 140
local near = dev.isTouch
local function setNear(on)
if on == near then return end
near = on
R.tween(grip, 0.2, { BackgroundTransparency = on and 0.35 or 0.92 })
R.tween(gripIcon, 0.2, { ImageTransparency = on and 0.3 or 0.95 })
for _, t in ipairs(ticks) do
R.tween(t, 0.2, { BackgroundTransparency = on and 0.3 or 0.95 })
end
end
if not dev.isTouch then
grip.BackgroundTransparency = 0.92
gripIcon.ImageTransparency = 0.95
for _, t in ipairs(ticks) do t.BackgroundTransparency = 0.95 end
windowScope:connect(UIS.InputChanged, function(input)
if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
if not gui.Enabled then return end
local corner = grip.AbsolutePosition + grip.AbsoluteSize
local d = (Vector2.new(input.Position.X, input.Position.Y) - corner).Magnitude
setNear(d < NEAR)
end)
end
local resizing, startMouse, startSize, startPos = false, nil, nil, nil
local function maxSize()
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
local k = scale.Scale
return Vector2.new((vp.X - 32) / k, (vp.Y - 32) / k)
end
grip.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
resizing = true
startMouse = input.Position
startSize = Vector2.new(holder.Size.X.Offset, holder.Size.Y.Offset)
local c = holder.AbsolutePosition + holder.AbsoluteSize / 2 - gui.AbsolutePosition
startPos = c
paint(true)
end)
windowScope:connect(UIS.InputChanged, function(input)
if not resizing then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement
and input.UserInputType ~= Enum.UserInputType.Touch then return end
local k = scale.Scale
local d = (input.Position - startMouse) / k
local lim = maxSize()
local w = math.clamp(startSize.X + d.X, minW, math.max(minW, lim.X))
local h = math.clamp(startSize.Y + d.Y, minH, math.max(minH, lim.Y))
local cx = startPos.X + (w - startSize.X) * k / 2
local cy = startPos.Y + (h - startSize.Y) * k / 2
R.set(holder, "Size", UDim2.fromOffset(w, h))
R.set(holder, "Position", UDim2.fromOffset(cx, cy))
end)
windowScope:connect(UIS.InputEnded, function(input)
if not resizing then return end
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
resizing = false
paint(false)
R.call(function()
if win.rememberPosition then win.rememberPosition() end
if win.rememberSize then win.rememberSize() end
local prof = BX._loaded["core.profiles"]
if prof and prof.rememberWindowGeometry then
prof.rememberWindowGeometry()
end
end)
end)
end
local pageFade = mk("Frame", {
Name = "PageFade",
AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 0, 1, 0),
Size = UDim2.new(1, 0, 0, T.FADE_H),
BackgroundColor3 = T.WHITE,     
BorderSizePixel = 0,
Active = false,
ZIndex = 6,
Parent = body,
}, {
T.corner(T.RADIUS_WIN),
T.gradient(ColorSequence.new(T.WORKSPACE, T.WORKSPACE), 90,
NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.35, 0.85),
NumberSequenceKeypoint.new(0.7, 0.35),
NumberSequenceKeypoint.new(1, 0),
})),
})
if topTabs then
T.roundBottomOnly(pageFade, T.RADIUS_WIN, T.PANEL)
elseif not narrow then
T.roundBottomRightOnly(pageFade, T.RADIUS_WIN, T.PANEL)
end
local dragHandle = mk("Frame", {
Name = "DragHandle",
AnchorPoint = Vector2.new(0.5, 1),
Position = UDim2.new(0.5, 0, 1, 8),
Size = UDim2.fromOffset(86, 4),
BackgroundColor3 = T.MUTED,
BackgroundTransparency = 0.35,
BorderSizePixel = 0,
Active = true,
ZIndex = 18,
Parent = holder,
}, { T.corner(2) })
dragHandle.MouseEnter:Connect(function()
R.tween(dragHandle, T.FADE, {
BackgroundColor3 = T.ACCENT,
BackgroundTransparency = 0.05,
})
end)
dragHandle.MouseLeave:Connect(function()
R.tween(dragHandle, T.FADE, {
BackgroundColor3 = T.MUTED,
BackgroundTransparency = 0.35,
})
end)
do
local lift = mk("UIScale", { Scale = 1, Parent = root })
local dragging, startCenter, startMouse = false, nil, nil
local visualOffset = Vector2.zero
local target, pos, vel = nil, nil, Vector2.zero
local lastMouse, lastMouseAt, mouseVel = nil, 0, Vector2.zero
local bounds = nil
local function screenBounds()
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
local half = holder.AbsoluteSize / 2
local margin = 8
return {
minX = half.X + margin, maxX = vp.X - half.X - margin,
minY = half.Y + margin, maxY = vp.Y - half.Y - margin - 12,
}
end
local function band(v, lo, hi)
if v < lo then
local over = lo - v
return lo - math.min(over * T.EDGE_GIVE, T.EDGE_MAX)
elseif v > hi then
local over = v - hi
return hi + math.min(over * T.EDGE_GIVE, T.EDGE_MAX)
end
return v
end
local function setLift(on)
R.tween(lift, on and 0.08 or 0.32, { Scale = on and T.LIFT_SCALE or 1 },
on and Enum.EasingStyle.Quad or Enum.EasingStyle.Back)
if shadow then
R.tween(shadow, on and 0.08 or 0.25,
{ Transparency = on and T.LIFT_SHADOW or T.SHADOW_ALPHA })
end
end
local function grabbable(input)
local pg = svc.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
if not pg then return true end
local ok, objs = pcall(pg.GetGuiObjectsAtPosition, pg, input.Position.X, input.Position.Y)
if not ok or type(objs) ~= "table" then return true end
local ours = false
for _, o in ipairs(objs) do
if not o:IsDescendantOf(holder) then continue end
ours = true
if o:IsA("GuiButton") or o:IsA("TextBox") then return false end
if o:IsA("ScrollingFrame") and o ~= rail then return false end
if o:IsDescendantOf(controls) then return false end
if o ~= overlay and o:IsDescendantOf(overlay) then return false end
end
if ours then return true end
local p, sz = bar.AbsolutePosition, bar.AbsoluteSize
return input.Position.X >= p.X and input.Position.X <= p.X + sz.X
and input.Position.Y >= p.Y and input.Position.Y <= p.Y + sz.Y
end
local function beginDrag(input, fromHandle)
if dragging then return end
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
if not fromHandle and not grabbable(input) then return end
dragging = true
local holderCenter = holder.AbsolutePosition + holder.AbsoluteSize / 2
local visualCenter = root.AbsolutePosition + root.AbsoluteSize / 2
visualOffset = visualCenter - holderCenter
startCenter = visualCenter
startMouse = input.Position
lastMouse, lastMouseAt, mouseVel = input.Position, os.clock(), Vector2.zero
bounds = screenBounds()
pos = visualCenter - visualOffset - gui.AbsolutePosition
vel = Vector2.zero
target = pos
setLift(true)
end
root.InputBegan:Connect(function(input) beginDrag(input, false) end)
bar.InputBegan:Connect(function(input) beginDrag(input, false) end)
dragHandle.InputBegan:Connect(function(input) beginDrag(input, true) end)
windowScope:connect(UIS.InputChanged, function(input)
if not dragging then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement
and input.UserInputType ~= Enum.UserInputType.Touch then return end
local now = os.clock()
local dt = now - lastMouseAt
if dt > 0 then
local v = (input.Position - lastMouse) / dt
mouseVel = mouseVel:Lerp(Vector2.new(v.X, v.Y), 0.5)
end
lastMouse, lastMouseAt = input.Position, now
local d = input.Position - startMouse
local x = band(startCenter.X + d.X, bounds.minX, bounds.maxX)
local y = band(startCenter.Y + d.Y, bounds.minY, bounds.maxY)
target = Vector2.new(x, y) - visualOffset - gui.AbsolutePosition
end)
windowScope:onFrame("drag", svc.RunService.RenderStepped, function(dt)
if not target or not pos then return end
dt = math.min(dt, 1 / 30)
local a = (target - pos) * T.DRAG_K - vel * T.DRAG_C
vel = vel + a * dt
pos = pos + vel * dt
holder.Position = UDim2.fromOffset(pos.X, pos.Y)
if not dragging and (target - pos).Magnitude < 0.3 and vel.Magnitude < 4 then
holder.Position = UDim2.fromOffset(target.X, target.Y)
target, pos = nil, nil
if win.rememberPosition then win.rememberPosition() end
end
end)
windowScope:connect(UIS.InputEnded, function(input)
if not dragging then return end
if input.UserInputType ~= Enum.UserInputType.MouseButton1
and input.UserInputType ~= Enum.UserInputType.Touch then return end
dragging = false
setLift(false)
if os.clock() - lastMouseAt > 0.08 then mouseVel = Vector2.zero end
local origin = gui.AbsolutePosition
local rest = (target or pos) + visualOffset + origin + mouseVel * T.THROW
rest = Vector2.new(
math.clamp(rest.X, bounds.minX, bounds.maxX),
math.clamp(rest.Y, bounds.minY, bounds.maxY))
target = rest - visualOffset - origin
end)
end
win.gui, win.root, win.overlay, win.scale = gui, root, overlay, scale
win.notify = function(_, title, body, o)
if type(_) == "string" then return M.notify(_, title, body) end
return M.notify(title, body, o)
end
local tabs, order, current = {}, 0, nil
local tabIndicatorTween = nil
local tabListeners = {}
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
self:minimise()
else
self:restore()
end
end
function win:destroy()
if not pcall(function() gui:Destroy() end) then
R.call(function() gui:Destroy() end)
end
end
minBtn.Activated:Connect(function()
win:minimise()
end)
closeBtn.Activated:Connect(function()
if opts.onClose then
task.spawn(function() BX.try("ui.window.close", opts.onClose) end)
else
win:minimise()
end
end)
local function moveTabIndicator(button, instant)
if not tabIndicator or not button or not button.Parent or not (narrow or topTabs) then return end
local ok, x, y, w, h = pcall(function()
local railPos = tabIndicatorLayer.AbsolutePosition
local buttonPos = button.AbsolutePosition
return buttonPos.X - railPos.X,
buttonPos.Y - railPos.Y,
button.AbsoluteSize.X,
button.AbsoluteSize.Y
end)
if not ok then return end
tabIndicator.Visible = true
local position = UDim2.fromOffset(x, y)
local size = UDim2.fromOffset(w, h)
if instant then
R.set(tabIndicator, "Position", position)
R.set(tabIndicator, "Size", size)
else
R.call(function()
if tabIndicatorTween then
pcall(function() tabIndicatorTween:Cancel() end)
end
local info = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
tabIndicatorTween = svc.TweenService:Create(tabIndicator, info, {
Position = position,
Size = size,
})
tabIndicatorTween:Play()
end)
end
end
local function selectTab(name)
if current == name then return end
local previous = current
current = name
BX.try("ui.lib.closeDropdownOnTabChange", W.closeOpenDropdown, nil)
if type(win.clearSearch) == "function" then
BX.try("ui.lib.clearSearch", win.clearSearch)
end
for n, t in pairs(tabs) do
local on = (n == name)
if n ~= name and n ~= previous and not t.wrap.Visible then continue end
if on then
R.set(t.wrap, "Position", UDim2.fromOffset(0, 0))
R.set(t.wrap, "Visible", true)
if name == "Farm" and t.page then
R.set(t.page, "CanvasPosition", Vector2.zero)
end
elseif t.wrap.Visible then
R.set(t.wrap, "Visible", false)
R.set(t.wrap, "Position", UDim2.fromOffset(0, 0))
end
local tabEdge = t.button:FindFirstChildOfClass("UIStroke")
if narrow or topTabs then
R.tween(t.button, T.TAB_FADE, {
BackgroundColor3 = topTabs and T.ACCENT or T.WHITE,
BackgroundTransparency = 1,
})
R.tween(t.label, T.TAB_FADE, { TextColor3 = on and T.TAB_ON or T.TAB_OFF })
if tabEdge then
R.tween(tabEdge, T.TAB_FADE, { Transparency = 1 })
end
else
R.tween(t.button, T.TAB_FADE, {
BackgroundColor3 = T.TAB_WASH,
BackgroundTransparency = on and T.TAB_WASH_ON or 1,
})
R.tween(t.label, T.TAB_FADE, { TextColor3 = on and T.TAB_ON or T.TAB_OFF })
if t.icon then R.tween(t.icon, T.FADE, { ImageColor3 = on and T.TAB_ON or T.TAB_OFF }) end
if t.accent then R.set(t.accent, "Visible", on) end
if tabEdge then
R.tween(tabEdge, T.FADE, {
Color = on and T.SIDE_EDGE_ON or T.SIDE_EDGE,
Transparency = 1,
Thickness = 1,
})
end
end
end
local selected = tabs[name]
if selected and selected.button then
moveTabIndicator(selected.button, previous == nil)
local selectedEdge = selected.button:FindFirstChildOfClass("UIStroke")
if selectedEdge then
if previous == nil then
R.tween(selectedEdge, T.TAB_FADE, { Transparency = 0 })
else
R.call(function()
local move = tabIndicatorTween
if not move then return end
move.Completed:Connect(function()
if current == name then
R.set(selectedEdge, "Transparency", 0)
end
end)
end)
end
end
end
local listener = tabListeners[name]
if listener then
R.call(function()
BX.try("ui.lazyTab." .. tostring(name), listener, name)
end)
end
end
win.select = function(_, name) selectTab(name) end
function win:selected() return current end
function win:onSelect(name, fn)
if type(name) ~= "string" or type(fn) ~= "function" then return false end
tabListeners[name] = fn
return true
end
if false then
local quickRail = mk("Frame", {
Name = "QuickActionRail",
AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -12, 0.5, 0),
Size = UDim2.fromOffset(74, 286),
BackgroundColor3 = T.PANEL,
BackgroundTransparency = 0.02,
BorderSizePixel = 0,
ZIndex = 100,
Parent = root,
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
end
function win:tab(name)
if tabs[name] then return tabs[name].api end
order = order + 1
local side = (opts.tabSide and opts.tabSide[name]) or "left"
local host = (not narrow and not topTabs and side == "right" and railRight) or rail
local topTabWidth = math.clamp(28 + #tostring(name) * 9, 72, 102)
local narrowTabWidth = math.clamp(math.floor((wantW - 28 - T.TAB_GAP * 5) / 6), 80, 132)
local btn = mk("TextButton", {
Name = "Tab_" .. name,
Text = "",
AutoButtonColor = false,
BackgroundColor3 = (narrow or topTabs) and T.ELEMENT or T.TAB_WASH,
BackgroundTransparency = 1,
BorderSizePixel = 0,
LayoutOrder = order,
Size = (narrow or topTabs) and UDim2.fromOffset(topTabs and topTabWidth or narrowTabWidth, topTabs and 38 or railH - 14)
or UDim2.new(1, -16, 0, T.SIDE_BTN_H),
Parent = host,
}, topTabs and {
T.corner(10),
} or narrow and {
T.corner(T.RADIUS_TAB),
T.gradient(T.TAB_ACTIVE, T.TAB_ACTIVE_ROT),
T.stroke(T.TAB_EDGE, 1, 1),
} or { T.corner(T.SIDE_RADIUS), T.stroke(T.SIDE_EDGE, 1, 1) })
local lbl = mk("TextLabel", {
BackgroundTransparency = 1,
Text = name,
FontFace = T.FONT,
TextSize = (narrow or topTabs) and T.SIZE_TAB or T.SIDE_TEXT_SIZE,
TextColor3 = T.TAB_OFF,
TextXAlignment = Enum.TextXAlignment.Center,
Position = UDim2.fromOffset(0, 0),
Size = UDim2.fromScale(1, 1),
Parent = btn,
})
local accent = nil
if false and not narrow then
accent = mk("Frame", {
Name = "ActiveAccent",
Position = UDim2.fromOffset(0, 7),
Size = UDim2.new(0, 2, 1, -14),
BackgroundColor3 = T.ACCENT,
BackgroundTransparency = 0,
BorderSizePixel = 0,
Visible = false,
ZIndex = 2,
Parent = btn,
}, { T.corner(1) })
end
if topTabs then
btn.MouseEnter:Connect(function()
SFX.hover()
if current == name then
R.tween(btn, T.FADE, { BackgroundTransparency = 1 })
else
R.tween(btn, T.FADE, {
BackgroundColor3 = T.WHITE,
BackgroundTransparency = 0.90,
})
R.tween(lbl, T.FADE, { TextColor3 = T.TAB_ON })
end
end)
btn.MouseLeave:Connect(function()
if current == name then
R.tween(btn, T.FADE, {
BackgroundColor3 = T.ACCENT,
BackgroundTransparency = 1,
})
else
R.tween(btn, T.FADE, { BackgroundTransparency = 1 })
R.tween(lbl, T.FADE, { TextColor3 = T.TAB_OFF })
end
end)
elseif not narrow then
btn.MouseEnter:Connect(function()
SFX.hover()
R.tween(btn, T.FADE, {
BackgroundColor3 = T.TAB_WASH,
BackgroundTransparency = current == name and T.TAB_WASH_ON or T.TAB_WASH_HOV,
})
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, { Color = T.ACCENT, Transparency = 0.5, Thickness = 1.1 }) end
if current ~= name then
R.tween(lbl, T.FADE, { TextColor3 = T.TAB_ON })
end
end)
btn.MouseLeave:Connect(function()
R.tween(btn, T.FADE, {
BackgroundTransparency = current == name and T.TAB_WASH_ON or 1,
})
local edge = btn:FindFirstChildOfClass("UIStroke")
if edge then R.tween(edge, T.FADE, {
Color = current == name and T.SIDE_EDGE_ON or T.SIDE_EDGE,
Transparency = 1,
Thickness = 1,
}) end
if current ~= name then
R.tween(lbl, T.FADE, { TextColor3 = T.TAB_OFF })
end
end)
end
local wrap = mk("Frame", {
Name = "Page_" .. name,
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
Visible = false,
Parent = body,
})
local page = mk("ScrollingFrame", {
Name = "Scroll",
Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1,
BorderSizePixel = 0,
Active = true,
ScrollingEnabled = true,
ScrollBarThickness = 0,
ScrollBarImageColor3 = T.LINE,
ScrollBarImageTransparency = 0.15,
CanvasSize = UDim2.new(),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollingDirection = Enum.ScrollingDirection.Y,
ElasticBehavior = Enum.ElasticBehavior.Always,
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
PaddingBottom = UDim.new(0, 96),
}),
})
local head = mk("Frame", {
Name = "PageHeader",
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 0),
LayoutOrder = 0,
Visible = false,
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
Size = UDim2.new(1, -4, 0, 32),
Parent = head,
})
local lastTabActivation = 0
local function activateTab()
local now = os.clock()
if now - lastTabActivation < 0.08 then return end
lastTabActivation = now
selectTab(name)
end
btn.Activated:Connect(activateTab)
btn.MouseButton1Click:Connect(activateTab)
btn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
activateTab()
end
end)
local n = 0
local function nextOrder() n = n + 1 return n end
local api = { name = name, page = page }
function api:section(o) o = o or {} o.order = nextOrder() return W.section(page, o) end
function api:subnav(o) o = o or {} o.order = nextOrder() return W.subnav(page, o) end
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
if lbl then
R.set(lbl, "Text", tostring(text))
R.set(head, "Visible", true)
R.set(head, "Size", UDim2.new(1, 0, 0, T.PAGE_HEADER_H))
end
end
function api:scrollTo(sectionName)
local target
for _, child in ipairs(page:GetChildren()) do
if child:IsA("Frame") and child.Name == "Section" then
local label = child:FindFirstChild("Head")
and child.Head:FindFirstChild("Label")
if label and label.Text == string.upper(tostring(sectionName)) then
target = child
break
end
end
end
if target then
local y = target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 4
page.CanvasPosition = Vector2.new(0, math.max(0, y))
end
end
function api:select()   selectTab(name) end
tabs[name] = { api = api, button = btn, label = lbl, accent = accent, page = page,
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
if false and not narrow then
searchRow = mk("Frame", {
Name = "SearchRow",
Position = UDim2.new(0, contentInset, 1, -(searchH + 8)),
Size = UDim2.new(1, -contentInset, 0, searchH),
BackgroundColor3 = T.SEARCH_BG,
BorderSizePixel = 0,
Parent = root,
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
local nodes = {}
for _, node in ipairs(scroll:GetChildren()) do
if node:IsA("GuiObject") and node.Name ~= "PageHeader" then
if node.Name:match("^Section") then
local label = node:FindFirstChild("Label", true)
if label then R.set(label, "Visible", query == "") end
local group = node:FindFirstChild("Group")
if group then
for _, row in ipairs(group:GetChildren()) do
if row:IsA("GuiObject") then nodes[#nodes + 1] = row end
end
end
else
nodes[#nodes + 1] = node
end
end
end
for _, node in ipairs(nodes) do
do
if query == "" then
R.set(node, "Visible", true)
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
addChrome(sidebarFade)
addChrome(dragHandle)
addChrome(searchRow)  addChrome(win.userChip)
local function setChrome(on)
for _, o in ipairs(chrome) do
R.set(o, "Visible", on and true or false)
end
end
local restPos = UDim2.fromScale(0.5, 0.5)
local restSize = UDim2.fromOffset(fullW, fullH)
win.rememberPosition = function() restPos = holder.Position end
win.rememberSize = function() restSize = holder.Size end
local LAYOUT = "strip-1"
function win:getGeometry()
return {
w = math.floor(holder.Size.X.Offset + 0.5),
h = math.floor(holder.Size.Y.Offset + 0.5),
layout = LAYOUT,
}
end
function win:setGeometry(geometry)
if type(geometry) ~= "table" then return false end
if geometry.layout ~= LAYOUT then return false end
if dev.isTouch then return self:fitForDevice() end
local w, h = tonumber(geometry.w), tonumber(geometry.h)
if not w or not h then return false end
local minW = narrow and T.WIN_MIN_W_NARROW or T.WIN_MIN_W
local minH = narrow and T.WIN_MIN_H_NARROW or T.WIN_MIN_H
w = math.clamp(math.floor(w + 0.5), minW, 2400)
h = math.clamp(math.floor(h + 0.5), minH, 1600)
R.set(holder, "Size", UDim2.fromOffset(w, h))
R.set(scale, "Scale", T.fitScale(w, h, fitMargin))
win.rememberSize()
return true
end
function win:fitForDevice()
if not dev.isTouch then return false end
R.set(holder, "Size", UDim2.fromOffset(fullW, fullH))
R.set(holder, "Position", UDim2.fromScale(0.5, 0.5))
R.set(scale, "Scale", T.fitScale(fullW, fullH, fitMargin))
win.rememberSize()
win.rememberPosition()
return true
end
BX.try("ui.lib.viewport", function()
local cam = workspace.CurrentCamera
if not cam then return end
windowScope:connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
task.defer(function()
if not gui.Parent then return end
local w, h = holder.Size.X.Offset, holder.Size.Y.Offset
if dev.isTouch then
w, h = T.fitTouchSize(narrow and T.WIN_W_NARROW or T.WIN_W,
narrow and T.WIN_H_NARROW or T.WIN_H)
R.set(holder, "Size", UDim2.fromOffset(w, h))
end
local k = T.fitScale(w, h, fitMargin)
R.set(scale, "Scale", k)
local vp = cam.ViewportSize
local half = Vector2.new(w * k / 2, h * k / 2)
local p = holder.Position
local cx = p.X.Scale * vp.X + p.X.Offset
local cy = p.Y.Scale * vp.Y + p.Y.Offset
cx = math.clamp(cx, half.X + 8, math.max(half.X + 8, vp.X - half.X - 8))
cy = math.clamp(cy, half.Y + 8, math.max(half.Y + 8, vp.Y - half.Y - 20))
R.set(holder, "Position", UDim2.fromOffset(cx, cy))
win.rememberPosition()
end)
end)
end)
local function rectOf(inst)
if not (inst and inst.Parent) then return nil end
local ok, p, sz = pcall(function()
return inst.AbsolutePosition, inst.AbsoluteSize
end)
if not ok or not p or sz.X < 1 then return nil end
local origin = gui.AbsolutePosition
return {
centre = UDim2.fromOffset(p.X - origin.X + sz.X / 2, p.Y - origin.Y + sz.Y / 2),
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
local morphing = false
local morphSeq = 0     
function win:isMinimised() return minimised end
function win:isMorphing() return morphing end
local function launcher()
if not launcherFn then return nil end
local ok, inst = pcall(launcherFn)
return ok and inst or nil
end
local function bumpLauncher(strength)
R.call(function()
local st = BX._loaded["ui.stats"]
if st and type(st.bump) == "function" then pcall(st.bump, strength) end
end)
end
function win:minimise()
if morphing or minimised or not visible then return false end
local rect = rectOf(launcher())
if not rect then
return false
end
if opts.onMinimising then
BX.try("ui.window.minimising", opts.onMinimising)
end
minimised = true
morphing = true
win.rememberSize()
win.rememberPosition()
R.call(function()
local prof = BX._loaded["core.profiles"]
if prof and prof.rememberWindowGeometry then
prof.rememberWindowGeometry()
end
end)
morphSeq = morphSeq + 1
local seq = morphSeq
W.closeOpenDropdown(nil)
fadeControls(false, 0.1)
R.call(function()
task.delay(T.MORPH_CHROME * 0.5, function()
if minimised and seq == morphSeq then setChrome(false) end
end)
end)
R.tween(holder, T.MORPH_IN, { Position = rect.centre, Size = rect.size },
T.EASE_WINDOW)
R.tween(rootCorner, T.MORPH_IN, { CornerRadius = UDim.new(1, 0) },
T.EASE_WINDOW)
R.tween(dim, T.MORPH_IN * 0.7, { BackgroundTransparency = 1 })
R.call(function()
task.delay(T.MORPH_IN + 0.02, function()
if minimised and seq == morphSeq then
R.set(gui, "Enabled", false)
visible = false
morphing = false
if opts.onMinimised then
task.spawn(function() BX.try("ui.window.minimised", opts.onMinimised) end)
end
end
end)
end)
return true
end
function win:restore()
if morphing then return false end
if not minimised then
self:setVisible(true)
return false
end
minimised = false
morphing = true
local rect = rectOf(launcher())
if not rect then
minimised = false
morphing = false
self:setVisible(true)
return false
end
morphSeq = morphSeq + 1
local seq = morphSeq
R.set(holder, "Position", rect.centre)
R.set(holder, "Size", rect.size)
R.set(rootCorner, "CornerRadius", UDim.new(1, 0))
setChrome(false)
R.set(gui, "Enabled", true)
visible = true
R.flush()
if opts.onRestored then
task.spawn(function() BX.try("ui.window.restored", opts.onRestored) end)
end
R.tween(holder, T.MORPH_OUT, { Position = restPos, Size = restSize },
T.EASE_WINDOW)
R.tween(rootCorner, T.MORPH_OUT, { CornerRadius = UDim.new(0, T.RADIUS_WIN) },
T.EASE_WINDOW)
R.tween(dim, T.MORPH_OUT * 0.8, { BackgroundTransparency = T.DIM_ALPHA })
R.call(function()
task.delay(T.MORPH_OUT * 0.55, function()
if not minimised and seq == morphSeq then
setChrome(true)
fadeControls(true, 0.15)
end
end)
task.delay(T.MORPH_OUT + 0.03, function()
if not minimised and seq == morphSeq then morphing = false end
end)
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
log.info("window built (%dx%d at scale %.2f, %s)", wantW, wantH, fit,
dev.isTouch and "touch, cut to screen" or "desktop")
return win
end
return M
end)
BX.module("ui.sfx", function(BX)
local M = {}
local sound
local function ensure()
if sound and sound.Parent then return sound end
local ok, result = pcall(function()
local s = Instance.new("Sound")
s.Name = "BlyxoHover"
s.SoundId = "rbxassetid://139800881181209"
s.Volume = 2
s.Parent = game:GetService("SoundService")
task.spawn(function()
pcall(function()
game:GetService("ContentProvider"):PreloadAsync({ s })
end)
end)
return s
end)
sound = ok and result or nil
return sound
end
function M.hover()
local s = ensure()
if not s then return false end
return pcall(function()
s.TimePosition = 0
game:GetService("SoundService"):PlayLocalSound(s)
end)
end
function M.stop()
if sound then pcall(function() sound:Destroy() end) end
sound = nil
end
BX.onTeardown("ui.sfx", M.stop)
return M
end)
BX.module("ui.logodata", function(BX)
return {
name = "logo-33f70fd5.png",
b64 = "iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAAA6FUlEQVR42u1dd5xbxfGf2X3q7fqdG9hgwC00UwyYnA2EOBB+EEAHIUAoCZ3QCQFinUxLQjAtxKb/4AchnEICpoQaW0DAQIBQfGCasbHv7OtFXW93fn9IOrUn3Z1J4Gzv+PNO7UmW9u3sfmfmOzMASpQoUaJEiRIlSpQoUaJEiRIlSpQoUaJEiRIlSpQoUaJEiRIlSpQoUaJEiRIlSpQoUaJEiRIlSpQoUaJEiRIlSpR8c+Lz+ViLt4WrkVCyzUnBxEc1Ikq2FcGWFuIAAOccetPUG05YtmjGDJ9ZDYuSrV68Oau+z/vXpqVnf9B14ymvrQEAQFSbwEiEqSHYQvF+43ItEGgSU6sWuH930vI766t3fjQpnNXhsOhSozNy0dQQbHmGLkAz+P2oX3rE/QeMq9nlToetbmZX30CSJGoATF1TpQBbr6Hb5G8SAH645sfPXOF21C8itJvauvt0XRC3mRGlkGqglAJslYYua2pCcercG3aYNmXOErdr/KE9gyGKRAclAtMQSBKpgVI2wFYHeYghIjU1objsfx72zpo6f6XDPv7Qjd39IhwRAIAMgAAIUjdqA1A7wNZk6Pr9qAOMs1/34/tvcLvG/SKaIGjv6hUEjCNAdu5n/qhtQCnAli+ELS3AmppQP+/Q23bbrmG3e5z2hr26+/tkNC4RkXEGlI53ZSY85dxXoiAQbMm+/RTkufKowFlTxu/9mtlcs1dbd68eiQMDYEgEIAlAEgERDS38Q7uAErUDbLGQJzBfP3jaSdXzdj/hDxXuSccPRGIQ6u8XhExDoKI1nnLukcHrSpQCjP2JDz7WTM2EiPr5C+5onFT3nbut1tqdOvv7RDwuGSLjQNnJjTl/U0AoZydQw6kgEGxRvn3ifvBLRCS/d9kVk8fNfgmZe6f2rh49ESeOyMpyGhThQe0AW6qgz7ecN/lRP+mAX243bbuD73Q7JyzoGRykSHRQAnIt5eUpXtMJELBwrVdeILUDbEl0BkQkv3++fulhDxw5a8cjVtrt4xe09/TpoYgOAIzBkIGbb+SmDgJJNGQIZ28JJKhAgNoBxrxvf74OABa/d9l1Lue4S2JJhI1dvUISaoiQNmWxyNTFIuBT6AIlUPNfKQCMWd++F1hTAPWzv3vz9IkTd73XaW/Yr6u/T0ZjAhCRA1AawWCBTx9L+n4yr1N6J1B+IAWBYMz69gMorjoq8NMp2+/9usVcs197V48ejQmGAGnIU4Dlcx5j+jkqeQAoN5DaAcYg3k9Bnv2r/8f1/YPOuNXjmnDqQCQOg319ggC1Yl8+FMEfA5PXYEdQa79SgLEEeIAQfIDoR/3s+bfuv/243e60WKtndfb1ilhCMgTGjX2Yxdh/JGAodSsVHUIpwNiAPBhAAX6gq4/66wVOZ92NBDbThq5uXQrQENMxXTKa/FTW508lzshAIUmoNEApwLcPeX606yV1u007ZKnbMe5HvaEQhCL9EoFpgIVgBQ3W8/JGLxmoCgGl13+hLoJSgG+bznDnoeOqdrnTYq6cvKmnRySSxBCR5c/lFLY3nvRUYgdI7RyYPjvPNiAAlooRqB0AlBcIvulUxTSdAX591OMLJ9TMelaQffKGrm49ngQOAJiCKHIIqkBOUCt7m/Xo5Aa3ss8Zv557CNIVO0LtAPDN0Rkal/OmwHzdu89VU2Ztf+BdTkfDIV0D/RSJxiSAEYNziL427IpfZFZnvf7F70rrlSBLGABg4ULJ/H5UYTG1A/yX6QzB+fpFP7j/mN12/N5Kq7XukPbubj0c1TGTqpgTo807SjszR/684WcQS6iro3aAb4zOcNVRf7vB42q4KBIn6OrrFkRMQ8w1VYuNW8wjO1CR0ZvB+eW8/oV2AwEBIkBCj6hFTSkA/NfpDKfOvW7G9uP3vs9pq923o69PxmJJRGR8KEk3x0TNn+yZ14q9+OXBO5ZVBSACBgyAEl8BAMxsVUxpBYHgv0NnuPSwh06ZOvGA101a5b4burr0aExngAzzYQ6BTB+59yVA3vOF5xU/zn5e2X+YtqyR3gcAWNWxQimA2gH+s6mKjbVe54HfPekWl73h9MFIDAZCPYIyldiIRpiqQkX+/FKcTyqzO1BeXhgAIvKkGISu3i9fBgBorfujcoeOxIuhhqA85KEUnUGeMe/mfSfUzrrHaq2e1dnbI2IJwcqXoMURXgDM8fFgjtWAOZO/OF6QZ2EQCYfNxcKxjf+6/fkj9/X5fOj3+5UHSEGgrw950I/yssMfvmBSwx5BYK5ZG7o69GhccIDM3C92SQ7vtSFD52au18jIBUp5lkOWAMc4EmeE0UT3dQBAM1ub1cKmdoCvCXmC8/Ufzj6jZs/tj7zD4aht6hkMwWA4LhEZw6LoLRbwdSgvcpu6zwx8/gj56S9owAnCItiUu1MASr3SUa31Dn751O0vHHOEz0fK/69sgM2nM4AvVXn57IP/eMi46p2WmkyVO27s6dbjCckxx7ePZXB98eqee9/IPVrI7yEDsFMcTgMi4bY7tViiu31t18ozfT5i4G9WF1LtALB5lZcDTQIA4PIjHv21y17fnBSc9QyEdCFTDM7RovuveymwhMELACBJSo/DwRgmI21dqw66/9Xz3lCrv9oBvhad4cjdzpz8nR2PXOK01S7oGuijcDQiIZO0YsgxG97TMxzF2fgcNNxXch6LSreTI8VjX3V+cMwDr17wRqp0OioqqNoBRkdnWLRokSQiuPD79x1Z6Zm4lDNPQ0dfj55MSl6+zxCOwsdTaOzmg6Dye0v2fEkAnJNe66nUhAh1tnV9fMw9L5/zSsZmUdNZKcCoDV0AMF12RMtvPI5xF0cTAnr7Q0ICcixA4miA/MsP6cjOLz35sTDhhawWTdZVVvNIdNO/v2x784T/e2PhR2ryKwUYfbMJL7GmAIqT9l00fceJ+9xlsVTN3dTXK6OxBCIwpPTsH9n0pRKT3ojnj3leogJ/TrFKIKbjayTcDht3OywwEGm79/F//uqi1d2rB73eFh5I2y1KlALASHz7gcBxAoDgksMeOsllb7gN0FbR2denJ3XSEMunqKAhZCk16Y2yvkorBxakyWTsDsZBr62o1BhF+7sHvjjvthdOfwgBYaFvIVPBLqUAo4Y8M2obnf+z3y9ucdobTh8IR2EgFB2CPCM3UGkUQ0c5+VvGrxjBHyJJFrMm6yureDTe9daXm94+7aHXr/qwxUu8KYAq+115gWC0dAb91Lk37jux7jt3WcwVu3b09ohoPMkQGceSObfZv6XqMORTGUYS+cWc/YCKgmFpf49wOa28wmHj4ej6JdcvO+piAIj5GpdrTQFUeB8UFWLUdIaLFjxw4fYNe6yQZN91fWeHHonpHCEFsgtrbwLltxwqV4wqP22R8up3FtbzNEp9zE2RlJIAkfS6Sg93WGiws+fjU69fdtQ5iBjz+XxMGbsKAo3a0P3RrmfVTZ/y/Tvs1vpjewYHIBRJCALg5avtgKHhikWsTTIANqMZaszz8lhMXNZXVfN4ouedrt6Pf7o0eKGCPAoCbXZ1BnHWQX/8Qa1nyhJN82zf1tOtJxKCpwpS0RB7GUuWnqKi/CwDMkJeLTcyMKGxZHAMIPU9EAikdNmtrMrl5OFo2z0PPHn2Be3QHlGQR+0Am+vb1y457OHrHPZxl8cSBL39g0IS8FRBqvwCU1iAxbPPlHNVjsRgLhfewqyXh4Fe7fFoZq6HewbWXHb7i6cvAUDweo/lgUBAuTiVAowO8hy/96KZO4zf/U6rpeaAzr5eGY4mYKgmz6hit+VLVY12KLGA2iaJyKwx2VBVw3W9b1XXwOqfLll+wdsK8igjePTVGdKpiucect/Ppk7a9zXGKw5Y39mhh6JxBgisdCJhFsJkdoTCdEQoOr/UUerzs587lPJIQjrsZhxXU82j8Y0Pvf7BvQcsWX7B22nII9TkVzvAKAJbTQIAbJce/pfbXLb6n/VHwtAfiggi5KlmE5vzQ9EQ7Q8PhbDss0QAiKRXeTyaRZOJwUjb5bc8d9KtBb+lmKwHPvSDXzUCVgpQjPdP2OuKHSY1HPCw1VI5p6O3W8QSOkNIhXRHGq4qTEY0igGTISl5uEYW+WQeTWOivrJGE2Lg8/b+1afcH7zw1RTkAQlQvqgtAsKj3kf5qhm1CCsAWus6aUZgFSnF2AYVIDP5j9vnugO3q931UU1zj+vs79J1HTTEkRCQRzFxR+ggLRdJJiml3WaBWk8FC0Xal723+vGfv/DFQx3DENkQAGjB7ufX1lVOcj+4/PIvAYwq3yK0eCVf1bECZ9Z10qoZq8jvV0qx1SpAZtKc0Xj3Ardz/N+ITNbewUEhiXiGvVxMTzMirBUqABqSFEZCg8ASQ0kEgECi0u3mFpOkcKzjqlufO/GGYSBPNoJNAE37XTx+nHvfl+qqaiVB5HPA5OqBcOQzouQHres/XP/Muzd9BQadwchHrBlWsJmtnbRK7RRbhwJkJv+Jc37/k3HV37k/oeumgXA0B+9TiWoLUFhL+T84FFgK8YCJM722slojCq/r6Fv9s3tfvvAF8hFr9jeDH4YnsmUyvH6yz20HTqid+bLDbgGziQFjAABJSIpIFJDWkky0xoX4MJkIv/9Vb9snL7/8+GfrYWW0GEKldgqYt0KqXWILUwBfo0/zB/36Kfv/4chK9w6PJ3RBoWiMUnm6het0uazd0bL2R5/aSCSlzWqG2opqFot2PLt642unL3v3xrbN4e43Ni7XgsH5+on73PGras/O1w9E+2MAoGka41azBe0WC9gtVrCYOTBGkNRDRCC/IhIfxJPh92KJ2DsbB9e/91DwyjWFEKrFS9u8QuCW5O358V43NdZV7fKcLsE0GIkU+ffLAZdSSkBls3FHyRBNfZiocDq53aJBKLbp2tuf/4kPAOTX4O4PxTh+9t2HnrNb6w/tD/UKCcjTzQAICYkxII1zNJs0brdawWG1gc1iAsYEJEUoCUifCD3xttCTr3VH1r51x3MXrwKAeG7uwcLv/kNrreukQKBpm4lD4JZAbfCDXx69+9U7NVTtuRK5pWowHJIAhcEtKpFVRQa3+VweyuN/4ggCYGgIeThHvbaiWkOIdHT3rznjnlfOe4KIsBmbcSSQZzh6x8E7nzV+l4nfewfQWhuORSlTpSL7HTBVJZ2AEIAQgUyahlaziTttNnDabGA2M9BlGIgSa5J6cmU0NhgcjPW9vOTFcz8q3B0CEICtXRlwS6Ay73dvk2XXqcf+02qq2KM/3CuIGC9XPz/fLC0Nh3DY9R0NCtoWq5wkSVaLmeoqa1g83vXy6g2vnvLk+zetSUOe/0hga2gX3Pemw2pc05+OxmN6QtfTBbqoJGFjqBcHASGi1BgDi5lrTrsD3HY7WMwMkiKUJNA/EDL5/GCk77mbnva/DvBZPPOrFzb+Q4PgCvl1lFgpwNe46Cftd8/dVa7JP+sLdeuSyhP4iksMFk+Ocp24jLK9jKASAoBM7R/C7bBzl90G0UTnjbc8e/yVAKDnllkZaUS7GZoB/EBYIiaQsSFOnXvvbzz2yb/sDXXrklAzNu7RsOFqRiuIQAKgNHGGVquJexxOcNptgJgASdFPY4nIc93hjr8uef7MVwBAH7IZZjTT1pSJhmN98h8z+3dH1lfMfDwaj+hJIVLthkbx5cnAbw8jMoCxoE9vQTUHIuAM9ZrKao1hvDcU2nD2khU/f5SAsBlGB3kMlKVUKCNjD+DpBz78itVcM2cg0isAjHZE40TLzL3c/4CISBIQRyYtZs49Tid6nA5gLAG6iLyX1COPfPHlO3/+07vXrc0ogjcAEmHL70jJxir0mTFjFX2v/kSHyzZxcVIISug6yzRMh5ykleEOyDs/01Ed05XEy703t5dX5sMgnQQjyGziYnxNvYY0+Ob69lf2X7Li54/6GpdrCAgjnfwEhC0txJsCTeKM+b/bcfGp/3ji3B/cvhcAkM9HRteGVgWaCQD17p7WE3URGrCYrShJSgLj35CHgQiGBk5SlsGEiMgZMgLQYgkdN3b3yk/XbdC/bOulcNSym8084Te7TJ333tVHP7H0zIOWzGgKoEBAavG2cKUA8N+o0gbM7/fLqolzLraZqnaIxsIi9V0LZnTBgXmlZcvR1qRhEyIcbi+REoiEdNntWF9ZySPRtqV/fua8eY+8fcPHKTftfH2keL/F28IRkJqaUFx19COnT5u8/5sV7qn/U+XceekMmGFON7go+kp+8Euv91H++KrrPu8fXHeWVbMwM+MSZGmKXt5voBwaYMHCkNnnWMq7pkXjSdzQ0S0/XbtB7+pJekxYd+b4ql3euvqop+/44exfbNcUaBJpRd1iKTU4Fld/AIS5U0+t2bHu4I8Zs1UmkvGcSuT0rfw0IgCOoFdXVGkmLkL9oa8uuit45j0ICAthIRsF5EGfbzn3++frx+97ev2sKcfc6nFNOG4wmoBQNJ6ocFSZN3a//9vFTx9/Rbm4Qea1U/a7+y6XY/uf94V6dALQRle7qFTWQrHTgKQkjiicDqtW66kGIUOdvaG2q+946ZS7NmMMlALAMIGf42bfcbHHMfmmcLxPECAfTQlCGqb+2ugnP5HFpIm6ylpN1wc+6B745OQHXrv836Pl7ueWZbnwsLuOHFe9y60Wc/X2nb19Ip6UDBHBbNaEmQHfsPGdg+96+dzl5ViiLd4Wtvj1xeaZk89/06RVzApFB8qMVSlLyEgJSo8VSSDGUFS4HFqFwwUD4baHWl684Mx2aI9kXNYKAn0NWRGcJwCAa5rttIRIUH4iuTRIKgco7sGbuZXp58Hw/eUT3tOHlNJps2J9ZY0Wi3c++Oqb18994LXL/z1a7r6vcbkWCDSJ2eP2tP/66Mdvm1Cz2+NJ3bb9Vxs7RTSucyJCKSXGYnEmwYTVlTvdu2Dq+e6WGd60W9/AHpjhpZXrV0Y7Bz46Wcp4zKJZgUjSsL+J5JBtAAXP578u00fWsEAEJJJaT/8AtXV36HbL+BOPmX/HU3O3O6HSD37pA2JKATbb8+PlCEiH73btbM7sMxLJMBBJnr0YuZNWFl3U7EE5Bm9udYd8RZA5igBDCpNOWyECBNKrPRXMabMkegY+u/C2F4776Zs9bw54vS18pJQGH/gYEaE/OF8/66DFBx753Rve8LimnN/VH5UdvQNSF8SllCCkACklSCI2GBnQ7ba6KdN2/O7t6EfZ3LjCcFX3+1H6Gn3asvevfXcw+tXFVrOVc8aE0aSHEopg/FzhWMp85Ul3AYzGk1pbz8akxVw1f9bkY54/eNq51X5A6QMfUwqwGTKj4xwEALBzzwKN2VBKKaBM/xUs2YtF5uRyZVrTUYEzM/OY0ufnJMFLSSbO9IbqBk1j8c839bUedPfLZ97a4iUOADhSSoOvcbmW6SB/+RGP/HpS3eyXgNyz1m3apIcjCUaSGJFMTXwhQQiRutVJ6w/36R7XdiefMW/pcf7gfL2Ux8Uf9Ou+xuXaI29dsCQUbXvUZavQEEgYg8Xc8ZJlHAVGPY1zXsspKJDUhamzr0O3WSr32ql2/rOH7HCGpxmaaUtRgrH1JefNkwAAnJkPEFIHTG/9hSmG2V67+YmNVGQP5J+RrxCQ95lDqZBE0m61QEN1nZZMdP/1jfce2v9PKy//52ggjw98rCW9S5y896KZVx/99PIq19RFvaGEqa2rWyaTQhOUWvWFEKlbEiBJgpQCpBQQiydYLJGQle4d/nD8Hr8d723xSp/PeFL5g/OEz0fsy/aXz4ol+j63W52cSErj9tzFnSfLt+Ymw1HMLSqgC6l1D3TqVmvVXts1NP4FAXmrdyZuCd6hsaQA6PejnApTLZL4zrpIgABCWbD9Zo7cYlRG9zMFq4pxbsYPXry9A5CscLuZx2mXfaE1V97+0nHHvL7pbx2jgTxebwv3g182BZrEJQsePGPypP1e46yycV3HJr0/FCOSwDIr/hD0EZkdQIKQqYMksXA0TBr31NTX7nQ3IhKsmFfieiG1+pswuPaBvu6e1acCCGk2mcnIHgAD6COHxtRorAvHVua9LimV7ZwUUusZ7Eo6rOMO+cne99wcCDSJFm8LU16gEYuPAfjlgdPOGDfROWc1gckFpKeyaEvW2/wPDgQCVXtqkLPEV6Fw+0/ve+3c5eQjhv5MyGzkrM1DZ549aY8ph9zisDUc3RcKQTZnIR2PTXt0M57dob+Y2/srdaNpqHtsFdqmvo9/cU/w1NtH4hr98d5/uKLCseMN/eFunaTUyhXlMmriXY5MWK7YCwGAWTPpdqtT6xtYfewj71742FivYM3GDuszjUyTWhUA2CWJgqbS+aGd/ObTxgcVNKAuqs6QPgRJybkVBsIdb3zY/vTe97127nJf43IN/ShHMvlTJRiBmgIozpi/9OjZU4943azVHb2hs1N09w+SEJJTBvLILMxJwZ/0qp95ndJwKG0UJxI6D8VCosIx8YaT9/7NTH/wIL1ElBj8wfnC6yX+yFvn/SYcbXvOaa/UCEjINOKXOchfGowNFYx3bvEvOWQt5Tf7zj0ACOJ6gsWScbJYGu744c4X18wIeMe0PTDmvhjpJhMR8DzXW4EXqNSBJZ4vdv/le39SlAgBUmIthDMr6YoR+bN9jT4tEGgS+1QtcF906J+X1Hp2eiwawwnrNrWLSCzBiQgFCdAzk54yk14MKULeIdJHWlGICMOxCBKYHB73LvcBkFYqSgwAFAg0ExHhpv4PTk0k+zZZLU4GJCWmxyfbUD5/zCgHLmIBbCwe25xrAVQ4piwWDwuzyVPvck6/xg8oZ3rHbtvWMacAJks0BghJ4zo7smyVHhrh46L3IjFdj0q7tXqHuqq97k95XZqHNeIICP1Bv37agTd/t3HOOa9ZLQ1nbezqEZt6emRS17mkHIyfXtEzRq/MrPzpXUHk2gSUc44QICWx/lCvbrXU7HPa3PsXNQVQ+BqXlwh4+WVTU4A99/Et7QMDa08zMYYmzSSJJBkRJIrNYxjaK/OdC8WGcU4V4bwzJEkeiQ9Is9lz+uHTfLOaAiC94B2TvKEx86WCsAIA/DC5ejY4TA1nMdCslMrgw3Kpjf9BqgPT9bjutNXssl3FnpuuWT73rcZGn7Z2bVCWiA5jMzTjuLD3mgrH5Lt1qdW3d2/SY4m4lvrOcmjHoSEOjswY21mDFNLxB8jZqSCHhJd+XhChkAlpM7sPnFy568t/fP3EL7zeFt7aGigaktbWADU2Lteefevk1bvUHGh32ccdGE9GBRExo65nlJdKWpoyMdLm3wCAUujCYnKaGDDXhxv3+ttMbzMz+q5qBygY7OAnq/uEFB2M8UxcqgS7sxDqFL4GI3gud2EjSMoEjybD0m1v+P2CqZfuGAwu0kvh1+ZmQL/fTyTYpEiM+Kae9kQiEddSUEpPr9wChNRTj6UOUuhA6dvUjqCDzOwIIh8KDe0M2SAZRhMxFIRY4drh3tk7eD0zZngJjKPEEAzOEy1e4o+8c95VkVjHP52Z+IDBGOLQYyxg2RbCG6MxLQE7gXgsGSKuOY754Q6+7VKG8NizBcbSF6KUMRnUEcV7LJXyKiHH9QlFEUooE900imRKQ/de9rMQo4kIce5wVFbsdDcAsVL+bL8fiYDg0XfPOSMc62i1mOxmSboUmYlNqYk/NNGlnvb76yBkEqRIDilHSgkyipFVnoyhnLEHhCQWivQLq6lyyqyGw25ORYJXlMoFoFWBZkJAva/vg5N0Eeq3mO0o81yj+ROdiiY6laCIU5nxH/oM1PWkMHGH3eKoPREAoLFxnlKA8pHgVQgAIPRIMFt0yhjDF9sExX4NMqjamVutM3ubEykm4uFon+6w1M4/ZtffXRwINInGRp/RJKMmb4ABQLyz75OfCREXGuckRZJkzmQeWv0z9ymtCFJPK0HqkDJHIWQy9f4hhUgrktAhqQveH+rRHZb6U717Lm7yB+fr3lJRYvDLY72P8ic/uWnNYPirsy2ahZm4SRhRxottKllwW3iuHPKp5b8n93mJukiAxq3HAAALpnheygYoGQheOw+CEKQ65/Q+m6XyDEQ0SZIl4xXGVR6M2s2VowUUnyNJIoCUZrO7cbxjxydfeueGdh/4WBCCVIy1fdryd29YN6ViDjittQcl9KgQJBiUxPhyCNdTDj8/L0iVYw8AyJxzU/eFEICMk1VzHDTeOulPT7xyab/R98t8R1/jcm3Jmye+v3PtvHEuW90+cT0iCICVBvVk3OBvKByQ7a9Q7hMICCUJZKjVTPDs8ejn3fO6Sn1PtQOkVyyfj9jLX9z2qRDh5WbNjgSpkP5wtZmhZB+vUjWbAUonzgBGE1FgzGytcE29BwC0UlAoGPQLr7eFL2v91bWDsY2vWc0OTUohclf+IVgkkykboPC+yNxPgszYEGkYJXIg1NBBOotE+4gxW42nYvoSAkLwNZdcKFLxgRbe3v3IhdFE54cOq4enNbGoFYjRWA6t+FTIDqKSFbIz4yil0DVuNVm1irkAACvGGAwac5istTWAAABhvfdmQAGIPBVkGSHDMddyLgzf58cGoKC3V9HBw9F+3W6p2ftH37nx6nJQaEZgFQGg3DT4yWlJPTJo5mYQUqe8SSuycCgDaVL2QBYS5doBlLYTpEzm2RAZ2yKp6yySGEhWOiYf4d39ptP8fpQlvt/QHA+uDcb6+r/8CclEzGKypanTubZVlhqRe6R2IMjSH2QOTRqK3198TRA4muaoOMAIJJBOs3t2lf/5WKL/H3azkwORoGG5HGRA8zKKFWTOliVJYpm/QgoeiQ8Ih7X+qkOmXTknGPTrRv5sP/hlY+NC7bUvl64eiLZdonEzZ4hC5O0CetbLQ7mKkUxPdj3tCUopwZCdkLENMh4kPQlC6sLtcGOtu8qU1Nv/Fzh/wefzsRXBZlFuXBsbfdqTn/jf7w9vuMxmdjCNcVno48/2vsz+g8zkN7KriAx33Zz0U9RlAhjDWQCAK1aMLTtgTEbovNDCA3CcWDD98j2qHLu8KaTAeDLBcAS9iqhM7WcqW+iKDEuKEIB02jwskRxsXdn9yOx99jk3GQh4DSkSjY0+LRj064ftdM3f7Nbaowaj3QIJOCCm+T9ZPJ3xx6du0xNtiBuUf34qRTflqzWbLLK2cjxnTO8MRTZe+uDKcx8czdiev+AZy+3PHhb/0axbH3ZY6k+IJgYFIvAyhSjKRGBKFxDOWVZIQzPqIrb+7Q9f32ktPBAbUVhhW06KD0CT8Hof5c9+9Nt3I4nua+xWD+cM9VKJGzLNDs3AHVlmS5YlEkCkQXZZ+lwWivUJm6VqxuyKo64JBJqEr7GZG/veQfrAx77se//seGKg3axZmZBCDkEgkSzA81luUJ6nKOc+kQAhkiCFEHarE+srJ3AhBp5Z2/nWnAdXnvtgKk+ARrCQEbZ4W/jtzx4Wb9r9xr0rXTXTCHQiIjRKEioe59KVMzKPU2OYz9QFIhBSB8aYe/L2tRWp7+JDBYGGh0LS623hj79/2bWR6MYXXPZqEwLoRoEvzAvKFAdqMi9hXomQ/JIh+Vyj/M8gIXkkNqDbzdWX/mDnqw7yB/26F4xcj37ZCjOxtTOwcSDReQYiIjJGhSQ3yo0PDCmFyHOdZuCSrieBIejVFQ3cZXdEwpH1F939ykmHP/3Bb75obPRpqXpC5Ql7mX7JTYEmcfqcO89rqJ4WtJo9eyb0GGDGG0RU0CM5l+aTP1652XVQZHcVoiAEIglI5CBglbnER6UAwyxZgcAqIiJa2/nK8UnR/6HHVaMhgm7cjSuf75j/T+RwHCUUJ8vAMHEFgHgyyiQReZzb3bl/9WmuGT7jKGwAUlg7uObGpwZjnUutJgcnkiIz0YXU04Q4fYj3kwp0ZSc9pQ1kKZLSarFQXdUkjbPkyt6BVXMfePOcW3w+Yj7wsWDQr480F3nOxEOrzv7uI3+qcO9w+2A4YtvU3SaFkEgFto/xr4ei2Ev+OINhzCU/YoNcIJpB9QkelWNUNiOwlRDo4eZxh+9Qs9tLFa7aqb2DHbqUUkuVxaQSdSGKCwMOBzoLufEFDbFZJDYoPI6aqXUTZi72+/HnKcwPejEUahY+XzP729JDL+Ww3zyzyTYtGuuXCMgA04mZmO5YgKl1CDP2AKUYOZxpeoW7VrNabDKe6Lnu4X+dvQgAko2NPs3vH0nv4FRdVfSj/uPZv59b455yL2fundu72vRoPMpThXUxL4W0FOenuGRwIYcIRzK+BEnlBdqs2IDX28L/+cVt69q73jgYIPpBXeVETeOaTlLA6IhypdP/sGR8IbvSSZI8HOvTnZbanx02zX94MOgvEYVNZWi9v+mFcDTRcSpJXefcRIIEyUK/fsbzk6Y96CJBJpNJ1FVN0jQTW90XWfP9h/919q8RMDnSVT8DedCP8tT97r6ktmKXfySFaecNHev0aCymITDMzwsu7SHBPJIcGpRYyYYfMW8Byc+1RoSEhhhOXVOlAJvhGvWxF7+4a90XXY8dlEj2Pl9XNVGz2RwkScqsi24krUvL0yUKEzwKPymhx5kudXLa6u/ce/xJ1SlCWjHJKwAB4YUW/s8NS1eGE13XWjQ7JyAhSE/DnrQ7lDKQJwmShHA7qrDKVc8Tyf57Vn8W2HfZB/4XGxuXawQ0onqjGciz75Tj689pfPSxSsfk3/cPDpo6utulLpIaotFKbkwXKWwWWxwqKzW6uSOX+sq61GNmc3IAVEokfO1eAQCAJ89Zcr3dWnNFPKlDT98mXRc6Z8iy/kUaeeokGnSLpDKVlpGBcNtq+WCs/f8e//CSkzPuT6OP9kILC0ATNE68JGjizgPCiT6BGQoKpsrLEgCZTVZZ7ZnAGaONsUTfBU9+tLBlZL3EsmMDvmbw+1GeuOfigyrc29/L0Tl5U0+bHk/EOeYMRH4jESp6bFQOnkp0UaOyZ6RqbGjMzHQZW/PpR0umtUJrQrlBvwYcAvAxAoIHV579q56B1QvMJvnhpIYdtEpPDQJjQgghpZRlzDHjVUvmJFpKQ9Jd9pBC8nCsV3dYqk/6wfRFRwVLeoWAArCKAEB0RT7/eVLEwho3o5BJkiRSHiCSwm5zY41nIk+KyJNrOt/Z58mPFrakodWISrBkEvH9fpSn7Xff1ZXuqS8kEmzyVx1filg8pmUqapeq7mBMghiOVCjzgolUKkmVJCFyYAhftEJrIp3OSYoMt9kSJD/4ocXbwptfOvvTTV+++b87TNq3x+lwTqty11VazDbUZRKEELqQAhAIEYv7xIzeVsgpKogAQkrgXAMTt86vwroH9r0kEQkG5yEUEb2C5AUvXxH9a0e9dVq3VfMcocukEDLBODfrle7xmtViDUWTvZc+/fGvL2ob/PdAY6NPe+aZ80Zce+iPz/xQHL7TRRO+N/Pihx2WurO6B7qhd6CbaKhzJhWZ9sZlUGgETUSwzGiR0fhJk2ZliWTkiU+6n3sOAHipJCOlAKOxC1oD5PW28JWt9ybeXvvE68DM99XYa76w2WxVLrtruyp3HTNpZhRSkK7rQpBIh+1T8eQ8qFMGLmFeGa48eIS6SEqHpcKlmZ2T7wxc2eL1nmuY9dQKrdQIPu218M1vNdhm7mE1uWZo3JKsdE8wSUy+1htad+TyL37/lM9HLBgEXLvWPyLIswJWwPy1U+RPZt92eEP1rCcY2vfa2L1Bj0QjDDHlcSpN26QCz02ppQGLKCflPT5U8ElEnJlYXB+45dPuF1dNnjyPjSUF2GLLWhcWic1tMPHTxj/s7ra4j2Zo/ZEkPgukCQYjgzAY7oNYIqYLoSOmqoDn9NkrCOfnlj8rVSqEUmVAbBaX1hNZ9+NnP1745zKYnQEQTXEcXDelZp8PXY7amki8d9ELn197bca9ORIPD0CWcgEAePqc+xfZrFVXR2Nx6O7vElISZ7l2EJYmg2PJtlJGVHPKo5qXbk+VU4kdiThyBKBI78DqXYIbbl+fKX+jFOC/pAjeFq/EbCkh7Zi9rtmnzj3xBxq3HkbE92Bow0gsCoPhPojEwkLXk5TOlUVEHAHdKL+WDwFKm8UBAHrP+p73d399/dK2Uh1iMkb893a+5AdSMv7SZzc+hYiwkEZcWnyo9tARO18yZUL9PndbNPfBnX0bZSgSBoCUf7Ncu8Dy/TQLawEZVdymMhGBwm4EJGwmJ4vr4X8s+/iCQ3w+Hxtr7ZW2JgXI67cFK+Yxf/AgPfdSHbHHr3atd005xGx2LGBo2oej1ZNIChiMDEA4OgCJeEzXpUAAwPT2UNL/nTdVEIXbVsXD8e4nlrVeetQwnpuhWZUi/Y2sC2OmUyQi0gmzb/FWOLb7A5FW19HbricScQ0RR2jlUAmPDhWs9VhSSUpNfgN1Enazm4cTHac/vfqX941ml1MK8B/6fV6vl83oOAcXvXyQTjl4uHH7cxqmTJy5v83m/D5ntrlEMJ2RFaPxGISi/RCJDlIimRQkJWJKGRCxRKUUAjBpmm63eLS+6Pqf/v3jhQ+WUwIf+FgrtGIAAmKUkEc7fb///a3NUnVxKBKGnv4uQUQcEA16Wparo0dDnc8KJ3mxExQNzFwqoQ45OwCBNGlmJBLdXeHWnV9dt6Q33fyElAJ8i3EEaJzHYN486fdj7lbMTj5g8XS3vXYuR+vBknAOEJskJYNoLAqh6ABEY2GZ1JNSksyxHzAXEEmrxQ5INNAWat39tS/vWDfaZnnlIM/Rs3zT6jzT7zVp7v07e9tFOBZiQ/zpEZA7cjE8FnnysUgtSk2OYlUopQyoOywVWjTedcOyTy69cqyWSNymFKCQK+P1BpgXvNAUYCL34jXWep07Tmvc02xyzteY9QAJsDdHa4UQAJFoGMLRAYjGI1JP6imFQGAIiMh4Cgolup9+6qPLf/h1LroXvDwAfxEABCfsedspFY4Ji3XBKjt72/WEntCYYcCunAu3kNtUuFtkVYTy6gFRkQ8oP4EGDVyoRCaTjRjQQE94zfTg2hs3ATQjjMHuMduwAhT27fIhrJjHZtZ1UmF/332nHF8/feK+uzut4/YHwnlEuDtDi1sIgGgsnN4hIlLXk5JzJhxmj6U31nbKC582P7A5SpApcjsR5tgOnXP2LXZL1Rn9oX7oG+wRkojjsNym0k2QRhYPh2HMF6O4QvYRQ6Y7bVXaYKTtqqc//dX1Y7lArlKAkrZDC5vRUYsGcAkO2umiCdvX7bSrxew8gDPTXABtV4amSikQIvEI6EkdQpGe7tVrXp3VGglsHLnrj7DFG2BNgSZx1HcWza5373y3xpx7dPRuEJFYhKU2mkyHCixRECB3Jc+u6FiA/6FkzQzMq5hBJbE+DvVoyEZGEAhIOK0VPCnCq95t/etep8C8hB/8NJaiv0oBNhMuzeioxeYV8wQWVGz/3q5n1Y1z7rG7w2yfg8jmItOmk26d2Nm3NrjqvVcO9fpa9EIlKtUYHADgJ3vddo7bOv53ySQ4OnvbdV3oWsYjRYY9HIs9+5inCEa05XIKAEWrfKkS9ZTTYpaAyGKySRM3UV9o/dwXvrzmjRSUCwjVH2DrMqeZ1zsTS+0Q+++yv2vG+FN3Dg/EGjs71v35xa9ubCvnAclAnt08R1bMnnbUHTZLzQm9A13QH+oTQMALTV0qS9+gHHSOm3G5sYyRWzoOQEBg1ixJp63KNBD66oKnPr3ytrHeG0ApwH9hhzBSiHKK5EszOJt2+90BFc5J9zC0T+vobtOjiQhHyPqZCuOwWJK5QwXxXSPnKBp4gWgYrF9a9SQQmDRT0uOoM4WibXc88dFl52Xa3aoOMduwDdHRsQqDQb9hX7Hc1fHE2X/8pdNauyie0M1dvRt1IYSGw3k4DekI+SCnXEjMyN1ZOipQmkgnichitogKV70Wjnb872OrLjg1/dvkWMX9SgG+dcpGyrd/0MQzJ+wwYe4Ss8lzRHf/RhoIDxAaUtRpRJ4aKkpeJEM2KxWUkUSDiHDptT8H+xNIm80BHnstC8U773zsg/PP8vmI+f1IW8LkVwrwLQTiMnSG43dbfLjbMW4pkHnipp4NIpGIMYQU+0ISGV4gGsobpgwFI9trIPfMsizQkSUKUUGuMOV9NAEgCo+rhtvMFgpFuq9+bNWF129pk18pwDc5+bPN7Uwnzr7zOrul6rJoLArd/R1CCsmNWalUHMQacoNSwWPj8l9UwO7JtyewwHooJDUY+H5IkslkFtWecRqAvn4g3nHG4x9c9vctCfYoBfiWVv0fzVy0W6Vr+6Vm5pnT2dcuQ5EQABAzxvtUplozFaRwUokOkFRUM9soZmBcUaPAEZraUYTD7uZVrjpI6uEnN2x6/+x/rL95w5Zi8CoF+IYll/140l5LL7Nbqn3JJDk6e9v0eCKu5ZQ8HNbALTV50egyYl6mT4nYAULpjK5c3xABEZGmaaLSXa+ZNB6Nx/uufvT98xePJmdZKcC2RrpLuzePmrloeo178h1mzTO/q28T9If6BEnJGRYTkEuv+sOhecwPfiEAkbErM99ERoNkeCio7QnSbrOzKvd4kDL6Rs/g+nOe+vjqd1J4vxnGIr9HKcC3uupn4cBPZ991vtXsvk4XzNXRs0GPJ2IckWFx2amRlO6i8pcuN/E573SZQ2krn8qYXxtCAGMmvcJTp1lNZj0pwr/90ztn+QEg6Wv0af4xxutXCjCGsP4PZ/mmNTin3mbizu/19HdCX6hHkCQOQ5An1wufTykYpi1rQd9GNEzTIcOUFcp7hUrSnVPuTavNhtXu8Sgh/kEsvPGcQOsVrwIg+GDE2WtKAbYVycXBP97jjoud1mq/EMzZ0bNexBMxlkm1pDJJJIXFBbEMtzO/Klu5WAGVjOIaxn2JgHEuKt113Go2gy6ii//91Z98rZ3BUNqLJbY0L49SgG8g4hsINImDp1yx83a102+1aO4FPQOd0DeYWvWzZUmoTAo5FaWdF6/eaBDywmGtAypY+Yv/r2xQy2q1Y5VnPALGP4zFuy4IvH/ZP3JSN8VWeQHVHIbN5v8gMiIiOHbXm0522xpuBqlVdfRs0OPxaBrr57oZC1d6KlqFZU6NTSjJ6MeizF40rNlQjjKdQ3UjAs413eOu0awWK0g9vvjtfz/QvBpeG0x7sba6VR+2nOrQY7lEI0oiMB33nT/c5LTWnh+O9EPvQLeQQmpGq35x+gjmRFqNVurhHKFURF6gIo8PleDwpOoxSpDSZnNgtWeiJin+YTzSeUGgNb3qp2CdvrVfS7UDbGZ90t08R1ZMn/T9v9gt1Qd3D7SJSCTM0CCiVTwZy/vnKS+8RSV5+8Up7LmuVDQkLGeLoUvizCQqPLWaxWwmIeOLV7X91ff+phfCW2pEVynANwV7gNH3q85zOxumPWM3ew7o7m9PxhNxU7rgXBGOp5LpilQyuUUalOIqx/7HouAYGu4mRASEJOw2J69yjwNJiXcHw+svWbbat3xrCGrB1l4c99s3eAOMYLpZq5r0Nw3tB3T0fpWMJ2ImQBgqrAsGJdYLu6nngxXK68WSm85Y2LfG6DYf/EjI/ybZ/0GQJMa5XlM5gXtc1XpC778h+M7dByxb7Vve4qURF+JVNgBss65OFgg0iUMmLbzexisO6gttTCb1pCm3+KyRh4eKGPr5iSjlqrVRUT22QuPXKHpLeeApxeEhYbe7eJWrQZMQe70/1n7h061Xv5mpPtEUQLHNrmpqao8c98+pu+g7lfZx/yYiSiZjeZi/fIR1pPSGrHLIEmmNhbGCkhCL0uVJNLOocNdrJpMWSSZDvw18eMENkK1FKrYVrK92gK8hrTATAQDsmvNSjiYWTQzqBIC5nHsqWYeHynTfKuXZKbQUjNJVykQNiAAQhNPh4RWuOk3I6Cv9oQ3nP/3pwvcQEI6FY3lgK6EyqB3gmxkjmuH2Vo1zzfyUo6lKlwkavipbuVXaCPKMpI4/5GXiGlHpiIg0k0VWe8ZxrsFgQo/5HvvgF7cAAKlVXxnBm1OhjQEAVFonzeZorkrKpCRAHEnXGSroNZbfRwXyTOTMc7JkPzM51L1Gpm/zGsGSBAIQTmcV1ldvx5GJZzcNrp7z2Ae/uJmIIKfBnpr8CgKNXDpgBgIAcK7tgcgJSEpAZDAiXiUV8T3BIF8r/wxZggVERcGtbDRXSrPZBlXuCRw5dUTjnQv/1nr5nQCpnAREFHn5jUqUAoxWSOJkIsLUhCtMHh8Z7GFFRUtKRwogr4RVQapKOg1SAgFHrrtd9ZrD7gYp43/q7fj8iufbFn/l8xEDfzP4FdZXCvAfMQSQVUiSBSVHjAgKpQkNsmyJkSxJjQzaEeUphiQgIGm1OLDKPV4DFF9GEl2XLWu94i9DTfP8265rUynAf1DqYCYBAHDGbBkMXi6BpVzPdGOWvnG0IDdvIBcEEUnSmEl4XHWaxWIFXUbvaOt9b+HK9ff2pCK5q2hbDGgpBfjv7wFkzKwcLgJAef4dNGw3RyVcpjmvpio/CJvVzavc4zQJifcGI5su+/tnvhe2VRqDUoBv0gZIY/+s65/KYPj8Cs1kuObnAyPjRhM0VH1N08yyyjWOayaejOv9N77R+qfr2uHtSGrie2UgoCCPUoD/pkgAYFSSX1/M6MzF9dKQE1rs9SnwEZEEQCZcjkrucdZxIWOvhsObLvr7F/5/DSWqqFVfKcA3swPIIi5Pvscm/x4ZruqluDsGzH4iaTbZoNI9nmsa9uhicNFfV118GwBQhrK8tWZpKQUYyzDIkJpQiOqxZOvQ4jzggneTBESue1w1mtNWAbqMPt4RXntZ8PObPyMgbIZm5lervlKAb2X6DxkBVFCMlg3FcKGA61my2o7Ba0QkrRYnVrnGa8DEupjee9mTH13RApAOaAVRRXJBUSG+HROAwBD/59OccxWjMA+ADAzc1CFJEGOaXu2ZyKo89UgYv/3zrrf3evKjK1p8PmKQpTEoUTvAt2gFSyiuxJxnH+RDIyrTTC5r5KJw2Cq4x9mgSUi8HY12X/bM59kMLRXQUgowhrbKDHaXBUVFqEQgjIqUAHOqLGuaVVa6x3PNxEK6CN3wxEeX3ggAySEjV2F9pQBjygtqYOQWV1QurvNJ+d4dQOS6y1GnOR1VXFD07wODnZe8uPbaj4b6A6uJrxRgLBoBhJlmFNmobrGrE0tQ3mSKv2N2YqVrggZMtEfjvVf9/bMr78+pJC3GckdFpQDKE2SwspNhl8a8aAERcW6WHmcDN1usQBS/e92mD5vf7b6vzefzMfCDYm0qBdhSAmH5kxtLMvezkVy7rZJ7HPWcMPF2NNp5xXNr/C9mjVwFd5QCbGGhMDTooltUk4FImjQ7VbomcM5xIC77b3jmkysWA0BC8XeUAmxBEsgs50PVFsqVPSSSxJhJuJ11mt3qBgHxx3oG23/18oYbPwVA8MKxyshVCrCleoGgiNtZUMNH2KwVvMLZoBGKT6N671XPfnZ1IIeuLJWRqxRgC1YBMpz4RCTNmo08znFc07SEhNjNGzvevf7NnocHfEDMD82gVn2lAFuFBVBQWpwY06TbXsOd9iqQmHw+nuy/4tnPFr6boSv7QeF8pQBbmxKkvTs2q4dXOMZxYGJNXIZ8z3zyy/8DyPXpq1VfKcBWxgYlKaXZZJMe5wSuaTxGkLi1J/Lpb19dt6Q3TVdG5dNXCrD1WQBCSk3TRJVrotlqcYKgxLJEou/Xz67xv5+BO5iCO4quDIoODVtTbTgAALPZ6WiomsqtNtu/YmLwyKc+veTIZ9f43/d6WzgAoYI7agfYKmUGrCIAAIfT9a849S17cvWlSwGAfEAMoBlUdpaSbXBPaOFqFJTAttYjIAV3VEVtJUqUKFGiRIkSJUqUKFGiRIkSJUqUKFGiRIkSJUqUKFGiRIkSJUqUKFGiRIkSJUqUKFGiRIkSJUqUKFGiRIkSJd+o/D8MmZ+pu0As7QAAAABJRU5ErkJggg==",
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
M.FALLBACK = FALLBACK_ASSET
function M.resolveAsync(cb)
if resolved then
task.spawn(cb, resolved)
return
end
task.spawn(function()
local id = M.image()
if id and id ~= FALLBACK_ASSET then pcall(cb, id) end
end)
end
local resolving = false
function M.image()
if resolved then return resolved end
if resolving then
local t0 = os.clock()
while resolving and not resolved and os.clock() - t0 < 5 do task.wait(0.05) end
return resolved or FALLBACK_ASSET
end
resolving = true
local ok, id = BX.try("logo.resolve", fromWorkspace)
resolved = (ok and id) or FALLBACK_ASSET
resolving = false
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
local AUTO_CONTINUE = 3 
local INVITE = "https://discord.gg/9KSXyabAYV"
local logomod = BX.require("ui.logo")
local LOGO = logomod.FALLBACK
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
local loadingSound = new("Sound", {
Name = "BlyxoLoadingNotification",
SoundId = "rbxassetid://139746569667955",
Volume = 3,
}, game:GetService("SoundService"))
local errorSound = new("Sound", {
Name = "BlyxoErrorNotification",
SoundId = "rbxassetid://71028126634386",
Volume = 3,
}, game:GetService("SoundService"))
task.spawn(function()
pcall(function()
game:GetService("ContentProvider"):PreloadAsync({ loadingSound, errorSound })
end)
end)
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
local backdropLogoSize = 320
pcall(function()
local viewport = workspace.CurrentCamera.ViewportSize
backdropLogoSize = math.clamp(math.min(viewport.X, viewport.Y) * 0.52, 190, 320)
end)
local backdropLogo = new("ImageLabel", {
Name = "BackdropLogo", AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(backdropLogoSize, backdropLogoSize),
BackgroundTransparency = 1, Image = LOGO,
ImageColor3 = WHITE, ImageTransparency = 1,
ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
}, dim)
local backdropLogoScale = new("UIScale", { Scale = 0.86 }, backdropLogo)
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
holder.Visible = false
local panel = fade(new("Frame", {
Name = "Panel", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
BackgroundColor3 = WHITE, BackgroundTransparency = 0.16,
}, holder), { BackgroundTransparency = 0.16 })
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
local logoImage = new("ImageLabel", {
Name = "Logo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
Size = UDim2.fromOffset(38, 38), BackgroundTransparency = 1, Image = LOGO,
ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
}, core)
fade(logoImage, { ImageTransparency = 0 })
logoImage.Rotation = -2.5
local logoFloatTween = tween(logoImage,
ease(3.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
{ Rotation = 2.5 })
local logoZoomTween = nil
logomod.resolveAsync(function(id)
if logoImage.Parent then logoImage.Image = id end
if backdropLogo.Parent then backdropLogo.Image = id end
end)
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
FontFace = font(Enum.FontWeight.SemiBold), Text = "Join Discord", TextColor3 = PANEL,
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
if logoFloatTween then logoFloatTween:Cancel() end
if logoZoomTween then logoZoomTween:Cancel() end
if blur then blur:Destroy() blur = nil end
if loadingSound then loadingSound:Destroy() loadingSound = nil end
if errorSound then errorSound:Destroy() errorSound = nil end
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
playFade(ease(0.3, Enum.EasingStyle.Quad), true)
tween(meter, ease(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
if blur then tween(blur, ease(0.4, Enum.EasingStyle.Quad), { Size = 0 }) end
tween(dim, ease(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
tween(backdropLogo, ease(0.45, Enum.EasingStyle.Quad), { ImageTransparency = 1 })
tween(backdropLogoScale, ease(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.84 })
tween(scale, ease(0.4, EXPO, Enum.EasingDirection.InOut), { Scale = baseScale * 0.82 })
task.delay(0.42, function()
notifyClosed()
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
local copied = exec.clipboard(INVITE)
flash(copied and "Invite copied to your clipboard" or "discord.gg/9KSXyabAYV")
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
pcall(function()
if loadingSound then
loadingSound.TimePosition = 0
game:GetService("SoundService"):PlayLocalSound(loadingSound)
end
end)
tween(dim, ease(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.3 })
tween(backdropLogo, ease(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0.04 })
logoZoomTween = tween(backdropLogoScale,
ease(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 })
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
pcall(function()
if errorSound then
errorSound.TimePosition = 0
game:GetService("SoundService"):PlayLocalSound(errorSound)
end
end)
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
local SoundService      = game:GetService("SoundService")
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
local gui, pill, scaler, stroke, brandFrame, brandSubtitle
local notificationSound
local launcher, launcherTitle, launcherSub
local chevron, chevronGlyph   
local sc   
local bars, labels, fadeList, iconBoxes = {}, {}, {}, {}
local momentRow, momentDot, momentTitle, momentSub, momentBar
local momentSpacer, momentClockDivider, momentPingDivider
local momentNodes = {}
local momentTrack = nil
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
local windowOpen = false
local notificationVisible = false
local function restoreFade()
for _, f in ipairs(fadeList) do
if f[1] and f[1].Parent then
pcall(function() f[1][f[2]] = f[3] end)
end
end
end
function M.setDock(_) docked = false end
function M.isDocked() return false end
function M.setWindowOpen(open)
windowOpen = open == true
if windowOpen then
notificationVisible = false
if pill and pill.Parent then pill.Visible = false end
return
end
if gui and gui.Parent then gui.Enabled = true end
if pill and pill.Parent then
pill.Visible = true
restoreFade()
end
end
function M.setNotificationVisible(on)
notificationVisible = on == true
if not gui or not gui.Parent or not pill or not pill.Parent then return end
if notificationVisible then
gui.Enabled = true
pill.Visible = true
elseif windowOpen then
pill.Visible = false
end
end
function M.setTapToOpen(on)
if brandSubtitle and brandSubtitle.Parent then
brandSubtitle.Text = on and "Tap to open" or (BX.game or "Steal An Egg")
end
end
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
function M.fetchIcon(kind, src, cb)
if type(kind) ~= "string" or type(src) ~= "string" or type(cb) ~= "function" then
return false
end
if not (exec.can.customAsset and exec.can.files) or exec.fragile then return false end
if iconAsset[kind] then
task.spawn(cb, iconAsset[kind])
return true
end
task.spawn(function()
local ok = BX.try("stats.icon." .. kind, function()
exec.ensureFolder(ICON_DIR)
local path = ICON_DIR .. "/" .. kind .. ".png"
local have = exec.isFile(path) and validPng(exec.readFile(path))
if not have then
local png = game:HttpGet(ICON_BASE .. src)
assert(validPng(png), "not a usable png")
assert(exec.writeFile(path, png), "writefile refused")
end
iconAsset[kind] = assert(exec.customAsset(path), "no custom asset")
end)
if ok and iconAsset[kind] then BX.try("stats.icon.cb." .. kind, cb, iconAsset[kind]) end
end)
return true
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
local TextService = game:GetService("TextService")
local MOMENT_IN, MOMENT_OUT, MOMENT_XFADE = 0.36, 0.30, 0.12
local momentStatsWidth = nil     
local momentWasVisible = {}      
local function measure(label, text)
local ok, size = pcall(function()
return TextService:GetTextSize(text, label.TextSize, Enum.Font.Gotham,
Vector2.new(1000, 40))
end)
if ok and size then return size.X end
return #text * label.TextSize * 0.55
end
local GHOST = {
TextLabel = "TextTransparency", ImageLabel = "ImageTransparency",
Frame = "BackgroundTransparency", TextButton = "BackgroundTransparency",
UIStroke = "Transparency",
}
local function ghostNodes(on, t)
for _, node in ipairs(momentNodes) do
local list = node:GetDescendants()
list[#list + 1] = node
for _, d in ipairs(list) do
local prop = GHOST[d.ClassName]
if prop then
local rest = d:GetAttribute("ghostRest")
if rest == nil and d[prop] < 1 then rest = d[prop] d:SetAttribute("ghostRest", rest) end
if rest and rest < 1 then
if t and t > 0 then tw(d, t, { [prop] = on and rest or 1 })
else d[prop] = on and rest or 1 end
end
end
end
end
end
local function rowWidthOfStats()
if not pill or not pill.Parent then return 200 end
local k = (scaler and scaler.Scale) or baseScale
local w = pill.AbsoluteSize.X / (k > 0.01 and k or 1)
return math.max(120, w - 28)     
end
local function layoutProgress(width, progress, animate)
local trackWidth = math.max(0, width - 48)
if momentTrack then momentTrack.Size = UDim2.fromOffset(trackWidth, 3) end
local target = UDim2.fromOffset(trackWidth * progress, 3)
if animate then tw(momentBar, 0.25, { Size = target })
else momentBar.Size = target end
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
tw(momentSub, MOMENT_XFADE, { TextTransparency = 1 })
tw(momentTitle, MOMENT_XFADE, { TextTransparency = 1 })
tw(momentDot, MOMENT_XFADE, { BackgroundTransparency = 1 })
tw(momentBar, MOMENT_XFADE, { BackgroundTransparency = 1 })
if momentTrack then tw(momentTrack, MOMENT_XFADE, { BackgroundTransparency = 1 }) end
local back = momentStatsWidth or rowWidthOfStats()
tw(momentRow, MOMENT_OUT, { Size = UDim2.fromOffset(back, 24) })
task.delay(MOMENT_OUT, function()
if token ~= momentToken or not pill or not pill.Parent then return end
for _, node in ipairs(momentNodes) do
local was = momentWasVisible[node]
node.Visible = was == nil and true or was
end
momentRow.Visible = false
M.bump(0.025)
task.delay(0.05, function()
if token ~= momentToken or not pill or not pill.Parent then return end
ghostNodes(true, MOMENT_XFADE + 0.06)
end)
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
local tw_ = measure(momentTitle, titleText)
local sw_ = subText ~= "" and measure(momentSub, subText) or 0
local maxWidth = math.clamp(tonumber(spec.maxWidth) or 360, 170, 360)
local width = math.clamp(tw_ + sw_ + 66, 170, maxWidth)
if entering then
momentStatsWidth = rowWidthOfStats()
ghostNodes(false, MOMENT_XFADE)
momentTitle.TextTransparency, momentSub.TextTransparency = 1, 1
momentDot.BackgroundTransparency = 1
momentBar.BackgroundTransparency, momentBar.Size = 1, UDim2.fromOffset(0, 3)
if momentTrack then momentTrack.BackgroundTransparency = 1 end
momentRow.Size = UDim2.fromOffset(momentStatsWidth, 24)
task.delay(MOMENT_XFADE * 0.5, function()
if token ~= momentToken then return end
for _, node in ipairs(momentNodes) do
momentWasVisible[node] = node.Visible
node.Visible = false
end
momentRow.Size = UDim2.fromOffset(momentStatsWidth, 24)
momentRow.Visible = true
tw(momentRow, MOMENT_IN, { Size = UDim2.fromOffset(width, 24) })
M.bump(0.03)
task.delay(0.08, function()
if token ~= momentToken then return end
tw(momentDot, MOMENT_XFADE, { BackgroundTransparency = 0 })
tw(momentTitle, 0.16, { TextTransparency = 0 })
end)
task.delay(0.14, function()
if token ~= momentToken then return end
tw(momentSub, 0.16, { TextTransparency = 0 })
if momentProgress ~= nil then
tw(momentBar, 0.16, { BackgroundTransparency = 0 })
if momentTrack then tw(momentTrack, 0.16, { BackgroundTransparency = 0.82 }) end
end
end)
end)
elseif not momentWidth or math.abs(momentWidth - width) > 12 then
tw(momentRow, 0.2, { Size = UDim2.fromOffset(width, 24) })
end
momentWidth = width
if titleChanged and not entering then
tw(momentTitle, 0.08, { TextTransparency = 1 })
task.delay(0.09, function()
if token ~= momentToken then return end
momentTitle.Text = titleText
tw(momentTitle, 0.14, { TextTransparency = 0 })
end)
else
momentTitle.Text = titleText
end
local liveProgressText = type(spec.progress) == "number"
and titleText == momentTitle.Text
if subChanged and not entering and liveProgressText then
momentSub.Text = subText
elseif subChanged and not entering then
tw(momentSub, 0.08, { TextTransparency = 1 })
task.delay(0.09, function()
if token ~= momentToken then return end
momentSub.Text = subText
tw(momentSub, 0.14, { TextTransparency = 0 })
end)
else
momentSub.Text = subText
end
momentSub.Position = UDim2.fromOffset(tw_ + 30, 1)
momentDot.BackgroundColor3 = spec.tone == "warn" and WARN
or spec.tone == "bad" and BAD or TEXT
local progress = type(spec.progress) == "number" and math.clamp(spec.progress, 0, 1) or nil
local hadProgress = momentProgress ~= nil
momentProgress = progress
momentBar.Visible = progress ~= nil
if momentTrack then momentTrack.Visible = progress ~= nil end
if progress ~= nil then
layoutProgress(width, progress, hadProgress)
if not hadProgress and not entering then
momentBar.BackgroundTransparency = 1
tw(momentBar, 0.16, { BackgroundTransparency = 0 })
if momentTrack then
momentTrack.BackgroundTransparency = 1
tw(momentTrack, 0.16, { BackgroundTransparency = 0.82 })
end
end
end
momentLastTitle, momentLastSub = titleText, subText
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
local COMPACT_T = 0.34
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
tw(chevronGlyph, COMPACT_T, { Rotation = rot }, Enum.EasingStyle.Cubic)
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
if notificationSound then pcall(function() notificationSound:Destroy() end) end
gui, pill, scaler, stroke, brandFrame, brandSubtitle = nil, nil, nil, nil, nil, nil
notificationSound = nil
launcher, launcherTitle, launcherSub = nil, nil, nil
chevron, chevronGlyph = nil, nil
menu, menuScale = nil, nil
bars, labels, fadeList, iconBoxes = {}, {}, {}, {}
cellFrames = {}
momentRow, momentDot, momentTitle, momentSub, momentBar, momentTrack = nil, nil, nil, nil, nil, nil
momentSpacer, momentClockDivider, momentPingDivider = nil, nil, nil
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
notificationSound = mk("Sound", {
Name = "BlyxoNotification",
SoundId = "rbxassetid://87437544236708",
Volume = 3,
PlaybackSpeed = 1,
RollOffMaxDistance = 10000,
}, SoundService)
task.spawn(function()
pcall(function()
game:GetService("ContentProvider"):PreloadAsync({ notificationSound })
end)
end)
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
pill = mk("TextButton", {
AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.01),
AutomaticSize = Enum.AutomaticSize.X,
Size = UDim2.fromOffset(0, touch and 46 or 42),
BackgroundColor3 = BG_TOP, BackgroundTransparency = 0.18,
BorderSizePixel = 0, Active = true, AutoButtonColor = false,
Text = "", Selectable = false,
}, gui)
pill.Visible = not windowOpen
mk("UICorner", { CornerRadius = UDim.new(0, 22) }, pill)
mk("UIGradient", {
Rotation = 90,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, BG_TOP),
ColorSequenceKeypoint.new(1, BG_TOP),
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
brandSubtitle = mk("TextLabel", {
Name = "Subtitle", Position = UDim2.fromOffset(32, 17),
Size = UDim2.fromOffset(76, 13), BackgroundTransparency = 1,
FontFace = face(Enum.FontWeight.Medium), TextSize = 9,
TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
Text = BX.game or "Steal An Egg",
}, brandFrame)
momentRow = mk("Frame", {
Name = "DynamicIslandRow", LayoutOrder = 1, Visible = false,
AutomaticSize = Enum.AutomaticSize.None, Size = UDim2.fromOffset(0, 24),
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
momentTrack = mk("Frame", {
Name = "ProgressTrack", AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 24, 1, -1), Size = UDim2.new(0, 0, 0, 3),
BackgroundColor3 = TEXT, BackgroundTransparency = 0.82,
BorderSizePixel = 0, Visible = false,
}, momentRow)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, momentTrack)
momentBar = mk("Frame", {
Name = "Progress", AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 24, 1, -1), Size = UDim2.new(0, 0, 0, 3),
BackgroundColor3 = TEXT, BorderSizePixel = 0, Visible = false, ZIndex = 2,
}, momentRow)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, momentBar)
labels.time = cell(pill, 2, "clock", "00:00")
local d1 = divider(pill, 3, "TimeDivider")
labels.fps  = cell(pill, 4, "pulse", "000", "FPS")
local d2 = divider(pill, 5, "PingDivider")
labels.ping = cell(pill, 6, "wifi", "000", "ms")
local spacer = mk("Frame", { LayoutOrder = 7, Size = UDim2.fromOffset(4, 18), BackgroundTransparency = 1, Visible = true }, pill)
momentClockDivider, momentPingDivider, momentSpacer = d1, d2, spacer
local hit = touch and 34 or 24
chevron = mk("TextButton", {
Name = "Collapse", LayoutOrder = 8, Size = UDim2.fromOffset(hit, hit),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
AutoButtonColor = false, Text = "", Selectable = false, Visible = true,
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
tw(scaler, 0.09, { Scale = baseScale * 0.975 }, Enum.EasingStyle.Quad)
tw(stroke, 0.09, { Transparency = 0.18 }, Enum.EasingStyle.Quad)
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
function M.bump(strength)
if not scaler or not scaler.Parent or closing then return false end
local k = baseScale * (1 + (strength or 0.06))
tw(scaler, 0.12, { Scale = k }, Enum.EasingStyle.Quad)
task.delay(0.12, function()
if scaler and scaler.Parent then
tw(scaler, 0.32, { Scale = baseScale }, Enum.EasingStyle.Back)
end
end)
return true
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
function M.recoverResting()
if not pill or not pill.Parent or closing or momentActive then return false end
if momentRow then momentRow.Visible = false end
if brandFrame then brandFrame.Visible = true end
if cellFrames.pulse then cellFrames.pulse.Visible = true end
if momentSpacer then momentSpacer.Visible = true end
if chevron then chevron.Visible = true end
if cellFrames.clock then cellFrames.clock.Visible = not compact end
if cellFrames.wifi then cellFrames.wifi.Visible = not compact end
for _, node in ipairs({ momentClockDivider, momentPingDivider }) do
if node then node.Visible = not compact end
end
ghostNodes(true, 0)
if compact then applyCompact(false) end
return true
end
function M.playNotificationSound()
if not notificationSound or not notificationSound.Parent then return false end
local ok = pcall(function()
notificationSound.TimePosition = 0
SoundService:PlayLocalSound(notificationSound)
end)
return ok
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
local spec = persistent[key]
if spec then return spec, key end
end
end
local function refresh()
if not BX.alive() then return end
local oldShown, oldKey = shown, current
local spec, key = resolve()
local hud = stats()
if hud and hud.moment then hud.moment(spec) end
if not spec and hud and hud.recoverResting then
task.delay(0.38, function()
if BX.alive() then BX.try("island.recoverResting", hud.recoverResting) end
end)
end
shown, current = spec ~= nil, key
if key ~= nil and key ~= "notify" and (oldShown ~= shown or oldKey ~= current) then
if hud and hud.playNotificationSound then
BX.try("island.stateSound", hud.playNotificationSound)
end
end
end
function M.show(key, spec)
spec = spec or {}
transient = { key = key, spec = spec, untilT = os.clock() + (spec.hold or 3) }
BX.try("island.show", refresh)
if key == "notify" then
local hud = BX._loaded["ui.stats"]
if hud and hud.playNotificationSound then
BX.try("island.notificationSound", hud.playNotificationSound)
end
end
local untilT = transient.untilT
task.delay((spec.hold or 3) + 0.05, function()
if transient and transient.untilT == untilT then BX.try("island.expire", refresh) end
end)
end
function M.set(key, spec)
spec = spec or {}
if persistent[key] == nil then
if spec.low then table.insert(persistentOrder, 1, key)
else persistentOrder[#persistentOrder + 1] = key end
end
persistent[key] = spec
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
function M.refresh() refresh() end
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
title = tostring(BX.versionTag
or ("V" .. (tostring(BX.version or ""):match("^(%d+%.%d+)") or "5.1"))),
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
function h:SetTitle(t) self:setTitle(t) end
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
local function frame()
local m = type(el) == "table" and rawget(el, "main") or nil
return typeof(m) == "Instance" and m or nil
end
function h:setVisible(v)
BX.try("adapter.setVisible", function()
if type(el.SetVisible) == "function" then
el:SetVisible(v and true or false)
elseif frame() then
frame().Visible = v and true or false
end
end)
end
function h:destroy()
BX.try("adapter.destroy", function()
if type(el.Destroy) == "function" then
el:Destroy()
return
end
local conns = rawget(el, "connections")
if type(conns) == "table" then
for _, c in pairs(conns) do
if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
end
end
if frame() then frame():Destroy() end
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
local PERSISTED = { toggle = "boolean", slider = "number", input = "string", dropdown = "string" }
local function persistKind(kind, opts)
if kind == "dropdown" and opts.multi then return "table" end
return PERSISTED[kind]
end
local function flagFor(kind, opts)
if opts.persist == false or not PERSISTED[kind] then return nil end
if opts.flag then return tostring(opts.flag) end
local name = tostring(opts.name or ""):gsub("[^%w]", "")
if name == "" then return nil end
return kind .. "." .. name
end
local function remember(h, kind, opts)
local flag = flagFor(kind, opts)
if not flag then return end
h.flag = flag
h._callback = opts.callback
BX.try("adapter.remember/" .. flag, function()
local prof = BX._loaded["core.profiles"] or BX.require("core.profiles")
if prof and prof.register then prof.register(flag, h, persistKind(kind, opts)) end
end)
end
local function touching(name, fn)
return function(value)
BX.try("adapter.touchProfile", function()
local prof = BX._loaded["core.profiles"]
if prof and prof.touch then prof.touch() end
end)
if fn then return fn(value) end
end
end
local function create(kind, opts)
opts = opts or {}
stats.created = stats.created + 1
local name = opts.name or kind
if native then
local o = opts
if PERSISTED[kind] and opts.persist ~= false then
o = table.clone(opts)
o.callback = touching(name, opts.callback)
end
local el = raw[kind](raw, o)
local h = wrapNative(el, kind, name)
remember(h, kind, opts)
return h
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
local h = wrapRayfield(el, kind, name, guard)
remember(h, kind, opts)
return h
end
function tab:CreateSection(o)  return create("section", o) end
function tab:CreateSubnav(o)
if native and type(raw.subnav) == "function" then
return wrapNative(raw:subnav(o or {}), "subnav", o and o.name)
end
local names = {}
for _, item in ipairs((o and o.items) or {}) do names[#names + 1] = tostring(item) end
return tab:CreateText({ name = "", text = table.concat(names, "   ") })
end
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
local native = BX.require("ui.lib")
local ORDER = {
Home = 10,
Main = 20,
Farm = 30,
Event = 40,
Misc = 50,
Config = 60,
}
local major = tostring(BX.version or "6"):match("^(%d+)") or "6"
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local raw
raw = native.window({
title = "BlyxoHub",
subtitle = BX.game or "Steal An Egg",
user = localPlayer and (localPlayer.DisplayName or localPlayer.Name) or "Player",
userTag = localPlayer and ("@" .. localPlayer.Name) or "@Player",
userImage = localPlayer and ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(localPlayer.UserId) .. "&w=150&h=150") or "",
badge = nil,
startHidden = true,
deferEntrance = true,
onMinimising = function()
BX.try("shell.statsPause", function()
BX.require("ui.stats").setWindowOpen(true)
end)
end,
onRestored = function()
BX.try("shell.islandClear", function()
BX.require("ui.island").clear("closed")
end)
BX.try("shell.statsResume", function()
local stats = BX.require("ui.stats")
stats.setWindowOpen(true)
stats.setTapToOpen(false)
end)
end,
onMinimised = function()
BX.try("shell.statsResume", function()
local stats = BX.require("ui.stats")
stats.setTapToOpen(true)
stats.setWindowOpen(false)
BX.try("shell.islandRefresh", function()
BX.require("ui.island").refresh()
end)
end)
end,
})
local M = {
ok = raw ~= nil,
error = raw and nil or "native UI failed to initialize",
window = raw,
screen = raw and raw.gui or nil,
ORDER = ORDER,
backend = "lib",
}
local notificationSerial = 0
if not M.ok then
log.error("native menu unavailable: %s", tostring(M.error))
return M
end
ad.setBackend("lib")
local tabs = {}
function M.tab(name)
if tabs[name] then return tabs[name] end
local tab = raw:tab(name)
if not tab then return nil end
local wrapped = ad.wrapTab(tab)
tabs[name] = wrapped
return wrapped
end
function M.onSelect(name, callback)
if type(raw.onSelect) ~= "function" then return false end
return raw:onSelect(name, callback)
end
local function bindIsland()
BX.try("shell.island", function()
local st = BX.require("ui.stats")
if not (st and type(st.anchor) == "function") then return end
raw:setLauncher(function() return (st.anchor()) end)
end)
end
function M.hide()
bindIsland()
if not raw:minimise() then raw:setVisible(false) end
return true
end
function M.reveal()
BX.try("shell.stats", function()
local cfg = BX.require("core.config")
if cfg.SHOW_STATS then
local stats = BX.require("ui.stats")
stats.setDock(nil)
stats.show(true)
end
end)
bindIsland()
local restored = raw:restore()
BX.try("shell.statsResume", function()
local stats = BX.require("ui.stats")
stats.setTapToOpen(false)
stats.setWindowOpen(true)
end)
if restored then
BX.try("shell.islandClear", function()
BX.require("ui.island").clear("closed")
end)
else
BX.try("shell.islandClear", function() BX.require("ui.island").clear("closed") end)
end
return true
end
function M.isVisible()
return raw:isVisible()
end
function M.isHidden()
return not M.isVisible()
end
function M.notify(title, content, duration)
local menuOpen = raw:isVisible()
local stats
local serial
if menuOpen then
stats = BX._loaded["ui.stats"]
if not stats then
local ok, loaded = pcall(BX.require, "ui.stats")
stats = ok and loaded or nil
end
end
local result = native.notify(title, content, { hold = duration })
if menuOpen and stats and stats.setNotificationVisible then
notificationSerial += 1
serial = notificationSerial
task.delay(0.14, function()
if serial == notificationSerial and raw:isVisible() then
stats.setNotificationVisible(true)
end
end)
end
if menuOpen and stats and stats.setWindowOpen then
if not serial then
notificationSerial += 1
serial = notificationSerial
end
task.delay((tonumber(duration) or 4) + 0.10, function()
if serial == notificationSerial and raw:isVisible() then
stats.setNotificationVisible(false)
end
end)
end
return result
end
M.hasNotify = true
function M.restoreLastTab()
if raw:selected() then return true end
raw:select("Home")
return true
end
function M.unload()
local stats = BX._loaded["ui.stats"]
if stats and type(stats.show) == "function" then
BX.try("shell.stats.hide", function() stats.show(false) end)
end
raw:destroy()
return true
end
M.win = raw
log.info("menu built on native BlyxoHub UI")
return M
end)
BX.module("ui.tabs.home", function(BX)
local exec = BX.require("core.exec")
local win  = BX.require("ui.shell")
local log  = BX.require("boot.log").for_module("home")
local M = {}
local INVITE = "https://discord.gg/9KSXyabAYV"
local UPDATES = type(BX.releaseNotes) == "table" and BX.releaseNotes or {
{ "New",      "Native V6 UI — no Rayfield download, cache, or CDN dependency." },
{ "Polished", "Premium motion, Dynamic Island, drag, resize, and touch controls." },
{ "Improved", "One dark-violet visual system with clearer, more readable type." },
{ "Fixed",    "Reliable tabs, profiles, fades, window morphs, and layout." },
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
titleSize = 16,
textSize = 13,
action = { label = "Join Discord", textSize = 14, callback = openDiscord },
})
tab:CreateSection({ name = "Updates" })
local major = tostring(BX.version or "5"):match("^(%d+)") or "5"
tab:CreateListCard({
name = "Latest",
badge = ("V%s Release"):format(major),
rows = UPDATES,
titleSize = 17,
badgeSize = 11,
tagSize = 10,
rowTextSize = 14,
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
local webhookToggle = nil
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
function M.syncWebhookState()
if webhookToggle and webhookToggle.Set then
webhookToggle:Set(hook.isOn())
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
name = "Join Smallest Server",
description = "Hops to the emptiest public server.",
callback = function()
task.spawn(function()
local ok, msg = servers.lowestServer()
say("Servers", ok, msg)
end)
end,
})
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
M.syncWebhookState()
win.notify("Webhook", ok and "Test sent" or tostring(why or "Test failed"), 5)
end,
})
webhookToggle = tab:CreateToggle({
name = "Webhook Logging",
description = "Send delivery events to the configured endpoint.",
value = hook.isOn(),
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
prof.onApply("WebhookOn", function(on)
hook.applyProfileEnabled(on and true or false)
end)
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
webhookStatus, webhookToggle, fpsToggle = nil, nil, nil
BX.try("misc.teardown", function() hook.setEnabled(false, true) end)
log.info("misc tab torn down")
end
return M
end)
BX.module("ui.tabs.config", function(BX)
local prof = BX.require("core.profiles")
local win  = BX.require("ui.shell")
local log  = BX.require("boot.log").for_module("config.tab")
local M = {}
local loadDrop, autoToggle
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
local autoLoadOn = prof.autoLoadName() ~= nil
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
persist = false,
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
if autoLoadOn then
prof.setAutoLoad(name)
if loadDrop and loadDrop.Set then loadDrop:Set(name) end
end
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
persist = false,
options = options(),
currentOption = prof.autoLoadName() or NONE,
callback = function(v)
local name = pick(v)
if name == "" then return end
local ok, msg = prof.load(name)
if ok and autoLoadOn then
local saved, why = prof.setAutoLoad(name)
if saved then
msg = msg .. " · Auto-load on"
else
msg = tostring(why or msg)
end
end
say(ok, msg)
end,
})
autoToggle = tab:CreateToggle({
name = "Auto Load Profile",
persist = false,
description = "Load the selected profile on start.",
value = autoLoadOn,
callback = function(on)
local selected = loadDrop and loadDrop:get() or ""
local name = pick(selected)
if on and name == "" then
autoLoadOn = false
if autoToggle and autoToggle.Set then autoToggle:Set(false) end
say(false, "Pick a profile first")
return
end
autoLoadOn = on and true or false
local ok, msg = prof.setAutoLoad(autoLoadOn and name or "")
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
MAX_PAGES = 2, TRIES = 4,
PAGE_DELAY = 0.55,
CACHE_FOR = 25,
RATE_LIMIT_FOR = 20,
FAILED_FOR = 600,     
FAILED_MAX = 200,     
TP_SETTLE  = 2.5,
}
M.K = K
local searching = false
local rateLimitedUntil = 0
local cachedCandidates, cachedListed, cachedAt = nil, 0, 0
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
local now = os.clock()
if now < rateLimitedUntil then
return nil, ("rate limited - wait %ds"):format(math.ceil(rateLimitedUntil - now))
end
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
if tonumber(status) == 429 then
local wasLimited = rateLimitedUntil > now
rateLimitedUntil = now + K.RATE_LIMIT_FOR
if not wasLimited then
log.warn("server list rate limited; pausing requests for %ds", K.RATE_LIMIT_FOR)
end
return nil, ("rate limited - wait %ds"):format(K.RATE_LIMIT_FOR)
end
if not body then
if tostring(status):find("429", 1, true) then
local wasLimited = rateLimitedUntil > now
rateLimitedUntil = now + K.RATE_LIMIT_FOR
if not wasLimited then
log.warn("server list rate limited; pausing requests for %ds", K.RATE_LIMIT_FOR)
end
return nil, ("rate limited - wait %ds"):format(K.RATE_LIMIT_FOR)
end
log.warn("server list: no response (via %s, %s)", tostring(via), tostring(status))
return nil, "no response"
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
local now = os.clock()
if cachedCandidates and (now - cachedAt) < K.CACHE_FOR then
local copy = table.create(#cachedCandidates)
for i, sv in ipairs(cachedCandidates) do copy[i] = sv end
log.info("candidates: using %ds cache (%d servers)",
math.floor(now - cachedAt), #copy)
return copy, cachedListed
end
local out, cursor = {}, nil
local here = tostring(game.JobId)
local listed, pages, why = 0, 0, nil
for pageN = 1, K.MAX_PAGES do
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
if pageN < K.MAX_PAGES then task.wait(K.PAGE_DELAY) end
end
if pages > 0 then
cachedCandidates, cachedListed, cachedAt = table.clone(out), listed, now
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
local enabledPersisted = false
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
local ENABLE_FILE = "BlyxoHub/webhook-state.txt"
local function rememberEnabled(v)
if not exec.can.files then return end
BX.try("webhook.rememberEnabled", function()
exec.ensureFolder("BlyxoHub")
exec.writeFile(ENABLE_FILE, v and "1" or "0")
end)
end
function M.setEnabled(on, quiet)
enabled = on and true or false
if not quiet then
enabledPersisted = true
rememberEnabled(enabled)
end
log.info("%s (url %s)", enabled and "enabled" or "disabled", M.redactedUrl())
return true
end
function M.applyProfileEnabled(on)
if enabledPersisted then return enabled end
return M.setEnabled(on, true)
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
if not quiet then
remember(v)
if not enabled then M.setEnabled(true) end
end
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
BX.try("webhook.restoreEnabled", function()
if not exec.can.files or not exec.isFile(ENABLE_FILE) then return end
local saved = exec.readFile(ENABLE_FILE)
if saved == "1" then enabledPersisted = true; M.setEnabled(true, true)
elseif saved == "0" then enabledPersisted = true; M.setEnabled(false, true) end
end)
function M.finishProfileRestore()
if not enabledPersisted and M.hasUrl() then
M.setEnabled(true, false)
log.info("enabled from saved webhook URL (legacy profile fallback)")
end
return enabled
end
local function embedFor(e)
local fields = {}
local function add(name, value)
if value == nil or value == "" then return end
fields[#fields + 1] = { name = name, value = tostring(value), inline = true }
end
local mutation = e.mutation or e.mutations
if type(mutation) == "table" then
local out = {}
for key, value in pairs(mutation) do
if value == true then out[#out + 1] = tostring(key)
elseif type(value) == "string" and value ~= "" then out[#out + 1] = value
elseif type(key) == "number" and value ~= nil then out[#out + 1] = tostring(value) end
end
table.sort(out)
mutation = #out > 0 and table.concat(out, ", ") or nil
end
local income = tonumber(e.value)
local weight = tonumber(e.kg)
add("Income", (income and (util.short(income) .. "/s")) or nil)
local luck = tonumber(e.luck)
add("Luck", luck and luck > 0 and util.short(luck) or nil)
add("Weight", weight and weight > 0 and ("%.1f kg"):format(weight) or nil)
add("Rarity", e.rarity ~= "?" and e.rarity or nil)
add("Mutation", mutation)
add("Area", e.areaId)
return {
username = "BlyxoHub",
embeds = { {
title = e.event == "stolen" and "Egg stolen" or "Egg delivered",
description = "**" .. tostring(e.name or "Egg") .. "**",
color = 5814783,
fields = fields,
footer = { text = ("BlyxoHub %s %s"):format(tostring(BX.game or ""), tostring(BX.version or "")) },
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
local queue, draining = {}, false
local function drain()
if draining then return end
draining = true
task.spawn(function()
while #queue > 0 do
local wait = K.MIN_GAP - (os.clock() - lastSend)
if wait > 0 then task.wait(wait) end
local e = table.remove(queue, 1)
lastSend = os.clock()
BX.try("webhook.delivered", function() post(embedFor(e), "delivery") end)
end
draining = false
end)
end
function M.onDelivered(e)
if not enabled or not M.hasUrl() or type(e) ~= "table" then return end
if #queue >= 20 then
stats.dropped = stats.dropped + 1
return
end
queue[#queue + 1] = e
drain()
end
function M.test()
if not M.hasUrl() then return false, "Set a webhook URL first" end
if not enabled then M.setEnabled(true) end
task.spawn(function()
BX.try("webhook.test", function()
post({
username = "BlyxoHub",
embeds = { {
title = "Test",
description = "Webhook is working.",
color = 5814783,
footer = { text = ("BlyxoHub %s %s"):format(tostring(BX.game or ""), tostring(BX.version or "")) },
timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
} },
}, "test")
end)
end)
return true, "Test sent"
end
return M
end)
BX.module("games.rideapet.eggfarm", function(BX)
local svc = BX.require("core.services")
local ch  = BX.require("core.character")
local log = BX.require("boot.log").for_module("rap.farm")
local M = {}
local K = {
PROMPT_RANGE   = 15,
MODEL_MATCH    = 30,
ARRIVE         = 8,
TWEEN_SPEED    = 800,
CARRY_SPEED    = 100,
MAX_DT         = 0.05,
MAX_FRAME      = 0.25,
MAX_DEBT       = 2.0,
SPOOF_HEADROOM = 1.35,
WS_MAX         = 4000,
TWEEN_MIN      = 0.25,
TWEEN_LIFT     = 4,
CRUISE_LIFT    = 70,
TRAVEL_CEILING = 120,
INTERACT_TRIES = 4,
INTERACT_GAP   = 0.35,
GRANT_GRACE    = 1.5,
BREAK_MARGIN   = 4,
DEPOSIT_CONFIRM = 3,
WARP_WAIT       = 6,
CYCLE_GAP       = 0.4,
IDLE_GAP        = 1.5,
MAX_CHASE      = 1600,
UNDER_MAP_DEPTH = 500,
UNDER_MAP_SPEED = 700,
UNDER_MAP_MIN   = 0.25,
}
M.K = K
local RS = svc.ReplicatedStorage
local LocalPlayer = svc.LocalPlayer
local remotes, gameRemotes, activeEggs, eggAssets, eggsData, generalData
local EggPickup, EggPlaced, ToPlot
M.ready = false
local function resolve()
if M.ready then return true end
local ok = BX.try("rap.resolve", function()
remotes     = RS:WaitForChild("Remotes", 10)
gameRemotes = remotes and remotes:WaitForChild("Game", 10)
EggPickup   = gameRemotes and gameRemotes:WaitForChild("EggPickup", 10)
EggPlaced   = gameRemotes and gameRemotes:WaitForChild("EggPlaced", 10)
ToPlot      = gameRemotes and gameRemotes:WaitForChild("TeleportToPlot", 10)
local sd    = RS:WaitForChild("ServerData", 10)
activeEggs  = sd and sd:WaitForChild("ActiveEggs", 10)
eggAssets   = RS:WaitForChild("Assets", 10):WaitForChild("Eggs", 10)
local gd    = RS:WaitForChild("GameData", 10)
eggsData    = require(gd:WaitForChild("Eggs", 10))
generalData = require(gd:WaitForChild("General", 10))
end)
M.ready = ok and activeEggs ~= nil and EggPickup ~= nil and EggPlaced ~= nil
if not M.ready then
log.error("Ride A Pet remotes/data not found - is this the right game?")
end
return M.ready
end
resolve()
M.state, M.status = "idle", "stopped"
M.stats = { collected = 0, deposited = 0, lost = 0, trips = 0, luck = 0, byEgg = {} }
M.target = nil
M.tripped, M.trippedBy = false, nil
local sc = nil
local listeners = {}
function M.onStatus(fn)
if type(fn) == "function" then listeners[#listeners + 1] = fn end
end
local function island()
return BX._loaded["ui.island"] or (BX.try("rap.island", function()
return BX.require("ui.island")
end) and BX._loaded["ui.island"]) or nil
end
local PHASE_PROGRESS = {
move = 0.05, interact = 0.40, carry = 0.48, ["return"] = 0.55, deposit = 0.88,
}
local function setState(state, status, tone, progress)
if state ~= M.state or status ~= M.status then
log.info("[%s] %s", tostring(state), tostring(status))
end
M.state, M.status = state, status
for _, fn in ipairs(listeners) do pcall(fn, state, status) end
local isl = island()
if not isl then return end
local target = M.target
if state == "done" and tone == "good" then
BX.try("rap.island.done", function()
isl.clear("rideapet")
isl.show("rideapet.done", {
title = "Egg delivered!",
sub = tostring(target and target.egg or "Egg") .. " · complete",
tone = "good", hold = 3, pulse = true,
})
end)
return
end
if sc and target and PHASE_PROGRESS[state] then
BX.try("rap.island.set", function()
local shownProgress = progress or PHASE_PROGRESS[state]
isl.set("rideapet", {
title = "Stealing " .. tostring(target.egg),
sub = ("%d%%"):format(math.floor(shownProgress * 100 + 0.5)),
tone = tone or "normal",
progress = shownProgress,
})
end)
return
end
local n = M.stats.deposited or 0
local spec = {
title = ("Auto Steal · %d egg%s"):format(n, n == 1 and "" or "s"),
sub = status,
tone = tone or "normal",
}
BX.try("rap.island.set", function()
if sc then
isl.set("rideapet", spec)
else
isl.clear("rideapet")
spec.hold = 4
isl.show("rideapet", spec)
end
end)
end
M.setState = setState
local baseFlags = (LocalPlayer and LocalPlayer:GetAttribute("TeleportFlags")) or 0
local function armGuard(scope)
if not LocalPlayer then return end
scope:connect(LocalPlayer:GetAttributeChangedSignal("TeleportFlags"), function()
local now = LocalPlayer:GetAttribute("TeleportFlags") or 0
if now > baseFlags then
M.tripped = true
M.trippedBy = ("TeleportFlags rose to %d"):format(now)
end
end)
local reusable = remotes and remotes:FindFirstChild("Reusable")
local msg = reusable and reusable:FindFirstChild("GameMessage")
if msg then
scope:connect(msg.OnClientEvent, function(text)
text = tostring(text or "")
if text:find("Teleport Detected") or text:find("Egg Was Returned") then
M.tripped, M.trippedBy = true, text
end
end)
end
end
local function basket()
return LocalPlayer and LocalPlayer:FindFirstChild("Basket")
end
function M.carrying()
local b = basket()
return b ~= nil and #b:GetChildren() > 0
end
function M.breaksIn()
local b = basket()
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
local function infoFor(name) return eggsData and eggsData[name] end
function M.luckOf(name)
local i = infoFor(name)
return (i and i.Luck) or 0
end
local LUCK_STEPS = {
{ 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
}
function M.formatLuck(n)
n = tonumber(n) or 0
for _, step in ipairs(LUCK_STEPS) do
local div, suffix = step[1], step[2]
if n >= div then
local v = n / div
local s = (v >= 100 or v % 1 == 0)
and ("%d"):format(math.floor(v + 0.5))
or ("%.1f"):format(v)
return s .. suffix
end
end
return ("%d"):format(n)
end
function M.rarityOf(name)
local i = infoFor(name)
return (i and i.Rarity) or "?"
end
function M.previewModel(name)
if not M.ready and not resolve() then return nil end
local asset = eggAssets and eggAssets:FindFirstChild(name)
if not asset then return nil end
local copy = asset:Clone()
local model = Instance.new("Model")
model.Name = name
for _, d in ipairs(copy:GetDescendants()) do
if d:IsA("BasePart") then
if d.Transparency >= 1 then
d:Destroy()
else
d.Anchored = true
d.CanCollide, d.CanTouch, d.CanQuery = false, false, false
d.Parent = model
end
end
end
copy:Destroy()
for _, d in ipairs(model:GetDescendants()) do
if d:IsA("ParticleEmitter") or d:IsA("JointInstance") or d:IsA("Sound")
or d:IsA("LuaSourceContainer") or d:IsA("Light") then
d:Destroy()
end
end
if not model:FindFirstChildWhichIsA("BasePart") then
model:Destroy()
return nil
end
return model
end
local function claimed(rec, name)
if rec:GetAttribute("AdminSpawn") == true then return false end
local list = LocalPlayer and LocalPlayer:GetAttribute("CollectedEggs")
if type(list) ~= "string" or list == "" then return false end
return list:find(name .. ",", 1, true) ~= nil
end
M.claimed = claimed
local function visibleToUs(rec, name)
local private = rec:GetAttribute("PrivateTo")
if private and LocalPlayer and private ~= LocalPlayer.UserId then return false end
return not claimed(rec, name)
end
function M.scan(maxRange)
if not M.ready and not resolve() then return {} end
local hrp = ch.root()
if not hrp then return {} end
local here = hrp.Position
local out = {}
for _, rec in ipairs(activeEggs:GetChildren()) do
local pos, name = rec:GetAttribute("Position"), rec:GetAttribute("Egg")
if typeof(pos) == "Vector3" and name and eggAssets:FindFirstChild(name)
and visibleToUs(rec, name) then
local d = (pos - here).Magnitude
if not maxRange or d <= maxRange then
out[#out + 1] = {
rec = rec, guid = rec.Name, egg = name, pos = pos, dist = d,
luck = M.luckOf(name), rarity = M.rarityOf(name),
weight = rec:GetAttribute("Weight") or 1,
mutation = rec:GetAttribute("Mutation"),
}
end
end
end
table.sort(out, function(a, b)
if a.luck ~= b.luck then return a.luck > b.luck end
return a.dist < b.dist
end)
return out
end
M.pinned = nil
function M.pin(eggName)
M.pinned = eggName
end
M.filter = { minLuck = 0, rarities = nil, mutations = nil }
function M.setFilter(key, value)
M.filter[key] = value
log.info("filter %s = %s", tostring(key), typeof(value) == "table" and ("%d picked"):format(#value) or tostring(value))
end
function M.passes(t)
local f = M.filter
if f.minLuck and f.minLuck > 0 and (t.luck or 0) < f.minLuck then return false end
if f.rarities and #f.rarities > 0 and not table.find(f.rarities, t.rarity) then return false end
if f.mutations and #f.mutations > 0 and not table.find(f.mutations, tostring(t.mutation)) then return false end
return true
end
function M.select(maxRange)
if M.pinned then
local best, bestD
for _, t in ipairs(M.scan()) do
if t.egg == M.pinned and (not bestD or t.dist < bestD) then
best, bestD = t, t.dist
end
end
return best, best == nil and "waiting for a " .. tostring(M.pinned) or nil
end
for _, t in ipairs(M.scan(maxRange)) do
if M.passes(t) then return t end
end
return nil
end
function M.plot()
local plots = workspace:FindFirstChild("Plots")
if not plots or not LocalPlayer then return nil end
for _, p in ipairs(plots:GetChildren()) do
if p:GetAttribute("NestsOwnerLoaded") == LocalPlayer.UserId then return p end
end
return nil
end
function M.freeNest()
local plot = M.plot()
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
function M.canPlant()
return LocalPlayer and LocalPlayer:GetAttribute("NoNest") == true
end
function M.petRoom()
local plot = M.plot()
local pets = plot and plot:FindFirstChild("Pets")
local have = pets and #pets:GetChildren() or 0
local max = tonumber(LocalPlayer and LocalPlayer:GetAttribute("MaxPets")) or 0
return have, max, (max > 0 and have < max)
end
local function bezier(p0, p1, p2, p3, t)
local u = 1 - t
return p0 * (u * u * u)
+ p1 * (3 * u * u * t)
+ p2 * (3 * u * t * t)
+ p3 * (t * t * t)
end
local function arcTable(p0, p1, p2, p3, steps)
local lut, prev, total = { { t = 0, len = 0 } }, p0, 0
for i = 1, steps do
local t = i / steps
local pt = bezier(p0, p1, p2, p3, t)
total = total + (pt - prev).Magnitude
prev = pt
lut[#lut + 1] = { t = t, len = total }
end
return lut, total
end
local function tForLength(lut, want)
if want <= 0 then return 0 end
for i = 2, #lut do
local a, b = lut[i - 1], lut[i]
if b.len >= want then
local span = b.len - a.len
local f = span > 0 and (want - a.len) / span or 0
return a.t + (b.t - a.t) * f
end
end
return 1
end
local function tweenTo(pos, abort, onProgress)
local char, hrp = ch.get(), ch.root()
if not char or not hrp then return false, "no character" end
local from = hrp.CFrame
local goalPos = pos + Vector3.new(0, K.TWEEN_LIFT, 0)
if (goalPos - from.Position).Magnitude <= K.ARRIVE then
return true, (goalPos - from.Position).Magnitude
end
local p0, p3 = from.Position, goalPos
local cruiseY = math.max(p0.Y, p3.Y) + K.CRUISE_LIFT
local p1 = Vector3.new(p0.X, cruiseY, p0.Z)
local p2 = Vector3.new(p3.X, cruiseY, p3.Z)
local lut, length = arcTable(p0, p1, p2, p3, 96)
local speed = K.TWEEN_SPEED
local hum = ch.humanoid()
local savedPS, savedWS
if hum then
savedPS, savedWS = hum.PlatformStand, hum.WalkSpeed
BX.try("rap.fly.ps", function() hum.PlatformStand = true end)
BX.try("rap.fly.ws", function()
hum.WalkSpeed = math.clamp(speed * K.SPOOF_HEADROOM, 16, K.WS_MAX)
end)
end
local function writeAt(travelled)
local t = tForLength(lut, travelled)
local point = bezier(p0, p1, p2, p3, t)
local ahead = bezier(p0, p1, p2, p3,
tForLength(lut, math.min(travelled + 6, length)))
local dir = ahead - point
local cf = (dir.Magnitude > 0.01)
and CFrame.lookAt(point, point + dir.Unit)
or CFrame.new(point)
local c = ch.get()
if not c then return false end
if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
pcall(function() c:PivotTo(cf) end)
local r = ch.root()
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
return true
end
local travelled, debt, stopped = 0, 0, nil
local lastT = os.clock()
local startedAt = lastT
local ceiling = math.min(length / speed + 4, K.TRAVEL_CEILING)
local biggestWrite = 0
local lastReport = 0
while travelled < length do
if onProgress and os.clock() - lastReport > 0.15 then
lastReport = os.clock()
pcall(onProgress, travelled / length)
end
if M.tripped then stopped = "detection tripped" break end
if abort and abort() then stopped = "aborted" break end
if os.clock() - startedAt > ceiling then stopped = "flight timed out" break end
if ch.get() ~= char then stopped = "respawned" break end
svc.RunService.Heartbeat:Wait()
local now = os.clock()
local raw = now - lastT
lastT = now
debt = math.min(debt + raw, K.MAX_DEBT)
local frameDt = math.min(debt, K.MAX_FRAME)
debt = debt - frameDt
local subSteps = math.max(1, math.ceil(frameDt / K.MAX_DT))
local dt = frameDt / subSteps
for _ = 1, subSteps do
local step = dt * speed
if step > biggestWrite then biggestWrite = step end
travelled = math.min(travelled + step, length)
if not writeAt(travelled) then stopped = "lost character" break end
if travelled >= length then break end
end
if stopped then break end
end
if hum and hum.Parent then
BX.try("rap.fly.restore", function()
hum.WalkSpeed = savedWS or 16
hum.PlatformStand = savedPS or false
end)
end
if stopped then return false, stopped end
local now = ch.root()
local gap = now and (pos - now.Position).Magnitude or math.huge
log.trace("flight %.0f studs at %.0f studs/s, biggest write %.1f studs",
length, speed, biggestWrite)
if gap <= K.PROMPT_RANGE then return true, gap end
return false, ("ended %d studs short"):format(math.floor(gap))
end
M.tweenTo = tweenTo
local function tweenUnderMap(stopWhen)
local char, hrp = ch.get(), ch.root()
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
local plot = M.plot()
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
local hum = ch.humanoid()
local conn = driver.Changed:Connect(function(cf)
local c = ch.get()
if not c then return end
pcall(function() c:PivotTo(cf) end)
local r = ch.root()
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
end)
if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) end
local tween = svc.TweenService:Create(
driver,
TweenInfo.new(duration, Enum.EasingStyle.Linear),
{ Value = goal })
tween:Play()
local deadline = os.clock() + duration + 2
local aborted
while os.clock() < deadline do
if M.tripped then aborted = "detection tripped" break end
if stopWhen and stopWhen() then aborted = "aborted" break end
if tween.PlaybackState ~= Enum.PlaybackState.Playing then break end
svc.RunService.Heartbeat:Wait()
end
tween:Cancel()
conn:Disconnect()
driver:Destroy()
if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
if aborted then return false, aborted end
local now = ch.root()
if not now then return false, "root lost" end
log.trace("under-map drop of %.0f studs in %.1fs, ended at Y %.1f", drop, duration, now.Position.Y)
return math.abs(now.Position.Y - targetY) <= 8,
("under-map return ended at Y %.1f"):format(now.Position.Y)
end
M.tweenUnderMap = tweenUnderMap
local function promptFirer()
local ok, fn = pcall(function() return fireproximityprompt end)
if ok and type(fn) == "function" then return fn end
ok, fn = pcall(function() return getgenv().fireproximityprompt end)
if ok and type(fn) == "function" then return fn end
return nil
end
local function promptFor(target)
local folder = workspace:FindFirstChild("RenderedEggs")
if not folder then return nil end
local best, bestGap, bestPos
for _, m in ipairs(folder:GetChildren()) do
if m.Name == target.egg and m:IsA("Model") then
local ok, pivot = pcall(function() return m:GetPivot().Position end)
if ok then
local gap = (pivot - target.pos).Magnitude
if gap <= K.MODEL_MATCH and (not bestGap or gap < bestGap) then
local pr = m:FindFirstChildWhichIsA("ProximityPrompt", true)
if pr then
local host = pr.Parent
local hostPos = pivot
if host then
if host:IsA("BasePart") then hostPos = host.Position
elseif host:IsA("Attachment") then hostPos = host.WorldPosition end
end
best, bestGap, bestPos = pr, gap, hostPos
end
end
end
end
end
return best, bestPos
end
local function interact(target)
local prompt, ppos = promptFor(target)
if not prompt then return false, "no prompt rendered for that egg" end
local fire = promptFirer()
local hold
if ppos then
local hrp = ch.root()
if hrp and (ppos - hrp.Position).Magnitude > (K.PROMPT_RANGE - 4) then
tweenTo(ppos)
end
hold = CFrame.new(ppos + Vector3.new(0, K.TWEEN_LIFT, 0))
end
for _ = 1, K.INTERACT_TRIES do
if M.tripped then return false, "detection tripped" end
if not target.rec.Parent and not M.carrying() then
return false, "taken by someone else"
end
if hold then
local c = ch.get()
if c then pcall(function() c:PivotTo(hold) end) end
local r = ch.root()
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
end
if fire then
pcall(fire, prompt)
else
EggPickup:FireServer(target.guid)
end
local deadline = os.clock() + K.INTERACT_GAP
while os.clock() < deadline do
if M.carrying() then return true end
if hold then
local c = ch.get()
if c then pcall(function() c:PivotTo(hold) end) end
end
task.wait(0.05)
end
end
local deadline = os.clock() + K.GRANT_GRACE
while os.clock() < deadline do
if M.carrying() then return true end
task.wait(0.05)
end
return false, target.rec.Parent and "prompt did not take" or "taken by someone else"
end
local function returnToPlot()
local plot = M.plot()
if not plot then return false, "plot not found" end
local base = plot:FindFirstChild("Baseplate")
local nest = M.freeNest()
local aim
if nest then
local ok, pivot = pcall(function() return nest:GetPivot().Position end)
aim = ok and pivot or nil
end
if not aim then aim = base and base.Position end
if not aim then return false, "no landing spot on the plot" end
local here = ch.root()
if here and (aim - here.Position).Magnitude <= K.ARRIVE then return true, 0 end
if not M.carrying() and ToPlot and base then
ToPlot:FireServer()
local t0 = os.clock()
while os.clock() - t0 < K.WARP_WAIT do
task.wait(0.15)
local r = ch.root()
if r and (r.Position - base.Position).Magnitude < 120 then break end
end
local r = ch.root()
if r and (aim - r.Position).Magnitude <= K.ARRIVE then return true, 0 end
end
local wasSpeed = K.TWEEN_SPEED
K.TWEEN_SPEED = K.CARRY_SPEED
local ok, why = tweenTo(aim)
K.TWEEN_SPEED = wasSpeed
return ok, why
end
M.returnToPlot = returnToPlot
function M.warpHome()
if not resolve() or not ToPlot then return false end
ToPlot:FireServer()
local t0 = os.clock()
while os.clock() - t0 < K.WARP_WAIT do
task.wait(0.15)
local plot = M.plot()
local base = plot and plot:FindFirstChild("Baseplate")
local hrp = ch.root()
if base and hrp and (hrp.Position - base.Position).Magnitude < 120 then
return true
end
end
return true
end
local function equipEgg()
local char, hum = ch.get(), ch.humanoid()
if not char or not hum then return false end
for _, c in ipairs(char:GetChildren()) do
if c:IsA("Tool") and (c:HasTag("Egg") or eggAssets:FindFirstChild(c.Name)) then
return true
end
end
local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
if not bp then return false end
for _, c in ipairs(bp:GetChildren()) do
if c:IsA("Tool") and (c:HasTag("Egg") or eggAssets:FindFirstChild(c.Name)) then
BX.try("rap.equip", function() hum:EquipTool(c) end)
local deadline = os.clock() + 1
while os.clock() < deadline do
if c.Parent == char then return true end
svc.RunService.Heartbeat:Wait()
end
return c.Parent == char
end
end
return true
end
local function plotEggCount()
local plot = M.plot()
local eggs = plot and plot:FindFirstChild("Eggs")
return eggs and #eggs:GetChildren() or 0
end
local function deposit()
if not M.carrying() then return false, "nothing to deposit" end
local nest, plot = M.freeNest()
if not plot then return false, "plot not found" end
local plotEggs = plot:FindFirstChild("Eggs")
local was = plotEggs and #plotEggs:GetChildren() or 0
local b = basket()
local carriedBefore = b and #b:GetChildren() or 0
equipEgg()
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
elseif M.canPlant() then
local hrp = ch.root()
local base = plot:FindFirstChild("Baseplate")
local spot = (hrp and hrp.Position) or (base and base.Position)
how = "planted"
EggPlaced:FireServer({ PlantPosition = spot })
else
return false, "every nest is full - unlock one or hatch what is on the plot"
end
local deadline = os.clock() + K.DEPOSIT_CONFIRM
while os.clock() < deadline do
local landed = plotEggs and #plotEggs:GetChildren() > was
local taken = nest and nest:GetAttribute("Occupied") == true
if landed or taken then return true, how end
task.wait(0.05)
end
b = basket()
if b and #b:GetChildren() < carriedBefore then
return false, M.tripped
and ("egg taken back: " .. tostring(M.trippedBy))
or "egg left the basket but never reached the plot"
end
return false, "placement not accepted"
end
M.deposit = deposit
function M.trip(maxRange)
if not M.ready and not resolve() then
return false, { reason = "game data not found", fatal = true }
end
if M.tripped then
setState("stopped", "stopped: " .. tostring(M.trippedBy), "bad")
return false, { reason = M.trippedBy, fatal = true }
end
if M.carrying() then
setState("return", "carrying already - heading home", "warn")
returnToPlot()
local ok, how = deposit()
if not ok then return false, { reason = how } end
M.stats.deposited = M.stats.deposited + 1
end
while M.holdBy and sc do
setState("idle", "waiting for " .. tostring(M.holdBy))
task.wait(0.2)
end
setState("scan", "scanning the board")
local target, why = M.select(maxRange)
if not target then
setState("idle", why or "no eggs in range - waiting for restock")
return false, { reason = why or "no eggs in range", idle = true }
end
local pinnedRun = (M.pinned ~= nil) and (M.pinned == target.egg)
M.target = target
M.stats.trips = M.stats.trips + 1
setState("move", ("moving to %s · %s luck · %d studs"):format(
target.egg, M.formatLuck(target.luck), math.floor(target.dist)))
local gone = function() return not target.rec.Parent and not M.carrying() end
local moving = M.status
local arrived, why = tweenTo(target.pos, gone, function(f)
setState("move", moving, nil,
PHASE_PROGRESS.move + (PHASE_PROGRESS.interact - PHASE_PROGRESS.move) * f)
end)
if not arrived then
setState("scan", "approach failed: " .. tostring(why))
return false, { reason = "approach failed: " .. tostring(why) }
end
setState("interact", "picking up " .. target.egg)
local plotEggsBefore = plotEggCount()
local got, err = interact(target)
if not got then
setState("scan", "missed: " .. tostring(err))
return false, { reason = err }
end
if pinnedRun then M.pinnedSpent = true M.pinned = nil end
local left = M.breaksIn()
local since = os.clock()
while not left and os.clock() - since < 2 do
task.wait(0.05)
left = M.breaksIn()
end
M.stats.collected = (M.stats.collected or 0) + 1
M.stats.luck = M.stats.luck + target.luck
M.stats.byEgg[target.egg] = (M.stats.byEgg[target.egg] or 0) + 1
BX.try("rap.webhook.stolen", function()
local hook = BX._loaded["features.misc.webhook"]
if hook and hook.onDelivered then
hook.onDelivered({
event = "stolen", name = target.egg, rarity = target.rarity,
mutation = target.mutation, luck = target.luck,
})
end
end)
setState("carry", ("carrying %s · %.0fs to deposit"):format(target.egg, left or 0), "warn")
local function banked(how)
M.stats.deposited = M.stats.deposited + 1
setState("done", ("deposited %s (%s)"):format(target.egg, how), "good")
log.info("deposited %s luck=%s from %d studs (%s)",
target.egg, M.formatLuck(target.luck), math.floor(target.dist), how)
BX.try("rap.webhook", function()
local hook = BX._loaded["features.misc.webhook"]
if hook and hook.onDelivered then
hook.onDelivered({
name = target.egg, rarity = target.rarity, mutation = target.mutation,
luck = target.luck, how = how,
})
end
end)
if pinnedRun then M.pinned = nil end
return true, {
egg = target.egg, luck = target.luck,
dist = target.dist, how = how, pinned = pinnedRun,
}
end
local function landedOnPlot(wait)
local deadline = os.clock() + (wait or 0)
repeat
if plotEggCount() > plotEggsBefore then return true end
if os.clock() >= deadline then return false end
task.wait(0.1)
until false
end
local pets, maxPets, room = M.petRoom()
if not room then
log.warn("plot at %d/%d pets - going home to try anyway", pets, maxPets)
end
setState("return", "got it · dropping below the map")
local under, underWhy = tweenUnderMap(function() return not M.carrying() end)
local home = false
if under then
setState("return", "teleporting home")
home = M.warpHome()
if not home then log.warn("plot warp from under the map did not take") end
else
log.warn("under-map drop failed: %s", tostring(underWhy))
end
if not home then
if not M.carrying() then
if landedOnPlot(1.5) then return banked("auto-placed") end
M.stats.lost = M.stats.lost + 1
setState("scan", "egg lost on the way down", "bad")
return false, { reason = "egg lost during the return" }
end
left = M.breaksIn()
local hrp, plot = ch.root(), M.plot()
local base = plot and plot:FindFirstChild("Baseplate")
if left and hrp and base then
local ride = (base.Position - hrp.Position).Magnitude / K.CARRY_SPEED
if left < ride + K.BREAK_MARGIN then
M.stats.lost = M.stats.lost + 1
setState("scan", ("too far to bank it (%.0fs left, %.0fs ride)"):format(left, ride), "bad")
return false, { reason = "not enough break time to get home" }
end
end
setState("return", ("flying home · %.0fs left"):format(M.breaksIn() or 0))
returnToPlot()
end
if landedOnPlot(0) then return banked("auto-placed") end
if not M.carrying() then
if landedOnPlot(2) then return banked("auto-placed") end
M.stats.lost = M.stats.lost + 1
setState("scan", "egg gone before deposit", "bad")
return false, { reason = "egg gone before deposit" }
end
left = M.breaksIn()
if left and left <= 0 then
M.stats.lost = M.stats.lost + 1
setState("scan", "egg broke before deposit", "bad")
return false, { reason = "egg broke in transit" }
end
setState("deposit", "depositing " .. target.egg)
local placed, how = deposit()
if not placed then
if landedOnPlot(2) then return banked("auto-placed") end
M.stats.lost = M.stats.lost + 1
setState("scan", "deposit failed: " .. tostring(how), "bad")
return false, { reason = how }
end
return banked(how)
end
function M.isRunning() return sc ~= nil end
function M.start(opts)
if sc then return false, "already running" end
if not resolve() then return false, "game data not found" end
opts = opts or {}
sc = BX.scope("games.rideapet.eggfarm")
armGuard(sc)
M.pinnedSpent = false
setState("scan", "starting")
sc:spawn("loop", function()
while sc and sc:alive() do
local ok, info = M.trip(opts.maxRange)
if opts.onResult then pcall(opts.onResult, ok, info) end
if not ok and info and info.fatal then
log.error("stopping: %s", tostring(info.reason))
break
end
if (ok and info and info.pinned) or M.pinnedSpent then
local egg = (info and info.egg) or (M.target and M.target.egg) or M.pinned
log.info("selected egg done (%s, %s) - stopping", tostring(egg), ok and "deposited" or "not deposited")
setState("done", ((ok and "got %s" or "%s taken but not banked") .. " · stopped"):format(tostring(egg)), ok and "good" or "warn")
M.pinnedSpent = false
break
end
task.wait((info and info.idle) and K.IDLE_GAP or K.CYCLE_GAP)
end
M.stop()
end)
return true
end
function M.stop()
local had = sc
if sc then
local s = sc
sc = nil
BX.try("rap.farm.stop", function() s:destroy() end)
end
if had then
setState("idle", M.tripped and ("stopped: " .. tostring(M.trippedBy)) or "stopped")
local isl = island()
if isl and isl.clear then BX.try("rap.island.clear", function() isl.clear("rideapet") end) end
end
return true
end
BX.onTeardown("games.rideapet.eggfarm", function() M.stop() end)
return M
end)
BX.module("games.rideapet.hatch", function(BX)
local svc  = BX.require("core.services")
local ch   = BX.require("core.character")
local log  = BX.require("boot.log").for_module("rap.hatch")
local farm = BX.require("games.rideapet.eggfarm")
local M = { enabled = false, stats = { hatched = 0, asked = 0 } }
local K = {
POLL      = 3,     
REACH     = 6,     
WALK_WAIT = 6,     
HATCH_WAIT = 1.5,  
HOME_RANGE = 250,  
}
M.K = K
local RS = svc.ReplicatedStorage
local LocalPlayer = svc.LocalPlayer
local Hatch, eggsData, generalData, dayNight
local function resolve()
if Hatch then return true end
return BX.try("rap.hatch.resolve", function()
Hatch = RS:WaitForChild("Remotes", 10):WaitForChild("Game", 10):WaitForChild("Hatch", 10)
local gd = RS:WaitForChild("GameData", 10)
eggsData    = require(gd:WaitForChild("Eggs", 10))
generalData = require(gd:WaitForChild("General", 10))
pcall(function()
dayNight = require(RS:WaitForChild("GameServices", 5):WaitForChild("DayNight", 5))
end)
end) and Hatch ~= nil
end
local function grown(egg)
if not egg:IsA("Model") or not egg.PrimaryPart then return false end
if not egg:GetAttribute("EggKey") or egg:HasTag("Hatching") then return false end
local data = egg:FindFirstChild("EggData")
local placeTime = data and data:FindFirstChild("PlaceTime")
local weight = data and data:FindFirstChild("Weight")
local info = eggsData[egg.Name]
if not info or not placeTime or placeTime.Value <= 0 then return false end
local elapsed
if egg:GetAttribute("FlatGrow") == true or not dayNight then
elapsed = workspace:GetServerTimeNow() - placeTime.Value
else
local ok, v = pcall(dayNight.GrowthElapsed, placeTime.Value)
elapsed = ok and v or (workspace:GetServerTimeNow() - placeTime.Value)
end
local need = info.GrowthTime or 0
pcall(function() need = generalData.GrowthTimeFor(info.GrowthTime, weight and weight.Value or 1) end)
return elapsed >= need
end
function M.grownEggs()
if not resolve() then return {} end
local plot = farm.plot()
local folder = plot and plot:FindFirstChild("Eggs")
if not folder then return {} end
local out = {}
for _, egg in ipairs(folder:GetChildren()) do
if grown(egg) then out[#out + 1] = egg end
end
return out
end
local function walkTo(pos)
local hum, hrp = ch.humanoid(), ch.root()
if not hum or not hrp then return false end
hum:MoveTo(pos)
local deadline = os.clock() + K.WALK_WAIT
while os.clock() < deadline do
local r = ch.root()
if not r then return false end
if ((r.Position - pos) * Vector3.new(1, 0, 1)).Magnitude <= K.REACH then return true end
task.wait(0.1)
end
return false
end
local function hatchOne(egg)
local part = egg.PrimaryPart
if not part then return false, "no part" end
local pos = part.Position
local r = ch.root()
if r and ((r.Position - pos) * Vector3.new(1, 0, 1)).Magnitude > K.REACH then
if not walkTo(pos) then return false, "could not reach it" end
end
local key = egg:GetAttribute("EggKey")
M.stats.asked = M.stats.asked + 1
Hatch:FireServer({ EggKey = key })
local deadline = os.clock() + K.HATCH_WAIT
while os.clock() < deadline do
if not egg.Parent or egg:HasTag("Hatching") then
M.stats.hatched = M.stats.hatched + 1
return true
end
task.wait(0.1)
end
return false, "no answer"
end
local busy = false
local function pass()
if busy or not M.enabled then return end
local eggs = M.grownEggs()
if #eggs == 0 then return end
if farm.isRunning() then
local st = farm.state
if st ~= "idle" and st ~= "done" and st ~= "blocked" then return end
end
if farm.carrying() then return end
local plot = farm.plot()
local base = plot and plot:FindFirstChild("Baseplate")
local hrp = ch.root()
if not base or not hrp then return end
busy = true
farm.holdBy = "Auto Hatch"
BX.try("rap.hatch.pass", function()
if (hrp.Position - base.Position).Magnitude > K.HOME_RANGE then
if not farm.warpHome() then return end
task.wait(0.5)
end
for _, egg in ipairs(eggs) do
if not M.enabled or not egg.Parent then break end
local ok, why = hatchOne(egg)
log.info("hatch %s: %s", egg.Name, ok and "ok" or tostring(why))
task.wait(0.3)
end
end)
farm.holdBy = nil
busy = false
end
local sc
function M.setEnabled(on)
on = on and true or false
if on == M.enabled then return end
M.enabled = on
if on then
if not resolve() then
M.enabled = false
log.warn("hatch remote not found")
return
end
sc = BX.scope("games.rideapet.hatch")
sc:spawn("poll", function()
while sc and sc:alive() do
pass()
task.wait(K.POLL)
end
end)
log.info("on")
else
if sc then local s = sc sc = nil pcall(function() s:destroy() end) end
if farm.holdBy == "Auto Hatch" then farm.holdBy = nil end
busy = false
log.info("off")
end
end
farm.onStatus(function(state)
if M.enabled and (state == "done" or state == "blocked") then
task.spawn(pass)
end
end)
BX.onTeardown("games.rideapet.hatch", function() M.setEnabled(false) end)
return M
end)
BX.module("games.rideapet.tab", function(BX)
local farm = BX.require("games.rideapet.eggfarm")
local win  = BX.require("ui.shell")
local log  = BX.require("boot.log").for_module("rap.tab")
local M = {}
local K = {
SYNC = 1.0,
MAX_EGGS = 12,
}
M.K = K
local sc = nil
local dropdown
local labelToEgg = {}
local function buildOptions()
local board = farm.scan()
local order, seen = {}, {}
for _, t in ipairs(board) do
local e = seen[t.egg]
if e then
e.n = e.n + 1
if t.dist < e.dist then e.dist = t.dist end
else
seen[t.egg] = { egg = t.egg, luck = t.luck, n = 1, dist = t.dist }
order[#order + 1] = seen[t.egg]
end
end
local options, map = {}, {}
for i = 1, math.min(#order, K.MAX_EGGS) do
local e = order[i]
local label = ("%s  ·  %s"):format(e.egg, farm.formatLuck(e.luck))
if e.n > 1 then label = label .. ("  (x%d)"):format(e.n) end
options[#options + 1] = label
map[label] = e.egg
end
if #options == 0 then options[1] = "No eggs found" end
return options, map
end
local refreshing = false
local function refresh(reason)
if refreshing or not dropdown then return end
refreshing = true
local options, map = buildOptions()
local ok = BX.try("rap.tab.refresh", function()
labelToEgg = map
dropdown:Refresh(options, true)
end)
refreshing = false
log.info("refresh (%s): %d eggs%s", tostring(reason), #options, ok and "" or " FAILED")
if reason == "button" then
win.notify("Auto Steal", ("%d kind%s on the board"):format(
#options, #options == 1 and "" or "s"), 3)
end
return ok
end
M.refresh = refresh
function M.build(tab)
if not tab then return M end
tab:CreateSection({ name = "Stealing" })
local options, map = buildOptions()
labelToEgg = map
dropdown = tab:CreateDropdown({
name = "Target Egg",
persist = false,
description = "Highest luck first. Leave it to take the best each trip.",
preview = function(picked) return farm.previewModel(labelToEgg[picked]) end,
metaTitle = "BEST EGG",
meta = function(picked)
local egg = labelToEgg[picked]
if not egg then return nil end
return {
name = egg,
rarity = farm.rarityOf(egg),
value = farm.formatLuck(farm.luckOf(egg)),
}
end,
options = options,
currentOption = nil,
callback = function(value)
local picked = type(value) == "table" and value[1] or value
local egg = labelToEgg[picked]
farm.pin(egg)
log.info("target: %s (egg=%s)", tostring(picked), tostring(egg))
end,
})
tab:CreateButton({
name = "Refresh Eggs",
callback = function() refresh("button") end,
})
local function startFarm()
if farm.isRunning() then
win.notify("Auto Steal", "Already running", 3)
return
end
local pets, maxPets, room = farm.petRoom()
if not room then
win.notify("Auto Steal",
("Plot is full (%d/%d pets) - eggs will be collected but not placed.")
:format(pets, maxPets), 6)
end
BX.try("rap.tab.start", function()
farm.start({
onResult = function(ok, info)
if not ok and info and info.fatal then
win.notify("Auto Steal", tostring(info.reason), 8)
return
end
if ok and info and info.pinned then
win.notify("Auto Steal", ("Got %s - stopped."):format(
tostring(info.egg)), 5)
end
end,
})
end)
end
function M.setFarm(on)
if on then startFarm() else farm.stop() end
end
tab:CreateButton({
name = "Auto Steal",
description = "Takes the egg, then places it if your plot has room. Pick a target above and it stops after that one; leave it to keep going.",
callback = startFarm,
})
tab:CreateButton({
name = "Go to My Plot",
description = "Uses the game's own plot teleport.",
callback = function()
BX.try("rap.tab.home", function()
local ok = farm.warpHome()
win.notify("Auto Steal", ok and "At your plot." or "Could not reach the plot.", 3)
end)
end,
})
sc = BX.scope("games.rideapet.tab")
farm.onStatus(function(state)
if state == "done" and not farm.pinned and dropdown and dropdown:get() ~= nil then
BX.try("rap.tab.unpin", function() dropdown:set(nil) end)
end
end)
log.info("Ride A Pet main tab built (%d eggs listed)", #options)
return M
end
function M.teardown()
if sc then sc:destroy() sc = nil end
BX.try("rap.tab.teardownFarm", farm.stop)
dropdown = nil
labelToEgg = {}
log.info("Ride A Pet main tab torn down")
end
return M
end)
BX.module("games.rideapet.main", function(BX)
local M = {}
local logmod = BX.require("boot.log")
logmod.level = BX.require("core.config").LOG_LEVEL
local log = logmod.for_module("rap.main")
local splash = {
step = function() end,
fail = function() end,
done = function() end,
}
local failed = false
local function stage(name, required, fn)
if failed then return false end
local ok = BX.try("rap.boot." .. name, fn)
if not ok then
log.error("stage %q failed", name)
if required then
failed = true
BX.try("rap.boot.fail", function()
splash.fail(("Failed to initialize  |  Stage: %s"):format(name))
end)
end
end
return ok
end
local win = nil
BX.releaseNotes = {
{ "New",      "Ride A Pet support with a dedicated egg preview and target selector." },
{ "Added",    "Vampauth Farm access with Get Key, saved keys, and expiry checks." },
{ "Improved", "Auto Steal is now a clean action button, with the full Home, Main, Farm, Misc, and Config layout." },
{ "Fixed",    "Ride A Pet branding, FPS startup performance, tab loading, and mobile spacing." },
}
local function buildFarmAccess(tab)
local exec = BX.require("core.exec")
local auth = BX.require("auth.vampauth")
local KEY_FILE = "BlyxoHub/vampauth_rideapet_farm_key.txt"
local gate, content = {}, {}
local keyValue, keyLink = "", nil
local open, checking = false, false
local function show(list, visible)
for _, handle in ipairs(list) do
BX.try("rideapet.farmAccess.visible", function()
handle:setVisible(visible)
end)
end
end
local function status(text, announce)
text = tostring(text)
win.notify("Farm access", text, announce and 5 or 4)
end
local function saveKey(key)
BX.try("rideapet.farmAccess.save", function()
exec.ensureFolder("BlyxoHub")
exec.writeFile(KEY_FILE, key)
end)
end
local function savedKey()
local value
BX.try("rideapet.farmAccess.read", function()
if exec.isFile(KEY_FILE) then value = exec.readFile(KEY_FILE) end
end)
value = value and tostring(value):gsub("^%s+", ""):gsub("%s+$", "") or ""
return value ~= "" and value or nil
end
local function unlock()
open = true
show(gate, false)
show(content, true)
end
local function check(key, quiet)
if checking then return nil end
checking = true
if not quiet then status("Checking key...") end
local ok, valid = pcall(auth.verifyKey, key)
checking = false
if not ok then return nil end
return valid
end
gate[#gate + 1] = tab:CreateSection({ name = "Farm Access" })
gate[#gate + 1] = tab:CreateInput({
name = "Farm Key",
placeholder = "KEY_...",
callback = function(value) keyValue = tostring(value or "") end,
})
gate[#gate + 1] = tab:CreateButton({
name = "Get Key",
callback = function()
task.spawn(function()
local ok, made, link, copied = pcall(auth.copyLink)
if ok and made and type(link) == "string" and link ~= "" then
if copied then
status("Key link copied - paste it in your browser.", true)
else
if keyLink and keyLink.Set then keyLink:Set(link) end
if keyLink then keyLink:setVisible(true) end
status("Key link is ready below.", true)
end
else
status(auth.lastMessage() or "Could not create the key link.", true)
end
end)
end,
})
keyLink = tab:CreateInput({
name = "Key Link",
placeholder = "Appears here if copy is unavailable",
})
keyLink:setVisible(false)
gate[#gate + 1] = keyLink
gate[#gate + 1] = tab:CreateButton({
name = "Unlock Farm",
callback = function()
task.spawn(function()
local key = keyValue:gsub("^%s+", ""):gsub("%s+$", "")
if key == "" then status("Paste a key first.", true) return end
local valid = check(key)
if valid then
saveKey(key)
status("Farm unlocked.", true)
unlock()
elseif valid == nil then
status(auth.lastMessage() or "Could not reach the key server - try again.", true)
else
status(auth.lastMessage() or "Invalid or expired key.", true)
end
end)
end,
})
local farm = BX.require("games.rideapet.eggfarm")
local hatch = BX.require("games.rideapet.hatch")
content[#content + 1] = tab:CreateSection({ name = "Targets" })
local LUCK_STEPS = {
{ "Any", 0 }, { "1K+", 1e3 }, { "10K+", 1e4 }, { "100K+", 1e5 },
{ "1M+", 1e6 }, { "10M+", 1e7 }, { "100M+", 1e8 }, { "1B+", 1e9 },
{ "100B+", 1e11 }, { "1T+", 1e12 },
}
local luckLabels, luckValues = {}, {}
for _, step in ipairs(LUCK_STEPS) do
luckLabels[#luckLabels + 1] = step[1]
luckValues[step[1]] = step[2]
end
content[#content + 1] = tab:CreateDropdown({
name = "Min Luck",
description = "Skip eggs worth less than this.",
options = luckLabels,
flag = "RideAPetMinLuck",
callback = function(picked)
picked = type(picked) == "table" and picked[1] or picked
farm.setFilter("minLuck", luckValues[picked] or 0)
end,
})
local RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal" }
content[#content + 1] = tab:CreateDropdown({
name = "Rarities",
description = "Nothing picked means every rarity.",
multi = true,
options = RARITIES,
flag = "RideAPetRarities",
callback = function(picked)
if type(picked) ~= "table" then picked = picked and { picked } or {} end
farm.setFilter("rarities", #picked > 0 and picked or nil)
end,
})
local MUTATIONS = { "Diamond", "Eternal", "Gold", "Rage", "Rainbow", "Shocked", "Void", "Volted" }
content[#content + 1] = tab:CreateDropdown({
name = "Mutations",
description = "Only eggs with one of these. Nothing picked means any egg, mutated or not.",
multi = true,
options = MUTATIONS,
flag = "RideAPetMutations",
callback = function(picked)
if type(picked) ~= "table" then picked = picked and { picked } or {} end
farm.setFilter("mutations", #picked > 0 and picked or nil)
end,
})
content[#content + 1] = tab:CreateSection({ name = "Farming" })
content[#content + 1] = tab:CreateToggle({
name = "Auto Farm",
description = "Same loop as Auto Steal on Main, with the filters above applied.",
value = false,
flag = "RideAPetAutoFarm",
callback = function(on)
local tabmod = BX._loaded["games.rideapet.tab"]
if tabmod and type(tabmod.setFarm) == "function" then
tabmod.setFarm(on == true)
elseif on then
farm.start()
else
farm.stop()
end
end,
})
content[#content + 1] = tab:CreateSection({ name = "Plot" })
content[#content + 1] = tab:CreateToggle({
name = "Auto Hatch",
description = "Hatch grown eggs on your plot whenever you are free - between trips, or right away if Auto Steal is off.",
value = false,
flag = "RideAPetAutoHatch",
callback = function(on) hatch.setEnabled(on == true) end,
})
show(content, false)
task.spawn(function()
local key = savedKey()
if not key then return end
keyValue = key
status("Checking your saved key...")
if check(key, true) then
unlock()
else
status("Your saved key expired - get a new one.")
end
end)
task.spawn(function()
while BX.alive() do
task.wait(600)
if open and keyValue ~= "" and not checking then
if check(keyValue, true) == false then
open = false
show(content, false)
show(gate, true)
status("Your key expired - get a new one.")
end
end
end
end)
end
function M.boot()
stage("services", true, function() BX.require("core.services") end)
if failed then return M end
stage("exec", false, function() BX.require("core.exec") end)
stage("device", false, function() BX.require("core.device") end)
stage("state", false, function() BX.require("core.state") end)
stage("util", false, function() BX.require("core.util") end)
stage("character", false, function() BX.require("core.character") end)
stage("splash", false, function()
local real = BX.require("ui.splash")
if real then splash = real end
end)
splash.step("Reading the egg board...", 0.15)
stage("eggfarm", false, function()
local farm = BX.require("games.rideapet.eggfarm")
if not farm.ready then
log.warn("Ride A Pet data not found - the Farm tab will be inert")
end
end)
splash.step("Building interface...", 0.35)
stage("shell", true, function()
win = BX.require("ui.shell")
if not win.ok then error(tostring(win.error or "menu unavailable"), 0) end
end)
if failed then return M end
local function breathe()
BX.try("rap.boot.breathe", function() task.wait() end)
end
splash.step(nil, 0.50)
stage("home tab", false, function()
BX.require("ui.tabs.home").build(win.tab("Home"))
end)
breathe()
splash.step(nil, 0.65)
stage("main tab", false, function()
BX.require("games.rideapet.tab").build(win.tab("Main"))
end)
breathe()
splash.step(nil, 0.72)
stage("farm tab", false, function()
buildFarmAccess(win.tab("Farm"))
end)
breathe()
splash.step(nil, 0.84)
stage("misc tab", false, function()
BX.require("ui.tabs.misc").build(win.tab("Misc"))
end)
breathe()
splash.step(nil, 0.90)
stage("config tab", false, function()
BX.require("ui.tabs.config").build(win.tab("Config"))
end)
breathe()
stage("fps", false, function()
local cfg = BX.require("core.config")
if cfg.AUTO_FPS_BOOST then
BX.require("features.fps").arm()
end
end)
BX.onTeardown("ui", function()
BX.try("rap.teardown.stats", function() BX.require("ui.stats").show(false) end)
BX.try("rap.teardown.window", function() win.unload() end)
end)
BX.onTeardown("tabs", function()
local mod = BX._loaded["games.rideapet.tab"]
if mod and type(mod.teardown) == "function" then
BX.try("rap.teardown.tab", mod.teardown)
end
end)
stage("last tab", false, function() win.restoreLastTab() end)
stage("autoload", false, function()
local prof = BX.require("core.profiles")
local ok, msg = prof.runAutoLoad()
prof.startAutoSave()
if not ok then log.info("no profile restored: %s", tostring(msg)) end
end)
splash.step("Ready", 1.0)
stage("reveal", false, function()
splash.whenClosed(function()
BX.try("rap.reveal", function()
win.reveal()
log.info("Ride A Pet hub ready")
end)
end)
splash.done()
end)
return M
end
return M
end)
BX.require("games.rideapet.main").boot()
