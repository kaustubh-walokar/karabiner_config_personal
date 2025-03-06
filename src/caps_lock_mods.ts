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
            map('a', 'Hyper').to$(`open -a "Google Chrome"`),
            map('s', 'Hyper').to$(`open -a "Slack"`),
            map('t', 'Hyper').to$(`open -a "iTerm"`),
            map('v', 'Hyper').to$(`open -a "Visual Studio Code"`),
            map('w', 'Hyper').to$(`open -a "WhatsApp"`),
        ]),
]


