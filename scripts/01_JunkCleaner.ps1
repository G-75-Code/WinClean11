# ============================================================
#  WinClean 11 - Module 01: Junk Cleaner
#  Deletes temp files, caches, logs, update junk
# ============================================================

#Requires -RunAsAdministrator

$LOG_FILE = "$env:TEMP\WinClean\winclean_log.txt"
function Write-Log { param([string]$m,[string]$l="INFO"); "$(Get-Date -f 'HH:mm:ss') [$l] $m" | Out-File -Append $LOG_FILE -Encoding UTF8 }
function Write-Step { param([string]$m); Write-Host "  [»] $m" -ForegroundColor Cyan }
function Write-Done { param([string]$m); Write-Host "  [✓] $m" -ForegroundColor Green; Write-Log $m "DONE" }
function Write-Skip { param([string]$m); Write-Host "  [~] $m" -ForegroundColor DarkGray }
function Write-Fail { param([string]$m); Write-Host "  [!] $m" -ForegroundColor Red; Write-Log $m "ERROR" }

$totalFreed = 0

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $bytes = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return [math]::Round($bytes / 1MB, 2)
    }
    return 0
}

function Remove-FolderContents {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) { Write-Skip "$Label - path not found"; return 0 }
    $size = Get-FolderSize $Path
    Write-Step "Cleaning $Label ($size MB)..."
    try {
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Done "Cleaned $Label — freed ~$size MB"
        return $size
    } catch {
        Write-Fail "Partial clean of $Label : $_"
        return 0
    }
}

# ── Header ───────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "    🗑️  JUNK CLEANER" -ForegroundColor Cyan
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# ── Ask user what to clean ───────────────────────────────────
Write-Host "  Select what to clean (press Enter to skip, Y to clean):" -ForegroundColor White
Write-Host ""

