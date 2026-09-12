# Settings

Install [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. The settings file is prepared when the mod starts. Open Main Menu > Mod Settings > All Mods. Select this mod, change settings and press Apply. **Load a save after Apply.** Restore discards unapplied changes; Reset selects this modâ€™s defaults.

The stable menu ID is `oOCamilleOo_QuietDawnHUD`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menuâ€™s recovery instructions. Startup prepares the menu file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| HUD visibility | Hide sprint/haste prompt | Off, On (default On) |
| Enemies | Hide enemy names | Off, On |
| Enemies | Hide enemy difficulty icons | Off, On |
| Vitals | Keep health visible below | 0% to 100% in 5-point steps (default 50%) |
| Vitals | Keep stamina visible below | 0% to 100% in 5-point steps (default 20%) |
| Vitals | Health / blood hold duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Stamina hold duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Show HUD duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Show HUD on hold | Off, On |
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

**HUD opacity:** every managed player panel has a 0% to 100% slider in 5-point steps. At 0%, Quiet Dawn keeps its existing control: health/blood and stamina appear for resource alerts, and other panels remain hidden until HUD peek. Any value above 0% keeps that panel shown at the selected opacity, including during resource alerts. The game still controls form selection and contextual visibility. HUD peek temporarily reveals all managed panels at 100%, then restores each selected opacity or automatic behavior.

**Show HUD** uses the game's **Toggle Controls Legend** action. Hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap. For keyboard, change the game's Controls Legend binding. Quiet Dawn follows the remapped action. Show HUD duration controls the time the HUD remains visible after activation.

**Logging** is the final menu setting and the only diagnostic control. Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply when the corresponding panel opacity is 0%. Positive opacity keeps that panel shown without resource-driven hiding.

Older On/Off panel settings are imported into the new opacity controls: Off becomes 0% and On becomes 100%. The upgrade adds the new keys while preserving existing settings, unknown keys and comments; it retains the original file as `settings.ini.before-panel-opacity`. Compass opacity remains unchanged. Keep recovery files if an upgrade error is reported.

**Hide sprint/haste prompt** suppresses only the running prompts, including during manual HUD peek. Other action prompts retain game behavior. Apply, then load a save. Existing settings receive the new option set to On, with their preferences and comments preserved.
