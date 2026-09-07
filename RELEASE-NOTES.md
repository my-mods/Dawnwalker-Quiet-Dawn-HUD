# Quiet Dawn HUD - Auto-hide HUD — development build

Combat, weapon draw, lock-on, and focus no longer reveal the general HUD. Health and stamina appear together after either resource drops and hide 1.5 seconds after the last drop, unless either value is strictly below 20%. Enemy health and difficulty-controlled parry/attack indicators retain normal game behavior. Manual whole-HUD reveal has been removed.

Standard and optional Show Compass archives use identical runtime code. Install one version only through Vortex with the game closed. Back up preferences: this update replaces the configuration rather than merging it. Disable HUD Tweaks and Fixes before enabling Quiet Dawn.

A 100 ms sampler reads the current player's two resource percentages without global searches or widget traversal. Gameplay validation and frame-time measurements remain pending. No release version or tag has been assigned.

Performance audit: resource show/hide jobs now touch only the stat panels and reuse the sampled result. Missing fields do not repeatedly restart readiness work after resource changes. The sampler yields to pending panel jobs to avoid low-frame-rate starvation. Offline comparison reduced panel reads from 32 to 4 per show/hide cycle; actual game frame times remain unmeasured.
