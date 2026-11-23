-- Run: luajit tests/omniwm_cheatsheet_test.lua   (from the repo root)
-- Drives the real module through a stub `hs` (fake clock, timers, eventtap,
-- task, canvas). JSON decoding is table-driven since LuaJIT has no JSON.
package.path = "hammerspoon/?.lua;" .. package.path

local clock, timers, taps, tasks, canvases = 0, {}, {}, {}, {}
local JSON, kbMods, screenFrame = {}, {}, { x = 0, y = 25, w = 1920, h = 1055 }

local function timerObj(fireAt, fn, every)
  local t = { at = fireAt, fn = fn, every = every, live = true }
  function t:stop() self.live = false end
  function t:running() return self.live end
  timers[#timers + 1] = t
  return t
end

local function canvasObj(frame)
  local c = { frame = frame, elements = {}, deleted = false }
  function c:appendElements(...) for _, e in ipairs({ ... }) do self.elements[#self.elements + 1] = e end return self end
  function c:level() return self end
  function c:behavior() return self end
  function c:clickActivating() return self end
  function c:canvasMouseEvents() return self end
  function c:show() self.shown = true return self end
  function c:hide() self.shown = false return self end
  function c:delete() self.deleted = true end
  function c:text() local t = {} for _, e in ipairs(self.elements) do if e.text then t[#t + 1] = tostring(e.text) end end return table.concat(t, "\n") end
  canvases[#canvases + 1] = c
  return c
end

hs = {
  timer = {
    secondsSinceEpoch = function() return clock end,
    doAfter = function(d, fn) return timerObj(clock + d, fn) end,
    doEvery = function(d, fn) return timerObj(clock + d, fn, d) end,
  },
  eventtap = {
    event = { types = { flagsChanged = 12, keyDown = 10, leftMouseDown = 1, rightMouseDown = 3, otherMouseDown = 25 } },
    new = function(types, fn)
      local t = { fn = fn, on = false }
      function t:start() self.on = true return self end
      function t:stop() self.on = false return self end
      function t:isEnabled() return self.on end
      taps[#taps + 1] = t
      return t
    end,
    checkKeyboardModifiers = function() return kbMods end,
    isSecureInputEnabled = function() return false end,
  },
  task = { new = function(path, cb, args)
    local t = { path = path, cb = cb, args = args }
    function t:start() self.started = true return self end
    function t:terminate() self.terminated = true end
    tasks[#tasks + 1] = t
    return t
  end },
  json = { decode = function(s) return JSON[s] end },
  screen = { mainScreen = function() return { frame = function() return screenFrame end } end },
  canvas = { new = canvasObj, windowLevels = { overlay = 102 }, windowBehaviors = { canJoinAllSpaces = 1, transient = 2 } },
  styledtext = { new = function(s) return s end },
}

local function advance(dt)
  local target = clock + dt
  while true do
    local best
    for _, t in ipairs(timers) do if t.live and t.at <= target and (not best or t.at < best.at) then best = t end end
    if not best then break end
    clock = best.at
    if best.every then best.at = best.at + best.every else best.live = false end
    best.fn()
  end
  clock = target
end

local M = require("omniwm_cheatsheet")
local inst
local function fresh()
  clock, timers, taps, tasks, canvases, JSON, kbMods = 1000, {}, {}, {}, {}, {}, {}
  screenFrame = { x = 0, y = 25, w = 1920, h = 1055 }
  inst = M.start()
end

local L, R = 0x08, 0x10
local function send(etype, flags, raw)
  local ev = { getType = function() return etype end, getFlags = function() return flags or {} end, rawFlags = function() return raw or 0 end }
  local ret = taps[1].fn(ev)
  assert(ret == false, "handler must pass events through (return false)")
end
local T = hs.eventtap.event.types
local function cmd(down, raw) kbMods = down and { cmd = true } or {}; send(T.flagsChanged, down and { cmd = true } or {}, down and (raw or L) or 0) end
local function key() send(T.keyDown, { cmd = true }, L) end

local function doc(hotkeys, enabled)
  local body = "doc" .. tostring(#tasks) .. tostring(clock) .. tostring(math.random())
  JSON[body] = { hotkeysEnabled = enabled == nil and true or enabled, hotkeys = hotkeys }
  return body
end
local function finish(task, out, code, err) task.cb(code or 0, out, err or "") end
local function hk(id, b) return { id = id, binding = b } end
local function activate(hotkeys, enabled)
  local n = #tasks
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); advance(0.41)
  assert(#tasks == n + 1, "expected a task to start")
  finish(tasks[#tasks], doc(hotkeys, enabled))
  return canvases[#canvases]
end
local function release() cmd(false) end

local tests, failed = {}, 0
local function test(name, fn) tests[#tests + 1] = { name, fn } end
local function has(c, s) return c:text():find(s, 1, true) ~= nil end

test("tap then hold reads live settings and shows; release hides", function()
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true)
  assert(#tasks == 0 and #canvases == 0)
  advance(0.41)
  assert(#tasks == 1 and tasks[1].started)
  assert(tasks[1].path:match("python3$") and tasks[1].args[1] == "-B" and tasks[1].args[2] == "-c")
  assert(tasks[1].args[4]:match("/%.config/omniwm/settings%.toml$"), "settings path passed as argv")
  assert(#canvases == 0, "nothing shown before settings arrive")
  finish(tasks[1], doc({ hk("toggleOverview", "Option+Space") }))
  local c = canvases[1]
  assert(c and c.shown and has(c, "Overview") and has(c, "⌥") and has(c, "Space"))
  release()
  assert(c.deleted, "release hides")
end)

test("hold shorter than the hold delay never starts", function()
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); advance(0.2); cmd(false); advance(1)
  assert(#tasks == 0 and #canvases == 0)
end)

test("slow first press, late second press, single hold are not a gesture", function()
  cmd(true); advance(0.6); cmd(false); advance(0.1); cmd(true); advance(1); cmd(false)
  cmd(true); advance(0.1); cmd(false); advance(0.5); cmd(true); advance(1); cmd(false)
  cmd(true); advance(2); cmd(false)
  assert(#tasks == 0)
end)

test("Cmd shortcut before or during second press cancels", function()
  cmd(true); key(); advance(0.05); cmd(false); advance(0.05); cmd(true); advance(1); cmd(false)
  assert(#tasks == 0, "Cmd+key then Cmd hold must not fire")
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); key(); advance(1); cmd(false)
  assert(#tasks == 0, "key during second press cancels")
end)

test("key during display hides the sheet", function()
  local c = activate({ hk("toggleOverview", "Option+Space") })
  key(); assert(c.deleted)
end)

test("Hyper chord is not a tap", function()
  local hyper = { cmd = true, ctrl = true, alt = true, shift = true }
  for _ = 1, 2 do
    send(T.flagsChanged, hyper, L); advance(0.1); send(T.flagsChanged, {}, 0); advance(0.1)
  end
  send(T.flagsChanged, hyper, L); advance(1)
  assert(#tasks == 0)
end)

test("Cmd plus another modifier mid-hold hides", function()
  local c = activate({ hk("toggleOverview", "Option+Space") })
  send(T.flagsChanged, { cmd = true, alt = true }, L); assert(c.deleted)
end)

test("left+right Cmd chord is not a repeated tap", function()
  cmd(true, L); advance(0.05); cmd(true, L + R); advance(0.05); cmd(true, R); advance(1)
  assert(#tasks == 0)
  cmd(false); advance(0.1)
  cmd(true, L); advance(0.1); cmd(false); advance(0.1)
  cmd(true, L); cmd(true, L + R); advance(1)
  assert(#tasks == 0)
end)

test("repeated flag events do not restart the hold timer", function()
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true)
  advance(0.3); cmd(true); advance(0.11)
  assert(#tasks == 1)
end)

test("result arriving after release is discarded and task cancelled", function()
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); advance(0.41)
  local t = tasks[1]; release()
  assert(t.terminated)
  finish(t, doc({ hk("toggleOverview", "Option+Space") }))
  assert(#canvases == 0)
end)

test("stale result cannot overwrite a newer activation", function()
  cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); advance(0.41)
  local old = tasks[1]; release(); advance(1)
  local c = activate({ hk("toggleOverview", "Option+O") })
  finish(old, doc({ hk("toggleOverview", "Option+Z") }))
  assert(#canvases == 1 and has(c, "Option+O") == false and has(c, "O") and not has(c, "Z"))
end)

test("settings re-read every activation; Unassigned omitted", function()
  local c = activate({ hk("toggleOverview", "Option+Space"), hk("openCommandPalette", "Unassigned") })
  assert(has(c, "Overview") and not has(c, "Command palette") and not has(c, "Unassigned"))
  release()
  c = activate({ hk("toggleOverview", "Option+X"), hk("openCommandPalette", "Control+Option+Space") })
  assert(#tasks == 2 and has(c, "X") and has(c, "Command palette"))
end)

test("uniform direction groups collapse, divergent ones list separately", function()
  local function dirs(leftBinding)
    return { hk("focus.left", leftBinding), hk("focus.down", "Option+K"), hk("focus.up", "Option+I"), hk("focus.right", "Option+L") }
  end
  local c = activate(dirs("Option+J"))
  assert(has(c, "Focus") and has(c, "J K I L") and not has(c, "Focus left"))
  release()
  c = activate(dirs("Control+Option+J"))
  assert(has(c, "Focus left") and has(c, "Focus down"))
end)

test("workspace digits group only when bindings really are 1-9", function()
  local function ws(f)
    local t = {}
    for i = 0, 8 do t[#t + 1] = hk("switchWorkspace." .. i, f(i)) end
    return t
  end
  local c = activate(ws(function(i) return "Option+" .. (i + 1) end))
  assert(has(c, "1-9") and has(c, "Workspace"))
  release()
  c = activate(ws(function(i) return i == 2 and "Option+Q" or "Option+" .. (i + 1) end))
  assert(not has(c, "1-9") and has(c, "Workspace 3") and has(c, "Q"))
  release()
  local only = activate({ hk("switchWorkspace.0", "Option+1") })
  assert(has(only, "Workspace 1") and not has(only, "Workspace 2") and not has(only, "1-9"))
end)

test("Karabiner-overridden actions carry a caveat marker", function()
  local c = activate({ hk("toggleContainerFullPrimarySpan", "Control+Option+Shift+Space"), hk("moveWorkspaceToMonitor.right", "Option+Shift+Tab") })
  assert(has(c, "Maximize") and has(c, "†") and has(c, "Karabiner"))
end)

test("errors are explicit", function()
  local function err(fn) cmd(true); advance(0.1); cmd(false); advance(0.1); cmd(true); advance(0.41); fn(tasks[#tasks]); local c = canvases[#canvases]; release(); return c end
  local c = err(function(t) finish(t, "", 1, "FileNotFoundError: settings.toml") end)
  assert(has(c, "settings.toml") and has(c, "unavailable"))
  c = err(function(t) finish(t, "{not json") end)
  assert(has(c, "malformed"))
  JSON["noh"] = { hotkeysEnabled = true }
  c = err(function(t) finish(t, "noh") end); assert(has(c, "malformed"))
  JSON["badb"] = { hotkeys = { { id = "x", binding = 5 } } }
  c = err(function(t) finish(t, "badb") end); assert(has(c, "malformed"))
  JSON["badf"] = { hotkeysEnabled = "yes", hotkeys = {} }
  c = err(function(t) finish(t, "badf") end); assert(has(c, "malformed"))
  c = err(function(t) t.cb(-15, "", "") ; end); assert(has(c, "unavailable"))
end)

test("disabled hotkeys warn but still list bindings", function()
  local c = activate({ hk("toggleOverview", "Option+Space") }, false)
  assert(has(c, "hotkeysEnabled") and has(c, "Overview"))
end)

test("sheet fits the current display's visible frame", function()
  local all = {}
  local function add(id, b) all[#all + 1] = hk(id, b) end
  for _, d in ipairs({ "left", "down", "up", "right" }) do add("focus." .. d, "Option+" .. d:sub(1, 1):upper()); add("move." .. d, "Option+Shift+" .. d:sub(1, 1):upper()); add("moveWindowToMonitor." .. d, "Control+Option+" .. d:sub(1, 1):upper()) end
  for i = 0, 8 do add("switchWorkspace." .. i, "Option+" .. (i + 1)); add("moveToWorkspace." .. i, "Option+Shift+" .. (i + 1)) end
  for _, id in ipairs({ "toggleWorkspaceLayout", "toggleColumnTabbed", "toggleFocusedWindowFloating", "toggleNativeFullscreen", "cycleSizeForward", "cycleSizeBackward", "balanceSizes", "toggleContainerFullPrimarySpan", "focusPrevious", "moveColumn.left", "moveColumn.right", "focusMonitorNext", "focusMonitorLast", "moveWorkspaceToMonitor.left", "moveWorkspaceToMonitor.right", "toggleOverview", "openCommandPalette", "toggleQuakeTerminal", "toggleScratchpad.1" }) do add(id, "Control+Option+Shift+Page Up") end
  for _, f in ipairs({ { x = 0, y = 25, w = 1920, h = 1055 }, { x = -1440, y = 900, w = 1440, h = 875 }, { x = 3000, y = 0, w = 1100, h = 650 } }) do
    screenFrame = f
    local c = activate(all); local fr = c.frame
    assert(fr.x >= f.x and fr.y >= f.y and fr.x + fr.w <= f.x + f.w and fr.y + fr.h <= f.y + f.h, "canvas outside frame " .. f.w)
    local rows = 0
    for _, e in ipairs(c.elements) do
      if e.frame and e.text then
        assert(e.frame.x >= 0 and e.frame.y >= 0 and e.frame.x + e.frame.w <= fr.w + 0.5 and e.frame.y + e.frame.h <= fr.h + 0.5, "text outside canvas: " .. tostring(e.text))
        rows = rows + 1
      end
    end
    assert(rows >= 30, "too few text elements: " .. rows)
    release()
  end
end)

test("missed Cmd release is caught by the modifier poll", function()
  local c = activate({ hk("toggleOverview", "Option+Space") })
  kbMods = {}; advance(0.6)
  assert(c.deleted)
end)

test("disabled event tap is restarted by the watchdog", function()
  taps[1].on = false; advance(5)
  assert(taps[1].on)
end)

test("Meh and Hyper combos display as words; lesser combos keep glyphs", function()
  local function shown(binding)
    local c = activate({ hk("toggleOverview", binding) })
    local t = c:text()
    release()
    return t
  end
  local function has2(t, s) return t:find(s, 1, true) ~= nil end
  local t = shown("Control+Option+Shift+Space")
  assert(has2(t, "Meh Space") and not has2(t, "⌃") and not has2(t, "⌘"), t)
  t = shown("Shift+Control+Option+Space")
  assert(has2(t, "Meh Space"), "order independent: " .. t)
  t = shown("Control+Option+Shift+Command+Tab")
  assert(has2(t, "Hyp Tab") and not has2(t, "Meh") and not has2(t, "⌘"), t)
  t = shown("Command+Option+Shift+Control+Tab")
  assert(has2(t, "Hyp Tab") and not has2(t, "Meh"), "order independent: " .. t)
  t = shown("Control+Option+Tab")
  assert(has2(t, "⌃⌥ Tab") and not has2(t, "Meh") and not has2(t, "Hyp"), t)
  t = shown("Option+Shift+Tab")
  assert(has2(t, "⌥⇧ Tab"), t)
  t = shown("Control+Shift+Command+X")
  assert(has2(t, "⌃⇧⌘ X") and not has2(t, "Meh") and not has2(t, "Hyp"), t)
  t = shown("Control+Option+Shift+Page Up")
  assert(has2(t, "Meh Page Up"), t)
end)

for _, t in ipairs(tests) do
  fresh()
  local ok, err = pcall(t[2])
  print((ok and "PASS " or "FAIL ") .. t[1] .. (ok and "" or ("\n     " .. tostring(err))))
  if not ok then failed = failed + 1 end
end
print(string.format("%d/%d passed", #tests - failed, #tests))
os.exit(failed == 0 and 0 or 1)
