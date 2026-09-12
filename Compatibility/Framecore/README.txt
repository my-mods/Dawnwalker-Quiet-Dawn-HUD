Legacy full-INI overlay

Use Enable-Blueprint-Hooks.bat bundled with the main Quiet Dawn mod to edit only the required setting. This older overlay replaces the complete INI and is retained for existing installations. Disable it and deploy your preferred loader configuration before using the script.

Quiet Dawn - Configurable HUD - Framecore Settings

Quiet Dawn requires Blueprint script hooks. Framecore 2b's Performance and Compatibility profiles both disable them. Start from Performance and set the following existing keys under `[Hooks]` in `Dawnwalker/Binaries/Win64/ue4ss/UE4SS-settings.ini`:

```ini
HookProcessInternal = 0
HookProcessLocalScriptFunction = 1
```

Keep the other Performance settings and restart the game. These settings enable the required dispatcher; they do not establish stability or frame-time performance on every game/runtime build. If enabling it causes a crash, restore the previous configuration and retain the launch log for diagnosis.

The optional **Quiet Dawn - Configurable HUD - Framecore Settings** overlay contains the complete Performance INI with this single change. It replaces the entire INI; it does not merge personal preferences. Back up your current INI first. Import `Quiet-Dawn-Configurable-HUD-Framecore-Settings.zip` through Vortex as **UE4SS (loader)** and make its `UE4SS-settings.ini` win the conflict with Framecore. Keep the main Quiet Dawn package as **UE4SS (Lua mods)**. Disabling the settings overlay and deploying restores the underlying Vortex-managed configuration.

Framecore's profile switcher replaces the complete INI. Switching profiles, reinstalling the loader, or changing the winning configuration can remove this setting; reapply the custom configuration through Vortex afterward.

Updating an older Root-type installation: disable the old settings entry and deploy first. Replace/reinstall that entry from this corrected ZIP through Vortex, confirm UE4SS (loader), then enable it and set it to load after UE4SS For BoD. Deploy again. Changing the old entry's type without reinstalling does not correct its stored paths.
