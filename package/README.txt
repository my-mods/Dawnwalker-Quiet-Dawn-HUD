# Quiet Dawn - Customizable HUD

The Sprint and Haste button prompts stay hidden while running. Turn off Hide sprint/haste prompt in Mod Settings to restore them. Other action prompts retain game behavior, and manual HUD peek keeps running prompts hidden.

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. Combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy health:** health bars and their end caps stay hidden for ordinary enemies and bosses, including boss health-phase indicators. Enemy names and difficulty icons are hidden by default, with separate toggles in Mod Settings. Enemy stamina, wounds and combat warnings retain game behavior.
- **Enemy lock-on marker:** hidden in its neutral state when directional indicators are disabled. Enabling directional indicators restores the shared widget, including its neutral directional display. Attack-direction and parry-direction cues stay hidden while directional indicators are disabled. Unblockable-attack and weak-spot cues retain the shared widget; game visibility rules remain in effect. Unknown states are left visible rather than suppressing a possible warning.
- **Player health and stamina:** at their default 0% setting, shown together at full opacity after damage or stamina use, while health is strictly below **50%**, or while stamina is strictly below **20%**. Vampire health follows the blood bar; human health follows HP.
- **Hide delay:** **4 seconds** after the last health/blood drop; **1.5 seconds** after the last stamina drop. Further meaningful drops restart the relevant delay; blood fluctuations smaller than 0.2% of the bar do not keep renewing it. Low health or stamina keeps the panel visible without a timeout. Exactly 50% health or 20% stamina does not qualify by itself.
- **Manual HUD peek:** hold the Controls Legend button (Menu on Xbox, Options on PlayStation, or L on keyboard by default) to show the player HUD for **3 seconds**. Repeat the gesture to refresh the peek. When it ends, automatic health/stamina visibility resumes.
- **Parry/attack indicators:** normal game behavior, including difficulty restrictions. This mod never enables disabled indicators.

At 0% opacity, Quiet Dawn hides the general HUD between alerts and reveals. Item and ability quickslots appear briefly after using the switch control (3 seconds by default); the double-arrow switch hint stays hidden. The special-attack panel appears only while its cooldown is running. Positive panel opacity keeps the chosen value, subject to the game's visibility rules. All 17 managed panels have 0% to 100% opacity sliders in 5-point steps. Interaction prompts, dialogue, subtitles, notifications and menus retain game behavior. Manual HUD peek reveals the other managed player panels at full opacity; the switch hint and special-attack panel keep their own rules. Enemy health and directional indicators keep their configured behavior.

The time-of-day panel is hidden by default. It appears at full opacity when time advances, then hides 4 seconds after the last time change. Time of day reveal duration adjusts from 0 to 10 seconds in 0.5-second steps; 0 disables automatic reveals. A positive Time of day opacity keeps it shown at the selected opacity. HUD peek also reveals it.

## Requirements and compatibility

- UE4SS for BoD **Framecore 2b** with the bundled native HUD bridge, or a Dawnwalker-compatible UE4SS build with Blueprint script hooks enabled, exposing `ExecuteInGameThreadWithDelay`, `CancelDelayedAction`, `KismetSystemLibrary.GetFrameCount`, and `GetGameTimeInSeconds`. Development reference: commit `97b7e501c`.
- Stock HUD/API reference: Steam build **25232147**, executable CL-258504.
- Disable **HUD Tweaks and HUD Tweaks - Fixes** before enabling this mod. They are not dependencies and can compete over opacity despite having different filenames.
- Mods altering the managed HUD panels require compatibility testing.

## Install, update, and remove

### UE4SS setup

**Framecore 2b:** use its Performance profile with the bundled `dlls/main.dll`. The helper supplies Quiet Dawn's HUD events while `HookProcessInternal` and `HookProcessLocalScriptFunction` remain 0 in the INI. It does not rewrite the loader configuration. Keep the helper and Lua scripts from the same package together.

