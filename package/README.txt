# Quiet Dawn HUD - Auto-hide HUD

A quiet view of the world, with the essentials returning when you need them.

Quiet Dawn HUD - Auto-hide HUD is a standalone HUD mod for **The Blood of Dawnwalker**. Health/stamina panels, compass, quest tracker, quickslots, and crosshair are hidden by default. HUD preset and focus events refresh their visibility for combat, drawn weapons, lock-on, and focus. **F8** toggles a persistent manual reveal.

Interaction prompts, dialogue, subtitles, notifications, boss bars, ability panels, and menus retain their normal game behavior. Revealing a panel restores its original opacity; it does not force the game to display a panel that its current HUD preset has hidden.

## Requirements and compatibility

- A Dawnwalker-compatible UE4SS build exposing `LoopInGameThreadWithDelay` and `KismetSystemLibrary.GetFrameCount`. Development reference: UE4SS commit `97b7e501c`.
- Game asset reference: Steam build **25129649**, executable CL-257186.
- **Development build: in-game validation is pending.** Event coverage, visibility transitions, and frame times have not yet been measured in the game.
- Disable **HUD Tweaks and HUD Tweaks - Fixes** before enabling this mod. Different filenames do not prevent competing runtime opacity changes. Neither is a dependency.
- Other mods that change the managed panels or the HUD Blueprint require compatibility testing.

## Install, update, and remove

1. Close the game. In Vortex, disable HUD Tweaks and its Fixes submod, then deploy.
2. Import `Quiet-Dawn-HUD.zip` (standard) or `Quiet-Dawn-HUD-Show-Compass.zip` (optional Show Compass version), enable it, and deploy. The installer must select **UE4SS (Lua mods)**.
3. The payload belongs under `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`. Start the game normally; live Lua reload is not supported.

For updates, back up any configuration changes and replace the existing Quiet Dawn HUD - Auto-hide HUD entry using the same ZIP filename. The shipped configuration is a full replacement, not an automatic merge. If Vortex chose an incorrect layout, remove/reinstall the archive through its installer; redeployment alone preserves the incorrect layout.

To uninstall, close the game, disable/remove Quiet Dawn HUD - Auto-hide HUD in Vortex, and deploy. You can then re-enable your previous HUD mods. No save-game changes are made.

## Optional Show Compass version

`Quiet-Dawn-HUD-Show-Compass.zip` is a complete alternative package. It leaves the compass under normal game control while the other five panels still auto-hide. The compass stays available during exploration; the game can still hide it in menus, dialogue, or other special states.

Install **one version only**. Both versions use the same internal mod ID and runtime paths. To switch, close the game, back up your configuration, disable/remove the previous entry in Vortex and deploy, then import the other ZIP, enable it, and deploy. Do not keep both enabled or set conflict winners between them.

## Configuration

Edit `Scripts/QuietDawnConfig.lua` through your normal mod configuration workflow, then restart the game. Do not edit a deployed hardlink directly.

The standard configuration lists six managed panels; Show Compass lists five and omits `WBP_Compass`. Remove an entry to leave that panel under game control. `showWeaponDrawn`, `showInFocus`, and `showLockedOn` control those reveal conditions. Combat also reveals the panels when the current world's combat subsystem is available. `manualRevealKey` defaults to `F8`; set it to `nil` to omit the shortcut. `enabled = false` disables the mod at startup.

## How it works

The mod reacts to HUD construction/activation, preset push/pop, player restart, and focus callbacks. It reads current state at those events and updates at most one named panel per frame. Six panels normally settle over several frames; there is no fade animation or idle activity poll. Interaction/UI events outside this set are intentionally left to the game.

Initialization and missing-widget retries are finite. Once a job finishes, its worker stops. No widget-tree enumeration or global HUD search runs. If a required hook is unavailable, initialization waits for a later lifecycle event. Missing player state reveals managed panels when possible.

The Lua entry point passed mocked startup, 600-second idle, event-burst, ownership/world replacement, delayed-widget, failed-registration, and frame-budget checks. These establish bounded work in the tests, not in-game reliability or an FPS improvement. Test a fresh launch, save loading, death/respawn, weapon draw/sheath, combat enter/exit, focus, dialogue, and F8 before relying on this development build.

## License

MIT. A standalone implementation informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS binaries are included.
