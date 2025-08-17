import { map, rule } from "karabiner.ts";

export const simple_mappings = [
  rule("Right Cmd -> Super")
    .description("map right command to super aka hyper key")
    .manipulators([map("right_command").toMeh()]),
];
