// Symlink ~/.hammerspoon/init.lua -> this repo's hammerspoon/init.lua, so the
// repo is the source of truth. Backs up any existing real file first.
import { existsSync, lstatSync, mkdirSync, readlinkSync, renameSync, symlinkSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoSrc = resolve(dirname(fileURLToPath(import.meta.url)), "..", "hammerspoon", "init.lua");
const dir = join(homedir(), ".hammerspoon");
const dest = join(dir, "init.lua");

mkdirSync(dir, { recursive: true });

if (existsSync(dest) || lstatSync(dest, { throwIfNoEntry: false })) {
  const st = lstatSync(dest);
  if (st.isSymbolicLink() && resolve(dir, readlinkSync(dest)) === repoSrc) {
    console.log("✓ Already linked:", dest, "->", repoSrc);
    process.exit(0);
  }
  const backup = `${dest}.bak-${Date.now()}`;
  renameSync(dest, backup);
  console.log("Backed up existing init.lua ->", backup);
}

symlinkSync(repoSrc, dest);
console.log("✓ Linked", dest, "->", repoSrc);
console.log("  Reload: click the Hammerspoon menu-bar icon → Reload Config.");
