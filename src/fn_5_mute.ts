// pressing f5 invokes the mute applescript
import { rule, map } from "karabiner.ts"

export const rules = [
    rule('F5 → Mute')
        .description('F5 → Mute')
        .manipulators([
            map('f5')
                .to$(`osascript /Users/kaustubw/scripts/muteAllApps.scpt`)
            // map('caps_lock', 'shift')
            //     .to('caps_lock')
        ])
]