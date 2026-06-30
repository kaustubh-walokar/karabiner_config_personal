// predeploy gate: refuse to deploy the Hammerspoon HUD unless Hammerspoon is
// actually installed and configured. Bypass with KW_NOTIFY=native, which makes
// the generator fall back to Karabiner's built-in notification box.
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

if (process.env.KW_NOTIFY === "native") {
  console.log("KW_NOTIFY=native → using built-in Karabiner notification.");
  process.exit(0);
}

const app = "/Applications/Hammerspoon.app";
const cfg = join(homedir(), ".hammerspoon", "init.lua");
const missing = [
  !existsSync(app) && `  - Hammerspoon not installed (${app})`,
  !existsSync(cfg) && `  - config missing (${cfg})`,
].filter(Boolean);

if (missing.length) {
  console.error(
    [
      "✗ Hyper HUD deploy blocked — Hammerspoon is not ready:",
      ...missing,
      "",
      "Fix it:  brew install --cask hammerspoon   (then open it once, grant Accessibility)",
      "Or fall back to the native notification:  KW_NOTIFY=native npm run deploy",
    ].join("\n")
  );
  process.exit(1);
}

console.log("✓ Hammerspoon ready — deploying Hyper HUD.");
