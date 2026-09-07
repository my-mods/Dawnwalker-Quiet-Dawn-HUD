# Quiet Dawn HUD - Auto-hide HUD

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. Combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy health:** normal game behavior, always exempt from this mod's hiding.
- **Enemy lock-on marker:** hidden in its neutral state. The shared widget is restored for active attack, parry-window, unblockable-attack, or weak-spot cues; game visibility and difficulty restrictions remain in effect. Unknown states are left visible rather than suppressing a possible warning.
- **Player health and stamina:** shown together when either value drops, or either is strictly below **20%**.
- **Hide delay:** **1.5 seconds** after the last damage or stamina drop. Further drops restart the relevant delay. Either value below 20% keeps the panel visible; exactly 20% does not qualify by itself.
- **Parry/attack indicators:** normal game behavior, including difficulty restrictions. This mod never enables disabled indicators.

The compass, quest tracker, quickslots and their change prompt, crosshair, control legend, buffs, ability cooldowns, focus panel/charge, special-attack cooldown, and XP bar stay hidden. Interaction prompts, dialogue, subtitles, notifications, boss bars, and menus retain their game behavior. There is no manual whole-HUD reveal shortcut.

## Requirements and compatibility

- Dawnwalker-compatible UE4SS exposing `ExecuteInGameThreadWithDelay`, `KismetSystemLibrary.GetFrameCount`, and `GetGameTimeInSeconds`. Development reference: commit `97b7e501c`.
- Stock asset/API reference: Steam build **25129649**, executable CL-257186.
- Disable **HUD Tweaks and HUD Tweaks - Fixes** before enabling this mod. They are not dependencies and can compete over opacity despite having different filenames.
- Mods altering the managed HUD panels require compatibility testing.

## Install, update, and remove

1. Close the game. Disable HUD Tweaks and its Fixes submod in Vortex and deploy.
2. Import `Quiet-Dawn-HUD.zip` or the optional `Quiet-Dawn-HUD-Show-Compass.zip`. Choose **UE4SS (Lua mods)**, enable, and deploy.
3. Runtime files belong under `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`. Restart the game; live Lua reload is not supported.

Install **one version only**. Both archives use the same internal ID and runtime paths. Back up configuration before replacing your existing Vortex entry: the shipped configuration is a full replacement, not an automatic merge. To switch variants, disable/remove the old entry and deploy before importing and enabling the other archive. If the installer selected an incorrect layout, reinstall through the installer; redeployment alone preserves it.

To remove, close the game, disable/remove the mod in Vortex, and deploy. No save-game data is changed.

## Optional Show Compass version

`Quiet-Dawn-HUD-Show-Compass.zip` is a complete alternative. It displays the compass at 50% opacity; the game may still hide it in dialogue or other special states. Health/stamina timing and all other settings are identical to the standard version.

## Configuration

Edit `Scripts/QuietDawnConfig.lua` through your normal mod configuration workflow and restart the game. Avoid editing a deployed hardlink directly.

`healthThreshold` and `staminaThreshold` default to `0.20`. `healthHoldSeconds` and `staminaHoldSeconds` default to `1.5`. Either resource can reveal the combined panel. Healing/regeneration alone does not extend the delay. The delay uses game time and pauses with the game. Changes to maximum resource capacity that lower its percentage can also trigger the reveal.

`panels` lists direct HUD fields. Removing a non-stat entry leaves it under game control. The optional configuration includes `WBP_Compass` and sets `compassOpacity = 0.5`. This value ranges from `0` (transparent) to `1` (opaque). `enabled = false` disables all mod work at startup.

## Debug logging

Copy `QuietDawnHUD.ini.example` to `%LOCALAPPDATA%/Dawnwalker/Saved/Config/QuietDawnHUD.ini`. Set `[Debug] debugLogging=true` to activate logging, or `debugLogging=false` to disable it, then restart the game. This personal file survives mod updates; the archive defaults to logging off.

Messages use `[Quiet Dawn HUD][DEBUG]` in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. They report HUD visibility transitions, panel/marker writes, hook setup, unavailable state, and periodic timing/counter summaries. `SummarySeconds=10`, `SlowCallbackMs=2`, and `MaxEventsPerSecond=6` control summary frequency, slow-phase reporting, and the event output limit. Suppressed events are counted. The INI is read once; logging adds no timer or object searches. Disabled diagnostics retain the original work functions without timing wrappers.

Timings use `os.clock` for Lua work phases, including their synchronous native calls. Nested phases overlap: do not sum them. These measurements are not engine frame times or proof of a stutter fix. Sample gaps use game time. For diagnosis, reproduce damage, stamina use, lock-on/cues and a save load, then inspect the log before launching another session.

## Behavior and performance

Lifecycle and preset callbacks initialize/reapply the named panels. A bounded sampler reads the current player's health and stamina percentages every **100 ms** because the available UI callbacks do not cover every resource change. Detection can take approximately one sampling interval; panel writes follow on separate frames. A damage/use-and-recovery change entirely between samples may not be observed.

The sampler checks current ownership using Unreal object addresses and stops if the player context or stat readings become unavailable. Different Lua wrappers for the same object retain its cached state. Recovery occurs on subsequent HUD/player lifecycle events. Missing readings leave the stat panel under normal game visibility when possible. Reveals restore opacity; they do not override the game's visibility presets.

The lock-on marker shares its widget with combat cues, so it cannot be hidden unconditionally. Its construction and icon-state callbacks schedule bounded updates through the existing worker. Construction events wait for HUD ownership initialization. HUD and marker ownership readiness use finite retries; exhausted HUD readiness waits for a later lifecycle event, and exhausted marker readiness waits for a later marker event. Debug logging reports readiness failures. No difficulty-setting poll or extra timer is added. A fixed 64-entry marker cache/queue bounds work; excess markers remain under normal game control until capacity becomes available.

There are no global HUD searches, widget-tree walks, class-default changes, or recurring configuration reads. The panel worker terminates after each job; the two-value sampler continues while the player context is ready. Unchanged samples cause no widget reads or writes. A shared frame guard separates sampling from panel updates. Pending panel work takes priority over the sampler so it can finish even at very low frame rates. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events. Missing fields are not retried on each resource change. Removing both stat panels from the configuration also disables stat sampling.


## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS binaries are included.
