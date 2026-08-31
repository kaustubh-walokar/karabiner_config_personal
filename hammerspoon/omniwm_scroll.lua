-- Middle-button drag scrolls OmniWM's niri column strip, standing in for the
-- three-finger trackpad swipe on a mouse.
--
-- OmniWM cannot see synthetic multitouch (it reads raw trackpad hardware), but
-- its mouse-wheel path accepts scroll events carrying the
-- gestures.scrollModifierKey modifiers (Option+Shift here), horizontal delta
-- preferred, one column step per ~120 px. So: swallow middle-button drags and
-- repost the motion as modifier-tagged pixel scroll events.
--
-- A quick middle press without motion is reposted as a normal middle click,
-- tagged so this tap ignores its own synthetic events. Trade-off: apps that
-- use middle-drag directly (CAD, Blender) lose that gesture while this is on.

local ev = hs.eventtap.event
local types = ev.types
local props = ev.properties

local SPEED = 1.0 -- mouse px -> scroll px; OmniWM steps one column per ~120
local INVERT = false -- flip if the strip moves opposite to your drag
local CLICK_SLOP = 5 -- max px of motion for a release to still count as a click
local SCROLL_MODS = { "alt", "shift" } -- OmniWM gestures.scrollModifierKey = optionShift
local SYNTH_TAG = 0x0771 -- marks our reposted clicks

local drag = { active = false, dist = 0 }

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
      return true
    end
    if t == types.otherMouseDragged and drag.active then
      local dx = e:getProperty(props.mouseEventDeltaX)
      local dy = e:getProperty(props.mouseEventDeltaY)
      drag.dist = drag.dist + math.abs(dx) + math.abs(dy)
      local sign = INVERT and -1 or 1
      -- offsets are {horizontal, vertical}, verified by probing axis2/axis1
      ev.newScrollEvent({ sign * dx * SPEED, sign * dy * SPEED }, SCROLL_MODS, "pixel"):post()
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