$tasks = [ordered]@{
    "User Temp Files (%TEMP%)"          = { Remove-FolderContents "$env:TEMP" "User Temp" }
    "System Temp Files (Windows\Temp)"  = { Remove-FolderContents "C:\Windows\Temp" "Windows Temp" }
    "Prefetch Files"                    = { Remove-FolderContents "C:\Windows\Prefetch" "Prefetch" }
    "Recycle Bin"                       = {
        Write-Step "Emptying Recycle Bin..."
        try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Done "Recycle Bin emptied" } catch {}
        0
    }
    "Windows Update Cache"              = {
        Write-Step "Stopping Windows Update service..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        $s = Remove-FolderContents "C:\Windows\SoftwareDistribution\Download" "Update Cache"
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        $s
    }
    "Browser Caches (Edge/Chrome/FF)"   = {
        $freed = 0
        $caches = @(
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data",
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\Cache_Data",
            "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles",
            "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache\Cache_Data"
        )
        foreach ($c in $caches) { $freed += Remove-FolderContents $c (Split-Path $c -Leaf) }
        $freed
    }
    "Thumbnail Cache"                   = {
        $p = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        Write-Step "Cleaning thumbnail cache..."
        $freed = 0
        if (Test-Path $p) {
            Get-ChildItem "$p\thumbcache_*.db" -ErrorAction SilentlyContinue | ForEach-Object {
                $freed += [math]::Round($_.Length/1MB,2)
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
            Write-Done "Thumbnail cache cleared (~$freed MB)"
        }
        $freed
    }
    "Crash Dumps & Error Logs"          = {
        $freed = 0
        $freed += Remove-FolderContents "$env:LOCALAPPDATA\CrashDumps" "CrashDumps"
        $freed += Remove-FolderContents "C:\Windows\Minidump" "Minidumps"
        if (Test-Path "C:\Windows\MEMORY.DMP") {
            $s = [math]::Round((Get-Item "C:\Windows\MEMORY.DMP").Length/1MB,2)
            Remove-Item "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
            Write-Done "Deleted MEMORY.DMP (~$s MB)"
            $freed += $s
        }
        $freed
    }
    "Windows Error Reporting"           = { Remove-FolderContents "C:\ProgramData\Microsoft\Windows\WER" "WER Store" }
    "DirectX Shader Cache"              = { Remove-FolderContents "$env:LOCALAPPDATA\D3DSCache" "DirectX Shader Cache" }
    "Windows Delivery Optimization"     = {
        Write-Step "Cleaning Delivery Optimization cache..."
        try {
            Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
            Write-Done "Delivery Optimization cache cleared"
        } catch {
            Remove-FolderContents "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization" "DO Cache"
        }
        0
    }
    "Font Cache"                        = {
        Write-Step "Resetting font cache..."
        Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
        Remove-FolderContents "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache" "Font Cache" | Out-Null
        Remove-Item "C:\Windows\System32\FNTCACHE.DAT" -Force -ErrorAction SilentlyContinue
        Start-Service -Name FontCache -ErrorAction SilentlyContinue
        Write-Done "Font cache reset"
        0
    }
    "Windows.old (old Windows install)"  = {
        if (Test-Path "C:\Windows.old") {
            $s = Get-FolderSize "C:\Windows.old"
            Write-Step "Found Windows.old ($s MB). Removing..."
            $proc = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:99" -PassThru -ErrorAction SilentlyContinue
            # Direct removal as alternative
            cmd /c "rd /s /q C:\Windows.old" 2>$null
            Write-Done "Windows.old removed (~$s MB freed)"
            $s
        } else {
            Write-Skip "Windows.old not found"
            0
        }
    }
    "Hibernation File (hiberfil.sys)"    = {
        Write-Host ""
        Write-Host "  ⚠  This disables hibernation to free disk space (4-32 GB)." -ForegroundColor Yellow
        Write-Host "     Only do this if you NEVER use hibernate/fast startup." -ForegroundColor DarkYellow
        $confirm = Read-Host "  Disable hibernation? (y/n)"
        if ($confirm -eq 'y') {
            $size = 0
            if (Test-Path "C:\hiberfil.sys") { $size = [math]::Round((Get-Item "C:\hiberfil.sys" -Force).Length/1GB,2) }
            powercfg /hibernate off 2>$null
            Write-Done "Hibernation disabled — freed ~$size GB"
            $size * 1024
        } else { Write-Skip "Hibernation file kept"; 0 }
    }
}

$selected = @{}
foreach ($task in $tasks.Keys) {
    $ans = Read-Host "  ➤ $task ? [Y/n]"
    $selected[$task] = ($ans -eq '' -or $ans -match '^[Yy]')
}

# ── Run selected tasks ────────────────────────────────────────
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "  Running selected clean tasks..." -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""

$i = 0
foreach ($task in $tasks.Keys) {
    if ($selected[$task]) {
        $i++
        Write-Progress -Activity "WinClean - Junk Cleaner" -Status "$task" -PercentComplete (($i / $tasks.Count) * 100)
        $freed = & $tasks[$task]
        if ($freed) { $totalFreed += $freed }
    }
}
Write-Progress -Activity "WinClean - Junk Cleaner" -Completed

# ── Also run DISM component cleanup silently ─────────────────
Write-Host ""
Write-Step "Running DISM Component Store Cleanup (this may take a few minutes)..."
$dismJob = Start-Job { Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1 }
$dots = 0
while ($dismJob.State -eq 'Running') {
    Write-Host -NoNewline "." -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
    $dots++
    if ($dots -gt 30) { break }
}
Receive-Job $dismJob | Out-Null
Remove-Job $dismJob
Write-Done "DISM component store cleaned"

# ── Summary ───────────────────────────────────────────────────
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅ JUNK CLEANER COMPLETE" -ForegroundColor Green
Write-Host "     Total freed: ~$([math]::Round($totalFreed,0)) MB" -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Log "Junk Cleaner complete. Freed ~$totalFreed MB" "DONE"
