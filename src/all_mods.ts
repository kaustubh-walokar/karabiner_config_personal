import { writeToProfile } from 'karabiner.ts'
import { rules as caps_lock_mods } from './caps_lock_mods'
import { rules as tab_mods } from './tab_mods'
import { rules as fn_5_mute } from './fn_5_mute'

const params = {
  'basic.to_if_alone_timeout_milliseconds': 1000,
  'basic.to_if_held_down_threshold_milliseconds': 500,
  'basic.to_delayed_action_delay_milliseconds': 500,
  'basic.simultaneous_threshold_milliseconds': 50,
  'mouse_motion_to_scroll.speed': 100,
  'simlayer.threshold_milliseconds': 500,
  'double_tap.delay_milliseconds': 200,
}

const all_mods = [...caps_lock_mods, ...tab_mods, ...fn_5_mute]

const target = process.env.WRITE_TARGET

if (target) {
  writeToProfile(target, all_mods, params)
} else {
  console.error('WRITE_TARGET environment variable not set.')
}
