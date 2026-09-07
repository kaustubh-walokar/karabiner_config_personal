import {
  buildDirectManipulators,
  buildHudText,
  buildManipulators,
  HyperApp,
} from "./lib/hyper_layer";

/**
 * Single source of truth for the Hyper (⇪ + o) app-launcher layer.
 * Editing this list updates the Karabiner mappings AND the HUD / native
 * notification text together; the machinery lives in lib/hyper_layer.ts.
 */
export const hyperApps: HyperApp[] = [
  { key: "v", app: "Vivaldi" },
  { key: "s", app: "Slack" },
  { key: "z", app: "zoom.us", label: "Zoom" },
  { key: "o", app: "Microsoft Outlook", label: "Mail" },
  { key: "c", app: "Cursor" },
  { key: "g", app: "Ghostty" },
  { key: "d", app: "Visual Studio Code", label: "Code" },
  { key: "n", app: "Obsidian" },
];

/** Direct Hyper+key launches (current mode). */
export const hyperDirectManipulators = buildDirectManipulators(hyperApps);

/** Legacy leader-layer manipulators, kept for an easy way back. */
export const hyperManipulators = buildManipulators(hyperApps);

/** Title + key→app grid, shared by the Hammerspoon HUD and the native fallback. */
export const hyperHudText = buildHudText("🚀  HYPER LAYER", hyperApps);
