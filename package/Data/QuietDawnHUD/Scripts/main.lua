-- Prepare the menu file once at startup; gameplay snapshots still wait for a save load.
local directory = assert(debug.getinfo(1, 'S').source:sub(2):match('^(.*[/\\])'))
local function report(message) print('[Save Settings] '..message..'\n') end
-- Discard this snapshot so menu edits are read afresh by the save-load session.
local prepared, prepareError = pcall(dofile, directory..'MenuSettings.lua')
if not prepared then report('Menu settings preparation failed: '..tostring(prepareError)) end
local session = dofile(directory..'UE4SSCommonSession.lua').new(_G, directory, report)
session.watch('/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C')
session.watch('/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatTargetIndicator.WBP_CombatTargetIndicator_C')
session.watch('/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatCharacterBar.WBP_CombatCharacterBar_C')
session.watch('/Game/_Dawnwalker/UI/_Unified/Combat/WBP_Combat_BossBar.WBP_Combat_BossBar_C')
local ok, err = pcall(function()
    dofile(directory..'UE4SSDawnwalkerSaveLoad.lua').start(_G, session, directory..'Gameplay.lua', report)
end)
if not ok then report('Save-load hooks unavailable: '..tostring(err)) end
