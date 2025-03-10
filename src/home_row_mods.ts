import {
  BasicParameters,
  FromAndToKeyCode,
  map,
  rule,
  toKey,
  ToKeyCode,
} from "karabiner.ts";

const mappings: HomeRowModifications[] = [
  { from: "spacebar", to: "left_shift" },

  { from: "f", to: "left_command" },
  { from: "j", to: "right_command" },

  { from: "d", to: "left_option" },
  { from: "k", to: "right_option" },

  { from: "s", to: "left_control" },
  { from: "l", to: "right_control" },

  { from: "a", to: "left_shift" },
  { from: "semicolon", to: "right_shift" },
];

export const rules = [
  rule(`HomeRow and Spacebar modifications`).manipulators(
    mappings.map((x) => ruleForCharToModifier(x))
  ),
];

interface HomeRowModifications {
  from: FromAndToKeyCode;
  to: ToKeyCode;
  paramsOverrides?: BasicParameters;
}

function ruleForCharToModifier({
  from,
  to,
  paramsOverrides,
}: HomeRowModifications) {
  return map(from)
    .description(`${from} -> ${to} if held down`)
    .toIfHeldDown({ key_code: to, halt: true })
    .toIfAlone(from, {}, { halt: true })
    .toDelayedAction(toKey("vk_none"), toKey(from))
    .parameters({
      "basic.to_if_held_down_threshold_milliseconds": 150,
      ...paramsOverrides,
    });
}
