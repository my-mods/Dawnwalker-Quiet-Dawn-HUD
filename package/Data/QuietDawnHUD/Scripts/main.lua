local D = require("QuietDawnDiagnostics")
-- Quiet Dawn HUD | MIT License
-- Event-driven panel opacity. No widget-tree walks, global object searches,
-- class-default edits, animation hooks, or Lua coroutines.
-- Resource reads run only on resource-change and HUD/player lifecycle events.
local ok, config = pcall(require, "QuietDawnConfig")
if not ok or type(config) ~= "table" then
    print("[Quiet Dawn HUD] Invalid configuration; HUD left to the game.")
    return
end
local allowed = {HumanStats=true, VampireStats=true, WBP_Compass=true,
    WBP_HUD_QuestInfo=true, WBP_HUD_Quickslots=true, Crosshair=true,
    WBP_AA_Quickslots=true, WBP_OpenFocusPrompt=true,
    WBP_HUD_Quickslots_ChangePrompt=true, WBP_ControlsLegend=true,
    WBP_BuffContainer=true, WBP_HUD_AbilityCooldownsContainer=true,
    CombatFocusPanel=true, WBP_HUD_FocusCharge_Bar=true,
    WBP_HUD_SpecialAttackCooldown=true, XPBar=true}
local names, seen = {}, {}
if type(config.panels) ~= "table" then return end
for _, name in ipairs(config.panels) do
    if not allowed[name] or seen[name] then
        print("[Quiet Dawn HUD] Unknown or duplicate panel; disabled.")
        return
    end
    seen[name] = true
    names[#names+1] = name
end
if type(config.enabled) ~= "boolean" then return end
if config.compassOpacity~=nil and (type(config.compassOpacity)~="number"
    or config.compassOpacity~=config.compassOpacity or config.compassOpacity<0 or config.compassOpacity>1) then
    print("[Quiet Dawn HUD] Invalid compass opacity; disabled.")
    return
end
for _, key in ipairs({"healthThreshold", "staminaThreshold"}) do
    local value=config[key]
    if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then
        print("[Quiet Dawn HUD] Invalid threshold; disabled.")
        return
    end
end
for _, key in ipairs({"healthHoldSeconds", "staminaHoldSeconds"}) do
    local value=config[key]
    if type(value) ~= "number" or value ~= value or value < 0 or value > 60 then
        print("[Quiet Dawn HUD] Invalid hold duration; disabled.")
        return
    end
end
if not config.enabled or #names == 0 then return end
local statNames = {}
for _, name in ipairs(names) do
    if name == "HumanStats" or name == "VampireStats" then statNames[#statNames+1]=name end
end
if type(ExecuteInGameThreadWithDelay) ~= "function" or type(CancelDelayedAction) ~= "function" then
    print("[Quiet Dawn HUD] Requires cancellable delayed game-thread callbacks; disabled.")
    return
end

if D.debugLogging then D.event("config","healthThreshold=%.3f staminaThreshold=%.3f healthHold=%.3fs staminaHold=%.3fs panels=%d",config.healthThreshold,config.staminaThreshold,config.healthHoldSeconds,config.staminaHoldSeconds,#names) end
local ROOT = "/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C"
local hud, candidate, controller, world
local hudAddress, controllerAddress
local worker, dirty, stateReady = false, false, false
local statsPending, expiryPending = false, false
local statsRefresh=true
local expiryHandle,expiryDue,expiryHUD,expiryController,expiryPawn
local healthDropped, staminaDropped = false, false
local statHookFailures, statHookAttempt = false, 0
local firstFailedStatHook
local lastPawnAddress, lastCombatAddress, previousHealth, previousStamina
local healthUntil, staminaUntil = 0, 0
local panels = {}
local absent, jobNames, fullPending, fullJob = {}, names, false, true
local cursor, desired, attempts = 0, 1, 0
local hooks, hookIndex = {}, 1
local warned = false
local frameClock, lastFrame
local wake, armExpiry
local function valid(object)
    return object ~= nil and object:IsValid()
end
local function sameObject(left, right)
    -- Reflected calls can return different Lua wrappers for the same UObject.
    -- Revalidate both objects; compare native identity, never wrapper identity.
    return valid(left) and valid(right) and left:GetAddress()==right:GetAddress()
end
local function unwrap(param)
    if param == nil then return nil end
    return param:get()
end
-- These are actual Blueprint delegate handlers, not delegate signatures.
-- Stock OnInitialized binds VampireStats to OnStaminaChanged in both forms.
local STAT_ROOT = "/Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/"
local function statEvent(kind, field)
    return function(context, newParam, oldParam)
        if #statNames==0 then return end
        local object=unwrap(context)
        if not valid(hud) or not valid(object) or not sameObject(hud[field],object)
            or not valid(controller) or not sameObject(object:GetOwningPlayer(),controller)
            or not sameObject(object:GetWorld(),world) then return end
        local new, old=tonumber(unwrap(newParam)),tonumber(unwrap(oldParam))
        if new and old and new==old then return end
        -- Retain a drop even if a second event restores the value before the worker.
        if new and old and new<old then
            if kind=="health" then healthDropped=true else staminaDropped=true end
        end
        statsPending=true
        if D.debugLogging then D.count("resourceEvents") end
        wake("resource")
    end
end
-- The game shares this widget between neutral lock-on, directions and cues.
-- Hide neutral and directional cues when directions are disabled.
local MARKER = "/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatTargetIndicator.WBP_CombatTargetIndicator_C"
local markerSpecs = {"Construct", "OnObservedStubIconTypeChanged",
    "NotifyIndicatorCleared", "EnableHardLock", "RefreshIndicatorsVisibility",
    "ToggleShowOnlyMiddleIndicator"}
local markerHookIndex, markerHookAttempts, markerSeen = 1, 0, false
local markerQueue, markerPending, markerFirst, markerLast = {}, {}, 1, 0
local markerCache, markerSlots, markerCount, markerPrune = {}, {}, 0, 1
local markerCacheWorld, markerCacheController, markerTurn
-- Steam build 25129649: ERebelSetting::Game_Difficulty_CombatDirectionMarkers=71.
-- This menu setting is distinct from the widget's internal Hide Directions flag.
local settingsFactory, settingsObject, directionsEnabled
local settingsPending, settingsAttempts = true, 0
local function markersReady()
    -- Keep construction events queued until HUD ownership has been accepted.
    -- Missing HUD readiness sleeps until a lifecycle event, without polling.
    return markerFirst<=markerLast and candidate==nil and world~=nil and controller~=nil
end
local function queueMarker(object, retries)
    if object == nil then return end
    -- Capture only the wrapper here: construction may not be on the game
    -- thread. Pointer/property reads happen in the shared game-thread worker.
    local pending=markerPending[object]
    if pending then pending.object=object; if D.debugLogging then D.count("markerCoalesced") end; return end
    -- Excess objects remain under game control. No unbounded queues or scans.
    if markerLast-markerFirst+1 >= 64 then if D.debugLogging then D.count("markerQueueFull") end; return end
    local job={object=object, retries=retries or 0}
    markerLast=markerLast+1
    markerQueue[markerLast]=job
    markerPending[object]=job
    if wake then wake("marker") end
end
local function markerEvent(context)
    queueMarker(unwrap(context))
end
local function refreshSettings(context, setting)
    if setting and tonumber(unwrap(setting))~=71 then return end
    settingsObject=unwrap(context)
    settingsPending,settingsAttempts=true,0
    wake("settings")
end
local function settingsStep()
    settingsAttempts=settingsAttempts+1
    local success,value=pcall(function()
        if not valid(settingsFactory) then
            settingsFactory=StaticFindObject("/Script/RebelSettings.Default__RebelGameUserSettings")
            return nil
        end
        if not valid(settingsObject) then
            settingsObject=settingsFactory:Get()
            return nil
        end
        local out={}
        local found=settingsObject:GetSettingAsBool(71,out)
        if found and type(out.OutSettingBool)=="boolean" then return out.OutSettingBool end
    end)
    if success and type(value)=="boolean" then
        settingsPending=false
        if D.debugLogging then D.count(value and "directionReadsEnabled" or "directionReadsDisabled") end
    elseif settingsAttempts<8 then
        return
    else
        value=nil
        settingsPending=false
        if D.debugLogging then D.count("directionReadFailures") end
    end
    if directionsEnabled~=value then
        directionsEnabled=value
        -- Fixed-size plain Lua cache traversal; native work stays in marker slices.
        for _,entry in pairs(markerCache) do queueMarker(entry.object) end
    end
    if D.debugLogging then D.event("directions","menuEnabled=%s readSuccess=%s attempts=%d",tostring(value),tostring(success),settingsAttempts) end
end
settingsStep=D.wrap("directions",settingsStep)
local function markerHooksStep()
    local path=MARKER..":"..markerSpecs[markerHookIndex]
    local success, pre, post=pcall(RegisterHook, path, markerEvent)
    markerHookAttempts=markerHookAttempts+1
    if success and type(pre)=="number" and type(post)=="number" then
        hooks[path]={pre,post}
        markerHookIndex=markerHookIndex+1
        if D.debugLogging then D.event("hook","registered=%s",path) end
    end
end
local function markerStep()
    local job=markerQueue[markerFirst]
    markerQueue[markerFirst]=nil
    markerPending[job.object]=nil
    markerFirst=markerFirst+1
    if markerFirst>markerLast then markerFirst,markerLast=1,0 end
    if markerHookIndex<=#markerSpecs then return end -- fail open until hooks work
    local object=job.object
    if not valid(object) then return end
    job.address=object:GetAddress()
    if not valid(controller) or not valid(world) then return end
    local objectWorld, owner=object:GetWorld(), object:GetOwningPlayer()
    if not valid(objectWorld) or not valid(owner) then
        if D.debugLogging then
            D.count("markerNotReady")
            if job.retries==0 or job.retries==119 then
                D.event("marker","id=%s ownership not ready; attempt=%d/120",tostring(job.address),job.retries+1)
            end
        end
        if job.retries<119 then queueMarker(object,job.retries+1) end
        return
    end
    if not sameObject(objectWorld,world) or not sameObject(owner,controller) then
        if D.debugLogging then D.count("markerForeignOwner") end
        return
    end
    if not sameObject(controller:GetWorld(),world) then return end
    if not sameObject(markerCacheWorld,world) or not sameObject(markerCacheController,controller) then
        markerCache,markerSlots,markerCount,markerPrune={}, {}, 0, 1
        markerCacheWorld,markerCacheController=world,controller
    end
    local entry=markerCache[job.address]
    if not entry and markerCount>=64 then
        if D.debugLogging then D.count("markerCacheFull") end
        -- Inspect one old slot per frame, not the entire object cache.
        local slot=markerPrune
        markerPrune=markerPrune%64+1
        local old=markerSlots[slot]
        if not valid(old.object) then
            markerCache[old.address]=nil
            markerSlots[slot]=nil
            markerCount=markerCount-1
            queueMarker(object,job.retries+1)
        end
        return
    end
    -- This Blueprint property is updated by the game's directional and
    -- non-directional display paths. Current build 25191761: 0=neutral,
    -- 1..8=attack/parry directions, 9=unblockable, 10..13=weak spots.
    -- Preserve the entire widget whenever the actual menu option enables cues.
    -- Unknown settings fail open so an unreadable option cannot suppress them.
    local readable,icon=pcall(function() return tonumber(object["Currently Displayed Icon Type"]) end)
    local current=object:GetRenderOpacity()
    if not entry then
        entry={object=object,address=job.address,original=current}
        markerCache[job.address]=entry
        -- Fixed-size plain-Lua slot selection; no object reads or traversal.
        for slot=1,64 do if not markerSlots[slot] then markerSlots[slot]=entry;break end end
        markerCount=markerCount+1
    end
    -- Retain the marker even when settings are unavailable, so a later
    -- successful settings event can revisit it without global discovery.
    if not readable or icon==nil or directionsEnabled==nil then
        if entry.hidden then
            object:SetRenderOpacity(entry.original)
            entry.hidden=false
        end
        if job.retries<8 then queueMarker(object,job.retries+1) end
        return
    end
    if icon>=0 and icon<=8 and icon%1==0 and not directionsEnabled then
        if not entry.hidden or current~=0 then entry.original=current end
        if current~=0 then
            object:SetRenderOpacity(0)
            if D.debugLogging then D.count("markerWrites");D.event("marker","id=%s icon=%s opacity=%.3f->0",tostring(job.address),tostring(icon),current) end
        end
        entry.hidden=true
    elseif entry.hidden then
        if current~=entry.original then
            object:SetRenderOpacity(entry.original)
            if D.debugLogging then D.count("markerWrites");D.event("marker","id=%s icon=%s opacity=%.3f->%.3f",tostring(job.address),tostring(icon),current,entry.original) end
        end
        entry.hidden=false
    else
        entry.original=current -- retain the game's opacity while a cue is active
    end
end
markerStep=D.wrap("marker",markerStep)
markerHooksStep=D.wrap("hook",markerHooksStep)
-- Enemy health lives outside WBP_GameHUD. Hide only its health widgets,
-- keeping stamina, wound information and combat warnings under game control.
-- Build 25191761: these named children and lifecycle functions are exported
-- by WBP_CombatCharacterBar and WBP_Combat_BossBar.
local healthTypes = {
    {path="/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatCharacterBar.WBP_CombatCharacterBar_C",
     fields={"SegmentedHealthBar","HealthBarLeftCap","HealthBarRightCap"},
     events={"Construct","UpdateTarget"}},
    {path="/Game/_Dawnwalker/UI/_Unified/Combat/WBP_Combat_BossBar.WBP_Combat_BossBar_C",
     fields={"HealthBar","HealthBarLeftCap","HealthBarRightCap","IndicatorBox"},
     events={"Update Owner"}},
}
local healthQueue, healthPending, healthFirst, healthLast = {}, {}, 1, 0
local function healthReady()
    return healthFirst<=healthLast and candidate==nil and valid(hud)
end
local function queueHealth(object, spec)
    if object==nil then return end
    if healthPending[object] then healthPending[object].again=true;return end
    if healthLast-healthFirst+1>=64 then
        if D.debugLogging then D.count("enemyHealthQueueFull") end
        return
    end
    local job={object=object,spec=spec,field=1,attempts=0}
    healthLast=healthLast+1;healthQueue[healthLast]=job;healthPending[object]=job
    wake("enemyHealth")
end
local function healthStep()
    local job=healthQueue[healthFirst]
    healthQueue[healthFirst]=nil;healthFirst=healthFirst+1
    if healthFirst>healthLast then healthFirst,healthLast=1,0 end
    local object,spec=job.object,job.spec
    local function retry()
        job.attempts=job.attempts+1
        if job.attempts>=120 then
            if D.debugLogging then D.event("enemyHealth","readiness exhausted: %s field=%s",spec.path,spec.fields[job.field]) end
            return false
        end
        return true
    end
    local keep=false
    local success,reason=pcall(function()
        if not valid(object) then return end
        local eventIndex=spec.eventIndex or 1
        if eventIndex<=#spec.events then
            local path=spec.path..":"..spec.events[eventIndex]
            if hooks[path] then spec.eventIndex=eventIndex+1;keep=true;return end
            local ok,pre,post=pcall(RegisterHook,path,function(context)
                queueHealth(unwrap(context),spec)
            end)
            spec.hookAttempts=(spec.hookAttempts or 0)+1
            if ok and type(pre)=="number" and type(post)=="number" then
                hooks[path]={pre,post};spec.eventIndex=eventIndex+1;spec.hookAttempts=0
            elseif spec.hookAttempts>=12 then
                spec.failedEvent=spec.failedEvent or eventIndex
                spec.eventIndex=eventIndex+1;spec.hookAttempts=0
                if D.debugLogging then D.event("enemyHealth","lifecycle hook unavailable: %s",path) end
            end
            keep=true
            return
        end
        local ow,pc=object:GetWorld(),object:GetOwningPlayer()
        if not valid(ow) or not valid(pc) then keep=retry();return end
        if not sameObject(ow,world) or not sameObject(pc,controller)
            or not sameObject(controller:GetWorld(),world) then return end
        local child=object[spec.fields[job.field]]
        if not valid(child) then keep=retry();return end
        if child:GetRenderOpacity()~=0 then
            child:SetRenderOpacity(0)
            if D.debugLogging then D.count("enemyHealthWrites");D.event("enemyHealth","hidden=%s",spec.fields[job.field]) end
        end
        job.field=job.field+1;job.attempts=0
        keep=job.field<=#spec.fields
        if not keep and job.again then job.field=1;job.again=false;keep=true end
    end)
    if not success then
        keep=retry()
        if D.debugLogging then D.event("enemyHealth","update failed: %s",tostring(reason)) end
    end
    if keep then healthLast=healthLast+1;healthQueue[healthLast]=job
    else healthPending[object]=nil end
end
healthStep=D.wrap("enemyHealth",healthStep)
local healthTurn=false
local function signal() if D.debugLogging then D.count("presetEvents") end;wake() end
local function capture(context)
    statsRefresh=true
    candidate = unwrap(context)
    wake()
end
-- Blueprint paths verified against the stock WBP_GameHUD export table.
-- Native paths use an explicit post-hook; Blueprint callbacks are post-hooks.
local specs = {
    {"/Script/DogwoodUI.HUDManagerSubsystem:PushHUDPreset", signal, true},
    {"/Script/DogwoodUI.HUDManagerSubsystem:PopHUDPreset", signal, true},
    {"/Script/Engine.PlayerController:ClientRestart", function(context)
        local pc = unwrap(context)
        if valid(pc) and pc:IsLocalController() then
            statsRefresh=true
            controller = pc
            controllerAddress = pc:GetAddress()
            wake()
        end
    end, true},
    {ROOT..":Construct", capture},
    {ROOT..":BP_OnActivated", capture},
    {ROOT..":On Coen Form Changed", capture},
    {"/Script/RebelSettings.RebelGameUserSettings:SetSetting", refreshSettings, true},
    {"/Script/RebelSettings.RebelGameUserSettings:SetSettingAsBool", refreshSettings, true},
}
if #statNames>0 then
    for _,entry in ipairs({
        {"WBP_HUD_HumanStats", "On HP changed", "health", "HumanStats"},
        {"WBP_HUD_VampireStats", "On HP changed", "health", "VampireStats"},
        {"WBP_HUD_VampireStats", "On Stamina changed", "stamina", "VampireStats"},
    }) do
        specs[#specs+1]={STAT_ROOT..entry[1].."."..entry[1].."_C:"..entry[2],statEvent(entry[3],entry[4]),false,true}
    end
end
local function noop() end
local function registerOne()
    if hookIndex > #specs then return true end
    local spec = specs[hookIndex]
    if hooks[spec[1]] then hookIndex=hookIndex+1;return hookIndex>#specs end
    local success, pre, post
    if spec[3] then
        success, pre, post = pcall(RegisterHook, spec[1], noop, spec[2])
    else
        success, pre, post = pcall(RegisterHook, spec[1], spec[2])
    end
    if success and type(pre) == "number" and type(post) == "number" then
        hooks[spec[1]] = {pre, post}
        hookIndex = hookIndex + 1
        statHookAttempt=0
        if D.debugLogging then D.event("hook","registered=%s",spec[1]) end
    end
    if not success and spec[4] then
        statHookAttempt=statHookAttempt+1
        if statHookAttempt>=12 then
            statHookFailures=true
            firstFailedStatHook=firstFailedStatHook or hookIndex
            print("[Quiet Dawn HUD] Resource event hook unavailable; stat panels left to the game: "..spec[1])
            hookIndex=hookIndex+1
            statHookAttempt=0
        end
    end
    return hookIndex > #specs
end
registerOne=D.wrap("hook",registerOne)
local function accept(object)
    if not valid(object) then return false, "invalid HUD" end
    local pc = object:GetOwningPlayer()
    if not valid(pc) then return false, "missing owning player" end
    if not pc:IsLocalController() then return false, "non-local owning player" end
    local objectWorld = object:GetWorld()
    if not sameObject(objectWorld,pc:GetWorld()) then return false, "world mismatch" end
    if valid(controller) and not sameObject(controller,pc) then return false, "controller mismatch" end
    if not sameObject(object,hud) or not sameObject(objectWorld,world) then
        hud, world, panels, absent = object, objectWorld, {}, {}
        lastPawnAddress, lastCombatAddress, previousHealth, previousStamina = nil, nil, nil, nil
        healthUntil, staminaUntil = 0, 0
        statsRefresh=true
        healthDropped,staminaDropped=false,false
        if D.debugLogging then D.event("lifecycle","HUD/world changed; cached state reset") end
    end
    controller = pc
    hudAddress, controllerAddress = object:GetAddress(), pc:GetAddress()
    return true
end
local function snapshot()
    if statHookFailures then return nil end
    if not valid(hud) or not valid(controller) or not valid(world) then return nil end
    if not sameObject(hud:GetWorld(),world) or not sameObject(controller:GetWorld(),world)
        or not sameObject(hud:GetOwningPlayer(),controller) then return nil end
    local pawn = controller.Pawn
    if not valid(pawn) or not sameObject(pawn:GetWorld(),world) then return nil end
    local combat = pawn.CombatComponent
    if not valid(combat) then return nil end
    -- No component search, arrays, or borrowed attribute structures.
    local health = tonumber(combat:GetHealthPercentage())
    local stamina = tonumber(combat:GetStaminaPercentage())
    if not health or not stamina or health ~= health or stamina ~= stamina
        or health < 0 or stamina < 0 or health > 1 or stamina > 1 then return nil end
    local now = frameClock:GetGameTimeInSeconds(controller)
    local pawnAddress, combatAddress=pawn:GetAddress(), combat:GetAddress()
    if lastPawnAddress~=pawnAddress or lastCombatAddress~=combatAddress then
        previousHealth, previousStamina = nil, nil
        healthUntil, staminaUntil = 0, 0
        lastPawnAddress, lastCombatAddress = pawnAddress, combatAddress
    end
    if healthDropped or (previousHealth and health < previousHealth - 0.000001) then
        healthUntil = now + config.healthHoldSeconds
    end
    if staminaDropped or (previousStamina and stamina < previousStamina - 0.000001) then
        staminaUntil = now + config.staminaHoldSeconds
    end
    healthDropped,staminaDropped=false,false
    previousHealth, previousStamina = health, stamina
    local needed = health < config.healthThreshold or stamina < config.staminaThreshold
        or now < healthUntil or now < staminaUntil
    if D.debugLogging then D.vitals(health,stamina,needed,now,healthUntil,staminaUntil) end
    return needed and 1 or 0
end
snapshot=D.wrap("sample",snapshot)
local function step()
    -- At most one hook registration OR one state snapshot OR one direct panel
    -- read/write per callback. 16 ms delay yields to a later game frame.
    if hookIndex <= #specs then
        if hookIndex > 3 and candidate == nil and not valid(hud) then
            worker=false
            return true
        end
        registerOne()
        attempts = attempts + 1
        if attempts >= 120 then
            if not warned then print("[Quiet Dawn HUD] HUD hooks not ready; waiting for a lifecycle event."); warned=true end
            worker=false
            return true
        end
        return false
    end
    if markerSeen and markerHookIndex<=#markerSpecs and markerHookAttempts<12 then
        markerHooksStep()
        return false
    end
    if settingsPending and markerSeen then
        settingsStep()
        return false
    end
    -- Alternate with existing work: one health child operation per frame,
    -- sharing the same one-shot worker and its native frame gate.
    healthTurn=not healthTurn
    if healthReady() and (healthTurn or (cursor==0 and not dirty and not statsPending and not markersReady())) then
        healthStep()
        return false
    end
    -- Coalesce resource events; no timer requests resource reads.
    if statsPending and candidate==nil and cursor==0 and not dirty then
        statsPending=false
        local success,value=pcall(snapshot)
        stateReady=success and value~=nil
        if not stateReady then healthDropped,staminaDropped=false,false end
        local target=stateReady and value or 1
        if target~=desired then desired=target;dirty=true end
        armExpiry()
        return false
    end
    markerTurn=not markerTurn
    if markersReady() and (markerTurn or (cursor==0 and not dirty)) then
        local success, reason=pcall(markerStep)
        if not success then print("[Quiet Dawn HUD] Marker update skipped: "..tostring(reason)) end
        return false
    end
    if cursor==0 and not dirty then
        if markersReady() or healthReady() then return false end
        worker=false
        armExpiry()
        return true
    end
    if cursor == 0 then
        dirty = false
        if candidate then
            local accepted, reason=accept(candidate)
            if accepted then
                candidate=nil
                dirty=true
                return false -- ownership acceptance and resource reads use separate frames
            else
                attempts=attempts+1
                if D.debugLogging then
                    D.count("hudNotReady")
                    if attempts==1 or attempts==120 then
                        D.event("lifecycle","HUD ownership not ready; reason=%s attempt=%d/120",reason,attempts)
                    end
                end
                -- Preserve the job while ownership becomes ready. Clearing
                -- dirty here used to terminate the worker after one attempt.
                if attempts < 120 then dirty=true; return false end
                candidate=nil
            end
        end
        fullJob, fullPending = fullPending, false
        jobNames = fullJob and names or statNames
        -- Resource events already supplied a fresh snapshot; only lifecycle jobs read again.
        if fullJob then
            if #statNames > 0 and statsRefresh then
                statsRefresh=false
                local success, value = pcall(snapshot)
                stateReady = success and value ~= nil
                desired = stateReady and value or 1
            elseif #statNames==0 then
                stateReady, desired = false, 0
            end
        end
        cursor=1
        return false
    end
    if cursor <= #jobNames then
        -- Revalidate ownership inside every deferred operation, including a still
        -- valid HUD left over from the previous world.
        if valid(hud) and valid(controller) and sameObject(hud:GetWorld(),world)
            and sameObject(controller:GetWorld(),world) and sameObject(hud:GetOwningPlayer(),controller) then
            local name = jobNames[cursor]
            if absent[name] then cursor=cursor+1; return false end
            local object = hud[name]
            if valid(object) then
                local current = object:GetRenderOpacity()
                local entry = panels[name]
                if not entry or not sameObject(entry.object,object) then
                    entry = {object=object, original=current}
                    panels[name]=entry
                end
                local isStats = name == "HumanStats" or name == "VampireStats"
                local target = isStats and desired == 1 and entry.original or 0
                if name=="WBP_Compass" and config.compassOpacity~=nil then target=config.compassOpacity end
                if current ~= target then
                    object:SetRenderOpacity(target)
                    if D.debugLogging then D.count("panelWrites");D.event("panel","name=%s opacity=%.3f->%.3f",name,current,target) end
                end
            elseif attempts < 120 then
                attempts=attempts+1
                return false
            else
                -- Missing fields stay absent until a lifecycle/preset event.
                -- Resource changes must not restart readiness retries.
                absent[name]=true
                if D.debugLogging then D.event("missing","panel=%s; retries exhausted",name) end
            end
        else
            hud, world, panels = nil, nil, {}
            hudAddress=nil
        end
        cursor=cursor+1
        return false
    end
    cursor=0
    if dirty or statsPending or markersReady() or healthReady() then return false end
    attempts=0
    worker=false
    armExpiry()
    return true -- the panel worker stops; no recurring resource worker remains
end
step=D.wrap("worker",step)
-- UE4SS repeating timers ignore return values. Chain one-shots explicitly.
local function repeatUntilDone(delay,fn)
    local function tick()
        if not fn() then ExecuteInGameThreadWithDelay(delay,tick) end
    end
    ExecuteInGameThreadWithDelay(delay,tick)
end
wake = function(statsOnly)
    if not statsOnly then
        if firstFailedStatHook then
            hookIndex=firstFailedStatHook
            firstFailedStatHook=nil
            statHookFailures=false
            statsRefresh=true
        end
        fullPending=true
        absent={}
        settingsPending,settingsAttempts=true,0
    end
    if statsOnly~="marker" and statsOnly~="settings" and statsOnly~="resource" and statsOnly~="enemyHealth" then dirty=true end
    if worker then if D.debugLogging then D.count("workerCoalesced") end; return end
    worker=true
    if D.debugLogging then D.count("workerStarts") end
    attempts=0
    repeatUntilDone(16, function()
        local success, stop = pcall(function()
            if not valid(frameClock) then
                frameClock=StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
                if not valid(frameClock) then
                    worker=false
                    print("[Quiet Dawn HUD] Frame clock unavailable; waiting for a lifecycle event.")
                    return true
                end
            end
            local frame=frameClock:GetFrameCount()
            if frame == lastFrame then return false end
            lastFrame=frame
            return step()
        end)
        if not success then
            worker=false
            cursor=0
            print("[Quiet Dawn HUD] Update failed: "..tostring(stop))
            return true
        end
        return stop
    end)
end
local subscribed = pcall(NotifyOnNewObject, ROOT, function(object)
    candidate=object -- construction is not readiness: defer all object reads
    wake()
end)
if not subscribed then
    print("[Quiet Dawn HUD] HUD lifecycle notification unavailable; disabled.")
    return
end
local markerSubscribed=pcall(NotifyOnNewObject, MARKER, function(object)
    markerSeen=true
    markerHookAttempts=0
    queueMarker(object)
end)
if not markerSubscribed then
    print("[Quiet Dawn HUD] Marker lifecycle notification unavailable; marker left to the game.")
end
for _,spec in ipairs(healthTypes) do
    local subscribedHealth=pcall(NotifyOnNewObject,spec.path,function(object)
        if spec.failedEvent then
            spec.eventIndex=spec.failedEvent;spec.failedEvent=nil;spec.hookAttempts=0
        end
        queueHealth(object,spec)
    end)
    if not subscribedHealth then print("[Quiet Dawn HUD] Enemy health notification unavailable: "..spec.path) end
end
-- At most one outstanding hide deadline. It reads cached percentages and the
-- game clock only. A pause/extended hold reschedules its remaining delay; once
-- settled or below threshold there is no timer and no resource polling.
armExpiry = function()
    local now=valid(frameClock) and valid(controller) and frameClock:GetGameTimeInSeconds(controller) or nil
    local eligible=now and stateReady and previousHealth and previousStamina
        and previousHealth>=config.healthThreshold and previousStamina>=config.staminaThreshold
    local remaining=eligible and math.max(healthUntil,staminaUntil)-now or 0
    if expiryPending then
        local sameOwner=expiryHUD==hudAddress and expiryController==controllerAddress and expiryPawn==lastPawnAddress
        if remaining>0 and sameOwner and expiryDue<=now+remaining then return end
        CancelDelayedAction(expiryHandle)
        expiryPending,expiryHandle=false,nil
    end
    if remaining<=0 then return end
    expiryPending=true
    expiryDue=now+remaining
    local ownedHUD,ownedController,ownedPawn=hudAddress,controllerAddress,lastPawnAddress
    expiryHUD,expiryController,expiryPawn=ownedHUD,ownedController,ownedPawn
    expiryHandle=ExecuteInGameThreadWithDelay(math.max(16,math.ceil(remaining*1000)),function()
        expiryPending,expiryHandle=false,nil
        if ownedHUD~=hudAddress or ownedController~=controllerAddress or ownedPawn~=lastPawnAddress then
            armExpiry()
            return
        end
        if not valid(hud) or not valid(controller) or not valid(frameClock)
            or not sameObject(hud:GetWorld(),world) or not sameObject(hud:GetOwningPlayer(),controller) then return end
        if not stateReady or not previousHealth or not previousStamina then return end
        if previousHealth<config.healthThreshold or previousStamina<config.staminaThreshold then return end
        local remaining=math.max(healthUntil,staminaUntil)-frameClock:GetGameTimeInSeconds(controller)
        if remaining>0 then armExpiry();return end
        if desired~=0 then desired=0;wake(true) end
    end)
end
wake()
