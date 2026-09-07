import { rule, map } from "karabiner.ts";
import { hyperDirectManipulators } from "./hyper_apps";

// Hyper+key launches apps DIRECTLY (no leader layer). The previous
// hyperLayer("o") leader — with its Hammerspoon HUD via
// `open -g "hammerspoon://hyperhud?text=..."` and leaderMode escapes —
// was retired 2026-09-07; hyper_apps.ts still exports hyperManipulators
// and hyperHudText if the layer ever needs restoring, and the HUD
// renderer remains in hammerspoon/init.lua.
export const rules = [
  rule("Caps Lock → Hyper/Escape")
    .description(
      "Caps Lock is escape if pressed alone or hyper when pressed with modifier."
    )
    .manipulators([map("caps_lock").toHyper().toIfAlone("escape")]),
  rule("Hyper+key → launch app")
    .description("Direct app launch on Hyper")
    .manipulators(hyperDirectManipulators),
];
