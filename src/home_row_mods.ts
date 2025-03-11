import {
  BasicParameters,
  FromAndToKeyCode,
  map,
  rule,
  toKey,
  ToKeyCode,
} from "karabiner.ts";

const modifierMappings: Partial<Record<FromAndToKeyCode, ToKeyCode>> = {
  // comand group
  d: "left_command",
  k: "right_command",

  //option group
  s: "left_option",
  l: "right_option",

  //control group
  a: "left_control",
  semicolon: "right_control",

  //shift group
  f: "left_shift",
  j: "right_shift",
};

const twoAtATimeMappings: [FromAndToKeyCode, FromAndToKeyCode][] = [];
// generate all possible mappings taken two at a time in a for loop picking one from each group
for (let i = 0; i < Object.keys(modifierMappings).length; i += 2) {
  for (let j = i + 2; j < Object.keys(modifierMappings).length; j += 2) {
    {
      const first = Object.keys(modifierMappings)[i];
      const second = Object.keys(modifierMappings)[j];
      twoAtATimeMappings.push([
        first as FromAndToKeyCode,
        second as FromAndToKeyCode,
      ]);
    }
    {
      const first = Object.keys(modifierMappings)[i + 1];
      const second = Object.keys(modifierMappings)[j + 1];
      twoAtATimeMappings.push([
        first as FromAndToKeyCode,
        second as FromAndToKeyCode,
      ]);
    }
  }
}

export const rules = [
  rule(`HomeRow and Spacebar modifications one at a time`).manipulators(
    Object.entries(modifierMappings).map(([from, to]) =>
      ruleForCharToModifier({
        from: from as FromAndToKeyCode,
        to: to as ToKeyCode,
      })
    )
  ),
  // does not work as expected
  // rule(`HomeRow and Spacebar modifications two at a time`).manipulators(
  //   twoAtATimeMappings.map(([a, b]) =>
  //     mapSimultaneous([a, b], { key_down_order: "strict" })
  //       .description(
  //         `${a} and ${b} -> ${modifierMappings[a]} and ${modifierMappings[b]} if held down`
  //       )
  //       .toIfAlone(a)
  //       .toIfAlone(b)
  //       .toIfHeldDown([
  //         { key_code: modifierMappings[a]! },
  //         { key_code: modifierMappings[b]! },
  //       ])
  //   )
  // ),
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
