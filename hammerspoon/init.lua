-- Hyper-layer HUD. Triggered by Karabiner via:
--   open -g "hammerspoon://hyperhud?text=<url-encoded multi-line text>"
-- (macOS lowercases URL hosts, so the handler name must be lowercase.)
-- Renders a centered rounded card that auto-fades. Karabiner owns the text,
-- so remapping apps in karabiner_rules/src/hyper_apps.ts updates this for free.

local FADE = 0.12 -- fade in/out, seconds
local BACKSTOP = 8.0 -- safety auto-hide if the keypress watcher can't run
local MUTE_HUD_SECONDS = 1.2 -- how long the mute-state toast stays up
local TOP_MARGIN = 60 -- gap below the menu bar; cards are top-anchored
local FONT = "Menlo"
local SIZE = 18

local canvas = nil
local hideTimer = nil
local keyTap = nil

local function hide()
  if hideTimer then hideTimer:stop(); hideTimer = nil end
  if keyTap then keyTap:stop(); keyTap = nil end
  if canvas then
    canvas:hide(FADE)
    local c = canvas
    canvas = nil
    hs.timer.doAfter(FADE + 0.05, function() c:delete() end)
  end
end

-- duration: if given, the card auto-hides after that many seconds and does NOT
-- close on the next keypress. Use it for status toasts (see the mute HUD), which
-- report something that already happened rather than prompting for a next key.
--
-- opts (all optional) restyles the card without touching its defaults, which the
-- hyper HUD depends on. IMPORTANT: the hyper HUD's text is a padEnd-aligned
-- monospace grid built in karabiner_rules/src/hyper_apps.ts, so its font must
-- stay Menlo -- a proportional font would ragged the columns. Only pass `font`
-- for single-line content.
--   font/size  - override the type
--   dot        - {red=,green=,blue=} draws a glowing status dot, text indents
--   accent     - {red=,green=,blue=} tints the border and adds a top hairline
--   minWidth   - override the 260px floor (single-line toasts want less)
-- `text` may also be an hs.styledtext, for content that needs mixed styling.
local function show(text, duration, opts)
  if canvas then return end -- already open; don't rebuild
  if not text or text == "" then return end
  opts = opts or {}

  local screen = hs.screen.mainScreen():frame()
  local styled = text
  if type(text) == "string" then
    styled = hs.styledtext.new(text, {
      font = { name = opts.font or FONT, size = opts.size or SIZE },
      color = { white = 0.96 },
      paragraphStyle = { alignment = "left", lineSpacing = 4 },
    })
  end
  local sz = hs.drawing.getTextDrawingSize(styled)

  local RADIUS = 18
  local padX, padY = 28, 22
  -- A dot reserves room to its left so the text doesn't crowd it.
  local dotR, dotGap = 7, 18
  local textX = padX + (opts.dot and (dotR * 2 + dotGap) or 0)
  local w = math.max(textX + sz.w + padX, opts.minWidth or 260)
  local h = sz.h + padY * 2
  local x = screen.x + (screen.w - w) / 2
  -- Anchored near the top rather than centered, so the card never sits over
  -- whatever you're reading. screen.y comes from frame(), which already excludes
  -- the menu bar / notch, so this can't tuck under them.
  local y = screen.y + TOP_MARGIN

  canvas = hs.canvas.new({ x = x, y = y, w = w, h = h })

  -- Body: vertical gradient + drop shadow, so the card reads as a raised
  -- surface rather than a flat rectangle.
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = RADIUS, yRadius = RADIUS },
    fillGradient = "linear",
    fillGradientAngle = 90,
    fillGradientColors = {
      { red = 0.13, green = 0.13, blue = 0.16, alpha = 0.97 },
      { red = 0.06, green = 0.06, blue = 0.08, alpha = 0.97 },
    },
    withShadow = true,
    shadow = { blurRadius = 24, color = { alpha = 0.5 }, offset = { h = -5, w = 0 } },
  }, {
    type = "rectangle",
    action = "stroke",
    roundedRectRadii = { xRadius = RADIUS, yRadius = RADIUS },
    strokeColor = opts.accent
        and { red = opts.accent.red, green = opts.accent.green, blue = opts.accent.blue, alpha = 0.45 }
      or { white = 1, alpha = 0.13 },
    strokeWidth = 1,
  })

  -- Accent hairline along the top edge, clipped to the card's rounded corners.
  if opts.accent then
    canvas:appendElements({
      type = "rectangle",
      action = "clip",
      roundedRectRadii = { xRadius = RADIUS, yRadius = RADIUS },
    }, {
      type = "rectangle",
      action = "fill",
      frame = { x = 0, y = 0, w = w, h = 2 },
      -- Fades out toward the edges so it reads as a highlight, not a stripe.
      fillGradient = "linear",
      fillGradientAngle = 0,
      fillGradientColors = {
        { red = opts.accent.red, green = opts.accent.green, blue = opts.accent.blue, alpha = 0.05 },
        { red = opts.accent.red, green = opts.accent.green, blue = opts.accent.blue, alpha = 0.7 },
        { red = opts.accent.red, green = opts.accent.green, blue = opts.accent.blue, alpha = 0.05 },
      },
    }, { type = "resetClip" })
  end

  -- Status dot: a soft halo under a solid core reads as lit rather than printed.
  if opts.dot then
    local cy = h / 2
    local cx = padX + dotR
    canvas:appendElements({
      type = "circle",
      action = "fill",
      center = { x = cx, y = cy },
      radius = dotR + 5,
      fillColor = { red = opts.dot.red, green = opts.dot.green, blue = opts.dot.blue, alpha = 0.22 },
    }, {
      type = "circle",
      action = "fill",
      center = { x = cx, y = cy },
      radius = dotR,
      fillColor = { red = opts.dot.red, green = opts.dot.green, blue = opts.dot.blue, alpha = 1 },
    })
  end

  canvas:appendElements({
    type = "text",
    text = styled,
    frame = { x = textX, y = padY, w = sz.w, h = sz.h },
  })
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:show(FADE)

  if duration then
    hideTimer = hs.timer.doAfter(duration, hide)
    return
  end

  -- Stay up until the next keypress. Karabiner sends the layer's app keys (and
  -- the leader-mode escape keys) as real key events, so the first keyDown after
  -- the HUD appears is exactly "the next key" — hide then. Needs Accessibility;
  -- the backstop timer covers the case where the tap can't run.
  keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function()
    hide()
    return false -- don't swallow the key; let it reach the app/layer
  end):start()
  hideTimer = hs.timer.doAfter(BACKSTOP, hide)
