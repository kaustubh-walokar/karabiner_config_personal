import { FromAndToKeyCode, map, rule, ToKeyCode } from "karabiner.ts";

const mappings: HomeRowModifications[] = [
  { from: "spacebar", to: "left_shift" },
  { from: "f", to: "left_command" },
];

export const rules = [
  rule(`HomeRow and Spacebar modifications`).manipulators(
    mappings.map((x) => ruleForCharToModifier(x))
  ),
];

interface HomeRowModifications {
  from: FromAndToKeyCode;
  to: ToKeyCode;
}

function ruleForCharToModifier({ from, to }: HomeRowModifications) {
  return map(from)
    .description(`${from} -> ${to} if held down`)
    .toIfHeldDown({ key_code: to })
    .toIfAlone(from)
    .parameters({ "basic.to_if_held_down_threshold_milliseconds": 100 });
}
