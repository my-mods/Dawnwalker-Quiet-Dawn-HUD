@echo off
setlocal
set "QUIET_DAWN_SCRIPT=%~f0"
powershell.exe -NoLogo -NoProfile -Command "$source=[IO.File]::ReadAllText($env:QUIET_DAWN_SCRIPT); & ([scriptblock]::Create(($source -split '(?m)^# POWERSHELL START\r?$',2)[1]))"
set "result=%errorlevel%"
if /i not "%~1"=="--no-pause" pause
exit /b %result%
# POWERSHELL START
$ErrorActionPreference = 'Stop'
$temporary = $null
try {
    if (Get-Process -Name Dawnwalker,Dawnwalker-Win64-Shipping -ErrorAction SilentlyContinue) {
        throw 'Close Dawnwalker before changing UE4SS settings.'
    }
    $scriptDirectory = [IO.Path]::GetDirectoryName($env:QUIET_DAWN_SCRIPT)
    $runtime = $null
    foreach ($directory in @($scriptDirectory, [IO.Path]::GetFullPath((Join-Path $scriptDirectory '..\..')))) {
        if ([IO.File]::Exists((Join-Path $directory 'UE4SS.dll'))) { $runtime = $directory; break }
    }
    if (!$runtime) { throw 'Run this script from ue4ss or ue4ss\Mods\QuietDawnHUD, with UE4SS.dll installed.' }
    $target = Join-Path $runtime 'UE4SS-settings.ini'
    $existing = [IO.File]::Exists($target)
    $source = $target
    if (!$existing) {
        $source = Join-Path $runtime 'profiles\profile_perf.ini'
        if (![IO.File]::Exists($source)) {
            throw 'No UE4SS-settings.ini or Framecore profiles\profile_perf.ini found. Restore your loader configuration, then run this script again.'
        }
    }
    $bytes = [IO.File]::ReadAllBytes($source)
    $skip = 0
    # Preserve every existing byte outside the edited setting, including ANSI/UTF-8 comments.
    $encoding = [Text.Encoding]::GetEncoding(28591)
    if ($bytes.Length -ge 4 -and (($bytes[0] -eq 255 -and $bytes[1] -eq 254 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) -or ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 254 -and $bytes[3] -eq 255))) {
        throw 'UTF-32 configuration is unsupported; no changes made.'
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { $skip = 3 }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) { $encoding = [Text.Encoding]::Unicode; $skip = 2 }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255) { $encoding = [Text.Encoding]::BigEndianUnicode; $skip = 2 }
    $text = $encoding.GetString($bytes, $skip, $bytes.Length - $skip)
    $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $headers = [regex]::Matches($text, '(?m)^[\t ]*\[([^\]\r\n]+)\][\t ]*(?:[;#][^\r\n]*)?\r?$')
    $sections = @($headers | Where-Object { $_.Groups[1].Value.Trim() -ieq 'Hooks' })
    if ($sections.Count -gt 1) { throw 'Duplicate [Hooks] sections found. Resolve the duplicate before running this script; no changes made.' }
    if ($sections.Count -eq 0) {
        $separator = if ($text.Length -gt 0 -and !$text.EndsWith("`n")) { $newline } else { '' }
        $updated = $text + $separator + '[Hooks]' + $newline + 'HookProcessLocalScriptFunction = 1' + $newline
    } else {
        $start = $sections[0].Index + $sections[0].Length
        $end = $text.Length
        foreach ($header in $headers) { if ($header.Index -gt $start) { $end = $header.Index; break } }
        $body = $text.Substring($start, $end - $start)
        $pattern = '(?im)^([\t ]*HookProcessLocalScriptFunction[\t ]*=[\t ]*)([^\s;#\r\n]*)([\t ]*(?:[;#][^\r\n]*)?\r?)$'
        $keys = [regex]::Matches($body, $pattern)
        if ($keys.Count -gt 1) { throw 'Duplicate HookProcessLocalScriptFunction settings found; no changes made.' }
        if ($keys.Count -eq 1) {
            $key = $keys[0]
            $body = $body.Substring(0, $key.Index) + $key.Groups[1].Value + '1' + $key.Groups[3].Value + $body.Substring($key.Index + $key.Length)
        } else {
            # Do not silently append a second key if the existing line is malformed.
            if ($body -match '(?im)^[\t ]*HookProcessLocalScriptFunction\b') { throw 'Malformed hook setting found; no changes made.' }
            $separator = if (!$body.EndsWith("`n")) { $newline } else { '' }
            $body += $separator + 'HookProcessLocalScriptFunction = 1' + $newline
        }
        $updated = $text.Substring(0, $start) + $body + $text.Substring($end)
    }
    if ($existing -and $updated -ceq $text) { Write-Host 'Blueprint hooks are already enabled. No changes needed.'; exit 0 }
    [byte[]]$result = $encoding.GetBytes($updated)
    if ($skip -gt 0) { $result = [byte[]]($bytes[0..($skip-1)] + $result) }
    $temporary = Join-Path $runtime ('QuietDawn-settings-' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllBytes($temporary, $result)
    if ($existing) {
        # Replace the directory entry, rather than writing through a Vortex hardlink.
        $backup = $target + '.QuietDawn-' + [guid]::NewGuid().ToString('N') + '.bak'
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($target)) -cne [Convert]::ToBase64String($bytes)) { throw 'The INI changed while this script was running. Run it again.' }
        [IO.File]::Replace($temporary, $target, $backup)
        Write-Host ('Original INI backed up to: ' + $backup)
    } else {
        [IO.File]::Move($temporary, $target)
        Write-Host 'Created UE4SS-settings.ini from the installed Framecore Performance template.'
    }
    $temporary = $null
    Write-Host 'Enabled HookProcessLocalScriptFunction = 1. Other settings were preserved.'
    Write-Host 'Restart the game. Rerun this script after a profile switch or configuration replacement.'
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
}
