-- OmniWM cheat sheet. Tap Command, then press it again and hold: a read-only
-- overlay lists OmniWM's live hotkeys; releasing Command hides it.
--
-- Bindings are read from ~/.config/omniwm/settings.toml on EVERY activation
-- (async python3 tomllib -> JSON), so edits show up without a reload. The
-- catalog below only maps action ids to labels and groups; it holds no keys.
-- Event taps never swallow events (always return false).
--
-- Karabiner (src/omniwm_mods.ts) overrides a few actions at the OS level. The
-- settings file cannot know that, so those rows carry a dagger and a footer.

local M = {}

local TAP_MAX = 0.35 -- first press must be released within this
local GAP_MAX = 0.35 -- second press must start within this after that release
local HOLD = 0.4 -- second press must be held this long to show the sheet
local POLL = 0.25 -- missed-release safety poll while a gesture is in flight
local WATCHDOG = 2.0 -- restart a disabled event tap
local LEFT_CMD, RIGHT_CMD = 0x08, 0x10
local unpack = table.unpack or unpack

local PYTHON = "/opt/homebrew/bin/python3"
local SCRIPT = [[
import json, sys, tomllib
try:
    with open(sys.argv[1], "rb") as f:
        d = tomllib.load(f)
except tomllib.TOMLDecodeError as e:
    print(e, file=sys.stderr)
    sys.exit(2)
except OSError as e:
    print(e, file=sys.stderr)
    sys.exit(1)
g = d.get("general", {})
en = g.get("hotkeysEnabled", True) if isinstance(g, dict) else True
print(json.dumps({"hotkeysEnabled": en, "hotkeys": d.get("hotkeys", [])}))
]]

local DIRS = { "left", "down", "up", "right" }
local D9 = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }

local function dirs(prefix, label)
  local ids = {}
  for i, d in ipairs(DIRS) do ids[i] = prefix .. d end
  return { label = label, ids = ids, names = DIRS }
end
local function digits(prefix, label)
  local ids = {}
  for i = 0, 8 do ids[i + 1] = prefix .. i end
  return { label = label, ids = ids, names = D9, digits = true }
end
local function one(id, label, caveat) return { label = label, ids = { id }, names = { "" }, caveat = caveat } end

local CATALOG = {
  { "Layout", {
    one("toggleWorkspaceLayout", "Toggle layout"),
    one("toggleColumnTabbed", "Tabbed column"),
    one("toggleFocusedWindowFloating", "Float window"),
    one("toggleNativeFullscreen", "Native fullscreen"),
  } },
  { "Resize", {
    one("cycleSizeForward", "Cycle size forward"),
    one("cycleSizeBackward", "Cycle size back"),
    one("balanceSizes", "Balance sizes"),
    one("toggleContainerFullPrimarySpan", "Maximize", true),
  } },
  { "Focus", {
    dirs("focus.", "Focus"),
    one("focusPrevious", "Focus previous"),
    one("focusDownOrLeft", "Focus down or left"),
    one("focusUpOrRight", "Focus up or right"),
  } },
  { "Move", {
    dirs("move.", "Move"),
    { label = "Move column", ids = { "moveColumn.left", "moveColumn.right" }, names = { "left", "right" } },
    one("consumeWindowIntoColumn", "Consume into column"),
    one("expelWindowFromColumn", "Expel from column"),
  } },
  { "Workspace", {
    digits("switchWorkspace.", "Workspace"),
    digits("moveToWorkspace.", "Move to workspace"),
    one("workspaceBackAndForth", "Back and forth"),
    one("switchWorkspace.next", "Next workspace"),
    one("switchWorkspace.previous", "Previous workspace"),
  } },
  { "Monitor", {
    one("focusMonitorNext", "Focus next monitor"),
    one("focusMonitorLast", "Focus last monitor"),
    dirs("moveWindowToMonitor.", "Window to monitor"),
    { label = "Workspace to monitor", ids = { "moveWorkspaceToMonitor.left", "moveWorkspaceToMonitor.right" },
      names = { "left", "right" }, caveat = true },
  } },
  { "Other", {
    one("toggleOverview", "Overview"),
    one("openCommandPalette", "Command palette"),
    one("toggleQuakeTerminal", "Terminal"),
    one("toggleScratchpad.1", "Scratchpad"),
    one("assignFocusedWindowToScratchpad.1", "Send to scratchpad"),
  } },
}

