import { buildHudText, buildManipulators, HyperApp } from "./lib/hyper_layer";

/**
 * Single source of truth for the Hyper (⇪ + o) app-launcher layer.
 * Editing this list updates the Karabiner mappings AND the HUD / native
 * notification text together; the machinery lives in lib/hyper_layer.ts.
 */
export const hyperApps: HyperApp[] = [
  { key: "b", app: "Vivaldi" },
  { key: "s", app: "Slack" },
  { key: "z", app: "Zoom" },
  { key: "e", app: "Microsoft Outlook", label: "Mail" },
  { key: "c", app: "Cursor" },
  { key: "t", app: "Ghostty" },
  { key: "v", app: "Visual Studio Code", label: "Code" },
  { key: "n", app: "Obsidian" },
];

export const hyperManipulators = buildManipulators(hyperApps);

/** Title + key→app grid, shared by the Hammerspoon HUD and the native fallback. */
export const hyperHudText = buildHudText("🚀  HYPER LAYER", hyperApps);
