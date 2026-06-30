import { rule, map, hyperLayer } from "karabiner.ts";
import { hyperManipulators, hyperHudText } from "./hyper_apps";

// KW_NOTIFY=native uses Karabiner's built-in notification box instead of the
// Hammerspoon HUD (set by the predeploy gate when Hammerspoon isn't present).
const useNative = process.env.KW_NOTIFY === "native";
const hudUrl = `hammerspoon://hyperhud?text=${encodeURIComponent(
  hyperHudText
)}`;

const hyper = hyperLayer("o", "Open Apps with Hyper")
  .description("Open Apps with Hyper")
  .leaderMode({ escape: ["escape", "spacebar", "caps_lock", "o"] });

if (useNative) {
  hyper.notification(hyperHudText);
} else {
  hyper.configKey((k) => k.to$(`open -g "${hudUrl}"`));
}

export const rules = [
  rule("Caps Lock → Hyper/Escape")
    .description(
      "Caps Lock is escape if pressed alone or hyper when pressed with modifier."
    )
    .manipulators([map("caps_lock").toHyper().toIfAlone("escape")]),
  hyper.manipulators(hyperManipulators),
];
