// Symlink every hammerspoon/*.lua in this repo into ~/.hammerspoon, so the
// repo is the source of truth. Backs up any existing real file first.
import {
  lstatSync,
  mkdirSync,
  readdirSync,
  readlinkSync,
  renameSync,
  symlinkSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const srcDir = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "hammerspoon"
);
const dir = join(homedir(), ".hammerspoon");
mkdirSync(dir, { recursive: true });

for (const name of readdirSync(srcDir).filter((f) => f.endsWith(".lua"))) {
  const repoSrc = join(srcDir, name);
  const dest = join(dir, name);
  const st = lstatSync(dest, { throwIfNoEntry: false });
  if (st) {
    if (st.isSymbolicLink() && resolve(dir, readlinkSync(dest)) === repoSrc) {
      console.log("✓ Already linked:", dest, "->", repoSrc);
      continue;
    }
    const backup = `${dest}.bak-${Date.now()}`;
    renameSync(dest, backup);
    console.log("Backed up existing", name, "->", backup);
  }
  symlinkSync(repoSrc, dest);
  console.log("✓ Linked", dest, "->", repoSrc);
}
console.log("  Reload: click the Hammerspoon menu-bar icon → Reload Config.");
