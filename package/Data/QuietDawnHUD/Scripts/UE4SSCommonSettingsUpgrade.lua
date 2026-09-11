-- MIT. Explicit, verified addition of newly introduced numeric settings.
local M = {}
function M.ensure(store, path, schema, defaults, tag)
    assert(tag:match('^[%w-]+$'), 'Invalid settings upgrade tag')
    local original, err = store.read(path)
    if not original then return nil, err end
    local text, values = original
    for _ = 1, #schema + 1 do
        values, err = store.parse(text, schema)
        if values then break end
        local key = err and err:match('^Missing setting: (.+)$')
        local value = key and defaults[key]
        if value == nil then return nil, err end
        local position
        for _, line, nextPosition in text:gmatch('()([^\n]*\n)()') do
            local clean = line:gsub('^\239\187\191',''):gsub('[;#].*$',''):match('^%s*(.-)%s*$')
            if clean == '[Settings]' then position = nextPosition; break end
        end
        if not position then return nil, 'Settings section unavailable for upgrade' end
        local newline = text:find('\r\n',1,true) and '\r\n' or '\n'
        text = text:sub(1,position-1)..key..' = '..tostring(value)..newline..text:sub(position)
        if #text > 1048576 then return nil, 'Upgraded settings exceed 1 MiB' end
    end
    if not values then return nil, err end
    if text == original then return values end
    local temporary, backup = path..'.upgrade', path..'.before-'..tag
    local oldBackup, backupError, backupCode = store.read(backup)
    if oldBackup or backupCode ~= 2 then return nil, 'Preserve/recover '..backup..': '..tostring(backupError or 'already exists') end
    local created, createError = store.create(temporary, text)
    if not created then return nil, 'Cannot prepare settings upgrade: '..tostring(createError) end
    if store.read(temporary) ~= text or store.read(path) ~= original then
        os.remove(temporary)
        return nil, 'Settings changed during upgrade; original retained'
    end
    local moved, moveError = os.rename(path, backup)
    if not moved then os.remove(temporary); return nil, 'Cannot back up settings: '..tostring(moveError) end
    local function recover(reason)
        local current, _, code = store.read(path)
        if not current and code == 2 then os.rename(backup, path) end
        return nil, reason..'; preserve '..temporary..' and '..backup..' for recovery'
    end
    if store.read(backup) ~= original then return recover('Settings changed before backup') end
    local installed, installError = os.rename(temporary, path)
    if not installed then return recover('Cannot finish settings upgrade: '..tostring(installError)) end
    if store.read(path) ~= text then return recover('Cannot verify upgraded settings') end
    return values
end
return M
