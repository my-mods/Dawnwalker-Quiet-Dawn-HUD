-- Shared startup snapshot for gameplay and diagnostics. MIT.
local directory = assert(debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])'))
local Store = dofile(directory .. 'SettingsStore.lua')
local schema = dofile(directory .. 'SettingsSchema.lua')
local panels = {"HumanStats","VampireStats","WBP_Compass","WBP_HUD_QuestInfo","WBP_HUD_Quickslots","Crosshair","WBP_AA_Quickslots","WBP_OpenFocusPrompt","WBP_HUD_Quickslots_ChangePrompt","WBP_ControlsLegend","WBP_BuffContainer","WBP_HUD_AbilityCooldownsContainer","CombatFocusPanel","WBP_HUD_FocusCharge_Bar","WBP_HUD_SpecialAttackCooldown","XPBar"}
local values, err = Store.load(directory, schema, function()
    local legacyPath = directory .. 'QuietDawnConfig.lua'
    local legacy, le, lc = Store.read(legacyPath)
    local sources = legacy and {{path=legacyPath, text=legacy}} or {}
    if not legacy and lc ~= 2 then return nil, le end
    local ok, cfg
    if legacy then
        local chunk, ce = load(legacy, '@' .. directory .. 'QuietDawnConfig.lua', 't', {})
        if not chunk then return nil, ce end
        ok, cfg = pcall(chunk)
    else
        ok, cfg = pcall(dofile, directory .. 'QuietDawnDefaults.lua')
    end
    if not ok or type(cfg) ~= 'table' or type(cfg.panels) ~= 'table' then return nil, 'Invalid legacy QuietDawnConfig.lua' end
    local result = {}
    for _, key in ipairs({'enabled','healthThreshold','staminaThreshold','healthHoldSeconds','staminaHoldSeconds','manualPeek','manualPeekSeconds','compassOpacity'}) do
        local v = cfg[key]; if type(v)=='boolean' then v=v and 1 or 0 end; result[key]=v
    end
    local known = {};for _, p in ipairs(panels) do known[p]=true;result['panel_'..p]=0 end
    local seen = {}
    for _, p in ipairs(cfg.panels) do
        if not known[p] or seen[p] then return nil, 'Unknown or duplicate legacy panel' end
        seen[p]=true;result['panel_'..p]=1
    end
    local base=os.getenv('LOCALAPPDATA')
    if not base then return nil, 'LOCALAPPDATA unavailable for legacy migration' end
    local diagnosticsPath=base..'/Dawnwalker/Saved/Config/QuietDawnHUD.ini'
    local text, e, code=Store.read(diagnosticsPath)
    if text then sources[#sources+1]={path=diagnosticsPath, text=text} end
    if not text and code~=2 then return nil,e end
    local section, canonical, legacy='',nil,nil
    for line in (text or ''):gmatch('[^\r\n]+') do
        line=line:gsub('^\239\187\191',''):gsub('[;#].*$',''):match('^%s*(.-)%s*$')
        local header=line:match('^%[([^%]]+)%]$');if header then section=header:lower() end
        local key,value=line:match('^([%w_]+)%s*=%s*(.-)%s*$')
        if key and section=='debug' then
            key=key:lower();value=value:lower()
            local b=({['true']=1,['false']=0,['1']=1,['0']=0,on=1,off=0,yes=1,no=0})[value]
            if key=='debuglogging' or key=='enabled' then
                if b==nil then return nil,'Invalid legacy debug toggle' end
                if key=='debuglogging' then canonical=b else legacy=b end
            else
                local name=({summaryseconds='SummarySeconds',slowcallbackms='SlowCallbackMs',maxeventspersecond='MaxEventsPerSecond'})[key]
                if name then result[name]=tonumber(value);if not result[name] then return nil,'Invalid legacy diagnostics value' end end
            end
        end
    end
    result.debugLogging=canonical or legacy or 0
    return result, nil, sources
end)
if not values then print('[Quiet Dawn HUD] Settings rejected: '..tostring(err));return {enabled=false,panels={},debugLogging=false} end
values.enabled=values.enabled==1;values.manualPeek=values.manualPeek==1;values.debugLogging=values.debugLogging==1
values.panels={};for _, p in ipairs(panels) do if values['panel_'..p]==1 then values.panels[#values.panels+1]=p end end
return values
