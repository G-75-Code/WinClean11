# ============================================================
#  WinClean 11 - Main Launcher
#  Run this as Administrator in PowerShell via bootstrap.ps1
# ============================================================

#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "WinClean 11"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# ── Version & Config ────────────────────────────────────────
$WC_VERSION    = "1.0.0"
$GITHUB_BASE   = "https://raw.githubusercontent.com/G-75-Code/WinClean11/main/scripts"
$TEMP_DIR      = "$env:TEMP\WinClean"
$LOG_FILE      = "$env:TEMP\WinClean\winclean_log.txt"

# ── Create temp working directory ───────────────────────────
if (-not (Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null }

# ── Logging ─────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -Append -FilePath $LOG_FILE -Encoding UTF8
}

# ── Banner ───────────────────────────────────────────────────
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ██╗    ██╗██╗███╗   ██╗ ██████╗██╗     ███████╗ █████╗ ███╗   ██╗" -ForegroundColor Cyan
    Write-Host "  ██║    ██║██║████╗  ██║██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║" -ForegroundColor Cyan
    Write-Host "  ██║ █╗ ██║██║██╔██╗ ██║██║     ██║     █████╗  ███████║██╔██╗ ██║" -ForegroundColor Cyan
    Write-Host "  ██║███╗██║██║██║╚██╗██║██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔███╔╝██║██║ ╚████║╚██████╗███████╗███████╗██║  ██║██║ ╚████║" -ForegroundColor Cyan
    Write-Host "   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Windows 11 Cleaner & Privacy Hardener  v$WC_VERSION" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

# ── Download sub-scripts from GitHub ──────────────────────────
function Get-Script {
    param([string]$ScriptName)
    $url    = "$GITHUB_BASE/$ScriptName"
    $dest   = "$TEMP_DIR\$ScriptName"
    try {
        Write-Host "  [↓] Downloading $ScriptName..." -ForegroundColor DarkCyan
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $scriptContent = $webClient.DownloadString($url)
        [System.IO.File]::WriteAllText($dest, $scriptContent, [System.Text.Encoding]::UTF8)
        $webClient.Dispose()
        Write-Log "Downloaded $ScriptName"
        return $dest
    } catch {
        Write-Host "  [!] Failed to download $ScriptName : $_" -ForegroundColor Red
        Write-Log "FAILED downloading $ScriptName : $_" "ERROR"
        return $null
    }
}

# ── Progress bar helper ──────────────────────────────────────
function Show-Progress {
    param([string]$Activity, [string]$Status, [int]$Percent)
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $Percent
}

# ── Check Windows version ────────────────────────────────────
function Assert-Windows11 {
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 22000) {
        Write-Host "  [!] This script is designed for Windows 11." -ForegroundColor Yellow
        Write-Host "      Detected build: $build (Windows 10 or older)" -ForegroundColor DarkYellow
        $c = Read-Host "  Continue anyway? (y/n)"
        if ($c -ne 'y') { exit }
    }
}

# ── Main Menu ─────────────────────────────────────────────────
function Show-MainMenu {
    Show-Banner
    Write-Host "  What would you like to do?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1]  🗑️  Junk Cleaner       - Delete temp files, caches, update junk" -ForegroundColor Green
    Write-Host "  [2]  👁️  Privacy Hardener    - Disable Microsoft spying & telemetry" -ForegroundColor Magenta
    Write-Host "  [3]  🔒  Security Booster    - Harden Defender, Firewall, UAC" -ForegroundColor Yellow
    Write-Host "  [4]  ⚡  Speed Optimizer     - Startup, visual effects, background apps" -ForegroundColor Cyan
    Write-Host "  [5]  📦  Bloatware Remover   - Remove pre-installed junk apps" -ForegroundColor Red
    Write-Host "  [6]  🚀  Run Everything      - Full clean + privacy + security + speed" -ForegroundColor White
    Write-Host "  [7]  📋  View Last Log       - See what was changed last run" -ForegroundColor DarkGray
    Write-Host "  [0]  ❌  Exit" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $choice = Read-Host "  Enter your choice"
    return $choice
}

# ── Run sub-script ─────────────────────────────────────────────
function Invoke-Module {
    param([string]$ScriptFile)
    $path = Get-Script $ScriptFile
    if ($path -and (Test-Path $path)) {
        Write-Host ""
        Write-Host "  [▶] Running $ScriptFile ..." -ForegroundColor Green
        Write-Host ""
        & $path
    } else {
        Write-Host "  [!] Could not run $ScriptFile" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Press any key to return to menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── View log ───────────────────────────────────────────────────
function Show-Log {
    if (Test-Path $LOG_FILE) {
        Get-Content $LOG_FILE | Select-Object -Last 60 | ForEach-Object {
            if ($_ -match "\[ERROR\]") { Write-Host $_ -ForegroundColor Red }
            elseif ($_ -match "\[WARN\]") { Write-Host $_ -ForegroundColor Yellow }
            elseif ($_ -match "\[DONE\]") { Write-Host $_ -ForegroundColor Green }
            else { Write-Host $_ -ForegroundColor DarkGray }
        }
    } else {
        Write-Host "  No log found yet." -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  Press any key to return to menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── Entry Point ────────────────────────────────────────────────
Assert-Windows11
Write-Log "=== WinClean $WC_VERSION started ===" "INFO"

do {
    $choice = Show-MainMenu
    switch ($choice) {
        "1" { Invoke-Module "01_JunkCleaner.ps1" }
        "2" { Invoke-Module "02_PrivacyHardener.ps1" }
        "3" { Invoke-Module "03_SecurityBooster.ps1" }
        "4" { Invoke-Module "04_SpeedOptimizer.ps1" }
        "5" { Invoke-Module "05_BloatwareRemover.ps1" }
        "6" {
            Invoke-Module "01_JunkCleaner.ps1"
            Invoke-Module "02_PrivacyHardener.ps1"
            Invoke-Module "03_SecurityBooster.ps1"
            Invoke-Module "04_SpeedOptimizer.ps1"
            Invoke-Module "05_BloatwareRemover.ps1"
        }
        "7" { Show-Banner; Show-Log }
        "0" {
            Write-Host ""
            Write-Host "  Goodbye! Your PC is cleaner now. " -ForegroundColor Cyan
            Write-Host ""
            exit
        }
        default {
            Write-Host "  [!] Invalid choice. Try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
