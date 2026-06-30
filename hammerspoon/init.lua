-- Hyper-layer HUD. Triggered by Karabiner via:
--   open -g "hammerspoon://hyperhud?text=<url-encoded multi-line text>"
-- (macOS lowercases URL hosts, so the handler name must be lowercase.)
-- Renders a centered rounded card that auto-fades. Karabiner owns the text,
-- so remapping apps in karabiner_rules/src/hyper_apps.ts updates this for free.

local FADE = 0.12 -- fade in/out, seconds
local BACKSTOP = 8.0 -- safety auto-hide if the keypress watcher can't run
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

local function show(text)
  if canvas then return end -- already open; don't rebuild
  if not text or text == "" then return end

  local screen = hs.screen.mainScreen():frame()
  local styled = hs.styledtext.new(text, {
    font = { name = FONT, size = SIZE },
    color = { white = 0.95 },
    paragraphStyle = { alignment = "left", lineSpacing = 4 },
  })
  local sz = hs.drawing.getTextDrawingSize(styled)
  local padX, padY = 28, 22
  local w = math.max(sz.w + padX * 2, 260)
  local h = sz.h + padY * 2
  local x = screen.x + (screen.w - w) / 2
  local y = screen.y + (screen.h - h) / 2

  canvas = hs.canvas.new({ x = x, y = y, w = w, h = h })
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 16, yRadius = 16 },
    fillColor = { red = 0.08, green = 0.08, blue = 0.10, alpha = 0.92 },
  }, {
    type = "rectangle",
    action = "stroke",
    roundedRectRadii = { xRadius = 16, yRadius = 16 },
    strokeColor = { white = 1, alpha = 0.12 },
    strokeWidth = 1,
  }, {
    type = "text",
    text = styled,
    frame = { x = padX, y = padY, w = sz.w, h = sz.h },
  })
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:show(FADE)

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

-- Enable the `hs` CLI and auto-reload this config when it changes.
hs.ipc.cliInstall()
hs.pathwatcher
  .new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, f in ipairs(files) do
      if f:sub(-4) == ".lua" then hs.reload() end
    end
  end)
  :start()

hs.alert.show("Hyper HUD loaded")
