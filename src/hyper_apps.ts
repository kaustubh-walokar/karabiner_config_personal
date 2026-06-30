import { to$ } from "karabiner.ts";

type HyperApp = { key: string; app: string; label?: string };

/**
 * Single source of truth for the Hyper (⇪ + o) app-launcher layer.
 * Editing this list updates the Karabiner mappings AND the HUD / native
 * notification text together.
 */
export const hyperApps: HyperApp[] = [
  { key: "b", app: "Vivaldi" },
  { key: "s", app: "Slack" },
  { key: "z", app: "Zoom" },
  { key: "e", app: "Microsoft Outlook", label: "Mail" },
  { key: "c", app: "Cursor" },
  { key: "t", app: "Warp" },
  { key: "v", app: "Visual Studio Code", label: "Code" },
  { key: "n", app: "Obsidian" },
];

// Karabiner consumes layer keys, so a pressed app key emits no real key event;
// dismiss the HUD here. Both actions go in ONE shell_command — a second
// adjacent shell_command to-event is dropped by Karabiner's executor.
export const hyperManipulators = Object.fromEntries(
  hyperApps.map(({ key, app }) => [
    key,
    to$(`open -g "hammerspoon://hyperhide" ; open -a "${app}".app`),
  ])
);

// Lay the bindings out as a 2-column monospace grid for the HUD/notification.
const cells = hyperApps.map(
  ({ key, app, label }) => `${key} → ${label ?? app}`
);
const colW = Math.max(...cells.map((c) => c.length)) + 4;
const rows: string[] = [];
for (let i = 0; i < cells.length; i += 2) {
  rows.push((cells[i].padEnd(colW) + (cells[i + 1] ?? "")).trimEnd());
}

/** Title + key→app grid, shared by the Hammerspoon HUD and the native fallback. */
export const hyperHudText = ["🚀  HYPER LAYER", "", ...rows].join("\n");
