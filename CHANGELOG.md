# Changelog

## Unreleased

- Hide the neutral enemy lock-on marker while preserving active cues on its shared widget.
- Add bounded event-driven marker updates to the existing worker; no new polling timer or difficulty override.

- Reduce resource show/hide updates to the two stat panels; reuse the sampler result and cache missing fields until lifecycle/preset changes.
- Prevent low-frame-rate sampler callbacks from starving pending panel updates.
- Stop stat sampling entirely when neither stat panel is configured.

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
