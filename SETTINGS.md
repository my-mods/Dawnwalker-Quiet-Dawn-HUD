# Settings

Install [Mod Setting Menu 1.0.5 or later](https://www.nexusmods.com/thebloodofdawnwalker/mods/271) and UE4SS through Vortex. The settings file is prepared when the mod starts. Open Main Menu > Mod Settings > All Mods. Select this mod, change settings and press Apply. **Load a save after Apply.** Restore discards unapplied changes; Reset selects this mod’s defaults.

The stable menu ID is `oOCamilleOo_QuietDawnHUD`. The mod generates `settings.ini` beside `mod_settings.ini` in its UE4SS mod folder. This generated file is the authoritative settings store and is not shipped in the ZIP. Existing supported preferences are imported on first use. After the new settings are saved and verified, the successfully imported legacy files are deleted if their contents are unchanged. Migration or save failures retain the originals. Cleanup failures are logged and do not prevent using the new settings. Files left by an earlier migration are not deleted automatically. Back up `settings.ini` before removing/reinstalling the mod or moving its folder. Restore that backup into the same runtime folder before launching. Do not restore an old INI over it.

Missing existing settings, duplicate or invalid settings stop configuration loading and are reported in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS.log`. Preserve the file before correcting it. If a menu save fails, preserve its temporary/backup files and follow the menu’s recovery instructions. Startup prepares the menu file once, including any supported upgrade. Gameplay reads a fresh settings snapshot when a save loads. Waiting at the main menu performs no recurring settings work; travel and possession events use the current snapshot. Settings are never polled. `debugLogging` controls additional diagnostic logging; it defaults to Off.

| Group | Setting | Choices or range |
| --- | --- | --- |
| General | Enabled | Off, On |
| Enemies | Hide enemy names | Off, On (default) |
| Enemies | Hide enemy difficulty icons | Off, On (default) |
| Vitals | Health or blood threshold | 0 to 1 |
| Vitals | Stamina threshold | 0 to 1 |
| Vitals | Health or blood hold | 0 to 60 |
| Vitals | Stamina hold | 0 to 60 |
| Vitals | Manual peek duration | 0 to 60 |
| Vitals | Manual peek | Off, On |
| Panels | Compass opacity | 0 to 1 |
| Diagnostics | Debug logging | Off, On |
| Diagnostics | Diagnostic summary interval | 5 to 120 |
| Diagnostics | Slow callback threshold | 0.1 to 1000 |
| Diagnostics | Diagnostic events per second | 1 to 20 |
| Panels | HumanStats | Off, On |
| Panels | VampireStats | Off, On |
| Panels | Compass | Off, On |
| Panels | QuestInfo | Off, On |
| Panels | Quickslots | Off, On |
| Panels | Crosshair | Off, On |
| Panels | AA Quickslots | Off, On |
| Panels | OpenFocusPrompt | Off, On |
| Panels | Quickslots ChangePrompt | Off, On |
| Panels | ControlsLegend | Off, On |
| Panels | BuffContainer | Off, On |
| Panels | AbilityCooldownsContainer | Off, On |
| Panels | CombatFocusPanel | Off, On |
| Panels | FocusCharge Bar | Off, On |
| Panels | SpecialAttackCooldown | Off, On |
| Panels | XPBar | Off, On |

Turn off **Hide enemy names** to restore enemy name labels (boss names), or **Hide enemy difficulty icons** to restore difficulty indicators for ordinary enemies and bosses. The choices are independent. Apply, then load a save. The player HUD peek keeps both choices in effect. At startup, older settings files receive only the missing new options, set to On, so the menu can edit them. Existing preferences and comments are preserved; the original file is retained as `settings.ini.before-enemy-labels`. Keep recovery files if an upgrade error is reported.

Console commands are not used to change settings.

Conditional rows and groups show relevant controls as you edit. Hidden options keep their saved values; hiding an option does not reset it. The interface uses toggles, labeled choices and sliders; the numeric representation in settings.ini is an implementation detail.

When upgrading an older Quiet Dawn package, back up `Scripts/QuietDawnConfig.lua` before Vortex replaces/removes that package. Restore the backed-up file beside the new scripts before first launch to import its panel/compass choices. If it is absent, the mod uses QuietDawnDefaults.lua. Successfully imported legacy Lua and diagnostics files are removed after the new settings are saved and verified.
