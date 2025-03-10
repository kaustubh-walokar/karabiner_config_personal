import { rule, map } from "karabiner.ts";

export const rules = [
  rule("Tab → Meh/Tab")
    .description(
      "Tab is tab if pressed alone or Meh when pressed with modifier."
    )
    .manipulators([map("tab").toMeh().toIfAlone("tab")]),
];
