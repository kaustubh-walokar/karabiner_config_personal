import { map, rule } from "karabiner.ts";

export const rules = [
  rule("Space -> Shift if held down")
    .description(
      "Space is space if pressed alone or shift when pressed with modifier."
    )
    .manipulators([
      map("spacebar")
        .toIfHeldDown({ key_code: "left_shift", hold_down_milliseconds: 100 })
        .toIfAlone("spacebar"),
    ]),
];
