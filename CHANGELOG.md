# Changelog

## Unreleased

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
