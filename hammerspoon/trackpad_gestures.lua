-- Trackpad three-finger gestures via the vendored Swipe.spoon (MIT,
-- mogenson/Swipe.spoon, which reads swipes from hs.eventtap gesture events).
--
-- Actions and gestures are separate, mirroring mouse_gestures.lua: ACTIONS
-- maps a name to a zero-arg function, GESTURES maps a swipe direction to an
-- action name. One action per swipe: the first crossing of THRESHOLD fires,
-- then the gesture latches until the fingers lift (new swipe id).
--
-- NOTE: in System Settings > Trackpad > More Gestures, keep Mission Control
-- and "Swipe between full-screen applications" OFF three fingers (four
-- fingers or off), or macOS fires its own gesture on top of these.

local OMNIWMCTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"

-- Configuration --------------------------------------------------------------
local NATURAL_SCROLLING = true -- content follows the hand, like macOS spaces
local THRESHOLD = 0.2 -- default fraction of trackpad the swipe must travel
-- Four fingers: three-finger horizontal motion belongs to OmniWM's niri
-- column scroll (gestures.fingerCount = 3), so these gestures live one
-- finger up to avoid overlapping it.
local FINGERS = 4

-- Returns an action that runs omniwmctl with the given arguments.
-- Requires general.ipcEnabled = true in OmniWM's settings.toml.
local function omniwm(...)
  local args = { ... }
  return function()
    hs.task.new(OMNIWMCTL, nil, args):start()
  end
end

local ACTIONS = {
  overview = omniwm("command", "toggle-overview"),
  workspacePrev = omniwm("command", "switch-workspace", "prev"),
  workspaceNext = omniwm("command", "switch-workspace", "next"),
}

-- action name, plus an optional per-direction threshold override.
local GESTURES = {
  up = { action = "overview" }, -- OmniWM's present-all-windows
  left = { action = NATURAL_SCROLLING and "workspaceNext" or "workspacePrev" },
  right = { action = NATURAL_SCROLLING and "workspacePrev" or "workspaceNext" },
}
--------------------------------------------------------------------------------

local swipe = hs.loadSpoon("Swipe")

local currentId, fired
swipe:start(FINGERS, function(direction, distance, id)
  if id ~= currentId then
    currentId, fired = id, false
  end
  if fired then
    return
  end
  local gesture = GESTURES[direction]
  if not gesture or distance <= (gesture.threshold or THRESHOLD) then
    return
  end
  local action = ACTIONS[gesture.action]
  if action then
    fired = true
    action()
  end
end)

return swipe
