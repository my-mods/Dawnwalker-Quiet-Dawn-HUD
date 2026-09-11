# Quiet Dawn - Customizable HUD

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. Combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy health:** health bars and their end caps stay hidden for ordinary enemies and bosses, including boss health-phase indicators. Enemy names and difficulty icons are hidden by default, with separate toggles in Mod Settings. Enemy stamina, wounds and combat warnings retain game behavior.
- **Enemy lock-on marker:** hidden in its neutral state when directional indicators are disabled. Enabling directional indicators restores the shared widget, including its neutral directional display. Attack-direction and parry-direction cues stay hidden while directional indicators are disabled. Unblockable-attack and weak-spot cues retain the shared widget; game visibility rules remain in effect. Unknown states are left visible rather than suppressing a possible warning.
- **Player health and stamina:** shown together at full opacity after damage or stamina use, while health is strictly below **50%**, or while stamina is strictly below **20%**. Vampire health follows the blood bar; human health follows HP.
- **Hide delay:** **4 seconds** after the last health/blood drop; **1.5 seconds** after the last stamina drop. Further drops restart the relevant delay. Low health or stamina keeps the panel visible without a timeout. Exactly 50% health or 20% stamina does not qualify by itself.
- **Manual HUD peek:** hold the Controls Legend button (Menu on Xbox, Options on PlayStation, or L on keyboard by default) to show the player HUD for **3 seconds**. Repeat the gesture to refresh the peek. When it ends, automatic health/stamina visibility resumes.
- **Parry/attack indicators:** normal game behavior, including difficulty restrictions. This mod never enables disabled indicators.

The compass, quest tracker, quickslots and their change prompt, crosshair, control legend, buffs, ability cooldowns, focus panel/charge, special-attack cooldown, and XP bar stay hidden. Interaction prompts, dialogue, subtitles, notifications, and menus retain their game behavior. The manual peek reveals the managed player panels at full opacity, including the compass, quests, quickslots, buffs and cooldowns. Enemy health bars and disabled directional indicators keep their configured behavior; menus, dialogue and the game's visibility restrictions remain in control.

## Requirements and compatibility

- Dawnwalker-compatible UE4SS with Blueprint script hooks enabled, exposing `ExecuteInGameThreadWithDelay`, `CancelDelayedAction`, `KismetSystemLibrary.GetFrameCount`, and `GetGameTimeInSeconds`. Development reference: commit `97b7e501c`.
- Stock HUD/API reference: Steam build **25191761**, executable CL-258042.
- Disable **HUD Tweaks and HUD Tweaks - Fixes** before enabling this mod. They are not dependencies and can compete over opacity despite having different filenames.
- Mods altering the managed HUD panels require compatibility testing.

## Install, update, and remove

### UE4SS setup (Framecore or Vercadi)

Quiet Dawn requires Blueprint script hooks. After deploying the mod, close the game and double-click `Enable-Blueprint-Hooks.bat` in `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`.

The script sets or adds `HookProcessLocalScriptFunction = 1` under `[Hooks]` in the runtime's `UE4SS-settings.ini`. It works with either distribution's existing INI, preserving its other settings, comments and encoding. Before an edit it saves the original as `UE4SS-settings.ini.QuietDawn-<unique ID>.bak`. Running it again when the setting is already 1 makes no changes. It does not change `HookProcessInternal` or choose a different profile.

If the INI is missing and the installed `profiles/profile_perf.ini` exists, the script creates the INI from that Framecore Performance template with the hook enabled. If neither file exists, it stops and asks you to restore your loader configuration. It does not guess the loader from its DLL or replace an existing INI with defaults. Duplicate sections/keys or a malformed setting are reported without editing the file.

Restart the game afterward. Rerun the script after a Framecore profile switch or a Vortex deployment/update that replaces the configuration. If Vortex reports an external file change, retain the edited INI when you want this setting preserved. This is a one-time user-run setup tool; the Lua mod does not edit or poll your loader settings.

If you used the older **Quiet Dawn - Framecore Settings** full-INI overlay, disable that overlay and deploy your preferred loader configuration before running this script. Back up any preferences first. The new script is bundled with the main Quiet Dawn ZIP and needs no settings overlay.

Enabling the dispatcher meets Quiet Dawn's hook requirement; stability and performance also depend on the game/runtime build. If enabling it causes a crash, retain the launch log and restore the backed-up configuration through your normal Vortex workflow.

1. Close the game. Disable HUD Tweaks and its Fixes submod in Vortex and deploy.
2. Import `Quiet-Dawn-Customizable-HUD.zip`. Choose **UE4SS (Lua mods)**, enable, and deploy.
3. Runtime files belong under `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`. Restart the game; live Lua reload is not supported.

