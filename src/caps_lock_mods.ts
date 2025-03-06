import { rule, map, simlayer, withModifier } from "karabiner.ts"

export const rules = [
    rule('Caps Lock → Hyper/Escape')
    .description('Caps Lock is escape if pressed alone or hyper when pressed with modifier.')
    .manipulators([
        map('caps_lock')
        .toHyper()
        .toIfAlone('escape'),
    ]),
    simlayer('o', 'Open Apps with Hyper')
    .description('Open Apps with Hyper')
    .manipulators([withModifier('Hyper')([
        map('b').to$(`open -a "Firefox"`),
        map('s').to$(`open -a "Slack"`),
        map('t').to$(`open -a "Ghostty"`),
        map('i').to$(`open -a "IntelliJ IDEA Ultimate"`),
    ])]),
]


