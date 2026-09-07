# Quiet Dawn HUD - Auto-hide HUD

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. Combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy health:** normal game behavior, always exempt from this mod's hiding.
- **Player health and stamina:** shown together when either value drops, or either is strictly below **20%**.
- **Hide delay:** **1.5 seconds** after the last damage or stamina drop. Further drops restart the relevant delay. Either value below 20% keeps the panel visible; exactly 20% does not qualify by itself.
- **Parry/attack indicators:** normal game behavior, including difficulty restrictions. This mod never enables disabled indicators.

The compass, quest tracker, quickslots and their change prompt, crosshair, control legend, buffs, ability cooldowns, focus panel/charge, special-attack cooldown, and XP bar stay hidden. Interaction prompts, dialogue, subtitles, notifications, boss bars, and menus retain their game behavior. There is no manual whole-HUD reveal shortcut.

## Requirements and compatibility

- Dawnwalker-compatible UE4SS exposing `LoopInGameThreadWithDelay`, `KismetSystemLibrary.GetFrameCount`, and `GetGameTimeInSeconds`. Development reference: commit `97b7e501c`.
- Stock asset/API reference: Steam build **25129649**, executable CL-257186.
- **Development build: in-game validation is pending.** Bar visibility, difficulty variants, and frame times require gameplay testing.
- Disable **HUD Tweaks and HUD Tweaks - Fixes** before enabling this mod. They are not dependencies and can compete over opacity despite having different filenames.
- Mods altering the managed HUD panels require compatibility testing.

## Install, update, and remove

1. Close the game. Disable HUD Tweaks and its Fixes submod in Vortex and deploy.
2. Import `Quiet-Dawn-HUD.zip` or the optional `Quiet-Dawn-HUD-Show-Compass.zip`. Choose **UE4SS (Lua mods)**, enable, and deploy.
3. Runtime files belong under `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`. Restart the game; live Lua reload is not supported.

Install **one version only**. Both archives use the same internal ID and runtime paths. Back up configuration before replacing your existing Vortex entry: the shipped configuration is a full replacement, not an automatic merge. To switch variants, disable/remove the old entry and deploy before importing and enabling the other archive. If the installer selected an incorrect layout, reinstall through the installer; redeployment alone preserves it.

To remove, close the game, disable/remove the mod in Vortex, and deploy. No save-game data is changed.

## Optional Show Compass version

`Quiet-Dawn-HUD-Show-Compass.zip` is a complete alternative. It leaves the compass under normal game control; the game may still hide it in dialogue or other special states. Health/stamina timing and all other settings are identical to the standard version.

## Configuration

Edit `Scripts/QuietDawnConfig.lua` through your normal mod configuration workflow and restart the game. Avoid editing a deployed hardlink directly.

`healthThreshold` and `staminaThreshold` default to `0.20`. `healthHoldSeconds` and `staminaHoldSeconds` default to `1.5`. Either resource can reveal the combined panel. Healing/regeneration alone does not extend the delay. The delay uses game time and pauses with the game. Changes to maximum resource capacity that lower its percentage can also trigger the reveal.

`panels` lists direct HUD fields. Removing a non-stat entry leaves it under game control. The optional configuration omits only `WBP_Compass`. `enabled = false` disables all mod work at startup.

## Behavior and performance

Lifecycle and preset callbacks initialize/reapply the named panels. A bounded sampler reads the current player's health and stamina percentages every **100 ms** because the available UI callbacks do not cover every resource change. Detection can take approximately one sampling interval; panel writes follow on separate frames. A damage/use-and-recovery change entirely between samples may not be observed.

The sampler checks current ownership and stops if the player context or stat readings become unavailable. Recovery occurs on subsequent HUD/player lifecycle events. Missing readings leave the stat panel under normal game visibility when possible. Reveals restore opacity; they do not override the game's visibility presets.

There are no global HUD searches, widget-tree walks, class-default changes, or recurring configuration reads. The panel worker terminates after each job; the two-value sampler continues while the player context is ready. Unchanged samples cause no widget reads or writes. A shared frame guard separates sampling from panel updates. Pending panel work takes priority over the sampler so it can finish even at very low frame rates. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events. Missing fields are not retried on each resource change. Removing both stat panels from the configuration also disables stat sampling.

Archive-based Lua mocks cover strict thresholds, the 1.5-second hold and refresh, shared stat visibility, combat remaining hidden, paused timers, 600-second idle sampling budgets, invalid/missing state, ownership/world replacement, hook failure, event bursts, and the compass option. Packaging checks verify the actual ZIP bytes and installed Vortex installer plan. These are offline checks, not proof of in-game correctness or an FPS improvement. Check fresh launch, loading/respawn, both player forms, damage, stamina spending/regeneration, low resources, difficulty-controlled indicators, and frame times in game.

## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS binaries are included.
