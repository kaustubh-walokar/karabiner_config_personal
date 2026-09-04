-- Mouse gestures: hold the middle button and swipe to trigger an action.
--
-- One gesture per press: the first TRIGGER_PX of motion picks the dominant
-- axis, fires once, and latches until the button is released. A quick press
-- without motion is reposted as a normal middle click, tagged so this tap
-- ignores its own synthetic events.
--
-- Actions and gestures are separate: ACTIONS maps a name to a zero-arg
-- function, GESTURES maps a swipe direction to an action name. To add or
-- change a gesture, edit those two tables only.
--
-- Trade-off: apps that use middle-drag natively (CAD, Blender) lose that
-- gesture while this is loaded.

local ev = hs.eventtap.event
local types = ev.types
local props = ev.properties

-- Configuration --------------------------------------------------------------
local NATURAL_SCROLLING = true -- horizontal swipes: content follows the hand
local TRIGGER_PX = 25 -- motion that fires the gesture
local CLICK_SLOP = 5 -- max total motion for a release to still count as a click
local OMNIWMCTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"

-- Returns an action that runs omniwmctl with the given arguments.
-- Requires general.ipcEnabled = true in OmniWM's settings.toml.
local function omniwm(...)
  local args = { ... }
  return function()
    hs.task.new(OMNIWMCTL, nil, args):start()
  end
end

local ACTIONS = {
  focusLeft = omniwm("command", "focus", "left"),
  focusRight = omniwm("command", "focus", "right"),
  -- OmniWM ignores IPC while Overview is open, so this opens but cannot
  -- close it; dismiss by clicking a window, Escape, or the hotkey.
  overview = omniwm("command", "toggle-overview"),
  missionControl = hs.spaces.toggleMissionControl,
  appExpose = hs.spaces.toggleAppExpose, -- all windows of the focused app
}

local GESTURES = {
  left = NATURAL_SCROLLING and "focusRight" or "focusLeft",
  right = NATURAL_SCROLLING and "focusLeft" or "focusRight",
  up = "overview", -- OmniWM's present-all-windows, not Mission Control
  down = "appExpose",
}
--------------------------------------------------------------------------------

local SYNTH_TAG = 0x0771 -- marks clicks this tap reposts, so it skips them

local drag -- nil while idle; { dist, x, y, fired } while the middle button is held

local function fire(direction)
  local action = ACTIONS[GESTURES[direction] or false]
  if action then
    action()
  end
end

local function directionOf(x, y)
  if math.abs(x) >= math.abs(y) then
    return x > 0 and "right" or "left"
  end
  return y > 0 and "down" or "up"
end

local function repostMiddleClick()
  local pos = hs.mouse.absolutePosition()
  for _, t in ipairs({ types.otherMouseDown, types.otherMouseUp }) do
    local click = ev.newMouseEvent(t, pos)
    click:setProperty(props.mouseEventButtonNumber, 2)
    click:setProperty(props.eventSourceUserData, SYNTH_TAG)
    click:post()
  end
end

local tap = hs.eventtap.new(
  { types.otherMouseDown, types.otherMouseUp, types.otherMouseDragged },
  function(e)
    if e:getProperty(props.eventSourceUserData) == SYNTH_TAG then
      return false -- our reposted click; let it through
    end
    if e:getProperty(props.mouseEventButtonNumber) ~= 2 then
      return false
    end

    local t = e:getType()
    if t == types.otherMouseDown then
      drag = { dist = 0, x = 0, y = 0, fired = false }
      return true
    end

    -- Only handle drag/up for a press we swallowed. Passing unpaired events
    -- through means we can never eat a button-up whose button-down some app
    -- already saw (stuck-button risk after a reload mid-hold).
    if not drag then
      return false
    end

    if t == types.otherMouseDragged then
      local dx = e:getProperty(props.mouseEventDeltaX)
      local dy = e:getProperty(props.mouseEventDeltaY)
      drag.dist = drag.dist + math.abs(dx) + math.abs(dy)
      drag.x = drag.x + dx
      drag.y = drag.y + dy
      if not drag.fired and math.max(math.abs(drag.x), math.abs(drag.y)) >= TRIGGER_PX then
        drag.fired = true
        fire(directionOf(drag.x, drag.y))
      end
      return true
    end

    -- otherMouseUp
    local wasClick = drag.dist <= CLICK_SLOP
    drag = nil
    if wasClick then
      repostMiddleClick()
    end
    return true
  end
)
tap:start()

return tap -- caller must hold the reference or the tap is garbage collected
