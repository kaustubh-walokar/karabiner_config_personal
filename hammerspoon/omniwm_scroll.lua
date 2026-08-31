-- Middle-button swipe steps OmniWM focus through its CLI: swipe left runs
-- `omniwmctl command focus left`, swipe right `focus right`. One gesture =
-- one step: the first STEP_PX of horizontal motion fires, then the gesture
-- latches until the button is released. The CLI (IPC) path is preferred over
-- synthetic Alt+H/L keystrokes so nothing can leak into the focused app,
-- and it works on niri and dwindle workspaces alike. Requires
-- general.ipcEnabled = true in OmniWM's settings.toml.
--
-- A quick middle press without motion is reposted as a normal middle click,
-- tagged so this tap ignores its own synthetic events. Trade-off: apps that
-- use middle-drag directly (CAD, Blender) lose that gesture while this is on.

local ev = hs.eventtap.event
local types = ev.types
local props = ev.properties

local STEP_PX = 60 -- horizontal pixels of drag per focus step
local CLICK_SLOP = 5 -- max px of motion for a release to still count as a click
local SYNTH_TAG = 0x0771 -- marks our reposted clicks
local CTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"

local function focusStep(direction)
  hs.task.new(CTL, nil, { "command", "focus", direction }):start()
end

local drag = { active = false, dist = 0, acc = 0, fired = false }

local tap = hs.eventtap.new(
  { types.otherMouseDown, types.otherMouseUp, types.otherMouseDragged },
  function(e)
    if e:getProperty(props.eventSourceUserData) == SYNTH_TAG then
      return false -- our own reposted click; let it through
    end
    if e:getProperty(props.mouseEventButtonNumber) ~= 2 then
      return false
    end
    local t = e:getType()
    if t == types.otherMouseDown then
      drag.active = true
      drag.dist = 0
      drag.acc = 0
      drag.fired = false
      return true
    end
    if t == types.otherMouseDragged and drag.active then
      local dx = e:getProperty(props.mouseEventDeltaX)
      local dy = e:getProperty(props.mouseEventDeltaY)
      drag.dist = drag.dist + math.abs(dx) + math.abs(dy)
      drag.acc = drag.acc + dx
      if not drag.fired then
        -- natural direction: content follows the hand, like a trackpad swipe
        if drag.acc >= STEP_PX then
          focusStep("left")
          drag.fired = true
        elseif drag.acc <= -STEP_PX then
          focusStep("right")
          drag.fired = true
        end
      end
      return true
    end
    if t == types.otherMouseUp then
      local wasClick = drag.active and drag.dist <= CLICK_SLOP
      drag.active = false
      if wasClick then
        local pos = hs.mouse.absolutePosition()
        for _, click in ipairs({ types.otherMouseDown, types.otherMouseUp }) do
          local c = ev.newMouseEvent(click, pos)
          c:setProperty(props.mouseEventButtonNumber, 2)
          c:setProperty(props.eventSourceUserData, SYNTH_TAG)
          c:post()
        end
      end
      return true
    end
    return false
  end
)
tap:start()

return tap -- caller must hold the reference or the tap gets garbage collected