local DAGGER = "†"
local FOOTER = {
  DAGGER .. " Karabiner overrides: workspace-to-monitor wraps prev/next,",
  "  Ctrl+Opt+Shift+Space is a layout-aware maximize.",
}

local MOD_GLYPH = { Control = "⌃", Option = "⌥", Shift = "⇧", Command = "⌘" }
local KEY_GLYPH = {
  ["Left Arrow"] = "←", ["Right Arrow"] = "→", ["Up Arrow"] = "↑", ["Down Arrow"] = "↓",
  Grave = "`", Minus = "-", Equal = "=", Period = ".", Comma = ",",
}

-- "Control+Option+Page Up" -> mods "<glyphs>", key "Page Up"
local function parseBinding(b)
  local mods, key = "", nil
  local parts, set = {}, {}
  for p in (b .. "+"):gmatch("(.-)%+") do parts[#parts + 1] = p end
  for i, p in ipairs(parts) do
    if i == #parts then key = p
    elseif MOD_GLYPH[p] then mods = mods .. MOD_GLYPH[p]; set[p] = true
    else return "", b end
  end
  -- Exactly Ctrl+Opt+Shift is "Meh"; adding Command makes it "Hyp".
  if set.Control and set.Option and set.Shift and #parts == (set.Command and 5 or 4) then
    mods = set.Command and "Hyp" or "Meh"
  end
  return mods, KEY_GLYPH[key] or key
end

local function ulen(s)
  local _, n = s:gsub("[^\128-\191]", "")
  return n
end

-- Build display rows [{label=, keys=}] per section from id -> binding.
local function buildSections(bindings)
  local sections, anyCaveat = {}, false
  for _, sec in ipairs(CATALOG) do
    local rows = {}
    local function add(label, mods, key, caveat)
      rows[#rows + 1] = { label = label .. (caveat and (" " .. DAGGER) or ""), keys = (mods ~= "" and (mods .. " ") or "") .. key }
      if caveat then anyCaveat = true end
    end
    for _, r in ipairs(sec[2]) do
      local assigned, allAssigned = {}, true
      for i, id in ipairs(r.ids) do
        local b = bindings[id]
        if b and b ~= "Unassigned" then
          local m, k = parseBinding(b)
          assigned[i] = { mods = m, key = k }
        else
          allAssigned = false
        end
      end
      local collapsed = false
      if #r.ids > 1 and allAssigned then
        local uniform = true
        for i = 2, #r.ids do if assigned[i].mods ~= assigned[1].mods then uniform = false end end
        if uniform and r.digits then
          for i = 1, #r.ids do if assigned[i].key ~= r.names[i] then uniform = false end end
          if uniform then add(r.label, assigned[1].mods, "1-9", r.caveat) collapsed = true end
        elseif uniform then
          local ks = {}
          for i = 1, #r.ids do ks[i] = assigned[i].key end
          add(r.label, assigned[1].mods, table.concat(ks, " "), r.caveat)
          collapsed = true
        end
      end
      if not collapsed then
        for i = 1, #r.ids do
          if assigned[i] then
            local name = r.names[i] ~= "" and (" " .. r.names[i]) or ""
            add(r.label .. name, assigned[i].mods, assigned[i].key, r.caveat)
          end
        end
      end
    end
    if #rows > 0 then sections[#sections + 1] = { title = sec[1], rows = rows } end
  end
  return sections, anyCaveat
end

-- Pick the largest monospace size (and most columns) that fits `avail`.
-- Returns canvas width, height and text elements positioned inside it.
local function layoutSheet(sections, anyCaveat, warning, avail)
  local total = 0
  for _, s in ipairs(sections) do total = total + #s.rows + 1 end

  local function try(size, ncols)
    local cw, lh = size * 0.602, size * 1.55
    local padX, padY = size * 1.6, size * 1.2
    local target = math.ceil(total / ncols)
    local cols, cur, curN = { {} }, 1, 0
    for _, s in ipairs(sections) do
      local n = #s.rows + 1
      if curN > 0 and curN + n > target and cur < ncols then cols[#cols + 1] = {}; cur = cur + 1; curN = 0 end
      table.insert(cols[cur], s)
      curN = curN + n
    end
    local colW, maxLines = {}, 0
    for i, col in ipairs(cols) do
      local lw, kw, lines = 0, 0, 0
      for _, s in ipairs(col) do
        lines = lines + #s.rows + 1
        for _, r in ipairs(s.rows) do lw = math.max(lw, ulen(r.label)); kw = math.max(kw, ulen(r.keys)) end
      end
      colW[i] = { label = lw * cw, key = kw * cw, w = (lw + kw + 2) * cw }
      maxLines = math.max(maxLines, lines)
    end
    local w = padX * 2 + (#cols - 1) * 3 * cw
    for _, c in ipairs(colW) do w = w + c.w end
    local foot = anyCaveat and #FOOTER or 0
    local h = padY * 2 + ((warning and 2 or 1) + 0.6) * lh + maxLines * lh + (foot > 0 and (foot * lh * 0.8 + lh * 0.4) or 0)
    if anyCaveat then
      local fw = 0
      for _, l in ipairs(FOOTER) do fw = math.max(fw, ulen(l)) end
      w = math.max(w, padX * 2 + fw * cw * 0.8)
    end
    if warning then w = math.max(w, padX * 2 + ulen(warning) * cw) end
    return { size = size, cw = cw, lh = lh, padX = padX, padY = padY, cols = cols, colW = colW, w = w, h = h, foot = foot }
  end

  local pick
  for size = 22, 10, -1 do
    for _, n in ipairs({ 3, 2, 1 }) do
      local c = try(size, n)
      if c.w <= avail.w * 0.96 and c.h <= avail.h * 0.96 then pick = c break end
    end
    if pick then break end
  end
  pick = pick or try(10, 3)

  local els = {}
  local function text(s, x, y, w, size, color, bold)
    els[#els + 1] = { type = "text", text = s, textFont = bold and "Menlo-Bold" or "Menlo", textSize = size,
      textColor = color, frame = { x = x, y = y, w = w, h = pick.lh } }
  end
  local white, dim = { white = 0.95 }, { white = 0.6 }
  local accent, warn = { red = 0.4, green = 0.8, blue = 1 }, { red = 1, green = 0.65, blue = 0.2 }
  local y = pick.padY
  text("OmniWM shortcuts", pick.padX, y, pick.w - pick.padX * 2, pick.size * 1.1, white, true)
  y = y + pick.lh
  if warning then text(warning, pick.padX, y, pick.w - pick.padX * 2, pick.size, warn) y = y + pick.lh end
  y = y + pick.lh * 0.6
  local x = pick.padX
  for i, col in ipairs(pick.cols) do
    local cy = y
    for _, s in ipairs(col) do
      text(s.title:upper(), x, cy, pick.colW[i].w, pick.size * 0.85, dim, true)
      cy = cy + pick.lh
      for _, r in ipairs(s.rows) do
        text(r.label, x, cy, pick.colW[i].label + pick.cw, pick.size, white)
        text(r.keys, x + pick.colW[i].label + pick.cw * 2, cy, pick.colW[i].key + pick.cw, pick.size, accent)
        cy = cy + pick.lh
      end
    end
    x = x + pick.colW[i].w + pick.cw * 3
  end
  if pick.foot > 0 then
    local fy = pick.h - pick.padY - pick.foot * pick.lh * 0.8
    for _, l in ipairs(FOOTER) do
      text(l, pick.padX, fy, pick.w - pick.padX * 2, pick.size * 0.8, dim)
      fy = fy + pick.lh * 0.8
    end
  end
  return pick.w, pick.h, els
end

local function errorSheet(msg)
  local lines, size = {}, 16
  local cw, lh = size * 0.602, size * 1.55
  local line = ""
  for word in msg:gmatch("%S+") do
    if ulen(line) + ulen(word) + 1 > 64 and line ~= "" then lines[#lines + 1] = line; line = word
    else line = (line == "" and "" or line .. " ") .. word end
  end
  if line ~= "" then lines[#lines + 1] = line end
  local w = 64 * cw + 48
  local els = {}
  for i, l in ipairs(lines) do
    els[#els + 1] = { type = "text", text = l, textFont = "Menlo", textSize = size,
      textColor = { red = 1, green = 0.65, blue = 0.2 }, frame = { x = 24, y = 20 + (i - 1) * lh, w = w - 48, h = lh } }
  end
  return w, 40 + #lines * lh, els
end

local function parseSettings(code, out, err)
  if code == 2 then return nil, "OmniWM settings malformed: " .. (err ~= "" and err or "TOML parse error") end
  if code ~= 0 then
    return nil, "OmniWM settings unavailable" .. (err ~= "" and (": " .. err) or (" (exit " .. tostring(code) .. ")"))
  end
  local ok, doc = pcall(hs.json.decode, out)
  if not ok or type(doc) ~= "table" then return nil, "OmniWM settings malformed: unreadable JSON from settings parser" end
  if doc.hotkeysEnabled ~= nil and type(doc.hotkeysEnabled) ~= "boolean" then
    return nil, "OmniWM settings malformed: general.hotkeysEnabled is not a boolean"
  end
  if type(doc.hotkeys) ~= "table" then return nil, "OmniWM settings malformed: no hotkeys list" end
  local bindings = {}
  for i, h in ipairs(doc.hotkeys) do
    if type(h) ~= "table" or type(h.id) ~= "string" or type(h.binding) ~= "string" then
      return nil, "OmniWM settings malformed: hotkeys entry " .. i .. " needs string id and binding"
    end
    bindings[h.id] = h.binding
  end
  return { enabled = doc.hotkeysEnabled ~= false, bindings = bindings }
end

function M.new()
  local self = {}
  local st = "idle" -- idle | down1 | wait | down2 | held | dead
  local t1 = 0
  local tapTimer, gapTimer, holdTimer, poll, watchdog
  local tap, canvas, curTask
  local gen = 0
  local live = {} -- strong refs to in-flight tasks until their callback runs
  local Tp = hs.eventtap.event.types

  local function stopT(t) if t then t:stop() end return nil end

  local function teardown()
    tapTimer, gapTimer, holdTimer, poll = stopT(tapTimer), stopT(gapTimer), stopT(holdTimer), stopT(poll)
    gen = gen + 1 -- any in-flight result is now stale
    if curTask then curTask:terminate(); curTask = nil end
    if canvas then canvas:delete(0.08); canvas = nil end
  end

  local function reset(to) teardown(); st = to end

  local function present(w, h, els)
    local f = hs.screen.mainScreen():frame() -- visible frame of the active display
    w, h = math.min(w, f.w), math.min(h, f.h)
    local c = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
    c:appendElements({
      type = "rectangle", action = "fill", roundedRectRadii = { xRadius = 18, yRadius = 18 },
      fillColor = { red = 0.08, green = 0.08, blue = 0.1, alpha = 0.96 },
    }, {
      type = "rectangle", action = "stroke", roundedRectRadii = { xRadius = 18, yRadius = 18 },
      strokeColor = { white = 1, alpha = 0.14 }, strokeWidth = 1,
    })
    c:appendElements(unpack(els))
    c:level(hs.canvas.windowLevels.overlay)
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.transient)
    c:clickActivating(false)
    c:canvasMouseEvents(false, false, false, false)
    c:show(0.08)
    canvas = c
  end

  local function render(code, out, err)
    local s, msg = parseSettings(code, out, err)
    if not s then return present(errorSheet(msg)) end
    local sections, anyCaveat = buildSections(s.bindings)
    if #sections == 0 then return present(errorSheet("OmniWM settings unavailable: no assigned hotkeys found")) end
    local warning = (not s.enabled) and "Hotkeys disabled: general.hotkeysEnabled = false" or nil
    present(layoutSheet(sections, anyCaveat, warning, hs.screen.mainScreen():frame()))
  end

  local function activate()
    holdTimer = nil
    st = "held"
    gen = gen + 1
    local myGen = gen
    local path = os.getenv("HOME") .. "/.config/omniwm/settings.toml"
    local task
    task = hs.task.new(PYTHON, function(code, out, err)
      live[task] = nil
      if curTask == task then curTask = nil end
      if myGen ~= gen or st ~= "held" then return end -- released meanwhile
      render(code, out or "", ((err or ""):gsub("%s+$", "")))
    end, { "-B", "-c", SCRIPT, path })
    if not task then return present(errorSheet("OmniWM settings unavailable: cannot create task")) end
    live[task], curTask = task, task
    if not task:start() then
      live[task], curTask = nil, nil
      present(errorSheet("OmniWM settings unavailable: cannot start " .. PYTHON))
    end
  end

  local function startPoll()
    if poll then return end
    poll = hs.timer.doEvery(POLL, function()
      local m = hs.eventtap.checkKeyboardModifiers()
      if not (m.cmd or m.alt or m.ctrl or m.shift or m.fn) then reset("idle") end
    end)
  end

  local function handler(ev)
    local et = ev:getType()
    if et == Tp.flagsChanged then
      local f = ev:getFlags()
      local other = f.alt or f.ctrl or f.shift or f.fn
      if not f.cmd and not other then
        if st == "down1" and hs.timer.secondsSinceEpoch() - t1 <= TAP_MAX then
          reset("wait")
          gapTimer = hs.timer.doAfter(GAP_MAX, function() gapTimer = nil; st = "idle" end)
        else
          reset("idle")
        end
      elseif other then
        reset("dead"); startPoll() -- Hyper, Cmd+Shift, Opt alone...: not our gesture
      else
        local raw = ev:rawFlags()
        if math.floor(raw / LEFT_CMD) % 2 == 1 and math.floor(raw / RIGHT_CMD) % 2 == 1 then
          reset("dead"); startPoll() -- left+right Cmd chord
        elseif st == "idle" then
          st = "down1"; t1 = hs.timer.secondsSinceEpoch()
          tapTimer = hs.timer.doAfter(TAP_MAX, function() tapTimer = nil; if st == "down1" then st = "dead" end end)
          startPoll()
        elseif st == "wait" then
          gapTimer = stopT(gapTimer)
          st = "down2"
          holdTimer = hs.timer.doAfter(HOLD, activate)
          startPoll()
        end -- down1/down2/held/dead: repeated flags event, ignore
      end
    elseif st == "wait" then
      reset("idle") -- key or click between the taps
    elseif st ~= "idle" then
      reset("dead"); startPoll() -- Cmd shortcut / Cmd+click
    end
    return false
  end

  function self.start()
    tap = hs.eventtap.new({ Tp.flagsChanged, Tp.keyDown, Tp.leftMouseDown, Tp.rightMouseDown, Tp.otherMouseDown }, handler)
    tap:start()
    watchdog = hs.timer.doEvery(WATCHDOG, function()
      if not tap:isEnabled() then reset("idle"); tap:start() end
    end)
    return self
  end

  function self.stop()
    reset("idle")
    if tap then tap:stop() end
    watchdog = stopT(watchdog)
  end

  return self
end

function M.start() return M.new().start() end

return M
