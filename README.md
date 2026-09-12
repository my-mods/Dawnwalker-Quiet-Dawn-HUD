# Quiet Dawn - Customizable HUD

A quiet view of the world, with health and stamina returning when needed.

For **The Blood of Dawnwalker**. Combat, drawing a weapon, lock-on, and focus no longer reveal the general HUD.

- **Enemy health:** health bars and their end caps stay hidden for ordinary enemies and bosses, including boss health-phase indicators. Enemy names and difficulty icons are hidden by default, with separate toggles in Mod Settings. Enemy stamina, wounds and combat warnings retain game behavior.
- **Enemy lock-on marker:** Four independent Combat cues toggles control counterattack directions, unblockable warnings, directional parry cues and the lock icon. All default to Off. The center dot is always hidden; directions hide the center lock icon.
- **Player health and stamina:** at their default 0% setting, shown together at full opacity after damage, meaningful healing or stamina use, while health is strictly below **50%**, or while stamina is strictly below **20%**. Vampire health follows the blood bar; human health follows HP.
- **Hide delay:** **4 seconds** after the last health/blood alert; **1.5 seconds** after the last stamina drop. Further meaningful drops restart the relevant delay; blood fluctuations smaller than 0.2% of the bar do not keep renewing it. Low health or stamina keeps the panel visible without a timeout. Exactly 50% health or 20% stamina does not qualify by itself.
- **Manual HUD peek:** hold the Controls Legend button (Menu on Xbox, Options on PlayStation, or L on keyboard by default) to show the player HUD for **3 seconds**. Repeat the gesture to refresh the peek. When it ends, automatic health/stamina visibility resumes.
- **Parry/attack indicators:** Show directional parry cues displays the incoming attack direction and highlights its arrow during the parry window, independently of the game's Directional Indicator option.
- **Counterattack direction:** Show counterattack direction displays the weak-spot attack direction during counterattack openings, including after a perfect parry. The cue ends when the game clears the opening. Combat cue size adjusts all combat icons and directions together from 10% to 200% in 10% steps, defaulting to 100%.

At 0% opacity, Quiet Dawn hides the general HUD between alerts and reveals. Item and ability quickslots appear briefly after using the switch control (3 seconds by default); the double-arrow switch hint stays hidden. The special-attack panel appears only while its cooldown is running. Positive panel opacity keeps the chosen value, subject to the game's visibility rules. All 17 managed panels have 0% to 100% opacity sliders in 5-point steps. Interaction prompts, dialogue, subtitles, notifications and menus retain game behavior. Manual HUD peek reveals the other managed player panels at full opacity; the Focus hint, switch hint and special-attack panel keep their own rules. Enemy health and directional indicators keep their configured behavior.

The Sprint and Haste button prompts stay hidden while running. Turn off **Hide sprint/haste prompt** in Mod Settings to restore them. Other action prompts retain game behavior, and manual HUD peek keeps running prompts hidden.

The Toggle abilities hint (RT with the remapped controller layout) stays hidden in Focus mode and during manual HUD peek. Ability switching still works. Raise Focus activation prompt opacity above 0% to restore the hint.

Health and blood gains of at least 1% of the bar reveal the stat panel for the existing health hold duration. Smaller regeneration stays quiet until the bar reaches full. That full-bar reveal rearms only after a deficit of at least 0.2%, preventing repeated near-full notifications. Positive panel opacity and low-resource thresholds keep their existing behavior.

The time-of-day panel is hidden by default. It appears at full opacity when time advances, then hides 4 seconds after the last time change. Time of day reveal duration adjusts from 0 to 10 seconds in 0.5-second steps; 0 disables automatic reveals. A positive Time of day opacity keeps it shown at the selected opacity. HUD peek also reveals it.

## Requirements and compatibility

- [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) for configuration.
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

Lifecycle and preset callbacks initialize/reapply the named panels. Health, blood, and stamina change handlers, plus the stat widgets' event-driven update functions, request a coalesced read of the current player's active resource percentages. The update-function hooks also cover direct event-graph dispatch. Blood-bar capacity changes are covered by the same widget update path. There is no recurring stat sampler. The stamina handler is bound by the shared HUD's vampire stats widget during initialization in both forms. Rapid loss followed by recovery still records the largest loss in that event burst, even if a smaller blood fluctuation follows.

A single pending hide deadline uses cached resource values and game time; it never rereads health or stamina. Further meaningful damage or healing extends the health deadline; reaching full after a meaningful deficit also reveals health once. Pausing preserves the remaining hold time: an outstanding deadline may reschedule for the remaining game-time delay. The same deadline ends manual HUD peeks, quickslot reveals and time-change reveals independently, including while health is low. It then restores normal hiding for the other panels while leaving low health visible. Once the relevant holds expire, no deadline timer continues. Panel updates run on separate frames.

Ownership checks use Unreal object addresses. Different Lua wrappers for the same object retain its cached state; old HUD/world events are ignored. Missing readings or unavailable resource hooks leave stat panels under normal game visibility when possible. Failed hook setup uses finite retries and can recover on a subsequent HUD/player lifecycle event. There is no polling fallback. Known health alerts use full opacity even if a stat panel was transparent during initialization. Form selection and the game's visibility presets remain in effect. Unknown forms or unavailable blood data leave the stat panels under game control.

Enemy health hiding uses the named health widgets verified in Steam build 25232147. Construction and target/owner changes schedule bounded work on the shared HUD worker, one named child per frame. It does not scan enemies, poll their stats, or change their actual health. A missing child exhausts its own readiness attempts; the remaining children are still processed. A later target or owner event retries missing children.

Combat cue changes use the existing marker construction, icon-render and lock events. Each update touches a fixed set of named child widgets; no widget-tree search or recurring timer is added. Parry and counterattack directions suppress center icons, and the lock toggle shows a padlock only on a hard-locked target between cues. The game retains control of distance fading and overall widget visibility. Readiness retries and the 64-entry marker cache/queue remain bounded. Logging reports the observed state, selected cue, size and readiness failures.

There are no global HUD searches, widget-tree walks, class-default changes, or recurring configuration reads. The panel worker terminates after each job. Resource events that leave visibility unchanged do not revisit panels. Resource visibility changes revisit only the two stat panels; unrelated HUD fields are checked on lifecycle/preset events and when a manual peek begins or ends. Missing fields are not retried on each resource change. Setting both stat panels to a positive opacity disables resource hooks and reads. Manual HUD peek remains available and temporarily shows the managed panels at 100%, then restores their selected opacity or automatic behavior.

## License

MIT. Standalone code informed by the author's HUD Tweaks - Fixes work and the game's HUD structure. No game assets or UE4SS runtime DLL are included. The bundled native helper uses UE4SS and Framecore APIs; their authors retain credit for the runtime and hook implementation. See LICENSES for third-party notices.

This mod includes the MIT-licensed [ue4ss-common Lua helpers](https://github.com/my-mods/ue4ss-common). No separate library installation is required. Its license is included in LICENSES/QuietDawnHUD-ue4ss-common.txt.
