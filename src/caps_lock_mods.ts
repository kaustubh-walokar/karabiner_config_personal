import { rule, map } from "karabiner.ts"

export const rules = [
    rule('Caps Lock → Hyper/Escape')
        .description('Caps Lock is escape if pressed alone or hyper when pressed with modifier.')
        .manipulators([
            map('caps_lock')
            .toHyper()
            .toIfAlone('escape')
        ]),
    rule('Shift + Caps Lock → Caps Lock')
        .description('Caps Lock is capslock if pressed with shift.')
        .manipulators([
            map('caps_lock', 'shift')
            .to('caps_lock')
        ])
]


