import { rule, map, simlayer } from "karabiner.ts"

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
        .manipulators([
            map('b', 'Hyper').to$(`open -a "Firefox"`),
            map('s', 'Hyper').to$(`open -a "Slack"`),
            map('t', 'Hyper').to$(`open -a "Ghostty"`),
            map('i', 'Hyper').to$(`open -a "IntelliJ IDEA Ultimate"`),
        ]),
]


