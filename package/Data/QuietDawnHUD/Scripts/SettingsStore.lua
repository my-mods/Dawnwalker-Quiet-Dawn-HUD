-- Numeric settings storage for Mod Setting Menu. MIT License.
-- No timers or game-object access. settings.ini is generated, never shipped.
local M = {}
local function read(path)
    local f, err, code = io.open(path, 'rb')
    if not f then return nil, err, code end
    local text, e = f:read(1048577); f:close()
    if not text or #text > 1048576 then return nil, e or 'Settings exceed 1 MiB', -1 end
    return text
end
M.read = read
local function valid(s, n)
    if type(n) ~= 'number' or n ~= n or math.abs(n) == math.huge then return false end
    if s.values then
        for _, v in ipairs(s.values) do if n == v then return true end end
        return false
    end
    return n >= s.min and n <= s.max and (not s.integer or n % 1 == 0)
end
function M.parse(text, schema)
    local result, seen, section = {}, {}, ''
    local byKey = {}; for _, s in ipairs(schema) do byKey[s.key] = s end
    for line in (text:gsub('^\239\187\191', '') .. '\n'):gmatch('(.-)\r?\n') do
        line = line:gsub('[;#].*$', ''):match('^%s*(.-)%s*$')
        local header = line:match('^%[([^%]]+)%]$')
        if header then section = header
        elseif line ~= '' then
            local key, value = line:match('^([%w_]+)%s*=%s*(.-)%s*$')
            if not key then return nil, 'Malformed settings line' end
            if section == 'Settings' then
                if seen[key] then return nil, 'Duplicate setting: ' .. key end
                seen[key] = true
                if byKey[key] then
                    local n = tonumber(value)
                    if not valid(byKey[key], n) then return nil, 'Invalid setting: ' .. key end
                    result[key] = n
                end
            end
        end
    end
    for _, s in ipairs(schema) do
        if result[s.key] == nil then return nil, 'Missing setting: ' .. s.key end
    end
    return result
end
local function temporary(path, text)
    if package.config:sub(1, 1) ~= '\\' then return nil, 'Windows is required' end
    local ok, token = pcall(os.tmpname)
    if not ok then return nil, token end
    os.remove(token)
    local name = path .. '.' .. assert(token:match('([^/\\]+)$')) .. '.tmp'
    local f, err = io.open(name, 'a+b')
    if not f then return nil, err end
    if f:seek('end') ~= 0 then f:close(); return nil, 'Temporary file occupied' end
    local written, we = f:write(text); local closed, ce = f:close()
    if not written or not closed then os.remove(name); return nil, we or ce end
    return name
end
function M.create(path, text)
    local tmp, err = temporary(path, text); if not tmp then return nil, err end
    local ok, e = os.rename(tmp, path)
    if not ok then os.remove(tmp); return nil, e end
    return true
end
function M.path(directory)
    return directory:gsub('[^/\\]+[/\\]$', '') .. 'settings.ini'
end
-- Only sources captured by this successful first-run migration are eligible.
local function cleanupLegacy(sources, settingsPath)
    for _, source in ipairs(sources or {}) do
        local current, err, code = read(source.path)
        if current ~= nil then
            if source.path == settingsPath or current ~= source.text then
                print('[Mod Settings] Legacy settings retained because the file changed: ' .. source.path)
            elseif source.preservePath and read(source.preservePath) ~= source.text then
                print('[Mod Settings] Legacy settings retained because the advanced snapshot differs: ' .. source.path)
            else
                local ok, e = os.remove(source.path)
                if not ok then print('[Mod Settings] Migrated settings are saved; could not remove legacy file ' .. source.path .. ': ' .. tostring(e)) end
            end
        elseif code ~= 2 then
            print('[Mod Settings] Migrated settings are saved; could not verify legacy file ' .. source.path .. ': ' .. tostring(err))
        end
    end
end
function M.load(directory, schema, seed)
    local path = M.path(directory)
    local migrated, created
    local text, err, code = read(path)
    if not text then
        if code ~= 2 then return nil, err, path end
        local backup, be, bc = read(path .. '.backup')
        if backup or bc ~= 2 then return nil, 'Recover settings.ini.backup before starting: ' .. tostring(be or ''), path end
        local values, e, sources = seed()
        migrated = sources
        if not values then return nil, e, path end
        local lines = {'; Managed through Main Menu > Mod Settings. Apply, then restart.',
            '; Generated preferences: back up before uninstalling. Legacy files are not synchronized.', '[Settings]'}
        for _, s in ipairs(schema) do
            local n = values[s.key]
            if n == nil then n = s.default end
            if not valid(s, n) then return nil, 'Cannot migrate setting: ' .. s.key, path end
            lines[#lines+1] = s.key .. ' = ' .. string.format('%.17g', n)
        end
        text = table.concat(lines, '\n') .. '\n'
        local ok, ce = M.create(path, text)
        if not ok then
            local existing = read(path)
            if not existing then return nil, ce, path end
            text = existing -- Concurrent creator won; never overwrite it or delete its legacy inputs.
        else
            created = true
            local saved, se = read(path)
            if saved ~= text then return nil, se or 'Cannot verify saved migration; legacy files retained', path end
        end
    end
    local values, e = M.parse(text, schema)
    if values and created then cleanupLegacy(migrated, path) end
    return values, e, path
end
return M
