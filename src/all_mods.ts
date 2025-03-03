import { writeToProfile } from "karabiner.ts"
import { rules as caps_lock_mods } from "./caps_lock_mods"
const params = {
    'basic.to_if_alone_timeout_milliseconds': 1000,
    'basic.to_if_held_down_threshold_milliseconds': 500,
    'basic.to_delayed_action_delay_milliseconds': 500,
    'basic.simultaneous_threshold_milliseconds': 50,
    'mouse_motion_to_scroll.speed': 100,
    'simlayer.threshold_milliseconds': 200,
    'double_tap.delay_milliseconds': 200,
}

const all_mods = [
    ...caps_lock_mods 
]

const target = process.env.WRITE_TARGET;

if (target) {
    writeToProfile("--dry-run" , all_mods, params)
} else {
    console.error("MY_PARAM environment variable not set.");
}
