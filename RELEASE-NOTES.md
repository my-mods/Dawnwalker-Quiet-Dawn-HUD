# Quiet Dawn HUD - Auto-hide HUD

Health and stamina now respond to resource-change events and the stat widgets' update functions without recurring stat checks. Alerts remain readable when stat panels were transparent during initialization. A cached-state deadline preserves the hide delay and rapid loss/recovery events.

The optional Show Compass variant displays the compass at 50% opacity. Standard and optional variants share the same HUD behavior and runtime code.

Combat, weapon draw, lock-on, and focus keep the general HUD hidden. Health and stamina appear together at full opacity for 4 seconds after health/blood loss or 1.5 seconds after stamina use. Health below 50% or stamina below 20% keeps them visible. Vampire alerts follow blood-bar fill, including after changing form or blood-bar capacity.

The neutral enemy lock-on marker hides when directional indicators are disabled. Enabling directions restores the shared widget immediately after the setting change is processed. Attack and parry-direction cues stay hidden while directional indicators are disabled. Unblockable and weak-spot cues retain game visibility rules. Enemy and boss health bars, end caps and boss health-phase indicators stay hidden.

Object-address comparisons correct false world mismatches during HUD initialization. Bounded readiness retries retain early marker events until player ownership is ready. Resource updates touch only the stat panels, and pending panel updates take priority over sampling at low frame rates.

Optional personal INI diagnostics use the debugLogging setting and report visibility changes and bounded timing summaries. Completed workers stop through explicitly chained one-shot callbacks.

Directional indicator restoration now follows the actual menu setting and refreshes cached markers on setting changes. The widget's internal display toggle no longer overrides the menu choice.
