import { rule, map, simlayer, withModifier } from 'karabiner.ts'

export const rules = [
  rule('Caps Lock → Hyper/Escape')
    .description(
      'Caps Lock is escape if pressed alone or hyper when pressed with modifier.',
    )
    .manipulators([map('caps_lock').toHyper().toIfAlone('escape')]),
  simlayer('o', 'Open Apps with Hyper')
    .description('Open Apps with Hyper')
    .manipulators([
      withModifier('Hyper')([
        map('b').to$(`open -a "Firefox"`), // browser
        // communication
        map('s').to$(`open -a "Slack"`), // slack
        map('c').to$(`open -a "Amazon Chime"`), // chime
        map('z').to$(`open -a "Zoom"`), // zoom
        map('e').to$(`open -a "Microsoft Outlook"`), // mail
        // development
        map('t').to$(`open -a "Ghostty"`), // terminal
        map('v').to$(`open -a "Visual Studio Code"`),
        map('i').to$(`open -a "IntelliJ IDEA Ultimate"`),
      ]),
    ]),
]