end

-- Introspection for debugging from the `hs` CLI.
function _hudState()
  return string.format(
    "canvas=%s keyTap=%s",
    tostring(canvas ~= nil),
    tostring(keyTap ~= nil and keyTap:isEnabled())
  )
end

hs.urlevent.bind("hyperhud", function(_, params)
  show(params.text or "")
end)

hs.urlevent.bind("hyperhide", function() hide() end)

-- Mute HUD. Triggered by scripts/muteAllApps.scpt (bound to F5 in Karabiner):
--   open -g "hammerspoon://mutestate?app=<conferencing app name>"
-- That script is a blind toggle -- it keystrokes the app's mute shortcut and
-- never learns the outcome. So we read the state back off the app's own mute
-- menu item, whose title flips between "Mute ..." and "Unmute ...". A title
-- saying "Unmute" means we are currently MUTED.
--
-- Slack huddles expose no such menu item, so they land in the nil branch and
-- report TOGGLED rather than showing a state we would only be guessing at.
-- Returns "muted", "unmuted", "nomenu" (app is up but exposes no own-mic mute
-- item -- no meeting, or a Slack huddle), or "error" (AX query blew up, usually
-- a revoked Accessibility grant). Distinguishing the last two matters: "nomenu"
-- is normal and expected, "error" means the HUD is broken and needs fixing.
local function muteStateOf(app)
  local ok, items = pcall(function() return app:getMenuItems() end)
  if not ok then return "error" end
  if items == nil then return "error" end -- AX refused; not the same as an empty menu

  local found = nil
  local function walk(list)
    for _, it in ipairs(list or {}) do
      local title = it.AXTitle or ""
      if found == nil and title ~= "" then
        local lower = title:lower()
        -- Host controls like "Mute All Others" / "Mute Everyone" are about other
        -- participants, not our own mic. Reading one of those as our state would
        -- show the exact opposite of the truth, so skip them.
        local aboutOthers = lower:find("all") or lower:find("other") or lower:find("everyone")
        if not aboutOthers then
          if lower:find("^unmute") then
            found = true
          elseif lower:find("^mute") then
            found = false
          end
        end
      end
      if it.AXChildren then walk(it.AXChildren[1]) end
    end
  end

  local walked = pcall(walk, items)
  if not walked then return "error" end
  if found == true then return "muted" end
  if found == false then return "unmuted" end
  return "nomenu"
