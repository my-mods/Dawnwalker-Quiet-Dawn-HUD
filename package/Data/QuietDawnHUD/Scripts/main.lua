local D = require("QuietDawnDiagnostics")
-- Quiet Dawn HUD | MIT License
-- Event-driven panel opacity. No widget-tree walks, global object searches,
-- class-default edits, animation hooks, or Lua coroutines.
-- Two cached player-stat reads every 100 ms cover changes without reliable UI events.
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
if type(ExecuteInGameThreadWithDelay) ~= "function" then
    print("[Quiet Dawn HUD] Requires delayed game-thread callbacks; disabled.")
    return
end

if D.debugLogging then D.event("config","healthThreshold=%.3f staminaThreshold=%.3f healthHold=%.3fs staminaHold=%.3fs panels=%d",config.healthThreshold,config.staminaThreshold,config.healthHoldSeconds,config.staminaHoldSeconds,#names) end
local ROOT = "/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C"
local hud, candidate, controller, world
local hudAddress, controllerAddress
local worker, dirty, monitoring, stateReady = false, false, false, false
local lastPawnAddress, lastCombatAddress, previousHealth, previousStamina
local healthUntil, staminaUntil = 0, 0
local panels = {}
local absent, jobNames, fullPending, fullJob = {}, names, false, true
local cursor, desired, attempts = 0, 1, 0
local hooks, hookIndex = {}, 1
local warned = false
local frameClock, lastFrame
local wake, startMonitor
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
-- The game shares this widget between neutral lock-on, directions and cues.
-- Hide neutral only when directions are disabled; never change game settings.
local MARKER = "/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatTargetIndicator.WBP_CombatTargetIndicator_C"
local markerSpecs = {"Construct", "OnObservedStubIconTypeChanged",
    "NotifyIndicatorCleared", "EnableHardLock", "RefreshIndicatorsVisibility",
    "ToggleShowOnlyMiddleIndicator"}
local markerHookIndex, markerHookAttempts, markerSeen = 1, 0, false
local markerQueue, markerPending, markerFirst, markerLast = {}, {}, 1, 0
local markerCache, markerSlots, markerCount, markerPrune = {}, {}, 0, 1
local markerCacheWorld, markerCacheController, markerTurn
local markerWork = 0
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
    -- non-directional display paths. 0=Defending (neutral); 1..13 are cues.
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
    if icon==0 and not directionsEnabled then
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
local function signal() if D.debugLogging then D.count("presetEvents") end;wake() end
local function capture(context)
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
local function noop() end
local function registerOne()
    if hookIndex > #specs then return true end
    local spec = specs[hookIndex]
    local success, pre, post
    if spec[3] then
        success, pre, post = pcall(RegisterHook, spec[1], noop, spec[2])
    else
        success, pre, post = pcall(RegisterHook, spec[1], spec[2])
    end
    if success and type(pre) == "number" and type(post) == "number" then
        hooks[spec[1]] = {pre, post}
        hookIndex = hookIndex + 1
        if D.debugLogging then D.event("hook","registered=%s",spec[1]) end
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
        if D.debugLogging then D.event("lifecycle","HUD/world changed; cached state reset") end
    end
    controller = pc
    hudAddress, controllerAddress = object:GetAddress(), pc:GetAddress()
    return true
end
local function snapshot()
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
    if previousHealth and health < previousHealth - 0.000001 then
        healthUntil = now + config.healthHoldSeconds
    end
    if previousStamina and stamina < previousStamina - 0.000001 then
        staminaUntil = now + config.staminaHoldSeconds
    end
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
        if hookIndex > 3 and candidate == nil then
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
    -- During a large marker burst the shared worker also services vitals.
    -- Six 16-ms marker slices plus this sample slice bound that extra cadence.
    if markerWork>=6 and stateReady and cursor==0 and not dirty then
        markerWork=0
        local success,value=pcall(snapshot)
        if not success or value==nil then
            stateReady=false
            desired=1
            wake(true)
        elseif value~=desired then
            desired=value
            wake(true)
        end
        return false
    end
    markerTurn=not markerTurn
    if markersReady() and (markerTurn or (cursor==0 and not dirty)) then
        local success, reason=pcall(markerStep)
        markerWork=markerWork+1
        if not success then print("[Quiet Dawn HUD] Marker update skipped: "..tostring(reason)) end
        return false
    end
    if cursor==0 and not dirty then
        if markersReady() then return false end
        worker=false
        if stateReady then startMonitor() end
        return true
    end
    if cursor == 0 then
        dirty = false
        if candidate then
            local accepted, reason=accept(candidate)
            if accepted then
                candidate=nil
                dirty=true
                return false -- ownership acceptance and stat sampling use separate frames
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
        -- Stat-only wakes already have a fresh sampler result. Do not sample
        -- twice or revisit unrelated HUD panels on every show/hide transition.
        if fullJob then
            markerWork=0
            if #statNames > 0 then
                local success, value = pcall(snapshot)
                stateReady = success and value ~= nil
                desired = stateReady and value or 1
            else
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
    if dirty or markersReady() then return false end
    attempts=0
    worker=false
    if stateReady then startMonitor() end
    return true -- the panel worker stops; only the bounded stat sampler remains
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
        fullPending=true
        absent={}
        settingsPending,settingsAttempts=true,0
    end
    if statsOnly~="marker" and statsOnly~="settings" then dirty=true end
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
-- One sampler, only after successful ownership/stat initialization. It reads two
-- scalar values every 100 ms. It never searches for objects or retries readiness.
-- Visibility changes wake the panel worker; unchanged values cause no widget work.
startMonitor = function()
    if monitoring then return end
    monitoring=true
    local ownedHUD, ownedController = hudAddress, controllerAddress
    repeatUntilDone(100, function()
        -- At low frame rates both timers may expire on every frame. Let a
        -- pending panel job finish rather than letting the sampler starve it.
        if worker then if D.debugLogging then D.count("sampleDeferred") end; return false end
        -- These are captured native identities; snapshot revalidates live owners.
        if hudAddress~=ownedHUD or controllerAddress~=ownedController then
            monitoring=false
            wake()
            return true
        end
        local success, value = pcall(function()
            if not valid(frameClock) then return nil end
            local frame=frameClock:GetFrameCount()
            if frame == lastFrame then return "deferred" end
            lastFrame=frame
            return snapshot()
        end)
        if value == "deferred" then return false end
        if not success or value == nil then
            monitoring=false
            stateReady=false
            if D.debugLogging then D.event("lifecycle","sampler stopped: player/stat context unavailable") end
            desired=1 -- leave the stat panel available if reading it fails
            wake()
            return true
        end
        if desired ~= value then
            desired=value
            wake(true)
        end
        return false
    end)
end
wake()
