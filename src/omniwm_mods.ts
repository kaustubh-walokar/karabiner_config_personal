// Opt+Shift+Tab cycles the active OmniWM workspace across monitors with
// wrap-around (aerospace's `move-workspace-to-monitor --wrap-around next`).
// OmniWM hotkeys are directional-only with no wrap, so Karabiner intercepts
// the key and drives omniwmctl through the cycle script instead. The script
// queries displays at runtime, so it works across different monitor setups.
// OmniWM keeps the same keys bound to its directional moves as a fallback
// for when Karabiner is not running.
import { map, rule } from "karabiner.ts";

const CYCLE = "/Users/kaustubw/.config/omniwm/cycle-workspace-monitor.py";
const SMART_MAX = "/Users/kaustubw/.config/omniwm/smart-maximize.sh";

export const rules = [
  rule("Opt+Shift+Tab → OmniWM workspace to next monitor (wraps)")
    .description("Cycle active OmniWM workspace across monitors")
    .manipulators([
      map("tab", ["option", "shift"]).to$(`${CYCLE} next`),
      map("tab", ["control", "option", "shift"]).to$(`${CYCLE} prev`),
    ]),
  // Meh+Space: layout-aware maximize. OmniWM hotkeys cannot branch on the
  // active layout, so Karabiner routes the key through a script that picks
  // full-primary-span on niri and overlay fullscreen on dwindle. OmniWM
  // keeps the same key bound to the span toggle as a fallback for when
  // Karabiner is not running.
  rule("Meh+Space → OmniWM layout-aware maximize")
    .description("Maximize: niri span toggle, dwindle fullscreen")
    .manipulators([
      map("spacebar", ["control", "option", "shift"]).to$(`bash ${SMART_MAX}`),
    ]),
];
