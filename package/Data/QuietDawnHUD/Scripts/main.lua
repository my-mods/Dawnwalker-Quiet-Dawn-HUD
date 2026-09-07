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
if type(LoopInGameThreadWithDelay) ~= "function" then
    print("[Quiet Dawn HUD] Requires delayed game-thread callbacks; disabled.")
    return
end

local ROOT = "/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C"
local hud, candidate, controller, world
local worker, dirty, monitoring, stateReady = false, false, false, false
local lastPawn, lastCombat, previousHealth, previousStamina
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
local function unwrap(param)
    if param == nil then return nil end
    return param:get()
end
-- The game uses one widget for neutral lock-on and combat cues. Never hide it
-- during a non-neutral/unknown icon state, and never change difficulty settings.
local MARKER = "/Game/_Dawnwalker/UI/_Unified/Combat/WBP_CombatTargetIndicator.WBP_CombatTargetIndicator_C"
local markerSpecs = {"Construct", "OnObservedStubIconTypeChanged",
    "NotifyIndicatorCleared", "EnableHardLock", "RefreshIndicatorsVisibility"}
local markerHookIndex, markerHookAttempts, markerSeen = 1, 0, false
local markerQueue, markerPending, markerFirst, markerLast = {}, {}, 1, 0
local markerCache, markerSlots, markerCount, markerPrune = {}, {}, 0, 1
local markerCacheWorld, markerCacheController, markerTurn
local markerWork = 0
local function queueMarker(object, retries)
    if object == nil then return end
    -- Capture only the wrapper here: construction may not be on the game
    -- thread. Pointer/property reads happen in the shared game-thread worker.
    local pending=markerPending[object]
    if pending then pending.object=object; return end
    -- Excess objects remain under game control. No unbounded queues or scans.
    if markerLast-markerFirst+1 >= 64 then return end
    local job={object=object, retries=retries or 0}
    markerLast=markerLast+1
    markerQueue[markerLast]=job
    markerPending[object]=job
    if wake then wake("marker") end
end
local function markerEvent(context)
    queueMarker(unwrap(context))
end
local function markerHooksStep()
    local path=MARKER..":"..markerSpecs[markerHookIndex]
    local success, pre, post=pcall(RegisterHook, path, markerEvent)
    markerHookAttempts=markerHookAttempts+1
    if success and type(pre)=="number" and type(post)=="number" then
        hooks[path]={pre,post}
        markerHookIndex=markerHookIndex+1
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
    if object:GetWorld()~=world or object:GetOwningPlayer()~=controller then return end
    if controller:GetWorld()~=world then return end
    if markerCacheWorld~=world or markerCacheController~=controller then
        markerCache,markerSlots,markerCount,markerPrune={}, {}, 0, 1
        markerCacheWorld,markerCacheController=world,controller
    end
    local entry=markerCache[job.address]
    if not entry and markerCount>=64 then
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
    local readable,icon=pcall(function() return tonumber(object["Currently Displayed Icon Type"]) end)
    if not readable or icon==nil then
        if entry and entry.hidden then
            object:SetRenderOpacity(entry.original)
            entry.hidden=false
        end
        if job.retries<8 then queueMarker(object,job.retries+1) end
        return
    end
    local current=object:GetRenderOpacity()
    if not entry then
        entry={object=object,address=job.address,original=current}
        markerCache[job.address]=entry
        -- Fixed-size plain-Lua slot selection; no object reads or traversal.
        for slot=1,64 do if not markerSlots[slot] then markerSlots[slot]=entry;break end end
        markerCount=markerCount+1
    end
    if icon==0 then
        if not entry.hidden or current~=0 then entry.original=current end
        if current~=0 then object:SetRenderOpacity(0) end
        entry.hidden=true
    elseif entry.hidden then
        if current~=entry.original then object:SetRenderOpacity(entry.original) end
        entry.hidden=false
    else
        entry.original=current -- retain the game's opacity while a cue is active
    end
end
local function signal() wake() end
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
            wake()
        end
    end, true},
    {ROOT..":Construct", capture},
    {ROOT..":BP_OnActivated", capture},
    {ROOT..":On Coen Form Changed", capture},
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
    end
    return hookIndex > #specs
