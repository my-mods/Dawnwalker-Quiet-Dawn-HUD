# Quiet Dawn HUD - Auto-hide HUD

Health and stamina now respond to resource-change events without recurring stat checks. A cached-state deadline preserves the hide delay and rapid loss/recovery events.

The optional Show Compass variant displays the compass at 50% opacity. Standard and optional variants share the same HUD behavior and runtime code.

Combat, weapon draw, lock-on, and focus keep the general HUD hidden. Health and stamina appear together after either resource drops and hide 1.5 seconds after the last drop, unless either value is strictly below 20%.

The neutral enemy lock-on marker hides when directional indicators are disabled. Enabling directions restores the shared widget immediately after the setting change is processed. Active attack, parry-window, unblockable, and weak-spot cues retain game visibility rules. Enemy health remains unchanged.

Object-address comparisons correct false world mismatches during HUD initialization. Bounded readiness retries retain early marker events until player ownership is ready. Resource updates touch only the stat panels, and pending panel updates take priority over sampling at low frame rates.

Optional personal INI diagnostics use the debugLogging setting and report visibility changes and bounded timing summaries. Completed workers stop through explicitly chained one-shot callbacks.

Directional indicator restoration now follows the actual menu setting and refreshes cached markers on setting changes. The widget's internal display toggle no longer overrides the menu choice.
