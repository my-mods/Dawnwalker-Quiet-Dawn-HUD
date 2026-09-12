-- MIT. Timer choices and a preserving upgrade from the former 0-60s range.
local M = {}
local keys = {healthHoldSeconds=true, staminaHoldSeconds=true,
    manualPeekSeconds=true, timeHoldSeconds=true, switchRevealSeconds=true}
function M.compatibleSchema(schema)
    local compatible = {}
    for _, row in ipairs(schema) do
        compatible[#compatible+1] = keys[row.key]
            and {key=row.key, default=row.default, min=0, max=60, integer=false} or row
    end
    return compatible
end
function M.normalize(values)
    for key in pairs(keys) do
        local value = values[key]
        -- Leave malformed values for the settings validator to reject.
        if type(value)=='number' and value==value and value>=0 and value<=60 then
            values[key] = math.min(10, math.floor(value*2+0.5)/2)
        end
    end
end
function M.ensure(store, path, schema)
    local original, err = store.read(path)
    if not original then return nil, err end
    local values
    values, err = store.parse(original, M.compatibleSchema(schema))
    if not values then return nil, err end
    M.normalize(values)
    local section = ''
    local text = original:gsub('([^\n]+)', function(line)
        local clean = line:gsub('^\239\187\191',''):gsub('[;#].*$',''):match('^%s*(.-)%s*$')
        local header = clean:match('^%[([^%]]+)%]$')
        if header then section=header end
        local key, raw = clean:match('^([%w_]+)%s*=%s*(.-)%s*$')
        if section=='Settings' and keys[key] and tonumber(raw)~=values[key] then
            return (line:gsub('^(%s*[%w_]+%s*=%s*)([^%s;#]+)', function(prefix)
                return prefix..tostring(values[key])
            end, 1))
        end
        return line
    end)
    values, err = store.parse(text, schema)
    if not values or text==original then return values, err end
    local temporary, backup = path..'.timers-upgrade', path..'.before-short-timers'
    local oldBackup, backupError, backupCode = store.read(backup)
    if oldBackup or backupCode~=2 then
        return nil, 'Preserve/recover '..backup..': '..tostring(backupError or 'already exists')
    end
    local created, createError = store.create(temporary, text)
    if not created then return nil, 'Cannot prepare timer upgrade: '..tostring(createError) end
    if store.read(temporary)~=text or store.read(path)~=original then
        os.remove(temporary)
        return nil, 'Settings changed during timer upgrade; original retained'
    end
    local moved, moveError = os.rename(path, backup)
    if not moved then os.remove(temporary); return nil, 'Cannot back up settings: '..tostring(moveError) end
    local function recover(reason)
        local current, _, code = store.read(path)
        if not current and code==2 then os.rename(backup, path) end
        return nil, reason..'; preserve '..temporary..' and '..backup..' for recovery'
    end
    if store.read(backup)~=original then return recover('Settings changed before backup') end
    local installed, installError = os.rename(temporary, path)
    if not installed then return recover('Cannot finish timer upgrade: '..tostring(installError)) end
    if store.read(path)~=text then return recover('Cannot verify timer upgrade') end
    return values
end
return M
