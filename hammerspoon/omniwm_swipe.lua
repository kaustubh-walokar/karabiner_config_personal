-- Middle-button swipe -> one OmniWM focus step per gesture.
--
-- Hold the middle button and drag horizontally: the first TRIGGER_PX of
-- motion fires a single `omniwmctl command focus <dir>`, then the gesture
-- latches until release. Runs over OmniWM's IPC (requires
-- general.ipcEnabled = true in settings.toml) rather than synthetic
-- keystrokes, so nothing can leak into the focused app; works on niri and
-- dwindle workspaces alike.
--
-- A quick press without motion is reposted as a normal middle click, tagged
-- so this tap ignores its own events. Trade-off: apps that use middle-drag
-- natively (CAD, Blender) lose that gesture while this is loaded.

local ev = hs.eventtap.event
local types = ev.types
local props = ev.properties

-- Configuration --------------------------------------------------------------
local NATURAL_SCROLLING = true -- content follows the hand: drag right -> focus left
local TRIGGER_PX = 25 -- horizontal motion that fires the gesture
local CLICK_SLOP = 5 -- max total motion for a release to still count as a click
local OMNIWMCTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"
--------------------------------------------------------------------------------

local SYNTH_TAG = 0x0771 -- marks clicks this tap reposts, so it skips them

local drag -- nil while idle; { dist, acc, fired } while the middle button is held

local function focusStep(direction)
  hs.task.new(OMNIWMCTL, nil, { "command", "focus", direction }):start()
end

local function directionFor(acc)
  local draggedRight = acc > 0
  if NATURAL_SCROLLING then
    return draggedRight and "left" or "right"
  end
  return draggedRight and "right" or "left"
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
      drag = { dist = 0, acc = 0, fired = false }
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
      drag.acc = drag.acc + dx
      if not drag.fired and math.abs(drag.acc) >= TRIGGER_PX then
        drag.fired = true
        focusStep(directionFor(drag.acc))
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