If you previously installed the **Quiet Dawn - Framecore Settings** overlay, back up your loader preferences, disable that overlay in Vortex, and deploy Framecore's preferred profile. Do not run `Enable-Blueprint-Hooks.bat` when using the native bridge with the Performance profile.

**Other UE4SS builds, including Vercadi:** use the regular Blueprint dispatcher. With the game closed, the optional `Enable-Blueprint-Hooks.bat` in `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/` enables `HookProcessLocalScriptFunction` in the existing INI and saves a uniquely named backup. It preserves other settings, comments and encoding; if the INI is absent, it can use the installed Framecore Performance template. Duplicate or malformed settings stop the script without edits. It never changes `HookProcessInternal`. Restart the game afterward.

The native route targets Framecore 2b's specific DLL. Another DLL hash or an already-enabled script dispatcher retains Quiet Dawn's regular Lua hook route. Native build details and the supported hash are in [native build notes](https://github.com/my-mods/Dawnwalker-Quiet-Dawn-Customizable-HUD/blob/main/native/BUILD.md).

1. Close the game. Disable HUD Tweaks and its Fixes submod in Vortex and deploy.
2. Import `Quiet-Dawn-Customizable-HUD.zip`. Choose **UE4SS (Lua mods)**, enable, and deploy.
3. Runtime files belong under `Dawnwalker/Binaries/Win64/ue4ss/Mods/QuietDawnHUD/`. Restart the game; live Lua or DLL reload is not supported.

Install **one version only**. When updating an older version, back up `Scripts/QuietDawnConfig.lua` and your personal diagnostics INI before Vortex removes or replaces the old package. To import those choices, restore the legacy Lua file beside the new scripts before first launch. The new ZIP supplies `QuietDawnDefaults.lua` and does not overwrite that legacy filename. After migration, back up the generated `settings.ini` for future reinstalls. Reinstall through Vortex’s installer when the package layout changes.

To remove, close the game, disable/remove the mod in Vortex, and deploy. No save-game data is changed.

## Compass

Change Compass opacity in Mod Settings in 5-point steps: 0% hides it; 50% shows it at half opacity; 100% is fully opaque. No separate compass toggle is needed; opacity alone controls visibility. The old Show Compass variant is no longer needed; its preferences can be imported from your backed-up legacy Lua file on first use.

## Settings

Use [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) from the main menu. Opacity and resource thresholds adjust in 5 percentage-point steps; HUD durations adjust in 0.5-second steps. Press Apply, then load a save. See [SETTINGS.md](SETTINGS.md) for all controls, first-use import and preference backups. Console settings commands are retired.

## Behavior and performance

Framecore 2b uses a native filter for Quiet Dawn's HUD events. It copies event values into a bounded queue and delivers them through the existing game-thread scheduler. Player alerts take priority over enemy-widget bursts; settings retain their save-load behavior. The helper adds no polling thread or continuous readiness timer.

Player creation and possession can activate the HUD when a loading-screen notification is missed. Readiness checks share one finite window of less than ten seconds; they stop after success or exhaustion and can resume on a later player event. An old world's player cannot activate a new session. Ordinary travel retains the settings snapshot.

Enable **Logging** (the final Mod Settings entry) for activation and HUD diagnostics in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Apply and load a save; restart the game to diagnose an activation failure that prevents the new snapshot from loading. Activation summaries include the event source, readiness attempts, failure reason and aggregate CPU time. Logging is off by default. Hook-registration failures include the exact function path and exception once per hook per session.

Lifecycle and preset callbacks initialize/reapply the named panels. Health, blood, and stamina change handlers, plus the stat widgets' event-driven update functions, request a coalesced read of the current player's active resource percentages. The update-function hooks also cover direct event-graph dispatch. Blood-bar capacity changes are covered by the same widget update path. There is no recurring stat sampler. The stamina handler is bound by the shared HUD's vampire stats widget during initialization in both forms. Rapid loss followed by recovery still records the loss event.

A single pending hide deadline uses cached resource values and game time; it never rereads health or stamina. Further drops extend the deadline. Pausing preserves the remaining hold time: an outstanding deadline may reschedule for the remaining game-time delay. The same deadline ends manual HUD peeks and time-change reveals independently, including while health is low. It then restores normal hiding for the other panels while leaving low health visible. Once the relevant holds expire, no deadline timer continues. Panel updates run on separate frames.

Ownership checks use Unreal object addresses. Different Lua wrappers for the same object retain its cached state; old HUD/world events are ignored. Missing readings or unavailable resource hooks leave stat panels under normal game visibility when possible. Failed hook setup uses finite retries and can recover on a subsequent HUD/player lifecycle event. There is no polling fallback. Known health alerts use full opacity even if a stat panel was transparent during initialization. Form selection and the game's visibility presets remain in effect. Unknown forms or unavailable blood data leave the stat panels under game control.

The lock-on marker shares its widget with combat cues, so it cannot be hidden unconditionally. The mod reads the Directional Indicator menu setting at initialization and on settings/HUD events. Enabling it restores cached markers; the widget's separate internal display toggle does not override that choice. Missing setting data leaves the widget under game control. Construction and icon-state callbacks schedule bounded updates through the existing worker. Construction events wait for HUD ownership initialization. HUD and marker ownership readiness use finite retries; exhausted HUD readiness waits for a later lifecycle event, and exhausted marker readiness waits for a later marker event. Debug logging reports readiness failures and direction-setting reads. No difficulty-setting poll or extra timer is added. A fixed 64-entry marker cache/queue bounds work; excess markers remain under normal game control until capacity becomes available.

There are no global HUD searches, widget-tree walks, class-default changes, or recurring configuration reads. The panel worker terminates after each job. Resource events that leave visibility unchanged do not revisit panels. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events and when a manual peek begins or ends. Missing fields are not retried on each resource change. Setting both stat panels to a positive opacity disables resource hooks and reads. Manual HUD peek remains available and temporarily shows the managed panels at 100%, then restores their selected opacity or automatic behavior.


## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS runtime DLL are included. The bundled native helper uses UE4SS and Framecore APIs; their authors retain credit for the runtime and hook implementation. See LICENSES for third-party notices.

Enemy health hiding uses the named health widgets verified in Steam build 25191761. Construction and target/owner changes schedule bounded work on the shared HUD worker, one named child per frame. It does not scan enemies, poll their stats, or change their actual health.

# Settings

Install [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. The settings file is prepared when the mod starts. Open Main Menu > Mod Settings > All Mods. Select this mod, change settings and press Apply. **Load a save after Apply.** Restore discards unapplied changes; Reset selects this mod’s defaults.

The stable menu ID is `oOCamilleOo_QuietDawnHUD`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Startup prepares the menu file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| Enemies | Hide enemy names | Off, On |
| Enemies | Hide enemy difficulty icons | Off, On |
| Vitals | Keep health visible below | 0% to 100% in 5-point steps (default 50%) |
| Vitals | Keep stamina visible below | 0% to 100% in 5-point steps (default 20%) |
| Vitals | Health / blood hold duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Stamina hold duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Show HUD duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Show HUD on hold | Off, On |
| HUD visibility | Time of day opacity | 0% to 100% in 5-point steps |
| HUD visibility | Time of day reveal duration | 0 to 10 seconds in 0.5-second steps (default 4 seconds) |
| HUD visibility | Compass opacity | 0% to 100% in 5-point steps |
| HUD visibility | Human health and stamina opacity | 0% to 100% in 5-point steps |
| HUD visibility | Vampire blood and stamina opacity | 0% to 100% in 5-point steps |
| HUD visibility | Quest tracker opacity | 0% to 100% in 5-point steps |
| HUD visibility | Quickslots opacity | 0% to 100% in 5-point steps |
| HUD visibility | Crosshair opacity | 0% to 100% in 5-point steps |
| HUD visibility | Quickslot shortcuts opacity | 0% to 100% in 5-point steps |
| HUD visibility | Focus activation prompt opacity | 0% to 100% in 5-point steps |
| HUD visibility | Switch quickslots prompt opacity | 0% to 100% in 5-point steps |
| HUD visibility | Controls legend opacity | 0% to 100% in 5-point steps |
| HUD visibility | Active buffs opacity | 0% to 100% in 5-point steps |
| HUD visibility | Ability cooldowns opacity | 0% to 100% in 5-point steps |
| HUD visibility | Combat focus opacity | 0% to 100% in 5-point steps |
| HUD visibility | Focus charge opacity | 0% to 100% in 5-point steps |
| HUD visibility | Special attack cooldown opacity | 0% to 100% in 5-point steps |
| HUD visibility | Experience bar opacity | 0% to 100% in 5-point steps |
| Diagnostics | Logging | Off, On |

Turn off **Hide enemy names** to restore enemy name labels (boss names), or **Hide enemy difficulty icons** to restore difficulty indicators for ordinary enemies and bosses. The choices are independent. Apply, then load a save. The player HUD peek keeps both choices in effect. At startup, older settings files receive any missing enemy-label options, set to On. Existing preferences and comments are preserved.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.

**HUD opacity:** every managed player panel has a 0% to 100% slider in 5-point steps. At 0%, health/blood and stamina appear for resource alerts, time appears after time changes, and quickslots/abilities appear briefly after switching. The switch hint stays hidden; the special-attack panel appears only while recharging. Positive opacity keeps the selected value, subject to the game's visibility rules. HUD peek reveals other managed panels at full opacity, then restores their selected behavior.

**Show HUD** uses the game's **Toggle Controls Legend** action. Hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap. For keyboard, change the game's Controls Legend binding. Quiet Dawn follows the remapped action. Show HUD duration controls the time the HUD remains visible after activation.

**Logging** is the final menu setting and the only diagnostic control. Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

**Timers:** all four HUD durations range from 0 to 10 seconds in 0.5-second steps. Zero disables that timed reveal. Health and stamina thresholds and positive panel opacity still apply independently. Defaults remain 4 seconds for health/blood, 1.5 seconds for stamina, 3 seconds for HUD peek and 4 seconds for time of day. Older durations above 10 seconds are capped at 10; other fractional durations round to the nearest half-second. If an existing settings file needs this adjustment, the original is kept as `settings.ini.before-short-timers`, preserving all other preferences and comments.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply when the corresponding panel opacity is 0%. Positive opacity keeps that panel shown without resource-driven hiding.

Older On/Off panel settings are imported into the new opacity controls: Off becomes 0% and On becomes 100%. The upgrade adds the new keys while preserving existing settings, unknown keys and comments; it retains the original file as `settings.ini.before-hud-events`. Any earlier `settings.ini.before-panel-opacity` backup is retained. Compass opacity remains unchanged. Keep recovery files if an upgrade error is reported.

**Quickslot switching:** Show quickslots after switching controls the reveal duration, from 0 to 10 seconds in half-second steps (default 3). Zero disables this reveal. Pausing preserves the remaining duration. The double-arrow switch hint keeps its own opacity.

**Time of day:** 0% opacity hides the complete time panel between time changes and HUD peeks. Time changes reveal it at 100% and restart the reveal duration, which defaults to 4 seconds. Pausing preserves the remaining duration. Set the duration to 0 seconds to disable automatic time-change reveals; HUD peek still works. Positive opacity keeps the panel shown and does not use the timer. Existing settings gain these two options without resetting other preferences.

Bundled library

This mod includes the MIT-licensed ue4ss-common Lua helpers (https://github.com/my-mods/ue4ss-common). No separate library installation is required. Its license is included in LICENSES/QuietDawnHUD-ue4ss-common.txt.
