import { rule, map } from "karabiner.ts"

export const rules = [
    rule('Caps Lock → Hyper/Escape')
    .description('Caps Lock is escape if pressed alone or hyper when pressed with modifier.')
    .manipulators([
        map('caps_lock')
        .toHyper()
        .toIfAlone('escape')
    ]),
]