end

-- The bubble is drawn as a canvas circle rather than an emoji: it gets a soft
-- halo, sits optically centered against the cap-height, and picks up the same
-- accent as the border. States with nothing meaningful to signal get no dot and
-- no accent, rather than a colour that would imply a mic state we can't read.
local RED = { red = 0.98, green = 0.29, blue = 0.31 }
local GREEN = { red = 0.29, green = 0.83, blue = 0.44 }
local AMBER = { red = 0.98, green = 0.71, blue = 0.24 }

local MUTE_STYLES = {
  muted = { label = "Muted", dot = RED, accent = RED },
  unmuted = { label = "Unmuted", dot = GREEN, accent = GREEN },
  nomenu = { label = "Toggled" },
  error = { label = "Mute: AX error", dot = AMBER, accent = AMBER },
}

-- One line, proportional type: the state is the headline and the app name recedes
-- behind it, so the thing you need at a glance wins. Two styles in one string,
-- hence the pre-built styledtext.
--
-- ".AppleSystemUIFont" is the real system face (SF). hs.styledtext REJECTS the
-- friendly name "SF Pro Text" and silently falls back to a default face, so it
-- has to be spelled this way -- verified by comparing measured widths against a
-- deliberately bogus font name.
local UI_FONT = ".AppleSystemUIFont"
local UI_BOLD = ".AppleSystemUIFontBold"

local function showMute(state, appName)
  local s = MUTE_STYLES[state] or MUTE_STYLES.nomenu
  local styled = hs.styledtext.new(s.label, {
    font = { name = UI_BOLD, size = 17 },
    color = { white = 0.97 },
  }) .. hs.styledtext.new("   " .. appName, {
    font = { name = UI_FONT, size = 15 },
    color = { white = 0.62 }, -- recedes; the state is what matters
  })
  hide() -- drop any card still up so show() will rebuild
  show(styled, MUTE_HUD_SECONDS, { dot = s.dot, accent = s.accent, minWidth = 150 })
end

hs.urlevent.bind("mutestate", function(_, params)
  local name = params.app
  if not name or name == "" then return end
  local app = hs.application.get(name)
  if not app then
    showMute("nomenu", name)
    return
  end

  -- Menus need a beat to redraw after the keystroke, and the toggled app has
  -- just been sent back behind whatever was frontmost. How long that takes
  -- varies by app and machine load, so poll briefly instead of betting the
  -- readout on one guessed delay: take the first definite answer, and only
  -- fall back to the last (indefinite) one once the attempts run out.
  local attempts, state = 0, "nomenu"
  local function attempt()
    attempts = attempts + 1
    state = muteStateOf(app)
    if (state == "muted" or state == "unmuted") or attempts >= 4 then
      showMute(state, app:name())
    else
      hs.timer.doAfter(0.15, attempt)
    end
  end
  hs.timer.doAfter(0.2, attempt)
end)

-- Enable the `hs` CLI and auto-reload this config when it changes.
hs.ipc.cliInstall()
hs.pathwatcher
  .new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, f in ipairs(files) do
      if f:sub(-4) == ".lua" then hs.reload() end
    end
  end)
  :start()

-- Middle-button mouse gestures (three-finger-swipe stand-in for mice).
-- Global keeps the eventtap referenced so it survives garbage collection.
mouseGestures = require("mouse_gestures")

-- Startup toast in the mute-HUD style (bold headline, receding detail,
-- green dot, top-center card) instead of the stock hs.alert box. Fires
-- last so it also vouches that every module above loaded cleanly.
show(
  hs.styledtext.new("Hammerspoon", {
    font = { name = UI_BOLD, size = 17 },
    color = { white = 0.97 },
  }) .. hs.styledtext.new("   config loaded", {
    font = { name = UI_FONT, size = 15 },
    color = { white = 0.62 },
  }),
  MUTE_HUD_SECONDS,
  { dot = GREEN, accent = GREEN, minWidth = 150 }
)
