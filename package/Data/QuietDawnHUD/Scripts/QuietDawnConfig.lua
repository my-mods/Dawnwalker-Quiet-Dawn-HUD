-- Read once at game startup. Restart the game after editing.
return {
    enabled = true,
    -- These are direct named children of the game's HUD, not wildcard searches.
    panels = {"HumanStats", "VampireStats", "WBP_Compass", "WBP_HUD_QuestInfo",
              "WBP_HUD_Quickslots", "Crosshair"},
    showWeaponDrawn = true,
    showInFocus = true,
    showLockedOn = true,
    -- F8 toggles a persistent reveal of the managed panels.
    manualRevealKey = "F8",
}
