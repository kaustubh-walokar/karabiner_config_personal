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

const link = (repoSrc, dest) => {
  const st = lstatSync(dest, { throwIfNoEntry: false });
  if (st) {
    if (st.isSymbolicLink() && resolve(dirname(dest), readlinkSync(dest)) === repoSrc) {
      console.log("✓ Already linked:", dest, "->", repoSrc);
      return;
    }
    const backup = `${dest}.bak-${Date.now()}`;
    renameSync(dest, backup);
    console.log("Backed up existing", dest, "->", backup);
  }
  symlinkSync(repoSrc, dest);
  console.log("✓ Linked", dest, "->", repoSrc);
};

for (const name of readdirSync(srcDir).filter((f) => f.endsWith(".lua"))) {
  link(join(srcDir, name), join(dir, name));
}

// Vendored Spoons link as whole directories.
const spoonsSrc = join(srcDir, "Spoons");
if (lstatSync(spoonsSrc, { throwIfNoEntry: false })) {
  const spoonsDir = join(dir, "Spoons");
  mkdirSync(spoonsDir, { recursive: true });
  for (const name of readdirSync(spoonsSrc).filter((f) => f.endsWith(".spoon"))) {
    link(join(spoonsSrc, name), join(spoonsDir, name));
  }
}
console.log("  Reload: click the Hammerspoon menu-bar icon → Reload Config.");
