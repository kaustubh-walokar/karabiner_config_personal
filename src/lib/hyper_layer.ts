import { to$ } from "karabiner.ts";

export type HyperApp = { key: string; app: string; label?: string };

// Karabiner consumes layer keys, so a pressed app key emits no real key event;
// dismiss the HUD here. Both actions go in ONE shell_command — a second
// adjacent shell_command to-event is dropped by Karabiner's executor.
export const buildManipulators = (apps: HyperApp[]) =>
  Object.fromEntries(
    apps.map(({ key, app }) => [
      key,
      to$(`open -g "hammerspoon://hyperhide" ; open -a "${app}".app`),
    ])
  );

// Lay the bindings out as a 2-column monospace grid for the HUD/notification.
export const buildHudText = (title: string, apps: HyperApp[]) => {
  const cells = apps.map(({ key, app, label }) => `${key} → ${label ?? app}`);
  const colW = Math.max(...cells.map((c) => c.length)) + 4;
  const rows: string[] = [];
  for (let i = 0; i < cells.length; i += 2) {
    rows.push((cells[i].padEnd(colW) + (cells[i + 1] ?? "")).trimEnd());
  }
  return [title, "", ...rows].join("\n");
};
