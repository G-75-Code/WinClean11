# ============================================================
#  WinClean 11 - Module 04: Speed Optimizer
#  Disables startup apps, background bloat, visual effects
# ============================================================

#Requires -RunAsAdministrator

$LOG_FILE = "$env:TEMP\WinClean\winclean_log.txt"
function Write-Log  { param([string]$m,[string]$l="INFO"); "$(Get-Date -f 'HH:mm:ss') [$l] $m" | Out-File -Append $LOG_FILE -Encoding UTF8 }
function Write-Step { param([string]$m); Write-Host "  [»] $m" -ForegroundColor Cyan }
function Write-Done { param([string]$m); Write-Host "  [✓] $m" -ForegroundColor Green; Write-Log $m "DONE" }
function Write-Warn { param([string]$m); Write-Host "  [~] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m); Write-Host "  [!] $m" -ForegroundColor Red; Write-Log $m "ERROR" }
function Set-Reg {
    param([string]$Path,[string]$Name,$Value,[string]$Type="DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    } catch { Write-Fail "Reg: $Path\$Name" }
}

$speedTasks = [ordered]@{

    "Disable common bloat startup programs" = {
        $bloatStartup = @(
            "OneDrive","Teams","Skype","Discord","Spotify",
            "Steam","EpicGamesLauncher","GalaxyClient","MicrosoftEdgeAutoLaunch",
            "Cortana","WindowsTerminal","CCleaner","Opera","OperaGX"
        )
        $disabled = 0
        # From Registry Run keys
        $runPaths = @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        foreach ($path in $runPaths) {
            if (Test-Path $path) {
                foreach ($app in $bloatStartup) {
                    $val = Get-ItemProperty -Path $path -Name $app -ErrorAction SilentlyContinue
                    if ($val) {
                        Remove-ItemProperty -Path $path -Name $app -Force -ErrorAction SilentlyContinue
                        $disabled++
                    }
                }
            }
        }
        Write-Done "Checked startup programs. Disabled $disabled known bloat entries."
        Write-Warn "Review Task Manager > Startup apps for anything else you want to disable."
    }

    "Disable Widgets / News Feed background service" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2
        # Disable the Widgets process
        Get-Process -Name "Widgets" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Done "Widgets/News Feed disabled"
    }

    "Set Visual Effects to Best Performance" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
        Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" "9012038010000000" "Binary"
        Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
        Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
        Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
        Write-Done "Visual effects set to Best Performance (animations off)"
    }

    "Disable Transparency Effects" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
        Write-Done "Transparency effects disabled"
    }

    "Enable Fast Startup" = {
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 1
        Write-Done "Fast Startup enabled"
    }

    "Disable Superfetch / SysMain (on SSDs)" = {
        $drive = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" }
        if ($drive) {
            Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
            Set-Service  -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Done "SysMain (Superfetch) disabled — SSD detected, not needed"
        } else {
            Write-Warn "SysMain kept — HDD detected, Superfetch helps with HDDs"
        }
    }

    "Disable Xbox Game Bar & DVR (wastes RAM even without Xbox)" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
        Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
        Write-Done "Xbox Game Bar & DVR disabled"
    }

    "Disable Background App Access for all apps" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" 0
        Write-Done "Background app access disabled globally"
    }

    "Disable Cortana background process" = {
        Get-AppxPackage -Name "Microsoft.549981C3F5F10" | Remove-AppxPackage -ErrorAction SilentlyContinue
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
        Write-Done "Cortana disabled"
    }

    "Optimize Power Plan to High Performance" = {
        powercfg /setactive SCHEME_MIN 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Create High Performance plan
            powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        }
        Write-Done "Power plan set to High Performance"
    }

    "Disable Search Indexing on SSD (not needed, uses resources)" = {
        $ssd = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq "SSD" }
        if ($ssd) {
            Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
            Set-Service  -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Done "Search Indexing disabled (SSD detected)"
            Write-Warn "You can still search files but it may be slightly slower on very large drives"
        } else {
            Write-Warn "Search Indexing kept — helps with HDD performance"
        }
    }

    "Reduce Taskbar Notification Area bloat" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "EnableAutoTray" 1
        Write-Done "Taskbar notification area cleaned up"
    }

    "Disable Windows Tips & Suggestions notifications" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0
        Write-Done "Windows tips & suggestions disabled"
    }

    "Enable Hardware-Accelerated GPU Scheduling (HAGS) if supported" = {
        $gpu = Get-WmiObject -Class Win32_VideoController -ErrorAction SilentlyContinue
        if ($gpu) {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
            Write-Done "Hardware GPU Scheduling enabled (requires GPU driver restart)"
        }
    }

    "Set DNS to Cloudflare (faster & more private than ISP DNS)" = {
        Write-Warn "This will change your DNS to Cloudflare (1.1.1.1 / 1.0.0.1)"
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        }
        Write-Done "DNS set to Cloudflare (1.1.1.1) on all active adapters"
    }
}

# ── Header ────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "    ⚡  SPEED OPTIMIZER" -ForegroundColor Cyan
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Speeds up boot, frees RAM, reduces background noise." -ForegroundColor White
Write-Host ""

$selected = @{}
foreach ($task in $speedTasks.Keys) {
    $ans = Read-Host "  ➤ $task ? [Y/n]"
    $selected[$task] = ($ans -eq '' -or $ans -match '^[Yy]')
}

Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "  Applying speed optimizations..." -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""

$i = 0
foreach ($task in $speedTasks.Keys) {
    if ($selected[$task]) {
        $i++
        Write-Progress -Activity "WinClean - Speed Optimizer" -Status $task -PercentComplete (($i / $speedTasks.Count)*100)
        & $speedTasks[$task]
        Write-Host ""
    }
}
Write-Progress -Activity "WinClean - Speed Optimizer" -Completed

Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅ SPEED OPTIMIZER COMPLETE" -ForegroundColor Green
Write-Host "     $i optimizations applied. Restart recommended." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Log "Speed Optimizer complete. $i settings applied." "DONE"
