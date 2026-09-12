# Settings

Install [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. The settings file is prepared when the mod starts. Open Main Menu > Mod Settings > All Mods. Select this mod, change settings and press Apply. **Load a save after Apply.** Restore discards unapplied changes; Reset selects this mod’s defaults.

The stable menu ID is `oOCamilleOo_QuietDawnHUD`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Startup prepares the menu file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| HUD visibility | Hide sprint/haste prompt | Off, On (default On) |
| Enemies | Hide enemy names | Off, On |
| Enemies | Hide enemy difficulty icons | Off, On |
| Combat cues | Show counterattack direction | Off (default), On |
| Combat cues | Show unblockable warning | Off (default), On |
| Combat cues | Show directional parry cues | Off (default), On |
| Combat cues | Show lock icon | Off (default), On |
| Combat cues | Combat cue size | 10%�200%, step 10%; default 100% |
| Vitals | Keep health visible below | 0% to 100% in 5-point steps (default 50%) |
| Vitals | Keep stamina visible below | 0% to 100% in 5-point steps (default 20%) |
| Vitals | Health / blood hold duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Stamina hold duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Show HUD duration | 0 to 10 seconds in 0.5-second steps |
| Vitals | Show HUD on hold | Off, On |
| HUD visibility | Time of day opacity | 0% to 100% in 5-point steps |
| HUD visibility | Time of day reveal duration | 0 to 10 seconds in 0.5-second steps (default 4 seconds) |
| HUD visibility | Show quickslots after switching | 0 to 10 seconds in 0.5-second steps (default 3; 0 disables) |
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

The four Combat cues toggles work independently of the game's Directional Indicator option. Counterattack directions show the attack opening after a perfect parry; unblockable warnings show the skull; directional parry cues show the incoming direction and highlight its arrow during the parry window; the lock option shows a padlock on a hard-locked target between cues. The dot stays hidden and directions hide all center lock icons. All four toggles default to Off. Combat cue size scales the whole cue group from 10% to 200% in 10% steps, defaulting to 100%. Apply, then load a save. Existing counterattack choices are retained when adding the new controls. Logging reports the observed icon, selected arrow or warning, lock state, size and readiness failures in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.

**HUD opacity:** all 17 player panels have 0% to 100% sliders in 5-point steps. At 0%, Quiet Dawn manages visibility through resource alerts, quickslot switching, special-attack cooldowns, time changes and manual peek. Positive opacity keeps the selected value while the game controls contextual visibility. HUD peek reveals other managed panels at 100%; the Focus hint, switch hint and special-attack panel retain their own rules.

**Show HUD** uses the game's **Toggle Controls Legend** action. Hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap. For keyboard, change the game's Controls Legend binding. Quiet Dawn follows the remapped action. Show HUD duration controls the time the HUD remains visible after activation.

**Logging** is the final menu setting and the only diagnostic control. Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

**Timers:** all five HUD durations range from 0 to 10 seconds in 0.5-second steps. Zero disables that timed reveal. Health and stamina thresholds and positive panel opacity still apply independently. Defaults remain 4 seconds for health/blood, 1.5 seconds for stamina, 3 seconds for HUD peek, 3 seconds for quickslot switching and 4 seconds for time of day. Older durations above 10 seconds are capped at 10; other fractional durations round to the nearest half-second. If an existing settings file needs this adjustment, the original is kept as `settings.ini.before-short-timers`, preserving all other preferences and comments.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply when the corresponding panel opacity is 0%. Positive opacity keeps that panel shown without resource-driven hiding.

Older On/Off panel settings are imported into the new opacity controls: Off becomes 0% and On becomes 100%. The upgrade adds the new keys while preserving existing settings, unknown keys and comments; it retains the original file under a `settings.ini.before-*` name for the upgrade being applied (currently `settings.ini.before-combat-cues`). Earlier recovery backups are retained. Compass opacity remains unchanged. Keep recovery files if an upgrade error is reported.

Switching items/abilities briefly reveals panels set to 0%; positive opacity stays at its selected value. The switch hint remains at its own opacity, including during manual HUD peek. Set the special-attack panel to 0% to show it only while recharging; positive values show it normally at the chosen opacity. Both still respect the game's visibility restrictions. The reveal duration uses game time and pauses with the game.

Small blood fluctuations below 0.2% of bar capacity do not renew the health hold. Low-resource thresholds and human damage/stamina alerts remain unchanged. Existing opacity settings gain the new duration without changing selected values; keep the `settings.ini.before-hud-events` recovery copy.

**Time of day:** 0% opacity hides the complete time panel between time changes and HUD peeks. Time changes reveal it at 100% and restart the reveal duration, which defaults to 4 seconds. Pausing preserves the remaining duration. Set the duration to 0 seconds to disable automatic time-change reveals; HUD peek still works. Positive opacity keeps the panel shown and does not use the timer. Existing settings gain these two options without resetting other preferences.

**Hide sprint/haste prompt** suppresses only the running prompts, including during manual HUD peek. Other action prompts retain game behavior. Apply, then load a save. Existing settings receive the new option set to On, with their preferences and comments preserved.

**Focus activation prompt opacity:** 0% keeps the Toggle abilities button and label hidden in Focus mode and during HUD peek. Positive values use the selected opacity when the game shows the prompt. Ability switching still works. Apply, then load a save.

**Healing and regeneration:** Health and blood gains of at least 1% of the bar reveal the stat panel for the existing health hold duration. Smaller regeneration stays quiet until the bar reaches full. That full-bar reveal rearms only after a deficit of at least 0.2%, preventing repeated near-full notifications. Positive panel opacity and low-resource thresholds keep their existing behavior. The health / blood hold duration also controls these healing reveals; 0 disables them. Small stamina recovery does not trigger a reveal.
