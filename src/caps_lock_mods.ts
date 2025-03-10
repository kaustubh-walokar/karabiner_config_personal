import { rule, map, hyperLayer, toApp } from "karabiner.ts";

export const rules = [
  rule("Caps Lock → Hyper/Escape")
    .description(
      "Caps Lock is escape if pressed alone or hyper when pressed with modifier."
    )
    .manipulators([map("caps_lock").toHyper().toIfAlone("escape")]),
  hyperLayer("o", "Open Apps with Hyper")
    .description("Open Apps with Hyper")
    .leaderMode({ escape: ["escape", "spacebar", "caps_lock", "o"] })
    .notification("Hyper Active")
    .manipulators({
      // communication
      b: toApp("Firefox"),
      s: toApp("Slack"),
      c: toApp("Amazon Chime"),
      z: toApp("Zoom"),
      e: toApp("Microsoft Outlook"),
      // development
      t: toApp("Ghostty"),
      v: toApp("Visual Studio Code"),
      i: toApp("IntelliJ IDEA Ultimate"),
    }),
];
