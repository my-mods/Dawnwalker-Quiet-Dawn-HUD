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
| Vitals | Health / blood hold duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Stamina hold duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Show HUD duration | 0 to 60 seconds in 0.5-second steps |
| Vitals | Show HUD on hold | Off, On |
| HUD visibility | Compass opacity | 0% to 100% in 5-point steps |
| HUD visibility | Human health and stamina | Off, On |
| HUD visibility | Vampire blood and stamina | Off, On |
| HUD visibility | Quest tracker | Off, On |
| HUD visibility | Quickslots | Off, On |
| HUD visibility | Crosshair | Off, On |
| HUD visibility | Quickslot shortcuts | Off, On |
| HUD visibility | Focus activation prompt | Off, On |
| HUD visibility | Switch quickslots prompt | Off, On |
| HUD visibility | Controls legend | Off, On |
| HUD visibility | Active buffs | Off, On |
| HUD visibility | Ability cooldowns | Off, On |
| HUD visibility | Combat focus | Off, On |
| HUD visibility | Focus charge | Off, On |
| HUD visibility | Special attack cooldown | Off, On |
| HUD visibility | Experience bar | Off, On |
| Diagnostics | Logging | Off, On |

Turn off **Hide enemy names** to restore enemy name labels (boss names), or **Hide enemy difficulty icons** to restore difficulty indicators for ordinary enemies and bosses. The choices are independent. Apply, then load a save. The player HUD peek keeps both choices in effect. At startup, older settings files receive only the missing new options, set to On, so the menu can edit them. Existing preferences and comments are preserved; the original file is retained as `settings.ini.before-enemy-labels`. Keep recovery files if an upgrade error is reported.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.

**HUD visibility:** On keeps the element visible under the game's normal rules. Off hides it between alerts or HUD peeks. The switches store On as 1 and Off as 0. Compass opacity is the only compass control: 0% hides it, and a positive percentage shows it at that opacity.

**Show HUD** uses the game's **Toggle Controls Legend** action. Hold **Menu (Xbox)**, **Options (PlayStation)**, or **L (keyboard)** by default. To change the controller button, edit **Toggle Controls Legend** in Controller Tweaks and Remap. For keyboard, change the game's Controls Legend binding. Quiet Dawn follows the remapped action. Show HUD duration controls the time the HUD remains visible after activation.

**Logging** is the final menu setting and the only diagnostic control. Leave it Off for normal play; On writes troubleshooting details to `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`.

**Visibility thresholds:** keep the health/stamina display visible while human health or vampire blood is below 50%, or stamina is below 20%, by default. Exactly the selected percentage does not trigger the threshold. Damage and stamina use can also reveal it for their hold durations, even above the thresholds. A 0% threshold disables that low-resource trigger. These rules apply when the corresponding HUD visibility switch is Off.

Unreleased menu settings now use percentages and direct On/Off values. Earlier development menu values are not converted. After updating a development installation, use Reset and Apply in Mod Settings, then load a save and set your preferences again. Reset replaces this mod's menu preferences with its defaults; back up settings.ini first if you want to retain a reference.
