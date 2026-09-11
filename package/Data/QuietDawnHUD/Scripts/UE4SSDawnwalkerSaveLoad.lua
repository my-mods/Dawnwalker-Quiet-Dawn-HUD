-- MIT. Dawnwalker build 25232147: explicit save requests + loading-screen completion.
-- Importing this adapter does nothing. Native APIs are injected by start().
local M = {}
function M.start(api, session, file, report)
    local enabled = false
    local requested, loading, completed, initialized, pending = false, false, false, false, false
    local engine, gameplay
    local function valid(object) return object and object:IsValid() end
    local function unwrap(value)
        if type(value) == 'number' then return value end
        return value and value:get()
    end
    local function ready()
        if not valid(engine) then engine = api.FindFirstOf('Engine') end
        if not valid(gameplay) then gameplay = api.StaticFindObject('/Script/Engine.Default__GameplayStatics') end
        if not valid(engine) or not valid(gameplay) then return end
        local viewport = engine.GameViewport
        if not valid(viewport) then return end
        local world = viewport:GetWorld()
        if not valid(world) then return end
        local pawn = gameplay:GetPlayerPawn(world, 0)
        if not valid(pawn) or not pawn:IsLocallyControlled() then return end
        if not valid(pawn.CharDevAttributeSet) then return end
        return {pawn=pawn, world=world}
    end
    local function wake()
        if not enabled or pending or loading or not completed or (initialized and not requested) then return end
        pending = true
        api.ExecuteInGameThreadWithDelay(16, function()
            pending = false
            if loading or not completed or (initialized and not requested) then return end
            local ok, context = pcall(ready)
            if not ok then report('Save readiness failed: '..tostring(context)); return end
            if not context then return end -- later readiness event resumes; no retry timer
            initialized, requested, completed = true, false, false
            session.open(file, context)
        end)
    end
    local function request() if enabled then requested = true; completed = false end end
    api.RegisterHook('/Script/DogwoodUI.SaveWindowBase:RequestLoadSave', request, function() end)
    for _, path in ipairs({
        '/Script/Persistency.SaveSystemBlueprintFunctionLibrary:LoadLastSave',
        '/Script/Persistency.SaveSystemBlueprintFunctionLibrary:TryQuickload',
    }) do
        -- Both functions return bool (no input parameters). UE4SS exposes the
        -- original result as the second post-hook argument. Refused quickloads
        -- must not turn a subsequent fast travel into a settings reload.
        api.RegisterHook(path, function()
            if enabled then requested, completed = false, false end
        end, function(_, result)
            if not enabled then return end
            requested = unwrap(result) == true
            if requested then
                if loading then session.pause() end
                wake()
            end
        end)
    end
    api.RegisterHook('/Script/DogwoodCombat.CombatSubsystem:OnLoadingScreenStateChanged',
        function() end, function(_, state)
            if not enabled then return end
            local value = tonumber(unwrap(state))
            if value == 0 then
                if loading then completed = true end
                loading = false
                wake()
            elseif value and value >= 1 and value <= 4 then
                loading = true
                if requested then session.pause() end
            end
        end)
    api.RegisterHook('/Script/Engine.PlayerController:ClientRestart', function() end, wake)
    for _, path in ipairs({'/Script/Dawnwalker.DawnwalkerPlayerCharacter','/Script/DogwoodStats.CharDevAttributeSet'}) do
        api.NotifyOnNewObject(path, wake)
    end
    enabled = true
end
return M