end
local function accept(object)
    if not valid(object) then return false end
    local pc = object:GetOwningPlayer()
    if not valid(pc) or not pc:IsLocalController() then return false end
    local objectWorld = object:GetWorld()
    if not valid(objectWorld) or objectWorld ~= pc:GetWorld() then return false end
    if valid(controller) and controller ~= pc then return false end
    if object ~= hud or objectWorld ~= world then
        hud, world, panels, absent = object, objectWorld, {}, {}
        lastPawn, lastCombat, previousHealth, previousStamina = nil, nil, nil, nil
        healthUntil, staminaUntil = 0, 0
    end
    controller = pc
    return true
end
local function snapshot()
    if not valid(hud) or not valid(controller) or not valid(world) then return nil end
    if hud:GetWorld() ~= world or controller:GetWorld() ~= world
        or hud:GetOwningPlayer() ~= controller then return nil end
    local pawn = controller.Pawn
    if not valid(pawn) or pawn:GetWorld() ~= world then return nil end
    local combat = pawn.CombatComponent
    if not valid(combat) then return nil end
    -- No component search, arrays, or borrowed attribute structures.
    local health = tonumber(combat:GetHealthPercentage())
    local stamina = tonumber(combat:GetStaminaPercentage())
    if not health or not stamina or health ~= health or stamina ~= stamina
        or health < 0 or stamina < 0 or health > 1 or stamina > 1 then return nil end
    local now = frameClock:GetGameTimeInSeconds(controller)
    if lastPawn ~= pawn or lastCombat ~= combat then
        previousHealth, previousStamina = nil, nil
        healthUntil, staminaUntil = 0, 0
        lastPawn, lastCombat = pawn, combat
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
    return needed and 1 or 0
end
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
    if markerFirst<=markerLast and (markerTurn or (cursor==0 and not dirty)) then
        local success, reason=pcall(markerStep)
        markerWork=markerWork+1
        if not success then print("[Quiet Dawn HUD] Marker update skipped: "..tostring(reason)) end
        return false
    end
    if cursor==0 and not dirty then
        if markerFirst<=markerLast then return false end
        worker=false
        if stateReady then startMonitor() end
        return true
    end
    if cursor == 0 then
        dirty = false
        if candidate then
            if accept(candidate) then candidate=nil else
                attempts=attempts+1
                if attempts < 120 then return false end
                candidate=nil
            end
        end
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
        fullJob, fullPending = fullPending, false
        jobNames = fullJob and names or statNames
        cursor=1
        return false
    end
    if cursor <= #jobNames then
        -- Revalidate ownership inside every deferred operation, including a still
        -- valid HUD left over from the previous world.
        if valid(hud) and valid(controller) and hud:GetWorld() == world
            and controller:GetWorld() == world and hud:GetOwningPlayer() == controller then
            local name = jobNames[cursor]
            if absent[name] then cursor=cursor+1; return false end
            local object = hud[name]
            if valid(object) then
                local current = object:GetRenderOpacity()
                local entry = panels[name]
                if not entry or entry.object ~= object then
                    entry = {object=object, original=current}
                    panels[name]=entry
                end
                local isStats = name == "HumanStats" or name == "VampireStats"
                local target = isStats and desired == 1 and entry.original or 0
                if current ~= target then object:SetRenderOpacity(target) end
            elseif attempts < 120 then
                attempts=attempts+1
                return false
            else
                -- Missing fields stay absent until a lifecycle/preset event.
                -- Resource changes must not restart readiness retries.
                absent[name]=true
            end
        else
            hud, world, panels = nil, nil, {}
        end
        cursor=cursor+1
        return false
    end
    cursor=0
    if dirty or markerFirst<=markerLast then return false end
    attempts=0
    worker=false
    if stateReady then startMonitor() end
    return true -- the panel worker stops; only the bounded stat sampler remains
end
wake = function(statsOnly)
    if not statsOnly then
        fullPending=true
        absent={}
    end
    if statsOnly~="marker" then dirty=true end
    if worker then return end
    worker=true
    attempts=0
    LoopInGameThreadWithDelay(16, function()
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
    local ownedHUD, ownedController = hud, controller
    LoopInGameThreadWithDelay(100, function()
        -- At low frame rates both timers may expire on every frame. Let a
        -- pending panel job finish rather than letting the sampler starve it.
        if worker then return false end
        if hud ~= ownedHUD or controller ~= ownedController then
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
