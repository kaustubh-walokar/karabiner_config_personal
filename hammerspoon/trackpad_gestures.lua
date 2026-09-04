-- Trackpad gestures via the vendored Swipe.spoon (MIT, mogenson/Swipe.spoon,
-- which reads three-finger swipes from hs.eventtap gesture events):
-- three-finger swipe up opens OmniWM's Overview through the CLI. Once per
-- swipe: the first crossing of THRESHOLD fires, then the gesture latches
-- until the fingers lift (new swipe id).
--
-- NOTE: set System Settings > Trackpad > More Gestures > Mission Control to
-- four fingers or off; on its default three-finger setting macOS fires
-- Mission Control on the same swipe and both overviews open.

local OMNIWMCTL = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"
local THRESHOLD = 0.2 -- fraction of trackpad height the swipe must travel

local swipe = hs.loadSpoon("Swipe")

local currentId, fired
swipe:start(3, function(direction, distance, id)
  if id ~= currentId then
    currentId, fired = id, false
  end
  if not fired and direction == "up" and distance > THRESHOLD then
    fired = true
    hs.task.new(OMNIWMCTL, nil, { "command", "toggle-overview" }):start()
  end
end)

return swipe
