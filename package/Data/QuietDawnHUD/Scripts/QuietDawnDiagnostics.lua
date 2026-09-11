-- MIT License. Personal diagnostics are opt-in and read once at startup.
local D={debugLogging=false}
local cfg=require('MenuSettings')
local settings={debuglogging=cfg.debugLogging,summaryseconds=cfg.SummarySeconds or 10,slowcallbackms=cfg.SlowCallbackMs or 2,maxeventspersecond=cfg.MaxEventsPerSecond or 6}
D.debugLogging=settings.debuglogging
function D.count() end
function D.event() end
function D.vitals() end
function D.wrap(_,fn) return fn end
if not D.debugLogging then return D end

local summarySeconds=math.max(5,math.min(120,settings.summaryseconds))
local slowMs=math.max(0.1,math.min(1000,settings.slowcallbackms))
local eventLimit=math.floor(math.max(1,math.min(20,settings.maxeventspersecond)))
local clock=os.clock
local windowStart,lastSummary=clock(),clock()
local events,dropped=0,0
local counts,timings={},{}
local depth=0
local lastVisible,lastGameTime,lastHealth,lastStamina,gapMax
local function output(message) print("[Quiet Dawn HUD][DEBUG] "..message) end
function D.count(key,amount) counts[key]=(counts[key] or 0)+(amount or 1) end
function D.event(kind,format,...)
    local now=clock()
    if now-windowStart>=1 then windowStart,events=now,0 end
    if events>=eventLimit then dropped=dropped+1;return end
    events=events+1
    output(kind.." "..string.format(format,...))
end
function D.vitals(health,stamina,visible,gameTime,healthUntil,staminaUntil)
    if lastGameTime and gameTime>=lastGameTime then
        gapMax=math.max(gapMax or 0,(gameTime-lastGameTime)*1000)
    end
    lastGameTime,lastHealth,lastStamina=gameTime,health,stamina
    if lastVisible~=visible then
        lastVisible=visible
        D.event("vitals","wanted=%s health=%.4f stamina=%.4f gameTime=%.3f healthHold=%.3f staminaHold=%.3f",tostring(visible),health,stamina,gameTime,math.max(0,(healthUntil or 0)-gameTime),math.max(0,(staminaUntil or 0)-gameTime))
    end
end
local function summary(now)
    if now-lastSummary<summarySeconds then return end
    local parts={string.format("summary interval=%.3fs suppressed=%d sampleGapMaxMs=%.3f",now-lastSummary,dropped,gapMax or 0)}
    for _,name in ipairs({"worker","sample","marker","hook"}) do
        local t=timings[name]
        if t then parts[#parts+1]=string.format("%s calls=%d avgMs=%.3f maxMs=%.3f slow=%d",name,t.n,t.total/t.n,t.max,t.slow) end
    end
    local keys={};for name in pairs(counts) do keys[#keys+1]=name end;table.sort(keys)
    for _,name in ipairs(keys) do parts[#parts+1]=name.."="..counts[name] end
    if lastHealth then parts[#parts+1]=string.format("health=%.4f stamina=%.4f wanted=%s",lastHealth,lastStamina,tostring(lastVisible)) end
    output(table.concat(parts," | "))
    lastSummary=now;timings={};counts={};dropped=0;gapMax=0
end
-- Used only for zero-argument native work phases, preserving their return/error.
-- Disabled mode returns the original function, with no timing/formatting cost.
function D.wrap(name,fn)
    return function()
        depth=depth+1
        local started=clock()
        local success,result=pcall(fn)
        local now=clock();local ms=math.max(0,(now-started)*1000)
        local t=timings[name]
        if not t then t={n=0,total=0,max=0,slow=0};timings[name]=t end
        t.n=t.n+1;t.total=t.total+ms;t.max=math.max(t.max,ms)
        if ms>=slowMs then t.slow=t.slow+1;D.event("slow","phase=%s elapsedMs=%.3f",name,ms) end
        if not success then D.event("error","phase=%s error=%s",name,tostring(result)) end
        -- Summarize at outer phases, avoiding resets partway through a worker.
        depth=depth-1
        if depth==0 then summary(now) end
        if not success then error(result,0) end
        return result
    end
end
output(string.format("enabled build=diagnostics-1 ini=%s summarySeconds=%.1f slowMs=%.2f eventLimit=%d clock=os.clock; phase timings overlap and are not engine frame times",D.path or "unavailable",summarySeconds,slowMs,eventLimit))
return D
