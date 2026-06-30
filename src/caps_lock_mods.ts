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
    .notification(
      [
        "🚀  HYPER LAYER",
        "b → Vivaldi     c → Cursor     s → Slack     z → Zoom",
        "e → Mail        t → Warp       v → Code      n → Obsidian",
      ].join("\n")
    )
    .manipulators({
      // communication
      b: toApp("Vivaldi"),
      s: toApp("Slack"),
      z: toApp("Zoom"),
      e: toApp("Microsoft Outlook"),
      // development
      c: toApp("Cursor"),
      t: toApp("Warp"),
      v: toApp("Visual Studio Code"),
      // productivity
      n: toApp("Obsidian"),
    }),
];
