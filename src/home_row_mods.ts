import {
  BasicParameters,
  FromAndToKeyCode,
  map,
  rule,
  toKey,
  ToKeyCode,
} from "karabiner.ts";

const modifierMappings: Record<FromAndToKeyCode, ToKeyCode> = {
  spacebar: "left_shift",
  f: "left_command",
  j: "right_command",

  d: "left_option",
  k: "right_option",

  s: "left_control",
  l: "right_control",

  a: "left_shift",
  semicolon: "right_shift",
};

export const rules = [
  rule(`HomeRow and Spacebar modifications one at a time`).manipulators(
    Object.entries(modifierMappings).map(([from, to]) =>
      ruleForCharToModifier({
        from: from as FromAndToKeyCode,
        to: to as ToKeyCode,
      })
    )
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
