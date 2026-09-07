-- Quiet Dawn HUD - Auto-hide HUD
-- Read once at startup. Restart the game after editing.
return {
    enabled = true,
    -- Both stat panels show together when either resource needs attention.
    healthThreshold = 0.20, -- strictly below 20 percent
    staminaThreshold = 0.20,
    healthHoldSeconds = 1.5,
    staminaHoldSeconds = 1.5,
    -- Other listed panels stay hidden, including during combat and focus.
    -- Enemy health and difficulty-controlled indicators are never modified.
    panels = {"HumanStats", "VampireStats", "WBP_Compass", "WBP_HUD_QuestInfo",
        "WBP_HUD_Quickslots", "Crosshair", "WBP_AA_Quickslots", "WBP_OpenFocusPrompt",
        "WBP_HUD_Quickslots_ChangePrompt", "WBP_ControlsLegend", "WBP_BuffContainer",
        "WBP_HUD_AbilityCooldownsContainer", "CombatFocusPanel", "WBP_HUD_FocusCharge_Bar",
        "WBP_HUD_SpecialAttackCooldown", "XPBar"},
}
