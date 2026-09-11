# Changelog

## Unreleased

- Add a one-click Blueprint hook setup script that edits only the required INI setting and backs up the original. Use the installed Framecore Performance template only when the active INI is missing.
- Include the exact hook-registration exception in Logging output once per hook per session.

- Restore HUD hiding after death-screen reloads when old HUD objects have been destroyed or replaced.

- Restore HUD and enemy-information hiding when loading notifications are missed or player attributes become ready after the first initialization attempt.

- Display compass opacity and visibility thresholds as percentages, explain when resource displays stay visible, and use direct On/Off visibility values.

- Simplify diagnostics to a single Logging switch at the end of Mod Settings.
- Clarify HUD hold durations and default controls. HUD visibility switches now show On for visible and Off for hidden; compass opacity alone controls compass visibility.

- Fix the Mod Settings "config key missing or ambiguous" error when opening Quiet Dawn before loading a save after an upgrade.

- Hide enemy names and difficulty icons by default. Add independent Mod Settings toggles to restore either, and preserve older settings files when adding the new defaults.

- Add a 3-second full player HUD peek on the existing Controls Legend hold gesture (Menu/Options on standard controller layouts). Refresh on another hold and restore automatic visibility afterward, keeping low health visible.

- Show health alerts at full opacity, including when the stat panels start transparent. Keep health visible below 50% and extend health/blood-loss reveals to 4 seconds; stamina retains its 20% threshold and 1.5-second delay.
- Follow the blood bar in vampire form and HP in human form. Handle overdrinking, form changes and blood-bar capacity changes.
- Listen to the stat widgets' actual update functions as well as resource event handlers, covering direct event-graph updates without polling.

- Replace periodic health/stamina checks with resource-change hooks and a cached-state hide deadline. Preserve rapid loss/recovery events and stop all resource timers after the hold settles.

- Read the actual Directional Indicator menu setting instead of the widget's separate internal display toggle. Refresh cached markers on setting changes so enabling indicators restores a previously hidden widget.

- Restore the shared marker/directional widget when directional indicators are enabled, including after changing the setting during play. Hide the neutral marker only while directions are disabled; preserve active combat cues.

- Set the optional Show Compass variant to 50 percent compass opacity.

- Compare Unreal object addresses instead of Lua wrapper identity throughout HUD ownership, marker ownership, panel caching, and player-state tracking. This fixes false world mismatches that prevented initialization.
- Separate HUD ownership acceptance from resource reads to keep their native work on separate frames.

- Fix HUD ownership retries stopping after the first unsuccessful attempt, leaving HUD and neutral marker hiding uninitialized.
- Retain early marker construction events until HUD initialization and retry delayed marker ownership with a finite budget. Add readiness diagnostics; preserve combat cues and difficulty rules.

- Hide the neutral enemy lock-on marker while preserving active cues on its shared widget.
- Add bounded event-driven marker updates to the existing worker; no new polling timer or difficulty override.

- Reduce resource show/hide updates to the two stat panels; reuse the event result and cache missing fields until lifecycle/preset changes.
- Keep pending panel updates progressing during resource-event bursts.
- Stop resource reads entirely when neither stat panel is configured.

- Keep general HUD hidden during combat, weapon draw, lock-on, and focus.
- Reveal the combined health/stamina panel after either resource drops for 1.5 seconds, or while either remains strictly below 20%.
- Preserve native enemy health and difficulty-controlled parry/attack indicators.
- Replace broad reveal controls with configurable resource thresholds and hold durations; remove F8 whole-HUD reveal.
- Add bounded 100 ms player-resource sampling, terminating on invalid contexts.

- Renamed display title to Quiet Dawn HUD - Auto-hide HUD.
- Added a complete optional Show Compass package that leaves compass visibility to the game.

- Initial standalone event-driven HUD implementation.
- Six optional persistent panels hidden while idle; combat, stance, lock-on, focus, and manual reveal support.
- Bounded initialization and panel updates, with no permanent worker after setup.

Pending development changes: add opt-in personal INI diagnostics with bounded event logging and phase summaries. Use explicitly chained one-shot callbacks so completed workers stop on the target UE4SS build; select the incoming job scope before deciding whether to sample stats.

- Standardize the debug logging setting as `debugLogging`; retain existing configuration compatibility.
