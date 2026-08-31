// Opt+Shift+Tab cycles the active OmniWM workspace across monitors with
// wrap-around (aerospace's `move-workspace-to-monitor --wrap-around next`).
// OmniWM hotkeys are directional-only with no wrap, so Karabiner intercepts
// the key and drives omniwmctl through the cycle script instead. The script
// queries displays at runtime, so it works across different monitor setups.
// OmniWM keeps the same keys bound to its directional moves as a fallback
// for when Karabiner is not running.
import {
  ifVar,
  map,
  mapPointingButton,
  mouseMotionToScroll,
  rule,
  toSetVar,
} from "karabiner.ts";

const CYCLE = "/Users/kaustubw/.config/omniwm/cycle-workspace-monitor.py";

export const rules = [
  rule("Opt+Shift+Tab → OmniWM workspace to next monitor (wraps)")
    .description("Cycle active OmniWM workspace across monitors")
    .manipulators([
      map("tab", ["option", "shift"]).to$(`${CYCLE} next`),
      map("tab", ["control", "option", "shift"]).to$(`${CYCLE} prev`),
    ]),
  // Hold middle button and move the mouse to scroll OmniWM's column strip,
  // trackpad-style. Karabiner turns motion into scroll-wheel events and
  // holds Opt+Shift for the duration, which is OmniWM's wheel-scroll
  // modifier (settings.toml gestures.scrollModifierKey = optionShift).
  // Momentum is off because momentum events would arrive after the
  // modifiers are released and leak into the app under the cursor.
  // A quick middle click without motion still clicks.
  rule("Middle-hold + mouse motion → OmniWM column scroll")
    .description("Middle-drag scrolls OmniWM columns like a trackpad")
    .manipulators([
      mapPointingButton("button3")
        .to(toSetVar("omniwm_mouse_scroll", 1, 0))
        .to({ key_code: "left_shift", modifiers: ["left_option"] })
        .toIfAlone({ pointing_button: "button3" }),
      mouseMotionToScroll()
        .condition(ifVar("omniwm_mouse_scroll", 1))
        .options({ momentum_scroll_enabled: false }),
    ]),
];