Install **one version only**. When updating an older version, back up `Scripts/QuietDawnConfig.lua` and your personal diagnostics INI before Vortex removes or replaces the old package. To import those choices, restore the legacy Lua file beside the new scripts before first launch. The new ZIP supplies `QuietDawnDefaults.lua` and does not overwrite that legacy filename. After migration, back up the generated `settings.ini` for future reinstalls. Reinstall through Vortex’s installer when the package layout changes.

To remove, close the game, disable/remove the mod in Vortex, and deploy. No save-game data is changed.

## Compass

Change Compass opacity in Mod Settings in 5-point steps: 0% hides it; 50% shows it at half opacity; 100% is fully opaque. No separate compass toggle is needed; opacity alone controls visibility. The old Show Compass variant is no longer needed; its preferences can be imported from your backed-up legacy Lua file on first use.

## Settings

Use [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) from the main menu. Opacity and resource thresholds adjust in 5 percentage-point steps; HUD durations adjust in 0.5-second steps. Press Apply, then load a save. See [SETTINGS.md](SETTINGS.md) for all controls, first-use import and preference backups. Console settings commands are retired.

## Behavior and performance

Player creation and possession can activate the HUD when a loading-screen notification is missed. Readiness checks share one finite window of less than ten seconds; they stop after success or exhaustion and can resume on a later player event. An old world's player cannot activate a new session. Ordinary travel retains the settings snapshot.

Enable **Logging** (the final Mod Settings entry) for activation and HUD diagnostics in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Apply and load a save; restart the game to diagnose an activation failure that prevents the new snapshot from loading. Activation summaries include the event source, readiness attempts, failure reason and aggregate CPU time. Logging is off by default. Hook-registration failures include the exact function path and exception once per hook per session.

Lifecycle and preset callbacks initialize/reapply the named panels. Health, blood, and stamina change handlers, plus the stat widgets' event-driven update functions, request a coalesced read of the current player's active resource percentages. The update-function hooks also cover direct event-graph dispatch. Blood-bar capacity changes are covered by the same widget update path. There is no recurring stat sampler. The stamina handler is bound by the shared HUD's vampire stats widget during initialization in both forms. Rapid loss followed by recovery still records the loss event.

A single pending hide deadline uses cached resource values and game time; it never rereads health or stamina. Further drops extend the deadline. Pausing preserves the remaining hold time: an outstanding deadline may reschedule for the remaining game-time delay. The same deadline also ends a manual HUD peek, including while health is low. It then restores normal hiding for the other panels while leaving low health visible. Once the relevant holds expire, no deadline timer continues. Panel updates run on separate frames.

Ownership checks use Unreal object addresses. Different Lua wrappers for the same object retain its cached state; old HUD/world events are ignored. Missing readings or unavailable resource hooks leave stat panels under normal game visibility when possible. Failed hook setup uses finite retries and can recover on a subsequent HUD/player lifecycle event. There is no polling fallback. Known health alerts use full opacity even if a stat panel was transparent during initialization. Form selection and the game's visibility presets remain in effect. Unknown forms or unavailable blood data leave the stat panels under game control.

The lock-on marker shares its widget with combat cues, so it cannot be hidden unconditionally. The mod reads the Directional Indicator menu setting at initialization and on settings/HUD events. Enabling it restores cached markers; the widget's separate internal display toggle does not override that choice. Missing setting data leaves the widget under game control. Construction and icon-state callbacks schedule bounded updates through the existing worker. Construction events wait for HUD ownership initialization. HUD and marker ownership readiness use finite retries; exhausted HUD readiness waits for a later lifecycle event, and exhausted marker readiness waits for a later marker event. Debug logging reports readiness failures and direction-setting reads. No difficulty-setting poll or extra timer is added. A fixed 64-entry marker cache/queue bounds work; excess markers remain under normal game control until capacity becomes available.

There are no global HUD searches, widget-tree walks, class-default changes, or recurring configuration reads. The panel worker terminates after each job. Resource events that leave visibility unchanged do not revisit panels. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events and when a manual peek begins or ends. Missing fields are not retried on each resource change. Removing both stat panels from the configuration disables resource hooks, reads and manual peeking.


## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS binaries are included.

Enemy health hiding uses the named health widgets verified in Steam build 25191761. Construction and target/owner changes schedule bounded work on the shared HUD worker, one named child per frame. It does not scan enemies, poll their stats, or change their actual health.


Bundled library

This mod includes the MIT-licensed ue4ss-common Lua helpers (https://github.com/my-mods/ue4ss-common). No separate library installation is required. Its license is included in LICENSES/QuietDawnHUD-ue4ss-common.txt.
