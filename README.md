# Using karabiner.ts

This is the examples/starter repo to get started with [karabiner.ts](https://github.com/evan-liu/karabiner.ts) for [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) config:

## Examples

- [./src/index.ts](./src/index.ts).

## Usage as Starter

(Install [Node.js](https://nodejs.org/en) first if not already installed)

1. [Download](https://github.com/evan-liu/karabiner.ts.examples/archive/refs/heads/main.zip) (or clone | [fork](https://github.com/evan-liu/karabiner.ts.examples/fork)) this repo.
2. Run `npm install`.
3. Update to your own [configs](./src/index.ts).
4. Set the profile name. Create a new Karabiner-Elements profile if needed.
5. Run `npm run build`.

### Hyper-layer HUD (Hammerspoon)

The Hyper (⇪ + `o`) app launcher shows a Hammerspoon HUD instead of the
built-in Karabiner notification.

1. `brew install --cask hammerspoon`, open it once, grant Accessibility.
2. `npm run install-hud` — symlinks `~/.hammerspoon/init.lua` to
   [`hammerspoon/init.lua`](./hammerspoon/init.lua) (backs up any existing file).
3. `npm run deploy`.

`npm run deploy` is gated and fails unless Hammerspoon is set up. To skip the
HUD and use the built-in notification box: `KW_NOTIFY=native npm run deploy`.

### Update karabiner.ts

Run `npm run update` to update `karabiner.ts` to latest version.

## Other examples

- [evan-liu/karabiner-config](https://github.com/evan-liu/karabiner-config/blob/main/src/index.ts)
